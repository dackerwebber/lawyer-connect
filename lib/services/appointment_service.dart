import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AppointmentService {
  static AppointmentService? _instance;

  AppointmentService._();

  static AppointmentService get instance {
    _instance ??= AppointmentService._();
    return _instance!;
  }

  SupabaseClient get _client => SupabaseService.instance.client;

  // Book a new appointment
  Future<Map<String, dynamic>> bookAppointment({
    required String lawyerId,
    required String appointmentDate,
    required String appointmentTime,
    required String consultationType,
    String? description,
    int durationMinutes = 60,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get lawyer's hourly rate
      final lawyerData = await _client
          .from('lawyer_profiles')
          .select('hourly_rate')
          .eq('id', lawyerId)
          .single();

      final hourlyRate = lawyerData['hourly_rate'] ?? 0.0;
      final totalCost = (hourlyRate * durationMinutes) / 60;

      final response = await _client.from('appointments').insert({
        'client_id': user.id,
        'lawyer_id': lawyerId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'duration_minutes': durationMinutes,
        'consultation_type': consultationType,
        'description': description,
        'total_cost': totalCost,
        'status': 'pending',
      }).select('''
            *,
            lawyer_profiles!inner(
              *,
              user_profiles!inner(full_name, email)
            )
          ''').single();

      return response;
    } catch (error) {
      print('Book appointment error: $error');
      throw Exception('Failed to book appointment: $error');
    }
  }

  // Get user appointments (client or lawyer view)
  Future<List<dynamic>> getUserAppointments({
    String? status,
    int? limit,
    bool upcoming = true,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is a lawyer
      final userProfile = await _client
          .from('user_profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      var query = _client.from('appointments').select('''
        *,
        user_profiles!appointments_client_id_fkey(full_name, profile_image_url),
        lawyer_profiles!inner(
          *,
          user_profiles!lawyer_profiles_user_id_fkey(full_name, profile_image_url)
        )
      ''');

      // Filter by user role
      if (userProfile['role'] == 'lawyer') {
        // Get lawyer profile ID first
        final lawyerProfile = await _client
            .from('lawyer_profiles')
            .select('id')
            .eq('user_id', user.id)
            .single();

        query = query.eq('lawyer_id', lawyerProfile['id']);
      } else {
        query = query.eq('client_id', user.id);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (upcoming) {
        query = query.gte(
            'appointment_date', DateTime.now().toIso8601String().split('T')[0]);
        var orderedQuery = query.order('appointment_date').order('appointment_time');
        
        if (limit != null) {
          orderedQuery = orderedQuery.limit(limit);
        }
        
        final response = await orderedQuery;
        return response;
      } else {
        var orderedQuery = query.order('created_at', ascending: false);
        
        if (limit != null) {
          orderedQuery = orderedQuery.limit(limit);
        }
        
        final response = await orderedQuery;
        return response;
      }
    } catch (error) {
      print('Get user appointments error: $error');
      throw Exception('Failed to fetch appointments: $error');
    }
  }

  // Get appointment by ID
  Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    try {
      final response = await _client.from('appointments').select('''
            *,
            user_profiles!appointments_client_id_fkey(full_name, profile_image_url, email, phone),
            lawyer_profiles!inner(
              *,
              user_profiles!lawyer_profiles_user_id_fkey(full_name, profile_image_url, email, phone)
            )
          ''').eq('id', appointmentId).maybeSingle();

      return response;
    } catch (error) {
      print('Get appointment by ID error: $error');
      throw Exception('Failed to fetch appointment details: $error');
    }
  }

  // Update appointment status
  Future<Map<String, dynamic>?> updateAppointmentStatus(
    String appointmentId,
    String newStatus, {
    String? notes,
    String? meetingLink,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) updates['notes'] = notes;
      if (meetingLink != null) updates['meeting_link'] = meetingLink;

      final response = await _client
          .from('appointments')
          .update(updates)
          .eq('id', appointmentId)
          .select('''
            *,
            user_profiles!appointments_client_id_fkey(full_name, profile_image_url),
            lawyer_profiles!inner(
              *,
              user_profiles!lawyer_profiles_user_id_fkey(full_name, profile_image_url)
            )
          ''').single();

      return response;
    } catch (error) {
      print('Update appointment status error: $error');
      throw Exception('Failed to update appointment: $error');
    }
  }

  // Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, {String? reason}) async {
    try {
      await _client.from('appointments').update({
        'status': 'cancelled',
        'notes': reason ?? 'Cancelled by user',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', appointmentId);

      return true;
    } catch (error) {
      print('Cancel appointment error: $error');
      throw Exception('Failed to cancel appointment: $error');
    }
  }

  // Get appointment statistics for lawyer dashboard
  Future<Map<String, dynamic>> getAppointmentStats() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get lawyer profile ID
      final lawyerProfile = await _client
          .from('lawyer_profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final lawyerId = lawyerProfile['id'];

      final todayAppointments = await _client
          .from('appointments')
          .select('id')
          .eq('lawyer_id', lawyerId)
          .eq('appointment_date',
              DateTime.now().toIso8601String().split('T')[0])
          .count();

      final pendingAppointments = await _client
          .from('appointments')
          .select('id')
          .eq('lawyer_id', lawyerId)
          .eq('status', 'pending')
          .count();

      final completedThisMonth = await _client
          .from('appointments')
          .select('id')
          .eq('lawyer_id', lawyerId)
          .eq('status', 'completed')
          .gte('appointment_date',
              '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01')
          .count();

      return {
        'today_appointments': todayAppointments.count ?? 0,
        'pending_requests': pendingAppointments.count ?? 0,
        'completed_this_month': completedThisMonth.count ?? 0,
      };
    } catch (error) {
      print('Get appointment stats error: $error');
      throw Exception('Failed to fetch appointment statistics: $error');
    }
  }

  // Get available time slots for a lawyer on a specific date
  Future<List<String>> getAvailableTimeSlots(
    String lawyerId,
    String date,
  ) async {
    try {
      final dateTime = DateTime.parse(date);
      final dayOfWeek =
          dateTime.weekday % 7; // Convert to 0-6 format (0 = Sunday)

      // Get lawyer availability for the day
      final availability = await _client
          .from('lawyer_availability')
          .select('start_time, end_time')
          .eq('lawyer_id', lawyerId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_available', true);

      if (availability.isEmpty) {
        return [];
      }

      // Get existing appointments for that date
      final existingAppointments = await _client
          .from('appointments')
          .select('appointment_time, duration_minutes')
          .eq('lawyer_id', lawyerId)
          .eq('appointment_date', date)
          .neq('status', 'cancelled');

      // Generate available time slots (simplified logic)
      List<String> availableSlots = [];

      for (var slot in availability) {
        final startTime = slot['start_time'] as String;
        final endTime = slot['end_time'] as String;

        // Generate hourly slots between start and end time
        final start = TimeOfDay.fromString(startTime);
        final end = TimeOfDay.fromString(endTime);

        for (int hour = start.hour; hour < end.hour; hour++) {
          final timeSlot = '${hour.toString().padLeft(2, '0')}:00';

          // Check if slot is not booked
          bool isBooked = existingAppointments.any((appointment) {
            return appointment['appointment_time'] == timeSlot;
          });

          if (!isBooked) {
            availableSlots.add(timeSlot);
          }
        }
      }

      return availableSlots;
    } catch (error) {
      print('Get available time slots error: $error');
      throw Exception('Failed to fetch available time slots: $error');
    }
  }
}

// Helper class for time parsing
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  static TimeOfDay fromString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}