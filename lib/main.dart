import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'controllers/auth_controller.dart';
import 'theme/app_theme.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // standard modern viewport aspect ratio
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Kargah Yab',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // follow system light/dark mode
          debugShowCheckedModeBanner: false,
          home: authState.when(
            data: (username) {
              if (username == null || username.isEmpty) {
                return const LoginScreen();
              }
              return const HomeScreen();
            },
            loading: () => const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'در حال راه‌اندازی برنامه...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
            error: (err, stack) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text('خطا در راه‌اندازی بانک اطلاعاتی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(err.toString(), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
