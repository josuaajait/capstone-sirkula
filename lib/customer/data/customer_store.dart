import 'package:flutter/widgets.dart';

import '../../app/format.dart';

import 'models.dart';

/// Penyimpanan state customer di memori.
///
/// Backend Laravel belum ada, jadi semua data di sini adalah contoh. Saat API
/// siap, isi method di kelas ini diganti dengan panggilan HTTP tanpa perlu
/// mengubah halaman.
class CustomerStore extends ChangeNotifier {
  CustomerStore() {
    _seed();
  }

  /// Faktor emisi sementara (kg CO2e per kg sampah). PRD mencatat metode
  /// tCO2e belum ditetapkan, jadi angka ini hanya placeholder.
  static const co2PerKg = 1.5;

  final partners = const [
    Partner(
      id: 'M1',
      name: 'Mitra 1',
      initials: 'M1',
      distanceKm: 1.2,
      address: 'Jl. Contoh Industri No. 1',
      area: 'Jakarta Selatan',
      hours: 'Senin–Sabtu, 08.00–17.00',
    ),
    Partner(
      id: 'M2',
      name: 'Mitra 2',
      initials: 'M2',
      distanceKm: 2.4,
      address: 'Jl. Hijau Raya No. 8',
      area: 'Jakarta Selatan',
      hours: 'Senin–Jumat, 08.00–16.00',
    ),
    Partner(
      id: 'M3',
      name: 'Mitra 3',
      initials: 'M3',
      distanceKm: 3.1,
      address: 'Jl. Bersih Utama No. 12',
      area: 'Jakarta Selatan',
      hours: 'Setiap hari, 07.00–15.00',
    ),
  ];

  final rewards = const [
    Reward(
      id: 'RW-VB10',
      initials: 'VB',
      name: 'Voucher Belanja Rp10.000',
      category: RewardCategory.voucher,
      points: 10000,
      stock: 120,
      description: 'Voucher belanja digital yang bisa dipakai di minimarket rekanan. Kode voucher dikirim lewat notifikasi aplikasi.',
    ),
    Reward(
      id: 'RW-BT',
      initials: 'BT',
      name: 'Bibit Tanaman',
      category: RewardCategory.bibit,
      points: 18000,
      stock: 40,
      description: 'Satu paket bibit tanaman sayur atau buah beserta polybag dan media tanam. Dikirim ke alamat Anda.',
    ),
    Reward(
      id: 'RW-EW25',
      initials: 'EW',
      name: 'Saldo E-Wallet Rp25.000',
      category: RewardCategory.eWallet,
      points: 25500,
      stock: 60,
      description: 'Saldo e-wallet senilai Rp25.000 dikirim ke nomor ponsel yang terdaftar di akun Anda.',
    ),
    Reward(
      id: 'RW-PS',
      initials: 'PS',
      name: 'Paket Sembako',
      category: RewardCategory.sembako,
      points: 72000,
      stock: 15,
      description: 'Paket berisi beras 5 kg, minyak goreng 2 liter, gula 1 kg, dan telur 1 kg. Dikirim ke alamat Anda.',
    ),
  ];

  late CustomerProfile profile;
  int points = 24500;
  final List<Deposit> deposits = [];
  final List<Redemption> redemptions = [];
  final List<AppNotification> notifications = [];
  Partner? preferredPartner;

  int _depositSeq = 2;
  int _redeemSeq = 8;

  // ---------- Ringkasan untuk beranda ----------

  double get totalVerifiedKg => deposits
      .where((d) => d.status == DepositStatus.verified)
      .fold(0.0, (sum, d) => sum + (d.weighedKg ?? 0));

  double get co2AvoidedKg => totalVerifiedKg * co2PerKg;

  int get pointsThisMonth {
    final now = DateTime.now();
    return deposits
        .where(
          (d) =>
              d.status == DepositStatus.verified &&
              d.createdAt.year == now.year &&
              d.createdAt.month == now.month,
        )
        .fold(0, (sum, d) => sum + (d.earnedPoints ?? 0));
  }

  /// Penjemputan yang masih berjalan, paling awal lebih dulu.
  List<Deposit> get activePickups =>
      deposits
          .where((d) => d.method == DepositMethod.pickup && d.isActive)
          .toList()
        ..sort(
          (a, b) => (a.pickupDate ?? a.createdAt).compareTo(
            b.pickupDate ?? b.createdAt,
          ),
        );

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  /// Daftar aktivitas gabungan setoran dan penukaran, terbaru lebih dulu.
  List<Activity> get activities {
    final list = <Activity>[
      for (final d in deposits) Activity.deposit(d),
      for (final r in redemptions) Activity.redemption(r),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ---------- Aksi ----------

  Deposit submitDeposit({
    required Partner partner,
    required WasteType type,
    required double estimatedKg,
    required DepositMethod method,
    DateTime? pickupDate,
    String? pickupSlot,
    String? address,
    String? note,
  }) {
    final now = DateTime.now();
    final id = nextDepositId(now);
    final deposit = Deposit(
      id: id,
      customer: profile,
      partner: partner,
      type: type,
      estimatedKg: estimatedKg,
      method: method,
      createdAt: now,
      status: DepositStatus.waiting,
      pickupDate: pickupDate,
      pickupSlot: pickupSlot,
      address: address,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      timeline: [
        TimelineStep('Permintaan dikirim', formatStamp(now), done: true),
        TimelineStep('Diterima ${partner.name}', 'Menunggu'),
        if (method == DepositMethod.pickup) ...[
          const TimelineStep('Mitra menuju lokasi', 'Menunggu'),
          const TimelineStep('Sampah diambil & ditimbang', 'Menunggu'),
        ] else
          const TimelineStep('Sampah diantar & ditimbang', 'Menunggu'),
        const TimelineStep('Poin masuk ke saldo', 'Menunggu'),
      ],
    );
    deposits.insert(0, deposit);
    notifications.insert(
      0,
      AppNotification(
        'Permintaan setoran terkirim',
        '$id dikirim ke ${partner.name}. Anda akan diberi kabar setelah mitra menerima.',
        now,
      ),
    );
    notifyListeners();
    return deposit;
  }

  /// Menukar poin. Mengembalikan null jika saldo tidak cukup.
  Redemption? redeem(Reward reward, String address) {
    if (reward.points > points) return null;
    final now = DateTime.now();
    _redeemSeq++;
    points -= reward.points;
    final redemption = Redemption(
      id: 'RDM-${_yymmdd(now)}-${_redeemSeq.toString().padLeft(2, '0')}',
      reward: reward,
      address: address,
      createdAt: now,
      status: RedemptionStatus.processing,
    );
    redemptions.insert(0, redemption);
    notifications.insert(
      0,
      AppNotification(
        'Penukaran diproses',
        '${reward.name} akan dikirim dalam 1–2 hari kerja.',
        now,
      ),
    );
    notifyListeners();
    return redemption;
  }

  void updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    Partner? preferred,
  }) {
    profile
      ..name = name
      ..phone = phone
      ..email = email
      ..address = address
      ..initials = _initials(name);
    preferredPartner = preferred;
    notifyListeners();
  }

  // ---------- Dipanggil dari sisi mitra ----------
  //
  // Selama backend belum ada, aplikasi customer dan mitra berbagi data di
  // memori yang sama agar satu siklus setoran bisa dicoba dari ujung ke ujung.

  /// Nomor setoran berikutnya, contoh STR-240521-01.
  String nextDepositId([DateTime? at]) {
    _depositSeq++;
    return 'STR-${_yymmdd(at ?? DateTime.now())}-${_depositSeq.toString().padLeft(2, '0')}';
  }

  void pushNotification(String title, String body) {
    notifications.insert(0, AppNotification(title, body, DateTime.now()));
    notifyListeners();
  }

  /// Menambah setoran yang dicatat langsung oleh mitra (customer datang).
  void addDeposit(Deposit deposit) {
    deposits.insert(0, deposit);
    notifyListeners();
  }

  /// Poin dari hasil timbang mitra masuk ke saldo customer.
  void creditPoints(Deposit deposit) {
    final earned = deposit.earnedPoints ?? 0;
    points += earned;
    pushNotification(
      'Poin masuk',
      '${formatSignedPoints(earned)} poin dari setoran ${deposit.type.lowerLabel} ${formatKg(deposit.weighedKg ?? 0)} di ${deposit.partner.name}.',
    );
  }

  /// Memberi tahu halaman customer bahwa data setoran berubah.
  void touch() => notifyListeners();

  /// Email akun demo yang memakai data contoh.
  static const demoEmail = 'customer1@example.com';

  /// Mengganti customer yang sedang masuk. Akun demo memakai data contoh,
  /// akun baru mulai dari saldo dan riwayat kosong.
  void signInAs({
    required String email,
    required String name,
    required String phone,
    required String address,
  }) {
    if (profile.email == email) return;
    deposits.clear();
    redemptions.clear();
    notifications.clear();
    preferredPartner = null;
    if (email == demoEmail) {
      points = 24500;
      _depositSeq = 2;
      _redeemSeq = 8;
      _seed();
    } else {
      points = 0;
      _newAccountSeq++;
      profile = CustomerProfile(
        id: 'CST-${_newAccountSeq.toString().padLeft(4, '0')}',
        name: name,
        initials: _initials(name),
        phone: phone,
        email: email,
        address: address,
        tier: 'Member Baru',
      );
      notifications.add(
        AppNotification(
          'Selamat datang di Sirkula',
          'Pilih bank sampah mitra terdekat, lalu setor sampah pertama Anda untuk mendapat poin.',
          DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  int _newAccountSeq = 1;

  void markNotificationsRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  // ---------- Data contoh ----------

  void _seed() {
    final now = DateTime.now();
    DateTime daysAgo(int d, [int h = 10]) =>
        DateTime(now.year, now.month, now.day - d, h);

    profile = CustomerProfile(
      id: 'CST-0001',
      name: 'Customer 1',
      initials: 'C1',
      phone: '+62 812 0000 0101',
      email: 'customer1@example.com',
      address: 'Jl. Customer Hijau No. 10, Jakarta Selatan',
      tier: 'Member Hijau',
    );

    final pickupDay = DateTime(now.year, now.month, now.day + 2);
    deposits.addAll([
      Deposit(
        id: 'STR-${_yymmdd(daysAgo(1))}-02',
        customer: profile,
        partner: partners[0],
        type: WasteType.plastik,
        estimatedKg: 8,
        method: DepositMethod.pickup,
        createdAt: daysAgo(1, 14),
        status: DepositStatus.scheduled,
        pickupDate: pickupDay,
        pickupSlot: pickupSlots[0],
        address: 'Jl. Customer Hijau No. 10, Jakarta Selatan',
        vehicle: 'Pikap · B 9124 KX',
        timeline: [
          TimelineStep(
            'Permintaan dikirim',
            formatStamp(daysAgo(1, 14)),
            done: true,
          ),
          TimelineStep(
            'Diterima Mitra 1',
            formatStamp(daysAgo(1, 15)),
            done: true,
          ),
          const TimelineStep('Mitra menuju lokasi', 'Menunggu'),
          const TimelineStep('Sampah diambil & ditimbang', 'Menunggu'),
          const TimelineStep('Poin masuk ke saldo', 'Menunggu'),
        ],
      ),
      _verified(
        'STR-${_yymmdd(daysAgo(3))}-01',
        partners[0],
        WasteType.plastik,
        8.4,
        daysAgo(3),
      ),
      _verified(
        'STR-${_yymmdd(daysAgo(10))}-01',
        partners[1],
        WasteType.kaca,
        5.2,
        daysAgo(10),
      ),
      _verified(
        'STR-${_yymmdd(daysAgo(17))}-01',
        partners[2],
        WasteType.kaleng,
        2.4,
        daysAgo(17),
      ),
      _verified(
        'STR-${_yymmdd(daysAgo(30))}-01',
        partners[0],
        WasteType.kertas,
        20,
        daysAgo(30),
      ),
      _verified(
        'STR-${_yymmdd(daysAgo(44))}-01',
        partners[1],
        WasteType.plastik,
        12.6,
        daysAgo(44),
      ),
    ]);

    redemptions.add(
      Redemption(
        id: 'RDM-${_yymmdd(daysAgo(6))}-08',
        reward: rewards[0],
        address: profile.address,
        createdAt: daysAgo(6),
        status: RedemptionStatus.done,
        trackingNumber: 'Kode digital',
      ),
    );

    notifications.addAll([
      AppNotification(
        'Jadwal jemput dikonfirmasi',
        'Mitra 1 akan menjemput pada ${pickupSlots[0]} WIB.',
        daysAgo(1, 15),
      ),
      AppNotification(
        'Poin masuk',
        '+4.200 poin dari setoran plastik 8,4 kg di Mitra 1.',
        daysAgo(3, 16),
        read: true,
      ),
      AppNotification(
        'Hadiah terkirim',
        'Voucher Belanja Rp10.000 sudah dikirim.',
        daysAgo(5),
        read: true,
      ),
    ]);
  }

  Deposit _verified(
    String id,
    Partner partner,
    WasteType type,
    double kg,
    DateTime date,
  ) {
    return Deposit(
      id: id,
      customer: profile,
      partner: partner,
      type: type,
      estimatedKg: kg,
      weighedKg: kg,
      method: DepositMethod.dropOff,
      createdAt: date,
      status: DepositStatus.verified,
      timeline: [
        TimelineStep('Permintaan dikirim', formatStamp(date), done: true),
        TimelineStep('Diterima ${partner.name}', formatStamp(date), done: true),
        TimelineStep(
          'Sampah diantar & ditimbang',
          formatStamp(date),
          done: true,
        ),
        TimelineStep('Poin masuk ke saldo', formatStamp(date), done: true),
      ],
    );
  }

  static String _yymmdd(DateTime d) =>
      '${(d.year % 100).toString().padLeft(2, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

enum ActivityKind { deposit, redemption }

/// Satu baris riwayat: setoran atau penukaran.
class Activity {
  Activity.deposit(Deposit this.deposit)
    : kind = ActivityKind.deposit,
      redemption = null,
      date = deposit.createdAt;

  Activity.redemption(Redemption this.redemption)
    : kind = ActivityKind.redemption,
      deposit = null,
      date = redemption.createdAt;

  final ActivityKind kind;
  final Deposit? deposit;
  final Redemption? redemption;
  final DateTime date;

  String get id => deposit?.id ?? redemption!.id;
}

/// Memberi akses [CustomerStore] ke seluruh halaman customer.
class CustomerScope extends InheritedNotifier<CustomerStore> {
  const CustomerScope({
    super.key,
    required CustomerStore store,
    required super.child,
  }) : super(notifier: store);

  static CustomerStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CustomerScope>()!.notifier!;

  /// Akses tanpa ikut rebuild, untuk dipakai di dalam callback.
  static CustomerStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CustomerScope>()!.notifier!;
}
