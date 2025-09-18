import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';

class RegistrationForm extends StatefulWidget {
  final String selectedRole;
  final VoidCallback onFormValid;
  final VoidCallback onFormInvalid;

  const RegistrationForm({
    Key? key,
    required this.selectedRole,
    required this.onFormValid,
    required this.onFormInvalid,
  }) : super(key: key);

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _barNumberController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedPracticeArea;
  bool _hasUploadedLicense = false;
  bool _isFormValid = false;

  final List<String> _practiceAreas = [
    'Corporate Law',
    'Criminal Law',
    'Family Law',
    'Real Estate Law',
    'Personal Injury',
    'Immigration Law',
    'Tax Law',
    'Employment Law',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    if (widget.selectedRole == 'lawyer') {
      _barNumberController.addListener(_validateForm);
      _experienceController.addListener(_validateForm);
    }
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    final basicFieldsValid = _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    bool lawyerFieldsValid = true;
    if (widget.selectedRole == 'lawyer') {
      lawyerFieldsValid = _barNumberController.text.isNotEmpty &&
          _experienceController.text.isNotEmpty &&
          _selectedPracticeArea != null &&
          _hasUploadedLicense;
    }

    final formValid = isValid && basicFieldsValid && lawyerFieldsValid;

    if (formValid != _isFormValid) {
      setState(() {
        _isFormValid = formValid;
      });

      if (formValid) {
        widget.onFormValid();
      } else {
        widget.onFormInvalid();
      }
    }
  }

  void _uploadLicense() {
    // Simulate license upload
    setState(() {
      _hasUploadedLicense = true;
    });
    _validateForm();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('License uploaded successfully'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'lawyer' or 'client'
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Insert user profile into your table
        await Supabase.instance.client.from('user_profiles').insert({
          'id': response.user!.id,
          'full_name': fullName,
          'email': email,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // If lawyer, insert into lawyer_profiles as well
        if (role == 'lawyer') {
          await Supabase.instance.client.from('lawyer_profiles').insert({
            'user_id': response.user!.id,
            // ...other lawyer fields
          });
        }
      }

      return response;
    } catch (error) {
      print('Sign up error: $error');
      throw Exception('Sign up failed: $error');
    }
  }

  Future<void> _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final role = widget.selectedRole;

    try {
      final response = await signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      if (response.user == null) {
        print('Registration failed');
      }
    } catch (error) {
      print('Sign up error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name Field
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Password Field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName: _obscurePassword ? 'visibility_off' : 'visibility',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName:
                      _obscureConfirmPassword ? 'visibility_off' : 'visibility',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: widget.selectedRole == 'lawyer'
                ? TextInputAction.next
                : TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          // Lawyer-specific fields
          if (widget.selectedRole == 'lawyer') ...[
            SizedBox(height: 2.h),

            // Bar Number Field
            TextFormField(
              controller: _barNumberController,
              decoration: const InputDecoration(
                labelText: 'Bar Number',
                hintText: 'Enter your bar registration number',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your bar number';
                }
                if (value.length < 5) {
                  return 'Please enter a valid bar number';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),

            // Practice Area Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPracticeArea,
              decoration: const InputDecoration(
                labelText: 'Practice Area',
                hintText: 'Select your primary practice area',
              ),
              items: _practiceAreas.map((area) {
                return DropdownMenuItem<String>(
                  value: area,
                  child: Text(area),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPracticeArea = value;
                });
                _validateForm();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your practice area';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),

            // Years of Experience Field
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                labelText: 'Years of Experience',
                hintText: 'Enter years of legal experience',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your years of experience';
                }
                final years = int.tryParse(value);
                if (years == null || years < 0 || years > 50) {
                  return 'Please enter valid years of experience (0-50)';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),

            // License Upload Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasUploadedLicense
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : AppTheme.lightTheme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8.0),
                color: _hasUploadedLicense
                    ? AppTheme.lightTheme.colorScheme.secondary
                        .withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify your human',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Verify to continue',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton.icon(
                    onPressed: _uploadLicense,
                    icon: CustomIconWidget(
                      iconName:
                          _hasUploadedLicense ? 'check_circle' : 'camera_alt',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      size: 20,
                    ),
                    label: Text(_hasUploadedLicense
                        ? 'Verification done'
                        : 'Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasUploadedLicense
                          ? AppTheme.lightTheme.colorScheme.secondary
                          : AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _barNumberController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}
