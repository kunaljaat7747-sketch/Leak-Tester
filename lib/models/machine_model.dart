// ============================================================
// models/machine_model.dart
// Data model for machine manuals
// ============================================================

enum ManualSource { asset, url }

/// Represents a single machine model with its associated PDF manual.
class MachineModel {
  final String id;          // Unique identifier / display name
  final String displayName; // Label shown in the dropdown
  final ManualSource source;
  final String? assetPath;  // e.g. 'assets/manuals/ls_r902_eng.pdf'
  final String? pdfUrl;     // Remote URL if not bundled locally

  const MachineModel({
    required this.id,
    required this.displayName,
    required this.source,
    this.assetPath,
    this.pdfUrl,
  });

  /// Whether this model has a valid manual path configured.
  bool get hasManual =>
      (source == ManualSource.asset && assetPath != null) ||
      (source == ManualSource.url && pdfUrl != null);
}

// ============================================================
// Catalogue of all supported machine models.
// Replace assetPath / pdfUrl with real values before shipping.
// ============================================================
const List<MachineModel> kMachineModels = [
  // MachineModel(
  //   id: 'LS-R902-ENG',
  //   displayName: 'LS-R902-ENG',
  //   source: ManualSource.asset,
  //   assetPath: 'assets/manuals/LS_R902_ENG.pdf',
  // ),
  // MachineModel(
  //   id: 'LS-R902-Temperature',
  //   displayName: 'LS-R902-Temperature',
  //   source: ManualSource.asset,
  //   assetPath: 'assets/manuals/LS_R902_Temperature.pdf',
  // ),
  // MachineModel(
  //   id: 'LS-R700-TH',
  //   displayName: 'LS-R700-TH',
  //   source: ManualSource.asset,
  //   assetPath: 'assets/manuals/LS_R700_TH.pdf',
  // ),
  // MachineModel(
  //   id: 'LS-R700-ENG',
  //   displayName: 'LS-R700-ENG',
  //   source: ManualSource.asset,
  //   assetPath: 'assets/manuals/LS_R700_ENG.pdf',
  // ),
  // MachineModel(
  //   id: 'LS-1866-ENG',
  //   displayName: 'LS-1866-ENG',
  //   source: ManualSource.asset,
  //   assetPath: 'assets/manuals/LS_1866_ENG.pdf',
  // ),
  // MachineModel(
  //   id: 'LM-1C-Series',
  //   displayName: 'LM-1C Series',
  //   source: ManualSource.asset,
  //   assetPath: 'assets/manuals/LM_1C_Series.pdf',
  // ),
  MachineModel(
    id: 'LS_R700',
    displayName: 'LS_R700',
    source: ManualSource.asset,
    assetPath: 'assets/manuals/LS_R700.pdf',
  ),
  MachineModel(
    id: 'LS_R900',
    displayName: 'LS_R900',
    source: ManualSource.asset,
    assetPath: 'assets/manuals/LS_R900.pdf',
  ),
  MachineModel(
    id: 'LS_R740',
    displayName: 'LS_R740',
    source: ManualSource.asset,
    assetPath: 'assets/manuals/LS_R740.pdf',
  ),
  MachineModel(
    id: 'LS_R1866',
    displayName: 'LS_1866',
    source: ManualSource.asset,
    assetPath: 'assets/manuals/LS_1866.pdf',
  ),
  MachineModel(
    id: 'LS_R1864X',
    displayName: 'LS_1864X',
    source: ManualSource.asset,
    assetPath: 'assets/manuals/LS_1864X.pdf',
  ),
  MachineModel(
    id: 'AF_2400',
    displayName: 'AF_2400',
    source: ManualSource.asset,
    assetPath: 'assets/manuals/AF_2400.pdf',
  ),
  MachineModel(
    id: 'AF_R220',
    displayName: 'AF_R220',
    source: ManualSource.asset,
    assetPath: 'assets/manuals/AF_R220.pdf',
  )
];
