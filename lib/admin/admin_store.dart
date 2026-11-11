import 'package:flutter/widgets.dart';

import '../app/api/api_client.dart';
import '../app/api/parsers.dart';
import '../customer/data/models.dart';
import '../partner/data/partner_store.dart';

/// Penukaran beserta customer yang menukar (untuk diproses admin).
class AdminRedemption {
  AdminRedemption(this.redemption, this.customerName, this.customerCode);

  final Redemption redemption;
  final String customerName;
  final String customerCode;
}

/// Akun customer atau petugas mitra yang dilihat admin.
class AdminUser {
  AdminUser({
    required this.serverId,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    this.address = '',
    this.points = 0,
  });

  factory AdminUser.fromJson(Json j) => AdminUser(
    serverId: parseInt(j['id']),
    code: j['code'] as String? ?? '',
    name: j['name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    address: j['address'] as String? ?? '',
    isActive: j['is_active'] as bool? ?? true,
    points: parseInt(j['points_balance']),
  );

  final int serverId;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String address;
  final bool isActive;
  final int points;
}

/// Ringkasan beranda admin (FR-P1).
class AdminSummary {
  AdminSummary(this.json);

  final Json json;

  double get kgThisMonth => parseDouble(json['kg_this_month']) ?? 0;
  double get targetKg =>
      parseDouble((json['partner'] as Map?)?['monthly_target_kg']) ?? 500;
  double get targetProgress => parseDouble(json['target_progress']) ?? 0;
  double get co2ThisMonthKg => parseDouble(json['co2_this_month_kg']) ?? 0;
  int get pointsThisMonth => parseInt(json['points_this_month']);
  int get activeCustomers => parseInt(json['active_customers_this_month']);
  int get totalCustomers => parseInt(json['total_customers']);
  int get pendingRedemptions => parseInt(json['pending_redemptions']);

  List<(DateTime, double)> get monthlyKg => [
    for (final m in (json['monthly_kg'] as List? ?? const []))
      (
        DateTime.tryParse('${(m as Map)['month']}-01') ?? DateTime.now(),
        parseDouble(m['kg']) ?? 0,
      ),
  ];

  List<(String, double)> get kgByGroup => [
    for (final g in (json['kg_by_group_this_month'] as List? ?? const []))
      ('${(g as Map)['name']}', parseDouble(g['kg']) ?? 0),
  ];
}

/// Laporan periode (FR-P7).
class AdminReport {
  AdminReport(this.json);

  final Json json;

  Json get _totals => Json.from(json['totals'] as Map? ?? const {});
  Json get _redemptions => Json.from(json['redemptions'] as Map? ?? const {});

  double get kg => parseDouble(_totals['kg']) ?? 0;
  double get tco2e => parseDouble(_totals['tco2e']) ?? 0;
  int get deposits => parseInt(_totals['deposits']);
  int get activeCustomers => parseInt(_totals['active_customers']);
  int get pointsGiven => parseInt(_totals['points_given']);
  int get redemptionCount => parseInt(_redemptions['count']);
  int get redemptionPoints => parseInt(_redemptions['points']);

  List<({String group, String name, double kg, int points})> get byType => [
    for (final t in (json['by_type'] as List? ?? const []))
      (
        group: '${(t as Map)['group']}',
        name: '${t['name']}',
        kg: parseDouble(t['kg']) ?? 0,
        points: parseInt(t['points']),
      ),
  ];
}

/// State peran Admin perusahaan. Admin hanya ada saat tersambung ke server,
/// jadi semua data di sini berasal dari API `/api/admin`.
class AdminStore extends ChangeNotifier {
  ApiClient? _api;
  bool get isConnected => _api != null;
  ApiClient get api => _api!;

  ({String code, String name, String email}) profile = (
    code: '',
    name: '',
    email: '',
  );

  AdminSummary? summary;
  Partner? bankSampah;
  List<AdminRedemption> redemptions = [];
  List<WasteType> wasteTypes = [];
  List<Reward> rewards = [];
  List<AdminUser> staff = [];
  List<AdminUser> customers = [];
  List<Deposit> deposits = [];
  List<AppNotification> notifications = [];

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  List<AdminRedemption> get pendingRedemptions => redemptions
      .where((r) => r.redemption.status != RedemptionStatus.done)
      .toList();

  Future<void> connect(ApiClient api, Json user) async {
    _api = api;
    profile = (
      code: user['code'] as String? ?? '',
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
    );
    await refresh();
  }

  void disconnect() {
    if (_api == null) return;
    _api = null;
    Catalog.invalidate();
    summary = null;
    bankSampah = null;
    redemptions = [];
    wasteTypes = [];
    rewards = [];
    staff = [];
    customers = [];
    deposits = [];
    notifications = [];
    WasteType.resetToDefaults();
    notifyListeners();
  }

  Future<void> refresh() async {
    final api = _api;
    if (api == null) return;
    final r = await Future.wait([
      api.get('/admin/summary'),
      api.get('/admin/bank-sampah'),
      api.get('/admin/redemptions'),
      api.get('/admin/waste-types'),
      api.get('/admin/rewards'),
      api.get('/admin/bank-sampah/staff'),
      api.get('/notifications'),
    ]);
    if (!identical(api, _api)) return;
    summary = AdminSummary(Json.from(r[0] as Map));
    bankSampah = parsePartner(dataObject(r[1]));
    redemptions = dataList(r[2]).map(_redemption).toList();
    final types = dataList(r[3]);
    for (final t in types) {
      if (t['group_id'] != null) {
        _groupIds['${t['group']}'] = parseInt(t['group_id']);
      }
    }
    wasteTypes = types.map(WasteType.upsertFromJson).toList();
    rewards = dataList(r[4]).map(parseReward).toList();
    staff = dataList(r[5]).map(AdminUser.fromJson).toList();
    notifications = dataList(r[6]).map(AppNotification.fromJson).toList();
    notifyListeners();
  }

  static AdminRedemption _redemption(Json j) {
    final c = Json.from(j['customer'] as Map? ?? const {});
    return AdminRedemption(
      parseRedemption(j),
      c['name'] as String? ?? '-',
      c['code'] as String? ?? '',
    );
  }

  void markNotificationsRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
    _api?.post('/notifications/read-all').catchError((_) => null);
  }

  // ---------- Setoran dan customer ----------

  Future<void> loadDeposits({String? search, DepositStatus? status}) async {
    final json = await api.get('/admin/deposits', {
      'search': search?.trim(),
      'status': status == null ? null : _statusValue(status),
    });
    deposits = [
      for (final j in dataList(json)) parseDeposit(j, PartnerCustomer.fromJson),
    ];
    notifyListeners();
  }

  Future<void> loadCustomers({String? search}) async {
    final json = await api.get('/admin/customers', {'search': search?.trim()});
    customers = dataList(json).map(AdminUser.fromJson).toList();
    notifyListeners();
  }

  static String _statusValue(DepositStatus s) => switch (s) {
    DepositStatus.waiting => 'waiting',
    DepositStatus.scheduled => 'scheduled',
    DepositStatus.onTheWay => 'on_the_way',
    DepositStatus.verified => 'verified',
    DepositStatus.rejected => 'rejected',
  };

  // ---------- Pengaturan (FR-P2 sampai FR-P5) ----------

  Future<void> updateWasteType(
    WasteType t, {
    required int pointsPerKg,
    required bool isActive,
  }) async {
    final json = await api.put('/admin/waste-types/${t.serverId}', {
      'points_per_kg': pointsPerKg,
      'is_active': isActive,
    });
    WasteType.upsertFromJson(dataObject(json));
    notifyListeners();
  }

  Future<void> addWasteType({
    required WasteGroup group,
    required String name,
    required String examples,
    required int pointsPerKg,
  }) async {
    final groupId = await _groupId(group);
    final json = await api.post('/admin/waste-types', {
      'waste_group_id': groupId,
      'name': name.trim(),
      'examples': examples.trim(),
      'points_per_kg': pointsPerKg,
    });
    wasteTypes = [...wasteTypes, WasteType.upsertFromJson(dataObject(json))];
    notifyListeners();
  }

  /// ID kelompok di server, dari kolom `group_id` jenis sampah.
  final Map<String, int> _groupIds = {};

  Future<int> _groupId(WasteGroup group) async =>
      _groupIds[group.name] ?? group.index + 1;

  Future<void> saveReward({
    Reward? existing,
    required String name,
    required RewardCategory category,
    required int points,
    required int stock,
    required String description,
    bool isActive = true,
  }) async {
    final body = {
      'name': name.trim(),
      'category': rewardCategoryValue(category),
      'points': points,
      'stock': stock,
      'description': description.trim(),
      'is_active': isActive,
    };
    final json = existing == null
        ? await api.post('/admin/rewards', body)
        : await api.put('/admin/rewards/${existing.serverId}', body);
    final saved = parseReward(dataObject(json));
    rewards = [
      for (final r in rewards)
        if (r.serverId != saved.serverId) r,
      saved,
    ]..sort((a, b) => a.points.compareTo(b.points));
    notifyListeners();
  }

  Future<void> updateBankSampah({
    required String address,
    required String area,
    required String hours,
    required String phone,
    required double monthlyTargetKg,
  }) async {
    final json = await api.put('/admin/bank-sampah', {
      'address': address.trim(),
      'area': area.trim(),
      'hours': hours.trim(),
      'phone': phone.trim(),
      'monthly_target_kg': monthlyTargetKg,
    });
    bankSampah = parsePartner(dataObject(json));
    await _refreshQuietly();
  }

  Future<void> addStaff({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await api.post('/admin/bank-sampah/staff', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    });
    staff = [...staff, AdminUser.fromJson(dataObject(json))];
    notifyListeners();
  }

  Future<void> setStaffActive(AdminUser u, bool active) async {
    final json = await api.put('/admin/bank-sampah/staff/${u.serverId}', {
      'is_active': active,
    });
    final saved = AdminUser.fromJson(dataObject(json));
    staff = [for (final s in staff) s.serverId == saved.serverId ? saved : s];
    notifyListeners();
  }

  // ---------- Penukaran (FR-P6) ----------

  Future<void> shipRedemption(AdminRedemption r, String trackingNumber) async {
    await api.post('/admin/redemptions/${r.redemption.id}/ship', {
      'tracking_number': trackingNumber.trim(),
    });
    await _refreshQuietly();
  }

  Future<void> completeRedemption(AdminRedemption r) async {
    await api.post('/admin/redemptions/${r.redemption.id}/complete');
    await _refreshQuietly();
  }

  // ---------- Laporan (FR-P7) ----------

  Future<AdminReport> loadReport(DateTime from, DateTime to) async {
    final json = await api.get('/admin/reports', {
      'from': apiDate(from),
      'to': apiDate(to),
    });
    return AdminReport(Json.from(json as Map));
  }

  /// Tautan unduhan sementara (berlaku beberapa menit) agar bisa dibuka di
  /// peramban tanpa token. [format] `csv` (Excel) atau `pdf` (siap cetak).
  Future<Uri> reportLink(DateTime from, DateTime to, String format) async {
    final json = await api.get('/admin/reports/link', {
      'from': apiDate(from),
      'to': apiDate(to),
      'format': format,
    });
    return Uri.parse((json as Map)['url'] as String);
  }

  Future<void> _refreshQuietly() async {
    try {
      await refresh();
    } on ApiException {
      notifyListeners();
    }
  }
}

class AdminScope extends InheritedNotifier<AdminStore> {
  const AdminScope({super.key, required AdminStore store, required super.child})
    : super(notifier: store);

  static AdminStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminScope>()!.notifier!;

  static AdminStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AdminScope>()!.notifier!;
}
