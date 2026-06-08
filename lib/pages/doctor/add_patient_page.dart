import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patient/patient_page.dart';
class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final searchController = TextEditingController();
  List<QueryDocumentSnapshot> results = [];
  bool isLoading = false;
  String doctorId = FirebaseAuth.instance.currentUser!.uid;
  List<String> addedPatients = [];

  Future<void> loadAddedPatients() async {
  final snap = await FirebaseFirestore.instance
      .collection("users")
      .where("doctorIds", arrayContains: doctorId)
      .get();

  setState(() {
    addedPatients = snap.docs.map((e) => e.id).toList();
  });
}
  // 🔍 SEARCH PATIENT
  Future<void> searchPatient(String value) async {
    setState(() => isLoading = true);

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "patient")
        .get();

    final valueLower = value.toLowerCase();

  results = snap.docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;

    final email = (data["email"] ?? "").toString().toLowerCase();
    final nom = (data["nom"] ?? "").toString().toLowerCase();

    return email.contains(valueLower) || nom.contains(valueLower);
  }).toList();

  setState(() => isLoading = false);
}

  // ➕ ADD PATIENT TO DOCTOR
  Future<void> addPatient(String patientId) async {
  if (addedPatients.contains(patientId)) return;

  try {

    await FirebaseFirestore.instance
        .collection("users")
        .doc(patientId)
        .set({
      "doctorIds": FieldValue.arrayUnion([doctorId])
    }, SetOptions(merge: true));

    setState(() {
      addedPatients.add(patientId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Patient ajouté ✅"),
      ),
    );

  } catch (e) {

    print("ERROR ADD PATIENT: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur: $e"),
      ),
    );
  }
}
  @override
void initState() {
  super.initState();
   loadAddedPatients();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FD),
      appBar: AppBar(
  backgroundColor: const Color(0xFFF8FBFF),
  elevation: 0,
  surfaceTintColor: Colors.transparent,

  title: const Text(
    "Ajouter un patient",
    style: TextStyle(
      color: Color(0xFF22304A),
      fontWeight: FontWeight.bold,
    ),
  ),
),

      body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFEAF6FF),
        Color(0xFFD6ECFF),
        Color(0xFFC8E6FF),
      ],
    ),
  ),

  child: Padding(
    padding: const EdgeInsets.all(16),

    child: Column(
          children: [

            // 🔍 SEARCH BOX
            TextField(
              controller: searchController,
              decoration: InputDecoration(
  hintText: "Rechercher un patient...",
  prefixIcon: const Icon(Icons.search),
contentPadding: const EdgeInsets.symmetric(
  vertical: 14,
),
  filled: true,
  fillColor: Colors.white,

  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide.none,
  ),

  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(
      color: Color(0xFFE3F2FD),
    ),
  ),

  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(
      color: Color(0xFF4A90E2),
      width: 2,
    ),
  ),
),
              onChanged: (value) {
                searchPatient(value);
              },
            ),

            const SizedBox(height: 20),

            // 🔄 LOADING
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
              if (!isLoading && results.isEmpty)
  const Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [

      Icon(
        Icons.person_search,
        size: 80,
        color: Color(0xFF4A90E2),
      ),

      SizedBox(height: 15),

      Text(
        "Aucun patient trouvé",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF22304A),
        ),
      ),

      SizedBox(height: 8),

      Text(
        "Recherchez par nom ou email",
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
    ],
  ),
),

            // 📋 RESULTS
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final data = results[index].data() as Map<String, dynamic>;

                  return Card(
  elevation: 3,
  color: Colors.white,

  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),

  child: ListTile(
                     leading: CircleAvatar(
  radius: 24,
  backgroundColor: const Color(0xFFEFF6FF),

  child: const Icon(
    Icons.person,
    color: Color(0xFF4A90E2),
  ),
),
                      title: Text(data["nom"] ?? ""),
                      subtitle: Text(data["email"] ?? ""),

                      // ➕ ADD BUTTON
                      
                    trailing: ElevatedButton(

  style: ElevatedButton.styleFrom(
    backgroundColor:
    addedPatients.contains(results[index].id)
        ? const Color(0xFF4CAF50)
        : const Color(0xFF4A90E2),

    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFF4CAF50),
disabledForegroundColor: Colors.white,

    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  onPressed: () async {

  if (addedPatients.contains(results[index].id)) {
    return;
  }

  await addPatient(results[index].id);
},
  child: Text(
    addedPatients.contains(results[index].id)
        ? "Déjà ajouté"
        : "Ajouter",
  ),
),


                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      ),
    );
  }
}
