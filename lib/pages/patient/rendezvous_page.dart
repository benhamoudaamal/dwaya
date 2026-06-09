import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RendezVousPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final bool readOnly;

  const RendezVousPage({
    super.key,
    required this.patientId,
    required this.patientName,
    this.readOnly = false,
  });

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  String patientName = "";

  Future<void> addRdv() async {
    if (widget.readOnly) return;

    if (dateController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection("rendezvous").add({
      "patientId": widget.patientId,

      // ❤️ اسم patient
      "patientName": patientName,

      // 📅 date
      "date": dateController.text,

      // ⏰ time
      "time": timeController.text,

      // 📝 note
      "note": noteController.text,

      "createdAt": Timestamp.now(),
    });
    await sendPatientNotification(
      patientId: widget.patientId,
      title: "📅 Nouveau rendez-vous",
      body:
          "Un rendez-vous a été ajouté pour le ${dateController.text} à ${timeController.text}",
    );
    dateController.clear();

    timeController.clear();

    noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Rendez-vous ajouté ✅",
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    loadPatientName();
  }

  Future<void> loadPatientName() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.patientId)
        .get();

    if (doc.exists) {
      setState(() {
        patientName = "${doc["nom"]} ${doc["prenom"]}";
      });
    }
  }

  Future<void> showDeleteConfirm(
      BuildContext context, String id, String date, String time) async {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Confirmation"),
        content: const Text("Voulez-vous supprimer ce rendez-vous ?"),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await sendPatientNotification(
                patientId: widget.patientId,
                title: "🗑️ Rendez-vous supprimé",
                body: "Le rendez-vous du $date à $time a été supprimé",
              );

              await FirebaseFirestore.instance
                  .collection("rendezvous")
                  .doc(id)
                  .delete();

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> showEditRdvDialog(
    BuildContext context,
    String id,
    String oldDate,
    String oldNote,
  ) async {
    if (widget.readOnly) return;
    TextEditingController dateController = TextEditingController(text: oldDate);
    TextEditingController noteController = TextEditingController(text: oldNote);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ Modifier rendez-vous"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date"),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Modifier"),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("rendezvous")
                  .doc(id)
                  .update({
                "date": dateController.text,
                "note": noteController.text,
              });

              await sendPatientNotification(
                patientId: widget.patientId,
                title: "✏️ Rendez-vous modifié",
                body:
                    "Le rendez-vous a été modifié pour le ${dateController.text}",
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> sendPatientNotification({
    required String patientId,
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance.collection("notifications").add({
      "patientId": patientId,
      "title": title,
      "body": body,
      "date": Timestamp.now(),
      "patientRead": false,
      "familyRead": false,
    });
  }

  @override
  Widget build(BuildContext context) {
    print("RENDEZVOUS READONLY = ${widget.readOnly}");

    return Scaffold(
      // ❤️ FLOATING BUTTON
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.redAccent,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 25,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Ajouter Rendez-vous",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 📅 DATE
                          TextField(
                            controller: dateController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                dateController.text =
                                    "${picked.day}/${picked.month}/${picked.year}";
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "Date rendez-vous",
                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                color: Colors.red,
                              ),
                              filled: true,
                              fillColor: Colors.red.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // ⏰ HEURE
                          TextField(
                            controller: timeController,
                            decoration: InputDecoration(
                              hintText: "Heure",
                              prefixIcon: const Icon(
                                Icons.access_time,
                                color: Colors.blue,
                              ),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // 📝 NOTE
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText: "Note médicale",
                              prefixIcon: const Icon(
                                Icons.note_alt,
                                color: Colors.green,
                              ),
                              filled: true,
                              fillColor: Colors.green.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ❤️ BUTTON AJOUTER
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await addRdv();

                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.add,
                              ),
                              label: const Text(
                                "Ajouter Rendez-vous",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

      appBar: AppBar(
        title: const Text(
          "Rendez-vous 📅",
        ),
        backgroundColor: const Color(0xFFE57373),
      ),

      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher rendez-vous",
                prefixIcon: const Icon(
                  Icons.search,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📋 LISTE RDV
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("rendezvous")
                  .where(
                    "patientId",
                    isEqualTo: widget.patientId,
                  )
                  .orderBy(
                    "createdAt",
                    descending: true,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Aucun rendez-vous",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Ajoutez votre premier rendez-vous 📅",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];

                    DateTime rdvDate =
                        DateFormat("d/M/yyyy").parse(data["date"]);

                    int diff = rdvDate.difference(DateTime.now()).inDays;

                    Color cardColor;

                    if (diff <= 1) {
                      cardColor = Colors.red.shade50;
                    } else if (diff <= 3) {
                      cardColor = Colors.orange.shade50;
                    } else {
                      cardColor = Colors.green.shade50;
                    }

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 15,
                      ),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // 📅 ICON
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 15),

                          // 📝 INFOS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data["date"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "⏰ ${data["time"]}",
                                ),
                                Text(
                                  "👤 ${data["patientName"]}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  data["note"] ?? "",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!widget.readOnly)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    dateController.text = data["date"];

                                    timeController.text = data["time"];

                                    noteController.text = data["note"] ?? "";

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            left: 20,
                                            right: 20,
                                            top: 20,
                                            bottom: MediaQuery.of(context)
                                                    .viewInsets
                                                    .bottom +
                                                20,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                "Modifier Rendez-vous",
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              TextField(
                                                controller: dateController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "Date",
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: timeController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "Heure",
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: noteController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "Note",
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection("rendezvous")
                                                      .doc(docs[index].id)
                                                      .update({
                                                    "date": dateController.text,
                                                    "time": timeController.text,
                                                    "note": noteController.text,
                                                  });
                                                  await sendPatientNotification(
                                                    patientId: widget.patientId,
                                                    title:
                                                        "✏️ Rendez-vous modifié",
                                                    body:
                                                        "Le rendez-vous a été modifié pour le ${dateController.text} à ${timeController.text}",
                                                  );
                                                  Navigator.pop(context);

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          "Rendez-vous modifié ✅"),
                                                    ),
                                                  );
                                                },
                                                child:
                                                    const Text("Mettre à jour"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              if (!widget.readOnly)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(Icons.warning,
                                                color: Colors.red),
                                            SizedBox(width: 8),
                                            Text("Confirmation"),
                                          ],
                                        ),
                                        content: const Text(
                                          "Voulez-vous vraiment supprimer ce rendez-vous ?",
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
                                            ),
                                            onPressed: () async {
                                              await sendPatientNotification(
                                                patientId: widget.patientId,
                                                title:
                                                    "🗑️ Rendez-vous supprimé",
                                                body:
                                                    "Le rendez-vous du ${data["date"]} à ${data["time"]} a été supprimé",
                                              );

                                              await FirebaseFirestore.instance
                                                  .collection("rendezvous")
                                                  .doc(docs[index].id)
                                                  .delete();

                                              Navigator.pop(context);

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Rendez-vous supprimé ✅",
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              "Supprimer",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
