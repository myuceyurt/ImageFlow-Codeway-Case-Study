import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  Future<File> generatePdfFromImage(File imageFile) async {
    return generatePdfFromImages([imageFile]);
  }

  Future<File> generatePdfFromImages(List<File> imageFiles) async {
    final pdf = pw.Document();
    for (final imageFile in imageFiles) {
      final image = pw.MemoryImage(
        imageFile.readAsBytesSync(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
