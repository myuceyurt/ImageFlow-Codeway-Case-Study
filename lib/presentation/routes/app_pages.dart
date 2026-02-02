import 'package:get/get.dart';
import 'package:image_flow/main.dart';
import 'package:image_flow/presentation/pages/result/result_binding.dart';
import 'package:image_flow/presentation/pages/result/result_view.dart';
import 'package:image_flow/presentation/pages/scan/scan_view.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.SCAN,
      page: () => const ScanView(),
    ),
    GetPage(
      name: Routes.RESULT,
      page: () => const ResultView(),
      binding: ResultBinding(),
    ),
  ];
}
