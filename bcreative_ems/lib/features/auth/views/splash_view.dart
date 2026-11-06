import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoading(message: 'Loading…'));
  }
}
