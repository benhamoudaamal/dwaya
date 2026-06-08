import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'stats_day_page.dart';
import 'package:intl/intl.dart';
class HistoryPage extends StatefulWidget {
  //final bool readOnly;
  final String patientId;
  const HistoryPage({super.key , required this.patientId ,});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List history = [];
  List allHistory = [];
  DateTime today = DateTime.now();

DateTime selectedDay = DateTime.now();

DateTime focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {

  final snapshot = await FirebaseFirestore.instance
      .collection("history_meds")
      .doc(widget.patientId)
      .collection("items")
      .orderBy("date", descending: true)
      .get();

  setState(() {

    allHistory = snapshot.docs.map((doc) {

      final data = doc.data();

      return {

        "name":
            data["name"] ?? "",

        "time":
            data["time"] ?? "",

        "moment":
            data["moment"] ?? "",

        "quantite":
            data["quantite"] ?? "",

        "type":
            data["type"] ?? "",

        "date":
            data["date"],

        "status":
            data["status"] ?? "waiting",
      };

    }).toList();
    history = allHistory;
  });
}
  Future<void> addHistoryItem(Map<String, dynamic> item) async {
  //final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance
      .collection("history_meds")
      .doc(widget.patientId)
      .collection("items")
      .add(item);

  await loadHistory(); // 🔥 reload مباشرة
}
Color getColor(String status) {
  if (status == "pris") return Colors.green;
  if (status == "pas_pris") return Colors.red;
  return Colors.grey;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,


      appBar: AppBar(
        title: const Text("📅 Historique"),
        backgroundColor: Colors.green,
      ),


      body: Column(
  children: [

    // 📅 CALENDAR
    Container(
      margin: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          )
        ],
      ),

      child: TableCalendar(

        firstDay: DateTime.utc(2020, 1, 1),

        lastDay: DateTime.utc(2030, 12, 31),

        focusedDay: focusedDay,

        selectedDayPredicate: (day) {
          return isSameDay(selectedDay, day);
        },

       

          onDaySelected: (
  selected,
  focused,
) {

  setState(() {

    selectedDay = selected;

    focusedDay = focused;

    history = allHistory.where((h) {

      final date =
          (h["date"] as Timestamp).toDate();

      return isSameDay(
        date,
        selected,
      );

    }).toList();

  });
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => StatsDayPage(
      selectedDate: selected,
      history: history,
    ),
  ),
);

},
      

        calendarStyle: CalendarStyle(

          todayDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),

         selectedDecoration: BoxDecoration(
  color: Colors.green,
  shape: BoxShape.circle,
),
        ),
      ),
    ),

    // 📋 HISTORY
    Expanded(
      child: history.isEmpty

          ? const Center(
              child: Text(
                "Aucun historique",
              ),
            )

          : ListView.builder(

              itemCount: history.length,

              itemBuilder: (
                context,
                index,
              ) {

                final h = history[index];

                final color =
                    getColor(h["status"]);

                return Container(

                  margin:
                      const EdgeInsets.all(10),

                  padding:
                      const EdgeInsets.all(12),

                  decoration: BoxDecoration(

                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        Colors.white
                      ],
                    ),

                    borderRadius:
                        BorderRadius.circular(15),

                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withOpacity(0.3),
                        blurRadius: 8,
                      )
                    ],
                  ),

                  child: Row(
                    children: [

                      CircleAvatar(
                        backgroundColor:
                            color,

                        child: const Icon(
                          Icons.medication,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              h["name"] ?? "",
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              "⏰ ${h["time"] ?? ""}",
                            ),

                            Text(
  "📅 ${DateFormat("dd/MM/yyyy").format((h["date"] as Timestamp).toDate())}",
),
                          ],
                        ),
                      ),

                                        Column(
  children: [

    Text(
      h["status"] == "pris"
          ? "✅ Pris"
          : "❌ Non pris",

      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 8),

    IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.red,
      ),

      onPressed: () {

        showDialog(
          context: context,

          builder: (_) => AlertDialog(

            title: const Text("Confirmation"),

            content: const Text(
              "Voulez-vous supprimer cet historique ?",
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Annuler"),
              ),

              TextButton(
                onPressed: () async {

                  await FirebaseFirestore.instance
                      .collection("historique")
                      .doc(h["id"])
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
  ],
),
                    ],
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
