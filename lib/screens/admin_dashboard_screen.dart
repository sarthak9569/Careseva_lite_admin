import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic_application.dart';
import '../services/admin_store.dart';
import 'application_detail_screen.dart';
import 'clinic_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminStore = Provider.of<AdminStore>(context);
    final pendingCount = adminStore.pendingApplications.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_hospital_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'CareSeva 2 Admin',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              adminStore.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Applications'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Registered Clinics'),
            const Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Applications Tab
          _buildApplicationsTab(context, adminStore),

          // Clinics Tab
          const ClinicManagementScreen(),

          // Audit Logs Tab
          _buildAuditLogsTab(adminStore),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab(BuildContext context, AdminStore adminStore) {
    final apps = adminStore.applications;

    if (apps.isEmpty) {
      return const Center(child: Text('No clinic registration applications submitted yet.'));
    }

    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(app.status).withValues(alpha: 0.15),
              child: Icon(_getStatusIcon(app.status), color: _getStatusColor(app.status)),
            ),
            title: Text(
              app.clinicName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Doctor: ${app.doctorName} (${app.doctorSpeciality})'),
                Text(
                  '${app.city}, ${app.state} • Submitted: ${dateFormat.format(app.submittedAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(
                    app.status.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(app.status),
                  visualDensity: VisualDensity.compact,
                ),
                if (app.assignedClinicId != null)
                  Text(
                    'ID: ${app.assignedClinicId}',
                    style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F766E)),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicationDetailScreen(application: app),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsTab(AdminStore adminStore) {
    final logs = adminStore.auditLogs;

    if (logs.isEmpty) {
      return const Center(child: Text('No audit logs recorded yet.'));
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final log = logs[index];
        final dt = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();

        return ListTile(
          leading: const Icon(Icons.history_rounded, color: Color(0xFF0F766E)),
          title: Text(
            log['action'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(log['details'] ?? ''),
          trailing: Text(
            dateFormat.format(dt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        );
      },
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
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}
