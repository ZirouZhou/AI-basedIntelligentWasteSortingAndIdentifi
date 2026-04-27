import 'package:flutter/material.dart';

import '../../app/app_shell.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final ApiClient _apiClient;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _registerMode = false;
  bool _submitting = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _emailController.text = 'alex.green@example.com';
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _apiClient.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_registerMode && name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });
    try {
      if (_registerMode) {
        await _apiClient.register(
          name: name,
          email: email,
          password: password,
        );
        _apiClient.clearAuthToken();
        if (!mounted) {
          return;
        }
        setState(() {
          _registerMode = false;
          _passwordController.clear();
          _info = 'Registration successful. Please login to continue.';
        });
      } else {
        final session = await _apiClient.login(email: email, password: password);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => AppShell(userId: session.user.id),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _registerMode ? 'Register' : 'Login',
                        style: textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _registerMode
                            ? 'Create your account first, then enter the system.'
                            : 'Please login to continue.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (_registerMode) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
                        ),
                      ],
                      if (_info != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _info!,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.green[700]),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: Icon(_registerMode ? Icons.person_add : Icons.login),
                          label: Text(
                            _submitting
                                ? 'Submitting...'
                                : (_registerMode ? 'Register' : 'Login'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _submitting
                              ? null
                              : () => setState(() {
                                    _registerMode = !_registerMode;
                                    _error = null;
                                    _info = null;
                                  }),
                          child: Text(
                            _registerMode
                                ? 'Already have an account? Login'
                                : 'No account? Register first',
                            style: const TextStyle(color: AppTheme.seed),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
