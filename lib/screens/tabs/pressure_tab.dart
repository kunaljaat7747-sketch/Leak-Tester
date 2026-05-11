// pressure_tab.dart
// ΔP = (Q × Patm × T) / (Ve × 60)
// UnitSelectorCard uses SegmentedButton — ZERO overflow possible

import 'package:flutter/material.dart';
import '../../services/calculations.dart';
import '../../widgets/shared_widgets.dart';

class PressureDropTab extends StatefulWidget {
  const PressureDropTab({super.key});
  @override State<PressureDropTab> createState() => _PressureDropTabState();
}

class _PressureDropTabState extends State<PressureDropTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final _fk = GlobalKey<FormState>();
  final _qc = TextEditingController();
  final _vc = TextEditingController();
  final _tc = TextEditingController();

  // SegmentedButton uses String keys — no enum comparison issue
  String _resultUnit = 'pa';

  double? _resultPa;
  bool _hasError = false; String? _errorMsg; bool _showResult = false;

  @override
  void dispose() { _qc.dispose(); _vc.dispose(); _tc.dispose(); super.dispose(); }

  String? _v(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.trim());
    if (d == null) return 'Invalid'; if (d <= 0) return 'Must be > 0'; return null;
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!_fk.currentState!.validate()) return;
    try {
      final r = calculatePressureDrop(
        leakRateMlMin: double.parse(_qc.text.trim()),
        volumeMl:      double.parse(_vc.text.trim()),
        timeSec:       double.parse(_tc.text.trim()),
      );
      setState(() { _resultPa = r.pressureDropPa; _hasError = false; _errorMsg = null; _showResult = true; });
    } catch (e) {
      setState(() { _resultPa = null; _hasError = true; _errorMsg = e.toString().replaceFirst('Invalid argument(s): ',''); _showResult = true; });
    }
  }

  void _reset() {
    _fk.currentState?.reset();
    _qc.clear(); _vc.clear(); _tc.clear();
    setState(() { _resultUnit = 'pa'; _resultPa = null; _hasError = false; _errorMsg = null; _showResult = false; });
  }

  PressureUnit get _unit => PressureUnit.values.firstWhere((u) => u.label.toLowerCase() == _resultUnit);

  List<ResultRow> get _rows {
    if (_resultPa == null) return [];
    final disp = _unit.fromPascals(_resultPa!);
    return [
      ResultRow(label: 'Pressure Drop (ΔP)', value: formatValue(disp), unit: _unit.label, isPrimary: true),
      if (_resultUnit != 'pa')
        ResultRow(label: 'Reference', value: formatValue(_resultPa!), unit: 'Pa'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(
        child: Form(
          key: _fk,
          child: Column(children: [
            const InfoBadge(text: 'ΔP = (Q × Patm × T) / (Ve × 60)'),
            const SizedBox(height: 4),
            SectionCard(title: 'Inputs', icon: Icons.input_rounded, children: [
              NumericField(controller: _qc, label: 'Leak Rate (Q)', unit: 'mL/min', hint: 'e.g. 0.5', validator: _v),
              NumericField(controller: _vc, label: 'Volume (Ve)',   unit: 'mL',     hint: 'e.g. 500', validator: _v),
              NumericField(controller: _tc, label: 'Test Time (T)', unit: 'sec',    hint: 'e.g. 60',  validator: _v),
            ]),

            // ── SegmentedButton fills full width — impossible to overflow ──
            UnitSelectorCard(
              icon:     Icons.swap_horiz_rounded,
              label:    'Result unit',
              selected: _resultUnit,
              onChanged: (v) => setState(() => _resultUnit = v),
              segments: const [
                ButtonSegment(value: 'pa',  label: Text('Pa')),
                ButtonSegment(value: 'kpa', label: Text('kPa')),
                ButtonSegment(value: 'bar', label: Text('bar')),
              ],
            ),

            ActionButtons(onCalculate: _calculate, onReset: _reset),
            if (_showResult) ResultCard(hasError: _hasError, errorMessage: _errorMsg, rows: _rows),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
