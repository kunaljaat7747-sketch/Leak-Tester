// leak_master_tab.dart
// All overflows fixed:
//  • ΔP result unit → UnitSelectorCard (SegmentedButton, full width)
//  • Legend rows → Wrap (reflows on any screen)
//  • Data table → LayoutBuilder centred + horizontal scroll

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/calculations.dart';
import '../../widgets/shared_widgets.dart';

class LeakMasterTab extends StatefulWidget {
  const LeakMasterTab({super.key});
  @override State<LeakMasterTab> createState() => _LeakMasterTabState();
}

class _LeakMasterTabState extends State<LeakMasterTab>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final _fk   = GlobalKey<FormState>();
  final _vc   = TextEditingController(text: '500');
  final _tc   = TextEditingController(text: '2');
  final _pc   = TextEditingController(text: '50');

  PressureUnit _pressInputUnit = PressureUnit.kpa;
  String _resultUnit = 'pa'; // pa | kpa | bar
  int? _highlightKpa;
  List<_LMResult>? _results;
  bool _hasError = false; String? _errorMsg;

  @override
  void dispose() { _vc.dispose(); _tc.dispose(); _pc.dispose(); super.dispose(); }

  String? _pos(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.trim()); if (d == null) return 'Invalid'; if (d <= 0) return 'Must be > 0'; return null;
  }

  PressureUnit get _ru => PressureUnit.values.firstWhere((u) => u.label.toLowerCase() == _resultUnit);

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!_fk.currentState!.validate()) return;
    try {
      final ve  = double.parse(_vc.text.trim());
      final t   = double.parse(_tc.text.trim());
      final kpa = _pressInputUnit.toPascals(double.parse(_pc.text.trim())) / 1000.0;
      final nearest = kLeakMasterPressures.reduce(
          (a, b) => (a - kpa).abs() < (b - kpa).abs() ? a : b);
      final row = kLeakMasterTable[nearest]!;
      final results = List.generate(kLeakMasterTypes.length, (i) {
        final q = row[i];
        return q == null
            ? _LMResult(type: kLeakMasterTypes[i], leakRate: null, deltaP: null)
            : _LMResult(type: kLeakMasterTypes[i], leakRate: q,
                deltaP: calculateLeakMasterDP(leakRateMlMin: q, volumeMl: ve, timeSec: t));
      });
      setState(() { _results = results; _highlightKpa = nearest; _hasError = false; _errorMsg = null; });
    } catch (e) {
      setState(() { _results = null; _highlightKpa = null; _hasError = true;
        _errorMsg = e.toString().replaceFirst('Invalid argument(s): ',''); });
    }
  }

  void _reset() {
    _fk.currentState?.reset();
    _vc.text = '500'; _tc.text = '2'; _pc.text = '50';
    setState(() { _pressInputUnit = PressureUnit.kpa; _resultUnit = 'pa';
      _results = null; _highlightKpa = null; _hasError = false; _errorMsg = null; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(
        child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Formula badge
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline, size: 15, color: AppTheme.accentBlue),
              SizedBox(width: 8),
              Text('Calculation Formula  (Ve & Q)', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
            ]),
            const SizedBox(height: 6),
            const Text('ΔP = (Q × 1.013×10⁵ / Ve) × (T / 60)',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                    color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...[['Ve','Equivalent Inner Volume (mL)'],['T','Detection Time (sec)'],
                ['P','Test Pressure — snaps to nearest table row'],
                ['Q','Leak Rate (mL/min) from LM-1B J1 table'],
                ['ΔP','Differential Pressure (Pa)']
            ].map((r) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                SizedBox(width: 28, child: Text(r[0], style: const TextStyle(
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
          NumericField(controller: _vc, label: 'Equivalent Inner Volume (Ve)', unit: 'mL', hint: 'e.g. 500', validator: _pos),
          NumericField(controller: _tc, label: 'Detection Time (T)', unit: 'sec', hint: 'e.g. 2', validator: _pos),
          PressureInputRow(controller: _pc, selectedUnit: _pressInputUnit,
              label: 'Test Pressure (P)',
              onUnitChanged: (u) { if (u != null) setState(() => _pressInputUnit = u); },
              validator: _pos),
        ]),

        // ΔP result unit — SegmentedButton fills full card width, never overflows
        UnitSelectorCard(
          icon: Icons.swap_horiz_rounded, label: 'ΔP result unit',
          selected: _resultUnit, onChanged: (v) => setState(() => _resultUnit = v),
          segments: const [
            ButtonSegment(value: 'pa',  label: Text('Pa')),
            ButtonSegment(value: 'kpa', label: Text('kPa')),
            ButtonSegment(value: 'bar', label: Text('bar')),
          ],
        ),

        ActionButtons(onCalculate: _calculate, onReset: _reset),

        if (_hasError) ResultCard(hasError: true, errorMessage: _errorMsg, rows: const []),
        if (_results != null && !_hasError) _buildSuggestionTable(),
        _buildDataTable(),
        const SizedBox(height: 20),
      ])),
      ),
    );
  }

  // ── Suggestion table ──────────────────────────────────────
  Widget _buildSuggestionTable() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: [
            const Icon(Icons.recommend_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'LM Selection  |  ${_highlightKpa} kPa  |  Ve:${_vc.text}mL  |  T:${_tc.text}s',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
        Container(
          decoration: const BoxDecoration(color: AppTheme.lightBlue),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            _th('Type', flex: 2),
            _th('Leak Rate\n(mL/min)', flex: 3),
            _th('Calc. ΔP\n(${_ru.label})', flex: 3),
          ]),
        ),
        ..._results!.map((r) {
          final ok    = r.leakRate != null;
          final disp  = ok ? _ru.fromPascals(r.deltaP!) : null;
          return Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(
                color: AppTheme.dividerGrey.withOpacity(0.5)))),
            child: Row(children: [
              _td(r.type, flex: 2, bold: true, color: AppTheme.primaryBlue),
              _td(ok ? r.leakRate!.toStringAsFixed(2) : '—', flex: 3,
                  color: ok ? AppTheme.textBody : AppTheme.textHint),
              _td(ok ? _fDP(disp!) : '—', flex: 3,
                  bold: ok, color: ok ? AppTheme.errorRed : AppTheme.textHint),
            ]),
          );
        }),
        _legend(),
      ]),
    );
  }

  Widget _th(String t, {int flex = 1}) => Expanded(flex: flex,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: AppTheme.textDark), textAlign: TextAlign.center)));

  Widget _td(String t, {int flex = 1, bool bold = false, Color color = AppTheme.textBody}) =>
      Expanded(flex: flex,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(t, style: TextStyle(fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: color),
              textAlign: TextAlign.center)));

  String _fDP(double v) {
    if (v.abs() >= 1000) return v.toStringAsFixed(2);
    if (v.abs() >= 1)    return v.toStringAsFixed(4);
    return v.toStringAsFixed(6);
  }

  // ── Legend — Wrap prevents overflow on any screen width ──
  Widget _legend() => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(spacing: 16, runSpacing: 6, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(
            color: AppTheme.lightBlue, border: Border.all(color: AppTheme.dividerGrey))),
        const SizedBox(width: 6),
        const Text('Measured', style: TextStyle(fontSize: 11, color: AppTheme.textBody)),
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: AppTheme.dividerGrey))),
        const SizedBox(width: 6),
        const Text('Calculated by formula', style: TextStyle(fontSize: 11, color: AppTheme.textBody)),
      ]),
    ]),
  );

  // ── LM-1B Data Table — centred, horizontal scroll ────────
  Widget _buildDataTable() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(color: AppTheme.darkBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          child: const Center(child: Text('LM-1B – J1 Series  Data Table',
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w800, letterSpacing: 0.4))),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(color: Color(0xFFFFF9C4)),
          child: const Center(child: Text('Leak Rate (mL/min) by Test Pressure (kPa)',
              style: TextStyle(fontSize: 11, color: AppTheme.textBody, fontStyle: FontStyle.italic))),
        ),

        // Centred + horizontally scrollable
        LayoutBuilder(builder: (ctx, con) {
          final table = DataTable(
            headingRowHeight: 44, dataRowMinHeight: 32, dataRowMaxHeight: 36,
            columnSpacing: 14,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF176)),
            border: TableBorder.all(color: AppTheme.dividerGrey, width: 0.5),
            columns: [
              const DataColumn(label: Text('Pressure\n(kPa)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textDark))),
              ...kLeakMasterTypes.map((t) => DataColumn(label: Text(t,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue)))),
            ],
            rows: kLeakMasterPressures.map((p) {
              final rd  = kLeakMasterTable[p]!;
              final sel = _highlightKpa != null && p == _highlightKpa;
              final idx = kLeakMasterPressures.indexOf(p);
              return DataRow(
                color: WidgetStateProperty.all(sel ? AppTheme.lightBlue
                    : idx % 2 == 0 ? const Color(0xFFFFFDE7) : Colors.white),
                cells: [
                  DataCell(Text('$p', style: TextStyle(fontSize: 12,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? AppTheme.primaryBlue : AppTheme.textDark))),
                  ...rd.map((v) => DataCell(Text(v != null ? v.toStringAsFixed(2) : '—',
                      style: TextStyle(fontSize: 12,
                          color: v != null ? (sel ? AppTheme.errorRed : AppTheme.textBody) : AppTheme.textHint,
                          fontWeight: sel && v != null ? FontWeight.w700 : FontWeight.w400),
                      textAlign: TextAlign.right))),
                ],
              );
            }).toList(),
          );
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: con.maxWidth),
              child: Center(child: table),
            ),
          );
        }),

        // Legend at bottom — Wrap so it never overflows on any screen
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 6, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 14, height: 14,
                  decoration: const BoxDecoration(color: Color(0xFFFFFDE7))),
              const SizedBox(width: 6),
              const Text('Value actually measured',
                  style: TextStyle(fontSize: 11, color: AppTheme.textBody)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(
                  color: Colors.white, border: Border.all(color: AppTheme.dividerGrey))),
              const SizedBox(width: 6),
              const Text('Value calculated by formula only',
                  style: TextStyle(fontSize: 11, color: AppTheme.textBody)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _LMResult {
  final String type; final double? leakRate, deltaP;
  const _LMResult({required this.type, required this.leakRate, required this.deltaP});
}
