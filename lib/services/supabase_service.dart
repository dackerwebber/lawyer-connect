import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    try {
      // Load environment configuration
      await dotenv.load(fileName: 'assets/.env');
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Supabase URL or Anon Key not found in environment variables');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      print('Supabase initialized successfully');
    } catch (error) {
      print('Supabase initialization failed: $error');
      rethrow;
    }
  }

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? role,
  }) async {
    try {
      final AuthResponse response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
          'role': role ?? 'client',
        },
      );
      return response;
    } catch (error) {
      throw Exception('Sign up failed: $error');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign in failed: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _client!.auth.signOut();
    } catch (error) {
      throw Exception('Sign out failed: $error');
    }
  }

  User? get currentUser => _client!.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client!.auth.onAuthStateChange;

  // Database methods
  Future<List<dynamic>> select(String table) async {
    try {
      final response = await _client!.from(table).select();
      return response;
    } catch (error) {
      throw Exception('Select failed: $error');
    }
  }

  Future<List<dynamic>> insert(String table, Map<String, dynamic> data) async {
    try {
      final response = await _client!.from(table).insert(data).select();
      return response;
    } catch (error) {
      throw Exception('Insert failed: $error');
    }
  }

  Future<List<dynamic>> update(
    String table,
    Map<String, dynamic> data,
    String column,
    dynamic value,
  ) async {
    try {
      final response =
          await _client!.from(table).update(data).eq(column, value).select();
      return response;
    } catch (error) {
      throw Exception('Update failed: $error');
    }
  }

  Future<List<dynamic>> delete(
    String table,
    String column,
    dynamic value,
  ) async {
    try {
      final response =
          await _client!.from(table).delete().eq(column, value).select();
      return response;
    } catch (error) {
      throw Exception('Delete failed: $error');
    }
  }
}
