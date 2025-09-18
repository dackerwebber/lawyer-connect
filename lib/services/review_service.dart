import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class ReviewService {
  static ReviewService? _instance;

  ReviewService._();

  static ReviewService get instance {
    _instance ??= ReviewService._();
    return _instance!;
  }

  SupabaseClient get _client => SupabaseService.instance.client;

  // Submit a review for a completed appointment
  Future<Map<String, dynamic>> submitReview({
    required String lawyerId,
    required String appointmentId,
    required int rating,
    String? reviewText,
    bool isAnonymous = false,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if appointment is completed and belongs to user
      final appointment = await _client
          .from('appointments')
          .select('status, client_id')
          .eq('id', appointmentId)
          .single();

      if (appointment['client_id'] != user.id) {
        throw Exception('Unauthorized to review this appointment');
      }

      if (appointment['status'] != 'completed') {
        throw Exception('Can only review completed appointments');
      }

      // Check if review already exists
      final existingReview = await _client
          .from('reviews')
          .select('id')
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (existingReview != null) {
        throw Exception('Review already submitted for this appointment');
      }

      final response = await _client.from('reviews').insert({
        'client_id': user.id,
        'lawyer_id': lawyerId,
        'appointment_id': appointmentId,
        'rating': rating,
        'review_text': reviewText,
        'is_anonymous': isAnonymous,
      }).select('''
            *,
            user_profiles!reviews_client_id_fkey(full_name, profile_image_url)
          ''').single();

      return response;
    } catch (error) {
      print('Submit review error: $error');
      throw Exception('Failed to submit review: $error');
    }
  }

  // Get reviews for a specific lawyer
  Future<List<dynamic>> getLawyerReviews(
    String lawyerId, {
    int? limit,
    int? rating,
  }) async {
    try {
      var query = _client.from('reviews').select('''
            *,
            user_profiles!reviews_client_id_fkey(full_name, profile_image_url)
          ''').eq('lawyer_id', lawyerId);

      if (rating != null) {
        query = query.eq('rating', rating);
      }

      var orderedQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      return response;
    } catch (error) {
      print('Get lawyer reviews error: $error');
      throw Exception('Failed to fetch reviews: $error');
    }
  }

  // Get review statistics for a lawyer
  Future<Map<String, dynamic>> getLawyerReviewStats(String lawyerId) async {
    try {
      // Get all reviews for rating distribution
      final reviews = await _client
          .from('reviews')
          .select('rating')
          .eq('lawyer_id', lawyerId);

      if (reviews.isEmpty) {
        return {
          'total_reviews': 0,
          'average_rating': 0.0,
          'rating_distribution': {
            '5': 0,
            '4': 0,
            '3': 0,
            '2': 0,
            '1': 0,
          },
        };
      }

      // Calculate statistics
      final totalReviews = reviews.length;
      final ratings = reviews.map((review) => review['rating'] as int).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / totalReviews;

      // Calculate rating distribution
      Map<String, int> distribution = {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };

      for (int rating in ratings) {
        distribution[rating.toString()] =
            (distribution[rating.toString()] ?? 0) + 1;
      }

      return {
        'total_reviews': totalReviews,
        'average_rating': double.parse(averageRating.toStringAsFixed(2)),
        'rating_distribution': distribution,
      };
    } catch (error) {
      print('Get lawyer review stats error: $error');
      throw Exception('Failed to fetch review statistics: $error');
    }
  }

  // Get reviews submitted by the current user
  Future<List<dynamic>> getUserReviews({int? limit}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      var query = _client.from('reviews').select('''
            *,
            lawyer_profiles!reviews_lawyer_id_fkey(
              *,
              user_profiles!lawyer_profiles_user_id_fkey(full_name, profile_image_url)
            ),
            appointments!reviews_appointment_id_fkey(appointment_date, consultation_type)
          ''').eq('client_id', user.id).order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return response;
    } catch (error) {
      print('Get user reviews error: $error');
      throw Exception('Failed to fetch user reviews: $error');
    }
  }

  // Update a review (if allowed)
  Future<Map<String, dynamic>?> updateReview(
    String reviewId, {
    int? rating,
    String? reviewText,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> updates = {};

      if (rating != null) {
        if (rating < 1 || rating > 5) {
          throw Exception('Rating must be between 1 and 5');
        }
        updates['rating'] = rating;
      }

      if (reviewText != null) {
        updates['review_text'] = reviewText;
      }

      if (updates.isEmpty) return null;

      final response = await _client
          .from('reviews')
          .update(updates)
          .eq('id', reviewId)
          .eq('client_id', user.id) // Ensure user owns the review
          .select('''
            *,
            user_profiles!reviews_client_id_fkey(full_name, profile_image_url)
          ''').single();

      return response;
    } catch (error) {
      print('Update review error: $error');
      throw Exception('Failed to update review: $error');
    }
  }

  // Delete a review (if allowed)
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('client_id', user.id); // Ensure user owns the review

      return true;
    } catch (error) {
      print('Delete review error: $error');
      throw Exception('Failed to delete review: $error');
    }
  }

  // Check if user can review an appointment
  Future<bool> canReviewAppointment(String appointmentId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // Check if appointment is completed and belongs to user
      final appointment = await _client
          .from('appointments')
          .select('status, client_id')
          .eq('id', appointmentId)
          .maybeSingle();

      if (appointment == null ||
          appointment['client_id'] != user.id ||
          appointment['status'] != 'completed') {
        return false;
      }

      // Check if review already exists
      final existingReview = await _client
          .from('reviews')
          .select('id')
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      return existingReview == null;
    } catch (error) {
      print('Can review appointment error: $error');
      return false;
    }
  }
}