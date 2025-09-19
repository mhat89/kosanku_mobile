import 'package:flutter/material.dart';
import 'views/shell/app_shell.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/otp_screen.dart';
import 'views/auth/forgot_email_screen.dart';
import 'views/auth/reset_password_screen.dart';
import 'views/auth/change_password_screen.dart';
import 'views/profile/profile_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    '/app': (_) => const AppShell(),
    '/login': (_) => const LoginScreen(),
    '/register': (_) => const RegisterScreen(),
    '/otp': (_) => const OtpScreen(),
    '/forgot': (_) => const ForgotEmailScreen(),
    '/reset': (_) => const ResetPasswordScreen(),
    '/change-password': (_) => const ChangePasswordScreen(),
    '/profile': (_) => const ProfileScreen(),
  };
}
