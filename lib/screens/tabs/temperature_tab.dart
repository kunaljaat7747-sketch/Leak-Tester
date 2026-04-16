// temperature_tab.dart
// ΔPt = (Δt / (273 + t)) × (101.3 + P) × 10³
// All selectors use UnitSelectorCard (SegmentedButton) — zero overflow

import 'dart:math';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/calculations.dart';
import '../../widgets/shared_widgets.dart';

class TemperatureTab extends StatefulWidget {
  const TemperatureTab({super.key});
  @override State<TemperatureTab> createState() => _TemperatureTabState();
}

class _TemperatureTabState extends State<TemperatureTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final _fk    = GlobalKey<FormState>();
  final _tc    = TextEditingController(text: '20');
  final _pc    = TextEditingController(text: '100');
  final _dtc   = TextEditingController(text: '0.01');

  PressureUnit _pressInputUnit = PressureUnit.kpa;
  String _resultUnit = 'pa';  // pa | kpa | bar
  String _scale      = '2';   // 1 | 2 | 5 | 10

  TempDPResult? _result;
  bool _hasError = false; String? _errorMsg; bool _showResult = false;

  @override
  void dispose() { _tc.dispose(); _pc.dispose(); _dtc.dispose(); super.dispose(); }

  String? _req(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v.trim()) == null) return 'Invalid number';
    return null;
  }
  String? _posReq(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.trim()); if (d == null) return 'Invalid'; if (d <= 0) return 'Must be > 0'; return null;
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!_fk.currentState!.validate()) return;
    try {
      final t   = double.parse(_tc.text.trim());
      final raw = double.parse(_pc.text.trim());
      final dt  = double.parse(_dtc.text.trim());
      final kpa = _pressInputUnit.toPascals(raw) / 1000.0;
      final r   = calculateTempDP(tempC: t, pressureKpa: kpa, deltaT: dt);
      setState(() { _result = r; _hasError = false; _errorMsg = null; _showResult = true; });
    } catch (e) {
      setState(() { _result = null; _hasError = true; _errorMsg = e.toString().replaceFirst('Invalid argument(s): ',''); _showResult = true; });
    }
  }

  void _reset() {
    _fk.currentState?.reset();
    _tc.text = '20'; _pc.text = '100'; _dtc.text = '0.01';
    setState(() { _pressInputUnit = PressureUnit.kpa; _resultUnit = 'pa'; _scale = '2';
      _result = null; _hasError = false; _errorMsg = null; _showResult = false; });
  }

  PressureUnit get _ru => PressureUnit.values.firstWhere((u) => u.label.toLowerCase() == _resultUnit);
  double get _resVal  => _result == null ? 0 : _ru.fromPascals(_result!.deltaPt);
  double get _slopeV  => _result == null ? 0 : _ru.fromPascals(_result!.slope);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Form(key: _fk, child: Column(children: [

        // Formula badge
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline, size: 15, color: AppTheme.accentBlue),
              SizedBox(width: 8),
              Text("Formula (Charles's Law)", style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
            ]),
            const SizedBox(height: 6),
            const Text('ΔPt = (Δt / (273 + t)) × (101.3 + P) × 10³',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                    color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...[['t','Avg Air Temperature (°C)'],['P','Test Pressure (kPa)'],
                ['Δt','Temperature Change (°C)'],['ΔPt','Differential Pressure Change (Pa)']
            ].map((r) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                SizedBox(width: 30, child: Text(r[0], style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentBlue))),
                Expanded(child: Text(': ${r[1]}', style: const TextStyle(
                    fontSize: 11, color: AppTheme.primaryBlue))),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 4),

        // Inputs
        SectionCard(title: 'Inputs', icon: Icons.input_rounded, children: [
          NumericField(controller: _tc,  label: 'Avg Air Temperature (t)', unit: '°C',  hint: 'e.g. 20',   validator: _req,    allowNegative: true),
          PressureInputRow(controller: _pc, selectedUnit: _pressInputUnit,
              label: 'Test Pressure (P)',
              onUnitChanged: (u) { if (u != null) setState(() => _pressInputUnit = u); },
              validator: _posReq),
          NumericField(controller: _dtc, label: 'Temperature Change (Δt)', unit: '°C',  hint: 'e.g. 0.01', validator: _req,    allowNegative: true),
        ]),

        // Result unit — SegmentedButton, full width
        UnitSelectorCard(
          icon: Icons.swap_horiz_rounded, label: 'Result unit',
          selected: _resultUnit, onChanged: (v) => setState(() => _resultUnit = v),
          segments: const [
            ButtonSegment(value: 'pa',  label: Text('Pa')),
            ButtonSegment(value: 'kpa', label: Text('kPa')),
            ButtonSegment(value: 'bar', label: Text('bar')),
          ],
        ),

        ActionButtons(onCalculate: _calculate, onReset: _reset),

        // Results
        if (_showResult) ...[
          ResultCard(hasError: _hasError, errorMessage: _errorMsg,
            rows: _hasError ? [] : [
              ResultRow(label: 'ΔPt (Pressure Change)', value: formatValue(_resVal),  unit: _ru.label, isPrimary: true),
              ResultRow(label: 'Slope per 1°C',          value: formatValue(_slopeV), unit: '${_ru.label}/°C'),
              if (_resultUnit != 'pa')
                ResultRow(label: 'ΔPt in Pa (ref)',      value: formatValue(_result!.deltaPt), unit: 'Pa'),
            ]),

          if (!_hasError && _result != null) ...[
            // Scale selector — SegmentedButton, full width
            UnitSelectorCard(
              icon: Icons.zoom_out_map, label: 'Chart x-axis scale',
              selected: _scale, onChanged: (v) => setState(() => _scale = v),
              segments: const [
                ButtonSegment(value: '1',  label: Text('×1')),
                ButtonSegment(value: '2',  label: Text('×2')),
                ButtonSegment(value: '5',  label: Text('×5')),
                ButtonSegment(value: '10', label: Text('×10')),
              ],
            ),

            // Chart
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  const Text('Temperature Change & Differential Pressure',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppTheme.textDark), textAlign: TextAlign.center),
                  Text('y-axis: ${_ru.label}', style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint)),
                  const SizedBox(height: 8),
                  // AspectRatio adapts to ANY screen width
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: CustomPaint(
                      painter: _ChartPainter(
                        slope:         _slopeV,
                        currentDeltaT: double.tryParse(_dtc.text.trim()) ?? 0,
                        currentDP:     _resVal,
                        scale:         int.parse(_scale),
                        yLabel:        _ru.label,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
      ])),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final double slope, currentDeltaT, currentDP;
  final int scale;
  final String yLabel;
  const _ChartPainter({required this.slope, required this.currentDeltaT,
      required this.currentDP, required this.scale, required this.yLabel});

  @override
  void paint(Canvas canvas, Size size) {
    const pL = 58.0, pR = 18.0, pT = 12.0, pB = 44.0;
    final w = size.width - pL - pR;
    final h = size.height - pT - pB;
    final xMax = 0.01 * scale;
    final yR   = _ru(slope.abs() * xMax * 1.25);
    final yMax = yR == 0 ? 1.0 : yR;

    double tx(double v) => pL + ((v + xMax) / (2 * xMax)) * w;
    double ty(double v) => pT + ((yMax - v) / (2 * yMax)) * h;

    canvas.drawRect(Rect.fromLTWH(pL, pT, w, h), Paint()..color = const Color(0xFFE0F7FA));

    final gp = Paint()..color = const Color(0xFF80D8CC).withOpacity(0.5)..strokeWidth = 0.8;
    final steps = List.generate(4, (i) => (i + 1) * xMax / 4);
    final ysteps = List.generate(4, (i) => (i + 1) * yMax / 4);
    for (final v in steps) {
      for (final s in [-1.0, 1.0]) {
        canvas.drawLine(Offset(tx(v * s), pT), Offset(tx(v * s), pT + h), gp);
      }
    }
    for (final v in ysteps) {
      for (final s in [-1.0, 1.0]) {
        canvas.drawLine(Offset(pL, ty(v * s)), Offset(pL + w, ty(v * s)), gp);
      }
    }

    final ap = Paint()..color = const Color(0xFF37474F)..strokeWidth = 1.2;
    canvas.drawLine(Offset(pL, ty(0)), Offset(pL + w, ty(0)), ap);
    canvas.drawLine(Offset(tx(0), pT), Offset(tx(0), pT + h), ap);

    canvas.drawPath(
      Path()..moveTo(tx(-xMax), ty(-xMax * slope))..lineTo(tx(xMax), ty(xMax * slope)),
      Paint()..color = const Color(0xFFE91E8C)..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    if (currentDeltaT.abs() <= xMax) {
      canvas.drawCircle(Offset(tx(currentDeltaT), ty(currentDP)), 6,
          Paint()..color = const Color(0xFFE91E8C));
      canvas.drawCircle(Offset(tx(currentDeltaT), ty(currentDP)), 3,
          Paint()..color = Colors.white);
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    void lbl(String t, double x, double y, TextAlign a) {
      tp.text = TextSpan(text: t, style: const TextStyle(fontSize: 9, color: Color(0xFF37474F)));
      tp.textAlign = a; tp.layout(maxWidth: 100);
      final dx = a == TextAlign.center ? -tp.width / 2 : a == TextAlign.right ? -tp.width - 2 : 2.0;
      tp.paint(canvas, Offset(x + dx, y - tp.height / 2));
    }

    for (final v in steps) {
      for (final s in [-1.0, 1.0]) {
        lbl((v * s).toStringAsFixed(3), tx(v * s), pT + h + 6, TextAlign.center);
      }
    }
    lbl('0', tx(0), pT + h + 6, TextAlign.center);
    for (final v in ysteps) {
      for (final s in [-1.0, 1.0]) {
        lbl(_fy(v * s), pL - 4, ty(v * s), TextAlign.right);
      }
    }
    lbl('0', pL - 4, ty(0), TextAlign.right);
    lbl('Temperature Change Rate  °C', pL + w / 2, pT + h + 28, TextAlign.center);
    canvas.save();
    canvas.translate(10, pT + h / 2);
    canvas.rotate(-pi / 2);
    lbl('ΔP $yLabel', 0, 0, TextAlign.center);
    canvas.restore();
  }

  String _fy(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v.abs() >= 1)   return v.toStringAsFixed(1);
    return v.toStringAsFixed(4);
  }

  double _ru(double v) {
    if (v <= 0) return 1;
    final e = (log(v) / log(10)).floor();
    return ((v / pow(10, e)).ceil() * pow(10, e)).toDouble();
  }

  @override bool shouldRepaint(_ChartPainter o) =>
      o.slope != slope || o.currentDeltaT != currentDeltaT || o.scale != scale || o.yLabel != yLabel;
}
