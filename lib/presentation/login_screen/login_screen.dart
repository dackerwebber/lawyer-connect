import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberEmail = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadRememberedEmail() {
    if (_rememberEmail) {
      _emailController.text = 'client@lawyerconnect.com';
    }
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }

    if (!_validateEmail(_emailController.text)) {
      setState(() => _emailError = 'Please enter a valid email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return;
    }

    if (!_validatePassword(_passwordController.text)) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
    }
  }

  Future<void> _handleLogin() async {
    _validateInputs();
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.toLowerCase().trim();
      final password = _passwordController.text;

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('Login failed');
        // Optionally show a message to the user
      }

      if (response.user != null) {
        final userId = response.user!.id;

        final client = await Supabase.instance.client
            .from('clients')
            .select('role')
            .eq('user_id', userId)
            .maybeSingle();

        final lawyer = await Supabase.instance.client
            .from('lawyers')
            .select('role')
            .eq('user_id', userId)
            .maybeSingle();

        String? role;
        if (client != null) {
          role = client['role'] ?? 'client';
        } else if (lawyer != null) {
          role = lawyer['role'] ?? 'lawyer';
        }

        if (role == 'client') {
          Navigator.pushReplacementNamed(context, '/client-home-dashboard');
        } else if (role == 'lawyer') {
          Navigator.pushReplacementNamed(context, '/lawyer-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/client-home-dashboard');
        }
      }
    } on AuthException catch (e) {
      setState(() => _passwordError = e.message);
    } catch (e) {
      setState(() => _passwordError = 'Network error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    HapticFeedback.lightImpact();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacementNamed(context, '/client-home-dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric authentication failed. Please use email and password.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onError,
            ),
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password',
            style: AppTheme.lightTheme.textTheme.titleLarge),
        content: Text(
          'Password reset will be available soon. Please contact support.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 8.h),
                _buildLogo(),
                SizedBox(height: 3.h),
                _buildWelcomeText(),
                SizedBox(height: 6.h),
                _buildEmailField(),
                SizedBox(height: 3.h),
                _buildPasswordField(),
                SizedBox(height: 2.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text('Forgot Password?',
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                                color:
                                    AppTheme.lightTheme.colorScheme.primary)),
                  ),
                ),
                SizedBox(height: 4.h),
                _buildLoginButton(),
                SizedBox(height: 3.h),
                _buildBiometricSection(),
                SizedBox(height: 4.h),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Container(
        width: 25.w,
        height: 25.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'gavel',
            color: AppTheme.lightTheme.colorScheme.onPrimary,
            size: 12.w,
          ),
        ),
      );

  Widget _buildWelcomeText() => Column(
        children: [
          Text('Welcome Back',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.primary)),
          SizedBox(height: 1.h),
          Text('Sign in to access your legal services',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
              textAlign: TextAlign.center),
        ],
      );

  Widget _buildEmailField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email Address',
              style: AppTheme.lightTheme.textTheme.labelLarge),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            onChanged: (_) => setState(() => _emailError = null),
          ),
          if (_emailError != null)
            Text(_emailError!,
                style: TextStyle(color: AppTheme.lightTheme.colorScheme.error)),
        ],
      );

  Widget _buildPasswordField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password',
              style: AppTheme.lightTheme.textTheme.labelLarge),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            onChanged: (_) => setState(() => _passwordError = null),
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          if (_passwordError != null)
            Text(_passwordError!,
                style: TextStyle(color: AppTheme.lightTheme.colorScheme.error)),
        ],
      );

  Widget _buildLoginButton() => SizedBox(
        width: double.infinity,
        height: 7.h,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading
              ? CircularProgressIndicator()
              : Text('Login',
                  style: AppTheme.lightTheme.textTheme.titleMedium),
        ),
      );

  Widget _buildBiometricSection() => Column(
        children: [
          Text('Or continue with',
              style: AppTheme.lightTheme.textTheme.bodyMedium),
          SizedBox(height: 2.h),
          GestureDetector(
            onTap: _handleBiometricLogin,
            child: Icon(Icons.fingerprint,
                color: AppTheme.lightTheme.colorScheme.primary, size: 40),
          ),
        ],
      );

  Widget _buildSignUpLink() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('New user? ',
              style: AppTheme.lightTheme.textTheme.bodyMedium),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/role-selection-registration'),
            child: Text('Sign Up',
                style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          )
        ],
      );
}
