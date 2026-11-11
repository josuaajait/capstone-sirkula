import 'package:capstone/app/api/api_client.dart';
import 'package:capstone/app/format.dart';
import 'package:capstone/app/session.dart';
import 'package:capstone/customer/data/customer_store.dart';
import 'package:capstone/customer/data/models.dart';
import 'package:capstone/main.dart';
import 'package:capstone/partner/data/partner_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<CustomerStore> pumpApp(WidgetTester tester) async {
  final (store, _) = await pumpBoth(tester, role: UserRole.customer);
  return store;
}

Future<(CustomerStore, PartnerStore)> pumpBoth(
  WidgetTester tester, {
  UserRole? role,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = CustomerStore();
  final partner = PartnerStore(store);
  await tester.pumpWidget(
    SirkulaApp(customerStore: store, partnerStore: partner, initialRole: role),
  );
  await tester.pumpAndSettle();
  return (store, partner);
}

void main() {
  group('PartnerStore', () {
    test('permintaan customer sampai ke mitra lalu poin masuk', () async {
      final customer = CustomerStore();
      final partner = PartnerStore(customer);
      final before = partner.requests.length;
      final d = await customer.submitDeposit(
        partner: customer.partner,
        type: WasteType.plastik,
        estimatedKg: 5,
        method: DepositMethod.pickup,
        pickupDate: DateTime.now().add(const Duration(days: 1)),
        pickupSlot: pickupSlots.first,
        address: 'Jl. Contoh No. 1',
      );
      expect(partner.requests.length, before + 1);
      expect(partner.notifications.first.title, 'Permintaan setoran baru');

      expect(await partner.accept(d, vehicle: partner.vehicles.first), isTrue);
      expect(d.status, DepositStatus.scheduled);
      final notifCount = customer.notifications.length;
      expect(await partner.accept(d), isFalse); // ketukan ganda tidak diproses
      expect(await partner.reject(d, 'x'), isFalse);
      expect(customer.notifications.length, notifCount);
      expect(d.vehicle, 'Pikap · B 9124 KX');
      expect(customer.notifications.first.title, 'Jadwal jemput dikonfirmasi');

      await partner.depart(d);
      expect(d.status, DepositStatus.onTheWay);

      final pointsBefore = customer.points;
      await partner.recordWeighing(
        request: d,
        customer: d.customer,
        type: WasteType.plastik,
        kg: 4.84,
      );
      expect(d.weighedKg, 4.8); // dibulatkan ke 0,1 kg
      expect(d.status, DepositStatus.verified);
      expect(customer.points, pointsBefore + 2400);
      expect(d.timeline.every((s) => s.done), isTrue);
    });

    test('setoran datang langsung dan cari customer', () async {
      final partner = PartnerStore(CustomerStore());
      final c2 = partner.findCustomer('0812 0000 0102')!;
      expect(c2.name, 'Customer 2');
      expect(partner.findCustomer('cst-0003')!.name, 'Customer 3');
      expect(partner.findCustomer('0899'), isNull);

      final balance = partner.balanceOf(c2);
      final d = await partner.recordWeighing(
        customer: c2,
        type: WasteType.kaleng,
        kg: 1.25,
      );
      expect(d.earnedPoints, WasteType.kaleng.pointsFor(1.3));
      expect(partner.balanceOf(c2), balance + d.earnedPoints!);
      expect(partner.deposits.first.id, d.id);
      await expectLater(
        () => partner.recordWeighing(
          customer: c2,
          type: WasteType.kaca,
          kg: maxWeighKg + 1,
        ),
        throwsArgumentError,
      );
    });

    test('tolak permintaan menyimpan alasan', () async {
      final partner = PartnerStore(CustomerStore());
      final d = partner.requests.first;
      await partner.reject(d, rejectReasons.first);
      expect(d.status, DepositStatus.rejected);
      expect(d.rejectReason, rejectReasons.first);
      expect(partner.requests.contains(d), isFalse);
    });

    test('koreksi berat menyesuaikan poin dengan tarif lama', () async {
      final customer = CustomerStore();
      final partner = PartnerStore(customer);
      final me = customer.profile;
      final d = await partner.recordWeighing(
        customer: me,
        type: WasteType.petBening,
        kg: 8.4,
      );
      final balance = customer.points;
      expect(d.canCorrect, isTrue);

      WasteType.petBening.pointsPerKg = 999; // tarif berubah setelah timbang
      addTearDown(WasteType.resetToDefaults);
      await partner.correctWeight(d, 4.8, 'Salah ketik angka');
      expect(d.weighedKg, 4.8);
      expect(d.originalWeighedKg, 8.4);
      expect(d.earnedPoints, 2400);
      expect(customer.points, balance - 1800);
      expect(customer.notifications.first.title, 'Berat setoran dikoreksi');

      // Tidak boleh membuat saldo negatif.
      customer.points = 0;
      await expectLater(
        partner.correctWeight(d, 0.1, 'Salah ketik lagi'),
        throwsA(isA<ApiException>()),
      );
      expect(d.weighedKg, 4.8);

      d.weighedAt = DateTime.now().subtract(const Duration(days: 8));
      expect(d.canCorrect, isFalse);
    });
  });

  testWidgets('masuk dengan akun mitra membuka beranda mitra', (tester) async {
    await pumpBoth(tester);
    expect(find.text('Selamat Datang!'), findsOneWidget);
    expect(find.text('Masuk sebagai Customer'), findsOneWidget);

    await tester.ensureVisible(find.text('Isi BSI Ias Toba'));
    await tester.tap(find.text('Isi BSI Ias Toba'));
    await tester.pump();
    // Tombol akun demo ikut memilih peran yang sesuai.
    expect(find.text('Masuk sebagai Mitra'), findsOneWidget);
    await tester.ensureVisible(find.text('MASUK'));
    await tester.tap(find.text('MASUK'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang, BSI Ias Toba'), findsOneWidget);
  });

  testWidgets('peran yang dipilih harus sama dengan peran akun', (
    tester,
  ) async {
    await pumpBoth(tester);
    await tester.enterText(find.byType(TextFormField).first, '081200000001');
    await tester.enterText(find.byType(TextFormField).last, 'sirkula123');
    await tester.ensureVisible(find.text('MASUK'));
    await tester.tap(find.text('MASUK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('terdaftar sebagai Mitra'), findsOneWidget);

    await tester.ensureVisible(find.text('Masuk sebagai Customer'));
    await tester.tap(find.text('Masuk sebagai Customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mitra').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('MASUK'));
    await tester.tap(find.text('MASUK'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang, BSI Ias Toba'), findsOneWidget);
  });

  testWidgets('akun perusahaan menunggu peran Admin', (tester) async {
    await pumpBoth(tester);
    await tester.enterText(find.byType(TextFormField).first, 'staf@sirkula.id');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia');
    await tester.ensureVisible(find.text('MASUK'));
    await tester.tap(find.text('MASUK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Peran Admin'), findsOneWidget);
  });

  testWidgets('mitra mencatat timbangan customer yang datang', (tester) async {
    final (_, partner) = await pumpBoth(tester, role: UserRole.partner);
    final c2 = partner.findCustomer('CST-0002')!;
    final balance = partner.balanceOf(c2);

    await tester.tap(find.text('Timbang'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'CST-0002');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();
    expect(find.text('Customer 2'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('weigh-kg')), '4,8');
    await tester.pumpAndSettle();
    final review = find.text('Tinjau & Simpan');
    await tester.scrollUntilVisible(
      review,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2.400 poin'), findsOneWidget);
    await tester.tap(review);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Timbangan'));
    await tester.pumpAndSettle();
    expect(partner.balanceOf(c2), balance + 2400);
    expect(find.text('Catat Setoran Lain'), findsOneWidget);
  });

  testWidgets('mitra menerima permintaan antar sendiri', (tester) async {
    final (_, partner) = await pumpBoth(tester, role: UserRole.partner);
    final dropOff = partner.requests.firstWhere(
      (d) => d.method == DepositMethod.dropOff,
    );

    await tester.tap(find.text('Permintaan').last);
    await tester.pumpAndSettle();
    final accept = find.widgetWithText(FilledButton, 'Terima');
    await tester.scrollUntilVisible(
      accept,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(accept);
    await tester.pumpAndSettle();
    await tester.tap(accept);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terima').last); // tombol di dialog
    await tester.pumpAndSettle();
    expect(dropOff.status, DepositStatus.scheduled);
    expect(partner.readyToWeigh.contains(dropOff), isTrue);
  });

  group('format', () {
    test('angka dan berat gaya Indonesia', () {
      expect(formatNumber(24500), '24.500');
      expect(formatNumber(-10000), '-10.000');
      expect(formatKg(8.4), '8,4 kg');
      expect(formatKg(8), '8 kg');
      expect(parseKg('8,5'), 8.5);
    });
  });

  group('CustomerStore', () {
    test('poin dibulatkan ke bawah', () {
      expect(WasteType.plastik.pointsFor(4.8), 2400);
      expect(WasteType.kaca.pointsFor(0.15), 15);
    });

    test('penukaran memotong saldo dan menolak saldo kurang', () async {
      final store = CustomerStore();
      final bibit = store.rewards.firstWhere((r) => r.points == 18000);
      final sembako = store.rewards.firstWhere((r) => r.points == 72000);
      expect(await store.redeem(sembako, 'Jl. Contoh No. 1'), isNull);
      expect(await store.redeem(bibit, 'Jl. Contoh No. 1'), isNotNull);
      expect(store.points, 24500 - 18000);
    });

    test('setoran baru menunggu mitra dan masuk riwayat', () async {
      final store = CustomerStore();
      final d = await store.submitDeposit(
        partner: store.partner,
        type: WasteType.kertas,
        estimatedKg: 3,
        method: DepositMethod.dropOff,
      );
      expect(d.status, DepositStatus.waiting);
      expect(d.earnedPoints, isNull);
      expect(store.activities.first.id, d.id);
    });
  });

  testWidgets('beranda tampil dan bottom nav berpindah tab', (tester) async {
    await pumpApp(tester);
    expect(find.text('Halo, Customer 1'), findsOneWidget);
    expect(find.text('24.500'), findsOneWidget);

    await tester.tap(find.text('Hadiah'));
    await tester.pumpAndSettle();
    expect(find.text('Hadiah Untuk Anda'), findsOneWidget);

    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
  });

  testWidgets('setor sampah: tinjau lalu kirim', (tester) async {
    final store = await pumpApp(tester);
    final before = store.deposits.length;

    await tester.tap(find.text('Setor'));
    await tester.pumpAndSettle();
    final submit = find.text('Kirim Pengajuan ke BSI Ias Toba');
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Tinjau Setoran'), findsOneWidget);

    await tester.tap(find.text('Konfirmasi & Kirim'));
    await tester.pumpAndSettle();
    expect(store.deposits.length, before + 1);
    expect(store.deposits.first.estimatedKg, 8);
  });

  testWidgets('tukar hadiah dari halaman detail', (tester) async {
    final store = await pumpApp(tester);
    await tester.tap(find.text('Hadiah'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bibit Tanaman'));
    await tester.pumpAndSettle();
    expect(find.text('6.500 poin'), findsOneWidget); // sisa saldo

    await tester.tap(find.text('Tukar Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi Penukaran').last);
    await tester.pumpAndSettle();
    expect(store.points, 6500);
    expect(store.redemptions.first.reward.name, 'Bibit Tanaman');
  });
}
