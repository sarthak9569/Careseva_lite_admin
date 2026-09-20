import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../models/doctor.dart';
import '../services/admin_store.dart';

class DoctorManagementScreen extends StatefulWidget {
  final Clinic clinic;

  const DoctorManagementScreen({super.key, required this.clinic});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  void _showAddDoctorModal() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final specialityController = TextEditingController();
    final qualificationController = TextEditingController();
    final regNumController = TextEditingController();
    int avgTime = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Doctor to ${widget.clinic.name}',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specialityController,
                  decoration: const InputDecoration(
                    labelText: 'Speciality (e.g. Dentist, Cardiologist)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qualificationController,
                  decoration: const InputDecoration(
                    labelText: 'Qualification (e.g. MBBS, MDS)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: regNumController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Council Reg No.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Avg Consultation Time: '),
                    DropdownButton<int>(
                      value: avgTime,
                      items: [5, 10, 15, 20, 30].map((t) {
                        return DropdownMenuItem(value: t, child: Text('$t mins'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => avgTime = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final newDoctor = Doctor(
                      doctorId: 'DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      clinicId: widget.clinic.clinicId,
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      speciality: specialityController.text.trim(),
                      qualification: qualificationController.text.trim(),
                      registrationNumber: regNumController.text.trim(),
                      avgConsultationMinutes: avgTime,
                      isAvailable: true,
                    );

                    final store = Provider.of<AdminStore>(context, listen: false);
                    await store.addDoctorToClinic(newDoctor);

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add Doctor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<AdminStore>(context);
    final clinicDoctors = store.doctors.where((d) => d.clinicId == widget.clinic.clinicId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Doctors - ${widget.clinic.name}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        onPressed: _showAddDoctorModal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Doctor', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLINIC ID: ${widget.clinic.clinicId}',
                        style: GoogleFonts.sourceCodePro(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                      Text(
                        'Doctors associated with this clinic maintain separate queues.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: clinicDoctors.isEmpty
                  ? const Center(child: Text('No doctors added to this clinic yet.'))
                  : ListView.builder(
                      itemCount: clinicDoctors.length,
                      itemBuilder: (context, index) {
                        final doc = clinicDoctors[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                              child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0F766E)),
                            ),
                            title: Text(
                              doc.name,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${doc.speciality} • ${doc.qualification}\nReg: ${doc.registrationNumber} • Est: ${doc.avgConsultationMinutes}m/pt',
                            ),
                            trailing: Chip(
                              label: Text(
                                doc.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                              backgroundColor: doc.isAvailable ? Colors.green : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
