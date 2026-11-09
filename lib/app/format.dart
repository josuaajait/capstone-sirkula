/// Format angka gaya Indonesia: 1.204 dan 8,4.
String formatNumber(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

/// Berat dicatat sampai 0,1 kg (aturan PRD).
String formatKg(double kg) {
  final rounded = (kg * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return '${text.replaceAll('.', ',')} kg';
}

String formatKm(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// Poin dengan tanda, misalnya +4.200 atau -10.000.
String formatSignedPoints(int value) =>
    value >= 0 ? '+${formatNumber(value)}' : formatNumber(value);

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const _monthsLong = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String formatDate(DateTime d) =>
    '${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

String formatDateShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String formatDateLong(DateTime d) =>
    '${_days[d.weekday - 1]}, ${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

/// Cap waktu garis waktu, misalnya "8 Nov, 14.05".
String formatStamp(DateTime d) => '${formatDateShort(d)}, ${formatTime(d)}';

/// Parse input berat yang boleh memakai koma.
double? parseKg(String input) =>
    double.tryParse(input.trim().replaceAll(',', '.'));
