// lib/models/sensor_data.dart

class SensorData {
  final DateTime timestamp;

  // DHT22
  final double tempAmbiente;
  final double humedad;

  // MAX30205
  final double tempCorporal;

  // LDR
  final int ldrRaw;
  final double luzPct;

  // MAX30102
  final int rojoRaw;
  final int irRaw;

  // MPU6050
  final double ax, ay, az;
  final double gx, gy, gz;

  SensorData({
    required this.timestamp,
    required this.tempAmbiente,
    required this.humedad,
    required this.tempCorporal,
    required this.ldrRaw,
    required this.luzPct,
    required this.rojoRaw,
    required this.irRaw,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as int) * 1000,
      ),
      tempAmbiente: (json['dht22']['temp_ambiente_C'] as num).toDouble(),
      humedad: (json['dht22']['humedad_pct'] as num).toDouble(),
      tempCorporal: (json['max30205']['temp_corporal_C'] as num).toDouble(),
      ldrRaw: (json['ldr']['raw'] as num).toInt(),
      luzPct: (json['ldr']['luz_pct'] as num).toDouble(),
      rojoRaw: (json['max30102']['rojo_raw'] as num).toInt(),
      irRaw: (json['max30102']['ir_raw'] as num).toInt(),
      ax: (json['mpu6050']['ax'] as num).toDouble(),
      ay: (json['mpu6050']['ay'] as num).toDouble(),
      az: (json['mpu6050']['az'] as num).toDouble(),
      gx: (json['mpu6050']['gx'] as num).toDouble(),
      gy: (json['mpu6050']['gy'] as num).toDouble(),
      gz: (json['mpu6050']['gz'] as num).toDouble(),
    );
  }
}
