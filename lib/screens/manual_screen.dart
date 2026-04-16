// screens/manual_screen.dart — with download support via share_plus

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../models/machine_model.dart';
import '../widgets/cosmo_logo.dart';

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});
  @override State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  MachineModel? _selectedModel;
  String?  _localPdfPath;
  bool     _isLoading      = false;
  bool     _hasError       = false;
  String?  _errorMsg;
  int      _totalPages     = 0;
  int      _currentPage    = 0;
  bool     _isDownloading  = false;   // download-in-progress flag
  PDFViewController? _pdfController;

  // ── Load PDF from assets into temp dir ────────────────────────────────────
  Future<void> _onModelSelected(MachineModel model) async {
    setState(() {
      _selectedModel = model; _localPdfPath = null;
      _isLoading = true; _hasError = false; _errorMsg = null;
      _totalPages = 0; _currentPage = 0; _pdfController = null;
    });
    try {
      final path = await _extractAssetToTemp(model.assetPath!);
      if (mounted) setState(() { _localPdfPath = path; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMsg = e.toString(); });
    }
  }

  Future<String> _extractAssetToTemp(String assetPath) async {
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/${assetPath.split('/').last}');
    if (!await file.exists()) {
      final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }

  // ── Download / Share the PDF ───────────────────────────────────────────────
  // On Android: system share sheet → user can pick "Save to Downloads" / Drive etc.
  // On iOS:     standard share sheet → save to Files, AirDrop, etc.
  Future<void> _downloadPdf() async {
    if (_localPdfPath == null || _selectedModel == null) return;
    setState(() => _isDownloading = true);
    try {
      final file    = XFile(_localPdfPath!, mimeType: 'application/pdf');
      final name    = _selectedModel!.displayName;
      final result  = await Share.shareXFiles(
        [file],
        subject: '$name — Cosmo Manual',
        text:    'Manual for $name',
      );

      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        _showSnack('Saved / shared successfully', success: true);
      } else if (result.status == ShareResultStatus.dismissed) {
        // user cancelled — no message needed
      }
    } catch (e) {
      if (mounted) _showSnack('Download failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_outline : Icons.error_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: success ? const Color(0xFF2E7D32) : AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: _buildAppBar(),
      body: Column(children: [
        _buildModelSelector(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkBlue, AppTheme.primaryBlue],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

              // ── COSMO LOGO ──────────────────────────────────────────────
              Image.asset(
                'assets/images/cosmo_logo.jpeg',
                height: 38,
                width:  106,
                fit:    BoxFit.contain,
                errorBuilder: (_, __, ___) => const CosmoLogoPainted(size: 38),
              ),

              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Troubleshooting',
                        style: TextStyle(color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    Text('Select a model to view its Error Manual',
                        style: TextStyle(color: Colors.white.withOpacity(0.72),
                            fontSize: 10),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),

              // Page counter (only while PDF is open)
              if (_totalPages > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_currentPage + 1}/$_totalPages',
                      style: const TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],

              // ── Download button — only visible when a PDF is loaded ──────
              if (_localPdfPath != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Download / Share PDF',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _isDownloading ? null : _downloadPdf,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: _isDownloading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.download_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ── Model selector ─────────────────────────────────────────────────────────
  Widget _buildModelSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.precision_manufacturing_outlined,
              size: 18, color: AppTheme.primaryBlue),
          SizedBox(width: 8),
          Text('Machine Model', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<MachineModel>(
          value: _selectedModel,
          hint: const Text('Select a model...',
              style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.dividerGrey, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2)),
          ),
          items: kMachineModels.map((m) => DropdownMenuItem(
            value: m,
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppTheme.accentBlue),
              const SizedBox(width: 8),
              Expanded(child: Text(m.displayName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: AppTheme.textBody),
                  overflow: TextOverflow.ellipsis)),
            ]),
          )).toList(),
          onChanged: (m) { if (m != null) _onModelSelected(m); },
          icon: const Icon(Icons.expand_more, color: AppTheme.primaryBlue),
          dropdownColor: Colors.white,
          isExpanded: true,
        ),
      ]),
    );
  }

  // ── Body dispatcher ────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_localPdfPath != null) return _buildPdfView();
    return LayoutBuilder(builder: (context, constraints) {
      Widget content;
      if (_isLoading)     content = _buildLoader();
      else if (_hasError) content = _buildError();
      else                content = _buildPlaceholder();

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: content),
        ),
      );
    });
  }

  // ── States ─────────────────────────────────────────────────────────────────
  Widget _buildPlaceholder() => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
            color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.picture_as_pdf_outlined,
            color: AppTheme.accentBlue, size: 36)),
      const SizedBox(height: 16),
      const Text('No Manual Selected',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppTheme.textDark),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('Choose a model from the dropdown above.',
          style: TextStyle(fontSize: 13, color: AppTheme.textBody.withOpacity(0.7)),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.lightBlue.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentBlue.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Available Models',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue)),
          const SizedBox(height: 8),
          ...kMachineModels.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.accentBlue),
              const SizedBox(width: 4),
              Expanded(child: Text(m.displayName,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textBody,
                      fontWeight: FontWeight.w500))),
            ]),
          )),
        ]),
      ),
    ]),
  ));

  Widget _buildLoader() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: AppTheme.primaryBlue, strokeWidth: 3),
      const SizedBox(height: 16),
      Text('Loading ${_selectedModel?.displayName ?? "manual"}...',
          style: const TextStyle(fontSize: 14, color: AppTheme.textBody),
          textAlign: TextAlign.center),
    ]),
  ));

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 52, color: AppTheme.errorRed),
      const SizedBox(height: 14),
      const Text('Failed to load PDF',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: AppTheme.errorRed),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        _errorMsg?.contains('Unable to load asset') == true
            ? 'File not found.\nPlace PDF in assets/manuals/ with exact filename.'
            : (_errorMsg ?? 'Unknown error'),
        style: const TextStyle(fontSize: 13, color: AppTheme.textBody, height: 1.5),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      ElevatedButton.icon(
        onPressed: () => _onModelSelected(_selectedModel!),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    ]),
  ));

  // ── PDF viewer with toolbar ────────────────────────────────────────────────
  Widget _buildPdfView() => Column(children: [
    Container(
      decoration: BoxDecoration(color: AppTheme.darkBlue.withOpacity(0.06)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        const Icon(Icons.picture_as_pdf, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Expanded(child: Text(_selectedModel?.displayName ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue),
            overflow: TextOverflow.ellipsis)),

        // ── Inline Download button in PDF toolbar ────────────────────────
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isDownloading ? null : _downloadPdf,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _isDownloading
                  ? const SizedBox(width: 13, height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppTheme.primaryBlue))
                  : const Icon(Icons.download_rounded,
                      size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 5),
              Text(_isDownloading ? 'Saving…' : 'Download',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
            ]),
          ),
        ),

        // Page navigation
        if (_totalPages > 1) ...[
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
            onPressed: _currentPage > 0
                ? () => _pdfController?.setPage(_currentPage - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text('${_currentPage + 1}/$_totalPages',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
            onPressed: _currentPage < _totalPages - 1
                ? () => _pdfController?.setPage(_currentPage + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ]),
    ),

    Expanded(child: PDFView(
      filePath: _localPdfPath!,
      enableSwipe: true, swipeHorizontal: false,
      autoSpacing: true, pageFling: true, pageSnap: true,
      defaultPage: 0, fitPolicy: FitPolicy.BOTH,
      onRender:     (p)   { if (mounted) setState(() => _totalPages = p ?? 0); },
      onViewCreated:(c)   { if (mounted) setState(() => _pdfController = c); },
      onPageChanged:(p,t) { if (mounted) setState(() { _currentPage = p ?? 0; _totalPages = t ?? 0; }); },
      onError:      (e)   { if (mounted) setState(() { _hasError = true; _errorMsg = e.toString(); }); },
      onPageError:  (p,e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error page $p: $e'), backgroundColor: AppTheme.errorRed)); },
    )),
  ]);
}
