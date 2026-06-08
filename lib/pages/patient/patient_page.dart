import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../medical/types_medicaments_page.dart';
import '../medical/analyse_page.dart';
import '../medical/dossier_medical_page.dart';
import '../medical/history_page.dart';
import 'rendezvous_page.dart';
import 'patient_profile_page.dart';
import '../../widgets/notifications_page.dart';
import '../family/family_role_page.dart';

class PatientPage extends StatefulWidget {
  final String patientName;
  final String patientId;
  final bool readOnly;

  const PatientPage({
    super.key,
    required this.patientName,
    required this.patientId,
    this.readOnly = false,
  });

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    loadPatient();
  }

  Future<void> loadPatient() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.patientId)
        .get();
    if (mounted) {
      setState(() {
        patientData = doc.data();
      });
    }
  }

  Future<void> markNotificationsAsRead() async {
    final snap = await FirebaseFirestore.instance
        .collection("notifications")
        .where(
          "patientId",
          isEqualTo: widget.patientId,
        )
        .where(
          "patientRead",
          isEqualTo: false,
        )
        .get();

    for (var doc in snap.docs) {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(doc.id)
          .update({
        "patientRead": true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: patientData?["photoUrl"] != null &&
                      patientData!["photoUrl"].toString().isNotEmpty
                  ? NetworkImage(patientData!["photoUrl"])
                  : null,
              child: patientData?["photoUrl"] == null ||
                      patientData!["photoUrl"].toString().isEmpty
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF4A90E2),
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              patientData?["nom"] ?? widget.patientName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
// 🔔 NOTIFICATIONS
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("notifications")
                .where(
                  "patientId",
                  isEqualTo: widget.patientId,
                )
                .where(
                  "patientRead",
                  isEqualTo: false,
                )
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                    ),
                    onPressed: () async {
                      await markNotificationsAsRead();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsPage(
                            patientId: widget.patientId,
                          ),
                        ),
                      );
                    },
                  ),

                  // 🔴 POINT ROUGE
                  if (count > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 👤 PROFILE
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientProfilePage(
                    patientId: widget.patientId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: patientData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(children: [
                // 🔥 HEADER MODERN
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
// 🧑‍⚕️ Avatar
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: patientData?["photoUrl"] != null &&
                                patientData!["photoUrl"].toString().isNotEmpty
                            ? NetworkImage(
                                patientData!["photoUrl"],
                              )
                            : null,
                        child: patientData?["photoUrl"] == null ||
                                patientData!["photoUrl"].toString().isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.blue,
                                size: 35,
                              )
                            : null,
                      ),

                      const SizedBox(width: 15),

                      // 📋 Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Dossier Patient",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Suivi médical intelligent",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 💊 Médicaments
                buildCard(
                  icon: Icons.medication,
                  title: "Médicaments",
                  subtitle: "Gestion du traitement",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TypesMedicamentsPage(
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                ),

                // 🧪 Analyse
                buildCard(
                  icon: Icons.science,
                  title: "Analyses",
                  subtitle: "Résultats médicaux",
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnalysePage(
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                ),

                // 📁 Dossier
                buildCard(
                  icon: Icons.folder,
                  title: "Dossier médical",
                  subtitle: "Informations complètes",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DossierMedicalPage(
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                ),

                // 📅 Historique
                buildCard(
                  icon: Icons.history,
                  title: "Historique",
                  subtitle: "Suivi des traitements",
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryPage(
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                ),
// 📅 Rendez-vous
                buildCard(
                  icon: Icons.calendar_month,
                  title: "Rendez-vous",
                  subtitle: "Gestion des rendez-vous",
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RendezVousPage(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                          readOnly: widget.readOnly,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                buildCard(
                  icon: Icons.family_restroom,
                  title: "Membres de famille",
                  subtitle: "Gérer les membres de famille",
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FamilyRolePage(
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ]),
            ),
    );
  }

// 💎 CARD PRO DESIGN
  Widget buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                color.withOpacity(0.08),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              // 🔵 ICON
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),

              const SizedBox(width: 15),

              // 📝 TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: color,
              )
            ],
          ),
        ),
      ),
    );
  }
}
