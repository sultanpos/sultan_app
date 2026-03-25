import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sultan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ServerPage(),
    );
  }
}

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  static const _channel = MethodChannel('com.sultan.android/server');
  bool _running = false;
  bool _loading = false;

  Future<void> _checkStatus() async {
    final running = await _channel.invokeMethod<bool>('isRunning') ?? false;
    setState(() => _running = running);
  }

  Future<void> _startServer() async {
    setState(() => _loading = true);
    try {
      final started =
          await _channel.invokeMethod<bool>('start', {
            'jwtSecret': 'sultan-secret-key',
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
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sultan Server'),
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
          ],
        ),
      ),
    );
  }
}
