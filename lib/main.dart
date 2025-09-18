import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './routes/app_routes.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (error) {
    print('Failed to initialize Supabase: $error');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.0)),
          child: MaterialApp(
              title: 'LawyerConnect',
              debugShowCheckedModeBanner: false,
              initialRoute: AppRoutes.initial,
              routes: AppRoutes.routes));
    });
  }
}
