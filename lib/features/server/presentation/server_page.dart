import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class ServerPage extends ConsumerStatefulWidget {
  const ServerPage({super.key});

  @override
  ConsumerState<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  static const _channel = MethodChannel('com.lekapin.sultan/server');
  bool _running = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final running = await _channel.invokeMethod<bool>('isRunning') ?? false;
      setState(() => _running = running);
    } on MissingPluginException {
      // Not on Android
    }
  }

  Future<void> _startServer() async {
    setState(() => _loading = true);
    try {
      final jwtSecret = await AuthService.instance.getOrCreateJwtSecret();
      final started =
          await _channel.invokeMethod<bool>('start', {
            'jwtSecret': jwtSecret,
            'port': 8721,
          }) ??
          false;
      setState(() => _running = started);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start: ${e.message}')),
        );
      }
    } on MissingPluginException {
      // Not on Android
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _stopServer() async {
    setState(() => _loading = true);
    try {
      await _channel.invokeMethod('stop');
      setState(() => _running = false);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to stop: ${e.message}')));
      }
    } on MissingPluginException {
      // Not on Android
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sultan Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _running ? Icons.cloud_done : Icons.cloud_off,
              size: 80,
              color: _running ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _running ? 'Server Running' : 'Server Stopped',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_running)
              Text(
                'http://localhost:8721',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: FilledButton.icon(
                onPressed: _loading
                    ? null
                    : (_running ? _stopServer : _startServer),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_running ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _loading
                      ? 'Please wait...'
                      : (_running ? 'Stop Server' : 'Start Server'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(indent: 48, endIndent: 48),
            const SizedBox(height: 16),
            Text(
              'Manage',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/categories'),
            ),
          ],
        ),
      ),
    );
  }
}
