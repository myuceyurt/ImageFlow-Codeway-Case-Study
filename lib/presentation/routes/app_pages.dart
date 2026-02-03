import 'package:get/get.dart';
import 'package:image_flow/main.dart';
import 'package:image_flow/presentation/pages/history_detail/history_detail_binding.dart';
import 'package:image_flow/presentation/pages/history_detail/history_detail_view.dart';
import 'package:image_flow/presentation/pages/home/home_binding.dart';
import 'package:image_flow/presentation/pages/home/home_view.dart';
import 'package:image_flow/presentation/pages/processing/processing_binding.dart';
import 'package:image_flow/presentation/pages/processing/processing_view.dart';
import 'package:image_flow/presentation/pages/result/result_binding.dart';
import 'package:image_flow/presentation/pages/result/result_view.dart';
import 'package:image_flow/presentation/pages/scan/scan_view.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage<dynamic>(
      name: Routes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage<dynamic>(
      name: Routes.scan,
      page: () => const ScanView(),
    ),
    GetPage<dynamic>(
      name: Routes.result,
      page: () => const ResultView(),
      binding: ResultBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.processing,
      page: () => const ProcessingView(),
      binding: ProcessingBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.historyDetail,
      page: () => const HistoryDetailView(),
      binding: HistoryDetailBinding(),
    ),
  ];
}
