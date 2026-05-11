import 'package:flutter/material.dart';
import '../../services/calculations.dart';
import '../../widgets/shared_widgets.dart';

class TimeTab extends StatefulWidget {
  const TimeTab({super.key});
  @override State<TimeTab> createState() => _S();
}
class _S extends State<TimeTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _fk = GlobalKey<FormState>();
  final _vc = TextEditingController();
  final _pc = TextEditingController();
  final _qc = TextEditingController();
  PressureUnit _pu = PressureUnit.pa;
  double? _res; bool _err = false; String? _em; bool _show = false;
  @override void dispose() { _vc.dispose(); _pc.dispose(); _qc.dispose(); super.dispose(); }
  String? _v(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.trim()); if (d == null) return 'Invalid'; if (d <= 0) return 'Must be > 0'; return null;
  }
  void _calc() {
    FocusScope.of(context).unfocus();
    if (!_fk.currentState!.validate()) return;
    try {
      final r = calculateTime(volumeMl: double.parse(_vc.text.trim()),
          pressureDropPa: _pu.toPascals(double.parse(_pc.text.trim())),
          leakRateMlMin: double.parse(_qc.text.trim()));
      setState(() { _res = r.timeSec; _err = false; _em = null; _show = true; });
    } catch (e) { setState(() { _res = null; _err = true; _em = e.toString().replaceFirst('Invalid argument(s): ',''); _show = true; }); }
  }
  void _reset() { _fk.currentState?.reset(); _vc.clear(); _pc.clear(); _qc.clear();
    setState(() { _pu = PressureUnit.pa; _res = null; _err = false; _em = null; _show = false; }); }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(
        child: Form(
          key: _fk,
          child: Column(children: [
            const InfoBadge(text: 'T = (Ve × ΔP × 60) / (Patm × Q)'),
            const SizedBox(height: 4),
            SectionCard(title: 'Inputs', icon: Icons.input_rounded, children: [
              NumericField(controller: _vc, label: 'Volume (Ve)', unit: 'mL', hint: 'e.g. 500', validator: _v),
              PressureInputRow(controller: _pc, selectedUnit: _pu, onUnitChanged: (u) { if (u != null) setState(() => _pu = u); }, validator: _v),
              NumericField(controller: _qc, label: 'Leak Rate (Q)', unit: 'mL/min', hint: 'e.g. 0.5', validator: _v),
            ]),
            ActionButtons(onCalculate: _calc, onReset: _reset),
            if (_show) ResultCard(
              hasError: _err,
              errorMessage: _em,
              rows: _err ? [] : [
                ResultRow(label: 'Test Time (T)', value: _res!.toStringAsFixed(4), unit: 'sec', isPrimary: true),
                ResultRow(label: 'In Minutes', value: (_res! / 60).toStringAsFixed(4), unit: 'min'),
              ],
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
