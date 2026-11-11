import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/widgets/common.dart';
import '../admin_store.dart';
import 'admin_home_page.dart' show formatDecimal;

/// Laporan berat, tCO2e, customer aktif, poin, dan penukaran per periode,
/// dengan unduhan Excel (CSV) dan PDF siap cetak (FR-P7).
class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  late DateTimeRange _range = () {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month, now.day),
    );
  }();
  AdminReport? _report;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final store = AdminScope.read(context);
    final r = await runAction(
      context,
      () => store.loadReport(_range.start, _range.end),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r != null) _report = r;
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
      helpText: 'Periode laporan',
    );
    if (picked == null) return;
    setState(() => _range = picked);
    await _load();
  }

  Future<void> _download(String format) async {
    final store = AdminScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final url = await runAction(
      context,
      () => store.reportLink(_range.start, _range.end, format),
    );
    if (url == null) return;
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka peramban.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: Text(
                '${formatDate(_range.start)} – ${formatDate(_range.end)}',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _download('csv'),
                    icon: const Icon(Icons.table_view_outlined, size: 18),
                    label: const Text('Excel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _download('pdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading && r == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (r != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Ringkasan'),
                    const SizedBox(height: 8),
                    InfoRow('Total berat', formatKg(r.kg)),
                    InfoRow(
                      'Emisi terhindarkan',
                      '${formatDecimal(r.tco2e, 3)} tCO2e',
                    ),
                    InfoRow('Jumlah setoran', formatNumber(r.deposits)),
                    InfoRow('Customer aktif', formatNumber(r.activeCustomers)),
                    InfoRow('Poin diberikan', formatNumber(r.pointsGiven)),
                    InfoRow('Hadiah ditukar', formatNumber(r.redemptionCount)),
                    InfoRow(
                      'Poin untuk hadiah',
                      formatNumber(r.redemptionPoints),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Per jenis sampah'),
                    const SizedBox(height: 8),
                    if (r.byType.isEmpty)
                      const Text(
                        'Belum ada setoran ditimbang di periode ini.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    for (final t in r.byType)
                      InfoRow(
                        '${t.group} · ${t.name}',
                        '${formatKg(t.kg)} · ${formatNumber(t.points)} poin',
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
