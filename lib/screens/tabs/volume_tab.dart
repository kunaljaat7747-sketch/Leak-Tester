import 'package:flutter/material.dart';
import '../../services/calculations.dart';
import '../../widgets/shared_widgets.dart';

class VolumeTab extends StatefulWidget {
  const VolumeTab({super.key});
  @override State<VolumeTab> createState() => _S();
}
class _S extends State<VolumeTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _fk = GlobalKey<FormState>();
  final _qc = TextEditingController();
  final _pc = TextEditingController();
  final _tc = TextEditingController();
  PressureUnit _pu = PressureUnit.pa;
  double? _res; bool _err = false; String? _em; bool _show = false;
  @override void dispose() { _qc.dispose(); _pc.dispose(); _tc.dispose(); super.dispose(); }
  String? _v(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.trim()); if (d == null) return 'Invalid'; if (d <= 0) return 'Must be > 0'; return null;
  }
  void _calc() {
    FocusScope.of(context).unfocus();
    if (!_fk.currentState!.validate()) return;
    try {
      final r = calculateVolume(leakRateMlMin: double.parse(_qc.text.trim()),
          pressureDropPa: _pu.toPascals(double.parse(_pc.text.trim())),
          timeSec: double.parse(_tc.text.trim()));
      setState(() { _res = r.volumeMl; _err = false; _em = null; _show = true; });
    } catch (e) { setState(() { _res = null; _err = true; _em = e.toString().replaceFirst('Invalid argument(s): ',''); _show = true; }); }
  }
  void _reset() { _fk.currentState?.reset(); _qc.clear(); _pc.clear(); _tc.clear();
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
            const InfoBadge(text: 'Ve = (Q × Patm × T) / (ΔP × 60)'),
            const SizedBox(height: 4),
            SectionCard(title: 'Inputs', icon: Icons.input_rounded, children: [
              NumericField(controller: _qc, label: 'Leak Rate (Q)', unit: 'mL/min', hint: 'e.g. 0.5', validator: _v),
              PressureInputRow(controller: _pc, selectedUnit: _pu, onUnitChanged: (u) { if (u != null) setState(() => _pu = u); }, validator: _v),
              NumericField(controller: _tc, label: 'Test Time (T)', unit: 'sec', hint: 'e.g. 60', validator: _v),
            ]),
            ActionButtons(onCalculate: _calc, onReset: _reset),
            if (_show) ResultCard(
              hasError: _err,
              errorMessage: _em,
              rows: _err ? [] : [ResultRow(label: 'Volume (Ve)', value: formatValue(_res!), unit: 'mL', isPrimary: true)],
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
