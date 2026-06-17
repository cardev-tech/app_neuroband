// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../services/auth_service.dart';
import '../services/mqtt_service.dart';
import '../widgets/sensor_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthService>();
    final mqtt   = context.watch<MqttService>();
    final data   = mqtt.latest;
    final status = mqtt.status;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(context, auth, status),
      body: data == null
          ? _buildLoading(status)
          : _buildGrid(context, data),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────
  AppBar _buildAppBar(
      BuildContext context, AuthService auth, ConnectionStatus status) {
    final (label, color, icon) = switch (status) {
      ConnectionStatus.live       => ('EN VIVO', Colors.green, Icons.wifi),
      ConnectionStatus.simulated  => ('SIMULADO', Colors.orange, Icons.wifi_off),
      ConnectionStatus.connecting => ('CONECTANDO', Colors.blue, Icons.sync),
      ConnectionStatus.error      => ('ERROR', Colors.red, Icons.error),
    };

    return AppBar(
      backgroundColor: const Color(0xFF1A1D2E),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.monitor_heart_outlined, size: 22),
          const SizedBox(width: 8),
          Text('NeuroBand',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 18)),
        ],
      ),
      actions: [
        // Connection badge
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        // User avatar + logout
        PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.deepPurple.shade300,
            child: Text(
              auth.session!.username[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
          onSelected: (v) {
            if (v == 'logout') context.read<AuthService>().logout();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.session!.username,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(auth.session!.role,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 16),
                  SizedBox(width: 8),
                  Text('Cerrar sesión'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Loading state ────────────────────────────────────────────
  Widget _buildLoading(ConnectionStatus status) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            status == ConnectionStatus.connecting
                ? 'Conectando al broker MQTT…'
                : 'Esperando datos del sensor…',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Card grid ────────────────────────────────────────────────
  Widget _buildGrid(BuildContext context, SensorData d) {
    final cards = _buildCards(d);
    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // Timestamp banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Última lectura: ${_fmt(d.timestamp)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Grid
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => cards[i],
                childCount: cards.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card definitions ─────────────────────────────────────────
  List<Widget> _buildCards(SensorData d) {
    return [
      // DHT22 — Ambiente
      buildCard(
        title: 'DHT22 · Ambiente',
        icon: Icons.thermostat_outlined,
        color: Colors.orange,
        rows: [
          ('Temperatura', '${d.tempAmbiente.toStringAsFixed(1)} °C',
              Colors.orange),
          ('Humedad', '${d.humedad.toStringAsFixed(1)} %',
              Colors.blueAccent),
        ],
      ),

      // MAX30205 — Temperatura corporal
      buildCard(
        title: 'MAX30205 · Corporal',
        icon: Icons.favorite_outline,
        color: Colors.red,
        rows: [
          ('Temperatura', '${d.tempCorporal.toStringAsFixed(2)} °C',
              _tempColor(d.tempCorporal)),
        ],
      ),

      // LDR — Luminosidad
      buildCard(
        title: 'LDR · Luminosidad',
        icon: Icons.light_mode_outlined,
        color: Colors.amber,
        rows: [
          ('Luz %', '${d.luzPct.toStringAsFixed(1)} %', Colors.amber.shade700),
          ('Raw', '${d.ldrRaw}', Colors.grey),
        ],
      ),

      // MAX30102 — Pulso/SpO2 raw
      buildCard(
        title: 'MAX30102 · Pulso & SpO₂',
        icon: Icons.monitor_heart_outlined,
        color: Colors.pink,
        rows: [
          ('IR Raw',   '${d.irRaw}',   Colors.deepPurple),
          ('Rojo Raw', '${d.rojoRaw}', Colors.redAccent),
        ],
      ),

      // MPU6050 — Acelerómetro
      buildCard(
        title: 'MPU6050 · Acelerómetro',
        icon: Icons.speed_outlined,
        color: Colors.teal,
        rows: [
          ('X', d.ax.toStringAsFixed(3), Colors.teal),
          ('Y', d.ay.toStringAsFixed(3), Colors.teal.shade700),
          ('Z', d.az.toStringAsFixed(3), Colors.teal.shade900),
        ],
      ),

      // MPU6050 — Giroscopio
      buildCard(
        title: 'MPU6050 · Giroscopio',
        icon: Icons.rotate_right_outlined,
        color: Colors.indigo,
        rows: [
          ('X', d.gx.toStringAsFixed(3), Colors.indigo),
          ('Y', d.gy.toStringAsFixed(3), Colors.indigo.shade700),
          ('Z', d.gz.toStringAsFixed(3), Colors.indigo.shade900),
        ],
      ),
    ];
  }

  Color _tempColor(double t) {
    if (t < 36.0) return Colors.blue;
    if (t > 37.5) return Colors.red;
    return Colors.green;
  }

  String _fmt(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
