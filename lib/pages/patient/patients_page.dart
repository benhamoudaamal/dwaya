import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../medical/types_medicaments_page.dart';
import '../medical/analyse_page.dart';
import '../medical/dossier_medical_page.dart';
import '../medical/history_page.dart';
import 'rendezvous_page.dart';
import '../../widgets/chatbot_page.dart';
import '../../widgets/notifications_page.dart';
import 'patient_profile_page.dart';
import '../auth/login_page.dart';
import '../family/family_role_page.dart';

class PatientsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientsPage({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FlutterTts flutterTts = FlutterTts();

  String patientName = "";
  List<Map<String, dynamic>> todayMeds = [];
  String activeMedId = "";
  bool blink = false;
  List<Map<String, dynamic>> tomorrowRdv = [];

  bool rdvBlink = false;

  Future<void> loadTodayMeds() async {
    print("LOAD TODAY MEDS START");
    final uid = widget.patientId;

    print("CURRENT UID = $uid");

    final snap = await FirebaseFirestore.instance
        .collection("meds")
        .where("patientId", isEqualTo: uid)
        .get();

    print("DOCS COUNT = ${snap.docs.length}");

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    List<Map<String, dynamic>> medsList = [];

    for (var e in snap.docs) {
      final data = e.data();

      try {
        final startRaw = data["dateDebut"];
        final endRaw = data["dateFin"];

        DateTime start;
        DateTime end;

        // ✅ Timestamp
        if (startRaw is Timestamp) {
          start = startRaw.toDate();
        } else {
          start = DateTime.parse(startRaw.toString());
        }

        if (endRaw is Timestamp) {
          end = endRaw.toDate();
        } else {
          end = DateTime.parse(endRaw.toString());
        }

        final startDay = DateTime(
          start.year,
          start.month,
          start.day,
        );

        final endDay = DateTime(
          end.year,
          end.month,
          end.day,
        );

        print("START = $startDay");
        print("END = $endDay");
        print("TODAY = $today");

        // ✅ اليوم بين البداية والنهاية
        if (!today.isBefore(startDay) && !today.isAfter(endDay)) {
          medsList.add({
            ...data,
            "id": e.id,
          });
        }
      } catch (err) {
        print("ERROR = $err");
      }
    }

    print("TODAY MEDS = ${medsList.length}");
    medsList.sort((a, b) {
      final timeA = a["time"] ?? "";
      final timeB = b["time"] ?? "";

      return timeA.compareTo(timeB);
    });
    for (int i = 0; i < medsList.length; i++) {
      await scheduleMedNotification(
        medsList[i],
        i + 1,
      );
    }

    setState(() {
      todayMeds = medsList;
    });
  }

  Widget buildCard(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          border: Border.all(
            color: const Color(0xFFE3F2FD),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90E2).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22304A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> loadPatientName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    setState(() {
      patientName = "${doc["nom"]} ${doc["prenom"]}";
    });
  }

  Future<void> loadTomorrowRdv() async {
    final snap = await FirebaseFirestore.instance
        .collection("rendezvous")
        .where(
          "patientId",
          isEqualTo: widget.patientId,
        )
        .get();

    DateTime tomorrow = DateTime.now().add(
      const Duration(days: 1),
    );

    List<Map<String, dynamic>> rdvList = [];

    for (var doc in snap.docs) {
      final data = doc.data();

      try {
        DateTime rdvDate = DateFormat("d/M/yyyy").parse(data["date"]);

        // ❤️ RDV غدوة
        if (isSameDay(
          rdvDate,
          tomorrow,
        )) {
          rdvList.add({
            ...data,
            "id": doc.id,
          });
        }
      } catch (e) {}
    }

    setState(() {
      tomorrowRdv = rdvList;

      rdvBlink = rdvList.isNotEmpty;
    });
  }

  Future<void> markNotificationsAsRead() async {
    final snap = await FirebaseFirestore.instance
        .collection("notifications")
        .where(
          "patientId",
          isEqualTo: widget.patientId,
        )
        .where("patientRead", isEqualTo: false)
        .get();

    for (var doc in snap.docs) {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(doc.id)
          .update({
        "patientRead": true,
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initNotifications();
    loadTomorrowRdv();

    print("INIT STATE CALLED");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPatientName();
      loadTodayMeds();
    });
  }

  Future<void> initNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: android);

    await notificationsPlugin.initialize(settings);

    // ❤️ CREATE CHANNEL
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'med_channel',
      'Médicaments',
      description: 'Notification médicaments',
      importance: Importance.max,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ❤️ PERMISSION
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMedNotification(
  Map<String, dynamic> med,
  int ordre,
) async {
  try {
    final time = med["time"];
    if (time == null) return;

    final parts = time.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();

    DateTime scheduled = DateTime(
      now.year, now.month, now.day, hour, minute,
    );

    if (scheduled.isBefore(now.subtract(const Duration(seconds: 30)))) {
      return;
    }

    print("NOTIFICATION SCHEDULED = $scheduled");

    // ✅ Notification système
    await notificationsPlugin.zonedSchedule(
      med["id"].hashCode,
      "💊 Heure du médicament",
      "${med["name"]} - ${med["quantite"]} - ${med["moment"]}",
      tz.TZDateTime.local(
        scheduled.year, scheduled.month, scheduled.day,
        scheduled.hour, scheduled.minute,
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel', 'Médicaments',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'Médicament',
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // ✅ Alerte vocale
    Future.delayed(scheduled.difference(now), () async {
      if (!mounted) return;

      final String message =
          "حان الآن موعد أخذ الدواء رقم $ordre. "
          "اسم الدواء ${med["name"]}. "
          "نوع الدواء ${med["type"]}. "
          "الجرعة ${med["quantite"]}. "
          "يؤخذ ${med["moment"]}.";

      await flutterTts.setLanguage("ar-SA");
      await flutterTts.setSpeechRate(0.35);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
      // ✅ PAS de awaitSpeakCompletion ici

      for (int repeat = 0; repeat < 3; repeat++) {
        if (!mounted) return;

        setState(() {
          activeMedId = med["id"];
          blink = true;
        });

        // ✅ Speak et blink en parallèle
        flutterTts.speak(message); // sans await

        // ✅ Blink pendant ~8 secondes (durée du message)
        for (int i = 0; i < 16; i++) {
          if (!mounted) return;
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() { blink = !blink; });
        }

        if (!mounted) return;
        setState(() {
          activeMedId = "";
          blink = false; // ✅ reset propre
        });

        if (repeat < 2) {
          await Future.delayed(const Duration(seconds: 30));
        }
      }
    });

  } catch (e) {
    print("NOTIFICATION ERROR = $e");
  }
}

  Future<void> sendSOS() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 🚨 alert
    await FirebaseFirestore.instance.collection("alerts").add({
      "userId": uid,
      "patientName": patientName,
      "type": "SOS",
      "status": "pending",
      "date": FieldValue.serverTimestamp(),
    });

    // 🔔 notification doctor
    await FirebaseFirestore.instance.collection("doctor_notifications").add({
      "title": "🚨 SOS urgence",
      "body": "$patientName a envoyé une alerte SOS",
      "patientId": uid,
      "date": Timestamp.now(),
      "read": false,
    });
    await FirebaseFirestore.instance.collection("family_notifications").add({
      "patientId": uid,
      "title": "🚨 SOS URGENCE",
      "message": "$patientName a besoin d'aide immédiatement",
      "date": Timestamp.now(),
      "read": false,
    });
  }

  Future<void> updateEtatMed(
    Map<String, dynamic> med,
    String etat,
  ) async {
    // 🔥 update etat
    await FirebaseFirestore.instance.collection("meds").doc(med["id"]).update({
      "etatToday": etat,
    });

    // 🔥 document unique
    String today = DateTime.now().toString().substring(0, 10);

    String docId = "${med["id"]}_$today";

    // 🔥 save history
    await FirebaseFirestore.instance
        .collection("history_meds")
        .doc(widget.patientId)
        .collection("items")
        .doc(docId)
        .set({
      "name": med["name"],
      "time": med["time"],
      "moment": med["moment"],
      "quantite": med["quantite"],
      "type": med["type"],
      "status": etat,
      "date": Timestamp.now(),
    });

    // 🔥 reload
    await loadTodayMeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEFF6FF),
              child: const Icon(
                Icons.person,
                color: Color(0xFF4A90E2),
                size: 24,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22304A),
                    ),
                  ),
                  const Text(
                    "Votre santé, notre priorité 🩺",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("notifications")
                .where(
                  "patientId",
                  isEqualTo: widget.patientId,
                )
                .where("patientRead", isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              print("PATIENT COUNT = ${snapshot.data?.docs.length}");
              int count = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    onPressed: () async {
                      await markNotificationsAsRead();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsPage(
                            patientId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      );
                    },
                  ),

                  // 🔴 POINT ROUGE
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          AnimatedContainer(
            duration: const Duration(
              milliseconds: 500,
            ),
            decoration: BoxDecoration(
              color: rdvBlink ? Colors.red : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                  //Icons.calendar_month,
                  Icons.calendar_today_rounded),
              color: rdvBlink ? Colors.white : Colors.red,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text(
                      "📅 Rendez-vous demain",
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: tomorrowRdv.isEmpty
                          ? const Text(
                              "Aucun rendez-vous demain",
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: tomorrowRdv.length,
                              itemBuilder: (context, index) {
                                final rdv = tomorrowRdv[index];

                                return ListTile(
                                  leading: const Icon(
                                    Icons.calendar_month,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    rdv["time"] ?? "",
                                  ),
                                  subtitle: Text(
                                    rdv["note"] ?? "",
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.person_rounded,
              size: 30,
              color: Color(0xFF4A90E2),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientProfilePage(
                    patientId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
// 💊 MÉDICAMENTS D'AUJOURD'HUI
//if (todayMeds.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                //color: Colors.white,
                color: const Color(0xFFF8FBFF),
                border: Border.all(
                  color: const Color(0xFFD6EAF8),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "💊 Médicaments d'aujourd'hui",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...todayMeds.map((m) {
                    return AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 500,
                      ),
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: activeMedId == m["id"]
                            ? (blink ? Colors.red.shade100 : Colors.white)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: activeMedId == m["id"]
                                ? (blink
                                    ? Colors.red.withOpacity(0.6)
                                    : Colors.black12)
                                : Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // 🔥 TOP
                          Row(
                            children: [
                              // 💊 ICON
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.medication,
                                  color: Colors.green,
                                  size: 32,
                                ),
                              ),

                              const SizedBox(width: 15),

                              // 📝 INFOS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m["name"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          m["time"] ?? "",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.wb_sunny,
                                          size: 18,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          m["moment"] ?? "",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.inventory_2,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Quantité : ${m["quantite"]}",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.category,
                                          size: 18,
                                          color: Colors.purple,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Type : ${m["type"]}",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 🔥 BUTTONS
                          Row(
                            children: [
                              // ✅ PRIS
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    setState(() {
                                      activeMedId = "";
                                    });
                                    await updateEtatMed(
                                      m,
                                      "pris",
                                    );
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text("Pris"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: m["etatToday"] == "pris"
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                    foregroundColor: m["etatToday"] == "pris"
                                        ? Colors.white
                                        : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // ❌ PAS PRIS
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    setState(() {
                                      activeMedId = "";
                                    });
                                    await updateEtatMed(
                                      m,
                                      "pas_pris",
                                    );
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text("Pas pris"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        m["etatToday"] == "pas_pris"
                                            ? Colors.red
                                            : Colors.grey.shade300,
                                    foregroundColor:
                                        m["etatToday"] == "pas_pris"
                                            ? Colors.white
                                            : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 10),

            buildCard(
              "🚨 SOS",
              "Envoyer alerte médecin & famille",
              Icons.warning,
              const Color(0xFFE57373),
              () async {
                await sendSOS();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🚨 SOS envoyé")),
                );
              },
            ),
            const SizedBox(height: 5),

// 💊 Médicaments (READ ONLY)

// 🧪 Analyse

            // 📁 Dossier médical
            Padding(
              padding: const EdgeInsets.all(15),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
                children: [
                  serviceCard(
                    "💊",
                    "Médicaments",
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TypesMedicamentsPage(
                            patientId: FirebaseAuth.instance.currentUser!.uid,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  serviceCard(
                    "🧪",
                    "Analyses",
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnalysePage(
                            patientId: FirebaseAuth.instance.currentUser!.uid,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  serviceCard(
                    "📁",
                    "Dossier",
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DossierMedicalPage(
                            patientId: FirebaseAuth.instance.currentUser!.uid,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  serviceCard(
                    "📅",
                    "RDV",
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RendezVousPage(
                            patientId: FirebaseAuth.instance.currentUser!.uid,
                            patientName: patientName,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  serviceCard(
                    "📊",
                    "Historique",
                    Colors.teal,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryPage(
                            patientId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      );
                    },
                  ),
                  serviceCard(
                    "🤖",
                    "Chatbot",
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatBotPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBtn(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget serviceCard(
    String emoji,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      splashColor: const Color(0xFF4A90E2).withOpacity(0.1),
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          border: Border.all(
            color: const Color(0xFFE3F2FD),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 42),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
