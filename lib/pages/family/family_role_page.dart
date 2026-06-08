import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyRolePage extends StatefulWidget 
{
  final String patientId;

  const FamilyRolePage({
    super.key,
    required this.patientId,
  });

  @override
  State<FamilyRolePage> createState() =>
      _FamilyRolePageState();
}

class _FamilyRolePageState
    extends State<FamilyRolePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),

      appBar: AppBar(
        title: const Text("👨‍👩‍👧 Membres de famille"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("role", isEqualTo: "famille")
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Aucun membre de famille trouvé",
              ),
            );
          }

          final familles = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: familles.length,

            itemBuilder: (context, index) {

              final famille = familles[index];

              final data =
                  famille.data() as Map<String, dynamic>;

              final nom = data["nom"] ?? "";
              final prenom = data["prenom"] ?? "";
              final email = data["email"] ?? "";
              final photoUrl = data["photoUrl"] ?? "";
              final linkedPatient =
                  data["patientId"] ?? "";
              final patientName =
    data["patientName"] ?? "";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(12),

                  child: Row(
                    children: [

                      CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,

                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              "$nom $prenom",
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              email,
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              linkedPatient.isEmpty
                                  ? "Non associé"
                                  : "Déjà associé",
                              style: TextStyle(
                                color:
                                    linkedPatient.isEmpty
                                        ? Colors.orange
                                        : Colors.green,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            if (linkedPatient.isNotEmpty)
  Text(
    "Patient : $patientName",
    style: const TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    ),
  ),

if (linkedPatient.isNotEmpty)
  TextButton.icon(
    onPressed: () async {

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          "Confirmation",
        ),

        content: const Text(
          "Voulez-vous vraiment retirer ce membre de famille ?",
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Annuler"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Confirmer"),
          ),
        ],
      );
    },
  );

  if (confirm != true) return;

  await FirebaseFirestore.instance
      .collection("users")
      .doc(famille.id)
      .update({
    "patientId": "",
    "patientName": "",
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Association supprimée ✅",
      ),
    ),
  );
},
    icon: const Icon(
      Icons.delete,
      color: Colors.red,
    ),
    label: const Text(
      "Retirer",
      style: TextStyle(
        color: Colors.red,
      ),
    ),
  ),
                          ],
                        ),
                      ),

                     linkedPatient.isEmpty
    ? ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text("Ajouter"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        

          onPressed: () async {

  final patientDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(widget.patientId)
      .get();

  final nom = patientDoc["nom"] ?? "";
  final prenom = patientDoc["prenom"] ?? "";

  await FirebaseFirestore.instance
      .collection("users")
      .doc(famille.id)
      .update({

    "patientId": widget.patientId,
    "patientName": "$nom $prenom",

  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Famille associée au patient ✅",
      ),
    ),
  );


  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Famille associée au patient ✅",
      ),
    ),
  );
},
      )
    : ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check),
        label: const Text("Associé"),
      ),
                    ],
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
