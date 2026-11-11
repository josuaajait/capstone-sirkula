import 'dart:convert';
import 'dart:typed_data';

import 'package:capstone/app/api/api_client.dart';
import 'package:capstone/app/push_service.dart';
import 'package:capstone/customer/data/customer_store.dart';
import 'package:capstone/customer/data/models.dart';
import 'package:capstone/customer/pages/deposit_detail_page.dart';
import 'package:capstone/partner/data/partner_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// PNG 1×1 piksel.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

AppNotification _n(int id, {bool read = false}) =>
    AppNotification('Judul $id', 'Isi $id', DateTime(2026), id: id, read: read);

void main() {
  group('PushService', () {
    late List<int> shown;
    late PushService push;

    setUp(() {
      shown = [];
      push = PushService(display: (id, _, _) async => shown.add(id));
    });

    test('notifikasi lama tidak ditampilkan saat pertama masuk', () async {
      await push.onNotifications('customer:a', [_n(1), _n(2)]);
      expect(shown, isEmpty);
    });

    test('hanya notifikasi baru yang belum dibaca yang tampil', () async {
      await push.onNotifications('customer:a', [_n(1)]);
      await push.onNotifications('customer:a', [_n(3), _n(2, read: true), _n(1)]);
      expect(shown, [3]);
      // Muat ulang berikutnya tidak menampilkan ulang.
      await push.onNotifications('customer:a', [_n(3), _n(2, read: true), _n(1)]);
      expect(shown, [3]);
    });

    test('ganti akun mulai dari awal, dan paling banyak 3 sekaligus', () async {
      await push.onNotifications('customer:a', [_n(1)]);
      await push.onNotifications('partner:b', [_n(1), _n(9)]);
      expect(shown, isEmpty);
      await push.onNotifications('partner:b', [
        for (final id in [10, 11, 12, 13, 1, 9]) _n(id),
      ]);
      expect(shown, [10, 11, 12]);
    });
  });

  group('Foto timbangan', () {
    test('mode demo: foto tersimpan di HP dan terlihat customer', () async {
      final customer = CustomerStore();
      final partner = PartnerStore(customer);
      final d = await partner.recordWeighing(
        customer: customer.profile,
        type: WasteType.kardus,
        kg: 2,
      );
      await partner.uploadPhoto(d, _png, 'timbang.png');
      expect(customer.depositById(d.id)!.localPhoto, _png);
    });

    test('mode server: unggah multipart lalu memakai alamat dari server', () async {
      late http.BaseRequest sent;
      final client = MockClient.streaming((request, body) async {
        sent = request;
        final bytes = await body.toBytes();
        expect(utf8.decode(bytes, allowMalformed: true), contains('timbang.png'));
        final json = jsonEncode({
          'data': {
            'code': 'STR-261112-01',
            'customer': {'id': 7, 'code': 'CST-0007', 'name': 'Uji'},
            'waste_type': {'code': 'kardus', 'name': 'Kardus', 'points_per_kg': 300},
            'estimated_kg': 2,
            'weighed_kg': 2,
            'points_earned': 600,
            'method': 'drop_off',
            'status': 'verified',
            'weigh_photo_url': 'http://server/api/media/weigh-photos/abc.png',
            'created_at': '2026-11-12T03:00:00Z',
            'timeline': [],
          },
        });
        return http.StreamedResponse(Stream.value(utf8.encode(json)), 200);
      });
      final api = ApiClient('http://server/api', client: client, token: 't');
      final json = await api.upload(
        '/partner/deposits/STR-261112-01/photo',
        field: 'photo',
        bytes: _png,
        filename: 'timbang.png',
      );
      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/partner/deposits/STR-261112-01/photo');
      expect(sent.headers['Authorization'], 'Bearer t');
      expect(sent.headers['content-type'], startsWith('multipart/form-data'));
      expect(json['data']['weigh_photo_url'], endsWith('abc.png'));
    });

    test('galat validasi foto tampil sebagai pesan', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'invalid',
            'errors': {
              'photo': ['Ukuran foto paling besar 5 MB.'],
            },
          }),
          422,
        ),
      );
      final api = ApiClient('http://server/api', client: client);
      await expectLater(
        api.upload('/x', field: 'photo', bytes: Uint8List(1), filename: 'a.jpg'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Ukuran foto paling besar 5 MB.',
          ),
        ),
      );
    });

    testWidgets('customer melihat foto dari mitra di detail setoran', (
      tester,
    ) async {
      final store = CustomerStore();
      final d = store.deposits.firstWhere(
        (d) => d.status == DepositStatus.verified,
      )..localPhoto = Uint8List.fromList(_png);
      await tester.pumpWidget(
        CustomerScope(
          store: store,
          child: MaterialApp(home: DepositDetailPage(deposit: d)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Foto timbangan ${d.id}'), findsOneWidget);
    });
  });
}
