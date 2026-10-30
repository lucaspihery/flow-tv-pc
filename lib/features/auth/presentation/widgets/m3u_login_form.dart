import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/gradients.dart';
import '../auth_controller.dart';
import 'login_error.dart';

class M3uLoginForm extends ConsumerStatefulWidget {
  const M3uLoginForm({super.key});

  @override
  ConsumerState<M3uLoginForm> createState() => _M3uLoginFormState();
}

class _M3uLoginFormState extends ConsumerState<M3uLoginForm> {
  final _url = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _submitUrl() async {
    final url = _url.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      setState(() => _error = 'Saisissez une URL commençant par http:// ou https://');
      return;
    }
    await ref.read(authControllerProvider.notifier).signInWithM3u(location: url, isLocalFile: false);
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choisir une playlist M3U',
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'txt'],
    );
    final path = file?.path;
    if (path == null) return;
    await ref.read(authControllerProvider.notifier).signInWithM3u(location: path, isLocalFile: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL de la playlist',
            hintText: 'https://exemple.com/playlist.m3u',
            prefixIcon: Icon(Icons.link),
          ),
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _submitUrl(),
        ),
        if (_error != null) ...[const SizedBox(height: 16), LoginError(_error!)],
        const SizedBox(height: 20),
        GradientButton(
          onPressed: _submitUrl,
          icon: Icons.playlist_play_rounded,
          child: const Text('Charger la playlist'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
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
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
          icon: const Icon(Icons.folder_open),
          label: const Text('Ouvrir un fichier .m3u'),
        ),
      ],
    );
  }
}
