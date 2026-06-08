import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'analyse_page.dart';
import 'types_medicaments_page.dart';
import '../../services/storage_service.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

class DossierMedicalPage extends StatefulWidget {
  final String patientId;
  final bool readOnly;
  const DossierMedicalPage({
    super.key,
    this.readOnly = false,
    required this.patientId,
  });

  @override
  State<DossierMedicalPage> createState() => _DossierMedicalPageState();
}

class _DossierMedicalPageState extends State<DossierMedicalPage> {
  // 👈 هنا بالضبط
  double uploadProgress = 0;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  String sectionTitle = "Information personnelle";

  Map<String, TextEditingController> fields = {
    "Nom": TextEditingController(),
    "Prénom": TextEditingController(),
    "Âge": TextEditingController(),
    "Sexe": TextEditingController(text: "Homme"),
    "Groupe sanguin": TextEditingController(text: "A+"),
  };

  List<String> sexes = ["Homme", "Femme"];
  List<String> groupes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];
  String antecedentTitle = "Antécédents médicaux";

  Map<String, TextEditingController> antecedents = {
    "Maladies": TextEditingController(),
    "Opérations": TextEditingController(),
    "Héréditaires": TextEditingController(),
  };
  String traitementTitle = "Traitement";

  Map<String, TextEditingController> traitements = {
    "Traitement 1": TextEditingController(),
  };
  String allergiesTitle = "Allergies";

  Map<String, TextEditingController> allergies = {
    "Allergie 1": TextEditingController(),
  };
  String analyseTitle = "Analyse";
  String medicamentTitle = "Médicaments";

  List<Map<String, dynamic>> medicalFiles = [];
  String contactTitle = "Contact d’urgence";

  List<Map<String, dynamic>> contactFields = [
    {
      "label": "Nom",
      "controller": TextEditingController(),
    },
    {
      "label": "Numéro",
      "controller": TextEditingController(),
    },
    {
      "label": "Relation",
      "controller": TextEditingController(),
    },
  ];
  List<Map<String, dynamic>> historiqueFields = [
    {
      "label": "Nom du docteur",
      "controller": TextEditingController(),
    },
    {
      "label": "Nom de l'hôpital",
      "controller": TextEditingController(),
    },
    {
      "label": "Date",
      "controller": TextEditingController(),
    },
  ];

  String historiqueTitle = "Historique médical";
  List<Map<String, dynamic>> dynamicSections = [];
  Future<void> deleteAllData() async {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer tout le dossier médical ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) return;

              try {
                // 🔥 DELETE FROM FIREBASE (FIXED)
                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .delete();
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "🗑️ Dossier médical supprimé",
                  "message": "Le médecin a supprimé tout le dossier médical.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });

                // 🧹 RESET UI
                setState(() {
                  fields.forEach((_, c) => c.clear());

                  antecedents.forEach((_, c) => c.clear());
                  traitements.forEach((_, c) => c.clear());
                  allergies.forEach((_, c) => c.clear());

                  dynamicSections.clear();

                  for (var c in contactFields) {
                    c.clear();
                  }

                  for (var c in historiqueFields) {
                    c.clear();
                  }
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Dossier supprimé ❌"),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur: $e"),
                  ),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteField(String key) {
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
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;

                //if (uid == null) return;
                final patientId = widget.patientId;

                // 🔥 DELETE FROM FIREBASE (FIXED COLLECTION)
                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "info.$key": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "📁 Dossier médical modifié",
                  "message": "Le médecin a supprimé le champ : $key",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });

                // 🔥 UPDATE UI
                setState(() {
                  fields.remove(key);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Champ supprimé ✅"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  //MT3 ANTECEDENT
  void deleteAntecedentField(String key) {
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
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "antecedents.$key": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "📁 Dossier médical modifié",
                  "message":
                      "Le médecin a supprimé un antécédent médical : $key",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });

                setState(() {
                  antecedents.remove(key);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Antécédent supprimé ✅"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteTraitement(String key) {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer ce traitement ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "traitements.$key": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "💊 Traitement supprimé",
                  "message": "Le médecin a supprimé un traitement : $key",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });

                setState(() {
                  traitements.remove(key);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Traitement supprimé ✅"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteAllergy(String key) {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer cette allergie ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "allergies.$key": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "⚠️ Allergie supprimée",
                  "message": "Le médecin a supprimé une allergie : $key",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });

                setState(() {
                  allergies.remove(key);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Allergie supprimée ✅"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteSection() {
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
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "info": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "📁 Dossier médical modifié",
                  "message":
                      "Le médecin a supprimé une section du dossier médical.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });
                setState(() {
                  fields.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Section supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteAntecedentSection() {
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
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "antecedents": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "🗑️ Antécédents supprimés",
                  "message":
                      "Le médecin a supprimé toute la section des antécédents médicaux.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });
                setState(() {
                  antecedents.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Section antecedents supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteTraitementSection() {
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
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "traitements": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "💊 Traitements supprimés",
                  "message":
                      "Le médecin a supprimé toute la section des traitements.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });
                setState(() {
                  traitements.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Section traitements supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteAllergySection() async {
    if (widget.readOnly) return;

    //final uid = FirebaseAuth.instance.currentUser?.uid;
    //if (uid == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer toute la section allergies ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "allergies": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "⚠️ Allergies supprimées",
                  "message":
                      "Le médecin a supprimé toute la section des allergies.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });
                setState(() {
                  allergies.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Section allergies supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteAnalyseCard() async {
    if (widget.readOnly) return;

    //final uid = FirebaseAuth.instance.currentUser?.uid;
    //if (uid == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer la section Analyse ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "analyseTitle": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "🧪 Analyse supprimée",
                  "message": "Le médecin a supprimé la section Analyse.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });
                setState(() {
                  analyseTitle = "";
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Analyse supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

// 🗑️ DELETE MEDICAMENT SECTION
  void deleteMedicamentCard() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer la section Médicaments ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "medicaments": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "💊 Médicaments supprimés",
                  "message": "Le médecin a supprimé la section Médicaments.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });
                setState(() {
                  medicamentTitle = "";
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Section médicaments supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

// 🗑️ DELETE CONTACT SECTION
  void deleteContactSection() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer la section Contact ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                //final uid = FirebaseAuth.instance.currentUser?.uid;
                //if (uid == null) return;

                // 🔥 DELETE FROM SAME COLLECTION
                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({"contact": []});
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "📞 Contact supprimé",
                  "message": "Le médecin a supprimé la section Contact.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });

                // 🧹 CLEAR STATE PROPERLY
                setState(() {
                  for (var field in contactFields) {
                    field["controller"].dispose();
                  }
                  contactFields.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Section contact supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteHistoriqueSection() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer la section Historique ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              //final uid = FirebaseAuth.instance.currentUser?.uid;
              //if (uid == null) return;

              try {
                // 🔥 IMPORTANT: same collection
                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "historique": FieldValue.delete(),
                  "historiqueTitle": FieldValue.delete(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "📜 Historique supprimé",
                  "message": "Le médecin a supprimé la section Historique.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });

                setState(() {
                  historiqueTitle = "";

                  for (var item in historiqueFields) {
                    item["controller"].dispose();
                  }

                  historiqueFields.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Section historique supprimée ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteFieldFromSection(int sectionIndex, int fieldIndex) {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer ce champ ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // final uid = FirebaseAuth.instance.currentUser?.uid;
              //if (uid == null) return;

              try {
                setState(() {
                  // 🧹 dispose controller
                  dynamicSections[sectionIndex]["fields"][fieldIndex].dispose();

                  dynamicSections[sectionIndex]["fields"].removeAt(fieldIndex);
                });

                await FirebaseFirestore.instance
                    .collection("dossiersMedicaux")
                    .doc(widget.patientId)
                    .update({
                  "dynamicSections": dynamicSections.map((section) {
                    return {
                      "title": section["title"],
                      "fields": (section["fields"] as List)
                          .map((c) => c.text)
                          .toList(),
                    };
                  }).toList(),
                });
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                  "patientId": widget.patientId,
                  "title": "📝 Champ supprimé",
                  "message":
                      "Le médecin a supprimé un champ d'une section personnalisée du dossier médical.",
                  "date": Timestamp.now(),
                  "patientRead": false,
                  "familyRead": false,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Champ supprimé ❌"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e")),
                );
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void deleteDynamicSection(int index) {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer cette section ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              setState(() {
                for (var c in dynamicSections[index]["fields"]) {
                  c.dispose();
                }

                dynamicSections.removeAt(index);
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .update({
                "dynamicSections": dynamicSections.map((section) {
                  return {
                    "title": section["title"],
                    "fields":
                        (section["fields"] as List).map((c) => c.text).toList(),
                  };
                }).toList(),
              });
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "📂 Section supprimée",
                "message":
                    "Le médecin a supprimé une section du dossier médical.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Section supprimée ❌"),
                ),
              );
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void addField() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter champ"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final key = ctrl.text.trim();
              if (key.isEmpty) return;

              Navigator.pop(context);

              //final user = FirebaseAuth.instance.currentUser;
              //if (user == null) return;

              setState(() {
                fields[key] = TextEditingController();
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "fields": {
                  for (var entry in fields.entries) entry.key: entry.value.text
                },
                "updatedAt": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "➕ Nouveau champ",
                "message": "Le médecin a ajouté un nouveau champ : $key",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void addAntecedentField() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter champ"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final key = ctrl.text.trim();
              if (key.isEmpty) return;

              Navigator.pop(context);

              //final uid = FirebaseAuth.instance.currentUser!.uid;

              setState(() {
                antecedents[key] = TextEditingController();
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "antecedents": {
                  for (var entry in antecedents.entries)
                    entry.key: entry.value.text
                },
                "updatedAt": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "➕ Antécédent ajouté",
                "message":
                    "Le médecin a ajouté un nouvel antécédent médical : $key",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void addTraitement() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter traitement"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final key = ctrl.text.trim();
              if (key.isEmpty) return;

              Navigator.pop(context);

              //final uid = FirebaseAuth.instance.currentUser!.uid;

              setState(() {
                traitements[key] = TextEditingController();
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "traitements": {
                  for (var e in traitements.entries) e.key: e.value.text
                }
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "💊 Traitement ajouté",
                "message": "Le médecin a ajouté un nouveau traitement : $key",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void addAllergy() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter allergie"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final key = ctrl.text.trim();
              if (key.isEmpty) return;

              Navigator.pop(context);

              //final uid = FirebaseAuth.instance.currentUser!.uid;

              setState(() {
                allergies[key] = TextEditingController();
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "allergies": {
                  for (var e in allergies.entries) e.key: e.value.text
                }
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "⚠️ Allergie ajoutée",
                "message": "Le médecin a ajouté une nouvelle allergie : $key",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

/*void addAllergy() {
  if (widget.readOnly) return;

  TextEditingController ctrl = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Ajouter allergie"),
      content: TextField(controller: ctrl),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        TextButton(
          onPressed: () async{
            if (ctrl.text.isEmpty) return;

            setState(() {
              allergies[ctrl.text] = TextEditingController();
            });
             await saveAllData();
            Navigator.pop(context);
          },
          child: const Text("Ajouter"),
        ),
      ],
    ),
  );
}*/
//SUPP ET ENREG add new section
/*void addNewSection() {
  if (widget.readOnly) return ;
  TextEditingController ctrl = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Nouvelle section"),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          hintText: "Nom de la section",
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Annuler"),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text("Ajouter"),
          onPressed: () {

            setState(() {
              dynamicSections.add({
                "title": ctrl.text,
                "fields": <String>[""]
                ],
              });
            });
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}*/
  void addNewSection() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nouvelle section"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: "Nom de la section",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Ajouter"),
            onPressed: () async {
              final title = ctrl.text.trim();
              if (title.isEmpty) return;

              Navigator.pop(context);

              //final uid = FirebaseAuth.instance.currentUser!.uid;

              final newSection = {
                "title": title,
                "fields": [""], // يبدأ ب champ واحد
              };

              setState(() {
                dynamicSections.add(newSection);
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "dynamicSections": dynamicSections,
                "updatedAt": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "📂 Nouvelle section",
                "message": "Le médecin a ajouté une nouvelle section : $title",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
            },
          ),
        ],
      ),
    );
  }

  void confirmDeleteDossier() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer tout le dossier médical ?"),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Supprimer"),
            onPressed: () async {
              Navigator.pop(context);

              //final uid = FirebaseAuth.instance.currentUser!.uid;

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .delete();
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🗑️ Dossier supprimé",
                "message": "Le médecin a supprimé tout le dossier médical.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              setState(() {
                fields.clear();
                historiqueFields.clear();
                dynamicSections.clear();
                antecedents.clear();
                traitements.clear();
                allergies.clear();
                contactFields.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Dossier supprimé ❌"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

// MODIFIER INFO PERS
  void modifyField() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier champ"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: fields.keys.map((oldKey) {
              return ListTile(
                title: Text(oldKey),
                onTap: () {
                  TextEditingController ctrl =
                      TextEditingController(text: oldKey);

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Nouveau nom"),
                      content: TextField(controller: ctrl),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final newKey = ctrl.text.trim();
                            if (newKey.isEmpty) return;
                            if (fields.containsKey(newKey)) return;

                            //final uid = FirebaseAuth.instance.currentUser!.uid;

                            setState(() {
                              final controller = fields[oldKey];

                              fields.remove(oldKey);

                              if (controller != null) {
                                fields[newKey] = controller;
                              }
                            });

                            await FirebaseFirestore.instance
                                .collection("dossiersMedicaux")
                                .doc(widget.patientId)
                                .set({
                              "fields": {
                                for (var e in fields.entries)
                                  e.key: e.value.text
                              }
                            }, SetOptions(merge: true));
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "✏️ Information modifiée",
                              "message":
                                  "Le médecin a renommé '$oldKey' en '$newKey'.",
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

  void modifyAntecedentField() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier champ"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: antecedents.keys.map((oldKey) {
              return ListTile(
                title: Text(oldKey),
                onTap: () {
                  TextEditingController ctrl =
                      TextEditingController(text: oldKey);

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Nouveau nom"),
                      content: TextField(controller: ctrl),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final newKey = ctrl.text.trim();
                            if (newKey.isEmpty) return;
                            if (antecedents.containsKey(newKey)) return;

                            // final uid = FirebaseAuth.instance.currentUser!.uid;

                            setState(() {
                              final controller = antecedents[oldKey];

                              antecedents.remove(oldKey);

                              if (controller != null) {
                                antecedents[newKey] = controller;
                              }
                            });

                            await FirebaseFirestore.instance
                                .collection("dossiersMedicaux")
                                .doc(widget.patientId)
                                .set({
                              "antecedents": {
                                for (var e in antecedents.entries)
                                  e.key: e.value.text
                              }
                            }, SetOptions(merge: true));
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "✏️ Antécédent modifié",
                              "message":
                                  "Le médecin a renommé l'antécédent '$oldKey' en '$newKey'.",
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

//MODIFIER TRAITEMENT
  void modifyTraitement() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier traitement"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: traitements.keys.map((oldKey) {
              return ListTile(
                title: Text(oldKey),
                onTap: () {
                  TextEditingController ctrl =
                      TextEditingController(text: oldKey);

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Nouveau nom"),
                      content: TextField(controller: ctrl),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final newKey = ctrl.text.trim();
                            if (newKey.isEmpty) return;
                            if (traitements.containsKey(newKey)) return;

                            setState(() {
                              final controller = traitements[oldKey];

                              traitements.remove(oldKey);

                              if (controller != null) {
                                traitements[newKey] = controller;
                              }
                            });

                            await saveAllData(); // 🔥 clean save
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "💊 Traitement modifié",
                              "message":
                                  "Le médecin a renommé le traitement '$oldKey' en '$newKey'.",
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

  void modifyAllergy() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier allergie"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: allergies.keys.map((oldKey) {
              return ListTile(
                title: Text(oldKey),
                onTap: () {
                  TextEditingController ctrl =
                      TextEditingController(text: oldKey);

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Nouveau nom"),
                      content: TextField(controller: ctrl),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final newKey = ctrl.text.trim();
                            if (newKey.isEmpty) return;
                            if (allergies.containsKey(newKey)) return;

                            setState(() {
                              final controller = allergies[oldKey];

                              allergies.remove(oldKey);

                              if (controller != null) {
                                allergies[newKey] = controller;
                              }
                            });

                            await saveAllData(); // 🔥 clean save
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                              "patientId": widget.patientId,
                              "title": "⚠️ Allergie modifiée",
                              "message":
                                  "Le médecin a renommé l'allergie '$oldKey' en '$newKey'.",
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

  // ✏️ RENAME INFO PER
  void renameSection() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController(text: sectionTitle);

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

              final newTitle = ctrl.text.trim();
              if (newTitle.isEmpty) return;

              setState(() {
                sectionTitle = newTitle;
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "sectionTitle": sectionTitle,
                "updatedAt": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "✏️ Section renommée",
                "message":
                    "Le médecin a renommé la section '$sectionTitle' en '$newTitle'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void renameAntecedentSection() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController(text: antecedentTitle);

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
              final oldTitle = antecedentTitle;
              final newTitle = ctrl.text.trim();

              if (newTitle.isEmpty) return;

              setState(() {
                antecedentTitle = newTitle;
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "antecedentTitle": antecedentTitle,
                "updatedAt": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "✏️ Antécédents modifiés",
                "message":
                    "Le médecin a renommé la section '$oldTitle' en '$newTitle'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

//RENAME TRAITEMENT
  void renameTraitementSection() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController(text: traitementTitle);

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
              final oldTitle = traitementTitle;
              final newTitle = ctrl.text.trim();
              if (newTitle.isEmpty) return;

              setState(() {
                traitementTitle = newTitle;
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "traitementTitle": traitementTitle,
                "updatedAt": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "💊 Traitements modifiés",
                "message":
                    "Le médecin a renommé la section '$oldTitle' en '$newTitle'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void renameAllergySection() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController(text: allergiesTitle);

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
              final oldTitle = allergiesTitle;
              final newTitle = ctrl.text.trim();
              if (newTitle.isEmpty) return;

              setState(() {
                allergiesTitle = newTitle;
              });

              await FirebaseFirestore.instance
                  .collection("dossiersMedicaux")
                  .doc(widget.patientId)
                  .set({
                "allergiesTitle": allergiesTitle,
                "updatedAt": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "⚠️ Allergies modifiées",
                "message":
                    "Le médecin a renommé la section '$oldTitle' en '$newTitle'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

//RENAME ANALYSE
  void renameAnalyseCard() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController(text: analyseTitle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier section"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final oldTitle = analyseTitle;
              final newTitle = ctrl.text.trim();
              if (newTitle.isEmpty) return;

              setState(() {
                analyseTitle = newTitle;
              });

              await saveAllData();
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "🧪 Analyse modifiée",
                "message":
                    "Le médecin a renommé la section '$oldTitle' en '$newTitle'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });

              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void renameMedicamentCard() {
    if (widget.readOnly) return;

    TextEditingController ctrl = TextEditingController(text: medicamentTitle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier section"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final oldTitle = medicamentTitle;
              final newTitle = ctrl.text.trim();
              if (newTitle.isEmpty) return;

              setState(() {
                medicamentTitle = newTitle;
              });

              await saveAllData();
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "💊 Médicaments modifiés",
                "message":
                    "Le médecin a renommé la section '$oldTitle' en '$newTitle'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

//RENAME SECTION JDIDA
  void renamedynamicSection(int index) {
    if (widget.readOnly) return;

    final currentTitle = dynamicSections[index]["title"] ?? "";

    TextEditingController ctrl = TextEditingController(text: currentTitle);

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
              final newTitle = ctrl.text.trim();
              if (newTitle.isEmpty) return;

              setState(() {
                dynamicSections[index]["title"] = newTitle;
              });

              await saveAllData();
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "📂 Section modifiée",
                "message":
                    "Le médecin a renommé la section '$currentTitle' en '$newTitle'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  void showMenu(int index) {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addField();
            },
            child: const Text("Ajouter champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyField();
            },
            child: const Text("Modifier champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renamedynamicSection(index); // 🔥 FIX IMPORTANT
            },
            child: const Text("Renommer section"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

  // 🎨 CARD DESIGN
  Widget medicalCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
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

  //MENU ANTECEDENT
  void showAntecedentMenu() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              addAntecedentField();
            },
            child: const Text("Ajouter champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyAntecedentField();
            },
            child: const Text("Modifier champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renameAntecedentSection();
            },
            child: const Text("Renommer section"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

  void showTraitementMenu() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              addTraitement();
            },
            child: const Text("Ajouter champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyTraitement();
            },
            child: const Text("Modifier champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renameTraitementSection();
            },
            child: const Text("Renommer section"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

//MENU ALLERGIE
  void showAllergyMenu() {
    if (widget.readOnly) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Options"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addAllergy();
              saveAllData();
            },
            child: const Text("Ajouter champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              modifyAllergy();
              saveAllData();
            },
            child: const Text("Modifier champ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              renameAllergySection();
              saveAllData();
            },
            child: const Text("Renommer section"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

//MENU URGENCE
  void showContactOptions(int index) {
    if (widget.readOnly) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ➕ Ajouter champ
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Ajouter champ"),
            onTap: () {
              Navigator.pop(context);

              TextEditingController nameCtrl = TextEditingController();

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Nom du champ"),
                  content: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: "Ex: Adresse",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Annuler"),
                    ),
                    TextButton(
                      onPressed: () {
                        final label = nameCtrl.text.trim();
                        if (label.isEmpty) return;

                        setState(() {
                          contactFields.add({
                            "label": label,
                            "controller": TextEditingController(),
                          });
                        });

                        saveAllData();
                        Navigator.pop(context);
                      },
                      child: const Text("Ajouter"),
                    ),
                  ],
                ),
              );
            },
          ),

          // ✏️ Modifier champ (هنا نحتاج index)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Modifier champ"),
            onTap: () {
              Navigator.pop(context);
              renameContactField(index);
            },
          ),

          // 🗑️ Supprimer champ
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text("Supprimer champ"),
            onTap: () {
              Navigator.pop(context);

              setState(() {
                contactFields.removeAt(index);
              });

              saveAllData();
            },
          ),
        ],
      ),
    );
  }

  void renameContactField(int index) {
    TextEditingController ctrl = TextEditingController(
      text: contactFields[index]["label"],
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Renommer champ"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final oldLabel = contactFields[index]["label"];
              final newLabel = ctrl.text.trim();
              if (newLabel.isEmpty) return;

              setState(() {
                contactFields[index]["label"] = newLabel;
              });

              await saveAllData();
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "📞 Contact modifié",
                "message":
                    "Le médecin a renommé le champ de contact '$oldLabel' en '$newLabel'.",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showSectionOptions(int index) {
    if (widget.readOnly) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ➕ ADD FIELD (WITH NAME INPUT)
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Ajouter champ"),
            onTap: () {
              Navigator.pop(context);

              TextEditingController nameCtrl = TextEditingController();

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Nom du champ"),
                  content: TextField(controller: nameCtrl),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Annuler"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final label = nameCtrl.text.trim();
                        if (label.isEmpty) return;

                        setState(() {
                          dynamicSections[index]["fields"]
                              .add(TextEditingController());
                        });

                        await saveAllData();
                        Navigator.pop(context);
                      },
                      child: const Text("Ajouter"),
                    ),
                  ],
                ),
              );
            },
          ),

          // ✏️ RENAME SECTION
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Renommer section"),
            onTap: () {
              Navigator.pop(context);
              renamedynamicSection(index);
            },
          ),

          // ⚙️ FUTURE
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Modifier champ"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

//URGENCE
  Widget buildField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: widget.readOnly,
              enabled: !widget.readOnly,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: widget.readOnly
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirmation"),
                        content: const Text("Supprimer ce champ ?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              // ❌ WRONG: controller.clear()

                              // ✅ لازم تمسح من المصدر الحقيقي (list)
                              setState(() {
                                // مثال حسب type متاعك:
                                // إذا عندك map fields
                                fields.removeWhere(
                                    (key, value) => value == controller);

                                // إذا dynamicSections:
                                for (var section in dynamicSections) {
                                  section["fields"].remove(controller);
                                }
                              });

                              await saveAllData();
                            },
                            child: const Text("Supprimer"),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget buildHistoriqueField(
      TextEditingController controller, String hint, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: widget.readOnly,
              enabled: !widget.readOnly,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: widget.readOnly
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirmation"),
                        content: const Text("Supprimer ce champ ?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              setState(() {
                                historiqueFields.removeAt(index);
                              });

                              saveAllData();
                            },
                            child: const Text("Supprimer"),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Future<void> deleteLocalFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> pickLocalFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;
    // Tentative d'upload vers Cloudinary; si échec on conserve le chemin local
    setState(() {
      uploadProgress = 0.01;
    });

    final file = File(path);
    String? uploadedUrl;
    try {
      uploadedUrl = await StorageService.uploadFile(file);
    } finally {
      setState(() {
        uploadProgress = 0;
      });
    }

    setState(() {
      medicalFiles.add({"path": uploadedUrl ?? path, "comment": ""});
    });

    await saveAllData();

    final fileName = result.files.single.name;

    await FirebaseFirestore.instance.collection("notifications").add({
      "patientId": widget.patientId,
      "title": "📎 Nouveau fichier médical",
      "message": "Le médecin a ajouté un nouveau document médical : $fileName",
      "date": Timestamp.now(),
      "patientRead": false,
      "familyRead": false,
    });
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

//ENREG ET BOUTON SUPP
  Future<void> saveAllData() async {
    if (widget.readOnly) return;

    final uid = widget.patientId;

    await firestore.collection("dossiersMedicaux").doc(widget.patientId).set({
      "info": {for (var e in fields.entries) e.key: e.value.text},

      "antecedents": {for (var e in antecedents.entries) e.key: e.value.text},

      "traitements": {for (var e in traitements.entries) e.key: e.value.text},

      "allergies": {for (var e in allergies.entries) e.key: e.value.text},

      "dynamicSections": dynamicSections.map((section) {
        return {
          "title": section["title"],
          "fields": (section["fields"] as List<TextEditingController>)
              .map((c) => c.text)
              .toList(),
        };
      }).toList(),

      "contact": contactFields.map((field) {
        return {
          "label": field["label"],
          "value": field["controller"].text,
        };
      }).toList(),

      "historique": historiqueFields.map((field) {
        return {
          "label": field["label"],
          "value": field["controller"].text,
        };
      }).toList(),

      // 🔥 NEW: FILES
      "medicalFiles": medicalFiles
          .map((f) => {"path": f["path"], "comment": f["comment"]})
          .toList(),

      "updatedAt": DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> loadAllData() async {
    final uid = widget.patientId;

    final doc = await firestore
        .collection("dossiersMedicaux")
        .doc(widget.patientId)
        .get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      // INFO
      final info = data["info"] ?? {};
      info.forEach((key, value) {
        fields[key] = TextEditingController(text: value.toString());
      });

      // ANTECEDENTS
      final ant = data["antecedents"] ?? {};
      ant.forEach((key, value) {
        antecedents[key] = TextEditingController(text: value.toString());
      });

      // TRAITEMENTS
      final tr = data["traitements"] ?? {};
      tr.forEach((key, value) {
        traitements[key] = TextEditingController(text: value.toString());
      });

      // ALLERGIES
      final al = data["allergies"] ?? {};
      al.forEach((key, value) {
        allergies[key] = TextEditingController(text: value.toString());
      });

      // DYNAMIC SECTIONS
      final sections = data["dynamicSections"] ?? [];

      dynamicSections = (sections as List).map((section) {
        return {
          "title": section["title"],
          "fields": (section["fields"] as List)
              .map((t) => TextEditingController(text: t.toString()))
              .toList(),
        };
      }).toList();

      // CONTACT (⚠️ label + controller structure)
      contactFields = (data["contact"] ?? []).map<Map<String, dynamic>>((item) {
        return {
          "label": item["label"],
          "controller": TextEditingController(
            text: item["value"] ?? "",
          ),
        };
      }).toList();

      // HISTORIQUE
      // HISTORIQUE
      historiqueFields =
          (data["historique"] ?? []).map<Map<String, dynamic>>((item) {
        return {
          "label": item["label"],
          "controller": TextEditingController(
            text: item["value"] ?? "",
          ),
        };
      }).toList();

      // MEDICAL FILES
      medicalFiles = (data["medicalFiles"] ?? [])
          .map<Map<String, dynamic>>((f) => {
                "path": f["path"] ?? "",
                "comment": f["comment"] ?? "",
              })
          .toList();
    });
  }

  void createNewSection() {
    if (widget.readOnly) return;

    TextEditingController titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nouvelle section"),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            hintText: "Nom de la section",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Créer"),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;

              Navigator.pop(context);

              setState(() {
                dynamicSections.add({
                  "title": title,
                  "fields": <TextEditingController>[], // ✅ مهم
                });
              });

              await saveAllData();
              await FirebaseFirestore.instance.collection("notifications").add({
                "patientId": widget.patientId,
                "title": "📂 Nouvelle section",
                "message": "Le médecin a ajouté une nouvelle section : $title",
                "date": Timestamp.now(),
                "patientRead": false,
                "familyRead": false,
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadAllData(); // 🔥 هذا هو السر
  }

  @override
  void dispose() {
    // INFO
    for (var c in fields.values) {
      c.dispose();
    }

    // ANTECEDENTS
    for (var c in antecedents.values) {
      c.dispose();
    }

    // TRAITEMENTS
    for (var c in traitements.values) {
      c.dispose();
    }

    // ALLERGIES
    for (var c in allergies.values) {
      c.dispose();
    }

    // DYNAMIC SECTIONS
    for (var section in dynamicSections) {
      for (var c in section["fields"]) {
        c.dispose();
      }
    }

    // CONTACT
    for (var field in contactFields) {
      field["controller"].dispose();
    }

    // HISTORIQUE
    for (var field in historiqueFields) {
      field["controller"].dispose();
    }

    super.dispose();
  }

  Future<void> sendPatientNotification({
    required String patientId,
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance.collection("notifications").add({
      "patientId": patientId,
      "title": title,
      "message": body,
      "date": Timestamp.now(),
      "patientRead": false,
      "familyRead": false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dossier médical 🏥"),
        actions: [
          // 💾 زر Enregistrer
          IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            onPressed: widget.readOnly
                ? null
                : () async {
                    await saveAllData();

                    final now = DateTime.now();

                    await sendPatientNotification(
                      patientId: widget.patientId,
                      title: "✏️ Dossier médical modifié",
                      body:
                          "Le dossier médical a été modifié le ${now.day}/${now.month}/${now.year} à ${now.hour}:${now.minute.toString().padLeft(2, '0')}",
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Données enregistrées ✅"),
                      ),
                    );
                  },
          ),
          // ⋮ option

          if (!widget.readOnly)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "add") {
                  addNewSection();
                } else if (value == "delete") {
                  deleteAllData();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "add",
                  child: Text("Ajouter section"),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Text("Supprimer dossier"),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              onPressed: addNewSection, // 👈 الأفضل هنا
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: medicalCard(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // 🔵 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          sectionTitle,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        /*IconButton(
  icon: const Icon(Icons.settings),
  onPressed: widget.readOnly ? null : () => 
  showMenu( index),
),*/
                        IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: widget.readOnly ? null : deleteSection),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 10),

                // 📋 FIELDS
                ...fields.keys.map((key) {
                  var value = fields[key];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: key == "Sexe"
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Sexe"),
                                    DropdownButton<String>(
                                      value: (fields["Sexe"]
                                                  as TextEditingController)
                                              .text
                                              .isEmpty
                                          ? null
                                          : (fields["Sexe"]
                                                  as TextEditingController)
                                              .text,
                                      isExpanded: true,
                                      items: sexes
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e),
                                              ))
                                          .toList(),
                                      onChanged: widget.readOnly
                                          ? null
                                          : (newValue) {
                                              setState(() {
                                                (fields["Sexe"]
                                                        as TextEditingController)
                                                    .text = newValue!;
                                              });
                                            },
                                    ),
                                  ],
                                )
                              : key == "Groupe sanguin"
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Groupe sanguin"),
                                        DropdownButton<String>(
                                          value: (fields[key]
                                                      as TextEditingController)
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : (fields[key]
                                                      as TextEditingController)
                                                  .text,
                                          isExpanded: true,
                                          items: groupes
                                              .map((e) => DropdownMenuItem(
                                                    value: e,
                                                    child: Text(e),
                                                  ))
                                              .toList(),
                                          onChanged: widget.readOnly
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    (fields[key]
                                                            as TextEditingController)
                                                        .text = val!;
                                                  });
                                                },
                                        ),
                                      ],
                                    )
                                  : TextField(
                                      controller:
                                          value as TextEditingController,
                                      readOnly: widget.readOnly,
                                      enabled: !widget.readOnly,
                                      decoration: InputDecoration(
                                        labelText: key,
                                        border: InputBorder.none,
                                      ),
                                    ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed:
                              widget.readOnly ? null : () => deleteField(key),
                        ),
                      ],
                    ),
                  );
                }),
                medicalCard(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🟢 TITLE
                            Row(
                              children: [
                                const Icon(Icons.health_and_safety,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    antecedentTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 🔘 BUTTONS تحت العنوان
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.settings), // ⚙️ paramètre
                                  color: Colors.grey,
                                  onPressed: widget.readOnly
                                      ? null
                                      : showAntecedentMenu,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.grey,
                                  onPressed: widget.readOnly
                                      ? null
                                      : deleteAntecedentSection,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // FIELDS antecedent
                        ...antecedents.keys.map((key) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.green.shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: antecedents[key],
                                    readOnly: widget.readOnly,
                                    enabled: !widget.readOnly,
                                    maxLines: 3, // 🔥 multi-line
                                    decoration: InputDecoration(
                                      labelText: key,
                                      alignLabelWithHint: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () => deleteAntecedentField(key),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                medicalCard(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🟢 TITLE
                        Row(
                          children: [
                            const Icon(Icons.medication, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                traitementTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ⚙️ BUTTONS تحت العنوان
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed:
                                  widget.readOnly ? null : showTraitementMenu,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: widget.readOnly
                                  ? null
                                  : deleteTraitementSection,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 📋 LIST
                        ...traitements.keys.map((key) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.yellow.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: traitements[key],
                                    readOnly: widget.readOnly,
                                    enabled: !widget.readOnly,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: key,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () => deleteTraitement(key),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                medicalCard(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🟣 TITLE
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                allergiesTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ⚙️ BUTTONS تحت العنوان
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed:
                                  widget.readOnly ? null : showAllergyMenu,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed:
                                  widget.readOnly ? null : deleteAllergySection,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 📋 LIST
                        ...allergies.keys.map((key) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: allergies[key],
                                    readOnly: widget.readOnly,
                                    enabled: !widget.readOnly,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      labelText: key,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () => deleteAllergy(key),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
//ANALYSE
                if (analyseTitle.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8, // 👈 هنا حطيتها
                    shadowColor: Colors.brown.withOpacity(0.2), // 👈 وهنا
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.brown.shade50, // 🤎 بني فاتح
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🧪 TITLE
                            Row(
                              children: [
                                const Icon(Icons.medical_information,
                                    color: Colors.black),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Analyse",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors.brown.shade700, // 🤎 بني غامق
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 🔘 BUTTON GO TO ANALYSE PAGE
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward,
                                    color: Colors.black),
                                label: const Text("Voir les analyses",
                                    style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.brown.shade600, // 🤎 بني غامق
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AnalysePage(
                                        patientId: widget.patientId,
                                        readOnly: widget.readOnly,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ⚙️ + 🗑️ BUTTONS
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.brown),
                                  onPressed: widget.readOnly
                                      ? null
                                      : renameAnalyseCard,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.brown),
                                  onPressed: widget.readOnly
                                      ? null
                                      : deleteAnalyseCard,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // ================= MEDICAMENT =================
                if (medicamentTitle.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: Colors.green.withOpacity(0.2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade50,
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.medication,
                                    color: Colors.black),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    medicamentTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward,
                                    color: Colors.black),
                                label: const Text(
                                  "Voir les médicaments",
                                  style: TextStyle(color: Colors.black),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TypesMedicamentsPage(
                                        patientId: widget.patientId,
                                        //readOnly: widget.readOnly,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.green),
                                  onPressed: widget.readOnly
                                      ? null
                                      : renameMedicamentCard,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.green),
                                  onPressed: widget.readOnly
                                      ? null
                                      : deleteMedicamentCard,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                //photo
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade100,
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (uploadProgress > 0 && uploadProgress < 1)
                            LinearProgressIndicator(value: uploadProgress),

                          // 📄 TITLE
                          Row(
                            children: [
                              const Icon(Icons.folder_copy,
                                  color: Colors.black), // 👈 أسود
                              const SizedBox(width: 8),
                              Text(
                                "Documents médicaux",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // 👈 نفس لون البوتون
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // 🔘 ADD BUTTON

                          // 📂 LIST FILES
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add,
                                  color: Colors.black), // 👈 icon أسود
                              label: const Text(
                                "Ajouter document",
                                style: TextStyle(
                                    color: Colors.black), // 👈 texte أسود
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey
                                    .shade200, // 👈 fond فاتح باش يبان الأسود
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: widget.readOnly ? null : pickLocalFile,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 📂 LIST FILES
                          Column(
                            children: medicalFiles.map((item) {
                              String file = item["path"];
                              String comment = item["comment"] ?? "";
                              bool isRemote = file.startsWith('http');
                              String fileName() {
                                try {
                                  if (isRemote)
                                    return Uri.parse(file).pathSegments.last;
                                  if (file.contains('/'))
                                    return file.split('/').last;
                                  if (file.contains('\\'))
                                    return file.split('\\').last;
                                  return file;
                                } catch (e) {
                                  return file;
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    if ((file.endsWith(".jpg") ||
                                            file.endsWith(".png") ||
                                            file.endsWith(".jpeg")) &&
                                        isRemote)
                                      Image.network(
                                        file,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    else if (file.endsWith(".jpg") ||
                                        file.endsWith(".png") ||
                                        file.endsWith(".jpeg"))
                                      Image.file(
                                        File(file),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      const Icon(Icons.insert_drive_file,
                                          color: Colors.teal),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        fileName(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: comment,
                                        decoration: const InputDecoration(
                                          hintText: "Ajouter commentaire...",
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (value) {
                                          item["comment"] = value;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new,
                                          color: Colors.blue),
                                      onPressed: () async {
                                        if (isRemote) {
                                          try {
                                            await launchUrl(
                                              Uri.parse(file),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Impossible d\'ouvrir le fichier')));
                                          }
                                        } else {
                                          try {
                                            await OpenFile.open(file);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Impossible d\'ouvrir le fichier')));
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: widget.readOnly
                                          ? null
                                          : () async {
                                              bool confirm = await showDialog(
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
                                                              context, false),
                                                      child:
                                                          const Text("Annuler"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                          "Supprimer"),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                setState(() {
                                                  medicalFiles.remove(item);
                                                });

                                                await saveAllData();
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                //URGENCE

                if (contactTitle.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: Colors.red.withOpacity(0.2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade50,
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ❤️ TITLE
                            Row(
                              children: [
                                const Icon(
                                  Icons.contact_phone,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    contactTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ⚙️ SETTINGS + DELETE
                            Row(
                              children: [
                                // ⚙️ SETTINGS
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (_) => Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // ➕ ADD FIELD
                                                ListTile(
                                                  leading:
                                                      const Icon(Icons.add),
                                                  title: const Text(
                                                      "Ajouter champ"),
                                                  onTap: () {
                                                    Navigator.pop(context);

                                                    TextEditingController
                                                        nameCtrl =
                                                        TextEditingController();

                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            "Nom du champ"),
                                                        content: TextField(
                                                          controller: nameCtrl,
                                                          decoration:
                                                              const InputDecoration(
                                                            hintText:
                                                                "Ex: Adresse",
                                                          ),
                                                        ),
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
                                                              final label =
                                                                  nameCtrl.text
                                                                      .trim();

                                                              if (label
                                                                  .isEmpty) {
                                                                return;
                                                              }

                                                              setState(() {
                                                                contactFields
                                                                    .add({
                                                                  "label":
                                                                      label,
                                                                  "controller":
                                                                      TextEditingController(),
                                                                });
                                                              });

                                                              await saveAllData();

                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Ajouter"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),

                                                // ✏️ MODIFIER CHAMP
                                                ListTile(
                                                  leading:
                                                      const Icon(Icons.edit),
                                                  title: const Text(
                                                      "Modifier champ"),
                                                  onTap: () {
                                                    Navigator.pop(context);

                                                    showModalBottomSheet(
                                                      context: context,
                                                      builder: (_) =>
                                                          ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: contactFields
                                                            .length,
                                                        itemBuilder:
                                                            (_, index) {
                                                          var field =
                                                              contactFields[
                                                                  index];

                                                          return ListTile(
                                                            title: Text(
                                                              field["label"],
                                                            ),
                                                            trailing:
                                                                const Icon(
                                                                    Icons.edit),
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);

                                                              TextEditingController
                                                                  renameCtrl =
                                                                  TextEditingController(
                                                                text: field[
                                                                    "label"],
                                                              );

                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (_) =>
                                                                    AlertDialog(
                                                                  title:
                                                                      const Text(
                                                                    "Modifier champ",
                                                                  ),
                                                                  content:
                                                                      TextField(
                                                                    controller:
                                                                        renameCtrl,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      hintText:
                                                                          "Nouveau nom",
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          const Text(
                                                                        "Annuler",
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () async {
                                                                        setState(
                                                                            () {
                                                                          contactFields[index]["label"] =
                                                                              renameCtrl.text;
                                                                        });

                                                                        await saveAllData();

                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          const Text(
                                                                        "Enregistrer",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),

                                                // ✏️ RENAME SECTION
                                                ListTile(
                                                  leading: const Icon(Icons
                                                      .drive_file_rename_outline),
                                                  title: const Text(
                                                      "Renommer section"),
                                                  onTap: () {
                                                    Navigator.pop(context);

                                                    TextEditingController
                                                        renameCtrl =
                                                        TextEditingController(
                                                      text: contactTitle,
                                                    );

                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            "Renommer section"),
                                                        content: TextField(
                                                          controller:
                                                              renameCtrl,
                                                        ),
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
                                                                contactTitle =
                                                                    renameCtrl
                                                                        .text;
                                                              });

                                                              await saveAllData();

                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Modifier"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                ),

                                // 🗑️ DELETE SECTION
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Confirmation"),
                                              content: const Text(
                                                "Supprimer toute la section ?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Annuler"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      contactFields.clear();

                                                      contactTitle = "";
                                                    });

                                                    await saveAllData();

                                                    Navigator.pop(context);
                                                  },
                                                  child:
                                                      const Text("Supprimer"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 📋 FIELDS
                            ...contactFields.asMap().entries.map((entry) {
                              int index = entry.key;
                              var field = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: field["controller"],
                                        readOnly: widget.readOnly,
                                        enabled: !widget.readOnly,
                                        onChanged: (value) async {
                                          await saveAllData();
                                        },
                                        decoration: InputDecoration(
                                          labelText: field["label"],
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // 🗑️ DELETE FIELD
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: widget.readOnly
                                          ? null
                                          : () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                    "Confirmation",
                                                  ),
                                                  content: const Text(
                                                    "Supprimer ce champ ?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                        "Annuler",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        setState(() {
                                                          contactFields
                                                              .removeAt(index);
                                                        });

                                                        await saveAllData();

                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                        "Supprimer",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (historiqueTitle.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔵 TITLE
                            Row(
                              children: [
                                const Icon(Icons.history, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    historiqueTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ⚙️ SETTINGS + DELETE
                            Row(
                              children: [
                                // ⚙️ SETTINGS
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (_) => Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // ➕ ADD FIELD
                                                ListTile(
                                                  leading:
                                                      const Icon(Icons.add),
                                                  title: const Text(
                                                      "Ajouter champ"),
                                                  onTap: () {
                                                    Navigator.pop(context);

                                                    TextEditingController
                                                        nameCtrl =
                                                        TextEditingController();

                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            "Nom du champ"),
                                                        content: TextField(
                                                          controller: nameCtrl,
                                                          decoration:
                                                              const InputDecoration(
                                                            hintText:
                                                                "Ex: Diagnostic",
                                                          ),
                                                        ),
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
                                                              final label =
                                                                  nameCtrl.text
                                                                      .trim();

                                                              if (label
                                                                  .isEmpty) {
                                                                return;
                                                              }

                                                              setState(() {
                                                                historiqueFields
                                                                    .add({
                                                                  "label":
                                                                      label,
                                                                  "controller":
                                                                      TextEditingController(),
                                                                });
                                                              });

                                                              await saveAllData();

                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Ajouter"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                //modif champ
                                                // ✏️ Modifier champ
                                                ListTile(
                                                  leading:
                                                      const Icon(Icons.edit),
                                                  title: const Text(
                                                      "Modifier champ"),
                                                  onTap: () {
                                                    Navigator.pop(context);

                                                    showModalBottomSheet(
                                                      context: context,
                                                      builder: (_) =>
                                                          ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            historiqueFields
                                                                .length,
                                                        itemBuilder:
                                                            (_, index) {
                                                          var field =
                                                              historiqueFields[
                                                                  index];

                                                          return ListTile(
                                                            title: Text(
                                                                field["label"]),
                                                            trailing:
                                                                const Icon(
                                                                    Icons.edit),
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);

                                                              TextEditingController
                                                                  renameCtrl =
                                                                  TextEditingController(
                                                                text: field[
                                                                    "label"],
                                                              );

                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (_) =>
                                                                    AlertDialog(
                                                                  title: const Text(
                                                                      "Modifier champ"),
                                                                  content:
                                                                      TextField(
                                                                    controller:
                                                                        renameCtrl,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      hintText:
                                                                          "Nouveau nom",
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                          "Annuler"),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () async {
                                                                        setState(
                                                                            () {
                                                                          historiqueFields[index]["label"] =
                                                                              renameCtrl.text;
                                                                        });

                                                                        await saveAllData();

                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                          "Enregistrer"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),

                                                // ✏️ RENAME SECTION
                                                ListTile(
                                                  leading:
                                                      const Icon(Icons.edit),
                                                  title: const Text(
                                                      "Renommer section"),
                                                  onTap: () {
                                                    Navigator.pop(context);

                                                    TextEditingController ctrl =
                                                        TextEditingController(
                                                      text: historiqueTitle,
                                                    );

                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            "Renommer"),
                                                        content: TextField(
                                                          controller: ctrl,
                                                        ),
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
                                                                historiqueTitle =
                                                                    ctrl.text;
                                                              });

                                                              await saveAllData();

                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Modifier"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                ),

                                // 🗑️ DELETE SECTION
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Confirmation"),
                                              content: const Text(
                                                "Supprimer toute la section ?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Annuler"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      historiqueFields.clear();
                                                      historiqueTitle = "";
                                                    });

                                                    await saveAllData();

                                                    Navigator.pop(context);
                                                  },
                                                  child:
                                                      const Text("Supprimer"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 📋 FIELDS
                            ...historiqueFields.asMap().entries.map((entry) {
                              int index = entry.key;
                              var field = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: field["controller"],
                                        readOnly: widget.readOnly,
                                        enabled: !widget.readOnly,
                                        decoration: InputDecoration(
                                          labelText: field["label"],
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // 🗑️ DELETE FIELD
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: widget.readOnly
                                          ? null
                                          : () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      "Confirmation"),
                                                  content: const Text(
                                                    "Supprimer ce champ ?",
                                                  ),
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
                                                          historiqueFields
                                                              .removeAt(index);
                                                        });

                                                        await saveAllData();

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
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ...dynamicSections.asMap().entries.map((entry) {
                  int index = entry.key;
                  var section = entry.value;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🆕 TITLE
                          Row(
                            children: [
                              const Icon(Icons.folder, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  section["title"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // ⚙️ + 🗑️
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: widget.readOnly
                                    ? null
                                    : () => showSectionOptions(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: widget.readOnly
                                    ? null
                                    : () => deleteDynamicSection(index),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // 🧾 FIELDS
                          ...List.generate(
                            (section["fields"] as List).length,
                            (i) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: section["fields"][i],
                                        readOnly: widget.readOnly,
                                        enabled: !widget.readOnly,
                                        decoration: InputDecoration(
                                          hintText: "Champ ${i + 1}",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: widget.readOnly
                                          ? null
                                          : () =>
                                              deleteFieldFromSection(index, i),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
