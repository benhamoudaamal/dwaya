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
import '../patient/rendezvous_page.dart';
import '../../widgets/chatbot_page.dart';
import '../../widgets/notifications_page.dart';
import 'Family_Profile_Page.dart';
import '../auth/login_page.dart';

class FamilyPatientsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const FamilyPatientsPage({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<FamilyPatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<FamilyPatientsPage> {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
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
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.patientId)
        .get();

    setState(() {
      patientName = "${doc["nom"]} ${doc["prenom"]}";
    });
  }

  Future<void> checkSOSNotifications() async {
    final snap = await FirebaseFirestore.instance
        .collection("family_notifications")
        .where(
          "patientId",
          isEqualTo: widget.patientId,
        )
        .where(
          "read",
          isEqualTo: false,
        )
        .get();

    if (snap.docs.isNotEmpty) {
      await flutterTts.setLanguage("fr-FR");

      await flutterTts.speak("Il y a un cas d'urgence");

      for (var doc in snap.docs) {
        await FirebaseFirestore.instance
            .collection("family_notifications")
            .doc(doc.id)
            .update({
          "read": true,
        });
      }
    }
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

        //  RDV غدوة
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
        .collection("family_notifications")
        .where(
          "patientId",
          isEqualTo: widget.patientId,
        )
        .where("read", isEqualTo: false)
        .get();

    for (var doc in snap.docs) {
      await FirebaseFirestore.instance
          .collection("family_notifications")
          .doc(doc.id)
          .update({
        "read": true,
      });
    }
  }

  @override
  void initState() {
    super.initState();
    
    _listenToSOSNotifications();
    initNotifications();
    loadTomorrowRdv();
    checkSOSNotifications();

    print("INIT STATE CALLED");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadPatientName();
      loadTodayMeds();
    });
  }

  void _listenToSOSNotifications() {
    FirebaseFirestore.instance
        .collection("family_notifications")
        .where("patientId", isEqualTo: widget.patientId)
        .where("read", isEqualTo: false)
        .snapshots()
        .listen((snap) async {
      if (snap.docs.isNotEmpty) {
        await flutterTts.setLanguage("fr-FR");
        await flutterTts.speak("Il y a un cas d'urgence");

        for (var doc in snap.docs) {
          await FirebaseFirestore.instance
              .collection("family_notifications")
              .doc(doc.id)
              .update({"read": true});
        }
      }
    });
  }

  Future<void> initNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: android);

    await notificationsPlugin.initialize(settings);

    //  CREATE CHANNEL
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

    //  PERMISSION
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
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduled.isBefore(now.subtract(
        const Duration(seconds: 30),
      ))) {
        return;
      }
      print("NOTIFICATION SCHEDULED = $scheduled");

      await notificationsPlugin.zonedSchedule(
        med["id"].hashCode,
        "💊 Heure du médicament",
        "${med["name"]} - ${med["quantite"]} - ${med["moment"]}",
        tz.TZDateTime.local(
          scheduled.year,
          scheduled.month,
          scheduled.day,
          scheduled.hour,
          scheduled.minute,
        ),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_channel',
            'Médicaments',
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

      // 🔊 VOICE
      // 🔊 VOICE
      Future.delayed(
        scheduled.difference(now),
        () async {
          String message = "حان الآن أخذ الدواء رقم $ordre "
              "${med["name"]} "
              "واسمه ${med["name"]} "
              "نوع الدواء ${med["type"]} "
              "الجرعة ${med["quantite"]} "
              "يؤخذ ${med["moment"]}";

          await flutterTts.setLanguage("ar");

          await flutterTts.setSpeechRate(0.30);

          await flutterTts.setPitch(1);

          //  3 مرات
          for (int repeat = 0; repeat < 3; repeat++) {
            //  يبدأ blinking
            // setState(() {
            // activeMedId = med["id"];
            // });

            //  blinking

            flutterTts.speak(message);

            //for (int i = 0; i < 12; i++) {
            //await Future.delayed(
            //const Duration(milliseconds: 500),
            //);

            //setState(() {
            //blink = !blink;
            //});
            //}

            //  الصوت
            await flutterTts.speak(message);

            //  يوقف blinking
            // setState(() {
            // activeMedId = "";
            // });

            //  يستنى دقيقة
            if (repeat < 2) {
              await Future.delayed(
                const Duration(minutes: 1),
              );
            }
          }
        },
      );
    } catch (e) {
      print("NOTIFICATION ERROR = $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👨‍👩‍👧 ${widget.patientName}"),
            const Text(
              "Welcome 👋",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("family_notifications")
                .where(
                  "patientId",
                  isEqualTo: widget.patientId,
                )
                .where(
                  "read",
                  isEqualTo: false,
                )
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                    ),
                    onPressed: () async {
                      await markNotificationsAsRead();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsPage(
                            collectionName: "family_notifications",
                            patientId: widget.patientId,
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
                Icons.calendar_month,
              ),
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
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FamilyProfilePage(),
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
                color: Colors.white,
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
                        /*color: activeMedId == m["id"]
                            ? (blink ? Colors.red.shade100 : Colors.white)
                            : Colors.white,*/
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            /* color: activeMedId == m["id"]
                                ? (blink
                                    ? Colors.red.withOpacity(0.6)
                                    : Colors.black12)
                                : Colors.black12,*/
                            color: Colors.black12,
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
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 10),

// 💊 Médicaments (READ ONLY)
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  buildDashboardCard(
                    Icons.medication,
                    "Médicaments",
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TypesMedicamentsPage(
                            patientId: widget.patientId,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  buildDashboardCard(
                    Icons.science,
                    "Analyses",
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnalysePage(
                            patientId: widget.patientId,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  buildDashboardCard(
                    Icons.folder,
                    "Dossier médical",
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DossierMedicalPage(
                            patientId: widget.patientId,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  buildDashboardCard(
                    Icons.history,
                    "Historique",
                    Colors.teal,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryPage(
                            patientId: widget.patientId,
                          ),
                        ),
                      );
                    },
                  ),
                  buildDashboardCard(
                    Icons.calendar_month,
                    "Rendez-vous",
                    Colors.redAccent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RendezVousPage(
                            patientId: widget.patientId,
                            patientName: patientName,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  buildDashboardCard(
                    Icons.smart_toy,
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

  Widget buildDashboardCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
