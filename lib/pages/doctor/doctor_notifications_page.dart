import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key});

  @override
  State<DoctorNotificationsPage> createState() =>
      _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState
    extends State<DoctorNotificationsPage> {
Future<void> markAllAsRead() async {

  final snapshot =
      await FirebaseFirestore.instance
          .collection("doctor_notifications")
          .where("read", isEqualTo: false)
          .get();

  for (var doc in snapshot.docs) {

    await doc.reference.update({
      "read": true,
    });

  }
}
@override
void initState() {
  super.initState();

  markAllAsRead();
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("🚨 Alertes d'urgence"),
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection("doctor_notifications")
            .orderBy("date", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {

            return const Center(
              child: Text("Aucune alerte"),
            );
          }

          return ListView.builder(

            itemCount: docs.length,

            itemBuilder: (context, index) {

              final data =
                  docs[index].data()
                      as Map<String, dynamic>;
                      

final timestamp =
    data["date"] as Timestamp;

final date =
    timestamp.toDate();

             return Card(
  margin: const EdgeInsets.all(10),

  color: const Color(0xFFFFF3F3),

  elevation: 3,

  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: ListTile(
    leading: CircleAvatar(
  radius: 26,

  backgroundColor: const Color(0xFFFFE5E5),

  child: const Icon(
    Icons.warning_rounded,
    color: Colors.red,
    size: 28,
  ),
),

    title: Text(
  data["title"] ?? "",
  maxLines: 1,
  overflow: TextOverflow.ellipsis,

      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data["body"] ?? "",
        ),

        const SizedBox(height: 6),

        Container(
  margin: const EdgeInsets.only(top: 6),

  child: Text(
    "🕒 "
    "${date.day.toString().padLeft(2, '0')}/"
    "${date.month.toString().padLeft(2, '0')}/"
    "${date.year} - "
    "${date.hour.toString().padLeft(2, '0')}:"
    "${date.minute.toString().padLeft(2, '0')}",

    style: const TextStyle(
      color: Color(0xFF6B7280),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  ),
),

      ],
    ),

    trailing: ElevatedButton.icon(

  style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFFFE5E5),
  foregroundColor: Colors.red,

  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 8,
  ),

  minimumSize: const Size(90, 40),

  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),

  icon: const Icon(Icons.delete),

  label: const Text(
  "Supprimer",
  style: TextStyle(
    fontSize: 13,
  ),
),

  onPressed: () {

    showDialog(
      context: context,

      builder: (_) => AlertDialog(

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        title: const Text("Confirmation"),

        content: const Text(
          "Voulez-vous supprimer cette alerte ?",
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Annuler"),
          ),

          ElevatedButton(

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),

            onPressed: () async {

              await FirebaseFirestore.instance
                  .collection("doctor_notifications")
                  .doc(docs[index].id)
                  .delete();

              Navigator.pop(context);
            },

            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  },
),
  ),
);
   
  },
);
},
),
);
}
}
