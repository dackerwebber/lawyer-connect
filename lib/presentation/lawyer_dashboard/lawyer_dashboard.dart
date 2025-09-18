import 'package:flutter/material.dart';
import 'package:lawyerconnect/presentation/lawyer_dashboard/widgets/real_time_calendar_widget.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import './widgets/appointment_timeline_widget.dart';
import './widgets/availability_toggle_widget.dart';
import './widgets/metrics_card_widget.dart';
import './widgets/pending_request_card_widget.dart';
import './widgets/quick_actions_widget.dart';

import '../messages_screen/messages_screen.dart';
import 'package:lawyerconnect/presentation/lawyer_dashboard/widgets/ghana_holidays.dart';


class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({Key? key}) : super(key: key);

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isAvailable = true;
  late TabController _tabController;

  Map<String, dynamic>? lawyerInfo;
  List<Map<String, dynamic>> pendingRequests = [];
  List<Map<String, dynamic>> todayAppointments = [];
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchDashboardData();
  }

  Future<Map<String, dynamic>?> _fetchLawyerInfo() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await supabase
        .from('lawyers')
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchPendingRequests() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await supabase
        .from('requests')
        .select()
        .eq('lawyer_id', userId)
        .eq('status', 'pending');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchTodayAppointments() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await supabase
        .from('appointments')
        .select()
        .eq('lawyer_id', userId)
        .gte('date', today)
        .lte('date', today);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _fetchDashboardData() async {
    final supabase = Supabase.instance.client;
    // Replace 'lawyers', 'requests', 'appointments' with your actual table names

    // Fetch lawyer info (example: get by current user id)
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final lawyerRes = await supabase
          .from('lawyers')
          .select()
          .eq('user_id', userId)
          .single();
      setState(() {
        lawyerInfo = lawyerRes;
      });
    }

    // Fetch pending requests
    final requestsRes = await _fetchPendingRequests();
    setState(() {
      pendingRequests = requestsRes;
    });

    // Fetch today's appointments
    final appointmentsRes = await _fetchTodayAppointments();
    setState(() {
      todayAppointments = appointmentsRes;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_currentIndex == 1) {
      body = RealTimeCalendarWidget(
        appointments: todayAppointments,
        holidays: ghanaHolidays, // Define this list in your code
      );
    } else if (_currentIndex == 2) {
      body = MessagesScreen(messageList: messages);
    } else {
      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingHeader(),
            SizedBox(height: 2.h),
            AvailabilityToggleWidget(
              isAvailable: _isAvailable,
              onToggle: (value) {
                _updateAvailability(value);
              },
            ),
            SizedBox(height: 3.h),
            _buildMetricsCards(),
            SizedBox(height: 3.h),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPendingRequests(),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];
                return _buildPendingRequestsSection(requests);
              },
            ),
            SizedBox(height: 3.h),
            _buildTodayAppointmentsSection(),
            SizedBox(height: 2.h),
            QuickActionsWidget(
              onBlockTime: _handleBlockTime,
              onUpdateRates: _handleUpdateRates,
              onViewCalendar: _handleViewCalendar,
            ),
            SizedBox(height: 10.h), // Bottom padding for FAB
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: body,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.all(2.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomImageWidget(
            imageUrl: lawyerInfo?['profileImage'] as String? ?? '',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        'Dashboard',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _handleNotifications,
          icon: Stack(
            children: [
              CustomIconWidget(
                iconName: 'notifications',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              if (pendingRequests.isNotEmpty)
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
        ),
        IconButton(
          onPressed: _handleSettings,
          icon: CustomIconWidget(
            iconName: 'settings',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingHeader() {
    final DateTime now = DateTime.now();
    final String greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            lawyerInfo?['name'] as String? ?? '',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            lawyerInfo?['specialization'] as String? ?? '',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (lawyerInfo?['licenseDescription'] != null &&
              (lawyerInfo?['licenseDescription'] as String).isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 0.5.h),
              child: Text(
                lawyerInfo?['licenseDescription'] as String,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MetricsCardWidget(
            title: 'Today',
            value: '${lawyerInfo?['todayAppointments'] ?? 0}',
            subtitle: 'Appointments',
            backgroundColor:
                AppTheme.lightTheme.colorScheme.primary.withAlpha(25),
            onTap: _handleTodayAppointmentsTap,
          ),
          MetricsCardWidget(
            title: 'Pending',
            value: '${lawyerInfo?['pendingRequests'] ?? 0}',
            subtitle: 'Requests',
            backgroundColor:
                AppTheme.lightTheme.colorScheme.tertiary.withAlpha(25),
            onTap: _handlePendingRequestsTap,
          ),
          MetricsCardWidget(
            title: 'Weekly',
            value: lawyerInfo?['weeklyEarnings'] as String? ?? '',
            subtitle: 'Earnings',
            backgroundColor:
                AppTheme.lightTheme.colorScheme.secondary.withAlpha(25),
            onTap: _handleWeeklyEarningsTap,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection(List<Map<String, dynamic>> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Requests',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              if (requests.length > 2)
                TextButton(
                  onPressed: _handleViewAllRequests,
                  child: Text(
                    'View All',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        requests.isEmpty
            ? _buildEmptyPendingRequests()
            : Column(
                children: requests.take(2).map((request) {
                  return PendingRequestCardWidget(
                    request: request,
                    onAccept: () => _handleAcceptRequest(request),
                    onDecline: () => _handleDeclineRequest(request),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildTodayAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Today\'s Appointments',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        todayAppointments.isEmpty
            ? _buildEmptyAppointments()
            : Column(
                children: todayAppointments.map((appointment) {
                  return AppointmentTimelineWidget(
                    appointment: appointment,
                    onReschedule: () =>
                        _handleRescheduleAppointment(appointment),
                    onAddNotes: () => _handleAddNotes(appointment),
                    onMessageClient: () => _handleMessageClient(appointment),
                    onMarkComplete: () => _handleMarkComplete(appointment),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyPendingRequests() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'inbox',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Pending Requests',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'New client requests will appear here',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'event_available',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Appointments Today',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your schedule is clear for today',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard',
            color: _currentIndex == 0
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'calendar_today',
            color: _currentIndex == 1
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'people',
            color: _currentIndex == 2
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Clients',
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
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _handleQuickAvailabilityToggle,
      backgroundColor: _isAvailable
          ? AppTheme.lightTheme.colorScheme.tertiary
          : AppTheme.lightTheme.colorScheme.secondary,
      foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
      icon: CustomIconWidget(
        iconName: _isAvailable ? 'pause' : 'play_arrow',
        color: AppTheme.lightTheme.colorScheme.onPrimary,
        size: 20,
      ),
      label: Text(
        _isAvailable ? 'Block Time' : 'Go Available',
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Event handlers
  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh data logic would go here
    });
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        // Navigate to calendar
        break;
      case 2:
        // Navigate to clients
        break;
      case 3:
        // Navigate to profile
        break;
    }
  }

  void _handleNotifications() {
    // Handle notifications tap
  }

  void _handleSettings() {
    // Handle settings tap
  }

  void _handleTodayAppointmentsTap() {
    // Handle today appointments card tap
  }

  void _handlePendingRequestsTap() {
    // Handle pending requests card tap
  }

  void _handleWeeklyEarningsTap() {
    // Handle weekly earnings card tap
  }

  void _handleViewAllRequests() {
    // Handle view all requests
  }

  void _handleAcceptRequest(Map<String, dynamic> request) {
    setState(() {
      pendingRequests.removeWhere((r) => r['id'] == request['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment request accepted'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDeclineRequest(Map<String, dynamic> request) {
    setState(() {
      pendingRequests.removeWhere((r) => r['id'] == request['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment request declined'),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleRescheduleAppointment(Map<String, dynamic> appointment) {
    // Handle reschedule appointment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Reschedule appointment for ${appointment['clientName']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleAddNotes(Map<String, dynamic> appointment) {
    // Handle add notes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add notes for ${appointment['clientName']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMessageClient(Map<String, dynamic> appointment) {
    // Handle message client
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message ${appointment['clientName']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMarkComplete(Map<String, dynamic> appointment) {
    setState(() {
      final index =
          todayAppointments.indexWhere((a) => a['id'] == appointment['id']);
      if (index != -1) {
        todayAppointments[index]['status'] = 'Completed';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment marked as completed'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBlockTime() {
    // Handle block time
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Block time slot'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleUpdateRates() {
    // Handle update rates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update consultation rates'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleViewCalendar() {
    // Handle view calendar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View full calendar'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleQuickAvailabilityToggle() {
    setState(() {
      _isAvailable = !_isAvailable;
    });
    _showAvailabilityUpdateMessage(_isAvailable);
  }

  void _showAvailabilityUpdateMessage(bool isAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAvailable
              ? 'You are now available for appointments'
              : 'Availability paused - new bookings blocked',
        ),
        backgroundColor: isAvailable
            ? AppTheme.lightTheme.colorScheme.secondary
            : AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateAvailability(bool value) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('lawyers')
        .update({'isAvailable': value})
        .eq('user_id', userId);
    setState(() {
      _isAvailable = value;
    });
  }
}
