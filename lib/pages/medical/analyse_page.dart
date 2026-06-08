import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'chart_page.dart';
import '../../services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalysePage extends StatefulWidget {
  final bool readOnly;
  final String patientId;
  const AnalysePage({
    super.key,
    this.readOnly = false,
    required this.patientId,
  });

  @override
  State<AnalysePage> createState() => _AnalysePageState();
}

class _AnalysePageState extends State<AnalysePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String statut = "";

  int selectedSectionIndex = 0;
  File? selectedFile;
  String? selectedFileUrl;
  List<Map<String, dynamic>> allSections = [];
  Map<String, bool> analyseCheck = {};

  // ================= BASIC INFO =================
  String sectionTitle = "Paramètres anthropométriques";
  String recTitle = "Recommandations médecin";
  String analyseSectionTitle = "Analyses à faire";
  String historiqueTitle = "Historique";

  // ================= RESULTATS =================
  Map<String, Map<String, TextEditingController>> resultats = {
    "Taille": {"val": TextEditingController(), "date": TextEditingController()},
    "Tension artérielle": {
      "val": TextEditingController(),
      "date": TextEditingController()
    },
    "Température": {
      "val": TextEditingController(),
      "date": TextEditingController()
    },
    "Poids": {"val": TextEditingController(), "date": TextEditingController()},
    "IMC": {"val": TextEditingController(), "date": TextEditingController()},
  };

  // ================= ANALYSES =================
  List<Map<String, dynamic>> analysesAFaire = [
    {
      "id": "1",
      "name": "Analyse 1",
      "checked": false,
    }
  ];

  // ================= RECOMMANDATIONS =================
  List<Map<String, dynamic>> recs = [
    {"id": "1", "text": ""}
  ];

  // ================= HISTORIQUE =================
  List<String> colonnes = ["Analyse de sang", "IRM"];
  List<String> lignes = ["12/07/2025"];

  Map<String, Map<String, String>> historiqueData = {
    "12/07/2025": {
      "Analyse de sang": "",
      "IRM": "",
    }
  };

  // ================= DOCUMENTS =================
  List<Map<String, dynamic>> documents = [];

// ================= DELETE ONE RECOMMENDATION =================
  void deleteRec(int index) {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer cette recommandation ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user =
              FirebaseAuth.instance.currentUser;

              // if (user == null) return;

              if (index >= 0 && index < recs.length) {
                setState(() {
                  recs.removeAt(index);
                });
              }

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "recs": recs
                    .map((e) => {
                          "id": e["id"],
                          "text": e["text"],
                        })
                    .toList(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Recommandation supprimée",
                "message": "Le médecin a supprimé une recommandation médicale",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void confirmDeleteRecSection() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer toute la section ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              recs.clear();
              setState(() {});

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "recs": [],
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Section supprimée",
                "message":
                    "Le médecin a supprimé toute la section des recommandations médicales",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  Future<void> saveData() async {
    //final user = FirebaseAuth.instance.currentUser;
    //if (user == null) return;

    await FirebaseFirestore.instance
        .collection("analyses")
        .doc(widget.patientId)
        .set({
      "recs": recs,
      "resultats": resultats.map((k, v) => MapEntry(k, {
            "val": v["val"]?.text ?? "",
            "date": v["date"]?.text ?? "",
          })),
      "historique": {
        "title": historiqueTitle,
        "colonnes": colonnes,
        "lignes": lignes,
        "data": historiqueData,
      },
      "analysesAFaire": analysesAFaire,
      "statut": statut,
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection("notifications").add({
      "patientId": widget.patientId,
      "title": "🧪 Analyses mises à jour",
      "message": "Le médecin a effectué des modifications sur vos analyses",
      "date": Timestamp.now(),
      "patientRead": false,
      "familyRead": false,
    });
  }

  Future<void> loadData() async {
    //final user = FirebaseAuth.instance.currentUser;
    //if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("analyses")
        .doc(widget.patientId)
        .get();

    if (!doc.exists) return;

    final data = doc.data() ?? {};

    setState(() {
      // 🟢 RECOMMANDATIONS
      recs = List<Map<String, dynamic>>.from(data["recs"] ?? []);

      // 🟢 RESULTATS
      final res = data["resultats"] ?? {};
      res.forEach((k, v) {
        if (resultats[k] != null) {
          resultats[k]!["val"]!.text = v["val"] ?? "";
          resultats[k]!["date"]!.text = v["date"] ?? "";
        }
      });

      // 🟢 HISTORIQUE (IMPORTANT)
      final hist = data["historique"] ?? {};
      historiqueTitle = hist["title"] ?? historiqueTitle;
      colonnes = List<String>.from(hist["colonnes"] ?? []);
      lignes = List<String>.from(hist["lignes"] ?? []);
      historiqueData = Map<String, Map<String, String>>.from(
        (hist["data"] ?? {}).map(
          (k, v) => MapEntry(k, Map<String, String>.from(v)),
        ),
      );

      // 🟢 ANALYSES
      analysesAFaire =
          List<Map<String, dynamic>>.from(data["analysesAFaire"] ?? []);

      // 🟢 STATUT
      statut = data["statut"] ?? "";
    });
  }

  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> deleteRecSection() async {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer toute la section ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              recs.clear();
              setState(() {});

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "recs": [],
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Section recommandations supprimée",
                "message":
                    "Le médecin a supprimé toute la section des recommandations médicales",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

// ✏️ RENAME
  void renameRec() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController(text: recTitle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Renommer section"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              if (ctrl.text.isEmpty) return;

              setState(() {
                recTitle = ctrl.text;
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "recTitle": ctrl.text,
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "✏️ Section modifiée",
                "message":
                    "Le médecin a modifié le titre de la section des recommandations",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void modifyRec() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier recommandation"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: List.generate(recs.length, (i) {
              return ListTile(
                title: Text(recs[i]["text"] ?? ""),
                onTap: () {
                  final ctrl = TextEditingController(
                    text: recs[i]["text"] ?? "",
                  );

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Modifier"),
                      content: TextField(controller: ctrl),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            // final user = FirebaseAuth.instance.currentUser;
                            // if (user == null) return;

                            if (ctrl.text.trim().isEmpty) return;

                            setState(() {
                              recs[i]["text"] = ctrl.text;
                            });

                            await FirebaseFirestore.instance
                                .collection("analyses")
                                .doc(widget.patientId)
                                .set({
                              "recs": recs
                                  .map((e) => {
                                        "id": e["id"],
                                        "text": e["text"],
                                      })
                                  .toList(),
                            }, SetOptions(merge: true));
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "✏️ Recommandation modifiée",
                              "message":
                                  "Le médecin a modifié une recommandation médicale",
                              "date": Timestamp.now(),
                              "patientRead": false,
                              "familyRead": false,
                            });

                            if (!mounted) return;
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("Modifier"),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }

// ⚙️ MENU
  void showRecMenu() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await addRec();
            },
            child: const Text("Ajouter champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyRec();
            },
            child: const Text("Modifier champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renameRec();
            },
            child: const Text("Renommer section"),
          ),
        ],
      ),
    );
  }

  Future<void> addRec() async {
    if (widget.readOnly) return;

    //final user = FirebaseAuth.instance.currentUser;
    //if (user == null) return;

    final newRec = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "text": "",
    };

    setState(() {
      recs.add(newRec);
    });

    await FirebaseFirestore.instance
        .collection("analyses")
        .doc(widget.patientId)
        .set({
      "recs": recs
          .map((e) => {
                "id": e["id"],
                "text": e["text"],
              })
          .toList(),
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection("notifications").add({
      "patientId": widget.patientId,
      "title": "➕ Recommandation ajoutée",
      "message": "Le médecin a ajouté une nouvelle recommandation médicale",
      "date": Timestamp.now(),
      "patientRead": false,
      "familyRead": false,
    });
  }

  final AudioPlayer player = AudioPlayer();

  // ================= DELETE SECTION =================
  void deleteSection() async {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer toute la section ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              resultats.clear();
              setState(() {});

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "resultats": {},
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Résultats supprimés",
                "message":
                    "Le médecin a supprimé toute la section des résultats d'analyses",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteField(String key) async {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text("Supprimer $key ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              // final user = FirebaseAuth.instance.currentUser;
              // if (user == null) return;

              resultats.remove(key);
              setState(() {});

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "resultats": resultats.map((k, v) => MapEntry(k, {
                      "val": v["val"]?.text ?? "",
                      "date": v["date"]?.text ?? "",
                    })),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Résultat supprimé",
                "message":
                    "Le médecin a supprimé un résultat d'analyse médicale",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void showSectionMenu() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renameSection();
            },
            child: const Text("Renommer"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addField();
            },
            child: const Text("Ajouter champ"),
          ),
        ],
      ),
    );
  }

  void renameSection() {
    if (widget.readOnly) return;

    TextEditingController controller =
        TextEditingController(text: sectionTitle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Renommer section"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              // final user = FirebaseAuth.instance.currentUser;
              // if (user == null) return;

              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;

              setState(() {
                sectionTitle = newTitle;
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "sectionTitle": sectionTitle,
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "✏️ Section renommée",
                "message":
                    "Le médecin a modifié le nom de la section des résultats d'analyses",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  void addField() async {
    if (widget.readOnly) return;

    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter champ"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              // final user = FirebaseAuth.instance.currentUser;
//if (user == null) return;
              if (controller.text.trim().isEmpty) return;

              setState(() {
                resultats[controller.text] = {
                  "val": TextEditingController(),
                  "date": TextEditingController(),
                };
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "resultats": resultats.map((k, v) => MapEntry(k, {
                      "val": v["val"]!.text,
                      "date": v["date"]!.text,
                    })),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "➕ Résultat ajouté",
                "message":
                    "Le médecin a ajouté un nouveau champ de résultats d'analyses",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  // ================= RADIO DESIGN =================
  Widget buildRadio(String value, String text, Color color, IconData icon) {
    bool selected = statut == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: selected ? color.withOpacity(0.15) : Colors.white,
        border: Border.all(
          color: selected ? color : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Radio<String>(
              value: value,
              groupValue: statut,
              activeColor: color,
              /*onChanged: (val) async {
  setState(() {
    statut = val!;
  });
*/
              onChanged: widget.readOnly
                  ? null
                  : (val) async {
                      if (val == null) return;

                      setState(() {
                        statut = val;
                      });
                      //final user = FirebaseAuth.instance.currentUser;
                      // if (user == null) return;

                      // 🔥 SAVE TO FIREBASE
                      await FirebaseFirestore.instance
                          .collection("analyses")
                          .doc(widget.patientId)
                          .set({
                        "statut": statut,
                      }, SetOptions(merge: true));
                      await FirebaseFirestore.instance
                          .collection("notifications")
                          .add({
                        "patientId": widget.patientId,
                        "title": "🩺 Statut médical modifié",
                        "message":
                            "Votre statut médical est maintenant : $statut",
                        "date": Timestamp.now(),
                        "patientRead": false,
                        "familyRead": false,
                      });

                      // 🔊 SOUND
                      if (val == "normal") {
                        await player.play(
                          AssetSource('mixkit-clear-mouse-clicks-2997.wav'),
                        );
                      } else if (val == "surveiller") {
                        await player.play(
                          AssetSource('mixkit-clear-mouse-clicks-2997.wav'),
                        );
                      } else if (val == "alarmant") {
                        await player.play(
                          AssetSource('mixkit-clear-mouse-clicks-2997.wav'),
                        );
                      }
                    }),
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATUS =================
  Widget buildStatut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Statut",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        buildRadio("normal", "Normal", Colors.green, Icons.check_circle),
        buildRadio("surveiller", "À surveiller", Colors.orange, Icons.warning),
        buildRadio("alarmant", "Alarmant", Colors.red, Icons.error),
      ],
    );
  }

// ================= DELETE ANALYSE =================
  void deleteAnalyse(String id) {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("supprimer cette analyse?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              // if (user == null) return;

              setState(() {
                analysesAFaire.removeWhere(
                  (item) => item["id"] == id,
                );
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "analysesAFaire": analysesAFaire
                    .map((e) => {
                          "id": e["id"],
                          "name": e["name"],
                          "checked": e["checked"],
                          "value": e["controller"].text,
                        })
                    .toList(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Analyse supprimée",
                "message": "Le médecin a supprimé une analyse à effectuer",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

// 🎨 CARD DESIGN MEDICAL
  Widget medicalCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10), // ✨ مسافة بين الكروت
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

// ================= ADD ANALYSE =================

  void addAnalyse() {
    if (widget.readOnly) return;

    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter analyse"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              // final user = FirebaseAuth.instance.currentUser;
              // if (user == null) return;

              if (controller.text.trim().isEmpty) return;

              setState(() {
                analysesAFaire.add({
                  "id": DateTime.now().millisecondsSinceEpoch.toString(),
                  "name": controller.text,
                  "controller": TextEditingController(),
                  "checked": false,
                });
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "analysesAFaire": analysesAFaire
                    .map((e) => {
                          "id": e["id"],
                          "name": e["name"],
                          "checked": e["checked"],
                          "value": e["controller"].text,
                        })
                    .toList(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "➕ Analyse ajoutée",
                "message":
                    "Le médecin a ajouté une nouvelle analyse à effectuer",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void renameAnalyseSection() {
    if (widget.readOnly) return;

    TextEditingController controller = TextEditingController(
      text: analyseSectionTitle,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Renommer section"),
        content: TextField(
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              // final user = FirebaseAuth.instance.currentUser;
//if (user == null) return;

              setState(() {
                analyseSectionTitle = controller.text;
              });

              // 🔥 UPDATE FIREBASE
              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "analyseSectionTitle": analyseSectionTitle,
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "✏️ Section Analyses modifiée",
                "message":
                    "Le médecin a modifié le titre de la section des analyses à effectuer",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              Navigator.pop(context);
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  void modifyAnalyse() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier analyse"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: analysesAFaire.map((item) {
              TextEditingController controller =
                  TextEditingController(text: item["name"]);

              return ListTile(
                title: Text(item["name"]),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Nouveau nom"),
                      content: TextField(controller: controller),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            //final user = FirebaseAuth.instance.currentUser;
                            //if (user == null) return;

                            if (controller.text.trim().isEmpty) return;

                            setState(() {
                              item["name"] = controller.text;
                            });

                            await FirebaseFirestore.instance
                                .collection("analyses")
                                .doc(widget.patientId)
                                .set({
                              "analysesAFaire": analysesAFaire
                                  .map((e) => {
                                        "id": e["id"],
                                        "name": e["name"],
                                        "checked": e["checked"],
                                        "value": e["controller"].text,
                                      })
                                  .toList(),
                            }, SetOptions(merge: true));
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "✏️ Analyse modifiée",
                              "message":
                                  "Le médecin a modifié une analyse à effectuer",
                              "date": Timestamp.now(),
                              "patientRead": false,
                              "familyRead": false,
                            });
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("Modifier"),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void deleteAnalyseSection() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer toute la section ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              setState(() {
                analysesAFaire.clear();
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "analysesAFaire": [],
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Section Analyses supprimée",
                "message":
                    "Le médecin a supprimé toute la section des analyses à effectuer",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void showAnalyseMenu() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renameAnalyseSection();
            },
            child: const Text("Renommer"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addAnalyse();
            },
            child: const Text("Ajouter champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyAnalyse();
            },
            child: const Text("Modifier champ"),
          ),
        ],
      ),
    );
  }

  void addNewSection() async {
    //final user = FirebaseAuth.instance.currentUser;
    //if (user == null) return;

    final newSection = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "title": "Nouvelle section",
      "items": [],
    };

    setState(() {
      allSections.add(newSection);
    });

    await FirebaseFirestore.instance
        .collection("analyses")
        .doc(widget.patientId)
        .set({
      "sections": allSections,
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection("notifications").add({
      "patientId": widget.patientId,
      "title": "➕ Section ajoutée",
      "message": "Le médecin a ajouté une nouvelle section d'analyses",
      "date": Timestamp.now(),
      "patientRead": false,
      "familyRead": false,
    });
  }

  void showAddDocumentDialog() {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter document 📄"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await pickFile();
              },
              child: const Text("Choisir fichier"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: "Commentaire du médecin",
              ),
            ),
            const SizedBox(height: 10),
            if (selectedFile != null)
              Text(
                selectedFileUrl != null
                    ? Uri.parse(selectedFileUrl!).pathSegments.last
                    : selectedFile!.path.split('/').last,
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              selectedFile = null;
            },
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              if (selectedFile == null && selectedFileUrl == null) return;

              final newDoc = {
                "id": DateTime.now().millisecondsSinceEpoch.toString(),
                "file": selectedFileUrl ?? selectedFile!.path,
                "comment": commentController.text.trim(),
                "date": DateTime.now().toString().substring(0, 16),
              };

              setState(() {
                documents.add(newDoc);
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "documents": documents,
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "📄 Nouveau document",
                "message": "Le médecin a ajouté un nouveau document médical",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              selectedFile = null;
              selectedFileUrl = null;

              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void confirmDeleteAnalyseSection() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer toute la section Analyse ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              // 🔥 1. delete Firebase FIRST
              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "documents": [],
                "analysesAFaire": [],
                "analyseCheck": {},
                "resultats": {},
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Section Analyse supprimée",
                "message":
                    "Le médecin a supprimé toute la section des analyses et documents médicaux",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              // 🔥 2. then clear UI
              setState(() {
                documents.clear();
                analysesAFaire.clear();
                analyseCheck.clear();
                resultats.clear();
              });

              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void openDocument(String path) {
    if (path.startsWith('http')) {
      try {
        launchUrl(Uri.parse(path), mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Failed to open url: $e');
      }
    } else {
      OpenFile.open(path);
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      final path = result.files.single.path;
      if (path == null) return;

      setState(() {
        selectedFile = File(path);
        selectedFileUrl = null;
      });

      debugPrint("FILE: ${selectedFile!.path}");

      // Upload to Cloudinary
      try {
        final uploaded = await StorageService.uploadFile(File(path));
        if (uploaded != null) {
          setState(() {
            selectedFileUrl = uploaded;
          });
          debugPrint("UPLOADED: $uploaded");
        }
      } catch (e) {
        debugPrint("Upload error: $e");
      }
    }
  }

  void showHistoriqueMenu() {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options Historique"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addColonne();
            },
            child: const Text("Ajouter colonne"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addLigne();
            },
            child: const Text("Ajouter ligne"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyLigne();
            },
            child: const Text("Modifier ligne"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyColonne();
            },
            child: const Text("Modifier colonne"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renameHistorique();
            },
            child: const Text("Renommer section"),
          ),
        ],
      ),
    );
  }

  void renameHistorique() {
    if (widget.readOnly) return;

    final controller = TextEditingController(text: historiqueTitle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Renommer Historique"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              //final user = FirebaseAuth.instance.currentUser;
              // if (user == null) return;

              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;

              if (!mounted) return;

              setState(() {
                historiqueTitle = newTitle;
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "historiqueTitle": newTitle,
              }, SetOptions(merge: true));

              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "📊 Historique modifié",
                "message":
                    "Le médecin a modifié le titre de l'historique médical",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              Navigator.pop(context);
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  void modifyLigne() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier ligne"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lignes.length,
            itemBuilder: (context, i) {
              final date = lignes[i];
              final controller = TextEditingController(text: date);

              return ListTile(
                title: Text(date),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Nouvelle date"),
                      content: TextField(controller: controller),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            // final user =
                            FirebaseAuth.instance.currentUser;
                            // if (user == null) return;

                            final newDate = controller.text.trim();
                            if (newDate.isEmpty) return;

                            final data = historiqueData[date];

                            setState(() {
                              lignes[i] = newDate;

                              historiqueData.remove(date);
                              if (data != null) {
                                historiqueData[newDate] = data;
                              }
                            });

                            await FirebaseFirestore.instance
                                .collection("analyses")
                                .doc(widget.patientId)
                                .set({
                              "lignes": lignes,
                              "Data": historiqueData,
                            }, SetOptions(merge: true));
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "🧪 Analyse modifiée",
                              "message":
                                  "La date d'analyse $date a été modifiée en $newDate",
                              "date": Timestamp.now(),
                              "patientRead": false,
                              "familyRead": false,
                            });

                            Navigator.pop(context); // edit dialog
                            Navigator.pop(context); // list dialog
                          },
                          child: const Text("Modifier"),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void modifyColonne() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier colonne"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: colonnes.length,
            itemBuilder: (context, i) {
              final col = colonnes[i];
              final controller = TextEditingController(text: col);

              return ListTile(
                title: Text(col),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Nouveau nom"),
                      content: TextField(controller: controller),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            //final user =
                            FirebaseAuth.instance.currentUser;
                            // if (user == null) return;

                            final newName = controller.text.trim();
                            if (newName.isEmpty) return;

                            setState(() {
                              for (var date in lignes) {
                                final row = historiqueData[date];

                                if (row == null) continue;

                                final value = row[col] ?? "";

                                row.remove(col);
                                row[newName] = value;
                              }

                              colonnes[i] = newName;
                            });

                            await FirebaseFirestore.instance
                                .collection("analyses")
                                .doc(widget.patientId)
                                .set({
                              "colonnes": colonnes,
                              "data": historiqueData,
                            }, SetOptions(merge: true));
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "🧪 Paramètre modifié",
                              "message":
                                  "Le paramètre '$col' a été renommé en '$newName'",
                              "date": Timestamp.now(),
                              "patientRead": false,
                              "familyRead": false,
                            });

                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("Modifier"),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> deleteHistoriqueSection() async {
    if (widget.readOnly) return;

    //final user = FirebaseAuth.instance.currentUser;
    // if (user == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer toute la section ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "colonnes": [],
                "lignes": [],
                "historiqueData": {},
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Historique supprimé",
                "message":
                    "Le médecin a supprimé tout l'historique des analyses médicales",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              setState(() {
                colonnes.clear();
                lignes.clear();
                historiqueData.clear();
              });

              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  Future<void> addColonne() async {
    if (widget.readOnly) return;

    final controller = TextEditingController();
    // final user = FirebaseAuth.instance.currentUser;
    //if (user == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter colonne"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              final col = controller.text.trim();
              if (col.isEmpty) return;

              setState(() {
                colonnes.add(col);

                for (var date in lignes) {
                  historiqueData[date] ??= {};
                  historiqueData[date]![col] = "";
                }
              });

              await FirebaseFirestore.instance
                  .collection("analyses")
                  .doc(widget.patientId)
                  .set({
                "colonnes": colonnes,
                "lignes": lignes,
                "data": historiqueData,
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "➕ Paramètre ajouté",
                "message":
                    "Le médecin a ajouté un nouveau paramètre d'analyse : $col",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Future<void> addLigne() async {
    if (widget.readOnly) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    //final user = FirebaseAuth.instance.currentUser;
    //if (user == null) return;

    final date = "${picked.day}/${picked.month}/${picked.year}";

    setState(() {
      lignes.add(date);

      historiqueData[date] = {for (var col in colonnes) col: ""};
    });

    await FirebaseFirestore.instance
        .collection("analyses")
        .doc(widget.patientId)
        .set({
      "colonnes": colonnes,
      "lignes": lignes,
      "Data": historiqueData,
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection("notifications").add({
      "patientId": widget.patientId,
      "title": "📅 Date d'analyse ajoutée",
      "message": "Le médecin a ajouté une nouvelle date d'analyse : $date",
      "date": Timestamp.now(),
      "patientRead": false,
      "familyRead": false,
    });
  }
// ✏️ rename

// ⚙️ menu

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
  } // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyse 🧪"),
        centerTitle: true,
        actions: [
          // 💾 SAVE
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: widget.readOnly
                  ? null
                  : () async {
                      await saveData();

                      final now = DateTime.now();

                      await sendPatientNotification(
                        patientId: widget.patientId,
                        title: "🧪 Analyses modifiées",
                        body:
                            "Les analyses ont été mises à jour le ${now.day}/${now.month}/${now.year} à ${now.hour}:${now.minute.toString().padLeft(2, '0')}",
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Données enregistrées"),
                        ),
                      );
                    },
            ),

          // ⚙️ OPTIONS
          if (!widget.readOnly)
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              onSelected: (value) {
                if (value == "add_section") {
                  addNewSection(); // 🔥 يزيد section
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "add_section",
                  child: Text("➕ Ajouter Section"),
                ),
              ],
            ),
        ],
      ),

      // 🔥 هذا المكان الصحيح
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              onPressed: addRec, // ✅ الصحيح
              backgroundColor: Colors.green, // ✅ نفس style dossier
              child: const Icon(Icons.add),
            ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            /* body: IgnorePointer(
  ignoring: widget.readOnly,
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [*/
            // كل الكود متاعك هنا

            // ================= CARD =================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              shadowColor: Colors.blue.withOpacity(0.2),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      // ================= HEADER =================
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // 🧪 title
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.medical_services,
                                  color: Colors.blue),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  sectionTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // 🔘 buttons
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings),
                                color: Colors.grey,
                                onPressed: showSectionMenu,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.grey,
                                onPressed: deleteAnalyseSection,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

// ================= FIELDS =================

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0), // من اليمين
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey(resultats.length),
                          children: resultats.keys.map((key) {
                            return Container(
                              key: ValueKey(key),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  // VALUE + DELETE
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: resultats[key]!["val"],
                                          readOnly: widget.readOnly,
                                          onChanged: widget.readOnly
                                              ? null
                                              : (value) async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection("analyses")
                                                      .doc(widget.patientId)
                                                      .set({
                                                    "resultats": resultats.map(
                                                        (k, v) => MapEntry(k, {
                                                              "val": v["val"]
                                                                      ?.text ??
                                                                  "",
                                                              "date": v["date"]
                                                                      ?.text ??
                                                                  "",
                                                            })),
                                                  }, SetOptions(merge: true));

                                                  await sendPatientNotification(
                                                    patientId: widget.patientId,
                                                    title:
                                                        "🩺 Résultat modifié",
                                                    body:
                                                        "Le médecin a modifié le résultat : $key",
                                                  );
                                                },
                                          decoration: InputDecoration(
                                            labelText: key,
                                            prefixIcon:
                                                const Icon(Icons.monitor_heart),
                                            filled: true,
                                            fillColor: Colors.blue.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : () => deleteField(key),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // DATE PICKER
                                  TextField(
                                    controller: resultats[key]!["date"],
                                    readOnly: true,
                                    //readOnly: widget.readOnly,|| true,
                                    // enabled: !widget.readOnly,
                                    // onTap: () async {
                                    onTap: widget.readOnly
                                        ? null
                                        : () async {
                                            DateTime? pickedDate =
                                                await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );

                                            if (pickedDate != null) {
                                              String formattedDate =
                                                  "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";

                                              setState(() {
                                                resultats[key]!["date"]!.text =
                                                    formattedDate;
                                              });
                                            }
                                          },
                                    decoration: InputDecoration(
                                      labelText: "Date",
                                      prefixIcon:
                                          const Icon(Icons.calendar_today),
                                      filled: true,
                                      fillColor: Colors.blue.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 15),

// ================= STATUS =================
                      buildStatut(),
                      const SizedBox(height: 20),

//ANALYSE
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔷 HEADER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.description, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      "Analyse médicale",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!widget.readOnly)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.settings,
                                            color: Colors.grey),
                                        onPressed: renameAnalyseSection,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.grey),
                                        onPressed: confirmDeleteAnalyseSection,
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // 🔘 ADD BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Ajouter document"),
                                onPressed: widget.readOnly
                                    ? null
                                    : showAddDocumentDialog,
                              ),
                            ),

                            const SizedBox(height: 15),

                            // 📄 DOCUMENTS LIST
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: documents.length,
                              itemBuilder: (context, index) {
                                final doc = documents[index];
                                final path = doc["file"];

                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.insert_drive_file,
                                          color: Colors.blue),
                                    ),
                                    title: Text(
                                      doc["comment"] ?? "Sans commentaire",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(doc["date"] ?? ""),
                                    onTap: () {
                                      if (path == null || path.isEmpty) return;

                                      if (path.endsWith(".jpg") ||
                                          path.endsWith(".png") ||
                                          path.endsWith(".jpeg")) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => Scaffold(
                                              appBar: AppBar(
                                                  title: const Text("Image")),
                                              body: Center(
                                                child: Image.file(File(path)),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        openDocument(path);
                                      }
                                    },
                                    trailing: widget.readOnly
                                        ? null
                                        : IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.grey),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      "Confirmation"),
                                                  content: const Text(
                                                      "Supprimer ce document ?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text("Annuler"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        setState(() {
                                                          documents
                                                              .removeAt(index);
                                                        });

                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                "analyses")
                                                            .doc(widget
                                                                .patientId)
                                                            .set(
                                                                {
                                                              "documents":
                                                                  documents,
                                                            },
                                                                SetOptions(
                                                                    merge:
                                                                        true));

                                                        await sendPatientNotification(
                                                          patientId:
                                                              widget.patientId,
                                                          title:
                                                              "🗑️ Document supprimé",
                                                          body:
                                                              "Le médecin a supprimé un document d'analyse médicale.",
                                                        );

                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                          "Supprimer"),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

/*medicalCard(
  child: Padding(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    // 🧾 TITLE
    const Text(
      "📄 Analyse",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),

    // 🔘 ACTIONS
    Row(
      children: [

        // ⚙️ OPTIONS (rename)
        if (!widget.readOnly)
          IconButton(
            icon: const Icon(Icons.settings , color: Colors.grey,),
            onPressed: () {
              renameAnalyseSection();
            },
          ),

        // 🗑 DELETE SECTION
        if (!widget.readOnly)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.grey,),
            onPressed: () {
              confirmDeleteAnalyseSection();
            },
          ),
      ],
    ),
  ],
),
      

        const SizedBox(height: 10),

        ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text("Ajouter document"),
          onPressed: widget.readOnly
              ? null
              : () {
                  showAddDocumentDialog();
                },
        ),

        const SizedBox(height: 10),

        // 📌 LISTE DOCUMENTS
       ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: documents.length,
  itemBuilder: (context, index) {

    final path = documents[index]["file"];

    return ListTile(
      leading: const Icon(Icons.insert_drive_file),

      title: Text(documents[index]["comment"] ?? ""),

      subtitle: Text(documents[index]["date"] ?? ""),

              onTap: () {
                if (path == null || path.isEmpty) return;

                // 📸 image
                if (path.endsWith(".jpg") ||
                    path.endsWith(".png") ||
                    path.endsWith(".jpeg")) {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text("Image")),
                        body: Center(
                          child: Image.file(File(path)),
                        ),
                      ),
                    ),
                  );

                } else {
                  // 📄 pdf / file
                  openDocument(path);
                }
              },
              // 🗑 delete button (فقط للطبيب)
  trailing: widget.readOnly ? null : 
       IconButton(
          icon: const Icon(Icons.delete_outline , color: Colors.grey,),

          onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Confirmation"),
              content: const Text("Supprimer ce document ?"),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      documents.removeAt(index);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Supprimer"),
                ),
              ],
            ),
          );
        },
       )

    );     
          },
        ),
      ],
    ),
  ),
),*/

// ================= HISTORIQUE =================
// ================= HISTORIQUE =================
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              // HEADER
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.history,
                                          color: Colors.teal),
                                      const SizedBox(width: 8),
                                      Text(
                                        historiqueTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.settings),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : showHistoriqueMenu,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : deleteHistoriqueSection,
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // TABLE
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: [
                                    const DataColumn(label: Text("Date")),
                                    ...colonnes.map((col) => DataColumn(
                                          label: GestureDetector(
                                            onTap: widget.readOnly
                                                ? null
                                                : () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ChartPage(col,
                                                                historiqueData),
                                                      ),
                                                    );
                                                  },
                                            child: Row(
                                              children: [
                                                Text(col),

                                                // 🔥 bouton delete colonne
                                                IconButton(
                                                  icon: const Icon(Icons.close,
                                                      size: 16),
                                                  onPressed: widget.readOnly
                                                      ? null
                                                      : () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (_) =>
                                                                AlertDialog(
                                                              title: const Text(
                                                                  "Confirmation"),
                                                              content: Text(
                                                                  "Supprimer $col ?"),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child: const Text(
                                                                      "Annuler"),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    setState(
                                                                        () {
                                                                      for (var d
                                                                          in lignes) {
                                                                        historiqueData[d]!
                                                                            .remove(col);
                                                                      }
                                                                      colonnes
                                                                          .remove(
                                                                              col);
                                                                    });
                                                                    final user =
                                                                        FirebaseAuth
                                                                            .instance
                                                                            .currentUser;
                                                                    if (user !=
                                                                        null) {
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                              "analyses")
                                                                          .doc(user
                                                                              .uid)
                                                                          .set({
                                                                        "historique":
                                                                            {
                                                                          "title":
                                                                              historiqueTitle,
                                                                          "colonnes":
                                                                              colonnes,
                                                                          "lignes":
                                                                              lignes,
                                                                          "data":
                                                                              historiqueData,
                                                                        }
                                                                      }, SetOptions(merge: true));
                                                                    }
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: const Text(
                                                                      "Supprimer"),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                ),
                                              ],
                                            ),
                                          ),
                                        )),
                                  ],
                                  rows: lignes.map((date) {
                                    return DataRow(
                                      cells: [
                                        // 🔥 DATE + DELETE LIGNE
                                        DataCell(
                                          Row(
                                            children: [
                                              Expanded(child: Text(date)),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18),
                                                onPressed: widget.readOnly
                                                    ? null
                                                    : () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (_) =>
                                                              AlertDialog(
                                                            title: const Text(
                                                                "Confirmation"),
                                                            content: Text(
                                                                "Supprimer $date ?"),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context),
                                                                child: const Text(
                                                                    "Annuler"),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () async {
                                                                  setState(() {
                                                                    lignes.remove(
                                                                        date);
                                                                    historiqueData
                                                                        .remove(
                                                                            date);
                                                                  });
                                                                  final user =
                                                                      FirebaseAuth
                                                                          .instance
                                                                          .currentUser;
                                                                  if (user !=
                                                                      null) {
                                                                    await FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            "analyses")
                                                                        .doc(user
                                                                            .uid)
                                                                        .set({
                                                                      "historique":
                                                                          {
                                                                        "title":
                                                                            historiqueTitle,
                                                                        "colonnes":
                                                                            colonnes,
                                                                        "lignes":
                                                                            lignes,
                                                                        "data":
                                                                            historiqueData,
                                                                      }
                                                                    }, SetOptions(merge: true));
                                                                  }
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: const Text(
                                                                    "Supprimer"),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 🔥 cells
                                        ...colonnes.map((col) {
                                          return DataCell(
                                            TextField(
                                              controller: TextEditingController(
                                                text: historiqueData[date]
                                                        ?[col] ??
                                                    "",
                                              ),
                                              readOnly: widget.readOnly,
                                              onChanged: widget.readOnly
                                                  ? null
                                                  : (val) async {
                                                      historiqueData[date]![
                                                          col] = val;

                                                      final user = FirebaseAuth
                                                          .instance.currentUser;

                                                      if (user != null) {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                "analyses")
                                                            .doc(user.uid)
                                                            .set(
                                                                {
                                                              "historique": {
                                                                "title":
                                                                    historiqueTitle,
                                                                "colonnes":
                                                                    colonnes,
                                                                "lignes":
                                                                    lignes,
                                                                "data":
                                                                    historiqueData,
                                                              }
                                                            },
                                                                SetOptions(
                                                                    merge:
                                                                        true));
                                                        await sendPatientNotification(
                                                          patientId:
                                                              widget.patientId,
                                                          title:
                                                              "📊 Historique mis à jour",
                                                          body:
                                                              "Le médecin a modifié les données de l'historique médical.",
                                                        );
                                                      }
                                                    },
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

// ================= ANALYSES A FAIRE =================
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              // HEADER
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.science,
                                          color: Colors.purple),
                                      const SizedBox(width: 8),
                                      Text(
                                        analyseSectionTitle,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.settings),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : showAnalyseMenu,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : deleteAnalyseSection,
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),
                              // LIST
                              ...analysesAFaire.map((item) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.purple.shade50,
                                  ),
                                  child: Row(
                                    children: [
                                      // CHECK / CROIX
                                      GestureDetector(
                                        onTap: () async {
                                          if (widget.readOnly) return;

                                          final newValue =
                                              !(item["checked"] ?? false);

                                          setState(() {
                                            item["checked"] = newValue;
                                          });

                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user == null) return;

                                          await sendPatientNotification(
                                            patientId: widget.patientId,
                                            title: "🧪 Analyse mise à jour",
                                            body: newValue
                                                ? "Une analyse a été marquée comme effectuée."
                                                : "Une analyse a été marquée comme non effectuée.",
                                          );
                                          /*onTap: () async {
  bool newValue = !(analyseCheck[key] ?? false);

  setState(() {
    analyseCheck[key] = newValue;
  });*/

                                          // 🔊 sound
                                          if (newValue) {
                                            await player.play(AssetSource(
                                                'mixkit-clear-mouse-clicks-2997.wav'));
                                          } else {
                                            await player.play(AssetSource(
                                                'mixkit-clear-mouse-clicks-2997.wav'));
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: (item["checked"] ?? false)
                                                ? Colors.green.withOpacity(0.15)
                                                : Colors.red.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            transitionBuilder: (child, anim) {
                                              return ScaleTransition(
                                                  scale: anim, child: child);
                                            },
                                            child: Icon(
                                              (item["checked"] ?? false)
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              key: ValueKey(
                                                  item["checked"] ?? false),
                                              color: (item["checked"] ?? false)
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                              text: item["name"]),
                                          readOnly: widget.readOnly,
                                          enabled: !widget.readOnly,
                                          onChanged: (val) {
                                            item["name"] = val;
                                          },
                                          decoration: const InputDecoration(
                                            hintText: "Nom de l'analyse...",
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : () => deleteAnalyse(item["id"]),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 10),

                              // EXPLICATION
                              Row(
                                children: const [
                                  Icon(Icons.check, color: Colors.green),
                                  SizedBox(width: 5),
                                  Text("Fait"),
                                  SizedBox(width: 20),
                                  Icon(Icons.close, color: Colors.red),
                                  SizedBox(width: 5),
                                  Text("Pas encore fait"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔵 HEADER (WRAP = no overflow)
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 8,
                                children: [
                                  // 🧠 TITLE
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.medical_services,
                                          color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        recTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ⚙️ + 🗑️ BUTTONS
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.settings),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : showRecMenu,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.grey,
                                        onPressed: widget.readOnly
                                            ? null
                                            : confirmDeleteRecSection,
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // 📋 LIST
                              Column(
                                children: [
                                  const SizedBox(height: 10),

                                  // 🔹 CHAMPS
                                  Column(
                                    children: List.generate(
                                      recs.length,
                                      (index) {
                                        final controller =
                                            TextEditingController(
                                          text: recs[index]["text"] ?? "",
                                        );

                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 13,
                                                backgroundColor: Colors.blue,
                                                child: Text(
                                                  "${index + 1}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: TextField(
                                                  controller: controller,
                                                  readOnly: widget.readOnly,
                                                  enabled: !widget.readOnly,
                                                  onChanged: (value) {
                                                    recs[index]["text"] = value;
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText:
                                                        "Recommandation...",
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline),
                                                onPressed: widget.readOnly
                                                    ? null
                                                    : () => deleteRec(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                              const SizedBox(height: 15),

                              ...allSections.map((section) {
                                return medicalCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          section["title"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text("Contenu vide..."),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),

/*Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    // ➕ ADD SECTION
    ElevatedButton.icon(
      onPressed: widget.readOnly ? null : addRecSection,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text("Ajouter section"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // 💾 SAVE
    ElevatedButton.icon(
      onPressed: widget.readOnly ? null : saveRec,
      icon: const Icon(Icons.save),
      label: const Text("Enregistrer"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ],
),*/

                              // ✍️ TEXT

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
