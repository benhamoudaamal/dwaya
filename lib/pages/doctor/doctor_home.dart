import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_patient_page.dart';
import 'doctor_notifications_page.dart';
import 'doctor_rendezvous_page.dart';
import '../patient/patient_page.dart';
class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  final searchController = TextEditingController();
String searchText = "";
String doctorName="";
int todayRdvCount = 0;


  Stream<QuerySnapshot> getPatients() {
    final doctorId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "patient")
        .where("doctorIds", arrayContains: doctorId)
        .snapshots();
  }
  Future<void> loadTodayRdvCount() async {

  final snapshot = await FirebaseFirestore
      .instance
      .collection("rendezvous")
      .get();

  DateTime now = DateTime.now();

  String today =
      "${now.day}/${now.month}/${now.year}";

  int count = 0;

  for (var doc in snapshot.docs) {

    if (doc["date"] == today) {

      count++;
    }
  }

  setState(() {

    todayRdvCount = count;

  });
}
@override
void initState() {
  super.initState();
  loadDoctor();
  loadTodayRdvCount();
}
Future<void> loadDoctor() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .get();

  setState(() {
    doctorName = doc["nom"] ?? "Doctor";
  });
}
  
Future<void> removePatient(String patientId) async {

  final doctorId =
      FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance
      .collection("users")
      .doc(patientId)
      .update({

    "doctorIds":
        FieldValue.arrayRemove([doctorId])

  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Patient removed ❌"),
    ),
  );
}
Future<void> checkTomorrowRendezVous() async {
  final doctorId = FirebaseAuth.instance.currentUser!.uid;

  final snap = await FirebaseFirestore.instance
      .collectionGroup("rendezvous")
      .get();

  final tomorrow = DateTime.now().add(const Duration(days: 1));

  for (var doc in snap.docs) {
    final data = doc.data();

    final date = data["date"]; // لازم يكون format واضح

    final patientId = doc.reference.parent.parent!.id;

    if (date == "tomorrow") {
      // 🔔 notification
      print("Rendez-vous demain avec patient $patientId");
    }
  }
}
Future<int> getPatientsCount() async {
  final doctorId = FirebaseAuth.instance.currentUser!.uid;

  final snap = await FirebaseFirestore.instance
      .collection("users")
      .where("role", isEqualTo: "patient")
      .where("doctorIds", arrayContains: doctorId)
      .get();

  return snap.docs.length;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  surfaceTintColor: Colors.transparent,
  title: Column(
  children: [
    Text(
  "👨‍⚕️ Dr. $doctorName",
  style: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF22304A),
  ),
),

const Text(
  "Bienvenue sur Dwaya 🩺",
  style: TextStyle(
    fontSize: 12,
    color: Color(0xFF4A90E2),
  ),
),
  ],
),


  actions: [

  IconButton(
    icon: const Icon(
      Icons.notifications_none,
      color: Colors.redAccent,
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorNotificationsPage(),
        ),
      );
    },
  ),

  IconButton(
    icon: const Icon(Icons.add),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddPatientPage(),
        ),
      );
    },
  ),

],
),

      
      body: SingleChildScrollView(
        child: Column(
  children: [


    Padding(

  padding: const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 15,
  ),

  child: Row(

    children: [

      Expanded(

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              "Bonjour Dr. $doctorName 👋",

              style: const TextStyle(

                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Bienvenue dans votre espace médical",

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),

      
      
    ],
  ),
),
   Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 10,
  ),
  child: Row(
    children: [

      // 👥 Patients
      Expanded(
        child: FutureBuilder<int>(
          future: getPatientsCount(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const SizedBox();
            }

            return Container(
              padding: const EdgeInsets.symmetric(
  vertical: 25,
),

              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),

                borderRadius: BorderRadius.circular(25),

                border: Border.all(
                  color: const Color(0xFFE3F2FD),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                  ),
                ],
              ),

              child: Column(
                children: [

                  const Icon(
  Icons.people,
  color: Color(0xFF5B9BE6),
  size: 35,
),

                  const SizedBox(height: 10),

                  Text(
                    "${snapshot.data}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Text(
                    "Patients",
                  ),
                ],
              ),
            );
          },
        ),
      ),

      const SizedBox(width: 12),

      // 📅 RDV
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),

            borderRadius: BorderRadius.circular(25),

            border: Border.all(
              color: const Color(0xFFE3F2FD),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
              ),
            ],
          ),

          child: Column(
            children: [

              const Icon(
                Icons.calendar_month,
                color: Colors.red,
                size: 35,
              ),

              const SizedBox(height: 10),

              Text(
                todayRdvCount.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                "RDV",
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),


GestureDetector(

  onTap: () {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const DoctorRendezVousPage(),
      ),
    );
  },

  child: Container(

    margin: const EdgeInsets.symmetric(
      horizontal: 15,
      vertical: 10,
    ),

   // padding: const EdgeInsets.all(18),
   padding: const EdgeInsets.symmetric(
  horizontal: 18,
  vertical: 14,
),

    decoration: BoxDecoration(
gradient: const LinearGradient(
  colors: [
    Color(0xFF5B9BE6),
    Color(0xFF5B9BE6),
  ],
),
    borderRadius:
          BorderRadius.circular(20),

      boxShadow: [
        BoxShadow(
  color: const Color(0xFF4A90E2).withOpacity(0.3),
  blurRadius: 10,
),
      ],
    ),

    child: Row(
      children: [

        const Icon(
          Icons.calendar_month,
          color: Colors.white,
          size: 28,
        ),

        const SizedBox(width: 15),

        const Expanded(
          child: Text(

            "Liste de Rendez-vous",

            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
        ),
      ],
    ),
  ),
),


const SizedBox(height: 20),

const Padding(
  padding: EdgeInsets.symmetric(
    horizontal: 15,
  ),

  child: Align(
    alignment: Alignment.centerLeft,

    child: Text(
      "Liste des patients",

      style: const TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Color(0xFF22304A),
),
    ),
  ),
),

const SizedBox(height: 10),

StreamBuilder<QuerySnapshot>(

  stream: FirebaseFirestore.instance
      .collection("rendezvous")
      .snapshots(),

  builder: (context, snapshot) {

    if (!snapshot.hasData) {

      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    DateTime now = DateTime.now();

    String today =
        "${now.day}/${now.month}/${now.year}";

    final rdvs =
        snapshot.data!.docs.where((doc) {

      return doc["date"] == today;

    }).toList();

    if (rdvs.isEmpty) {

      return const Center(
        child: Text(
          "Aucun rendez-vous aujourd’hui",
        ),
      );
    }

    return Column(

      children: rdvs.map((doc) {

        final data =
            doc.data()
                as Map<String, dynamic>;

        return Container(

  margin: const EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 10,
  ),

  padding: const EdgeInsets.all(20),

  decoration: BoxDecoration(

    color: Colors.white,

    borderRadius: BorderRadius.circular(28),

    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  ),

  child: Column(

    children: [

      Row(
        children: [

          // 👤 AVATAR
          CircleAvatar(
            radius: 28,
            backgroundColor:
                Colors.blue.shade50,

            child: const Icon(
              Icons.person,
              color: Colors.blue,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          // ❤️ INFOS
          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  data["patientName"] ?? "",

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [

                    const Icon(
                      Icons.access_time,
                      color: Colors.red,
                      size: 18,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      data["time"] ?? "",
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [

                    const Icon(
                      Icons.note,
                      color: Colors.orange,
                      size: 18,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        data["note"] ?? "",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

      // ❤️ BUTTONS
      Row(
        children: [

          Expanded(
            child: ElevatedButton(

              onPressed: () async {

                await FirebaseFirestore
                    .instance
                    .collection("rendezvous")
                    .doc(doc.id)
                    .update({

                  "etat": "fait",

                });
              },

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    data["etat"] == "fait"
                        ? Colors.green
                        : Colors.green.shade50,

                foregroundColor:
                    data["etat"] == "fait"
                        ? Colors.white
                        : Colors.green,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),

              child: const Text(
                "Fait",
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(

              onPressed: () async {

                await FirebaseFirestore
                    .instance
                    .collection("rendezvous")
                    .doc(doc.id)
                    .update({

                  "etat": "pas_fait",

                });
              },

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    data["etat"] == "pas_fait"
                        ? Colors.red
                        : Colors.red.shade50,

                foregroundColor:
                    data["etat"] == "pas_fait"
                        ? Colors.white
                        : Colors.red,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),

              child: const Text(
                "Pas fait",
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
      }).toList(),
    );
  },
),
    Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Rechercher un patient...",
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(
  vertical: 18,
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
    width: 1.5,
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
          setState(() {
            searchText = value.toLowerCase();
          });
        },
      ),
    ),

    SizedBox(
      height: 400,
   child: StreamBuilder<QuerySnapshot>(
    stream: getPatients(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final patients = snapshot.data!.docs;

      final filteredPatients = patients.where((p) {

        final nom =
            (p["nom"] ?? "").toString().toLowerCase();

        final email =
            (p["email"] ?? "").toString().toLowerCase();

        return nom.contains(searchText) ||
               email.contains(searchText);

      }).toList();

      if (filteredPatients.isEmpty) {
        return const Center(
          child: Text("No patients found 😢"),
        );
      }

      return ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {

          final p = filteredPatients[index];

         return Card(
  color: const Color(0xFFF8FBFF),
  elevation: 4,
  shadowColor: Colors.black12,

  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: const BorderSide(
      color: Color(0xFFE3F2FD),
    ),
  ),

  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 10,
),
           leading: CircleAvatar(
  radius: 24,
  backgroundColor: const Color(0xFFEFF6FF),
  child: const Icon(
    Icons.person,
    color: Color(0xFF4A90E2),
    size: 26,
  ),
),
            title: Text(
  p["nom"] ?? "",
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

           subtitle: Text(
  p["email"] ?? "",
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: Colors.grey.shade600,
  ),
),

           trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [

    IconButton(
      icon: const Icon(
        Icons.delete,
        color: Color(0xFFE57373),
      ),

      onPressed: () {

  showDialog(
    context: context,

    builder: (_) => AlertDialog(
      title: const Text("Confirmation"),
      content: const Text("Supprimer ce patient ?"),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Annuler"),
        ),

        TextButton(
          onPressed: () async {

            Navigator.pop(context);

            await removePatient(p.id);

          },
          child: const Text("Supprimer"),
        ),

      ],
    ),
  );
},
    ),

   const Icon(
  Icons.arrow_forward_ios,
  size: 18,
  color: Color(0xFF4A90E2),
),

  ],
),

            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientPage(
                    patientName: p["nom"],
                    patientId: p.id,
                    readOnly: false,
                  ),
                ),
              );

            },
  ),
          );
        },
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

