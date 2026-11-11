import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';

/// Foto yang dipilih mitra, siap diunggah.
typedef PickedPhoto = ({Uint8List bytes, String name});

/// Pilih foto timbangan dari kamera atau galeri. Foto diperkecil agar unggahan
/// ringan (lebar paling besar 1600 px, kualitas 80%). Mengembalikan null jika
/// dibatalkan.
Future<PickedPhoto?> pickWeighPhoto(BuildContext context) async {
  final source = kIsWeb
      // Di peramban, kamera HP dibuka lewat dialog pilih file.
      ? ImageSource.gallery
      : await showModalBottomSheet<ImageSource>(
          context: context,
          showDragHandle: true,
          backgroundColor: AppColors.white,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Ambil dengan kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Pilih dari galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
  if (source == null) return null;
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file == null) return null;
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    return (bytes: await file.readAsBytes(), name: name);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kamera atau galeri tidak bisa dibuka. Periksa izin aplikasi.',
          ),
        ),
      );
    }
    return null;
  }
}

/// Kotak foto opsional di formulir timbang.
class PhotoField extends StatelessWidget {
  const PhotoField({super.key, required this.photo, required this.onChanged});

  final PickedPhoto? photo;
  final ValueChanged<PickedPhoto?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = photo;
    if (p == null) {
      return OutlinedButton.icon(
        onPressed: () async {
          final picked = await pickWeighPhoto(context);
          if (picked != null) onChanged(picked);
        },
        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
        label: const Text('Tambah Foto Timbangan'),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(
              p.bytes,
              fit: BoxFit.cover,
              semanticLabel: 'Foto timbangan yang dipilih',
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filledTonal(
            tooltip: 'Hapus foto',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}
