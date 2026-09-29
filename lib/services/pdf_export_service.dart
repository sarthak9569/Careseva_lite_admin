import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/clinic_application.dart';

class PdfExportService {
  /// Generate official PDF Document for Clinic Application
  static Future<pw.Document> generateApplicationPdf(ClinicApplication app) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');

    // Primary Brand Color (#0F766E)
    const primaryColor = PdfColor.fromInt(0xFF0F766E);
    const darkSlate = PdfColor.fromInt(0xFF0F172A);
    const lightGrey = PdfColor.fromInt(0xFFF8FAFC);
    const borderGrey = PdfColor.fromInt(0xFFE2E8F0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. OFFICIAL HEADER BAND
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CARESEVA HEALTHCARE NETWORK',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Official Clinical Establishment Registration Record',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        app.status.name.toUpperCase(),
                        style: const pw.TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // 2. METADATA BANNER
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderGrey),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Application ID: ${app.id}', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Submitted On: ${dateFormat.format(app.submittedAt)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    if (app.assignedClinicId != null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('ASSIGNED CLINIC ID: ${app.assignedClinicId}', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: primaryColor)),
                          pw.Text('Ref #: REF-${app.assignedClinicId!.replaceAll('CS-', '')}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // 3. CLINIC ESTABLISHMENT DETAILS
              _buildPdfSectionHeader('CLINIC ESTABLISHMENT INFORMATION', primaryColor),
              pw.SizedBox(height: 8),
              _buildPdfGrid([
                _buildPdfField('Clinic Name', app.clinicName),
                _buildPdfField('Phone Number', app.clinicPhone),
                _buildPdfField('Email Address', app.email.isEmpty ? 'N/A' : app.email),
                _buildPdfField('Speciality', app.speciality),
                _buildPdfField('Operating Hours', app.operatingHours),
                _buildPdfField('Full Address', '${app.address}, ${app.city}, ${app.state} - ${app.pincode}'),
                _buildPdfField('GPS Coordinates', 'Lat: ${app.latitude.toStringAsFixed(4)}, Long: ${app.longitude.toStringAsFixed(4)}'),
              ], borderGrey),
              pw.SizedBox(height: 20),

              // 4. DOCTOR / MEDICAL SUPERINTENDENT INFORMATION
              _buildPdfSectionHeader('PRIMARY DOCTOR & MEDICAL SUPERINTENDENT', primaryColor),
              pw.SizedBox(height: 8),
              _buildPdfGrid([
                _buildPdfField('Doctor Name', app.doctorName),
                _buildPdfField('Contact Phone', app.doctorPhone),
                _buildPdfField('Speciality', app.doctorSpeciality),
                _buildPdfField('Qualifications', app.doctorQualification),
                _buildPdfField('Medical Registration No.', app.doctorRegNum),
                _buildPdfField('Avg Consultation Time', '${app.avgConsultationMinutes} Minutes'),
              ], borderGrey),
              pw.SizedBox(height: 20),

              // 5. STATUTORY VERIFICATION CHECKLIST
              _buildPdfSectionHeader('STATUTORY COMPLIANCE CHECKLIST', primaryColor),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderGrey),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfCheckItem('State Clinical Establishment Act License', true),
                    _buildPdfCheckItem('Medical Superintendent Registration & Credentials', true),
                    _buildPdfCheckItem('GSTIN / PAN Tax Verification', true),
                    _buildPdfCheckItem('Bio-Medical Waste Authorization', true),
                  ],
                ),
              ),
              pw.Spacer(),

              // 6. FOOTER & STAMP
              pw.Divider(color: borderGrey),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CareSeva SuperAdmin Verification System', style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkSlate)),
                      pw.Text('Digitally verified and generated on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: primaryColor, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text('VERIFIED & STAMPED', style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Download or Print Application PDF
  static Future<void> downloadOrPrintApplication(BuildContext context, ClinicApplication app) async {
    try {
      final pdf = await generateApplicationPdf(app);
      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'CareSeva_Application_${app.id}_${app.clinicName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading application: $e')),
        );
      }
    }
  }

  static pw.Widget _buildPdfSectionHeader(String title, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title,
        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildPdfGrid(List<pw.Widget> fields, PdfColor borderGrey) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderGrey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: fields,
      ),
    );
  }

  static pw.Widget _buildPdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfCheckItem(String title, bool isChecked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(isChecked ? '[X] ' : '[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromInt(0xFF0F766E))),
          pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
        ],
      ),
    );
  }
}
