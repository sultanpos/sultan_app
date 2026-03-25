enum ServerMode { standalone, client }

class AppConfiguration {
  final ServerMode mode;
  final String? host;
  final int? port;

  const AppConfiguration({required this.mode, this.host, this.port});

  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    return AppConfiguration(
      mode: ServerMode.values.byName(json['mode'] as String),
      host: json['host'] as String?,
      port: json['port'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    if (host != null) 'host': host,
    if (port != null) 'port': port,
  };

  String get baseUrl {
    if (mode == ServerMode.standalone) {
      return 'http://localhost:8721';
    }
    return 'http://$host:$port';
  }
}
