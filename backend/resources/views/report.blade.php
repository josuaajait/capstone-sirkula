@php
    $num = fn ($n, $d = 1) => number_format((float) $n, $d, ',', '.');
    $int = fn ($n) => number_format((int) $n, 0, ',', '.');
@endphp
<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Laporan Sirkula {{ $report['period']['from'] }} s.d. {{ $report['period']['to'] }}</title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; color: #15231E; margin: 24px; font-size: 13px; }
        h1 { color: #166B52; font-size: 22px; margin: 0 0 4px; }
        h2 { font-size: 15px; margin: 24px 0 8px; }
        .muted { color: #5B6A64; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #E4EAE6; padding: 6px 8px; text-align: left; }
        th { background: #E8F4EC; }
        td.n { text-align: right; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 8px; }
        .box { border: 1px solid #E4EAE6; border-radius: 8px; padding: 10px; }
        .box b { display: block; font-size: 17px; margin-top: 2px; }
        .hint { background: #FFF3D6; color: #A66808; padding: 8px 10px; border-radius: 8px; }
        @media print { .hint { display: none; } body { margin: 0; } }
    </style>
</head>
<body>
    <p class="hint">Pilih "Simpan sebagai PDF" di dialog cetak untuk menyimpan laporan ini.</p>
    <h1>Laporan Sirkula · BSI Ias Toba</h1>
    <div class="muted">Periode {{ $report['period']['from'] }} s.d. {{ $report['period']['to'] }} · dibuat {{ now()->format('Y-m-d H:i') }}</div>

    <h2>Ringkasan</h2>
    <div class="grid">
        <div class="box">Total berat<b>{{ $num($report['totals']['kg']) }} kg</b></div>
        <div class="box">Emisi terhindarkan<b>{{ $num($report['totals']['tco2e'], 3) }} tCO2e</b></div>
        <div class="box">Jumlah setoran<b>{{ $int($report['totals']['deposits']) }}</b></div>
        <div class="box">Customer aktif<b>{{ $int($report['totals']['active_customers']) }}</b></div>
        <div class="box">Poin diberikan<b>{{ $int($report['totals']['points_given']) }}</b></div>
        <div class="box">Hadiah ditukar<b>{{ $int($report['redemptions']['count']) }} ({{ $int($report['redemptions']['points']) }} poin)</b></div>
    </div>

    <h2>Per jenis sampah</h2>
    <table>
        <tr><th>Kelompok</th><th>Jenis</th><th>Berat (kg)</th><th>Poin</th></tr>
        @forelse ($report['by_type'] as $t)
            <tr><td>{{ $t['group'] }}</td><td>{{ $t['name'] }}</td><td class="n">{{ $num($t['kg']) }}</td><td class="n">{{ $int($t['points']) }}</td></tr>
        @empty
            <tr><td colspan="4" class="muted">Belum ada setoran ditimbang di periode ini.</td></tr>
        @endforelse
    </table>

    <h2>Rincian setoran</h2>
    <table>
        <tr><th>Kode</th><th>Tanggal timbang</th><th>Customer</th><th>Jenis</th><th>Berat (kg)</th><th>Poin</th></tr>
        @foreach ($deposits as $d)
            <tr>
                <td>{{ $d->code }}</td>
                <td>{{ $d->weighed_at->format('Y-m-d H:i') }}</td>
                <td>{{ $d->customer->name }} ({{ $d->customer->code }})</td>
                <td>{{ $d->wasteType->name }}</td>
                <td class="n">{{ $num($d->weighed_kg) }}</td>
                <td class="n">{{ $int($d->points_earned) }}</td>
            </tr>
        @endforeach
    </table>
    <script>window.addEventListener('load', () => setTimeout(() => window.print(), 400));</script>
</body>
</html>
