import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/proposel.dart';

class PdfService {
  Future<Uint8List> build(
      Proposal p, {
        double? hourlyRate,
        String currency = '',
      }) async {
    // Noto Sans supports far more characters than the default PDF font.
    // It is downloaded when the PDF is made, so it needs an internet connection.
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

    pw.Widget heading(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
      child: pw.Text(
        t,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            p.projectTitle,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(p.summary),

          heading('Scope & estimate'),
          ...p.tasks.map(
                (t) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          t.name,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(t.description),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text('${t.hours.toStringAsFixed(0)} h'),
                ],
              ),
            ),
          ),
          pw.Divider(),
          pw.Text(
            'Total: ${p.totalHours.toStringAsFixed(0)} hours',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (hourlyRate != null && hourlyRate > 0)
            pw.Text(
              'Estimated price: $currency${(p.totalHours * hourlyRate).toStringAsFixed(0)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

          if (p.milestones.isNotEmpty) ...[
            heading('Timeline'),
            ...p.sortedMilestones.map(
                  (m) => pw.Bullet(text: 'Week ${m.week}: ${m.name}'),
            ),
          ],
          if (p.assumptions.isNotEmpty) ...[
            heading('Assumptions'),
            ...p.assumptions.map((a) => pw.Bullet(text: a)),
          ],
          if (p.questionsForClient.isNotEmpty) ...[
            heading('Questions to confirm'),
            ...p.questionsForClient.map((q) => pw.Bullet(text: q)),
          ],
        ],
      ),
    );

    return doc.save();
  }
}