import 'package:capstone/app/session.dart';
import 'package:capstone/customer/data/customer_store.dart';
import 'package:capstone/customer/pages/deposit_detail_page.dart';
import 'package:capstone/customer/data/models.dart';
import 'package:capstone/customer/widgets/deposit_chart.dart';
import 'package:capstone/main.dart';
import 'package:capstone/partner/data/partner_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membuka aplikasi sebagai customer pada lebar layar tertentu.
Future<CustomerStore> pumpCustomer(
  WidgetTester tester, {
  double width = 390,
  UserRole? role = UserRole.customer,
}) async {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = CustomerStore();
  await tester.pumpWidget(
    SirkulaApp(
      customerStore: store,
      partnerStore: PartnerStore(store),
      initialRole: role,
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  // Taruh di tengah layar agar tidak tertutup app bar/navigasi bawah.
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(resetAccountRegistry);

  group('akun', () {
    test('daftar, masuk, dan tolak data ganda', () {
      expect(
        registerCustomer(
          name: 'Budi Santoso',
          email: 'Budi@Mail.com',
          phone: '+62 813 1111 2222',
          address: 'Jl. Melati No. 5, Bandung',
          password: 'rahasia123',
        ),
        isNull,
      );
      expect(
        authenticate('budi@mail.com', 'rahasia123')?.label,
        'Budi Santoso',
      );
      expect(authenticate('081311112222', 'rahasia123'), isNotNull);
      expect(authenticate('budi@mail.com', DemoAccount.password), isNull);
      expect(
        registerCustomer(
          name: 'Lain',
          email: 'lain@mail.com',
          phone: '081311112222',
          address: 'Jl. Melati No. 6, Bandung',
          password: 'rahasia123',
        ),
        contains('sudah terdaftar'),
      );
      expect(
        registerCustomer(
          name: 'Staf',
          email: 'admin@sirkula.id',
          phone: '081399998888',
          address: 'Kantor Sirkula, Jakarta',
          password: 'rahasia123',
        ),
        isNotNull,
      );
    });

    test('aturan kata sandi', () {
      expect(validatePassword('pendek1'), isNotNull);
      expect(validatePassword('tanpaangka'), isNotNull);
      expect(validatePassword('benar1234'), isNull);
    });

    test('ganti kata sandi akun demo', () {
      final a = findAccount('customer1@example.com')!;
      resetAccountPassword(a, 'baru12345');
      expect(authenticate(a.email, DemoAccount.password), isNull);
      expect(authenticate(a.email, 'baru12345'), isNotNull);
    });

    test('akun baru mulai dengan saldo dan riwayat kosong', () {
      final store = CustomerStore();
      store.signInAs(
        email: 'budi@mail.com',
        name: 'Budi Santoso',
        phone: '081311112222',
        address: 'Jl. Melati No. 5, Bandung',
      );
      expect(store.points, 0);
      expect(store.deposits, isEmpty);
      expect(store.profile.initials, 'BS');
      store.signInAs(
        email: CustomerStore.demoEmail,
        name: 'Customer 1',
        phone: '',
        address: '',
      );
      expect(store.points, 24500);
      expect(store.deposits, isNotEmpty);
    });
  });

  test('jenis sampah rinci mengikuti tabel PRD', () {
    expect(WasteType.values.length, 10);
    expect(WasteGroup.kaleng.types.length, 2);
    expect(WasteType.kalengBesi.pointsFor(2.5), 750);
    expect(WasteType.pecahanKaca.pointsFor(0.3), 15);
    expect(WasteType.petBening.lowerLabel, 'botol PET bening');
  });

  testWidgets('daftar dari halaman masuk lalu langsung masuk', (tester) async {
    await pumpCustomer(tester, role: null);
    await scrollToAndTap(tester, find.text('Daftar Disini'));
    final fields = find.byType(TextFormField);
    const values = [
      'Budi Santoso',
      'budi@mail.com',
      '081311112222',
      'Jl. Melati No. 5, Bandung',
      'rahasia123',
      'rahasia123',
    ];
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(fields.at(i), values[i]);
    }
    await scrollToAndTap(tester, find.byType(CheckboxListTile));
    await scrollToAndTap(tester, find.widgetWithText(FilledButton, 'Daftar'));
    expect(find.text('Halo, Budi Santoso'), findsOneWidget);
    expect(find.text('0'), findsWidgets); // saldo awal
  });

  testWidgets('lupa kata sandi lalu masuk dengan sandi baru', (tester) async {
    await pumpCustomer(tester, role: null);
    await scrollToAndTap(tester, find.text('Lupa Kata Sandi?'));
    await tester.enterText(find.byType(TextFormField), 'customer1@example.com');
    await tester.tap(find.text('Kirim Kode'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '000000');
    await tester.enterText(fields.at(1), 'baru12345');
    await tester.enterText(fields.at(2), 'baru12345');
    await scrollToAndTap(tester, find.text('Simpan Kata Sandi'));
    expect(find.text('Kode verifikasi salah.'), findsOneWidget);

    await tester.enterText(fields.at(0), demoResetCode);
    await scrollToAndTap(tester, find.text('Simpan Kata Sandi'));
    expect(
      find.text('Kata sandi berhasil diganti. Silakan masuk.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(1), 'baru12345');
    await scrollToAndTap(tester, find.widgetWithText(FilledButton, 'MASUK'));
    expect(find.text('Halo, Customer 1'), findsOneWidget);
  });

  testWidgets('pilih kelompok kaleng memunculkan jenis rinci', (tester) async {
    await pumpCustomer(tester);
    await tester.tap(find.text('Setor'));
    await tester.pumpAndSettle();
    await scrollToAndTap(tester, find.widgetWithText(ChoiceChip, 'Kaleng'));
    expect(find.text('Kaleng aluminium'), findsOneWidget);
    await scrollToAndTap(tester, find.text('Kaleng besi'));
    final estimate = find.textContaining('300 poin/kg (Kaleng besi)');
    await tester.scrollUntilVisible(
      estimate,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(estimate, findsOneWidget);
  });

  testWidgets('detail setoran terverifikasi menampilkan bukti timbang', (
    tester,
  ) async {
    final store = CustomerStore();
    final d = store.deposits.firstWhere(
      (d) => d.status == DepositStatus.verified,
    );
    await tester.pumpWidget(
      CustomerScope(
        store: store,
        child: MaterialApp(home: DepositDetailPage(deposit: d)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bukti Timbang'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Foto timbangan belum diunggah mitra.'), findsOneWidget);
  });

  test('grafik menjumlahkan setoran terverifikasi per bulan', () {
    final store = CustomerStore();
    final now = DateTime(2026, 11, 20);
    final partner = store.partner;
    Deposit dep(DateTime date, double kg, DepositStatus status) => Deposit(
      id: 'X',
      customer: store.profile,
      partner: partner,
      type: WasteType.plastik,
      estimatedKg: kg,
      weighedKg: status == DepositStatus.verified ? kg : null,
      method: DepositMethod.dropOff,
      createdAt: date,
      status: status,
    );
    final data = DepositChart.monthlyKg([
      dep(DateTime(2026, 11, 2), 3.5, DepositStatus.verified),
      dep(DateTime(2026, 11, 9), 1.5, DepositStatus.verified),
      dep(DateTime(2026, 11, 10), 9, DepositStatus.waiting), // belum ditimbang
      dep(DateTime(2026, 7, 1), 2, DepositStatus.verified),
      dep(DateTime(2026, 1, 1), 50, DepositStatus.verified), // di luar 6 bulan
    ], now);
    expect(data.length, 6);
    expect(data.first.$1, DateTime(2026, 6));
    expect(data.last.$2, 5.0);
    expect(data[1].$2, 2.0); // Juli
    expect(data.fold(0.0, (s, e) => s + e.$2), 7.0);
  });

  testWidgets('beranda menampilkan grafik setoran', (tester) async {
    await pumpCustomer(tester);
    final title = find.text('Setoran 6 Bulan Terakhir');
    await tester.scrollUntilVisible(
      title,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(title, findsOneWidget);
  });

  testWidgets('isian berat hanya menerima satu angka desimal', (tester) async {
    await pumpCustomer(tester);
    await tester.tap(find.text('Setor'));
    await tester.pumpAndSettle();

    final field = find.byWidgetPredicate(
      (w) => w is EditableText && w.controller.text == '8',
    );
    await tester.scrollUntilVisible(
      field,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final controller = tester.widget<EditableText>(field).controller;
    await tester.enterText(field, '8,57');
    await tester.pump();
    final text = controller.text;
    expect(text, isNot('8,57'));
    expect(RegExp(r'^\d+([.,]\d)?$').hasMatch(text), isTrue);
  });

  testWidgets('profil membuka pengaturan dan bantuan', (tester) async {
    await pumpCustomer(tester);
    await tester.tap(find.text('C1').first);
    await tester.pumpAndSettle();

    await scrollToAndTap(tester, find.text('Pengaturan'));
    expect(find.text('Notifikasi Aplikasi'), findsOneWidget);
    await tester.tap(find.text('Info & promo'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await scrollToAndTap(tester, find.text('Bantuan'));
    expect(find.text('Pertanyaan Umum'), findsOneWidget);
    await tester.tap(find.text('Apakah poin bisa hangus?'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak. Poin tidak punya masa berlaku.'), findsOneWidget);
  });

  testWidgets('semua tab customer muat di layar 360 px tanpa overflow', (
    tester,
  ) async {
    await pumpCustomer(tester, width: 360);
    for (final tab in ['Setor', 'Jemput', 'Hadiah', 'Riwayat', 'Beranda']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      // Gulir sampai bawah agar seluruh isi sempat di-render.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
  });
}
