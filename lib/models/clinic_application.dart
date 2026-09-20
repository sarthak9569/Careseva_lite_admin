import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { pending, approved, rejected }

class ClinicApplication {
  final String id;
  final String clinicName;
  final String clinicPhone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String speciality;
  final String operatingHours;

  // Primary Doctor Info
  final String doctorName;
  final String doctorPhone;
  final String doctorSpeciality;
  final String doctorQualification;
  final String doctorRegNum;
  final int avgConsultationMinutes;

  ApplicationStatus status;
  final DateTime submittedAt;
  DateTime? reviewedAt;
  String? assignedClinicId;
  String? rejectionReason;

  ClinicApplication({
    required this.id,
    required this.clinicName,
    required this.clinicPhone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.speciality,
    required this.operatingHours,
    required this.doctorName,
    required this.doctorPhone,
    required this.doctorSpeciality,
    required this.doctorQualification,
    required this.doctorRegNum,
    this.avgConsultationMinutes = 10,
    this.status = ApplicationStatus.pending,
    required this.submittedAt,
    this.reviewedAt,
    this.assignedClinicId,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinicName': clinicName,
      'clinicPhone': clinicPhone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'speciality': speciality,
      'operatingHours': operatingHours,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'doctorSpeciality': doctorSpeciality,
      'doctorQualification': doctorQualification,
      'doctorRegNum': doctorRegNum,
      'avgConsultationMinutes': avgConsultationMinutes,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'assignedClinicId': assignedClinicId,
      'rejectionReason': rejectionReason,
    };
  }

  factory ClinicApplication.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is Timestamp) return val.toDate();
      return DateTime.now();
    }

    return ClinicApplication(
      id: json['id']?.toString() ?? '',
      clinicName: json['clinicName']?.toString() ?? 'Unnamed Clinic',
      clinicPhone: json['clinicPhone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speciality: json['speciality']?.toString() ?? '',
      operatingHours: json['operatingHours']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      doctorPhone: json['doctorPhone']?.toString() ?? '',
      doctorSpeciality: json['doctorSpeciality']?.toString() ?? '',
      doctorQualification: json['doctorQualification']?.toString() ?? '',
      doctorRegNum: json['doctorRegNum']?.toString() ?? '',
      avgConsultationMinutes: (json['avgConsultationMinutes'] as num?)?.toInt() ?? 10,
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == json['status']?.toString().toLowerCase(),
        orElse: () => ApplicationStatus.pending,
      ),
      submittedAt: parseDate(json['submittedAt']),
      reviewedAt: json['reviewedAt'] != null ? parseDate(json['reviewedAt']) : null,
      assignedClinicId: json['assignedClinicId']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}
