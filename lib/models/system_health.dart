class SystemHealth {
  const SystemHealth({
    required this.status,
    required this.models,
    required this.isHealthy,
  });

  final String status;
  final Map<String, dynamic> models;
  final bool isHealthy;

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'unknown';
    return SystemHealth(
      status: status,
      models: (json['models'] as Map<String, dynamic>?) ?? {},
      isHealthy: status.toLowerCase() == 'ok',
    );
  }

  factory SystemHealth.disconnected() {
    return const SystemHealth(
      status: 'offline',
      models: {},
      isHealthy: false,
    );
  }
}
