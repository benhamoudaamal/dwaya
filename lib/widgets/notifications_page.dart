import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  final String patientId;
  final String collectionName;

  const NotificationsPage({
    super.key,
    required this.patientId,
    this.collectionName = "notifications",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collectionName == "notifications"
            ? "🔔 Alertes famille"
            : "🔔 Notifications"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(collectionName)
            .where("patientId", isEqualTo: patientId)
            //.orderBy("date", descending: true)
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
              child: Text("Aucune notification"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final n = docs[index];
              final data = n.data();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(
                    Icons.notifications,
                    color: Colors.blue,
                  ),
                  title: Text(
                    n["title"],
                  ),
                  subtitle: Text(
                    data.containsKey("message")
                        ? data["message"]
                        : (data.containsKey("body") ? data["body"] : ""),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirmation"),
                          content: const Text(
                            "Supprimer cette notification ?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annuler"),
                            ),
                            TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection(collectionName)
                                    .doc(n.id)
                                    .delete();

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Notification supprimée ✅",
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Supprimer",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
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
