import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/services/file_download_service.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

class ViewInvoiceScreen extends StatefulWidget {
  const ViewInvoiceScreen({
    super.key,
    required this.transaction,
  });

  final TransactionItem transaction;

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  // Unpadded day (e.g. "Aug 9, 2026") to match the web invoice modal.
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  String _formatDate(DateTime date) => _dateFormat.format(date);

  // Invoices carry no room field of their own, so the student's current
  // classroom is looked up separately by student code.
  String? _roomName;

  // The transaction row (esp. the family-ledger "Family Transaction" list)
  // only carries a summary shape with no invoice number/due date/service
  // period — the web app's invoice modal shows all three, so the full
  // invoice is fetched by code here to match it, regardless of which list
  // this screen was opened from.
  InvoiceListItemEntity? _invoiceDetail;

  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadRoomName();
    _loadInvoiceDetail();
  }

  Future<void> _loadRoomName() async {
    final code = widget.transaction.studentCode?.trim();
    if (code == null || code.isEmpty) return;
    try {
      final profile = await serviceLocator<GetStudentProfileUseCase>()(
        code: code,
      );
      if (!mounted) return;
      setState(() => _roomName = profile.classroomName);
    } catch (_) {
      // No room fallback — the row is simply omitted.
    }
  }

  Future<void> _loadInvoiceDetail() async {
    final code = widget.transaction.invoiceCode?.trim();
    if (code == null || code.isEmpty) {
      debugPrint(
        '[ViewInvoiceScreen] No invoiceCode on this transaction row — '
        'Invoice Number/Due Date/Invoice Period will fall back to the '
        'summary the list screen passed in.',
      );
      return;
    }
    try {
      final detail = await serviceLocator<GetInvoiceByCodeUseCase>()(code);
      if (!mounted) return;
      setState(() => _invoiceDetail = detail);
    } catch (e) {
      // Fall back to whatever summary fields the transaction row carried.
      CoreUtils.logApiError('[ViewInvoiceScreen] getInvoiceByCode($code) failed: $e');
    }
  }

  String? get _invoiceNumberLabel {
    final code = (_invoiceDetail?.code ?? widget.transaction.invoiceCode ?? '')
        .trim();
    return code.isEmpty ? null : code;
  }

  String? get _dueDateLabel {
    final resolved = _invoiceDetail?.dueDate;
    if (resolved != null) return _formatDate(resolved);
    final raw = widget.transaction.endDate;
    if (raw != null && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) return _formatDate(parsed);
    }
    return null;
  }

  String? get _invoicePeriodLabel {
    final start = _invoiceDetail?.periodStart;
    final end = _invoiceDetail?.periodEnd;
    if (start == null || end == null) return null;
    return '${_formatDate(start)} to ${_formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'View Invoice',
      bottomBar: _buildBottomBar(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BillingSchoolHeader(),
            const SizedBox(height: 20),
            _buildBilledForRow(),
            const SizedBox(height: 16),
            _buildInvoiceMeta(),
            const SizedBox(height: 12),
            _buildItemsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildBilledForRow() {
    final classroom = (_roomName ?? widget.transaction.classroom).trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Billed for : ',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.transaction.studentName,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (classroom.isNotEmpty)
                Text(
                  classroom,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceMeta() {
    // Matches the web invoice modal's field set (Invoice Number / Due Date /
    // Invoice Period). Falls back to the issue date only if none of those
    // resolved (e.g. the invoice-detail fetch failed and the row carried no
    // invoiceCode), so the screen never renders with no date at all.
    final rows = <Widget>[
      if (_invoiceNumberLabel != null)
        _metaRow('Invoice Number', _invoiceNumberLabel!),
      if (_dueDateLabel != null) _metaRow('Due Date', _dueDateLabel!),
      if (_invoicePeriodLabel != null)
        _metaRow('Invoice Period', _invoicePeriodLabel!),
    ];
    if (rows.isEmpty) {
      rows.add(_metaRow('Invoice Date', _formatDate(widget.transaction.date)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          rows[i],
        ],
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.billingGreyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  widget.transaction.displayDescription,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '\$${widget.transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$${widget.transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// School name + address for the PDF header — same storage/API sourcing
  /// as [BillingSchoolHeader], fetched fresh here since that widget keeps
  /// its resolved data private to itself.
  Future<({String name, String address})> _fetchSchoolHeaderForPdf() async {
    final storage = serviceLocator<StorageService>();
    final fallbackName =
        (await storage.getString(StorageKeys.selectedSchoolName) ?? '').trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    if (schoolCode.isEmpty) {
      return (name: fallbackName.isEmpty ? 'School' : fallbackName, address: '');
    }
    try {
      final client = serviceLocator<ApiClient>().client;
      final response = await client.get<dynamic>(
        ApiPaths.url(ApiPaths.schoolByCode(schoolCode)),
      );
      final body = response.data;
      if (body is! Map) {
        return (name: fallbackName.isEmpty ? 'School' : fallbackName, address: '');
      }
      final data = (body['data'] is Map ? body['data'] : body) as Map;

      String pick(Map source, List<String> keys) {
        for (final k in keys) {
          final v = (source[k] ?? '').toString().trim();
          if (v.isNotEmpty) return v;
        }
        return '';
      }

      final name = pick(data, ['name', 'schoolName']);
      final addr = data['address'] is Map ? data['address'] as Map : data;
      final addressParts = <String>[
        pick(addr, ['line1', 'addressLine1', 'line', 'street', 'addressLine']),
        pick(addr, ['line2', 'addressLine2']),
        pick(addr, ['city']),
        pick(addr, ['state', 'province']),
        pick(addr, ['country']),
        pick(addr, ['postalCode', 'zipCode', 'zipcode', 'zip']),
      ].where((p) => p.isNotEmpty).toList();

      return (
        name: name.isNotEmpty ? name : (fallbackName.isEmpty ? 'School' : fallbackName),
        address: addressParts.join(', '),
      );
    } catch (_) {
      return (name: fallbackName.isEmpty ? 'School' : fallbackName, address: '');
    }
  }

  /// Builds a single-page PDF mirroring exactly what's on screen (school
  /// header, Billed for + classroom, invoice meta rows, the item row, and
  /// the total) and returns its bytes.
  Future<Uint8List> _buildInvoicePdfBytes() async {
    final school = await _fetchSchoolHeaderForPdf();
    final classroom = (_roomName ?? widget.transaction.classroom).trim();

    final metaRows = <String>[
      if (_invoiceNumberLabel != null) 'Invoice Number : $_invoiceNumberLabel',
      if (_dueDateLabel != null) 'Due Date : $_dueDateLabel',
      if (_invoicePeriodLabel != null) 'Invoice Period : $_invoicePeriodLabel',
    ];
    if (metaRows.isEmpty) {
      metaRows.add('Invoice Date : ${_formatDate(widget.transaction.date)}');
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              school.name,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (school.address.isNotEmpty)
              pw.Text(school.address, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 20),
            pw.Text(
              'Billed for : ${widget.transaction.studentName}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            if (classroom.isNotEmpty)
              pw.Text(classroom, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 14),
            for (final row in metaRows) pw.Text(row, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 20),
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Description', style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('Amount', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(widget.transaction.displayDescription),
                      pw.Text('\$${widget.transaction.amount.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.grey300,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          '\$${widget.transaction.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _downloadInvoicePdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final bytes = await _buildInvoicePdfBytes();
      final invoiceNumber =
          _invoiceNumberLabel ?? widget.transaction.id.toString();
      final fileName = 'Invoice_$invoiceNumber.pdf';
      final downloadService = serviceLocator<FileDownloadService>();
      final savedPath = await downloadService.saveFile(
        fileData: bytes,
        fileName: fileName,
        assetCode: invoiceNumber,
        mimeType: 'application/pdf',
      );
      if (!mounted) return;
      if (savedPath == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to save the invoice PDF',
          isError: true,
        );
        return;
      }
      final opened = await downloadService.openFile(
        filePath: savedPath,
        fileName: fileName,
        assetCode: invoiceNumber,
        mimeType: 'application/pdf',
      );
      if (!mounted) return;
      if (opened) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Invoice saved',
          isSuccess: true,
        );
      } else {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Invoice saved, but no app could open it',
          isWarning: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Error generating the invoice PDF: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Widget _buildBottomBar() {
    final isParent = context.read<RoleCubit>().isParent;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.buildPrimaryGradient(),
          ),
          child: TextButton(
            onPressed: isParent
                ? (_isDownloading ? null : _downloadInvoicePdf)
                : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isParent && _isDownloading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.billingButtonTextColor,
                      ),
                    ),
                  )
                : Text(
                    isParent ? 'Download' : 'Send Invoice',
                    style: TextStyle(
                      color: AppColors.billingButtonTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
