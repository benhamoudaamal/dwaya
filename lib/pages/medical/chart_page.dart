import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';

class ChartPage extends StatefulWidget {
  final String colonne;
  final Map<String, Map<String, String>> data;

  const ChartPage(this.colonne, this.data, {super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final TextEditingController doctorCtrl = TextEditingController();

  final AudioPlayer player = AudioPlayer();

  String get safeId =>
      widget.colonne.trim().replaceAll(" ", "_");

  List<double> values = [];
  List<MapEntry<String, Map<String, String>>> entries = [];

  List<double> lowGroup = [];
  List<double> midGroup = [];
  List<double> highGroup = [];

  bool blink = false;
  bool alarmPlayed = false;

  // 🎨 COLORS
  Color getColor(double v) {
    if (lowGroup.contains(v)) return Colors.blue;
    if (midGroup.contains(v)) return Colors.green;
    return Colors.red;
  }

  bool isDanger() {
    if (values.isEmpty) return false;
    return getColor(values.last) != Colors.green;
  }

  // 🔊 SOUND
  Future<void> playAlarm() async {
    await player.play(
      AssetSource('mixkit-clear-announce-tones-2861.wav'),
    );
  }

  // 🤖 AI
  String getAIAdvice() {
    if (values.isEmpty) return "No data";

    double last = values.last;
    double prev =
        values.length > 1 ? values[values.length - 2] : last;

    String trend = last > prev
        ? "📈 في ارتفاع"
        : last < prev
            ? "📉 في انخفاض"
            : "➡️ مستقر";

    Color c = getColor(last);

    if (c == Colors.red) {
      return "$trend\n🚨 خطر، لازم متابعة طبية";
    } else if (c == Colors.blue) {
      return "$trend\n⚠️ ضعيف";
    } else {
      return "$trend\n✅ طبيعي";
    }
  }

  int getScore() {
    if (values.isEmpty) return 0;

    Color c = getColor(values.last);

    if (c == Colors.green) return 90;
    if (c == Colors.blue) return 60;

    return 30;
  }

  // 🔥 LOAD FIREBASE
  Future<void> loadData() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final adviceDoc = await FirebaseFirestore.instance
      .collection("charts_data")
      .doc(uid)
      .collection("advice")
      .doc(safeId)
      .get();

  if (adviceDoc.exists) {
    doctorCtrl.text =
        adviceDoc.data()?["doctorAdvice"] ?? "";
  }

  setState(() {});
}
  // 🔥 SAVE FIREBASE
  Future<void> saveDoctorAdvice() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance
      .collection("charts_data")
      .doc(uid)
      .collection("advice")
      .doc(safeId)
      .set({
    "doctorAdvice": doctorCtrl.text,
    "aiAdvice": getAIAdvice(),
    "updatedAt": DateTime.now().toIso8601String(),
  });
}
  @override
  void initState() {
    super.initState();

    loadData();

    Future.doWhile(() async {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return false;

      if (isDanger()) {
        setState(() {
          blink = !blink;
        });

        return true;
      }

      return false;
    });
  }

  @override
  Widget build(BuildContext context) {

    // 🔥 IMPORTANT
    entries = widget.data.entries.toList();

    // 🔥 SORT DATE
    entries.sort((a, b) {
      List p1 = a.key.split('/');
      List p2 = b.key.split('/');

      DateTime d1 = DateTime(
        int.parse(p1[2]),
        int.parse(p1[1]),
        int.parse(p1[0]),
      );

      DateTime d2 = DateTime(
        int.parse(p2[2]),
        int.parse(p2[1]),
        int.parse(p2[0]),
      );

      return d1.compareTo(d2);
    });

    // 🔥 VALUES
    values = entries.map((e) {

      final v = e.value[widget.colonne];

      return double.tryParse(
            v?.toString() ?? "0",
          ) ??
          0;

    }).toList();

    // 🧠 CLUSTER
    List<double> sorted = List.from(values)..sort();

    if (sorted.length >= 3) {

      List<double> diffs = [];

      for (int i = 0; i < sorted.length - 1; i++) {
        diffs.add(sorted[i + 1] - sorted[i]);
      }

      List<int> idx =
          List.generate(diffs.length, (i) => i);

      idx.sort(
        (a, b) => diffs[b].compareTo(diffs[a]),
      );

      int c1 = idx[0];
      int c2 = idx[1];

      if (c1 > c2) {
        int t = c1;
        c1 = c2;
        c2 = t;
      }

      lowGroup = sorted.sublist(0, c1 + 1);
      midGroup = sorted.sublist(c1 + 1, c2 + 1);
      highGroup = sorted.sublist(c2 + 1);
    }

    // 🔊 ALARM
    if (values.isNotEmpty &&
        isDanger() &&
        !alarmPlayed) {

      alarmPlayed = true;
      playAlarm();
    }

    double maxY = values.isNotEmpty
        ? values.reduce(
              (a, b) => a > b ? a : b,
            ) +
            10
        : 100;

    return Scaffold(

      appBar: AppBar(
        title: Text(
          "Analyse ${widget.colonne}",
        ),

        actions: [

          // 💾 SAVE BUTTON
          IconButton(
            icon: const Icon(Icons.save),

            onPressed: () async {

              await saveDoctorAdvice();

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    "✅ Enregistré",
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                Text(
                  "Comparaison de ${widget.colonne}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // 📊 CHART
                SizedBox(
                  height: 300,

                  child: BarChart(
                    BarChartData(

                      maxY: maxY,

                      alignment:
                          BarChartAlignment.spaceAround,

                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(

                            showTitles: true,

                            getTitlesWidget:
                                (value, meta) {

                              int i = value.toInt();

                              if (i >= entries.length) {
                                return Container();
                              }

                              return Text(
                                entries[i].key,
                                style: const TextStyle(
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      barGroups: List.generate(
                        values.length,
                        (i) {

                          return BarChartGroupData(
                            x: i,

                            barRods: [

                              BarChartRodData(
                                toY: values[i],
                                width: 16,
                                color:
                                    getColor(values[i]),
                                borderRadius:
                                    BorderRadius.circular(
                                  6,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🚨 DANGER
                if (values.isNotEmpty && isDanger())

                  AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 400),

                    width: double.infinity,

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color:
                          blink
                              ? Colors.red
                              : Colors.white,

                      borderRadius:
                          BorderRadius.circular(12),

                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),

                    child: Text(
                      "🚨 DANGER",

                      style: TextStyle(
                        color:
                            blink
                                ? Colors.white
                                : Colors.red,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // 🤖 AI
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(15),

                    color: Colors.green.shade50,
                  ),

                  child: Text(getAIAdvice()),
                ),

                const SizedBox(height: 15),

                // 💯 SCORE
                Text(
                  "Score santé: ${getScore()} / 100",
                ),

                const SizedBox(height: 20),

                // 🧑‍⚕️ CONSEIL
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(15),

                    color: Colors.blue.shade50,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Conseil du médecin",

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: doctorCtrl,

                        maxLines: 3,

                        decoration: InputDecoration(
                          hintText:
                              "Écrire un conseil...",

                          filled: true,

                          fillColor: Colors.white,

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🎨 LEGEND
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    buildLegend(
                      Colors.blue,
                      "Faible",
                    ),

                    buildLegend(
                      Colors.green,
                      "Normal",
                    ),

                    buildLegend(
                      Colors.red,
                      "Élevé",
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLegend(
    Color color,
    String text,
  ) {

    return Row(
      children: [

        Container(
          width: 12,
          height: 12,
          color: color,
        ),

        const SizedBox(width: 5),

        Text(text),

        const SizedBox(width: 15),
      ],
    );
  }
}