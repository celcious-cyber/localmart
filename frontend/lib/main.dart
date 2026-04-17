import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'features/home/home_screen.dart';
import 'core/theme/app_colors.dart';
import 'core/services/api_service.dart';
import 'features/auth/widgets/auth_utils.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/profile/screens/help_center_screen.dart';
import 'features/profile/screens/selling_guide_screen.dart';
import 'features/chat/screens/chat_room_screen.dart';

// Import Module Discovery Screens
import 'features/localfood/localfood_screen.dart';
import 'features/kost/kost_screen.dart';
import 'features/rental/rental_screen.dart';
import 'features/transport/transport_screen.dart';
import 'features/service/service_screen.dart';
import 'features/umkm/umkm_screen.dart';
import 'features/agri/agri_screen.dart';
import 'features/tourism/tourism_screen.dart';
import 'features/second_hand/second_hand_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register AuthController (Global)
  Get.put(AuthController());
  
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
        GetPage(name: '/help-center', page: () => HelpCenterScreen()),
        GetPage(name: '/selling-guide', page: () => const SellingGuideScreen()),
        GetPage(name: '/chat-room', page: () => const ChatRoomScreen()),
        
        // Modular Discovery Routes
        GetPage(name: '/localfood', page: () => const LocalFoodScreen()),
        GetPage(name: '/kost', page: () => const KostScreen()),
        GetPage(name: '/rental', page: () => const RentalScreen()),
        GetPage(name: '/transport', page: () => const TransportScreen()),
        GetPage(name: '/service', page: () => const ServiceScreen()),
        GetPage(name: '/umkm', page: () => const UMKMScreen()),
        GetPage(name: '/agri', page: () => const AgriScreen()),
        GetPage(name: '/tourism', page: () => const TourismScreen()),
        GetPage(name: '/second-hand', page: () => const SecondHandScreen()),
      ],
    );
  }
}
