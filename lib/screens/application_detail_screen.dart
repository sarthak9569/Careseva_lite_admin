import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic_application.dart';
import '../services/admin_store.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final ClinicApplication application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _isProcessing = false;

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve Clinic', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to approve "${widget.application.clinicName}"?\n\n'
          'A unique alpha-numeric Clinic ID (e.g. CS-7K82P) will be generated and assigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              final store = Provider.of<AdminStore>(context, listen: false);
              try {
                final clinicId = await store.approveApplication(widget.application.id);
                if (mounted) {
                  setState(() => _isProcessing = false);
                  _showSuccessDialog(clinicId);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isProcessing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error approving clinic: $e')),
                  );
                }
              }
            },
            child: const Text('Approve & Assign ID'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String clinicId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
        title: Text('Clinic Approved!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The clinic has been approved successfully.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0F766E)),
              ),
              child: Column(
                children: [
                  const Text('GENERATED CLINIC ID', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SelectableText(
                    clinicId,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F766E),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Pop dialog
              Navigator.pop(context); // Return to list
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Application', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Incomplete verification details or invalid doctor registration.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              final store = Provider.of<AdminStore>(context, listen: false);
              await store.rejectApplication(widget.application.id, reason);
              if (mounted) {
                setState(() => _isProcessing = false);
                Navigator.pop(context);
              }
            },
            child: const Text('Reject Application'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Application #${app.id}'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(app.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(app.status)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(app.status), color: _getStatusColor(app.status)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUS: ${app.status.name.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(app.status),
                              ),
                            ),
                            Text(
                              'Submitted: ${dateFormat.format(app.submittedAt)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (app.assignedClinicId != null)
                          Chip(
                            label: Text(
                              'ID: ${app.assignedClinicId}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF0F766E),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Clinic Information
                  _buildSectionHeader(Icons.local_hospital_rounded, 'Clinic Information'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Clinic Name', app.clinicName),
                          _buildDetailRow('Phone Number', app.clinicPhone),
                          _buildDetailRow('Email', app.email.isEmpty ? 'N/A' : app.email),
                          _buildDetailRow('Speciality', app.speciality),
                          _buildDetailRow('Operating Hours', app.operatingHours),
                          _buildDetailRow('Address', '${app.address}, ${app.city}, ${app.state} - ${app.pincode}'),
                          _buildDetailRow('Coordinates', 'Lat: ${app.latitude}, Long: ${app.longitude}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Doctor Information
                  _buildSectionHeader(Icons.person_rounded, 'Primary Doctor Information'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Doctor Name', app.doctorName),
                          _buildDetailRow('Phone Number', app.doctorPhone),
                          _buildDetailRow('Speciality', app.doctorSpeciality),
                          _buildDetailRow('Qualification', app.doctorQualification),
                          _buildDetailRow('Registration No.', app.doctorRegNum),
                          _buildDetailRow('Avg Consultation', '${app.avgConsultationMinutes} minutes'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  if (app.status == ApplicationStatus.pending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _showRejectDialog,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('REJECT'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _showApproveDialog,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('APPROVE & GENERATE ID'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.approved:
        return Icons.verified_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}
