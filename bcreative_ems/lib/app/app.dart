import 'package:bcreative_ems/app/bindings/initial_binding.dart';
import 'package:bcreative_ems/app/routes/app_pages.dart';
import 'package:bcreative_ems/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BCreativeApp extends StatelessWidget {
  const BCreativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BCreative EMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
