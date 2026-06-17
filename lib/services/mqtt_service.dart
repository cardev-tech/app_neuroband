// lib/services/mqtt_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';

enum ConnectionStatus { connecting, live, simulated, error }

class MqttService extends ChangeNotifier {
  // ── MQTT config ────────────────────────────────────────────────
  static const _host = 'iot2.ruwaylabs.lat';
  static const _port = 443;
  static const _wsPath = '/mqtt';
  static const _user = 'esp32user';
  static const _pass = 'ABCabc123';
  static const _topic = 'proyecto/esp32_01/sensores';

  // ── State ──────────────────────────────────────────────────────
  SensorData? _latest;
  ConnectionStatus _status = ConnectionStatus.connecting;
  final List<SensorData> _history = [];

  SensorData? get latest => _latest;
  ConnectionStatus get status => _status;
  List<SensorData> get history => List.unmodifiable(_history);

  // ── Internals ──────────────────────────────────────────────────
  MqttServerClient? _client;
  Timer? _simTimer;
  final _rng = Random();

  // Random walk seeds
  double _rw_tempAmb = 23.5;
  double _rw_hum = 61.0;
  double _rw_tempCorp = 36.7;
  double _rw_luzPct = 57.2;
  double _rw_ax = 0.012, _rw_ay = -0.003, _rw_az = 1.001;
  double _rw_gx = 0.23, _rw_gy = -0.11, _rw_gz = 0.05;

  // ── Public API ─────────────────────────────────────────────────
  Future<void> connect() async {
    _setStatus(ConnectionStatus.connecting);
    try {
      await _connectMqtt();
    } catch (e) {
      debugPrint('MQTT failed: $e — switching to simulation');
      _startSimulation();
    }
  }

  void dispose() {
    _simTimer?.cancel();
    _client?.disconnect();
    super.dispose();
  }

  // ── MQTT logic ─────────────────────────────────────────────────
  Future<void> _connectMqtt() async {
    final clientId = 'neuroband_${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient.withPort(_host, clientId, _port);
    _client!.useWebSocket = true;
    _client!.websocketProtocols = ['mqtt'];
    _client!.secure = true;
    _client!.keepAlivePeriod = 30;
    _client!.connectTimeoutPeriod = 8000;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onBadCertificate = (_) => true;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(_user, _pass)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMsg;

    await _client!.connect();

    if (_client!.connectionStatus!.state != MqttConnectionState.connected) {
      throw Exception(
          'Connection refused: ${_client!.connectionStatus!.returnCode}');
    }

    _client!.subscribe(_topic, MqttQos.atLeastOnce);

    _client!.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> events) {
      for (final event in events) {
        final pubMsg = event.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          pubMsg.payload.message,
        );
        _handlePayload(payload);
      }
    });
  }

  void _onConnected() {
    debugPrint('MQTT connected ✓');
    _setStatus(ConnectionStatus.live);
    _simTimer?.cancel();
  }

  void _onDisconnected() {
    debugPrint('MQTT disconnected — switching to simulation');
    _startSimulation();
  }

  void _handlePayload(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final data = SensorData.fromJson(json);
      _push(data);
      _setStatus(ConnectionStatus.live);
    } catch (e) {
      debugPrint('Parse error: $e');
    }
  }

  // ── Simulation ─────────────────────────────────────────────────
  void _startSimulation() {
    _setStatus(ConnectionStatus.simulated);
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) => _simTick());
    _simTick(); // immediate first value
  }

  double _walk(double v, double step, double lo, double hi) {
    final delta = (_rng.nextDouble() * 2 - 1) * step;
    return (v + delta).clamp(lo, hi);
  }

  void _simTick() {
    _rw_tempAmb  = _walk(_rw_tempAmb,  0.1, 15, 40);
    _rw_hum      = _walk(_rw_hum,      0.3, 20, 95);
    _rw_tempCorp = _walk(_rw_tempCorp, 0.05, 35, 40);
    _rw_luzPct   = _walk(_rw_luzPct,  1.0, 0, 100);
    _rw_ax = _walk(_rw_ax, 0.01, -2, 2);
    _rw_ay = _walk(_rw_ay, 0.01, -2, 2);
    _rw_az = _walk(_rw_az, 0.01, -2, 2);
    _rw_gx = _walk(_rw_gx, 0.05, -5, 5);
    _rw_gy = _walk(_rw_gy, 0.05, -5, 5);
    _rw_gz = _walk(_rw_gz, 0.05, -5, 5);

    final data = SensorData(
      timestamp: DateTime.now(),
      tempAmbiente: _rw_tempAmb,
      humedad: _rw_hum,
      tempCorporal: _rw_tempCorp,
      ldrRaw: (_rng.nextDouble() * 4095).toInt(),
      luzPct: _rw_luzPct,
      rojoRaw: 80000 + _rng.nextInt(20000),
      irRaw:   85000 + _rng.nextInt(20000),
      ax: _rw_ax, ay: _rw_ay, az: _rw_az,
      gx: _rw_gx, gy: _rw_gy, gz: _rw_gz,
    );
    _push(data);
  }

  // ── Helpers ────────────────────────────────────────────────────
  void _push(SensorData d) {
    _latest = d;
    _history.add(d);
    if (_history.length > 60) _history.removeAt(0);
    notifyListeners();
  }

  void _setStatus(ConnectionStatus s) {
    _status = s;
    notifyListeners();
  }
}
