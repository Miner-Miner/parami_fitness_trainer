import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_picker.dart';
import '../core/api_client.dart';
import '../core/session_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController(
    text: ApiClient.defaultBaseUrl,
  );
  final _databaseController = TextEditingController(
    text: ApiClient.defaultDatabase,
  );
  var _hidePassword = true;
  var _isLoading = false;
  var _showConnection = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final session = await ApiClient.login(
        baseUrl: _serverController.text,
        database: _databaseController.text,
        login: _usernameController.text,
        password: _passwordController.text,
      );
      await widget.sessionStore.save(session);
    } on ApiFailure catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) {
        _showError('Sign in could not be completed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppPalette.of(context).ink,
      body: Stack(
        children: [
          Positioned(
            top: -size.width * 0.45,
            right: -size.width * 0.34,
            child: _Halo(
              size: size.width * 1.15,
              color: AppPalette.of(context).navyBright.withValues(alpha: 0.66),
            ),
          ),
          Positioned(
            left: -120,
            top: size.height * 0.36,
            child: _Halo(
              size: 220,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ThemePickerButton(
                            sessionStore: widget.sessionStore,
                            onDark: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                        SizedBox(height: 26),
                        Text(
                          'Trainer sign in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Manage your members, sessions, and class attendance from one focused workspace.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 34),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppPalette.of(context).card,
                            borderRadius: BorderRadius.circular(
                              AppPalette.of(context).radius,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44000000),
                                blurRadius: 28,
                                offset: Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Use your trainer account to continue.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              SizedBox(height: 22),
                              TextFormField(
                                controller: _usernameController,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Enter your username.'
                                    : null,
                              ),
                              SizedBox(height: 13),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: _hidePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Enter your password.'
                                    : null,
                              ),
                              SizedBox(height: 18),
                              _ConnectionPanel(
                                expanded: _showConnection,
                                onPressed: () => setState(
                                  () => _showConnection = !_showConnection,
                                ),
                                serverController: _serverController,
                                databaseController: _databaseController,
                              ),
                              SizedBox(height: 22),
                              FilledButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text('Sign in as trainer'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 22),
                        Center(
                          child: Text(
                            'Protected trainer access',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
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
        ],
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.expanded,
    required this.onPressed,
    required this.serverController,
    required this.databaseController,
  });

  final bool expanded;
  final VoidCallback onPressed;
  final TextEditingController serverController;
  final TextEditingController databaseController;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.of(context).mist,
        borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
        border: Border.all(color: AppPalette.of(context).line),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppPalette.of(context).radius),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    Icons.dns_outlined,
                    color: AppPalette.of(context).foregroundAccent,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connection settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.of(context).foregroundAccent,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  TextFormField(
                    controller: serverController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      isDense: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the base URL.'
                        : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: databaseController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Odoo database',
                      isDense: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the database name.'
                        : null,
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
