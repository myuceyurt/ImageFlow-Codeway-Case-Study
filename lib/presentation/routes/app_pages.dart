import 'package:get/get.dart';
import 'package:image_flow/main.dart';
import 'package:image_flow/presentation/pages/home/home_binding.dart';
import 'package:image_flow/presentation/pages/home/home_view.dart';
import 'package:image_flow/presentation/pages/result/result_binding.dart';
import 'package:image_flow/presentation/pages/result/result_view.dart';
import 'package:image_flow/presentation/pages/scan/scan_view.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class AppPages {
  static const initial = Routes.SPLASH;

  static final routes = [
    GetPage<dynamic>(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage<dynamic>(
      name: Routes.SCAN,
      page: () => const ScanView(),
    ),
    GetPage<dynamic>(
      name: Routes.RESULT,
      page: () => const ResultView(),
      binding: ResultBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
  ];
}
