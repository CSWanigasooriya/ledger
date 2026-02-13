import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/student_provider.dart';

class QrPrintScreen extends StatelessWidget {
  final String studentId;
  const QrPrintScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final student = provider.students
            .where((s) => s.id == studentId)
            .firstOrNull;

        if (student == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('QR Code')),
            body: const Center(child: Text('Student not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Student QR Card'),
            actions: [
              FilledButton.icon(
                onPressed: () => _printQrCard(
                  context,
                  student.fullName,
                  student.qrCode,
                  student.id,
                ),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Preview Card
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LEDGER',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        QrImageView(
                          data: student.qrCode,
                          version: QrVersions.auto,
                          size: 180,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: colorScheme.onSurface,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          student.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            student.qrCode,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Preview of the student QR card',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _printQrCard(
    BuildContext context,
    String name,
    String qrCode,
    String studentId,
  ) async {
    final pdf = pw.Document();

    final qrImage = await QrPainter(
      data: qrCode,
      version: QrVersions.auto,
      gapless: true,
    ).toImageData(300);

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          8.5 * PdfPageFormat.cm,
          5.4 * PdfPageFormat.cm,
          marginAll: 0.5 * PdfPageFormat.cm,
        ),
        build: (pw.Context ctx) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'LEDGER',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        qrCode,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (qrImage != null)
                  pw.Image(
                    pw.MemoryImage(qrImage.buffer.asUint8List()),
                    width: 80,
                    height: 80,
                  ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'QR_${name.replaceAll(' ', '_')}',
    );
  }
}
