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

/// Jenis sampah rinci dan poin per kg sesuai tabel usulan PRD. Nantinya
/// diambil dari API karena perusahaan bisa mengubahnya.
enum WasteType {
  petBening(
    WasteGroup.plastik,
    'Botol PET bening',
    'Botol air mineral, botol minuman',
    500,
  ),
  plastikKeras(
    WasteGroup.plastik,
    'Plastik keras',
    'Galon, ember, botol sampo',
    400,
  ),
  plastikLembaran(
    WasteGroup.plastik,
    'Plastik lembaran',
    'Kantong kresek, bungkus makanan',
    100,
  ),
  kardus(WasteGroup.kertas, 'Kardus', 'Kotak kemasan, karton', 300),
  kertasPutih(WasteGroup.kertas, 'Kertas putih', 'HVS, arsip', 300),
  kertasCampur(WasteGroup.kertas, 'Kertas campur', 'Koran, majalah, buku', 200),
  kalengAluminium(
    WasteGroup.kaleng,
    'Kaleng aluminium',
    'Kaleng minuman',
    1500,
  ),
  kalengBesi(
    WasteGroup.kaleng,
    'Kaleng besi',
    'Kaleng susu, kaleng sarden',
    300,
  ),
  botolKaca(
    WasteGroup.kaca,
    'Botol kaca utuh',
    'Botol kecap, botol sirup',
    100,
  ),
  pecahanKaca(WasteGroup.kaca, 'Pecahan kaca', 'Beling', 50);

  const WasteType(this.group, this.label, this.examples, this.pointsPerKg);

  final WasteGroup group;
  final String label;
  final String examples;
  final int pointsPerKg;

  IconData get icon => group.icon;

  /// Untuk di tengah kalimat: "botol PET bening", singkatan tetap kapital.
  String get lowerLabel => label[0].toLowerCase() + label.substring(1);

  // Alias untuk kode lama yang memakai nama kelompok.
  static const plastik = petBening;
  static const kertas = kardus;
  static const kaleng = kalengAluminium;
  static const kaca = botolKaca;

  /// Poin dibulatkan ke bawah (aturan PRD).
  int pointsFor(double kg) => (kg * pointsPerKg).floor();
}

class Partner {
  const Partner({
    required this.id,
    required this.name,
    required this.initials,
    required this.distanceKm,
    required this.address,
    required this.area,
    required this.hours,
    this.accepts = WasteType.values,
  });

  final String id;
  final String name;
  final String initials;
  final double distanceKm;
  final String address;
  final String area;
  final String hours;
  final List<WasteType> accepts;
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
  final List<TimelineStep> timeline;

  int get estimatedPoints => type.pointsFor(estimatedKg);

  /// Poin final hanya ada setelah mitra menimbang.
  int? get earnedPoints =>
      weighedKg == null ? null : type.pointsFor(weighedKg!);

  bool get isActive =>
      status != DepositStatus.verified && status != DepositStatus.rejected;

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
  });

  final String id;
  final String initials;
  final String name;
  final RewardCategory category;
  final int points;
  final int stock;
  final String description;
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
  final String title;
  final String body;
  final DateTime time;
  bool read;
}
