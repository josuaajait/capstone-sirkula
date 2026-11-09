import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../widgets/common.dart';

/// Bantuan dan pertanyaan umum (FR-C11). Isinya mengikuti aturan bisnis PRD.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faq = [
    (
      'Bagaimana poin dihitung?',
      'Sistem menghitung poin dari berat hasil timbang mitra dikali poin per kg jenis sampah, lalu dibulatkan ke bawah. Angka sebelum menyetor hanya perkiraan.',
    ),
    (
      'Kenapa poin saya berbeda dari estimasi?',
      'Estimasi memakai berat yang Anda isi. Poin final memakai berat timbangan mitra, yang bisa lebih besar atau lebih kecil.',
    ),
    ('Apakah poin bisa hangus?', 'Tidak. Poin tidak punya masa berlaku.'),
    (
      'Sampah seperti apa yang diterima?',
      'Sampah harus bersih, kering, dan terpilah per jenis. Mitra boleh menolak sampah yang kotor atau tercampur.',
    ),
    (
      'Berapa lama hadiah dikirim?',
      'Hadiah disiapkan dan dikirim perusahaan dalam 1–2 hari kerja setelah penukaran. Status dan nomor resi bisa dilihat di Riwayat.',
    ),
    (
      'Siapa yang menjemput sampah saya?',
      'Mitra bank sampah yang Anda pilih, dengan kendaraan milik mitra. Jadwal dan kendaraannya tampil di menu Jemput.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bantuan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const PageHeading(
            'Pertanyaan Umum',
            'Jawaban singkat seputar setoran, poin, dan hadiah.',
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (final (q, a) in _faq)
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.muted,
                      title: Text(
                        q,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AppCard(
            child: Row(
              children: [
                IconTile(Icons.support_agent_rounded, size: 44),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masih butuh bantuan?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Hubungi tim Sirkula di bantuan@sirkula.id, Senin–Jumat 08.00–17.00.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
