import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          image: DecorationImage(
            image: const AssetImage('assets/images/dental_bg_3d.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppTheme.darkBackground.withValues(alpha: 0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.local_hospital,
                      color: AppTheme.primary, size: 44),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.tr('dentalscan_ai'),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Text(AppLocalizations.tr('aipowered_oral_cancer_detection'),
                    style: TextStyle(fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8))),
              ]),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32))),
                  child: Column(children: [
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12)),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10)),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textGrey,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        tabs: const [Tab(text: 'Login'), Tab(text: 'Sign Up')],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [LoginForm(), SignUpForm()],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── LOGIN FORM ───────────────────────────────────────────────
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final result = await ApiService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      await AuthState.save(
        token: result.data['access_token'],
        name: result.data['user']['name'],
        email: result.data['user']['email'],
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text);
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Forgot Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your email to receive a password reset token.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            setState(() => error = 'Enter a valid email');
                            return;
                          }
                          setState(() { isLoading = true; error = null; });
                          final result = await ApiService.forgotPassword(email);
                          setState(() => isLoading = false);
                          if (result.success) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _showResetPasswordDialog();
                          } else {
                            setState(() => error = result.error);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetPasswordDialog() {
    final tokenCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isLoading = false;
    String? error;
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the reset token sent to your email and your new password.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reset Token',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      errorText: error,
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final token = tokenCtrl.text.trim();
                          final pw = passCtrl.text;
                          if (token.isEmpty) {
                            setState(() => error = 'Please enter the reset token');
                            return;
                          }
                          if (pw.length < 6) {
                            setState(() => error = 'Minimum 6 characters required');
                            return;
                          }
                          setState(() { isLoading = true; error = null; });
                          final result = await ApiService.resetPassword(token, pw);
                          setState(() => isLoading = false);
                          if (result.success) {
                            if (!ctx.mounted || !mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Password reset successfully! You can now login.'), backgroundColor: AppTheme.success),
                            );
                          } else {
                            setState(() => error = result.error);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.tr('welcome_back'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text(AppLocalizations.tr('sign_in_to_your_account'),
                style: const TextStyle(fontSize: 14, color: AppTheme.textGrey)),
            const SizedBox(height: 24),



            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textGrey),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                ]),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(AppLocalizations.tr('forgot_password'),
                    style: const TextStyle(color: AppTheme.primary)),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.tr('login')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SIGN UP FORM ─────────────────────────────────────────────
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});
  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _mobileController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final result = await ApiService.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      mobile: _mobileController.text.trim(),
      dob: '',
      gender: _selectedGender ?? "",
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      await AuthState.save(
        token: result.data['access_token'],
        name: result.data['user']['name'],
        email: result.data['user']['email'],
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.tr('create_account_1'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text(AppLocalizations.tr('register_to_get_started'),
                style: const TextStyle(fontSize: 14, color: AppTheme.textGrey)),
            const SizedBox(height: 20),



            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outlined, color: AppTheme.primary),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary),
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter mobile number';
                if (v.length != 10) return 'Mobile number must be exactly 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.primary),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter your age' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.people_alt_outlined, color: AppTheme.primary),
              ),
              items: ['Male', 'Female', 'Other', 'Prefer not to say']
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedGender = val;
                });
              },
              validator: (v) => v == null || v.isEmpty ? 'Please select gender' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textGrey),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textGrey),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.tr('create_account')),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(AppLocalizations.tr('by_signing_up_you_agree_to_our_terms__privacy_policy'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
            ),
          ],
        ),
      ),
    );
  }
}