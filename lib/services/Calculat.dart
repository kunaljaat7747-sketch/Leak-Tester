// ============================================================
// services/calculations.dart
// All engineering formulas for Cosmo Calculator
// ============================================================

// ── Constants ────────────────────────────────────────────────
/// Standard atmospheric pressure in Pascals
const double kPatm = 101300.0; // 1.013 × 10^5 Pa

/// Reference temperature in Kelvin (20°C)
const double kTref = 293.15;

// ── Pressure Unit Enum ───────────────────────────────────────
enum PressureUnit { pa, kpa, bar }

extension PressureUnitExtension on PressureUnit {
  String get label {
    switch (this) {
      case PressureUnit.pa:  return 'Pa';
      case PressureUnit.kpa: return 'kPa';
      case PressureUnit.bar: return 'bar';
    }
  }

  String get description {
    switch (this) {
      case PressureUnit.pa:  return 'Pascal';
      case PressureUnit.kpa: return 'Kilopascal';
      case PressureUnit.bar: return 'Bar';
    }
  }

  /// Convert a value FROM this unit TO Pascals
  double toPascals(double value) {
    switch (this) {
      case PressureUnit.pa:  return value;
      case PressureUnit.kpa: return value * 1000.0;
      case PressureUnit.bar: return value * 100000.0;
    }
  }

  /// Convert a value FROM Pascals TO this unit
  double fromPascals(double valuePa) {
    switch (this) {
      case PressureUnit.pa:  return valuePa;
      case PressureUnit.kpa: return valuePa / 1000.0;
      case PressureUnit.bar: return valuePa / 100000.0;
    }
  }
}

// ── Temperature helpers ──────────────────────────────────────
double celsiusToKelvin(double celsius) => celsius + 273.15;

/// Returns unchanged Q if temperature is null (no correction applied).
double applyTemperatureCorrection(double q, double? temperatureCelsius) {
  if (temperatureCelsius == null) return q;
  final double tActual = celsiusToKelvin(temperatureCelsius);
  return q * (kTref / tActual);
}

// ============================================================
// FORMULA 1 — Leak Rate
// Q = (Ve × ΔP × 60) / (Patm × T)
// ============================================================
class LeakRateResult {
  final double rawLeakRate;
  final double correctedLeakRate;
  final double? temperatureK;
  final bool tempCorrectionApplied;
  const LeakRateResult({
    required this.rawLeakRate,
    required this.correctedLeakRate,
    this.temperatureK,
    required this.tempCorrectionApplied,
  });
}

LeakRateResult calculateLeakRate({
  required double volumeMl,
  required double pressureDropPa,
  required double timeSec,
  double? temperatureC,
}) {
  if (timeSec == 0) throw ArgumentError('Time must not be zero.');
  final double q = (volumeMl * pressureDropPa * 60.0) / (kPatm * timeSec);
  final double qCorrected = applyTemperatureCorrection(q, temperatureC);
  return LeakRateResult(
    rawLeakRate: q,
    correctedLeakRate: qCorrected,
    temperatureK: temperatureC != null ? celsiusToKelvin(temperatureC) : null,
    tempCorrectionApplied: temperatureC != null,
  );
}

// ============================================================
// FORMULA 2 — Volume
// Ve = (Q × Patm × T) / (ΔP × 60)
// ============================================================
class VolumeResult {
  final double volumeMl;
  final double correctedVolumeMl;
  final bool tempCorrectionApplied;
  const VolumeResult({
    required this.volumeMl,
    required this.correctedVolumeMl,
    required this.tempCorrectionApplied,
  });
}

VolumeResult calculateVolume({
  required double leakRateMlMin,
  required double pressureDropPa,
  required double timeSec,
  double? temperatureC,
}) {
  if (pressureDropPa == 0) throw ArgumentError('Pressure drop must not be zero.');
  final double v = (leakRateMlMin * kPatm * timeSec) / (pressureDropPa * 60.0);
  double vCorrected = v;
  if (temperatureC != null) {
    final double tActual = celsiusToKelvin(temperatureC);
    vCorrected = v * (kTref / tActual);
  }
  return VolumeResult(
    volumeMl: v,
    correctedVolumeMl: vCorrected,
    tempCorrectionApplied: temperatureC != null,
  );
}

// ============================================================
// FORMULA 3 — Pressure Drop
// ΔP = (Q × Patm × T) / (Ve × 60)   → result in Pa, caller converts
// ============================================================
class PressureDropResult {
  final double pressureDropPa;
  final double correctedPressureDropPa;
  final bool tempCorrectionApplied;
  const PressureDropResult({
    required this.pressureDropPa,
    required this.correctedPressureDropPa,
    required this.tempCorrectionApplied,
  });
}

PressureDropResult calculatePressureDrop({
  required double leakRateMlMin,
  required double volumeMl,
  required double timeSec,
  double? temperatureC,
}) {
  if (volumeMl == 0) throw ArgumentError('Volume must not be zero.');
  final double dp = (leakRateMlMin * kPatm * timeSec) / (volumeMl * 60.0);
  double dpCorrected = dp;
  if (temperatureC != null) {
    final double tActual = celsiusToKelvin(temperatureC);
    dpCorrected = dp * (kTref / tActual);
  }
  return PressureDropResult(
    pressureDropPa: dp,
    correctedPressureDropPa: dpCorrected,
    tempCorrectionApplied: temperatureC != null,
  );
}

// ============================================================
// FORMULA 4 — Time
// T = (Ve × ΔP × 60) / (Patm × Q)
// ============================================================
class TimeResult {
  final double timeSec;
  final double correctedTimeSec;
  final bool tempCorrectionApplied;
  const TimeResult({
    required this.timeSec,
    required this.correctedTimeSec,
    required this.tempCorrectionApplied,
  });
}

TimeResult calculateTime({
  required double volumeMl,
  required double pressureDropPa,
  required double leakRateMlMin,
  double? temperatureC,
}) {
  if (leakRateMlMin == 0) throw ArgumentError('Leak rate must not be zero.');
  final double t = (volumeMl * pressureDropPa * 60.0) / (kPatm * leakRateMlMin);
  double tCorrected = t;
  if (temperatureC != null) {
    final double tActual = celsiusToKelvin(temperatureC);
    tCorrected = t * (kTref / tActual);
  }
  return TimeResult(
    timeSec: t,
    correctedTimeSec: tCorrected,
    tempCorrectionApplied: temperatureC != null,
  );
}

// ── Formatting utils ─────────────────────────────────────────
String formatValue(double value, {int decimals = 6}) {
  if (value.abs() >= 1000 || (value.abs() < 0.001 && value != 0)) {
    return value.toStringAsExponential(decimals);
  }
  return value.toStringAsFixed(decimals);
}

double? tryParseDouble(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}
