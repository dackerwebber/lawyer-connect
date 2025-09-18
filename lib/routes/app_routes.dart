import 'package:flutter/material.dart';
import '../presentation/client_home_dashboard/client_home_dashboard.dart';
import '../presentation/lawyer_profile_booking/lawyer_profile_booking.dart';
import '../presentation/lawyer_dashboard/lawyer_dashboard.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/role_selection_registration/role_selection_registration.dart';
import '../presentation/appointment_booking_confirmation/appointment_booking_confirmation.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/messages_screen/messages_screen.dart';

class AppRoutes {
  static const String initial = '/splash-screen'; // Set splash as initial
  static const String clientHomeDashboard = '/client-home-dashboard';
  static const String lawyerProfileBooking = '/lawyer-profile-booking';
  static const String lawyerDashboard = '/lawyer-dashboard';
  static const String login = '/login'; // Use '/login'
  static const String roleSelectionRegistration =
      '/role-selection-registration';
  static const String appointmentBookingConfirmation =
      '/appointment-booking-confirmation';
  static const String messages = '/messages';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(), // Splash screen as initial
    clientHomeDashboard: (context) => const ClientHomeDashboard(),
    lawyerProfileBooking: (context) => const LawyerProfileBooking(),
    lawyerDashboard: (context) => const LawyerDashboard(),
    login: (context) => const LoginScreen(), // Use '/login'
    roleSelectionRegistration: (context) => const RoleSelectionRegistration(),
    appointmentBookingConfirmation: (context) =>
        const AppointmentBookingConfirmation(),
    messages: (context) => MessagesScreen(messageList: [
      {'sender': 'Client A', 'content': 'Hello!', 'time': '10:30 AM'},
      {'sender': 'Client B', 'content': 'Can we reschedule?', 'time': 'Yesterday'},
    ]),
  };
}

void main() {
  runApp(
    MaterialApp(
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    ),
  );
}
