import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/patient/patients_page.dart';
import '../pages/medical/types_medicaments_page.dart';
import '../pages/medical/analyse_page.dart';
import '../pages/medical/history_page.dart';
import '../pages/patient/patient_profile_page.dart';

class PatientNavBar extends StatefulWidget {
  final String patientId;
  final String patientName;
  const PatientNavBar(
      {super.key, required this.patientId, required this.patientName});

  @override
  State<PatientNavBar> createState() => _PatientNavBarState();
}

class _PatientNavBarState extends State<PatientNavBar> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PatientsPage(
          patientId: widget.patientId, patientName: widget.patientName),
      TypesMedicamentsPage(patientId: widget.patientId, readOnly: true),
      AnalysePage(patientId: widget.patientId, readOnly: true),
      HistoryPage(patientId: widget.patientId),
      PatientProfilePage(patientId: widget.patientId),
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
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Accueil",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.medication_outlined),
                activeIcon: Icon(Icons.medication),
                label: "Médicaments",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.science_outlined),
                activeIcon: Icon(Icons.science),
                label: "Analyses",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: "Historique",
              ),
              BottomNavigationBarItem(
                icon: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("notifications")
                      .where("patientId", isEqualTo: widget.patientId)
                      .where("patientRead", isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.data?.docs.length ?? 0;
                    return Stack(
                      children: [
                        const Icon(Icons.account_circle_outlined),
                        if (count > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
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
                activeIcon: const Icon(Icons.account_circle),
                label: "Profil",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
