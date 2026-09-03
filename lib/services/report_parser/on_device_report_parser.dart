import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' show PdfDocument, PdfTextExtractor;

class ParsedReportResult {
  final String rawText;
  final String detectedReportType;
  final String summary;
  final Map<String, String> testResults;
  final String? patientName;
  final String? date;
  final List<String> keyObservations;

  const ParsedReportResult({
    required this.rawText,
    required this.detectedReportType,
    required this.summary,
    required this.testResults,
    this.patientName,
    this.date,
    this.keyObservations = const [],
  });
}

class OnDeviceReportParser {
  OnDeviceReportParser._();
  static final OnDeviceReportParser instance = OnDeviceReportParser._();

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Analyzes an image or PDF report completely on-device.
  /// Returns a structured [ParsedReportResult].
  Future<ParsedReportResult> parseReport(File file) async {
    final path = file.path.toLowerCase();
    String rawText = '';

    try {
      if (path.endsWith('.pdf')) {
        rawText = await _extractTextFromPdf(file);
      } else {
        rawText = await _extractTextFromImage(file);
      }
    } catch (e) {
      debugPrint('OnDeviceReportParser error reading file: $e');
    }

    return analyzeText(rawText);
  }

  /// Extracts text from image using Google ML Kit with spatial row reconstruction.
  Future<String> _extractTextFromImage(File file) async {
    final inputImage = InputImage.fromFilePath(file.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Reconstruct spatial line text so table columns on the same row are merged together
    final spatialText = _reconstructSpatialText(recognizedText);

    // Combine spatial text and original block text so all pattern extractors succeed
    return '$spatialText\n\n--- RAW BLOCKS ---\n${recognizedText.text}';
  }

  /// Reconstructs table rows by clustering text lines that share the same vertical Y coordinate.
  String _reconstructSpatialText(RecognizedText recognizedText) {
    final List<TextLine> lines = [];
    for (final block in recognizedText.blocks) {
      lines.addAll(block.lines);
    }
    if (lines.isEmpty) return recognizedText.text;

    // Sort lines top to bottom
    lines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // Group lines into rows where their vertical centers fall within threshold
    final List<List<TextLine>> rows = [];
    for (final line in lines) {
      final lineY = line.boundingBox.top + (line.boundingBox.height / 2);
      bool placed = false;
      for (final row in rows) {
        final rowY = row.first.boundingBox.top + (row.first.boundingBox.height / 2);
        final avgHeight = (row.first.boundingBox.height + line.boundingBox.height) / 2;
        // Lines with Y coordinates within 70% of line height are in the same row
        if ((lineY - rowY).abs() < avgHeight * 0.7) {
          row.add(line);
          placed = true;
          break;
        }
      }
      if (!placed) {
        rows.add([line]);
      }
    }

    // Sort each row left to right
    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    }

    // Sort rows from top to bottom
    rows.sort((a, b) => a.first.boundingBox.top.compareTo(b.first.boundingBox.top));

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map((e) => e.text.trim()).join('   '));
    }

    return buffer.toString();
  }

  /// Extracts text from PDF document on-device using Syncfusion PDF TextExtractor.
  Future<String> _extractTextFromPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      return '';
    }
  }

  /// Core clinical NLP parser analyzing raw extracted report text.
  ParsedReportResult analyzeText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ParsedReportResult(
        rawText: '',
        detectedReportType: 'Others',
        summary: 'No readable text could be extracted from this document.',
        testResults: {},
      );
    }

    debugPrint('=== ON-DEVICE OCR RAW TEXT ===\n$rawText\n==================================');

    final lowerText = rawText.toLowerCase();

    // 1. Detect Specific Report Type
    final reportType = _detectReportType(lowerText);

    // 2. Extract structured test results
    final testResults = _extractTestParameters(rawText, lowerText);

    // 3. Extract patient name and date if present
    final patientName = _extractPatientName(rawText);
    final date = _extractDate(rawText);

    // 4. Extract key observations / comments
    final observations = _extractObservations(rawText);

    // 5. Generate concise, clinical summary with normal/abnormal interpretation
    final summary = _generateSummary(
      reportType: reportType,
      testResults: testResults,
      patientName: patientName,
      date: date,
      observations: observations,
      rawText: rawText,
    );

    return ParsedReportResult(
      rawText: rawText,
      detectedReportType: reportType,
      summary: summary,
      testResults: testResults,
      patientName: patientName,
      date: date,
      keyObservations: observations,
    );
  }

  String _detectReportType(String text) {
    // 1. Hemoglobin specific report
    if (text.contains('hemoglobin') || text.contains('haemoglobin') || text.contains(' hb ') || text.contains('; hb')) {
      if (!text.contains('urine') && !text.contains('culture')) {
        return 'Hemoglobin (Hb) Report';
      }
    }

    // 2. Urine Test
    if (text.contains('urine routine') || text.contains('urinalysis') || text.contains('pus cells') || text.contains('epithelial cells') || (text.contains('urine') && text.contains('protein'))) {
      return 'Urine Test';
    }

    // 3. Complete Blood Count
    if (text.contains('complete blood count') || text.contains('cbc') || (text.contains('platelet') && text.contains('wbc'))) {
      return 'Complete Blood Count (CBC)';
    }

    // 4. Thyroid Profile
    if (text.contains('thyroid') || text.contains('tsh') || text.contains('t3') || text.contains('t4')) {
      return 'Thyroid Report';
    }

    // 5. Blood Glucose / Sugar
    if (text.contains('fasting blood sugar') || text.contains('glucose') || text.contains('hba1c') || text.contains('ppbs') || text.contains('rbs')) {
      return 'Blood Glucose / Sugar';
    }

    // 6. Liver Function Test
    if (text.contains('liver function') || text.contains('lft') || (text.contains('bilirubin') && text.contains('sgpt'))) {
      return 'Liver Function Test (LFT)';
    }

    // 7. Kidney Function Test
    if (text.contains('kidney function') || text.contains('kft') || text.contains('creatinine') || text.contains('blood urea')) {
      return 'Kidney Function (KFT)';
    }

    // 8. Lipid Profile
    if (text.contains('lipid profile') || text.contains('cholesterol') || text.contains('triglycerides')) {
      return 'Lipid Profile';
    }

    // 9. Beta HCG
    if (text.contains('beta hcg') || text.contains('b-hcg') || text.contains('beta-hcg') || text.contains('human chorionic')) {
      return 'Beta HCG Report';
    }

    // 10. Ultrasound
    if (text.contains('ultrasound') || text.contains('sonography') || text.contains('usg') || text.contains('fetal') || text.contains('gestational')) {
      return 'Ultrasound Scan';
    }

    // 11. ECG
    if (text.contains('ecg') || text.contains('ekg') || text.contains('electrocardiogram') || text.contains('sinus rhythm')) {
      return 'ECG';
    }

    // 12. X-Ray
    if (text.contains('x-ray') || text.contains('xray') || text.contains('radiograph') || text.contains('chest pa')) {
      return 'x-ray';
    }

    // 13. CT Scan
    if (text.contains('ct scan') || text.contains('computed tomography') || text.contains('hrct')) {
      return 'CT Scan';
    }

    // 14. Mammogram
    if (text.contains('mammogram') || text.contains('mammography') || text.contains('birads')) {
      return 'Mammogram';
    }

    // 15. MRI
    if (text.contains('mri') || text.contains('magnetic resonance')) {
      return 'MRI';
    }

    // 16. Blood Test general
    if (text.contains('blood') || text.contains('serum') || text.contains('plasma') || text.contains('hematology')) {
      return 'Blood Test';
    }

    return 'Lab Test';
  }

  Map<String, String> _extractTestParameters(String rawText, String lowerText) {
    final Map<String, String> results = {};

    // ─── 1. HEMOGLOBIN (Hb) EXTRACTION ───
    // A. Direct spatial row match: "HEMOGLOBIN; Hb   7.90   g/dL   13.00 - 17.00"
    final hbSpatialRegex = RegExp(
      r'(?:hemoglobin|haemoglobin|hb)\b[^\d\n]*?(\d+(?:\.\d+)?)\s*([a-zA-Z\/]+)?(?:[^\d\n]*?(\d+(?:\.\d+)?\s*[\-\–]\s*\d+(?:\.\d+)?))?',
      caseSensitive: false,
    );
    final hbSpatialMatch = hbSpatialRegex.firstMatch(rawText);
    if (hbSpatialMatch != null && hbSpatialMatch.group(1) != null) {
      final val = hbSpatialMatch.group(1)!;
      final unit = hbSpatialMatch.group(2) ?? 'g/dL';
      final ref = hbSpatialMatch.group(3);
      results['Hemoglobin'] = ref != null ? '$val $unit (Ref: $ref)' : '$val $unit';
    }

    // B. Column-based extraction (where "HEMOGLOBIN" is in Test Name and "7.90" is under Results)
    if (!results.containsKey('Hemoglobin') && (lowerText.contains('hemoglobin') || lowerText.contains('; hb'))) {
      final resultsMatch = RegExp(r'\bresults?\b[^\d]*?(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(rawText);
      final unitsMatch = RegExp(r'\bunits?\b[^\n]*\n\s*([a-zA-Z\/]+)', caseSensitive: false).firstMatch(rawText);
      final refMatch = RegExp(r'(?:ref|interval)[^\d]*?(\d+(?:\.\d+)?\s*[\-\–]\s*\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(rawText);

      if (resultsMatch != null) {
        final val = resultsMatch.group(1)!;
        final unit = unitsMatch?.group(1) ?? 'g/dL';
        final ref = refMatch?.group(1);
        results['Hemoglobin'] = ref != null ? '$val $unit (Ref: $ref)' : '$val $unit';
      }
    }

    // ─── 2. PLATELET COUNT ───
    final pltRegex = RegExp(r'\b(?:platelets?|plt|platelet count)\b[^\d\n]*?(\d+[\d,]*(?:\.\d+)?)\s*([a-zA-Z\/\^0-9]+)?', caseSensitive: false);
    final pltMatch = pltRegex.firstMatch(rawText);
    if (pltMatch != null && pltMatch.group(1) != null) {
      results['Platelets'] = '${pltMatch.group(1)} ${pltMatch.group(2) ?? '/cumm'}';
    }

    // ─── 3. RBC COUNT ───
    final rbcRegex = RegExp(r'\b(?:rbc|red blood cells?)\b[^\d\n]*?(\d+(?:\.\d+)?)\s*([a-zA-Z\/\^0-9]+)?', caseSensitive: false);
    final rbcMatch = rbcRegex.firstMatch(rawText);
    if (rbcMatch != null && rbcMatch.group(1) != null) {
      results['RBC Count'] = '${rbcMatch.group(1)} ${rbcMatch.group(2) ?? 'mil/uL'}';
    }

    // ─── 4. WBC COUNT ───
    final wbcRegex = RegExp(r'\b(?:wbc|white blood cells?|total leukocyte count|tlc)\b[^\d\n]*?(\d+[\d,]*(?:\.\d+)?)\s*([a-zA-Z\/\^0-9]+)?', caseSensitive: false);
    final wbcMatch = wbcRegex.firstMatch(rawText);
    if (wbcMatch != null && wbcMatch.group(1) != null) {
      results['WBC Count'] = '${wbcMatch.group(1)} ${wbcMatch.group(2) ?? '/cumm'}';
    }

    // ─── 5. BLOOD SUGAR / GLUCOSE ───
    final glucRegex = RegExp(r'\b(?:fasting blood sugar|blood glucose|glucose|fbs|ppbs|rbs)\b[^\d\n]*?(\d+(?:\.\d+)?)\s*(mg\/dl)?', caseSensitive: false);
    final glucMatch = glucRegex.firstMatch(rawText);
    if (glucMatch != null && glucMatch.group(1) != null) {
      results['Blood Glucose'] = '${glucMatch.group(1)} mg/dL';
    }

    // ─── 6. HbA1c ───
    final hba1cRegex = RegExp(r'\b(?:hba1c|glycated hemoglobin)\b[^\d\n]*?(\d+(?:\.\d+)?)\s*(%)?', caseSensitive: false);
    final hba1cMatch = hba1cRegex.firstMatch(rawText);
    if (hba1cMatch != null && hba1cMatch.group(1) != null) {
      results['HbA1c'] = '${hba1cMatch.group(1)}%';
    }

    // ─── 7. THYROID TSH ───
    final tshRegex = RegExp(r'\b(?:tsh|thyroid stimulating hormone)\b[^\d\n]*?(\d+(?:\.\d+)?)\s*([a-zA-Z\/]+)?', caseSensitive: false);
    final tshMatch = tshRegex.firstMatch(rawText);
    if (tshMatch != null && tshMatch.group(1) != null) {
      results['TSH'] = '${tshMatch.group(1)} ${tshMatch.group(2) ?? 'uIU/mL'}';
    }

    // ─── 8. BETA HCG ───
    final hcgRegex = RegExp(r'\b(?:beta[\s\-]hcg|b[\s\-]hcg|hcg)\b[^\d\n]*?(\d+[\d,]*(?:\.\d+)?)\s*([a-zA-Z\/]+)?', caseSensitive: false);
    final hcgMatch = hcgRegex.firstMatch(rawText);
    if (hcgMatch != null && hcgMatch.group(1) != null) {
      results['Beta HCG'] = '${hcgMatch.group(1)} ${hcgMatch.group(2) ?? 'mIU/mL'}';
    }

    // ─── 9. URINE PARAMETERS ───
    if (lowerText.contains('urine') || lowerText.contains('pus cells')) {
      final pusMatch = RegExp(r'pus\s*cells?\b[^\d\n]*?(\d+\s*[\-\–]\s*\d+|\d+)', caseSensitive: false).firstMatch(rawText);
      if (pusMatch != null) results['Pus Cells'] = '${pusMatch.group(1)} /HPF';

      final epiMatch = RegExp(r'epithelial\s*cells?\b[^\d\n]*?(\d+\s*[\-\–]\s*\d+|\d+)', caseSensitive: false).firstMatch(rawText);
      if (epiMatch != null) results['Epithelial Cells'] = '${epiMatch.group(1)} /HPF';

      final protMatch = RegExp(r'(?:protein|albumin)\b[^\w\n]*?(nil|negative|present|\+|\+\+)', caseSensitive: false).firstMatch(rawText);
      if (protMatch != null) results['Urine Protein'] = protMatch.group(1)!.toUpperCase();

      final sugMatch = RegExp(r'sugar\b[^\w\n]*?(nil|negative|present|\+|\+\+)', caseSensitive: false).firstMatch(rawText);
      if (sugMatch != null) results['Urine Sugar'] = sugMatch.group(1)!.toUpperCase();
    }

    // ─── 10. BLOOD PRESSURE & PULSE ───
    final bpMatch = RegExp(r'\b(?:bp|blood pressure)\b[^\d\n]*?(\d{2,3}\s*[\/\-]\s*\d{2,3})\s*(?:mmhg)?', caseSensitive: false).firstMatch(rawText);
    if (bpMatch != null) results['Blood Pressure'] = '${bpMatch.group(1)} mmHg';

    final hrMatch = RegExp(r'\b(?:heart rate|pulse rate|pulse|fhr)\b[^\d\n]*?(\d{2,3})\s*(?:bpm)?', caseSensitive: false).firstMatch(rawText);
    if (hrMatch != null) results['Heart Rate'] = '${hrMatch.group(1)} bpm';

    // ─── 11. GESTATIONAL AGE ───
    final gaMatch = RegExp(r'\b(?:gestational age|ga)\b[^\d\n]*?(\d+\s*(?:weeks?|w)?(?:\s*(?:and|\+)?\s*\d+\s*(?:days?|d)?)?)', caseSensitive: false).firstMatch(rawText);
    if (gaMatch != null) results['Gestational Age'] = gaMatch.group(1)!.trim();

    return results;
  }

  String? _extractPatientName(String text) {
    // E.g. "Mr. PSSRIVASTAVA" or "Patient: Jane Doe"
    final salutationMatch = RegExp(r'\b(Mr\.|Mrs\.|Ms\.|Dr\.)\s*([A-Za-z\s]{3,30})', caseSensitive: false).firstMatch(text);
    if (salutationMatch != null) {
      final title = salutationMatch.group(1) ?? '';
      final name = salutationMatch.group(2)?.trim() ?? '';
      if (name.isNotEmpty && !name.toLowerCase().contains('patklabs') && !name.toLowerCase().contains('pathlabs') && !name.toLowerCase().contains('dimple')) {
        return '$title $name';
      }
    }

    final match = RegExp(r'(?:patient name|name|patient)\s*[:\-]?\s*([A-Za-z\.\s]{3,30})', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final name = match.group(1)?.trim();
      if (name != null && name.length > 2 && !name.toLowerCase().contains('report') && !name.toLowerCase().contains('test')) {
        return name;
      }
    }
    return null;
  }

  String? _extractDate(String text) {
    final match = RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b').firstMatch(text);
    return match?.group(1);
  }

  List<String> _extractObservations(String text) {
    final List<String> observations = [];
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].trim();
      if (l.toLowerCase().startsWith('result rechecked') ||
          l.toLowerCase().startsWith('please correlate') ||
          l.toLowerCase().startsWith('comments:') ||
          l.toLowerCase().startsWith('impression:') ||
          l.toLowerCase().startsWith('remarks:')) {
        observations.add(l);
      }
    }
    return observations;
  }

  String _generateSummary({
    required String reportType,
    required Map<String, String> testResults,
    String? patientName,
    String? date,
    required List<String> observations,
    required String rawText,
  }) {
    final buffer = StringBuffer();

    // 1. Report title and primary value
    buffer.write('$reportType: ');

    if (testResults.isNotEmpty) {
      // Format as "Hemoglobin = 7.90 g/dL (Ref: 13.00-17.00)"
      final formattedList = testResults.entries.map((e) => '${e.key} = ${e.value}').join(', ');
      buffer.write('$formattedList. ');

      // Check clinical severity for Hemoglobin
      if (testResults.containsKey('Hemoglobin')) {
        final hbStr = testResults['Hemoglobin']!;
        final valMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(hbStr);
        if (valMatch != null) {
          final val = double.tryParse(valMatch.group(1)!);
          if (val != null) {
            if (val < 11.0) {
              buffer.write('Result indicates Low Hemoglobin (Anemia). ');
            } else if (val >= 11.0 && val <= 16.5) {
              buffer.write('Hemoglobin is within normal physiological limits. ');
            } else {
              buffer.write('Hemoglobin is elevated above reference limits. ');
            }
          }
        }
      }
    } else {
      // Clean fallback text
      final cleanLines = rawText
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !e.startsWith('---') && e.length > 5 && !e.toLowerCase().contains('important instructions'))
          .take(2)
          .join('; ');
      if (cleanLines.isNotEmpty) {
        buffer.write('${cleanLines.length > 120 ? cleanLines.substring(0, 120) : cleanLines}. ');
      }
    }

    // Add observation (e.g. "Result Rechecked. Please correlate clinically.")
    if (observations.isNotEmpty) {
      buffer.write('${observations.take(2).join('. ')}. ');
    }

    if (patientName != null) {
      buffer.write('Patient: $patientName. ');
    }

    if (date != null) {
      buffer.write('Report Date: $date.');
    }

    return buffer.toString().trim();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
