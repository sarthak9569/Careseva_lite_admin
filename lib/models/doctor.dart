class Doctor {
  final String doctorId;
  final String clinicId;
  final String name;
  final String phone;
  final String speciality;
  final String qualification;
  final String registrationNumber;
  final int avgConsultationMinutes;
  bool isAvailable;

  Doctor({
    required this.doctorId,
    required this.clinicId,
    required this.name,
    required this.phone,
    required this.speciality,
    required this.qualification,
    required this.registrationNumber,
    this.avgConsultationMinutes = 10,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'clinicId': clinicId,
      'name': name,
      'phone': phone,
      'speciality': speciality,
      'qualification': qualification,
      'registrationNumber': registrationNumber,
      'avgConsultationMinutes': avgConsultationMinutes,
      'isAvailable': isAvailable,
    };
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctorId'],
      clinicId: json['clinicId'],
      name: json['name'],
      phone: json['phone'],
      speciality: json['speciality'],
      qualification: json['qualification'],
      registrationNumber: json['registrationNumber'] ?? '',
      avgConsultationMinutes: json['avgConsultationMinutes'] ?? 10,
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
