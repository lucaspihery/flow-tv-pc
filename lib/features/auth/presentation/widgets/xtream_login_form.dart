import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../auth_controller.dart';
import 'login_error.dart';

class XtreamLoginForm extends ConsumerStatefulWidget {
  const XtreamLoginForm({super.key});

  @override
  ConsumerState<XtreamLoginForm> createState() => _XtreamLoginFormState();
}

class _XtreamLoginFormState extends ConsumerState<XtreamLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _server = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithXtream(server: _server.text, username: _username.text, password: _password.text);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Connexion impossible : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Champ obligatoire' : null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _server,
              decoration: const InputDecoration(
                labelText: 'URL du serveur',
                hintText: 'http://exemple.com:8080',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: _required,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Nom d\'utilisateur', prefixIcon: Icon(Icons.person)),
              autofillHints: const [AutofillHints.username],
              validator: _required,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Afficher' : 'Masquer',
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              autofillHints: const [AutofillHints.password],
              validator: _required,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[const SizedBox(height: 16), LoginError(_error!)],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              child: _loading
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
