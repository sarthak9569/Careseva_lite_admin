import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic_application.dart';
import '../services/admin_store.dart';
import '../services/pdf_export_service.dart';
import '../theme/admin_theme.dart';
import 'application_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedFilterIndex = 0; // 0: Pending, 1: All, 2: Approved, 3: Rejected
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminStore = Provider.of<AdminStore>(context);
    final pendingApps = adminStore.pendingApplications;
    final approvedApps = adminStore.approvedApplications;
    final rejectedApps = adminStore.rejectedApplications;
    final allApps = adminStore.applications;

    // Filter logic
    List<ClinicApplication> currentList;
    switch (_selectedFilterIndex) {
      case 0:
        currentList = pendingApps;
        break;
      case 1:
        currentList = allApps;
        break;
      case 2:
        currentList = approvedApps;
        break;
      case 3:
        currentList = rejectedApps;
        break;
      default:
        currentList = pendingApps;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      currentList = currentList.where((app) {
        return app.clinicName.toLowerCase().contains(q) ||
            app.doctorName.toLowerCase().contains(q) ||
            app.city.toLowerCase().contains(q) ||
            app.id.toLowerCase().contains(q) ||
            (app.assignedClinicId != null && app.assignedClinicId!.toLowerCase().contains(q));
      }).toList();
    }

    return Scaffold(
      backgroundColor: AdminTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP COMMAND CENTER HEADER
              _buildTopHeader(context, adminStore),
              const SizedBox(height: 20),

              // 2. STATUTORY CLINICAL STANDARD BANNER
              _buildStatutoryBanner(),
              const SizedBox(height: 20),

              // 3. METRIC CARDS GRID (4 Cards)
              _buildMetricCardsRow(
                pendingCount: pendingApps.length,
                approvedCount: approvedApps.length,
                totalBeds: 0, // Dynamic bed capacity counter
                accreditedCount: 0, // NABH / NABL count
              ),
              const SizedBox(height: 24),

              // 4. FILTER TABS & SEARCH BAR ROW
              _buildFilterAndSearchRow(
                pendingCount: pendingApps.length,
                allCount: allApps.length,
                approvedCount: approvedApps.length,
                rejectedCount: rejectedApps.length,
              ),
              const SizedBox(height: 16),

              // 5. MAIN CONTENT (EMPTY STATE OR LIVE APPLICATION LIST)
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor)),
                )
              else if (currentList.isEmpty)
                _buildEmptyStateCard()
              else
                _buildApplicationList(currentList, adminStore),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Header Row
  Widget _buildTopHeader(BuildContext context, AdminStore adminStore) {
    return Row(
      children: [
        // Brand Shield Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.4)),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF14B8A6),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),

        // Command Center Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CareSeva SuperAdmin Command Center',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Corporate Regulatory Compliance, Em-panelment & Legal Verification Portal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Cloud Production Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 15),
              SizedBox(width: 8),
              Text(
                'Env: Cloud Production',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Refresh Button
        IconButton(
          tooltip: 'Refresh Data Real-time',
          icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textSecondary, size: 22),
          onPressed: () async {
            await adminStore.refreshData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard synchronized in real-time with Railway & Firestore'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),

        // Logout Button
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded, color: AdminTheme.textMuted, size: 22),
          onPressed: () {
            adminStore.logout();
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
      ],
    );
  }

  /// 2. Statutory Banner Card
  Widget _buildStatutoryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131825),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Color(0xFF38BDF8),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statutory Clinical Em-panelment Standard (Clinical Establishments Act & NABH Guidelines)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hospitals on CareSeva must furnish verified State Clinical Establishment License, GSTIN/PAN, Medical Superintendent credentials, and Bio-Medical Waste authorizations before public patient booking is activated.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AdminTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Metric Cards Row (4 Grid Cards)
  Widget _buildMetricCardsRow({
    required int pendingCount,
    required int approvedCount,
    required int totalBeds,
    required int accreditedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final cards = [
          _buildMetricCard(
            title: 'Pending Verifications',
            count: '$pendingCount',
            subtitle: 'Awaiting SuperAdmin approval',
            accentColor: AdminTheme.pendingGold,
            icon: Icons.hourglass_top_rounded,
          ),
          _buildMetricCard(
            title: 'Approved Facilities',
            count: '$approvedCount',
            subtitle: 'Active & accepting patients',
            accentColor: AdminTheme.approvedGreen,
            icon: Icons.check_circle_rounded,
          ),
          _buildMetricCard(
            title: 'Monitored Hospital Beds',
            count: '$totalBeds',
            subtitle: 'Total capacity tracked across India',
            accentColor: AdminTheme.cyanBeds,
            icon: Icons.bed_rounded,
          ),
          _buildMetricCard(
            title: 'Accredited Facilities',
            count: '$accreditedCount',
            subtitle: 'NABH / NABL certified institutions',
            accentColor: AdminTheme.accreditedPurple,
            icon: Icons.military_tech_rounded,
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        } else {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: cards,
          );
        }
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131825),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AdminTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Filter Tabs & Search Bar Row
  Widget _buildFilterAndSearchRow({
    required int pendingCount,
    required int allCount,
    required int approvedCount,
    required int rejectedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final tabs = [
          _buildFilterChip(0, 'Pending Approvals ($pendingCount)', Icons.gavel_rounded),
          _buildFilterChip(1, 'All Facilities ($allCount)', Icons.apartment_rounded),
          _buildFilterChip(2, 'Approved & Active ($approvedCount)', Icons.check_circle_outline_rounded),
          _buildFilterChip(3, 'Rejected ($rejectedCount)', Icons.cancel_outlined),
        ];

        final searchBar = SizedBox(
          width: isMobile ? double.infinity : 280,
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Name, HopID, CEA #, City...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminTheme.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: AdminTheme.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: tabs.map((t) => Padding(padding: const EdgeInsets.only(right: 8), child: t)).toList()),
              ),
              const SizedBox(height: 12),
              searchBar,
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: tabs.map((t) => Padding(padding: const EdgeInsets.only(right: 8), child: t)).toList()),
              searchBar,
            ],
          );
        }
      },
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon) {
    final isSelected = _selectedFilterIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E).withValues(alpha: 0.25) : const Color(0xFF131825),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF1E2638),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF14B8A6) : AdminTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AdminTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Empty State Card matching uploaded screenshot precisely
  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF131825),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Checkmark Icon matching screenshot
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF94A3B8),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All hospital compliance applications have been processed!',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When a new hospital submits registration, it will appear here immediately for legal verification.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AdminTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 6. Application Cards List
  Widget _buildApplicationList(List<ClinicApplication> apps, AdminStore adminStore) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131825),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E2638)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Top Bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(app.status).withValues(alpha: 0.15),
                    radius: 20,
                    child: Icon(_getStatusIcon(app.status), color: _getStatusColor(app.status), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.clinicName,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Doctor: ${app.doctorName} (${app.doctorSpeciality})',
                          style: GoogleFonts.inter(fontSize: 13, color: AdminTheme.textSecondary),
                        ),
                        Text(
                          'Location: ${app.address}, ${app.city}, ${app.state} • Phone: ${app.clinicPhone}',
                          style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(app.status).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusColor(app.status).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          app.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(app.status),
                          ),
                        ),
                      ),
                      if (app.assignedClinicId != null) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          'Clinic ID: ${app.assignedClinicId}',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF14B8A6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E2638), height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Text(
                    'Submitted: ${dateFormat.format(app.submittedAt)}',
                    style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Download PDF Application',
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8), size: 20),
                    onPressed: () => PdfExportService.downloadOrPrintApplication(context, app),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApplicationDetailScreen(application: app),
                        ),
                      );
                    },
                    child: const Text('View Full Details', style: TextStyle(fontSize: 12)),
                  ),
                  if (app.status == ApplicationStatus.pending) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.rejectedRed,
                        side: const BorderSide(color: AdminTheme.rejectedRed),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _rejectApplicationQuick(context, adminStore, app),
                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _approveApplicationQuick(context, adminStore, app),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve & Assign ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _approveApplicationQuick(BuildContext context, AdminStore adminStore, ClinicApplication app) async {
    setState(() => _isProcessing = true);
    try {
      final clinicId = await adminStore.approveApplication(app.id);
      if (!context.mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog(context, clinicId, app.clinicName);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving application: $e')),
      );
    }
  }

  void _rejectApplicationQuick(BuildContext context, AdminStore adminStore, ClinicApplication app) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131825),
        title: Text('Reject Application', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Provide reason for rejecting "${app.clinicName}":', style: const TextStyle(color: AdminTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Invalid license number or incomplete details',
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
              await adminStore.rejectApplication(app.id, reason);
              if (mounted) setState(() => _isProcessing = false);
            },
            child: const Text('Reject Application', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String clinicId, String clinicName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131825),
        icon: const Icon(Icons.check_circle_rounded, color: AdminTheme.approvedGreen, size: 52),
        title: Text('Clinic Approved & Live!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$clinicName" has been em-paneled successfully.',
              style: const TextStyle(color: AdminTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
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
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}

