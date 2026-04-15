import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'features/home/home_screen.dart';
import 'core/theme/app_colors.dart';
import 'core/services/api_service.dart';
import 'features/auth/widgets/auth_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Periksa status login dari penyimpanan lokal (Persistence)
  final isLoggedIn = await ApiService().isLoggedIn();
  AuthUtils.isLoggedIn = isLoggedIn;

  runApp(const LocalMartApp());
}

class LocalMartApp extends StatelessWidget {
  const LocalMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LocalMart KSB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const HomeScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],
    );
  }
}
