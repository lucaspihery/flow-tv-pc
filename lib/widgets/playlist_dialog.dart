import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/playlist_service.dart';

/// Boîte de dialogue pour choisir une playlist (URL ou fichier local).
Future<PlaylistSource?> showPlaylistDialog(BuildContext context) {
  return showDialog<PlaylistSource>(context: context, builder: (_) => const _PlaylistDialog());
}

class _PlaylistDialog extends StatefulWidget {
  const _PlaylistDialog();

  @override
  State<_PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<_PlaylistDialog> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _submitUrl() {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    Navigator.pop(context, PlaylistSource(PlaylistSourceType.url, url));
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choisir une playlist M3U',
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'txt'],
    );
    final path = file?.path;
    if (path != null && mounted) {
      Navigator.pop(context, PlaylistSource(PlaylistSourceType.file, path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Charger une playlist'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _url,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'https://exemple.com/playlist.m3u',
                prefixIcon: Icon(Icons.link),
              ),
              onSubmitted: (_) => _submitUrl(),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _submitUrl, child: const Text('Charger depuis l\'URL')),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou')),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Ouvrir un fichier .m3u'),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler'))],
    );
  }
}
