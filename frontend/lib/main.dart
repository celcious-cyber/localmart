import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/theme/app_colors.dart';
import 'core/services/api_service.dart';
import 'features/auth/widgets/auth_utils.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/profile/screens/help_center_screen.dart';
import 'features/profile/screens/selling_guide_screen.dart';
import 'features/chat/screens/chat_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register AuthController (Global)
  Get.put(AuthController());
  
  // Periksa status login dari penyimpanan lokal (Persistence)
  final isLoggedIn = await ApiService().isLoggedIn();
  AuthUtils.isLoggedIn = isLoggedIn;

  // Periksa apakah perlu menampilkan Onboarding
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;

  runApp(LocalMartApp(showOnboarding: showOnboarding));
}

class LocalMartApp extends StatelessWidget {
  final bool showOnboarding;
  const LocalMartApp({super.key, required this.showOnboarding});

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
      initialRoute: showOnboarding ? '/onboarding' : '/',
      getPages: [
        GetPage(name: '/', page: () => const HomeScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/help-center', page: () => HelpCenterScreen()),
        GetPage(name: '/selling-guide', page: () => const SellingGuideScreen()),
        GetPage(name: '/chat-room', page: () => const ChatRoomScreen()),
      ],
    );
  }
}
