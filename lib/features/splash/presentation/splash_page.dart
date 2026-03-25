import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sultan/core/constants/api_constants.dart';
import 'package:sultan/core/services/auth_service.dart';
import 'package:sultan/features/configuration/data/configuration_service.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _serverChannel = MethodChannel('com.sultan.android/server');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if the app has been configured
    final configService = ConfigurationService.instance;
    final isConfigured = await configService.isConfigured();
    if (!mounted) return;

    if (!isConfigured) {
      context.go('/configuration');
      return;
    }

    // Apply saved configuration
    final config = await configService.getConfiguration();
    if (!mounted) return;

    if (config != null) {
      ApiConstants.setBaseUrl(config.baseUrl);
      if (config.mode == ServerMode.standalone) {
        await _startServerIfAndroid();
        if (!mounted) return;
      }
    }

    final hasTokens = await AuthService.instance.hasTokens();
    if (!mounted) return;
    if (hasTokens) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  Future<void> _startServerIfAndroid() async {
    try {
      final jwtSecret = await AuthService.instance.getOrCreateJwtSecret();
      final started = await _serverChannel.invokeMethod<bool>('start', {
        'jwtSecret': jwtSecret,
        'port': 8721,
      });
      if (started == true) {
        // Brief wait for the server to be ready to accept connections
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } on MissingPluginException {
      // Not on Android — ignore
    } on PlatformException {
      // Server failed to start — continue anyway, login will fail gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 80, color: colorScheme.onPrimary),
            const SizedBox(height: 16),
            Text(
              'Sultan',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Point of Sale',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
