import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/registration_form.dart';
import './widgets/role_selection_card.dart';

class RoleSelectionRegistration extends StatefulWidget {
  const RoleSelectionRegistration({Key? key}) : super(key: key);

  @override
  State<RoleSelectionRegistration> createState() =>
      _RoleSelectionRegistrationState();
}

class _RoleSelectionRegistrationState extends State<RoleSelectionRegistration> {
  final PageController _pageController = PageController();
  String _selectedRole = '';
  bool _isFormValid = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  int _currentStep = 1;
  final int _totalSteps = 2;

  final List<Map<String, dynamic>> _roles = [
    {
      'title': 'Client',
      'description': 'Book appointments and connect with legal professionals',
      'icon': 'person',
    },
    {
      'title': 'Lawyer',
      'description': 'Manage your practice and connect with clients',
      'icon': 'balance',
    },
  ];

  void _selectRole(String role) {
    if (_selectedRole != role) {
      setState(() {
        _selectedRole = role;
      });

      // Haptic feedback
      HapticFeedback.selectionClick();

      // Auto-advance to registration form after selection
      Future.delayed(const Duration(milliseconds: 300), () {
        _nextStep();
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onFormValid() {
    setState(() {
      _isFormValid = true;
    });
  }

  void _onFormInvalid() {
    setState(() {
      _isFormValid = false;
    });
  }

  Future<void> _createAccount() async {
    if (!_isFormValid || !_acceptedTerms) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate account creation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Account created successfully! Please check your email for verification.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to appropriate dashboard based on role
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          if (_selectedRole.toLowerCase() == 'client') {
            Navigator.pushReplacementNamed(context, '/client-home-dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/lawyer-dashboard');
          }
        }
      });
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms of Service & Privacy Policy'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Terms of Service',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'By using LawyerConnect, you agree to our terms of service including professional conduct standards, appointment policies, and payment terms.',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Privacy Policy',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'We protect your personal information and legal communications with industry-standard encryption and confidentiality measures.',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back navigation and progress
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _currentStep > 1
                        ? _previousStep
                        : () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _currentStep == 1 ? 'Choose Your Role' : 'Create Account',
                      style: AppTheme.lightTheme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Progress Indicator
            ProgressIndicatorWidget(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
            ),

            // Main Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Role Selection
                  _buildRoleSelectionStep(),

                  // Step 2: Registration Form
                  _buildRegistrationStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),

          // Welcome Text
          Text(
            'Welcome to LawyerConnect',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),

          Text(
            'Choose your role to get started with our legal services platform',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),

          // Role Selection Cards
          Column(
            children: _roles.map((role) {
              final isSelected =
                  _selectedRole.toLowerCase() == role['title'].toLowerCase();
              return RoleSelectionCard(
                title: role['title'],
                description: role['description'],
                iconName: role['icon'],
                isSelected: isSelected,
                onTap: () => _selectRole(role['title']),
              );
            }).toList(),
          ),

          SizedBox(height: 4.h),

          // Continue Button (only show if role selected)
          if (_selectedRole.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                child: const Text('Continue'),
              ),
            ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildRegistrationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),

          // Selected Role Indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: _selectedRole.toLowerCase() == 'client'
                      ? 'person'
                      : 'balance',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registering as $_selectedRole',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Complete the form below to create your account',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Registration Form
          RegistrationForm(
            selectedRole: _selectedRole.toLowerCase(),
            onFormValid: _onFormValid,
            onFormInvalid: _onFormInvalid,
          ),

          SizedBox(height: 3.h),

          // Terms and Conditions Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _acceptedTerms = !_acceptedTerms;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: RichText(
                      text: TextSpan(
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: _showTermsDialog,
                              child: Text(
                                'Terms of Service and Privacy Policy',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Create Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isFormValid && _acceptedTerms && !_isLoading)
                  ? _createAccount
                  : null,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Text('Create Account'),
            ),
          ),

          SizedBox(height: 2.h),

          // Login Link
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login-screen'),
              child: RichText(
                text: TextSpan(
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
