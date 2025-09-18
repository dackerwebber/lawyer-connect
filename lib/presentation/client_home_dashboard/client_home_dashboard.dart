import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lawyerconnect/presentation/client_home_dashboard/widgets/profile_tab.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import './widgets/available_lawyers_list_widget.dart';
import './widgets/book_appointment_hero_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/recent_appointments_widget.dart';

class ClientHomeDashboard extends StatefulWidget {
  const ClientHomeDashboard({Key? key}) : super(key: key);

  @override
  State<ClientHomeDashboard> createState() => _ClientHomeDashboardState();
}

class _ClientHomeDashboardState extends State<ClientHomeDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isRefreshing = false;

  Future<List<Map<String, dynamic>>> _fetchAvailableLawyers() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('lawyers')
        .select()
        .eq('isAvailable', true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchRecentAppointments() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await supabase
        .from('appointments')
        .select('*, lawyer:lawyers(*)')
        .eq('client_id', userId)
        .order('date', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> _fetchClientData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await supabase
        .from('clients')
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_currentIndex == 3) {
      body = const ProfileTabWidget();
    } else {
      body = SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.lightTheme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingHeaderWidget(
                      userName: 'Hello User',
                      onNotificationTap: _handleNotificationTap,
                    ),
                    BookAppointmentHeroWidget(
                      onBookAppointmentTap: _handleBookAppointment,
                    ),
                    SizedBox(height: 2.h),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchAvailableLawyers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading lawyers');
                        }
                        final lawyers = snapshot.data ?? [];
                        return AvailableLawyersListWidget(
                          availableLawyers: lawyers,
                          onLawyerTap: _handleLawyerTap,
                        );
                      },
                    ),
                    SizedBox(height: 3.h),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchRecentAppointments(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading appointments');
                        }
                        final appointments = snapshot.data ?? [];
                        return RecentAppointmentsWidget(
                          appointments: appointments,
                          onReschedule: _handleRescheduleAppointment,
                          onCancel: _handleCancelAppointment,
                          onMessage: _handleMessageLawyer,
                          onAppointmentTap: _handleAppointmentTap,
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'home',
                  color: _currentIndex == 0
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'calendar_today',
              color: _currentIndex == 1
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'message',
                  color: _currentIndex == 2
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentIndex == 3
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _handleEmergencyConsultation,
      backgroundColor: AppTheme.lightTheme.colorScheme.error,
      foregroundColor: AppTheme.lightTheme.colorScheme.onError,
      icon: CustomIconWidget(
        iconName: 'emergency',
        color: AppTheme.lightTheme.colorScheme.onError,
        size: 20,
      ),
      label: Text(
        'Emergency',
        style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onError,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate network refresh
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });

    Fluttertoast.showToast(
      msg: "Updated lawyer availability",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      textColor: AppTheme.lightTheme.colorScheme.onPrimary,
    );
  }

  void _handleNotificationTap() {
    Fluttertoast.showToast(
      msg: "You have 2 new notifications",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleBookAppointment() {
    Navigator.pushNamed(context, '/lawyer-profile-booking');
  }

  void _handleLawyerTap(Map<String, dynamic> lawyer) {
    Navigator.pushNamed(
      context,
      '/lawyer-profile-booking',
      arguments: lawyer,
    );
  }

  void _handleRescheduleAppointment(Map<String, dynamic> appointment) {
    Fluttertoast.showToast(
      msg: "Reschedule appointment with ${appointment['lawyerName']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleCancelAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel your appointment with ${appointment['lawyerName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Trigger a refresh by calling _handleRefresh or setState to rebuild
              });
              Fluttertoast.showToast(
                msg: "Appointment cancelled successfully",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  void _handleMessageLawyer(Map<String, dynamic> appointment) {
    Fluttertoast.showToast(
      msg: "Opening chat with ${appointment['lawyerName']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleAppointmentTap(Map<String, dynamic> appointment) {
    Navigator.pushNamed(
      context,
      '/appointment-booking-confirmation',
      arguments: appointment,
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Fluttertoast.showToast(
          msg: "Navigating to Appointments",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        break;
      case 2:
        Navigator.pushNamed(context, '/messages');
        break;
      case 3:
        Fluttertoast.showToast(
          msg: "Navigating to Profile",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        break;
    }
  }

  void _handleEmergencyConsultation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'emergency',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Emergency Consultation'),
          ],
        ),
        content: Text(
          'Connect with an available lawyer immediately for urgent legal matters. Emergency consultations are available 24/7.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Connecting you with an emergency lawyer...",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
                textColor: AppTheme.lightTheme.colorScheme.onError,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Connect Now'),
          ),
        ],
      ),
    );
  }
}
