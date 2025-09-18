import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import './supabase_service.dart';

class AuthService {
  static AuthService? _instance;

  AuthService._();

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String role = 'client',
  }) async {
    try {
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'role': role,
        },
      );

      if (response.user != null && response.session != null) {
        print('User signed up successfully: ${response.user!.id}');
        // Insert into user_profiles
        await _client.from('user_profiles').insert({
          'id': response.user!.id,
          'full_name': fullName ?? email.split('@')[0],
          'email': email,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } catch (error) {
      print('Sign up error: $error');
      throw Exception('Sign up failed: $error');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        print('User signed in successfully: ${response.user!.id}');
      }

      return response;
    } catch (error) {
      print('Sign in error: $error');
      throw Exception('Sign in failed: $error');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('User signed out successfully');
    } catch (error) {
      print('Sign out error: $error');
      throw Exception('Sign out failed: $error');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _client
          .from('user_profiles')
          .select('*, lawyer_profiles(*)')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response;
    } catch (error) {
      print('Get user profile error: $error');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>?> updateUserProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> updates = {};

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null)
        updates['profile_image_url'] = profileImageUrl;

      if (updates.isEmpty) return null;

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUser!.id)
          .select()
          .single();

      print('User profile updated successfully');
      return response;
    } catch (error) {
      print('Update user profile error: $error');
      throw Exception('Failed to update profile: $error');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      print('Password reset email sent to: $email');
    } catch (error) {
      print('Reset password error: $error');
      throw Exception('Failed to send reset email: $error');
    }
  }

  // Check user role
  Future<String?> getUserRole() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'];
    } catch (error) {
      print('Get user role error: $error');
      return null;
    }
  }

  // Check if user is lawyer
  Future<bool> isLawyer() async {
    final role = await getUserRole();
    return role == 'lawyer';
  }

  // Check if user is client
  Future<bool> isClient() async {
    final role = await getUserRole();
    return role == 'client';
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  // Pick and upload profile image
  Future<String?> pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    final supabase = Supabase.instance.client;
    final fileBytes = await pickedFile.readAsBytes();
    final fileName = 'profile_images/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

    try {
      final filePath = await supabase.storage
          .from('profile-images-bucket') // Your bucket name
          .uploadBinary(fileName, fileBytes);

      if (filePath == null || filePath.isEmpty) {
        print('Upload error: file path is empty');
        return null;
      }

      final publicUrl = supabase.storage
          .from('profile-images-bucket')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (error) {
      print('Upload error: $error');
      return null;
    }
  }
}
