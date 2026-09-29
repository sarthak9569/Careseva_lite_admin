import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic_application.dart';
import '../services/admin_store.dart';
import '../services/pdf_export_service.dart';
import '../theme/admin_theme.dart';

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
        backgroundColor: const Color(0xFF131825),
        title: Text('Approve Clinic', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text(
          'Are you sure you want to approve "${widget.application.clinicName}"?\n\n'
          'A unique alpha-numeric Clinic ID (e.g. CS-7K82P) will be generated and assigned.',
          style: const TextStyle(color: AdminTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AdminTheme.textMuted)),
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
            child: const Text('Approve & Assign ID', style: TextStyle(color: Colors.white)),
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
        backgroundColor: const Color(0xFF131825),
        icon: const Icon(Icons.check_circle_rounded, color: AdminTheme.approvedGreen, size: 52),
        title: Text('Clinic Approved!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The clinic application has been approved and em-paneled successfully.', style: TextStyle(color: AdminTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0D9488)),
              ),
              child: Column(
                children: [
                  const Text('GENERATED CLINIC ID', style: TextStyle(fontSize: 11, color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(
                    clinicId,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14B8A6),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
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
        backgroundColor: const Color(0xFF131825),
        title: Text('Reject Application', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for rejection:', style: TextStyle(color: AdminTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Incomplete verification details or invalid doctor registration.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AdminTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.rejectedRed),
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
            child: const Text('Reject Application', style: TextStyle(color: Colors.white)),
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
      backgroundColor: AdminTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AdminTheme.headerBg,
        title: Text('Application Record #${app.id}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Download PDF Action Button
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => PdfExportService.downloadOrPrintApplication(context, app),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('Download PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131825),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(app.status)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getStatusColor(app.status).withValues(alpha: 0.2),
                          child: Icon(_getStatusIcon(app.status), color: _getStatusColor(app.status)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUS: ${app.status.name.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(app.status),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Submitted: ${dateFormat.format(app.submittedAt)}',
                              style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (app.assignedClinicId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0D9488)),
                            ),
                            child: SelectableText(
                              'Clinic ID: ${app.assignedClinicId}',
                              style: GoogleFonts.sourceCodePro(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF14B8A6),
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Clinic Information
                  _buildSectionHeader(Icons.local_hospital_rounded, 'Clinic Establishment Details'),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131825),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2638)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Clinic Name', app.clinicName),
                        _buildDetailRow('Phone Number', app.clinicPhone),
                        _buildDetailRow('Email', app.email.isEmpty ? 'N/A' : app.email),
                        _buildDetailRow('Speciality', app.speciality),
                        _buildDetailRow('Operating Hours', app.operatingHours),
                        _buildDetailRow('Full Address', '${app.address}, ${app.city}, ${app.state} - ${app.pincode}'),
                        _buildDetailRow('GPS Location', 'Lat: ${app.latitude}, Long: ${app.longitude}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Doctor Information
                  _buildSectionHeader(Icons.person_rounded, 'Primary Doctor & Medical Superintendent'),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131825),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2638)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Doctor Name', app.doctorName),
                        _buildDetailRow('Doctor Phone', app.doctorPhone),
                        _buildDetailRow('Speciality', app.doctorSpeciality),
                        _buildDetailRow('Qualification', app.doctorQualification),
                        _buildDetailRow('Registration No.', app.doctorRegNum),
                        _buildDetailRow('Avg Consultation', '${app.avgConsultationMinutes} minutes'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legal Compliance Verification Checklist
                  _buildSectionHeader(Icons.verified_user_rounded, 'Statutory Compliance & Legal Checklist'),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131825),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2638)),
                    ),
                    child: Column(
                      children: [
                        _buildChecklistRow('State Clinical Establishment Act License', true),
                        _buildChecklistRow('Medical Superintendent Credentials Verification', true),
                        _buildChecklistRow('GSTIN / PAN Tax Verification', true),
                        _buildChecklistRow('Bio-Medical Waste Authorization Document', true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      // Download PDF Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => PdfExportService.downloadOrPrintApplication(context, app),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('DOWNLOAD PDF APPLICATION', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (app.status == ApplicationStatus.pending) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminTheme.rejectedRed,
                              side: const BorderSide(color: AdminTheme.rejectedRed),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _showRejectDialog,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('REJECT APPLICATION', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _showApproveDialog,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('APPROVE & GENERATE ID', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF14B8A6)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, color: AdminTheme.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(String title, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AdminTheme.approvedGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: const BoxDecoration(
              color: Color(0xFF064E3B),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: const Text('VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AdminTheme.pendingGold;
      case ApplicationStatus.approved:
        return AdminTheme.approvedGreen;
      case ApplicationStatus.rejected:
        return AdminTheme.rejectedRed;
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

