import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clinic.dart';
import '../models/clinic_application.dart';
import '../models/doctor.dart';
import 'api_service.dart';

class AdminStore extends ChangeNotifier {
  static const String _kApplicationsKey = 'cs_clinic_applications';
  static const String _kClinicsKey = 'cs_approved_clinics';
  static const String _kDoctorsKey = 'cs_doctors';
  static const String _kAuditLogsKey = 'cs_audit_logs';

  List<ClinicApplication> _applications = [];
  List<Clinic> _clinics = [];
  List<Doctor> _doctors = [];
  List<Map<String, dynamic>> _auditLogs = [];

  bool _isLoggedIn = false;
  String _adminUser = 'Admin User';
  Timer? _pollingTimer;

  List<ClinicApplication> get applications => _applications;
  List<Clinic> get clinics => _clinics;
  List<Doctor> get doctors => _doctors;
  List<Map<String, dynamic>> get auditLogs => _auditLogs;
  bool get isLoggedIn => _isLoggedIn;
  String get adminUser => _adminUser;

  List<ClinicApplication> get pendingApplications =>
      _applications.where((a) => a.status == ApplicationStatus.pending).toList();

  List<ClinicApplication> get approvedApplications =>
      _applications.where((a) => a.status == ApplicationStatus.approved).toList();

  List<ClinicApplication> get rejectedApplications =>
      _applications.where((a) => a.status == ApplicationStatus.rejected).toList();

  Future<void> refreshData() async {
    await _fetchRemoteData();
  }

  AdminStore() {
    _initAndLoadData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAndLoadData() async {
    await _loadLocalData();
    await _fetchRemoteData();

    // Setup periodic polling every 3 seconds for real-time application updates from Railway MongoDB
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchRemoteData();
    });
  }

  Future<void> _fetchRemoteData() async {
    try {
      final apiApps = await ApiService.getApplications();
      if (apiApps.isNotEmpty) {
        for (var rawApp in apiApps) {
          final parsed = ClinicApplication.fromJson(Map<String, dynamic>.from(rawApp));
          final idx = _applications.indexWhere((a) => a.id == parsed.id);
          if (idx != -1) {
            _applications[idx] = parsed;
          } else {
            _applications.add(parsed);
          }
        }
        _applications.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        await _saveData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AdminStore] Railway Backend Fetch Error: $e');
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final appsRaw = prefs.getString(_kApplicationsKey);
    if (appsRaw != null) {
      final List decoded = jsonDecode(appsRaw);
      _applications = decoded.map((e) => ClinicApplication.fromJson(e)).toList();
    } else {
      _seedDemoData();
    }

    final clinicsRaw = prefs.getString(_kClinicsKey);
    if (clinicsRaw != null) {
      final List decoded = jsonDecode(clinicsRaw);
      _clinics = decoded.map((e) => Clinic.fromJson(e)).toList();
    }

    final doctorsRaw = prefs.getString(_kDoctorsKey);
    if (doctorsRaw != null) {
      final List decoded = jsonDecode(doctorsRaw);
      _doctors = decoded.map((e) => Doctor.fromJson(e)).toList();
    }

    final logsRaw = prefs.getString(_kAuditLogsKey);
    if (logsRaw != null) {
      final List decoded = jsonDecode(logsRaw);
      _auditLogs = List<Map<String, dynamic>>.from(decoded);
    }

    notifyListeners();
  }

  void _seedDemoData() {
    _applications = [
      ClinicApplication(
        id: 'APP-1001',
        clinicName: 'ABC Dental Clinic',
        clinicPhone: '+91 98765 43210',
        email: 'info@abcdental.com',
        address: '102 Healthcare Avenue, Block B',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
        latitude: 19.0760,
        longitude: 72.8777,
        speciality: 'Dental & Orthodontics',
        operatingHours: '09:00 AM - 08:00 PM',
        doctorName: 'Dr. Rahul Sharma',
        doctorPhone: '+91 98765 43211',
        doctorSpeciality: 'Dentist',
        doctorQualification: 'BDS, MDS (Orthodontics)',
        doctorRegNum: 'MCI-884920',
        avgConsultationMinutes: 10,
        status: ApplicationStatus.pending,
        submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    const demoClinicId = 'CS-7K82P';
    final demoClinic = Clinic(
      clinicId: demoClinicId,
      clinicRefNum: 'REF-78291',
      name: 'LifeCare Health Clinic',
      phone: '+91 99000 11223',
      email: 'care@lifecare.com',
      address: 'Shop 12, Sunrise Complex, MG Road',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
      latitude: 12.9716,
      longitude: 77.5946,
      speciality: 'General Medicine & Cardiology',
      operatingHours: '08:00 AM - 09:00 PM',
      status: ClinicStatus.approved,
    );
    _clinics = [demoClinic];

    _doctors = [
      Doctor(
        doctorId: 'DOC-101',
        clinicId: demoClinicId,
        name: 'Dr. Suresh Kumar',
        phone: '+91 99000 11224',
        speciality: 'General Physician',
        qualification: 'MBBS, MD (Internal Medicine)',
        registrationNumber: 'KMC-12345',
        avgConsultationMinutes: 10,
        isAvailable: true,
      ),
    ];

    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kApplicationsKey,
      jsonEncode(_applications.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _kClinicsKey,
      jsonEncode(_clinics.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _kDoctorsKey,
      jsonEncode(_doctors.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_kAuditLogsKey, jsonEncode(_auditLogs));
  }

  bool login(String username, String password) {
    if (username.isNotEmpty && password == 'admin123') {
      _isLoggedIn = true;
      _adminUser = username;
      _logAudit('ADMIN_LOGIN', 'Admin $username logged into CareSeva SuperAdmin Command Center.');
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  String _generateUniqueClinicId() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random();
    String newId;
    do {
      final code = String.fromCharCodes(
        Iterable.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
      newId = 'CS-$code';
    } while (_clinics.any((c) => c.clinicId == newId));
    return newId;
  }

  /// Approve Clinic Application via Railway FastAPI MongoDB Backend
  Future<String> approveApplication(String appId) async {
    final index = _applications.indexWhere((a) => a.id == appId);
    if (index == -1) throw Exception('Application not found');

    final app = _applications[index];
    final generatedClinicId = _generateUniqueClinicId();
    final generatedRefNum = 'REF-${generatedClinicId.replaceAll('CS-', '')}';

    app.status = ApplicationStatus.approved;
    app.reviewedAt = DateTime.now();
    app.assignedClinicId = generatedClinicId;

    final newClinic = Clinic(
      clinicId: generatedClinicId,
      clinicRefNum: generatedRefNum,
      name: app.clinicName,
      phone: app.clinicPhone,
      email: app.email,
      address: app.address,
      city: app.city,
      state: app.state,
      pincode: app.pincode,
      latitude: app.latitude,
      longitude: app.longitude,
      speciality: app.speciality,
      operatingHours: app.operatingHours,
      status: ClinicStatus.approved,
    );

    final newDoctor = Doctor(
      doctorId: 'DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      clinicId: generatedClinicId,
      name: app.doctorName,
      phone: app.doctorPhone,
      speciality: app.doctorSpeciality,
      qualification: app.doctorQualification,
      registrationNumber: app.doctorRegNum,
      avgConsultationMinutes: app.avgConsultationMinutes,
      isAvailable: true,
    );

    _clinics.insert(0, newClinic);
    _doctors.insert(0, newDoctor);

    // Direct HTTP POST to Railway FastAPI MongoDB Backend
    try {
      await ApiService.approveApplication(appId);
    } catch (e) {
      debugPrint('[AdminStore] ApiService Approve Error: $e');
    }

    _logAudit('CLINIC_APPROVED', 'Approved ${app.clinicName}. Generated Clinic ID: $generatedClinicId.');
    await _saveData();
    notifyListeners();
    return generatedClinicId;
  }

  /// Reject Application via Railway FastAPI MongoDB Backend
  Future<void> rejectApplication(String appId, String reason) async {
    final index = _applications.indexWhere((a) => a.id == appId);
    if (index == -1) return;

    final app = _applications[index];
    app.status = ApplicationStatus.rejected;
    app.reviewedAt = DateTime.now();
    app.rejectionReason = reason;

    // Direct HTTP POST to Railway FastAPI MongoDB Backend
    try {
      await ApiService.rejectApplication(appId, reason);
    } catch (e) {
      debugPrint('[AdminStore] ApiService Reject Error: $e');
    }

    _logAudit('CLINIC_REJECTED', 'Rejected application for ${app.clinicName}. Reason: $reason');
    await _saveData();
    notifyListeners();
  }

  /// Toggle Suspend / Reactivate Clinic Status
  Future<void> toggleClinicStatus(String clinicId) async {
    final index = _clinics.indexWhere((c) => c.clinicId == clinicId);
    if (index == -1) return;

    final clinic = _clinics[index];
    if (clinic.status == ClinicStatus.approved) {
      clinic.status = ClinicStatus.suspended;
      _logAudit('CLINIC_SUSPENDED', 'Clinic ${clinic.name} ($clinicId) has been SUSPENDED.');
    } else {
      clinic.status = ClinicStatus.approved;
      _logAudit('CLINIC_REACTIVATED', 'Clinic ${clinic.name} ($clinicId) has been REACTIVATED.');
    }

    await _saveData();
    notifyListeners();
  }

  /// Add Doctor to a Clinic
  Future<void> addDoctorToClinic(Doctor doctor) async {
    _doctors.add(doctor);
    _logAudit('DOCTOR_ADDED', 'Added Doctor ${doctor.name} to Clinic ${doctor.clinicId}');
    await _saveData();
    notifyListeners();
  }

  void _logAudit(String action, String details) {
    final logData = {
      'id': 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      'action': action,
      'performedBy': _adminUser,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _auditLogs.insert(0, logData);
  }
}
