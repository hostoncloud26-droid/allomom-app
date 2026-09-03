import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' show PdfDocument, PdfTextExtractor;

class ParsedPrescriptionMedicine {
  final String name;
  final String dosage;
  final String mealInstruction;
  final int durationDays;
  final List<TimeOfDay> times;
  final String frequencyLabel;

  const ParsedPrescriptionMedicine({
    required this.name,
    this.dosage = '1 Tablet',
    this.mealInstruction = 'After Food',
    this.durationDays = 7,
    this.times = const [TimeOfDay(hour: 8, minute: 0)],
    this.frequencyLabel = '1 time daily',
  });
}

class ParsedPrescriptionResult {
  final String rawText;
  final List<ParsedPrescriptionMedicine> medicines;
  final String? doctorName;
  final String? hospitalName;
  final String? date;
  final String summary;

  const ParsedPrescriptionResult({
    required this.rawText,
    required this.medicines,
    this.doctorName,
    this.hospitalName,
    this.date,
    required this.summary,
  });
}

class OnDevicePrescriptionParser {
  OnDevicePrescriptionParser._();
  static final OnDevicePrescriptionParser instance = OnDevicePrescriptionParser._();

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Analyzes a prescription image or PDF on-device.
  Future<ParsedPrescriptionResult> parsePrescription(File file) async {
    final path = file.path.toLowerCase();
    String rawText = '';

    try {
      if (path.endsWith('.pdf')) {
        rawText = await _extractTextFromPdf(file);
      } else {
        rawText = await _extractTextFromImage(file);
      }
    } catch (e) {
      debugPrint('OnDevicePrescriptionParser error: $e');
    }

    return analyzeText(rawText);
  }

  /// Extracts text from image using Google ML Kit with spatial row reconstruction.
  Future<String> _extractTextFromImage(File file) async {
    final inputImage = InputImage.fromFilePath(file.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final spatialText = _reconstructSpatialText(recognizedText);
    return '$spatialText\n\n--- RAW BLOCKS ---\n${recognizedText.text}';
  }

  /// Clusters lines by vertical Y coordinates so horizontal prescription rows are kept together.
  String _reconstructSpatialText(RecognizedText recognizedText) {
    final List<TextLine> lines = [];
    for (final block in recognizedText.blocks) {
      lines.addAll(block.lines);
    }
    if (lines.isEmpty) return recognizedText.text;

    lines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final List<List<TextLine>> rows = [];
    for (final line in lines) {
      final lineY = line.boundingBox.top + (line.boundingBox.height / 2);
      bool placed = false;
      for (final row in rows) {
        final rowY = row.first.boundingBox.top + (row.first.boundingBox.height / 2);
        final avgHeight = (row.first.boundingBox.height + line.boundingBox.height) / 2;
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

    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    }
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

  /// Clinical NLP parser for prescriptions.
  ParsedPrescriptionResult analyzeText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ParsedPrescriptionResult(
        rawText: '',
        medicines: [],
        summary: 'No readable text could be extracted from this prescription.',
      );
    }

    debugPrint('=== ON-DEVICE PRESCRIPTION RAW TEXT ===\n$rawText\n======================================');

    final medicines = _extractMedicines(rawText);
    final doctorName = _extractDoctorName(rawText);
    final hospitalName = _extractHospitalName(rawText);
    final date = _extractDate(rawText);

    final summary = _generateSummary(
      medicines: medicines,
      doctorName: doctorName,
      hospitalName: hospitalName,
      date: date,
      rawText: rawText,
    );

    return ParsedPrescriptionResult(
      rawText: rawText,
      medicines: medicines,
      doctorName: doctorName,
      hospitalName: hospitalName,
      date: date,
      summary: summary,
    );
  }

  List<ParsedPrescriptionMedicine> _extractMedicines(String rawText) {
    final List<ParsedPrescriptionMedicine> medicines = [];
    final lines = rawText.split('\n');

    final drugPrefixRegex = RegExp(
      r'^(?:(?:\d+[\.\)]\s*)|\-\s*|\*\s*)?(?:tab(?:let)?\.?|cap(?:sule)?\.?|syr(?:up)?\.?|inj(?:ection)?\.?|oint(?:ment)?\.?|drops?\.?|susp(?:ension)?\.?)\s+',
      caseSensitive: false,
    );

    final strengthPattern = RegExp(r'\b\d+(?:\.\d+)?\s*(?:mg|mcg|gm|g|ml|iu|%)\b', caseSensitive: false);
    final freqPattern1 = RegExp(r'\b([012])\s*[\-\–\/]\s*([012])\s*[\-\–\/]\s*([012])\b'); // 1-0-1, 1-1-1
    final freqPattern2 = RegExp(r'\b(od|bd|bid|tds|tid|qid|qds|hs|sos|prn|once daily|twice daily|thrice daily)\b', caseSensitive: false);
    final mealPattern = RegExp(r'\b(after (?:food|meals?|breakfast|lunch|dinner)|before (?:food|meals?|breakfast)|empty stomach|with (?:food|milk)|at bedtime|pc|ac)\b', caseSensitive: false);
    final durationPattern = RegExp(r'(?:x\s*|for\s*)?(\d+)\s*(?:days?|d|weeks?|wks?|w|months?|m)\b', caseSensitive: false);

    // Common prenatal/maternal/general medicines to detect even without "Tab." prefix
    final knownMeds = [
      'dolo', 'paracetamol', 'folvite', 'folic acid', 'autrin', 'shelcal', 'calcium',
      'iron', 'ferrous', 'zinc', 'pantocid', 'pantoprazole', 'pan', 'omee', 'omeprazole',
      'amoxicillin', 'augmentin', 'azithromycin', 'cefixime', 'taxim', 'metformin',
      'thyronorm', 'eltroxin', 'cetirizine', 'montair', 'duphaston', 'susten',
      'progesterone', 'gestofit', 'ecosprin', 'aspirin', 'labetalol', 'glycomet',
      'becosules', 'supradyn', 'livogen', 'orofer', 'feff', 'ciprofloxacin', 'norflox',
    ];

    final Set<String> addedNames = {};

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 3 || trimmed.startsWith('---')) continue;

      final lower = trimmed.toLowerCase();
      final hasPrefix = drugPrefixRegex.hasMatch(trimmed);
      final hasStrength = strengthPattern.hasMatch(trimmed);
      final hasFreq = freqPattern1.hasMatch(trimmed) || freqPattern2.hasMatch(trimmed);
      final isKnownMed = knownMeds.any((m) => lower.contains(m));

      if (hasPrefix || (isKnownMed && (hasStrength || hasFreq || lower.contains('tab') || lower.contains('cap'))) || (hasStrength && hasFreq)) {
        // Clean line prefix
        String cleanLine = trimmed.replaceFirst(RegExp(r'^(?:rx:?\s*|\d+[\.\)]\s*|\-\s*|\*\s*)', caseSensitive: false), '').trim();

        // Extract duration
        int duration = 7;
        final durMatch = durationPattern.firstMatch(cleanLine);
        if (durMatch != null) {
          final num = int.tryParse(durMatch.group(1) ?? '7') ?? 7;
          final durStr = durMatch.group(0)!.toLowerCase();
          if (durStr.contains('week') || durStr.contains('wk') || durStr.endsWith('w')) {
            duration = num * 7;
          } else if (durStr.contains('month') || durStr.endsWith('m')) {
            duration = num * 30;
          } else {
            duration = num;
          }
        }

        // Extract meal instruction
        String meal = 'After Food';
        final mealMatch = mealPattern.firstMatch(cleanLine);
        if (mealMatch != null) {
          final m = mealMatch.group(0)!.toLowerCase();
          if (m.contains('before') || m == 'ac' || m.contains('empty')) {
            meal = 'Before Food';
          } else if (m.contains('bedtime') || m == 'hs') {
            meal = 'At Bedtime';
          } else {
            meal = 'After Food';
          }
        }

        // Extract frequency & timings
        List<TimeOfDay> times = [const TimeOfDay(hour: 8, minute: 0)];
        String freqLabel = 'Once daily';

        final f1 = freqPattern1.firstMatch(cleanLine);
        if (f1 != null) {
          final m = int.tryParse(f1.group(1)!) ?? 0;
          final a = int.tryParse(f1.group(2)!) ?? 0;
          final n = int.tryParse(f1.group(3)!) ?? 0;
          times = [];
          if (m > 0) times.add(const TimeOfDay(hour: 8, minute: 0));
          if (a > 0) times.add(const TimeOfDay(hour: 14, minute: 0));
          if (n > 0) times.add(const TimeOfDay(hour: 20, minute: 0));
          if (times.isEmpty) times.add(const TimeOfDay(hour: 8, minute: 0));
          freqLabel = '${f1.group(0)} (${times.length} ${times.length == 1 ? 'dose' : 'doses'}/day)';
        } else {
          final f2 = freqPattern2.firstMatch(cleanLine);
          if (f2 != null) {
            final code = f2.group(0)!.toLowerCase();
            if (code == 'bd' || code == 'bid' || code.contains('twice')) {
              times = [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 20, minute: 0)];
              freqLabel = 'Twice daily (BD)';
            } else if (code == 'tds' || code == 'tid' || code.contains('thrice')) {
              times = [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 14, minute: 0), const TimeOfDay(hour: 20, minute: 0)];
              freqLabel = '3 times daily (TDS)';
            } else if (code == 'hs' || code.contains('bedtime')) {
              times = [const TimeOfDay(hour: 21, minute: 0)];
              freqLabel = 'At Bedtime (HS)';
            } else {
              times = [const TimeOfDay(hour: 8, minute: 0)];
              freqLabel = 'Once daily (OD)';
            }
          }
        }

        // Extract dosage
        String dosage = '1 Tablet';
        final strMatch = strengthPattern.firstMatch(cleanLine);
        if (strMatch != null) {
          dosage = strMatch.group(0)!;
        }

        // Extract clean medicine name (strip instructions, timings, durations)
        String medName = cleanLine;
        final cutoffs = [freqPattern1, freqPattern2, mealPattern, durationPattern];
        int earliestCutoff = medName.length;
        for (final p in cutoffs) {
          final match = p.firstMatch(medName);
          if (match != null && match.start < earliestCutoff && match.start > 3) {
            earliestCutoff = match.start;
          }
        }
        medName = medName.substring(0, earliestCutoff).replaceAll(RegExp(r'[\-\–,;:]+$'), '').trim();

        // Avoid adding duplicates or non-medicines
        final normalized = medName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (medName.length >= 3 && !addedNames.contains(normalized) && !_isNoiseLine(medName)) {
          addedNames.add(normalized);
          medicines.add(ParsedPrescriptionMedicine(
            name: medName,
            dosage: dosage,
            mealInstruction: meal,
            durationDays: duration,
            times: times,
            frequencyLabel: freqLabel,
          ));
        }
      }
    }

    return medicines;
  }

  bool _isNoiseLine(String s) {
    final lower = s.toLowerCase();
    return lower.contains('doctor') ||
        lower.contains('hospital') ||
        lower.contains('clinic') ||
        lower.contains('patient') ||
        lower.contains('phone') ||
        lower.contains('signature') ||
        lower.contains('date');
  }

  String? _extractDoctorName(String text) {
    final match = RegExp(r'\b(Dr\.[^\n,]+)', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final doc = match.group(1)?.trim();
      if (doc != null && doc.length > 4 && doc.length < 40) return doc;
    }
    return null;
  }

  String? _extractHospitalName(String text) {
    final match = RegExp(r'([A-Za-z\s]+(?:Hospital|Clinic|Healthcare|Maternity|Medical Centre|Nursing Home))\b', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final hosp = match.group(1)?.trim();
      if (hosp != null && hosp.length > 5 && hosp.length < 50) return hosp;
    }
    return null;
  }

  String? _extractDate(String text) {
    final match = RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b').firstMatch(text);
    return match?.group(1);
  }

  String _generateSummary({
    required List<ParsedPrescriptionMedicine> medicines,
    String? doctorName,
    String? hospitalName,
    String? date,
    required String rawText,
  }) {
    final buffer = StringBuffer();

    if (doctorName != null) {
      buffer.write('Prescribed by $doctorName');
      if (hospitalName != null) buffer.write(' at $hospitalName');
      buffer.write('. ');
    }

    if (medicines.isNotEmpty) {
      buffer.write('Medications (${medicines.length}): ');
      final medSummaries = medicines.map((m) => '${m.name} (${m.frequencyLabel}, ${m.mealInstruction} x ${m.durationDays}d)').join(', ');
      buffer.write('$medSummaries. ');
    } else {
      buffer.write('Prescription recorded. Attached images/documents processed on-device. ');
    }

    if (date != null) {
      buffer.write('Dated: $date.');
    }

    return buffer.toString().trim();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
