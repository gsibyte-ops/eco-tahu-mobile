import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/order_provider.dart';
import 'providers/store_provider.dart';
import 'providers/theme_provider.dart';
import 'services/local_notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  await LocalNotificationService.instance.init(navigatorKey: appNavigatorKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()..loadCart()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => StoreProvider()..loadStoreInfo()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'EcoTahu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              final uri = Uri.tryParse(settings.name ?? '');
              if (uri != null && uri.path.contains('reset-password')) {
                final token = uri.queryParameters['token'] ??
                    (uri.pathSegments.length > 1 ? uri.pathSegments[1] : null);
                final email = uri.queryParameters['email'];
                return MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(token: token, email: email),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
