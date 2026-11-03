import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/proposel.dart';

class PdfService {
  static final _purple = PdfColor.fromInt(0xFF660000);
  static final _soft = PdfColor.fromInt(0xFFFBEFEF);
  static final _ink = PdfColor.fromInt(0xFF1F2937);
  static final _muted = PdfColor.fromInt(0xFF6B7280);
  static final _line = PdfColor.fromInt(0xFFE5E7EB);

  String _fmt(double h) =>
      h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

  // simple = true makes a plain black-and-white PDF.
  Future<Uint8List> build(
      Proposal p, {
        double? hourlyRate,
        String currency = '',
        bool simple = false,
      }) async {
    // Try the nicer font first. If there's no internet, use the built-in one.
    pw.Font regular;
    pw.Font bold;
    try {
      regular = await PdfGoogleFonts.notoSansRegular();
      bold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      regular = pw.Font.helvetica();
      bold = pw.Font.helveticaBold();
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final ms = p.sortedMilestones;
    final weeks = ms.isEmpty ? null : ms.last.week;
    final rate = hourlyRate ?? 0;
    final hasRate = rate > 0;
    final priceText =
    hasRate ? '$currency${(p.totalHours * rate).toStringAsFixed(0)}' : '';

    // Colours: styled uses the purple theme, simple uses black and grey.
    final accent = simple ? PdfColors.black : _purple;
    final textColor = simple ? PdfColors.black : _ink;
    final subColor = simple ? PdfColors.grey800 : _muted;
    final lineColor = simple ? PdfColors.grey400 : _line;

    pw.Widget heading(String t) {
      if (simple) {
        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(top: 18, bottom: 8),
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
          child: pw.Text(
            t,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
        child: pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 14,
              decoration: pw.BoxDecoration(
                color: _purple,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              t,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget header() {
      if (simple) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              p.projectTitle,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(p.summary, style: const pw.TextStyle(fontSize: 10.5)),
          ],
        );
      }
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          color: _purple,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              p.projectTitle,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              p.summary,
              style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.white),
            ),
          ],
        ),
      );
    }

    pw.Widget statBox(String label, String value) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _soft,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _muted)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _purple,
              ),
            ),
          ],
        ),
      ),
    );

    pw.Widget stats() {
      if (simple) {
        final parts = <String>['Total effort: ${_fmt(p.totalHours)} hours'];
        if (weeks != null) {
          parts.add('Duration: $weeks ${weeks == 1 ? 'week' : 'weeks'}');
        }
        if (hasRate) parts.add('Estimated price: $priceText');
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            parts.join('   |   '),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        );
      }
      return pw.Row(
        children: [
          statBox('TOTAL EFFORT', '${_fmt(p.totalHours)} hours'),
          if (weeks != null) ...[
            pw.SizedBox(width: 8),
            statBox('DURATION', '$weeks ${weeks == 1 ? 'week' : 'weeks'}'),
          ],
          if (hasRate) ...[
            pw.SizedBox(width: 8),
            statBox('ESTIMATED PRICE', priceText),
          ],
        ],
      );
    }

    pw.Widget taskRow(TaskItem t) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: lineColor, width: 0.8),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  t.name,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: textColor,
                  ),
                ),
                if (t.description.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      t.description,
                      style: pw.TextStyle(fontSize: 9.5, color: subColor),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Text(
            '${_fmt(t.hours)} h',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: accent,
            ),
          ),
        ],
      ),
    );

    pw.Widget weekRow(Milestone m) {
      if (simple) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            'Week ${m.week}: ${m.name}',
            style: const pw.TextStyle(fontSize: 10.5),
          ),
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 54,
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              decoration: pw.BoxDecoration(
                color: _soft,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                'Week ${m.week}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _purple,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Text(m.name, style: const pw.TextStyle(fontSize: 10.5)),
            ),
          ],
        ),
      );
    }

    pw.Widget dotLine(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Container(
              width: 4,
              height: 4,
              decoration: pw.BoxDecoration(
                color: accent,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: subColor),
          ),
        ),
        build: (context) => [
          header(),
          pw.SizedBox(height: 12),
          stats(),

          heading('Scope & estimate'),
          ...p.tasks.map(taskRow),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: ${_fmt(p.totalHours)} hours'
                  '${hasRate ? '   |   Estimated price: $priceText' : ''}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: textColor,
              ),
            ),
          ),

          if (ms.isNotEmpty) ...[
            heading('Timeline'),
            ...ms.map(weekRow),
          ],
          if (p.assumptions.isNotEmpty) ...[
            heading('Assumptions'),
            ...p.assumptions.map(dotLine),
          ],
          if (p.questionsForClient.isNotEmpty) ...[
            heading('Questions to confirm'),
            ...p.questionsForClient.map(dotLine),
          ],
        ],
      ),
    );

    return doc.save();
  }
}