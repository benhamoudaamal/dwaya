import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

class MedicamentsPage extends StatefulWidget {
  final String patientId;
  final String? typeFilter;
  final bool readOnly;

  const MedicamentsPage(
      {super.key,
      required this.patientId,
      this.typeFilter,
      this.readOnly = false});

  @override
  State<MedicamentsPage> createState() => _MedicamentsPageState();
}

class _MedicamentsPageState extends State<MedicamentsPage> {
  List<Map<String, dynamic>> meds = [];
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadMeds();
  }

  // 🔊 SOUND
  Future<void> playSound() async {
    await player.play(
      AssetSource(
          'mixkit-quick-positive-video-game-notification-interface-265.wav'),
    );
  }

  // 📥 LOAD
  Future<void> loadMeds() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("meds")
        .where("patientId", isEqualTo: widget.patientId)
        .get();

    List<Map<String, dynamic>> all = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      all.add({
        ...data,
        "id": doc.id,
      });
    }

    setState(() {
      if (widget.typeFilter == null) {
        meds = all;
      } else {
        meds = all
            .where((m) =>
                (m["type"] ?? "").toString().toLowerCase() ==
                widget.typeFilter!.toLowerCase())
            .toList();
      }
    });
    // print("UID used for meds: $"patientId); // ← vérifie dans console
    //print("widget.patientId: ${widget.patientId}");
  }

  // ➕ ADD
  Future<void> addMed(
    String name,
    String time,
    String fois,
    String quantite,
    String duree,
    String moment,
    String type,
    String dateDebut,
    String dateFin,
  ) async {
    print("PATIENT ID = ${widget.patientId}");

    if (widget.readOnly) return;

    final docRef = FirebaseFirestore.instance.collection("meds").doc();

    Map<String, dynamic> newMed = {
      "id": docRef.id,
      "name": name,
      "time": time,
      "fois": fois,
      "quantite": quantite,
      "duree": duree,
      "moment": moment,
      "type": widget.typeFilter ?? type,
      "etatToday": "waiting",
      "date": DateTime.now().toString(),
      "status": "waiting",
      "taken": false,

// 🔥 مهم جدا
      "patientId": widget.patientId,

      "dateDebut": Timestamp.fromDate(
        DateTime.parse(dateDebut),
      ),

      "dateFin": Timestamp.fromDate(
        DateTime.parse(dateFin),
      ),
    };

    await docRef.set(newMed);

    await sendPatientNotification(
      patientId: widget.patientId,
      title: "💊 Médicament ajouté",
      body: "Le docteur a ajouté ${name} dans Médicaments",
    );

    await loadMeds();
  }

  // ✔️ TOGGLE
  Future<void> toggleTaken(String id, bool value) async {
    if (widget.readOnly) return;
    await FirebaseFirestore.instance.collection("meds").doc(id).update({
      "taken": value,
    });

    await loadMeds();
  }

  // ❌ DELETE
  Future deleteMed(String id) async {
    if (widget.readOnly) return;

    final med = meds.firstWhere(
      (m) => m["id"] == id,
    );
    await FirebaseFirestore.instance.collection("meds").doc(id).delete();
    await sendPatientNotification(
      patientId: widget.patientId,
      title: "🗑️ Médicament supprimé",
      body: "Le docteur a supprimé ${med["name"]} dans Médicaments",
    );

    await loadMeds();
  }

  Future updateMed(
    String id,
    String name,
    String time,
    String fois,
    String quantite,
    String duree,
    String moment,
    String dateDebut,
    String dateFin,
  ) async {
    if (widget.readOnly) return;

    await FirebaseFirestore.instance.collection("meds").doc(id).update({
      "name": name,
      "time": time,
      "fois": fois,
      "quantite": quantite,
      "duree": duree,
      "moment": moment,
      "dateDebut": Timestamp.fromDate(
        DateTime.parse(dateDebut),
      ),
      "dateFin": Timestamp.fromDate(
        DateTime.parse(dateFin),
      ),
    });
    await sendPatientNotification(
      patientId: widget.patientId,
      title: "✏️ Médicament modifié",
      body: "Le docteur a modifié ${name} dans Médicaments",
    );

    await loadMeds();
  }

  // 🎨 FIELD
  Widget buildField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: widget.readOnly,
        enabled: !widget.readOnly,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          labelText: label,
          filled: true,
          fillColor: Colors.green.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Future<void> pickDate(TextEditingController controller) async {
    if (widget.readOnly) return;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}"; // yyyy-MM-dd
    }
  }
//hedhou ui

  // ➕ DIALOG
  void showAddDialog() {
    if (widget.readOnly) return;
    TextEditingController name = TextEditingController();
    TextEditingController time = TextEditingController();
    TextEditingController fois = TextEditingController();
    TextEditingController quantite = TextEditingController();
    TextEditingController duree = TextEditingController();
    TextEditingController moment = TextEditingController();
    TextEditingController dateDebut = TextEditingController();
    TextEditingController dateFin = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("➕ Ajouter médicament"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle("💊 Informations"),
              buildField(name, "Nom", Icons.medication),
              sectionTitle("⏰ Horaire"),
              GestureDetector(
                onTap: widget.readOnly
                    ? null
                    : () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (picked != null) {
                          final hour = picked.hour.toString().padLeft(2, '0');
                          final minute =
                              picked.minute.toString().padLeft(2, '0');

                          time.text = "$hour:$minute"; // 🔥 format صحيح
                        }
                      },
                child: AbsorbPointer(
                  child: buildField(time, "Heure", Icons.access_time),
                ),
              ),
              buildField(moment, "Moment", Icons.wb_sunny),
              sectionTitle("📊 Dosage"),
              buildField(fois, "Fois/jour", Icons.repeat),
              buildField(quantite, "Quantité", Icons.format_list_numbered),
              sectionTitle("📅 Durée"),
              buildField(duree, "Durée", Icons.calendar_today),
              sectionTitle("📅 Dates"),
              GestureDetector(
                onTap: widget.readOnly ? null : () => pickDate(dateDebut),
                child: AbsorbPointer(
                  child:
                      buildField(dateDebut, "Date début", Icons.calendar_today),
                ),
              ),
              GestureDetector(
                onTap: widget.readOnly ? null : () => pickDate(dateFin),
                child: AbsorbPointer(
                  child: buildField(dateFin, "Date fin", Icons.calendar_today),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Ajouter"),
            onPressed: widget.readOnly
                ? null
                : () async {
                    await addMed(
                      name.text,
                      time.text,
                      fois.text,
                      quantite.text,
                      duree.text,
                      moment.text,
                      widget.typeFilter ?? "Autre",
                      dateDebut.text,
                      dateFin.text,
                    );

                    Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }

  void showEditDialog(Map med) {
    if (widget.readOnly) return;
    TextEditingController name = TextEditingController(text: med["name"]);
    TextEditingController time = TextEditingController(text: med["time"]);
    TextEditingController fois = TextEditingController(text: med["fois"]);
    TextEditingController quantite =
        TextEditingController(text: med["quantite"]);
    TextEditingController duree = TextEditingController(text: med["duree"]);
    TextEditingController moment = TextEditingController(text: med["moment"]);

    // 🔥 مهم
    final format = DateFormat('yyyy-MM-dd');

    final dateDebutValue = med["dateDebut"];
    final dateFinValue = med["dateFin"];

    TextEditingController dateDebut = TextEditingController(
      text: dateDebutValue is Timestamp
          ? format.format(dateDebutValue.toDate())
          : dateDebutValue.toString(),
    );

    TextEditingController dateFin = TextEditingController(
      text: dateFinValue is Timestamp
          ? format.format(dateFinValue.toDate())
          : dateFinValue.toString(),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ Modifier médicament"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              buildField(name, "Nom", Icons.medication),
              buildField(time, "Heure", Icons.access_time),
              buildField(moment, "Moment", Icons.wb_sunny),
              buildField(fois, "Fois", Icons.repeat),
              buildField(quantite, "Quantité", Icons.format_list_numbered),
              buildField(duree, "Durée", Icons.calendar_today),

              const SizedBox(height: 10),

              // 🔥 DATES
              GestureDetector(
                onTap: widget.readOnly ? null : () => pickDate(dateDebut),
                child: AbsorbPointer(
                  child:
                      buildField(dateDebut, "Date début", Icons.calendar_today),
                ),
              ),

              GestureDetector(
                onTap: widget.readOnly ? null : () => pickDate(dateFin),
                child: AbsorbPointer(
                  child: buildField(dateFin, "Date fin", Icons.calendar_today),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Modifier"),
            onPressed: widget.readOnly
                ? null
                : () async {
                    await updateMed(
                      med["id"],
                      name.text,
                      time.text,
                      fois.text,
                      quantite.text,
                      duree.text,
                      moment.text,
                      dateDebut.text,
                      dateFin.text,
                    );
                    Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }

  // 🔥 INFO ROW
  Widget infoRow(IconData icon, String label, String? value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // 🔹 ICON (ملوّن)
          Icon(icon, size: 18, color: color),

          const SizedBox(width: 8),

          // 🔹 LABEL (ملوّن)
          Text(
            "$label : ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          // 🔹 VALUE (أسود)
          Expanded(
            child: Text(
              value ?? "",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // COULEUR MT3 kol ism dwa
  IconData getIconByType(String type) {
    switch (type.toLowerCase()) {
      case "sirop":
        return Icons.local_drink;
      case "comprimé":
        return Icons.circle;
      case "gélule":
        return Icons.medication;
      case "crème":
        return Icons.spa;
      case "injection":
        return Icons.vaccines;
      case "gouttes":
        return Icons.opacity;
      case "patch":
        return Icons.healing;
      case "inhalateur":
        return Icons.air;
      case "gel":
        return Icons.water_drop;
      case "sachet":
        return Icons.inventory_2;
      case "spray":
        return Icons.sanitizer;
      default:
        return Icons.medical_services;
    }
  }

  Color getColorByType(String type) {
    switch (type.toLowerCase()) {
      case "sirop":
        return Colors.orange;
      case "comprimé":
        return Colors.green;
      case "gélule":
        return Colors.blue;
      case "crème":
        return Colors.pink;
      case "injection":
        return Colors.red;
      case "gouttes":
        return Colors.cyan;
      case "patch":
        return Colors.purple;
      case "inhalateur":
        return Colors.teal;
      case "gel":
        return Colors.lightBlue;
      case "sachet":
        return Colors.amber;
      case "spray":
        return Colors.indigo;
      default:
        return Colors.grey;
    }
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

  // 🎨 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("💊 ${widget.typeFilter ?? ""}"),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              onPressed: showAddDialog,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
      body: meds.isEmpty
          ? const Center(child: Text("Aucun médicament"))
          : ListView.builder(
              itemCount: meds.length,
              itemBuilder: (context, index) {
                final med = meds[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 💊 NAME + ICON
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: getColorByType(med["type"])
                                    .withOpacity(0.2),
                                child: Icon(
                                  getIconByType(med["type"]),
                                  color: getColorByType(med["type"]),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  med["name"],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: getColorByType(med["type"]),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          infoRow(Icons.access_time, "Heure", med["time"],
                              getColorByType(med["type"])),

                          infoRow(Icons.wb_sunny, "Moment", med["moment"],
                              getColorByType(med["type"])),

                          infoRow(Icons.repeat, "Fois/jour", med["fois"],
                              getColorByType(med["type"])),

                          infoRow(Icons.format_list_numbered, "Quantité",
                              med["quantite"], getColorByType(med["type"])),

                          infoRow(Icons.calendar_today, "Durée", med["duree"],
                              getColorByType(med["type"])),
                          infoRow(
                            Icons.date_range,
                            "Début",
                            med["dateDebut"] is Timestamp
                                ? DateFormat('yyyy-MM-dd')
                                    .format(med["dateDebut"].toDate())
                                : med["dateDebut"].toString(),
                            getColorByType(med["type"]),
                          ),

                          infoRow(
                            Icons.date_range,
                            "Fin",
                            med["dateFin"] is Timestamp
                                ? DateFormat('yyyy-MM-dd')
                                    .format(med["dateFin"].toDate())
                                : med["dateFin"].toString(),
                            getColorByType(med["type"]),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Checkbox(
                                value: med["taken"] ?? false,
                                onChanged: widget.readOnly
                                    ? null
                                    : (value) {
                                        toggleTaken(med["id"], value!);
                                      },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: widget.readOnly
                                    ? null
                                    : () {
                                        showEditDialog(med);
                                      },
                              ),
                              if (!widget.readOnly)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("⚠️ Confirmation"),
                                        content: const Text(
                                            "Voulez-vous supprimer ce médicament ?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("Annuler"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await deleteMed(med["id"]);
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Supprimer"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          )

                          //SUPP

                          // 🗑 SUPPRIMER avec confirmation
                          /*if (!widget.readOnly)
  IconButton(
    icon: const Icon(Icons.delete),
    onPressed: () {
      deleteMed(med["id"]);
    },
  ),*/
                          /* context: context,
          builder: (_) => AlertDialog(
            title: const Text("⚠️ Confirmation"),
            content: const Text("هل تريد حذف هذا الدواء؟"),
            actions: [
              TextButton(
                child: const Text("لا"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("نعم"),
                onPressed: () async {
                  await deleteMed(med["id"]);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );*/
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
