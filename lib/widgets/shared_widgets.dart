// widgets/shared_widgets.dart
// All Rows use Expanded/Flexible — zero overflow risk.
// SegmentedButton used for unit selection (replaces ChoiceChip rows).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/calculations.dart';

// ── SectionCard ───────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const SectionCard({super.key, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.dividerGrey),
          const SizedBox(height: 14),
          ...children,
        ]),
      ),
    );
  }
}

// ── NumericField ──────────────────────────────────────────────
class NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final String? hint;
  final String? Function(String?)? validator;
  final bool allowNegative;
  const NumericField({super.key, required this.controller, required this.label,
      required this.unit, this.hint, this.validator, this.allowNegative = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [FilteringTextInputFormatter.allow(
            allowNegative ? RegExp(r'^-?\d*\.?\d*') : RegExp(r'^\d*\.?\d*'))],
        validator: validator,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textBody),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: unit,
          suffixStyle: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

// ── PressureInputRow — text + Pa/kPa/bar dropdown ─────────────
class PressureInputRow extends StatelessWidget {
  final TextEditingController controller;
  final PressureUnit selectedUnit;
  final ValueChanged<PressureUnit?> onUnitChanged;
  final String? Function(String?)? validator;
  final String label;
  const PressureInputRow({super.key, required this.controller,
      required this.selectedUnit, required this.onUnitChanged,
      this.validator, this.label = 'Pressure Drop (ΔP)'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Input field — flex 6
        Expanded(
          flex: 6,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            validator: validator,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textBody),
            decoration: InputDecoration(
              labelText: label,
              hintText: 'e.g. 100',
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                borderSide: BorderSide(color: AppTheme.dividerGrey)),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                borderSide: BorderSide(color: AppTheme.dividerGrey, width: 1.2)),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                borderSide: BorderSide(color: AppTheme.accentBlue, width: 2)),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                borderSide: BorderSide(color: AppTheme.errorRed, width: 1.5)),
            ),
          ),
        ),
        // Unit dropdown — flex 3
        Expanded(
          flex: 3,
          child: Container(
            height: 52,
            decoration: const BoxDecoration(
              color: AppTheme.lightBlue,
              border: Border(
                top:    BorderSide(color: AppTheme.accentBlue, width: 1.2),
                right:  BorderSide(color: AppTheme.accentBlue, width: 1.2),
                bottom: BorderSide(color: AppTheme.accentBlue, width: 1.2),
              ),
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PressureUnit>(
                value: selectedUnit,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, size: 16, color: AppTheme.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700, fontSize: 13),
                dropdownColor: Colors.white,
                items: PressureUnit.values.map((u) =>
                    DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                onChanged: onUnitChanged,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── UnitSelectorCard — SegmentedButton, NEVER overflows ───────
// Used for result unit selection (Pa/kPa/bar) and scale (×1/×2/×5/×10)
class UnitSelectorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<ButtonSegment<String>> segments;
  final String selected;
  final ValueChanged<String> onChanged;

  const UnitSelectorCard({super.key, required this.label, required this.icon,
      required this.segments, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 17, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          ]),
          const SizedBox(height: 8),
          // SegmentedButton fills full width — zero overflow risk
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: segments,
              selected: {selected},
              onSelectionChanged: (s) => onChanged(s.first),
              style: SegmentedButton.styleFrom(
                backgroundColor:         AppTheme.bgGrey,
                selectedBackgroundColor: AppTheme.primaryBlue,
                selectedForegroundColor: Colors.white,
                foregroundColor:         AppTheme.textBody,
                side: const BorderSide(color: AppTheme.dividerGrey),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                visualDensity: VisualDensity.compact,
              ),
              showSelectedIcon: false,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── ActionButtons ─────────────────────────────────────────────
class ActionButtons extends StatelessWidget {
  final VoidCallback onCalculate;
  final VoidCallback onReset;
  final bool isLoading;
  const ActionButtons({super.key, required this.onCalculate,
      required this.onReset, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onCalculate,
            icon: isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Calculate'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset'),
          ),
        ),
      ]),
    );
  }
}

// ── ResultCard ────────────────────────────────────────────────
class ResultCard extends StatelessWidget {
  final List<ResultRow> rows;
  final bool hasError;
  final String? errorMessage;
  const ResultCard({super.key, required this.rows,
      this.hasError = false, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: hasError
              ? LinearGradient(colors: [AppTheme.errorRed.withOpacity(0.06), AppTheme.errorRed.withOpacity(0.02)])
              : LinearGradient(colors: [AppTheme.primaryBlue.withOpacity(0.07), AppTheme.lightBlue.withOpacity(0.3)]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(hasError ? Icons.error_outline_rounded : Icons.analytics_outlined,
                  color: hasError ? AppTheme.errorRed : AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(hasError ? 'Calculation Error' : 'Results',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: hasError ? AppTheme.errorRed : AppTheme.primaryBlue)),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (hasError)
              Text(errorMessage ?? 'Unknown error.',
                  style: const TextStyle(color: AppTheme.errorRed, fontSize: 14))
            else
              ...rows.map(_buildRow),
          ]),
        ),
      ),
    );
  }

  Widget _buildRow(ResultRow r) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(
        flex: 5,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.label, style: const TextStyle(fontSize: 12,
              color: AppTheme.textHint, fontWeight: FontWeight.w500)),
          if (r.sublabel != null)
            Text(r.sublabel!, style: const TextStyle(fontSize: 10,
                color: AppTheme.textHint, fontStyle: FontStyle.italic)),
        ]),
      ),
      Expanded(
        flex: 5,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Flexible(
            child: Text(r.value,
                style: TextStyle(
                  fontSize: r.isPrimary ? 17 : 15,
                  fontWeight: r.isPrimary ? FontWeight.w800 : FontWeight.w600,
                  color: r.isPrimary ? AppTheme.primaryBlue : AppTheme.textBody,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 4),
          Text(r.unit, style: const TextStyle(fontSize: 12,
              color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]),
  );
}

class ResultRow {
  final String label;
  final String? sublabel;
  final String value;
  final String unit;
  final bool isPrimary;
  const ResultRow({required this.label, this.sublabel, required this.value,
      required this.unit, this.isPrimary = false});
}

// ── InfoBadge ─────────────────────────────────────────────────
class InfoBadge extends StatelessWidget {
  final String text;
  const InfoBadge({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 15, color: AppTheme.accentBlue),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12,
            color: AppTheme.primaryBlue, fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
