import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Kelompok sampah (PRD: Plastik, Kertas, Kaleng, Kaca).
enum WasteGroup {
  plastik('Plastik', Icons.local_drink_outlined),
  kertas('Kertas', Icons.inventory_2_outlined),
  kaleng('Kaleng', Icons.liquor_outlined),
  kaca('Kaca', Icons.wine_bar_outlined);

  const WasteGroup(this.label, this.icon);
  final String label;
  final IconData icon;

  List<WasteType> get types =>
      WasteType.values.where((t) => t.group == this).toList();
}

/// Jenis sampah rinci dan poin per kg. Nilai awal sesuai tabel usulan PRD;
/// saat aplikasi tersambung ke API, nilainya diperbarui dari server karena
/// perusahaan bisa mengubahnya (FR-P3).
class WasteType {
  /// Jenis bawaan; nilai awalnya dicatat agar bisa dikembalikan.
  WasteType._(
    this.code,
    this.group,
    this.label,
    this.examples,
    this.pointsPerKg,
  ) {
    _defaults[code] = (group, label, examples, pointsPerKg);
  }

  /// Jenis baru dari server (ditambahkan admin).
  WasteType._fromServer(this.code, this.group)
    : label = '',
      examples = '',
      pointsPerKg = 0;

  /// Kode tetap yang sama dengan kolom `code` di server, misalnya `petBening`.
  final String code;
  WasteGroup group;
  String label;
  String examples;
  int pointsPerKg;

  /// ID di server; null selama memakai data contoh.
  int? serverId;
  bool isActive = true;

  static final petBening = WasteType._(
    'petBening',
    WasteGroup.plastik,
    'Botol PET bening',
    'Botol air mineral, botol minuman',
    500,
  );
  static final plastikKeras = WasteType._(
    'plastikKeras',
    WasteGroup.plastik,
    'Plastik keras',
    'Galon, ember, botol sampo',
    400,
  );
  static final plastikLembaran = WasteType._(
    'plastikLembaran',
    WasteGroup.plastik,
    'Plastik lembaran',
    'Kantong kresek, bungkus makanan',
    100,
  );
  static final kardus = WasteType._(
    'kardus',
    WasteGroup.kertas,
    'Kardus',
    'Kotak kemasan, karton',
    300,
  );
  static final kertasPutih = WasteType._(
    'kertasPutih',
    WasteGroup.kertas,
    'Kertas putih',
    'HVS, arsip',
    300,
  );
  static final kertasCampur = WasteType._(
    'kertasCampur',
    WasteGroup.kertas,
    'Kertas campur',
    'Koran, majalah, buku',
    200,
  );
  static final kalengAluminium = WasteType._(
    'kalengAluminium',
    WasteGroup.kaleng,
    'Kaleng aluminium',
    'Kaleng minuman',
    1500,
  );
  static final kalengBesi = WasteType._(
    'kalengBesi',
    WasteGroup.kaleng,
    'Kaleng besi',
    'Kaleng susu, kaleng sarden',
    300,
  );
  static final botolKaca = WasteType._(
    'botolKaca',
    WasteGroup.kaca,
    'Botol kaca utuh',
    'Botol kecap, botol sirup',
    100,
  );
  static final pecahanKaca = WasteType._(
    'pecahanKaca',
    WasteGroup.kaca,
    'Pecahan kaca',
    'Beling',
    50,
  );

  static final List<WasteType> _all = [
    petBening,
    plastikKeras,
    plastikLembaran,
    kardus,
    kertasPutih,
    kertasCampur,
    kalengAluminium,
    kalengBesi,
    botolKaca,
    pecahanKaca,
  ];

  /// Jenis yang masih aktif dan bisa dipilih.
  static List<WasteType> get values =>
      _all.where((t) => t.isActive).toList(growable: false);

  /// Semua jenis, termasuk yang dinonaktifkan (untuk admin dan riwayat).
  static List<WasteType> get all => List.unmodifiable(_all);

  static WasteType? byCode(String code) {
    for (final t in _all) {
      if (t.code == code) return t;
    }
    return null;
  }

  static WasteType? byServerId(int id) {
    for (final t in _all) {
      if (t.serverId == id) return t;
    }
    return null;
  }

  /// Memperbarui jenis dari data server. Objek lama dipakai ulang agar
  /// setoran yang sudah ada tetap menunjuk jenis yang sama.
  static WasteType upsertFromJson(Map<String, dynamic> j) {
    final code = j['code'] as String;
    final group = WasteGroup.values.firstWhere(
      (g) => g.name == j['group'],
      orElse: () => byCode(code)?.group ?? WasteGroup.plastik,
    );
    var t = byCode(code);
    if (t == null) {
      t = WasteType._fromServer(code, group);
      _all.add(t);
    }
    t
      ..serverId = (j['id'] as num?)?.toInt()
      ..group = group
      ..label = j['name'] as String? ?? code
      ..examples = j['examples'] as String? ?? ''
      ..pointsPerKg = (j['points_per_kg'] as num?)?.toInt() ?? t.pointsPerKg
      ..isActive = j['is_active'] as bool? ?? true;
    return t;
  }

  static final Map<String, (WasteGroup, String, String, int)> _defaults = {};

  /// Kembalikan ke data contoh (dipakai saat keluar akun dan di tes).
  static void resetToDefaults() {
    _all.removeWhere((t) => !_defaults.containsKey(t.code));
    for (final t in _all) {
      final (g, l, e, p) = _defaults[t.code]!;
      t
        ..group = g
        ..label = l
        ..examples = e
        ..pointsPerKg = p
        ..serverId = null
        ..isActive = true;
    }
  }

  IconData get icon => group.icon;

  /// Untuk di tengah kalimat: "botol PET bening", singkatan tetap kapital.
  String get lowerLabel => label[0].toLowerCase() + label.substring(1);

  // Alias untuk kode lama yang memakai nama kelompok.
  static final plastik = petBening;
  static final kertas = kardus;
  static final kaleng = kalengAluminium;
  static final kaca = botolKaca;

  /// Poin dibulatkan ke bawah (aturan PRD).
  int pointsFor(double kg) => (kg * pointsPerKg + 1e-6).floor();

  @override
  String toString() => 'WasteType($code)';
}

/// Bank sampah. Rilis pertama hanya melayani satu: BSI Ias Toba.
class Partner {
  const Partner({
    required this.id,
    required this.name,
    required this.initials,
    required this.address,
    required this.area,
    required this.hours,
    this.phone = '',
    this.monthlyTargetKg = 500,
  });

  final String id;
  final String name;
  final String initials;
  final String address;
  final String area;
  final String hours;
  final String phone;
  final double monthlyTargetKg;

  /// Jenis sampah yang diterima: semua jenis aktif.
  List<WasteType> get accepts => WasteType.values;
}

enum DepositMethod {
  dropOff('Antar sendiri'),
  pickup('Dijemput mitra');

  const DepositMethod(this.label);
  final String label;
}

/// Slot jemput dari PRD (FR-C4).
const pickupSlots = ['09.00–11.00', '13.00–15.00', '15.00–17.00'];

enum DepositStatus {
  waiting('Menunggu mitra', AppColors.amberSoft, AppColors.amberDeep),
  scheduled('Dijadwalkan', AppColors.blueSoft, AppColors.blueDeep),
  onTheWay('Mitra menuju lokasi', AppColors.blueSoft, AppColors.blueDeep),
  verified('Terverifikasi', AppColors.emeraldSoft, AppColors.emeraldDeep),
  rejected('Ditolak', AppColors.roseSoft, AppColors.roseDeep);

  const DepositStatus(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

/// Data customer yang dilihat mitra. [CustomerProfile] (customer yang sedang
/// masuk) dan customer lain di sisi mitra sama-sama memenuhi bentuk ini.
abstract interface class CustomerRef {
  String get id;
  String get name;
  String get initials;
  String get phone;
  String get address;
}

/// Kendaraan milik mitra untuk menjemput (FR-M3).
class Vehicle {
  const Vehicle({required this.id, required this.type, required this.plate});

  final String id;
  final String type;
  final String plate;

  String get label => '$type · $plate';
}

class Deposit {
  Deposit({
    required this.id,
    required this.customer,
    required this.partner,
    required this.type,
    required this.estimatedKg,
    required this.method,
    required this.createdAt,
    required this.status,
    this.weighedKg,
    this.pickupDate,
    this.pickupSlot,
    this.address,
    this.note,
    this.vehicle,
    this.weighedAt,
    this.weighNote,
    this.weighPhotoUrl,
    this.rejectReason,
    this.originalWeighedKg,
    this.correctionReason,
    List<TimelineStep>? timeline,
  }) : timeline = timeline ?? [];

  final String id;
  final CustomerRef customer;
  final Partner partner;

  /// Jenis bisa diganti mitra saat menimbang jika berbeda dari permintaan.
  WasteType type;
  final double estimatedKg;
  final DepositMethod method;
  final DateTime createdAt;
  DepositStatus status;
  double? weighedKg;
  DateTime? pickupDate;
  String? pickupSlot;
  final String? address;
  final String? note;
  String? vehicle;
  DateTime? weighedAt;
  String? weighNote;

  /// Foto hasil timbang dari mitra (disimpan di penyimpanan objek S3 nanti).
  String? weighPhotoUrl;
  String? rejectReason;

  /// Berat sebelum dikoreksi mitra (FR-M8); null jika belum pernah dikoreksi.
  double? originalWeighedKg;
  String? correctionReason;
  final List<TimelineStep> timeline;

  /// Mitra boleh mengoreksi berat sampai 7 hari setelah ditimbang.
  static const correctionDays = 7;

  bool get canCorrect =>
      status == DepositStatus.verified &&
      weighedAt != null &&
      DateTime.now().difference(weighedAt!) <
          const Duration(days: correctionDays);

  int get estimatedPoints => type.pointsFor(estimatedKg);

  /// Poin final hanya ada setelah mitra menimbang.
  int? get earnedPoints =>
      earnedPointsOverride ??
      (weighedKg == null ? null : type.pointsFor(weighedKg!));

  bool get isActive =>
      status != DepositStatus.verified && status != DepositStatus.rejected;

  /// Salin data terbaru dari server ke objek ini, agar halaman yang sedang
  /// membuka setoran ini ikut melihat perubahan.
  void updateFrom(Deposit other) {
    type = other.type;
    status = other.status;
    weighedKg = other.weighedKg;
    pickupDate = other.pickupDate;
    pickupSlot = other.pickupSlot;
    vehicle = other.vehicle;
    weighedAt = other.weighedAt;
    weighNote = other.weighNote;
    weighPhotoUrl = other.weighPhotoUrl;
    rejectReason = other.rejectReason;
    originalWeighedKg = other.originalWeighedKg;
    correctionReason = other.correctionReason;
    earnedPointsOverride = other.earnedPointsOverride;
    timeline
      ..clear()
      ..addAll(other.timeline);
  }

  /// Poin final dari server (memakai poin per kg saat ditimbang).
  int? earnedPointsOverride;

  /// Tandai langkah garis waktu yang judulnya diawali [prefix] sebagai selesai.
  void completeStep(String prefix, String time, {String? title}) {
    final i = timeline.indexWhere((s) => s.title.startsWith(prefix));
    if (i < 0) return;
    timeline[i] = TimelineStep(title ?? timeline[i].title, time, done: true);
  }
}

class TimelineStep {
  const TimelineStep(this.title, this.time, {this.done = false});
  final String title;
  final String time;
  final bool done;
}

enum RewardCategory {
  voucher('Voucher', AppColors.emeraldSoft, AppColors.emeraldDeep),
  eWallet('E-Wallet', AppColors.blueSoft, AppColors.blueDeep),
  sembako('Sembako', AppColors.amberSoft, AppColors.amberDeep),
  bibit('Bibit', AppColors.violetSoft, AppColors.violetDeep);

  const RewardCategory(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

class Reward {
  const Reward({
    required this.id,
    required this.initials,
    required this.name,
    required this.category,
    required this.points,
    required this.stock,
    required this.description,
    this.serverId,
    this.isActive = true,
  });

  /// Kode hadiah, misalnya `RW-VB10`.
  final String id;
  final String initials;
  final String name;
  final RewardCategory category;
  final int points;
  final int stock;
  final String description;

  /// ID di server; null selama memakai data contoh.
  final int? serverId;
  final bool isActive;
}

enum RedemptionStatus {
  processing('Diproses', AppColors.amberSoft, AppColors.amberDeep),
  shipped('Dikirim', AppColors.blueSoft, AppColors.blueDeep),
  done('Selesai', AppColors.emeraldSoft, AppColors.emeraldDeep);

  const RedemptionStatus(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

class Redemption {
  Redemption({
    required this.id,
    required this.reward,
    required this.address,
    required this.createdAt,
    required this.status,
    this.trackingNumber,
  });

  final String id;
  final Reward reward;
  final String address;
  final DateTime createdAt;
  RedemptionStatus status;
  String? trackingNumber;
}

class CustomerProfile implements CustomerRef {
  CustomerProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.phone,
    required this.email,
    required this.address,
    required this.tier,
  });

  @override
  final String id;
  @override
  String name;
  @override
  String initials;
  @override
  String phone;
  String email;
  @override
  String address;
  final String tier;
}

class AppNotification {
  AppNotification(this.title, this.body, this.time, {this.read = false});

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    j['title'] as String? ?? '',
    j['body'] as String? ?? '',
    DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    read: j['read'] as bool? ?? false,
  );

  final String title;
  final String body;
  final DateTime time;
  bool read;
}
