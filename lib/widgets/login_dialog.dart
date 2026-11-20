import 'package:material_ui/material_ui.dart';
import '../services/api_service.dart';

class LoginDialog extends StatefulWidget {
  final DrinkApiService apiService;

  const LoginDialog({super.key, required this.apiService});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _userErrorMessage;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _userErrorMessage = null;
    });

    try {
      await widget.apiService.login(
        _userCtrl.text.trim(),
        _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;
      setState(() {
        _userErrorMessage = e.statusCode == 401
            ? 'Nieprawidłowy login lub hasło.'
            : 'Błąd połączenia z serwerem.';
      });
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      if (!mounted) return;
      setState(() {
        _userErrorMessage = 'Wystąpił nieoczekiwany błąd logowania.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      //title: const Text(''),
      content: SizedBox(
        height: 120,
        width: 340,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _userCtrl,
                enabled: !_isLoading,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Login',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Podaj login' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Hasło',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Podaj hasło' : null,
              ),
              if (_userErrorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _userErrorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Zaloguj'),
        ),
      ],
    );
  }
}