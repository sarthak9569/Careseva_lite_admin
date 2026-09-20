import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../services/admin_store.dart';
import 'doctor_management_screen.dart';

class ClinicManagementScreen extends StatefulWidget {
  const ClinicManagementScreen({super.key});

  @override
  State<ClinicManagementScreen> createState() => _ClinicManagementScreenState();
}

class _ClinicManagementScreenState extends State<ClinicManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final adminStore = Provider.of<AdminStore>(context);
    final clinics = adminStore.clinics.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.clinicId.toLowerCase().contains(query) ||
          c.city.toLowerCase().contains(query) ||
          c.speciality.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by Clinic Name, Clinic ID (e.g. CS-7K82P), City...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        Expanded(
          child: clinics.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'No clinics registered yet.' : 'No matching clinics found.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clinics.length,
                  itemBuilder: (context, index) {
                    final clinic = clinics[index];
                    final doctorsCount = adminStore.doctors.where((d) => d.clinicId == clinic.clinicId).length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clinic.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${clinic.city}, ${clinic.state} • ${clinic.speciality}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: clinic.status == ClinicStatus.approved
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: clinic.status == ClinicStatus.approved ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  child: Text(
                                    clinic.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: clinic.status == ClinicStatus.approved ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Public Clinic ID Banner
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        'CLINIC ID: ${clinic.clinicId}',
                                        style: GoogleFonts.sourceCodePro(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Doctors: $doctorsCount',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorManagementScreen(clinic: clinic),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.people_alt_rounded, size: 18),
                                  label: const Text('Manage Doctors'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: clinic.status == ClinicStatus.approved
                                        ? Colors.orange.shade800
                                        : Colors.green.shade700,
                                  ),
                                  onPressed: () async {
                                    final action = clinic.status == ClinicStatus.approved ? 'SUSPEND' : 'REACTIVATE';
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('$action Clinic'),
                                        content: Text(
                                          'Are you sure you want to $action "${clinic.name}" ($clinic.clinicId)?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text('Confirm $action'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await adminStore.toggleClinicStatus(clinic.clinicId);
                                    }
                                  },
                                  icon: Icon(
                                    clinic.status == ClinicStatus.approved
                                        ? Icons.pause_circle_outline_rounded
                                        : Icons.play_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    clinic.status == ClinicStatus.approved ? 'Suspend' : 'Reactivate',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
