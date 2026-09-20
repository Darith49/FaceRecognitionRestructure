import 'dart:typed_data';

import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/utils/report_period.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds the "Overtime Report" PDF and hands it to the phone's share sheet
/// (from there the employee can save it to the phone, Drive, Files, send it...).
///
/// NOTE: uses the built-in PDF font, so plain English text and numbers are
/// fine. Khmer text (names / reasons) will not show correctly with it.
class OvertimeReportPdf {
  OvertimeReportPdf._();

  static const PdfColor _blue = PdfColor.fromInt(0xFF3B78F0);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _softBlue = PdfColor.fromInt(0xFFEFF4FE);

  /// Creates the PDF and opens the share / save sheet.
  /// [requests] must not be empty and should already be filtered + sorted.
  static Future<void> share({
    required List<OvertimeRequest> requests,
    required ReportPeriod period,
  }) async {
    final bytes = await build(requests: requests, period: period);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'overtime_report_${period.fileSuffix}.pdf',
    );
  }

  static Future<Uint8List> build({
    required List<OvertimeRequest> requests,
    required ReportPeriod period,
  }) async {
    final owner = requests.first;
    final total = _sum(requests);
    final approved = _sum(
      requests.where((r) => r.status == OvertimeStatus.approved),
    );

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Overtime Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _blue,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            period.label,
            style: const pw.TextStyle(fontSize: 12, color: _grey),
          ),
          pw.SizedBox(height: 16),
          _infoRow('Employee', owner.fullName),
          _infoRow('Employee ID', owner.employeeId),
          _infoRow(
            'Generated',
            '${DateText.weekdayYmd(DateTime.now())}  ${DateText.time(DateTime.now())}',
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _softBlue,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summary('Total requests', '${requests.length}'),
                _summary('Total overtime', _formatDuration(total)),
                _summary('Approved overtime', _formatDuration(approved)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _table(requests),
        ],
      ),
    );

    return doc.save();
  }

  static Duration _sum(Iterable<OvertimeRequest> requests) {
    return requests.fold<Duration>(
      Duration.zero,
      (sum, request) => sum + request.duration,
    );
  }

  /// 2 h 30 min
  static String _formatDuration(Duration d) {
    final hours = d.inMinutes ~/ 60;
    final minutes = d.inMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: _grey),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summary(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _grey)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _table(List<OvertimeRequest> requests) {
    final header = pw.TableRow(
      decoration: const pw.BoxDecoration(color: _blue),
      children: [
        _cell('No.', header: true),
        _cell('Date', header: true),
        _cell('From', header: true),
        _cell('To', header: true),
        _cell('Duration', header: true),
        _cell('Status', header: true),
        _cell('Reason', header: true),
      ],
    );

    final rows = <pw.TableRow>[];
    for (var i = 0; i < requests.length; i++) {
      final r = requests[i];
      rows.add(
        pw.TableRow(
          children: [
            _cell('${i + 1}'),
            _cell(DateText.ymd(r.date)),
            _cell(DateText.time(r.fromTime)),
            _cell(DateText.time(r.toTime)),
            _cell(_formatDuration(r.duration)),
            _cell(r.status.label),
            _cell(r.reason),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(26),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(52),
        5: const pw.FixedColumnWidth(50),
        6: const pw.FlexColumnWidth(),
      },
      children: [header, ...rows],
    );
  }

  static pw.Widget _cell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }
}
