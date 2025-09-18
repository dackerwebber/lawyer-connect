import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class LawyerService {
  static LawyerService? _instance;

  LawyerService._();

  static LawyerService get instance {
    _instance ??= LawyerService._();
    return _instance!;
  }

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get all verified lawyers
  Future<List<dynamic>> getAvailableLawyers({
    List<String>? specializations,
    int? limit,
  }) async {
    try {
      var query = _client.from('lawyer_profiles').select('''
            *, 
            user_profiles!inner(full_name, profile_image_url, email),
            lawyer_gallery(image_url, caption)
          ''').eq('is_verified', true);

      if (specializations != null && specializations.isNotEmpty) {
        query = query.overlaps('specializations', specializations);
      }

      var transformBuilder = query.order('average_rating', ascending: false);

      if (limit != null) {
        transformBuilder = transformBuilder.limit(limit);
      }

      final response = await transformBuilder;
      print('GetAvailableLawyers response: $response'); // <-- Add this line
      return response;
    } catch (error) {
      print('Get available lawyers error: $error');
      throw Exception('Failed to fetch lawyers: $error');
    }
  }

  // Get lawyer by ID
  Future<Map<String, dynamic>?> getLawyerById(String lawyerId) async {
    try {
      final response = await _client.from('lawyer_profiles').select('''
            *, 
            user_profiles!inner(full_name, profile_image_url, email, phone),
            lawyer_gallery(id, image_url, caption, display_order),
            lawyer_availability(day_of_week, start_time, end_time, is_available)
          ''').eq('id', lawyerId).eq('is_verified', true).maybeSingle();

      print('GetLawyerById response: $response'); // <-- Add this line
      return response;
    } catch (error) {
      print('Get lawyer by ID error: $error');
      throw Exception('Failed to fetch lawyer details: $error');
    }
  }

  // Get lawyer reviews
  Future<List<dynamic>> getLawyerReviews(String lawyerId, {int? limit}) async {
    try {
      var query = _client.from('reviews').select('''
            *,
            user_profiles!inner(full_name, profile_image_url)
          ''').eq('lawyer_id', lawyerId).order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return response;
    } catch (error) {
      print('Get lawyer reviews error: $error');
      throw Exception('Failed to fetch reviews: $error');
    }
  }

  // Get lawyer availability for specific date
  Future<List<dynamic>> getLawyerAvailability(
      String lawyerId, int dayOfWeek) async {
    try {
      final response = await _client
          .from('lawyer_availability')
          .select('*')
          .eq('lawyer_id', lawyerId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_available', true)
          .order('start_time');

      return response;
    } catch (error) {
      print('Get lawyer availability error: $error');
      throw Exception('Failed to fetch availability: $error');
    }
  }

  // Search lawyers
  Future<List<dynamic>> searchLawyers({
    String? query,
    List<String>? specializations,
    double? minRating,
    int? maxHourlyRate,
    int? limit,
  }) async {
    try {
      var supabaseQuery = _client.from('lawyer_profiles').select('''
            *, 
            user_profiles!inner(full_name, profile_image_url, email)
          ''').eq('is_verified', true);

      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery
            .or('bio.ilike.%$query%,user_profiles.full_name.ilike.%$query%');
      }

      if (specializations != null && specializations.isNotEmpty) {
        supabaseQuery =
            supabaseQuery.overlaps('specializations', specializations);
      }

      if (minRating != null) {
        supabaseQuery = supabaseQuery.gte('average_rating', minRating);
      }

      if (maxHourlyRate != null) {
        supabaseQuery = supabaseQuery.lte('hourly_rate', maxHourlyRate);
      }

      var transformBuilder = supabaseQuery.order('average_rating', ascending: false);

      if (limit != null) {
        transformBuilder = transformBuilder.limit(limit);
      }

      final response = await transformBuilder;
      return response;
    } catch (error) {
      print('Search lawyers error: $error');
      throw Exception('Failed to search lawyers: $error');
    }
  }

  // Update lawyer profile (for lawyers only)
  Future<Map<String, dynamic>?> updateLawyerProfile({
    String? bio,
    double? hourlyRate,
    List<String>? specializations,
    String? education,
    List<String>? certifications,
    List<String>? languages,
    String? officeAddress,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> updates = {};

      if (bio != null) updates['bio'] = bio;
      if (hourlyRate != null) updates['hourly_rate'] = hourlyRate;
      if (specializations != null) updates['specializations'] = specializations;
      if (education != null) updates['education'] = education;
      if (certifications != null) updates['certifications'] = certifications;
      if (languages != null) updates['languages'] = languages;
      if (officeAddress != null) updates['office_address'] = officeAddress;

      if (updates.isEmpty) return null;

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('lawyer_profiles')
          .update(updates)
          .eq('user_id', user.id)
          .select()
          .single();

      return response;
    } catch (error) {
      print('Update lawyer profile error: $error');
      throw Exception('Failed to update lawyer profile: $error');
    }
  }

  // Get lawyer statistics
  Future<Map<String, dynamic>> getLawyerStats(String lawyerId) async {
    try {
      final appointmentsData = await _client
          .from('appointments')
          .select('id')
          .eq('lawyer_id', lawyerId)
          .count();

      final completedData = await _client
          .from('appointments')
          .select('id')
          .eq('lawyer_id', lawyerId)
          .eq('status', 'completed')
          .count();

      final reviewsData = await _client
          .from('reviews')
          .select('id')
          .eq('lawyer_id', lawyerId)
          .count();

      return {
        'total_appointments': appointmentsData.count ?? 0,
        'completed_appointments': completedData.count ?? 0,
        'total_reviews': reviewsData.count ?? 0,
        'completion_rate':
            appointmentsData.count > 0
                ? double.parse(
                    ((completedData.count / appointmentsData.count) * 100)
                        .toStringAsFixed(1))
                : 0.0,
      };
    } catch (error) {
      print('Get lawyer stats error: $error');
      throw Exception('Failed to fetch lawyer statistics: $error');
    }
  }
}