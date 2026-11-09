import 'package:flutter/widgets.dart';

import '../../app/format.dart';
import '../../customer/data/customer_store.dart';
import '../../customer/data/models.dart';

/// Customer lain yang pernah menyetor ke mitra ini (data contoh).
class PartnerCustomer implements CustomerRef {
  PartnerCustomer({
    required this.id,
    required this.name,
    required this.initials,
    required this.phone,
    required this.address,
    required this.points,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String initials;
  @override
  final String phone;
  @override
  final String address;
  int points;
}

/// Alasan penolakan sesuai syarat sampah di PRD (bersih, kering, terpilah).
const rejectReasons = [
  'Sampah kotor atau basah',
  'Sampah tercampur, belum dipilah',
  'Alamat di luar jangkauan jemput',
  'Jadwal jemput penuh',
];

/// Batas berat per setoran untuk mencegah salah catat (mitigasi risiko PRD).
const maxWeighKg = 200.0;

/// State aplikasi mitra di memori.
///
/// Setoran milik customer yang sedang masuk dibaca langsung dari
/// [CustomerStore], sehingga permintaan dari aplikasi customer muncul di sini
/// dan poin hasil timbang masuk ke saldo customer. Customer lain adalah data
/// contoh. Saat API Laravel siap, method di kelas ini diganti panggilan HTTP.
class PartnerStore extends ChangeNotifier {
  PartnerStore(this.customerStore) {
    customerStore.addListener(notifyListeners);
    _seed();
  }

  final CustomerStore customerStore;

  /// Target bulanan per bank sampah dari PRD (500 kg sampai 1 ton).
  static const monthlyTargetKg = 500.0;

  Partner get partner => customerStore.partners.first;

  final profile = (
    id: 'MTR-0001',
    owner: 'Budi Pratama',
    phone: '+62 812 0000 0001',
    email: 'mitra1@example.com',
    joined: DateTime(2024, 1, 12),
  );

  final List<Vehicle> vehicles = [
    const Vehicle(id: 'V1', type: 'Pikap', plate: 'B 9124 KX'),
    const Vehicle(id: 'V2', type: 'Motor roda tiga', plate: 'B 4471 TE'),
  ];

  final List<PartnerCustomer> _otherCustomers = [];
  final List<Deposit> _otherDeposits = [];
  final List<AppNotification> notifications = [];
  int _vehicleSeq = 2;

  @override
  void dispose() {
    customerStore.removeListener(notifyListeners);
    super.dispose();
  }

  // ---------- Data turunan ----------

  List<CustomerRef> get customers => [
    customerStore.profile,
    ..._otherCustomers,
  ];

  /// Semua setoran ke mitra ini, terbaru lebih dulu.
  List<Deposit> get deposits => [
    ...customerStore.deposits.where((d) => d.partner.id == partner.id),
    ..._otherDeposits,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Permintaan baru yang belum diterima atau ditolak (FR-M2).
  List<Deposit> get requests =>
      deposits.where((d) => d.status == DepositStatus.waiting).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Penjemputan yang sudah diterima dan belum ditimbang (FR-M3).
  List<Deposit> get pickups =>
      deposits
          .where(
            (d) =>
                d.method == DepositMethod.pickup &&
                (d.status == DepositStatus.scheduled ||
                    d.status == DepositStatus.onTheWay),
          )
          .toList()
        ..sort(_bySchedule);

  /// Setoran diterima yang siap ditimbang, dijemput maupun diantar.
  List<Deposit> get readyToWeigh =>
      deposits
          .where(
            (d) =>
                d.status == DepositStatus.scheduled ||
                d.status == DepositStatus.onTheWay,
          )
          .toList()
        ..sort(_bySchedule);

  List<Deposit> get todayPickups {
    final now = DateTime.now();
    return pickups.where((d) => _sameDay(d.pickupDate, now)).toList();
  }

  List<Deposit> get verified =>
      deposits.where((d) => d.status == DepositStatus.verified).toList()..sort(
        (a, b) =>
            (b.weighedAt ?? b.createdAt).compareTo(a.weighedAt ?? a.createdAt),
      );

  List<Deposit> get verifiedThisMonth {
    final now = DateTime.now();
    return verified.where((d) {
      final t = d.weighedAt ?? d.createdAt;
      return t.year == now.year && t.month == now.month;
    }).toList();
  }

  double get kgThisMonth =>
      verifiedThisMonth.fold(0.0, (sum, d) => sum + (d.weighedKg ?? 0));

  int get pointsThisMonth =>
      verifiedThisMonth.fold(0, (sum, d) => sum + (d.earnedPoints ?? 0));

  int get customersThisMonth =>
      verifiedThisMonth.map((d) => d.customer.id).toSet().length;

  double get targetProgress => (kgThisMonth / monthlyTargetKg).clamp(0.0, 1.0);

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  int balanceOf(CustomerRef c) => c is PartnerCustomer
      ? c.points
      : identical(c, customerStore.profile)
      ? customerStore.points
      : 0;

  /// Cari customer lewat nomor ponsel atau ID (FR-M4).
  CustomerRef? findCustomer(String query) {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return null;
    final digits = _digits(q);
    for (final c in customers) {
      if (c.id.toUpperCase() == q) return c;
      final phone = _digits(c.phone);
      if (digits.length >= 6 &&
          (phone == digits ||
              phone.endsWith(digits) ||
              // 0812... sama dengan 62812...
              (digits.startsWith('0') &&
                  phone.endsWith(digits.substring(1))))) {
        return c;
      }
    }
    return null;
  }

  // ---------- Aksi ----------

  /// Terima permintaan. Penjemputan wajib punya tanggal, slot, dan kendaraan.
  /// Mengembalikan false jika permintaan sudah ditangani sebelumnya.
  bool accept(Deposit d, {DateTime? date, String? slot, Vehicle? vehicle}) {
    if (d.status != DepositStatus.waiting) return false; // sudah ditangani
    final now = DateTime.now();
    d.status = DepositStatus.scheduled;
    d.completeStep('Diterima', formatStamp(now));
    if (d.method == DepositMethod.pickup) {
      d
        ..pickupDate = date ?? d.pickupDate
        ..pickupSlot = slot ?? d.pickupSlot
        ..vehicle = vehicle?.label;
    }
    _notifyCustomer(
      d,
      d.method == DepositMethod.pickup
          ? 'Jadwal jemput dikonfirmasi'
          : 'Permintaan setoran diterima',
      d.method == DepositMethod.pickup
          ? '${partner.name} akan menjemput ${formatDateShort(d.pickupDate!)}, ${d.pickupSlot} WIB dengan ${d.vehicle}.'
          : '${partner.name} menunggu Anda mengantar sampah ke ${partner.address}.',
    );
    _changed(d);
    return true;
  }

  bool reject(Deposit d, String reason) {
    if (d.status != DepositStatus.waiting) return false; // sudah ditangani
    final now = DateTime.now();
    d
      ..status = DepositStatus.rejected
      ..rejectReason = reason;
    final first = d.timeline.isEmpty ? null : d.timeline.first;
    d.timeline
      ..clear()
      ..addAll([
        ?first,
        TimelineStep(
          'Ditolak ${partner.name}: $reason',
          formatStamp(now),
          done: true,
        ),
      ]);
    _notifyCustomer(
      d,
      'Permintaan setoran ditolak',
      '${d.id} ditolak ${partner.name}: $reason.',
    );
    _changed(d);
    return true;
  }

  /// Ubah jadwal atau kendaraan penjemputan yang sudah diterima.
  void reschedule(
    Deposit d, {
    required DateTime date,
    required String slot,
    required Vehicle vehicle,
  }) {
    d
      ..pickupDate = date
      ..pickupSlot = slot
      ..vehicle = vehicle.label;
    _notifyCustomer(
      d,
      'Jadwal jemput diubah',
      '${partner.name} akan menjemput ${formatDateShort(date)}, $slot WIB dengan ${vehicle.label}.',
    );
    _changed(d);
  }

  /// Mitra berangkat menjemput.
  void depart(Deposit d) {
    d.status = DepositStatus.onTheWay;
    d.completeStep('Mitra menuju', formatStamp(DateTime.now()));
    _notifyCustomer(
      d,
      'Mitra menuju lokasi',
      '${partner.name} sedang menuju alamat Anda dengan ${d.vehicle ?? 'kendaraan mitra'}.',
    );
    _changed(d);
  }

  /// Catat hasil timbang (FR-M4, FR-M5). Poin dihitung sistem dari berat dan
  /// jenis, mitra tidak bisa mengubah angkanya (FR-M6).
  ///
  /// Jika [request] kosong, setoran dibuat baru untuk customer yang datang
  /// langsung tanpa permintaan.
  Deposit recordWeighing({
    Deposit? request,
    required CustomerRef customer,
    required WasteType type,
    required double kg,
    String? note,
  }) {
    final weighed = (kg * 10).round() / 10; // sampai 0,1 kg
    if (weighed <= 0 || weighed > maxWeighKg) {
      throw ArgumentError.value(kg, 'kg', 'Berat di luar batas');
    }
    final now = DateTime.now();
    final cleanNote = (note == null || note.trim().isEmpty)
        ? null
        : note.trim();

    final Deposit d;
    if (request != null) {
      d = request;
      d.completeStep('Mitra menuju', formatStamp(now));
      d.completeStep('Sampah', formatStamp(now));
    } else {
      final stamp = formatStamp(now);
      d = Deposit(
        id: customerStore.nextDepositId(now),
        customer: customer,
        partner: partner,
        type: type,
        estimatedKg: weighed,
        method: DepositMethod.dropOff,
        createdAt: now,
        status: DepositStatus.waiting,
        timeline: [
          TimelineStep(
            'Dicatat langsung di ${partner.name}',
            stamp,
            done: true,
          ),
          TimelineStep('Sampah diantar & ditimbang', stamp, done: true),
          const TimelineStep('Poin masuk ke saldo', 'Menunggu'),
        ],
      );
    }

    d
      ..type = type
      ..weighedKg = weighed
      ..weighedAt = now
      ..weighNote = cleanNote
      ..status = DepositStatus.verified;
    d.completeStep('Poin masuk', formatStamp(now));

    if (identical(customer, customerStore.profile)) {
      if (request == null) customerStore.addDeposit(d);
      customerStore.creditPoints(d);
    } else {
      if (request == null) _otherDeposits.add(d);
      if (customer is PartnerCustomer) customer.points += d.earnedPoints!;
    }
    notifyListeners();
    return d;
  }

  Vehicle addVehicle(String type, String plate) {
    _vehicleSeq++;
    final v = Vehicle(
      id: 'V$_vehicleSeq',
      type: type.trim(),
      plate: plate.trim().toUpperCase(),
    );
    vehicles.add(v);
    notifyListeners();
    return v;
  }

  void markNotificationsRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  /// Dipanggil saat customer mengirim permintaan baru ke mitra ini.
  void _onCustomerChanged() {
    final known = _seenRequestIds;
    for (final d in customerStore.deposits) {
      if (d.partner.id == partner.id &&
          d.status == DepositStatus.waiting &&
          known.add(d.id)) {
        notifications.insert(
          0,
          AppNotification(
            'Permintaan setoran baru',
            '${d.customer.name} · ${d.type.label} ±${formatKg(d.estimatedKg)}, ${d.method.label.toLowerCase()}.',
            d.createdAt,
          ),
        );
      }
    }
  }

  final Set<String> _seenRequestIds = {};

  @override
  void notifyListeners() {
    _onCustomerChanged();
    super.notifyListeners();
  }

  void _notifyCustomer(Deposit d, String title, String body) {
    if (identical(d.customer, customerStore.profile)) {
      customerStore.pushNotification(title, body);
    }
  }

  void _changed(Deposit d) {
    if (identical(d.customer, customerStore.profile)) {
      customerStore.touch(); // ikut memicu notifyListeners di sini
    } else {
      notifyListeners();
    }
  }

  static int _bySchedule(Deposit a, Deposit b) =>
      (a.pickupDate ?? a.createdAt).compareTo(b.pickupDate ?? b.createdAt);

  static bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  // ---------- Data contoh ----------

  void _seed() {
    final now = DateTime.now();
    DateTime at(int dayOffset, [int h = 10, int m = 0]) =>
        DateTime(now.year, now.month, now.day + dayOffset, h, m);
    String id(DateTime d, int n) =>
        'STR-${(d.year % 100).toString().padLeft(2, '0')}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}-$n';

    PartnerCustomer c(int n, String phone, String address, int points) =>
        PartnerCustomer(
          id: 'CST-${n.toString().padLeft(4, '0')}',
          name: 'Customer $n',
          initials: 'C$n',
          phone: phone,
          address: address,
          points: points,
        );

    _otherCustomers.addAll([
      c(
        2,
        '+62 812 0000 0102',
        'Jl. Kemang Raya No. 21, Jakarta Selatan',
        8200,
      ),
      c(3, '+62 812 0000 0103', 'Jl. Bangka II No. 5, Jakarta Selatan', 15600),
      c(
        4,
        '+62 812 0000 0104',
        'Jl. Tebet Barat No. 14, Jakarta Selatan',
        3100,
      ),
      c(
        5,
        '+62 812 0000 0105',
        'Jl. Pejaten Raya No. 9, Jakarta Selatan',
        42750,
      ),
    ]);
    final [c2, c3, c4, c5] = _otherCustomers;

    Deposit request(
      PartnerCustomer cust,
      int n,
      WasteType type,
      double kg,
      DepositMethod method,
      DateTime created, {
      DateTime? date,
      String? slot,
      String? note,
    }) => Deposit(
      id: id(created, n),
      customer: cust,
      partner: partner,
      type: type,
      estimatedKg: kg,
      method: method,
      createdAt: created,
      status: DepositStatus.waiting,
      pickupDate: date,
      pickupSlot: slot,
      address: method == DepositMethod.pickup ? cust.address : null,
      note: note,
      timeline: [
        TimelineStep('Permintaan dikirim', formatStamp(created), done: true),
        TimelineStep('Diterima ${partner.name}', 'Menunggu'),
        if (method == DepositMethod.pickup) ...[
          const TimelineStep('Mitra menuju lokasi', 'Menunggu'),
          const TimelineStep('Sampah diambil & ditimbang', 'Menunggu'),
        ] else
          const TimelineStep('Sampah diantar & ditimbang', 'Menunggu'),
        const TimelineStep('Poin masuk ke saldo', 'Menunggu'),
      ],
    );

    Deposit done(
      PartnerCustomer cust,
      int n,
      WasteType type,
      double kg,
      DateTime when,
    ) {
      final s = formatStamp(when);
      return Deposit(
        id: id(when, n),
        customer: cust,
        partner: partner,
        type: type,
        estimatedKg: kg,
        weighedKg: kg,
        weighedAt: when,
        method: DepositMethod.dropOff,
        createdAt: when,
        status: DepositStatus.verified,
        timeline: [
          TimelineStep('Permintaan dikirim', s, done: true),
          TimelineStep('Diterima ${partner.name}', s, done: true),
          TimelineStep('Sampah diantar & ditimbang', s, done: true),
          TimelineStep('Poin masuk ke saldo', s, done: true),
        ],
      );
    }

    // Penjemputan hari ini yang sudah diterima.
    final today = request(
      c4,
      13,
      WasteType.kertas,
      15,
      DepositMethod.pickup,
      at(-1, 19),
      date: at(0, 0),
      slot: pickupSlots[1],
      note: 'Kardus sudah diikat, ada di depan pagar.',
    );
    accept(today, vehicle: vehicles.first);

    _otherDeposits.addAll([
      request(
        c2,
        11,
        WasteType.plastik,
        6,
        DepositMethod.pickup,
        at(0, 8, 12),
        date: at(1, 0),
        slot: pickupSlots[0],
        note: 'Botol sudah dibilas dan dipipihkan.',
      ),
      request(
        c3,
        12,
        WasteType.kaleng,
        3.5,
        DepositMethod.dropOff,
        at(0, 9, 40),
      ),
      today,
      // Riwayat bulan ini, kira-kira separuh target.
      for (final (i, (cust, type, kg)) in [
        (c2, WasteType.plastik, 18.4),
        (c3, WasteType.kertas, 42.0),
        (c5, WasteType.kaleng, 9.6),
        (c4, WasteType.kaca, 26.5),
        (c5, WasteType.plastik, 31.2),
        (c2, WasteType.kertas, 55.0),
        (c3, WasteType.plastik, 22.8),
        (c5, WasteType.kertas, 64.3),
      ].indexed)
        done(cust, 21 + i, type, kg, at(-(i * 2 + 1), 11 + i % 4)),
    ]);
    // Lewati dulu notifikasi untuk permintaan yang sudah ada sebelum mitra masuk.
    _seenRequestIds.addAll(deposits.map((d) => d.id));
    notifications.addAll([
      for (final d in requests)
        AppNotification(
          'Permintaan setoran baru',
          '${d.customer.name} · ${d.type.label} ±${formatKg(d.estimatedKg)}, ${d.method.label.toLowerCase()}.',
          d.createdAt,
        ),
    ]);
  }
}

/// Memberi akses [PartnerStore] ke seluruh halaman mitra.
class PartnerScope extends InheritedNotifier<PartnerStore> {
  const PartnerScope({
    super.key,
    required PartnerStore store,
    required super.child,
  }) : super(notifier: store);

  static PartnerStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PartnerScope>()!.notifier!;

  static PartnerStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PartnerScope>()!.notifier!;
}
