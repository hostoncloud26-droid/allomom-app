class TimingWithMedicationResponse {
  final String id;
  final String medicineId;
  final String medicineName;
  final String? type;
  final String? dosage;
  final String? instructions;
  final DateTime dateTime;
  final String status;
  final String? doctorName;
  final String? prescriptionId;
  final String? mealInstruction;
  final bool? isTaken;

  TimingWithMedicationResponse({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    this.type,
    this.dosage,
    this.instructions,
    required this.dateTime,
    this.status = 'pending',
    this.doctorName,
    this.prescriptionId,
    this.mealInstruction,
    this.isTaken,
  });

  bool get taken => status.toLowerCase() == 'taken' || isTaken == true;

  factory TimingWithMedicationResponse.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['date_time'] != null) {
        parsedDate = DateTime.parse(json['date_time'].toString());
      } else if (json['dateTime'] != null) {
        parsedDate = DateTime.parse(json['dateTime'].toString());
      } else if (json['time'] != null) {
        parsedDate = DateTime.parse(json['time'].toString());
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final med = json['medicine'] is Map ? json['medicine'] as Map<String, dynamic> : <String, dynamic>{};

    return TimingWithMedicationResponse(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      medicineId: json['medicine_id']?.toString() ?? med['id']?.toString() ?? '',
      medicineName: json['medicine_name']?.toString() ??
          med['name']?.toString() ??
          json['name']?.toString() ??
          'Medication',
      type: json['type']?.toString() ?? med['type']?.toString() ?? 'tablet',
      dosage: json['dosage']?.toString() ?? med['dosage']?.toString() ?? '1 dose',
      instructions: json['instructions']?.toString() ?? med['instructions']?.toString(),
      dateTime: parsedDate,
      status: json['status']?.toString() ?? (json['is_taken'] == true ? 'taken' : 'pending'),
      doctorName: json['doctor_name']?.toString() ?? json['doctor']?.toString(),
      prescriptionId: json['prescription_id']?.toString(),
      mealInstruction: json['meal_instruction']?.toString() ??
          json['meal_timing']?.toString() ??
          med['meal_instruction']?.toString(),
      isTaken: json['is_taken'] as bool? ?? (json['status']?.toString().toLowerCase() == 'taken'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'type': type,
      'dosage': dosage,
      'instructions': instructions,
      'date_time': dateTime.toIso8601String(),
      'status': status,
      'doctor_name': doctorName,
      'prescription_id': prescriptionId,
      'meal_instruction': mealInstruction,
      'is_taken': taken,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String? doctorName;
  final String? hospitalName;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<PrescriptionMedicineModel> medicines;

  PrescriptionModel({
    required this.id,
    this.doctorName,
    this.hospitalName,
    this.description,
    this.imageUrl,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.medicines = const [],
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    DateTime created;
    try {
      created = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      created = DateTime.now();
    }

    DateTime? start;
    if (json['start_date'] != null || json['medicine_start_date'] != null) {
      try {
        start = DateTime.parse((json['start_date'] ?? json['medicine_start_date']).toString());
      } catch (_) {}
    }

    DateTime? end;
    if (json['end_date'] != null) {
      try {
        end = DateTime.parse(json['end_date'].toString());
      } catch (_) {}
    }

    final medList = <PrescriptionMedicineModel>[];
    if (json['medicines'] is List) {
      for (final m in json['medicines'] as List) {
        if (m is Map<String, dynamic>) {
          medList.add(PrescriptionMedicineModel.fromJson(m));
        }
      }
    }

    return PrescriptionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? json['doctor']?.toString(),
      hospitalName: json['hospital_name']?.toString() ?? json['hospital']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      createdAt: created,
      startDate: start,
      endDate: end,
      medicines: medList,
    );
  }
}

class PrescriptionMedicineModel {
  final String id;
  final String name;
  final String? type;
  final String? dosage;
  final int days;
  final String? mealInstruction;
  final List<String> times;

  PrescriptionMedicineModel({
    required this.id,
    required this.name,
    this.type = 'tablet',
    this.dosage,
    this.days = 5,
    this.mealInstruction,
    this.times = const [],
  });

  factory PrescriptionMedicineModel.fromJson(Map<String, dynamic> json) {
    final timesList = <String>[];
    if (json['times'] is List) {
      for (final t in json['times'] as List) {
        timesList.add(t.toString());
      }
    } else if (json['timings'] is List) {
      for (final t in json['timings'] as List) {
        if (t is Map && t['time'] != null) {
          timesList.add(t['time'].toString());
        }
      }
    }

    return PrescriptionMedicineModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Medicine',
      type: json['type']?.toString() ?? 'tablet',
      dosage: json['dosage']?.toString(),
      days: (json['days'] as num?)?.toInt() ?? 5,
      mealInstruction: json['meal_instruction']?.toString() ?? json['meal_timing']?.toString(),
      times: timesList,
    );
  }
}
