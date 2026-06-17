// lib/widgets/sensor_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_CardRow> rows;

  const SensorCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Values
            ...rows.map((r) => _buildRow(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_CardRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(r.label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(r.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: r.accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }
}

class _CardRow {
  final String label;
  final String value;
  final Color accent;
  const _CardRow(this.label, this.value, {this.accent = Colors.black87});
}

// Factory helper so callers don't need to import _CardRow
SensorCard buildCard({
  required String title,
  required IconData icon,
  required Color color,
  required List<(String label, String value, Color accent)> rows,
}) {
  return SensorCard(
    title: title,
    icon: icon,
    color: color,
    rows: rows
        .map((r) => _CardRow(r.$1, r.$2, accent: r.$3))
        .toList(),
  );
}
