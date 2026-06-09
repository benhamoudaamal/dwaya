import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'medicaments_page.dart';
import 'stats_page.dart';

class TypesMedicamentsPage extends StatefulWidget {
  final String patientId;
  final bool readOnly;

  //yet7akem fi patient et docteur

  const TypesMedicamentsPage({
    super.key,
    required this.patientId,
    this.readOnly = false,
  });

  @override
  State<TypesMedicamentsPage> createState() => _TypesMedicamentsPageState();
}

class _TypesMedicamentsPageState extends State<TypesMedicamentsPage> {
  int? pressedIndex;

  final player = AudioPlayer();
  final translator = GoogleTranslator();
  final FlutterTts tts = FlutterTts();
  TextEditingController searchController = TextEditingController();
  String searchText = "";
  String selectedLanguage = "fr";
  List<Map<String, dynamic>> types = [
    {
      "name": "Gélule",
      "icon": Icons.medication,
      "color": Colors.blue,
      "fav": false,
      "count": 0
    },
    {
      "name": "Comprimé",
      "icon": Icons.circle,
      "color": Colors.green,
      "fav": false,
      "count": 0
    },
    {
      "name": "Sirop",
      "icon": Icons.local_drink,
      "color": Colors.orange,
      "fav": false,
      "count": 0
    },
    {
      "name": "Crème",
      "icon": Icons.spa,
      "color": Colors.pink,
      "fav": false,
      "count": 0
    },
    {
      "name": "Injection",
      "icon": Icons.vaccines,
      "color": Colors.red,
      "fav": false,
      "count": 0
    },
    {
      "name": "Gouttes",
      "icon": Icons.opacity,
      "color": Colors.cyan,
      "fav": false,
      "count": 0
    },
    {
      "name": "Patch",
      "icon": Icons.healing,
      "color": Colors.purple,
      "fav": false,
      "count": 0
    },
    {
      "name": "Inhalateur",
      "icon": Icons.air,
      "color": Colors.teal,
      "fav": false,
      "count": 0
    },
    {
      "name": "Gel",
      "icon": Icons.water_drop,
      "color": Colors.lightBlue,
      "fav": false,
      "count": 0
    },
    {
      "name": "Sachet",
      "icon": Icons.inventory_2,
      "color": Colors.amber,
      "fav": false,
      "count": 0
    },
    {
      "name": "Spray",
      "icon": Icons.sanitizer,
      "color": Colors.indigo,
      "fav": false,
      "count": 0
    },
  ];
  //Map<String, dynamic> history = {};

  Future<void> saveData() async {
    final batch = FirebaseFirestore.instance.batch();
    final ref = FirebaseFirestore.instance.collection("medicine_types");

    for (var t in types) {
      final doc = ref.doc(t["name"]);

      batch.set(doc, {
        "name": t["name"],
        "icon": t["icon"].codePoint,
        "color": t["color"].value,
        "fav": t["fav"],
        "count": t["count"],
      });
    }

    final settingsRef =
        FirebaseFirestore.instance.collection("settings").doc("language");

    batch.set(settingsRef, {"lang": selectedLanguage});

    await batch.commit();

    print("DATA SAVED TO FIREBASE");
  }

  Future<void> loadData() async {
    // 🔥 جيب types من Firebase
    final snapshot =
        await FirebaseFirestore.instance.collection("medicine_types").get();

    if (snapshot.docs.isNotEmpty) {
      types = snapshot.docs.map((doc) {
        return {
          "name": doc["name"],
          "icon": IconData(doc["icon"], fontFamily: 'MaterialIcons'),
          "color": Color(doc["color"]),
          "fav": doc["fav"] ?? false,
          "count": doc["count"] ?? 0,
        };
      }).toList();
    } else {
      // أول مرة - default values
      types = [
        {
          "name": "Gélule",
          "icon": Icons.medication,
          "color": Colors.blue,
          "fav": false,
          "count": 0
        },
        {
          "name": "Comprimé",
          "icon": Icons.circle,
          "color": Colors.green,
          "fav": false,
          "count": 0
        },
        {
          "name": "Sirop",
          "icon": Icons.local_drink,
          "color": Colors.orange,
          "fav": false,
          "count": 0
        },
        {
          "name": "Crème",
          "icon": Icons.spa,
          "color": Colors.pink,
          "fav": false,
          "count": 0
        },
        {
          "name": "Injection",
          "icon": Icons.vaccines,
          "color": Colors.red,
          "fav": false,
          "count": 0
        },
        {
          "name": "Gouttes",
          "icon": Icons.opacity,
          "color": Colors.cyan,
          "fav": false,
          "count": 0
        },
        {
          "name": "Patch",
          "icon": Icons.healing,
          "color": Colors.purple,
          "fav": false,
          "count": 0
        },
        {
          "name": "Inhalateur",
          "icon": Icons.air,
          "color": Colors.teal,
          "fav": false,
          "count": 0
        },
        {
          "name": "Gel",
          "icon": Icons.water_drop,
          "color": Colors.lightBlue,
          "fav": false,
          "count": 0
        },
        {
          "name": "Sachet",
          "icon": Icons.inventory_2,
          "color": Colors.amber,
          "fav": false,
          "count": 0
        },
        {
          "name": "Spray",
          "icon": Icons.sanitizer,
          "color": Colors.indigo,
          "fav": false,
          "count": 0
        },
      ];
      // 🔥 احفظهم في Firebase أول مرة
      await saveData();
    }

    // 🔥 RESET يوم جديد
    String today = DateTime.now().toString().substring(0, 10);

    final lastDoc = await FirebaseFirestore.instance
        .collection("settings")
        .doc("lastDate")
        .get();

    if (lastDoc.exists) {
      String savedDay = lastDoc["date"].toString().substring(0, 10);

      if (savedDay != today) {
        // reset count
        for (var t in types) {
          t["count"] = 0;
          await FirebaseFirestore.instance
              .collection("medicine_types")
              .doc(t["name"])
              .update({"count": 0});
        }

        // update lastDate
        await FirebaseFirestore.instance
            .collection("settings")
            .doc("lastDate")
            .set({"date": DateTime.now().toString()});

        Future.delayed(Duration.zero, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🆕 Nouveau jour → compteur reset")),
          );
        });
      }
    } else {
      // 🔥 أول مرة - انشئ lastDate
      await FirebaseFirestore.instance
          .collection("settings")
          .doc("lastDate")
          .set({"date": DateTime.now().toString()});
    }

    // 🔥 جيب اللغة من Firebase
    final langDoc = await FirebaseFirestore.instance
        .collection("settings")
        .doc("language")
        .get();

    if (langDoc.exists) {
      selectedLanguage = langDoc["lang"];
    }

    setState(() {});
    print("DATA LOADED FROM FIREBASE");
  }

  @override
  void initState() {
    super.initState();
    // 🔥 يمسح القديم
    loadData();
  }

  //AUTO SELECT

  Map<String, dynamic> autoSelect(String name) {
    name = name.toLowerCase();

    if (name.contains("sirop")) {
      return {"icon": Icons.local_drink, "color": Colors.orange};
    } else if (name.contains("gel")) {
      return {"icon": Icons.water_drop, "color": Colors.lightBlue};
    } else if (name.contains("spray")) {
      return {"icon": Icons.sanitizer, "color": Colors.indigo};
    } else if (name.contains("comprime")) {
      return {"icon": Icons.circle, "color": Colors.green};
    } else if (name.contains("injection")) {
      return {"icon": Icons.vaccines, "color": Colors.red};
    } else if (name.contains("creme")) {
      return {"icon": Icons.spa, "color": Colors.pink};
    }

    // 🔥 NEW SMART RULES
    else if (name.contains("vitamine")) {
      return {"icon": Icons.biotech, "color": Colors.deepOrange};
    } else if (name.contains("coeur")) {
      return {"icon": Icons.monitor_heart, "color": Colors.red};
    } else if (name.contains("blood")) {
      return {"icon": Icons.bloodtype, "color": Colors.redAccent};
    } else {
      return {"icon": Icons.medication, "color": Colors.blue};
    }
  }

//ADD
  void showAddDialog() {
    if (widget.readOnly) return;
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Ajouter type 💊"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      readOnly: widget.readOnly,
                      enabled: !widget.readOnly,
                      decoration:
                          const InputDecoration(hintText: "Nom du type"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: widget.readOnly
                      ? null
                      : () async {
                          if (controller.text.isEmpty) return;

                          final result = autoSelect(controller.text);

                          // 🔥 احفظ مباشرة في Firebase
                          await FirebaseFirestore.instance
                              .collection("medicine_types")
                              .doc(controller.text
                                  .toLowerCase()
                                  .replaceAll(" ", "_"))
                              .set({
                            "name": controller.text,
                            "icon": result["icon"].codePoint,
                            "color": result["color"].value,
                            "fav": false,
                            "count": 0,
                          });

                          // 🔥 update local list
                          setState(() {
                            types.add({
                              "name": controller.text,
                              "icon": result["icon"],
                              "color": result["color"],
                              "fav": false,
                              "count": 0,
                            });
                          });

                          Navigator.pop(context);
                        },
                  child: const Text("Ajouter"),
                ),
              ],
            );
          },
        );
      },
    );
  }

// ✅ هذان يبقيا كيما هما - ما عندهمش علاقة بالحفظ
  int totalTypes() => types.length;
  int totalFavs() => types.where((e) => e["fav"] == true).length;

  void showStatsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Statistiques 📊"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Total: ${totalTypes()}"),
            Text("Favoris: ${totalFavs()} ❤️"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ================= SOUND =================

  Future<String> translateText(String text) async {
    var result = await translator.translate(text, to: selectedLanguage);
    return result.text;
  }

  Future<void> playSounds(String name) async {
    Map<String, Map<String, String>> sounds = {
      "sirop": {
        "fr": "sirop_fr.mp3",
        "en": "sirop_en.mp3",
        "ar": "sirop_ar.mp3",
      },
    };

    String key = name.toLowerCase();

    if (sounds.containsKey(key)) {
      String file = sounds[key]![selectedLanguage] ?? "click.mp3";

      await player.play(
        AssetSource('Sounds/$file'),
      );
    } else {
      String translated = await translateText(name);

      if (selectedLanguage == "fr") {
        await tts.setLanguage("fr-FR");
      } else if (selectedLanguage == "en") {
        await tts.setLanguage("en-US");
      } else {
        await tts.setLanguage("ar-SA");
      }

      await tts.speak(translated);
    }
  }

  // HEDHI YBADEL
  void showEditDialog() {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Choisir type à modifier"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: types.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(types[index]["name"]),
                onTap: widget.readOnly
                    ? null
                    : () {
                        Navigator.pop(context);
                        editType(index);
                      },
              );
            },
          ),
        ),
      ),
    );
  }

  void editType(int index) {
    if (widget.readOnly) return;
    TextEditingController controller =
        TextEditingController(text: types[index]["name"]);

    IconData selectedIcon = types[index]["icon"];
    Color selectedColor = types[index]["color"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Modifier type ✏️"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      readOnly: widget.readOnly,
                      enabled: !widget.readOnly,
                    ),
                    const SizedBox(height: 15),
                    const Text("Changer couleur"),
                    Wrap(
                      spacing: 8,
                      children: allColors.map((color) {
                        return GestureDetector(
                          onTap: widget.readOnly
                              ? null
                              : () {
                                  setStateDialog(() {
                                    selectedColor = color;
                                  });
                                },
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: selectedColor == color ? 18 : 14,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                    const Text("Changer icône"),
                    Wrap(
                      spacing: 10,
                      children: allIcons.map((icon) {
                        return GestureDetector(
                          onTap: widget.readOnly
                              ? null
                              : () {
                                  setStateDialog(() {
                                    selectedIcon = icon;
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selectedIcon == icon
                                  ? selectedColor.withOpacity(0.3)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: selectedColor),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: widget.readOnly
                      ? null
                      : () async {
                          String oldName = types[index]["name"];
                          String newName = controller.text;

                          // 🔥 إذا تبدل الاسم - احذف القديم وانشئ جديد
                          if (oldName != newName) {
                            await FirebaseFirestore.instance
                                .collection("medicine_types")
                                .doc(oldName)
                                .delete();
                          }

                          // 🔥 احفظ في Firebase
                          await FirebaseFirestore.instance
                              .collection("medicine_types")
                              .doc(newName)
                              .set({
                            "name": newName,
                            "icon": selectedIcon.codePoint,
                            "color": selectedColor.value,
                            "fav": types[index]["fav"],
                            "count": types[index]["count"],
                          });

                          // 🔥 update local list
                          setState(() {
                            types[index] = {
                              "name": newName,
                              "icon": selectedIcon,
                              "color": selectedColor,
                              "fav": types[index]["fav"],
                              "count": types[index]["count"],
                            };
                          });

                          Navigator.pop(context);
                        },
                  child: const Text("Valider"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showDeleteDialog() {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer type"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: types.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(types[index]["name"]),
                onTap: widget.readOnly
                    ? null
                    : () {
                        Navigator.pop(context);
                        confirmDelete(index);
                      },
              );
            },
          ),
        ),
      ),
    );
  }

  void confirmDelete(int index) {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text("Supprimer ${types[index]["name"]} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Non"),
          ),
          ElevatedButton(
            onPressed: widget.readOnly
                ? null
                : () async {
                    String deletedName =
                        types[index]["name"]; // 🔥 احفظ الاسم قبل الحذف

                    setState(() {
                      types.removeAt(index);
                    });

                    // 🔥 احذف من Firebase مباشرة
                    await FirebaseFirestore.instance
                        .collection("medicine_types")
                        .doc(deletedName)
                        .delete();

                    Navigator.pop(context);
                  },
            child: const Text("Oui"),
          ),
        ],
      ),
    );
  }

  List<IconData> allIcons = [
    Icons.medication,
    Icons.local_drink,
    Icons.spa,
    Icons.vaccines,
    Icons.healing,
    Icons.air,
    Icons.water_drop,
    Icons.sanitizer,

    // 🔥 ICONS جدد
    Icons.biotech,
    Icons.medical_services,
    Icons.health_and_safety,
    Icons.science,
    Icons.bloodtype,
    Icons.monitor_heart,
  ];

  List<Color> allColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.cyan,

    // 🔥 COLORS جدد
    Colors.indigo,
    Colors.amber,
    Colors.deepOrange,
    Colors.lime,
    Colors.brown,
    Colors.grey,
  ];
//UI
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
    Future<void> playSounds(String name) async {
      Map<String, Map<String, String>> sounds = {
        "Gélule": {
          "fr": "gelule_fr.mp3",
          "en": "Capsules_en.mp3",
          "ar": "gellull_ar.mp3",
        },
        "Comprimé": {
          "fr": "comprime_fr.mp3",
          "en": "Tablets_en.mp3",
          "ar": "commprimee_ar.mp3",
        },
        "Sirop": {
          "fr": "sirop_fr.mp3",
          "en": "Syrup_en.mp3",
          "ar": "sirooo_ar.mp3",
        },
        "Crème": {
          "fr": "creme_fr.mp3",
          "en": "Cream_en.mp3",
          "ar": "crame_ar.mp3",
        },
        "Injection": {
          "fr": "injection_fr.mp3",
          "en": "Injectiono_en.mp3",
          "ar": "injectionnn_ar.mp3",
        },
        "Gouttes": {
          "fr": "goutte_fr.mp3",
          "en": "Drops_en.mp3",
          "ar": "gout_ar.mp3",
        },
        "Patch": {
          "fr": "patch_fr.mp3",
          "en": "Patchee_en.mp3",
          "ar": "patche_ar.mp3",
        },
        "Inhalateur": {
          "fr": "inhalateur_fr.mp3",
          "en": "Inhaler_en.mp3",
          "ar": "inhalateuur_ar.mp3",
        },
        "Gel": {
          "fr": "gel_fr.mp3",
          "en": "Gell_en.mp3",
          "ar": "gellle_ar.mp3",
        },
        "Sachet": {
          "fr": "sachet_fr.mp3",
          "en": "Packet_en.mp3",
          "ar": "sache_ar.mp3",
        },
        "Spray": {
          "fr": "spray_fr.mp3",
          "en": "Spraye_en.mp3",
          "ar": "sprayy_ar.mp3",
        },
      };

      if (sounds.containsKey(name)) {
        String file = sounds[name]![selectedLanguage] ?? "click.mp3";
        await player.play(AssetSource('Sounds/$file'));
      }
      // 🔥 إذا type جديد → TTS
      else {
        try {
          String translated = await translateText(name);

          if (selectedLanguage == "fr") {
            await tts.setLanguage("fr-FR");
          } else if (selectedLanguage == "en") {
            await tts.setLanguage("en-US");
          } else {
            await tts.setLanguage("ar-SA");
          }

          await tts.setPitch(1);
          await tts.setSpeechRate(0.5);

          await tts.speak(translated);
        } catch (e) {
          print("TTS error: $e");
        }
      }
    }

    var filtered = types
        .where((e) => e["name"].toLowerCase().contains(searchText))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Types de médicaments 💊"),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          // 💾 SAVE - ✅ يبقى كيما هو
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: widget.readOnly
                  ? null
                  : () async {
                      print("SAVE CLICKED");
                      await saveData();
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Données enregistrées")),
                      );
                    }),

          // 🌐 LANGUAGE
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) async {
              setState(() {
                selectedLanguage = value;
              });
              // 🔥 احفظ اللغة مباشرة في Firebase
              await FirebaseFirestore.instance
                  .collection("settings")
                  .doc("language")
                  .set({"lang": value});
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "fr", child: Text("Français 🇫🇷")),
              PopupMenuItem(value: "en", child: Text("English 🇬🇧")),
              PopupMenuItem(value: "ar", child: Text("العربية 🇸🇦")),
            ],
          ),

          // ⚙️ SETTINGS - ✅ يبقى كيما هو
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              if (value == "add") showAddDialog();
              if (value == "edit") showEditDialog();
              if (value == "delete") showDeleteDialog();
            },
            itemBuilder: (context) {
              if (widget.readOnly) {
                return [];
              }
              return const [
                PopupMenuItem(value: "add", child: Text("Ajouter")),
                PopupMenuItem(value: "edit", child: Text("Modifier")),
                PopupMenuItem(value: "delete", child: Text("Supprimer")),
              ];
            },
          ),
          // 📊 CHART
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsPage(types: types),
                ),
              );
            },
          ),
          // IconButton(
          //icon: const Icon(Icons.history),
          //onPressed: () {
          //Navigator.push(
          //context,
          //MaterialPageRoute(
          //builder: (_) => HistoryPage(history: history),
          //),
          //);
          //},
//),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              onPressed: showAddDialog,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // 📦 GRID

          //String today = DateTime.now().toString().substring(0, 10);

          //if (!history.containsKey(today)) {
          //history[today] = {};
          //}

          //if (!history[today].containsKey(type["name"])) {
          //history[today][type["name"]] = 0;
          //}

          //history[today][type["name"]]++;

          Expanded(
            child: GridView.builder(
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                var type = filtered[index];

                Color color = type["color"];
                List favBy = type["favBy"] ?? [];

                bool isFav = favBy.contains(widget.patientId);
//bool isFav = (type["favBy"] ?? []).contains(widget.patientId);
                return GestureDetector(
                  // 👉 NAVIGATION + SOUND + COUNT
                  onTap: () async {
                    // 🔥 1. update محلي

                    // 🔥 2. احفظ count في Firebase مباشرة
                    await FirebaseFirestore.instance
                        .collection("medicine_types")
                        .doc(type["name"])
                        .update({
                      "count": FieldValue.increment(1),
                    });

                    // 🔥 3. NAVIGATION
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicamentsPage(
                          patientId: widget.patientId,
                          typeFilter: type["name"],
                          readOnly: widget.readOnly,
                        ),
                      ),
                    );

                    // 🔥 4. الصوت
                    playSounds(type["name"]);
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          color.withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ❤️ FAVORIS
                        SizedBox(
                          height: 35,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: widget.readOnly
                                ? null
                                : () async {
                                    // 🔥 إذا favBy موش موجودة
                                    type["favBy"] ??= [];

                                    bool isFav = type["favBy"]
                                        .contains(widget.patientId);

                                    if (isFav) {
                                      // ❌ REMOVE
                                      await FirebaseFirestore.instance
                                          .collection("medicine_types")
                                          .doc(type["name"])
                                          .update({
                                        "favBy": FieldValue.arrayRemove(
                                            [widget.patientId])
                                      });

                                      //setState(() {
                                      //   type["favBy"].remove(widget.patientId);
                                      //});
                                    } else {
                                      // ❤️ ADD
                                      await FirebaseFirestore.instance
                                          .collection("medicine_types")
                                          .doc(type["name"])
                                          .update({
                                        "favBy": FieldValue.arrayUnion(
                                            [widget.patientId])
                                      });
                                    }
                                    // setState(() {
                                    //  type["favBy"].add(widget.patientId);
                                    // });
                                    await loadData();
                                  },
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                //(type["favBy"] ?? []).contains(widget.patientId)
                                isFav ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(isFav),
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),

                        // 💊 ICON
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            type["icon"],
                            size: 35,
                            color: color,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 📝 NAME
                        Text(
                          type["name"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
