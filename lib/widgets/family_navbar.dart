import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/medical/types_medicaments_page.dart';
import '../pages/medical/analyse_page.dart';
import '../pages/medical/dossier_medical_page.dart';
import '../pages/medical/history_page.dart';
import '../pages/family/family_profile_page.dart';
import '../widgets/chatbot_page.dart';
import '../pages/family/family_member_page.dart';

class FamilyNavBar extends StatefulWidget {
  final String memberName;
  final String patientId;
  const FamilyNavBar({
    super.key,
    required this.memberName,
    required this.patientId,
  });

  @override
  State<FamilyNavBar> createState() => _FamilyNavBarState();
}

class _FamilyNavBarState extends State<FamilyNavBar> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FamilyPatientsPage(
  patientName: widget.memberName,
  patientId: widget.patientId,
),
      TypesMedicamentsPage(patientId: widget.patientId, readOnly: true),
      AnalysePage(patientId: widget.patientId, readOnly: true),
      HistoryPage(patientId: widget.patientId),
      const FamilyProfilePage(),
      const ChatBotPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Accueil",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medication_outlined),
                activeIcon: Icon(Icons.medication),
                label: "Médicaments",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.science_outlined),
                activeIcon: Icon(Icons.science),
                label: "Analyses",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: "Historique",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profil",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy_outlined),
                activeIcon: Icon(Icons.smart_toy),
                label: "Chatbot",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Page Accueil Famille
// ============================================
class FamilyHomeContent extends StatelessWidget {
  final String memberName;
  final String patientId;
  const FamilyHomeContent({
    super.key,
    required this.memberName,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text("👨‍👩‍👧 $memberName"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.family_restroom,
                        color: Colors.blue, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Espace Famille",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text("Suivi du patient",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Derniers médicaments aujourd'hui
            _TodayMedsSummary(patientId: patientId),
          ],
        ),
      ),
    );
  }
}

// Widget résumé médicaments du jour
class _TodayMedsSummary extends StatefulWidget {
  final String patientId;
  const _TodayMedsSummary({required this.patientId});

  @override
  State<_TodayMedsSummary> createState() => _TodayMedsSummaryState();
}

class _TodayMedsSummaryState extends State<_TodayMedsSummary> {
  List<Map<String, dynamic>> todayMeds = [];

  @override
  void initState() {
    super.initState();
    loadTodayMeds();
  }

  Future<void> loadTodayMeds() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snap = await FirebaseFirestore.instance
        .collection("meds")
        .where("patientId", isEqualTo: widget.patientId)
        .get();

    List<Map<String, dynamic>> list = [];
    for (var doc in snap.docs) {
      final data = doc.data();
      try {
        final start = (data["dateDebut"] as Timestamp).toDate();
        final end = (data["dateFin"] as Timestamp).toDate();
        final startDay = DateTime(start.year, start.month, start.day);
        final endDay = DateTime(end.year, end.month, end.day);
        if (!today.isBefore(startDay) && !today.isAfter(endDay)) {
          list.add({...data, "id": doc.id});
        }
      } catch (_) {}
    }
    setState(() => todayMeds = list);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("💊 Médicaments d'aujourd'hui",
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (todayMeds.isEmpty)
            const Text("Aucun médicament aujourd'hui",
                style: TextStyle(color: Colors.grey))
          else
            ...todayMeds.map((m) {
              Color statusColor;
              IconData statusIcon;
              switch (m["etatToday"]) {
                case "pris":
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case "pas_pris":
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.access_time;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: statusColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m["name"] ?? "",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text("⏰ ${m["time"] ?? ""}",
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(statusIcon, color: statusColor),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// Redirect helper
class _LoginRedirect extends StatelessWidget {
  const _LoginRedirect();
  @override
  Widget build(BuildContext context) {
    // Retour vers LoginPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/');
    });
    return const SizedBox();
  }
}