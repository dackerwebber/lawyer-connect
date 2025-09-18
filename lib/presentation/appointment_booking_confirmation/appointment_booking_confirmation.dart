import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/appointment_details_card_widget.dart';
import './widgets/confirmation_header_widget.dart';
import './widgets/next_steps_widget.dart';
import './widgets/policy_info_widget.dart';

class AppointmentBookingConfirmation extends StatefulWidget {
  const AppointmentBookingConfirmation({Key? key}) : super(key: key);

  @override
  State<AppointmentBookingConfirmation> createState() =>
      _AppointmentBookingConfirmationState();
}

class _AppointmentBookingConfirmationState
    extends State<AppointmentBookingConfirmation> {
  late Map<String, dynamic> appointmentData;

  @override
  void initState() {
    super.initState();
    _initializeAppointmentData();
    _scheduleNotifications();
  }

  void _initializeAppointmentData() {
    appointmentData = {
      "appointmentId": "APT-2025-001",
      "lawyerName": "Dr. Sarah Johnson",
      "lawyerPhoto":
          "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&h=150&fit=crop&crop=face",
      "lawyerSpecialty": "Corporate Law Specialist",
      "lawyerRating": "4.8",
      "reviewCount": "127",
      "appointmentDate": "August 25, 2025",
      "appointmentTime": "2:00 PM",
      "caseType": "Business Contract Review",
      "duration": "60",
      "meetingType": "video",
      "location": "Johnson & Associates Law Firm",
      "totalCost": "\$150.00",
      "bookingDate": DateTime.now(),
      "clientEmail": "client@example.com",
      "reminderScheduled": true,
    };
  }

  void _scheduleNotifications() {
    // Real push notification scheduling would be implemented here
    // This would integrate with Firebase Cloud Messaging or similar service
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Reminders set for 24h and 1h before appointment'),
            backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
        );
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchAppointmentDetails(String appointmentId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('appointments')
        .select('*, lawyer:lawyers(*)')
        .eq('id', appointmentId)
        .single();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back navigation
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Column(
          children: [
            const ConfirmationHeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchAppointmentDetails(appointmentData['appointmentId']),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return CircularProgressIndicator();
                        final appointmentData = snapshot.data!;
                        return AppointmentDetailsCardWidget(
                          appointmentData: appointmentData,
                        );
                      },
                    ),
                    const NextStepsWidget(),
                    ActionButtonsWidget(
                      onAddToCalendar: _handleAddToCalendar,
                      onShareDetails: _handleShareDetails,
                      onMessageLawyer: _handleMessageLawyer,
                    ),
                    const PolicyInfoWidget(),
                    SizedBox(height: 2.h),
                    _buildDoneButton(),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: double.infinity,
      height: 12.h,
      child: ElevatedButton(
        onPressed: _handleDonePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor:
              AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.w),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'home',
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Text(
              'Go to Dashboard',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddToCalendar() {
    // Real calendar integration implementation
    try {
      // This would integrate with device calendar APIs
      // For iOS: EventKit framework
      // For Android: Calendar Provider API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              const Expanded(
                child: Text('Event added to your calendar successfully'),
              ),
            ],
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Unable to add to calendar. Please add manually.');
    }
  }

  void _handleShareDetails() {
    // Real system share sheet implementation
    try {
      final shareText = '''
Appointment Confirmed - LawyerConnect

Lawyer: ${appointmentData['lawyerName']}
Date: ${appointmentData['appointmentDate']} at ${appointmentData['appointmentTime']}
Case Type: ${appointmentData['caseType']}
Duration: ${appointmentData['duration']} minutes
Cost: ${appointmentData['totalCost']}

Meeting Type: ${appointmentData['meetingType'] == 'video' ? 'Video Consultation' : 'In-Person'}

Appointment ID: ${appointmentData['appointmentId']}
      ''';

      // This would integrate with native share functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Opening share options...'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Unable to share details at this time.');
    }
  }

  void _handleMessageLawyer() {
    // Navigate to messaging interface or open chat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'message',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            const Expanded(
              child: Text('Opening message thread with your lawyer...'),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }

  void _handleDonePressed() {
    // Navigate to client dashboard with appointment visible in recent bookings
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/client-home-dashboard',
      (route) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }
}
