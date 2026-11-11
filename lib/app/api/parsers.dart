import '../../customer/data/models.dart';
import '../format.dart';
import 'api_client.dart';

/// Mengubah JSON dari API Laravel menjadi model aplikasi.

typedef Json = Map<String, dynamic>;

DateTime? parseTime(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

double? parseDouble(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

int parseInt(Object? v, [int fallback = 0]) => switch (v) {
  num n => n.toInt(),
  String s => int.tryParse(s) ?? fallback,
  _ => fallback,
};

/// Isi `data` dari respons Laravel (daftar berhalaman atau resource tunggal).
List<Json> dataList(dynamic json) {
  final data = json is Map ? json['data'] : json;
  return [
    for (final e in (data is List ? data : const [])) Json.from(e as Map),
  ];
}

Json dataObject(dynamic json) {
  final data = json is Map && json['data'] is Map ? json['data'] : json;
  return Json.from(data as Map);
}

Partner parsePartner(Json j) => Partner(
  id: j['code'] as String? ?? 'BSI-IAS-TOBA',
  name: j['name'] as String? ?? 'BSI Ias Toba',
  initials: j['initials'] as String? ?? 'BI',
  address: j['address'] as String? ?? '',
  area: j['area'] as String? ?? '',
  hours: j['hours'] as String? ?? '',
  phone: j['phone'] as String? ?? '',
  monthlyTargetKg: parseDouble(j['monthly_target_kg']) ?? 500,
);

RewardCategory parseRewardCategory(Object? v) => switch (v) {
  'e_wallet' => RewardCategory.eWallet,
  'sembako' => RewardCategory.sembako,
  'bibit' => RewardCategory.bibit,
  _ => RewardCategory.voucher,
};

String rewardCategoryValue(RewardCategory c) => switch (c) {
  RewardCategory.voucher => 'voucher',
  RewardCategory.eWallet => 'e_wallet',
  RewardCategory.sembako => 'sembako',
  RewardCategory.bibit => 'bibit',
};

Reward parseReward(Json j) => Reward(
  id: j['code'] as String? ?? 'RW-${j['id']}',
  serverId: parseInt(j['id']),
  initials: j['initials'] as String? ?? '?',
  name: j['name'] as String? ?? '',
  category: parseRewardCategory(j['category']),
  points: parseInt(j['points']),
  stock: parseInt(j['stock']),
  description: j['description'] as String? ?? '',
  isActive: j['is_active'] as bool? ?? true,
);

Vehicle parseVehicle(Json j) => Vehicle(
  id: '${j['id']}',
  type: j['type'] as String? ?? '',
  plate: j['plate'] as String? ?? '',
);

DepositStatus parseDepositStatus(Object? v) => switch (v) {
  'scheduled' => DepositStatus.scheduled,
  'on_the_way' => DepositStatus.onTheWay,
  'verified' => DepositStatus.verified,
  'rejected' => DepositStatus.rejected,
  _ => DepositStatus.waiting,
};

RedemptionStatus parseRedemptionStatus(Object? v) => switch (v) {
  'shipped' => RedemptionStatus.shipped,
  'done' => RedemptionStatus.done,
  _ => RedemptionStatus.processing,
};

WasteType parseWasteType(Object? v) {
  if (v is Map) {
    final code = v['code'] as String?;
    final known = code == null ? null : WasteType.byCode(code);
    // Jenis baru dari admin belum ada di daftar lokal: tambahkan.
    return known ?? WasteType.upsertFromJson(Json.from(v));
  }
  return WasteType.plastik;
}

/// [customer] membuat objek customer dari bagian `customer` di JSON.
Deposit parseDeposit(Json j, CustomerRef Function(Json) customer) {
  final partner = j['partner'] is Map
      ? parsePartner(Json.from(j['partner'] as Map))
      : null;
  final vehicle = j['vehicle'] is Map
      ? parseVehicle(Json.from(j['vehicle'] as Map))
      : null;
  final created = parseTime(j['created_at']) ?? DateTime.now();
  final weighedKg = parseDouble(j['weighed_kg']);
  return Deposit(
      id: j['code'] as String,
      customer: customer(Json.from((j['customer'] ?? const {}) as Map)),
      partner: partner ?? _fallbackPartner,
      type: parseWasteType(j['waste_type']),
      estimatedKg: parseDouble(j['estimated_kg']) ?? weighedKg ?? 0,
      method: j['method'] == 'pickup'
          ? DepositMethod.pickup
          : DepositMethod.dropOff,
      createdAt: created,
      status: parseDepositStatus(j['status']),
      weighedKg: weighedKg,
      pickupDate: parseTime(j['pickup_date']),
      pickupSlot: j['pickup_slot'] as String?,
      address: j['address'] as String?,
      note: j['note'] as String?,
      vehicle: vehicle?.label,
      weighedAt: parseTime(j['weighed_at']),
      weighNote: j['weigh_note'] as String?,
      weighPhotoUrl: j['weigh_photo_url'] as String?,
      rejectReason: j['reject_reason'] as String?,
      originalWeighedKg: parseDouble(j['original_weighed_kg']),
      correctionReason: j['correction_reason'] as String?,
      timeline: [
        for (final s in (j['timeline'] as List? ?? const []))
          _step(Json.from(s as Map)),
      ],
    )
    ..earnedPointsOverride = j['points_earned'] == null
        ? null
        : parseInt(j['points_earned']);
}

TimelineStep _step(Json s) {
  final time = parseTime(s['time']);
  return TimelineStep(
    s['title'] as String? ?? '',
    time == null ? 'Menunggu' : formatStamp(time),
    done: s['done'] as bool? ?? time != null,
  );
}

const _fallbackPartner = Partner(
  id: 'BSI-IAS-TOBA',
  name: 'BSI Ias Toba',
  initials: 'BI',
  address: 'Kabupaten Toba',
  area: 'Sumatera Utara',
  hours: 'Senin–Sabtu, 08.00–17.00',
);

Redemption parseRedemption(Json j) => Redemption(
  id: j['code'] as String,
  reward: j['reward'] is Map
      ? parseReward(Json.from(j['reward'] as Map))
      : Reward(
          id: '-',
          initials: '?',
          name: 'Hadiah',
          category: RewardCategory.voucher,
          points: parseInt(j['points']),
          stock: 0,
          description: '',
        ),
  address: j['address'] as String? ?? '',
  createdAt: parseTime(j['created_at']) ?? DateTime.now(),
  status: parseRedemptionStatus(j['status']),
  trackingNumber: j['tracking_number'] as String?,
);

/// Data bersama semua peran: bank sampah, jenis sampah, dan katalog hadiah.
class Catalog {
  Catalog({
    required this.partner,
    required this.rewards,
    required this.pickupSlots,
  });

  final Partner partner;
  final List<Reward> rewards;
  final List<String> pickupSlots;

  static (ApiClient, DateTime, Catalog)? _cache;

  /// Seperti [load], tetapi memakai hasil terakhir selama 5 menit. Jenis
  /// sampah dan hadiah jarang berubah, dan setiap permintaan ke server
  /// lokal bisa memakan waktu sekitar satu detik.
  static Future<Catalog> cached(ApiClient api) async {
    final c = _cache;
    if (c != null &&
        identical(c.$1, api) &&
        DateTime.now().difference(c.$2) < const Duration(minutes: 5)) {
      return c.$3;
    }
    final fresh = await load(api);
    _cache = (api, DateTime.now(), fresh);
    return fresh;
  }

  static void invalidate() => _cache = null;

  static Future<Catalog> load(ApiClient api) async {
    final results = await Future.wait([
      api.get('/config'),
      api.get('/waste-types'),
      api.get('/rewards'),
    ]);
    final config = Json.from(results[0] as Map);
    for (final g in dataList(results[1])) {
      for (final t in (g['types'] as List? ?? const [])) {
        WasteType.upsertFromJson({...Json.from(t as Map), 'group': g['code']});
      }
    }
    return Catalog(
      partner: parsePartner(Json.from(config['bank_sampah'] as Map)),
      rewards: dataList(results[2]).map(parseReward).toList(),
      pickupSlots: [
        for (final s in (config['pickup_slots'] as List? ?? const [])) '$s',
      ],
    );
  }
}

/// Format tanggal untuk dikirim ke server: 2026-11-12.
String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
