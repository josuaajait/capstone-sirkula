// Uji ujung ke ujung terhadap API Laravel sungguhan.
//
// Jalankan server dengan database contoh yang baru di-seed, lalu:
//   flutter test test/e2e_api_test.dart --dart-define=E2E_API=http://127.0.0.1:8000/api
// Tanpa E2E_API, tes ini dilewati.
import 'dart:convert';

import 'package:capstone/admin/admin_store.dart';
import 'package:capstone/app/api/api_client.dart';
import 'package:capstone/app/auth_service.dart';
import 'package:capstone/app/session.dart';
import 'package:capstone/customer/data/customer_store.dart';
import 'package:capstone/customer/data/models.dart';
import 'package:capstone/partner/data/partner_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _url = String.fromEnvironment('E2E_API');

Future<(ApiClient, SignedIn)> _login(String id) async {
  final api = ApiClient(_url);
  final signed = await ApiAuthService(api).login(id, 'sirkula123');
  return (api, signed);
}

void main() {
  tearDown(WasteType.resetToDefaults);

  test(
    'siklus penuh: setor, terima, jemput, timbang, poin, tukar, kirim hadiah',
    () async {
      // Customer mengirim permintaan jemput.
      final (cApi, cUser) = await _login('customer1@example.com');
      expect(cUser.role, UserRole.customer);
      final customer = CustomerStore();
      await customer.connect(cApi, cUser.user!);
      expect(customer.isRemote, isTrue);
      expect(customer.rewards, isNotEmpty);
      expect(WasteType.petBening.serverId, isNotNull);
      final pointsBefore = customer.points;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final sent = await customer.submitDeposit(
        partner: customer.partner,
        type: WasteType.petBening,
        estimatedKg: 5,
        method: DepositMethod.pickup,
        pickupDate: tomorrow,
        pickupSlot: pickupSlots.first,
        address: 'Jl. Uji Coba No. 1, Balige',
        note: 'tes e2e',
      );
      expect(sent.status, DepositStatus.waiting);
      expect(customer.deposits.first.id, sent.id);

      // Mitra menerima, berangkat, lalu menimbang.
      final (pApi, pUser) = await _login('081200000001');
      expect(pUser.role, UserRole.partner);
      final partner = PartnerStore(CustomerStore());
      await partner.connect(pApi, pUser.user!);
      final req = partner.requests.firstWhere((d) => d.id == sent.id);
      expect(req.customer.name, 'Customer 1');
      expect(partner.vehicles, isNotEmpty);

      expect(
        await partner.accept(
          req,
          date: tomorrow,
          slot: pickupSlots.first,
          vehicle: partner.vehicles.first,
        ),
        isTrue,
      );
      expect(req.status, DepositStatus.scheduled);
      expect(await partner.accept(req), isFalse); // sudah ditangani

      await partner.depart(req);
      expect(req.status, DepositStatus.onTheWay);

      final weighed = await partner.recordWeighing(
        request: req,
        customer: req.customer,
        type: WasteType.petBening,
        kg: 4.84,
      );
      expect(weighed.status, DepositStatus.verified);
      expect(weighed.weighedKg, 4.8);
      expect(weighed.earnedPoints, 2400);

      // Mitra mengoreksi berat yang salah catat; poin ikut turun.
      final corrected = await partner.correctWeight(
        req,
        4.0,
        'Salah baca timbangan',
      );
      expect(corrected.earnedPoints, 2000);
      expect(corrected.originalWeighedKg, 4.8);
      await partner.correctWeight(req, 4.8, 'Timbang ulang, ternyata benar');
      expect(req.earnedPoints, 2400);

      // Mitra mengunggah foto timbangan; customer bisa membukanya.
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );
      await partner.uploadPhoto(req, png, 'timbang.png');
      expect(req.weighPhotoUrl, contains('/api/media/weigh-photos/'));
      final photo = await http.get(Uri.parse(req.weighPhotoUrl!));
      expect(photo.statusCode, 200);
      expect(photo.bodyBytes.length, greaterThan(0));

      // Customer melihat poin masuk.
      await customer.refresh();
      expect(customer.points, pointsBefore + 2400);
      final mine = customer.depositById(sent.id)!;
      expect(identical(mine, sent), isTrue); // objek lama diperbarui
      expect(mine.status, DepositStatus.verified);
      expect(mine.timeline.every((s) => s.done), isTrue);
      expect(customer.notifications.first.title, isNotEmpty);

      // Mitra mencatat customer yang datang langsung.
      final c3 = await partner.lookupCustomer('CST-0003');
      expect(c3, isNotNull);
      final balance = partner.balanceOf(c3!);
      final walkIn = await partner.recordWeighing(
        customer: c3,
        type: WasteType.kalengAluminium,
        kg: 1.3,
      );
      expect(walkIn.earnedPoints, 1950);
      expect(partner.balanceOf(c3), balance + 1950);
      expect(await partner.lookupCustomer('0899999999'), isNull);

      // Customer menukar poin; saldo kurang ditolak.
      final mahal = Reward(
        id: 'x',
        initials: 'X',
        name: 'x',
        category: RewardCategory.voucher,
        points: customer.points + 1,
        stock: 1,
        description: '',
        serverId: customer.rewards.first.serverId,
      );
      expect(await customer.redeem(mahal, 'Jl. Uji'), isNull);
      final voucher = customer.rewards.firstWhere((r) => r.id == 'RW-VB10');
      final before = customer.points;
      final redemption = await customer.redeem(voucher, 'Jl. Uji Coba No. 1');
      expect(redemption, isNotNull);
      expect(customer.points, before - voucher.points);

      // Admin memproses penukaran dan melihat laporan.
      final (aApi, aUser) = await _login('admin@sirkula.id');
      expect(aUser.role, UserRole.admin);
      final admin = AdminStore();
      await admin.connect(aApi, aUser.user!);
      expect(admin.summary!.kgThisMonth, greaterThan(0));
      final item = admin.redemptions.firstWhere(
        (r) => r.redemption.id == redemption!.id,
      );
      await admin.shipRedemption(item, 'RESI-E2E-1');
      final shipped = admin.redemptions.firstWhere(
        (r) => r.redemption.id == redemption!.id,
      );
      expect(shipped.redemption.status, RedemptionStatus.shipped);
      await admin.completeRedemption(shipped);

      await customer.refresh();
      expect(
        customer.redemptions.firstWhere((r) => r.id == redemption!.id).status,
        RedemptionStatus.done,
      );

      await admin.loadDeposits(search: sent.id);
      expect(admin.deposits.single.id, sent.id);

      final now = DateTime.now();
      final report = await admin.loadReport(DateTime(now.year, now.month), now);
      expect(report.kg, greaterThan(0));
      for (final format in ['csv', 'pdf']) {
        final link = await admin.reportLink(
          DateTime(now.year, now.month),
          now,
          format,
        );
        final res = await http.get(link); // tanpa token
        expect(res.statusCode, 200, reason: format);
        expect(res.body, contains('Laporan Sirkula'));
      }

      // Ubah poin per kg lalu kembalikan.
      final kardus = admin.wasteTypes.firstWhere((t) => t.code == 'kardus');
      final old = kardus.pointsPerKg;
      await admin.updateWasteType(
        kardus,
        pointsPerKg: old + 50,
        isActive: true,
      );
      expect(WasteType.kardus.pointsPerKg, old + 50);
      await admin.updateWasteType(kardus, pointsPerKg: old, isActive: true);

      await ApiAuthService(cApi).logout();
      await expectLater(
        cApi.get('/customer/summary'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    },
    skip: _url.isEmpty
        ? 'Set --dart-define=E2E_API=... untuk menjalankan'
        : false,
    timeout: const Timeout(Duration(minutes: 6)),
  );

  test(
    'daftar, lupa kata sandi, dan peran tidak cocok',
    () async {
      final api = ApiClient(_url);
      final auth = ApiAuthService(api);
      final stamp = DateTime.now().millisecondsSinceEpoch % 100000000;
      final email = 'e2e$stamp@mail.com';
      final signed = await auth.register(
        name: 'Uji Daftar',
        email: email,
        phone: '0813${stamp.toString().padLeft(8, '0')}',
        address: 'Jl. Daftar No. 2',
        password: 'rahasia123',
      );
      expect(signed.role, UserRole.customer);
      await expectLater(
        auth.register(
          name: 'Uji Daftar',
          email: email,
          phone: '081399999999',
          address: 'Jl. Daftar',
          password: 'rahasia123',
        ),
        throwsA(isA<AuthException>()),
      );

      final code = await auth.requestReset(email);
      expect(code, isNotNull, reason: 'server harus APP_DEBUG=true');
      await auth.resetPassword(email, code!, 'baru12345');
      await expectLater(
        auth.login(email, 'rahasia123'),
        throwsA(isA<AuthException>()),
      );
      expect((await auth.login(email, 'baru12345')).role, UserRole.customer);

      final restored = await auth.restore(api.token!);
      expect(restored?.email, email);
      expect(await auth.restore('token-salah'), isNull);
    },
    skip: _url.isEmpty
        ? 'Set --dart-define=E2E_API=... untuk menjalankan'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
