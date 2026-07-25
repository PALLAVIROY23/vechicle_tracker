import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.count;
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          "assets/animations/Globe Animation.json",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}