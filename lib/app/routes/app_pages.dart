import 'package:get/get.dart';

import '../modules/home/binding.dart';
import '../modules/home/view.dart';
import '../modules/splash/binding.dart';
import '../modules/splash/view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),

  ];
}
