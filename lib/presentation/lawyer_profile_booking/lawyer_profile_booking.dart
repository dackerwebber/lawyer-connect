import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import './widgets/availability_calendar_widget.dart';
import './widgets/booking_bottom_sheet_widget.dart';
import './widgets/lawyer_biography_widget.dart';
import './widgets/lawyer_gallery_widget.dart';
import './widgets/lawyer_header_widget.dart';
import './widgets/lawyer_info_widget.dart';
import './widgets/lawyer_reviews_widget.dart';

class LawyerProfileBooking extends StatefulWidget {
  const LawyerProfileBooking({Key? key}) : super(key: key);

  @override
  State<LawyerProfileBooking> createState() => _LawyerProfileBookingState();
}

class _LawyerProfileBookingState extends State<LawyerProfileBooking> {
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _showBookingButton = false;

  Map<String, dynamic>? _lawyerData;
  List<Map<String, dynamic>> _reviewsData = [];
  List<String> _galleryImages = [];
  String? _lawyerId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lawyerId == null) {
      _lawyerId = ModalRoute.of(context)?.settings.arguments as String?;
      if (_lawyerId != null) {
        _fetchLawyerProfile(_lawyerId!);
      }
    }
  }

  Future<void> _fetchLawyerProfile(String lawyerId) async {
    final supabase = Supabase.instance.client;
    // Fetch lawyer profile
    final lawyerRes = await supabase
        .from('lawyers')
        .select()
        .eq('id', lawyerId)
        .single();
    setState(() {
      _lawyerData = lawyerRes;
    });

    // Fetch reviews
    final reviewsRes = await supabase
        .from('reviews')
        .select()
        .eq('lawyer_id', lawyerId);
    setState(() {
      _reviewsData = List<Map<String, dynamic>>.from(reviewsRes);
    });

    // Fetch gallery images
    final galleryRes = await supabase
        .from('lawyer_gallery')
        .select('image_url')
        .eq('lawyer_id', lawyerId);
    setState(() {
      _galleryImages = galleryRes.map<String>((img) => img['image_url'] as String).toList();
    });
  }

  Future<void> _bookAppointment({
    required String lawyerId,
    required DateTime date,
    required String time,
    required String caseType,
  }) async {
    final supabase = Supabase.instance.client;
    final clientId = supabase.auth.currentUser?.id;
    if (clientId == null) return;

    // Insert appointment
    final response = await supabase
        .from('appointments')
        .insert({
          'lawyer_id': lawyerId,
          'client_id': clientId,
          'date': date.toIso8601String(),
          'time': time,
          'case_type': caseType,
          'status': 'pending',
        })
        .select()
        .single();

    // Optionally: Notify lawyer (if you have a notifications table)
    await supabase.from('notifications').insert({
      'user_id': lawyerId,
      'type': 'appointment',
      'message': 'New appointment request from client.',
      'created_at': DateTime.now().toIso8601String(),
      'appointment_id': response['id'],
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment request sent to lawyer!'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );

    // Navigate to confirmation screen
    Navigator.pushNamed(
      context,
      '/appointment-booking-confirmation',
      arguments: response,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: LawyerHeaderWidget(lawyerData: _lawyerData ?? {}),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                SliverToBoxAdapter(
                  child: LawyerInfoWidget(lawyerData: _lawyerData ?? {}),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                SliverToBoxAdapter(
                  child: LawyerBiographyWidget(lawyerData: _lawyerData ?? {}),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                SliverToBoxAdapter(
                  child: LawyerGalleryWidget(images: _galleryImages),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                SliverToBoxAdapter(
                  child: LawyerReviewsWidget(reviews: _reviewsData),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                SliverToBoxAdapter(
                  child: AvailabilityCalendarWidget(
                    lawyerData: _lawyerData ?? {},
                    onTimeSlotSelected: _onTimeSlotSelected,
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                SliverToBoxAdapter(child: _buildActionButtons()),
                SliverToBoxAdapter(child: SizedBox(height: _showBookingButton ? 20.h : 4.h)),
              ],
            ),
            // Sticky booking button
            if (_showBookingButton)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildStickyBookingButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _messageLawyer,
              icon: CustomIconWidget(
                iconName: 'message',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 5.w,
              ),
              label: Text('Message'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                side: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _callLawyer,
              icon: CustomIconWidget(
                iconName: 'phone',
                color: Colors.white,
                size: 5.w,
              ),
              label: Text('Call Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBookingButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedDate != null && _selectedTime != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(3.w),
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withAlpha(25),
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withAlpha(75),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${_formatDate(_selectedDate!)} at $_selectedTime',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Total: \$${((_lawyerData?['hourlyRate'] as double? ?? 0.0) * 1.1).toStringAsFixed(2)}',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDate != null && _selectedTime != null
                      ? _showBookingBottomSheet
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                  ),
                  child: Text(
                    _selectedDate != null && _selectedTime != null
                        ? 'Book Appointment'
                        : 'Select Date & Time',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTimeSlotSelected(DateTime date, String time) {
    setState(() {
      _selectedDate = date;
      _selectedTime = time;
      _showBookingButton = true;
    });
  }

  void _showBookingBottomSheet() {
    if (_selectedDate == null || _selectedTime == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheetWidget(
        selectedDate: _selectedDate!,
        selectedTime: _selectedTime!,
        lawyerData: _lawyerData ?? {},
        onBookingConfirmed: _onBookingConfirmed,
      ),
    );
  }

  void _onBookingConfirmed(Map<String, dynamic> bookingData) {
    _bookAppointment(
      lawyerId: _lawyerId!,
      date: _selectedDate!,
      time: _selectedTime!,
      caseType: bookingData['caseType'],
    );

    // Navigate to booking confirmation screen
    Navigator.pushNamed(
      context,
      '/appointment-booking-confirmation',
      arguments: bookingData,
    );
  }

  void _messageLawyer() {
    // Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${_lawyerData?['name'] ?? 'Lawyer'}...'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _callLawyer() {
    // Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${_lawyerData?['name']}...'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
