// ============================================================
// services/calculations.dart — All engineering formulas
// ============================================================

// ── Constants ────────────────────────────────────────────────
const double kPatm = 101300.0; // 1.013 × 10^5 Pa

// ── Pressure Unit ────────────────────────────────────────────
enum PressureUnit { pa, kpa, bar }

extension PressureUnitExtension on PressureUnit {
  String get label {
    switch (this) { case PressureUnit.pa: return 'Pa'; case PressureUnit.kpa: return 'kPa'; case PressureUnit.bar: return 'bar'; }
  }
  double toPascals(double v) {
    switch (this) { case PressureUnit.pa: return v; case PressureUnit.kpa: return v * 1000.0; case PressureUnit.bar: return v * 100000.0; }
  }
  double fromPascals(double v) {
    switch (this) { case PressureUnit.pa: return v; case PressureUnit.kpa: return v / 1000.0; case PressureUnit.bar: return v / 100000.0; }
  }
}

// ── FORMULA 1: Leak Rate ─────────────────────────────────────
// Q = (Ve × ΔP × 60) / (Patm × T)
class LeakRateResult {
  final double leakRate;
  const LeakRateResult({required this.leakRate});
}
LeakRateResult calculateLeakRate({required double volumeMl, required double pressureDropPa, required double timeSec}) {
  if (timeSec == 0) throw ArgumentError('Time must not be zero.');
  return LeakRateResult(leakRate: (volumeMl * pressureDropPa * 60.0) / (kPatm * timeSec));
}

// ── FORMULA 2: Volume ─────────────────────────────────────────
// Ve = (Q × Patm × T) / (ΔP × 60)
class VolumeResult {
  final double volumeMl;
  const VolumeResult({required this.volumeMl});
}
VolumeResult calculateVolume({required double leakRateMlMin, required double pressureDropPa, required double timeSec}) {
  if (pressureDropPa == 0) throw ArgumentError('Pressure drop must not be zero.');
  return VolumeResult(volumeMl: (leakRateMlMin * kPatm * timeSec) / (pressureDropPa * 60.0));
}

// ── FORMULA 3: Pressure Drop ──────────────────────────────────
// ΔP = (Q × Patm × T) / (Ve × 60)
class PressureDropResult {
  final double pressureDropPa;
  const PressureDropResult({required this.pressureDropPa});
}
PressureDropResult calculatePressureDrop({required double leakRateMlMin, required double volumeMl, required double timeSec}) {
  if (volumeMl == 0) throw ArgumentError('Volume must not be zero.');
  return PressureDropResult(pressureDropPa: (leakRateMlMin * kPatm * timeSec) / (volumeMl * 60.0));
}

// ── FORMULA 4: Time ───────────────────────────────────────────
// T = (Ve × ΔP × 60) / (Patm × Q)
class TimeResult {
  final double timeSec;
  const TimeResult({required this.timeSec});
}
TimeResult calculateTime({required double volumeMl, required double pressureDropPa, required double leakRateMlMin}) {
  if (leakRateMlMin == 0) throw ArgumentError('Leak rate must not be zero.');
  return TimeResult(timeSec: (volumeMl * pressureDropPa * 60.0) / (kPatm * leakRateMlMin));
}

// ── FORMULA 5: Temperature Change → Differential Pressure ────
// ΔPt = (Δt / (273 + t)) × (101.3 + P) × 10³
// t  = Average Air Temperature (°C)
// P  = Test Pressure (kPa)
// Δt = Temperature Change (°C)
// ΔPt = Differential Pressure Change (Pa)
class TempDPResult {
  final double deltaPt; // Pa
  final double slope;   // Pa per °C — for chart
  const TempDPResult({required this.deltaPt, required this.slope});
}
TempDPResult calculateTempDP({required double tempC, required double pressureKpa, required double deltaT}) {
  final double denom = 273.0 + tempC;
  if (denom == 0) throw ArgumentError('Temperature results in invalid denominator.');
  final double slope = (101.3 + pressureKpa) * 1000.0 / denom;
  return TempDPResult(deltaPt: slope * deltaT, slope: slope);
}

// ── FORMULA 6: Leak Master ΔP ─────────────────────────────────
// ΔP = (Q × 1.013×10⁵ / Ve) × (T / 60)
double calculateLeakMasterDP({required double leakRateMlMin, required double volumeMl, required double timeSec}) {
  if (volumeMl == 0) throw ArgumentError('Volume must not be zero.');
  return (leakRateMlMin * 101300.0 / volumeMl) * (timeSec / 60.0);
}

// ── Leak Master Data Table ────────────────────────────────────
// null = not available / out of range for that type
const List<String> kLeakMasterTypes = ['J1-1','J1-2','J1-5','J1-10','J1-20','J1-50','J1-100','J1-200'];
const List<int> kLeakMasterPressures = [10,20,30,40,50,60,70,80,90,100,150,200,250,300,350,400,450,500,550,600];

const Map<int, List<double?>> kLeakMasterTable = {
  10:  [0.08, 0.17, 0.42, 0.79,  1.64,   4.61,   11.00,  22.70],
  20:  [0.16, 0.35, 0.84, 1.59,  3.29,   9.23,   22.00,  45.50],
  30:  [0.24, 0.55, 1.29, 2.49,  5.20,  14.35,   32.70,  66.80],
  40:  [0.33, 0.76, 1.75, 3.40,  7.11,  19.47,   43.50,  88.00],
  50:  [0.42, 0.97, 2.21, 4.31,  9.03,  24.60,   54.30, 108.20],
  60:  [0.52, 1.20, 2.77, 5.36, 11.36,  29.90,   64.90, 128.40],
  70:  [0.63, 1.44, 3.33, 6.42, 13.69,  35.20,   75.50, 147.50],
  80:  [0.73, 1.67, 3.90, 7.48, 16.03,  40.60,   85.90, 166.60],
  90:  [0.84, 1.91, 4.46, 8.54, 18.36,  45.90,   96.40, 185.10],
  100: [0.95, 2.15, 5.03, 9.60, 20.70,  51.20,  106.90, 203.70],
  150: [1.59, 3.80, 8.59,15.65, 34.70,  78.30,  157.90,  null],
  200: [2.23, 5.46,12.16,21.70, 48.70, 105.30,  208.90,  null],
  250: [3.12, 7.83,16.72,28.40, 65.30, 131.40,    null,  null],
  300: [4.02,10.20,21.20,35.20, 81.90, 157.50,    null,  null],
  350: [4.92,12.57,25.80,41.90, 98.40,   null,    null,  null],
  400: [5.82,14.95,30.40,48.60,115.00,   null,    null,  null],
  450: [6.91,18.13,35.70,56.00,133.70,   null,    null,  null],
  500: [8.01,21.30,41.00,63.40,152.40,   null,    null,  null],
  550: [9.10,24.50,46.30,70.80,171.10,   null,    null,  null],
  600:[10.20,27.70,51.60,78.20,189.90,   null,    null,  null],
};

// ── Utilities ─────────────────────────────────────────────────
String formatValue(double value, {int decimals = 4}) {
  if (value.abs() >= 10000 || (value.abs() < 0.001 && value != 0)) {
    return value.toStringAsExponential(3);
  }
  return value.toStringAsFixed(decimals);
}

double? tryParseDouble(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  return double.tryParse(t);
}
