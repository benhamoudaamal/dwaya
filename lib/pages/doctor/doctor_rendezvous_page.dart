import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
class DoctorRendezVousPage
    extends StatefulWidget {

  const DoctorRendezVousPage({
    super.key,
  });

  @override
  State<DoctorRendezVousPage>
      createState() =>
          _DoctorRendezVousPageState();
}

class _DoctorRendezVousPageState
    extends State<DoctorRendezVousPage> {

  List allRdv = [];

  DateTime selectedDay =
      DateTime.now();

  DateTime focusedDay =
      DateTime.now();

  // 🔥 LOAD RDV
  Future<void> loadRdv() async {

    final snapshot =
        await FirebaseFirestore.instance
            .collection("rendezvous")
            .get();

    setState(() {

      allRdv =
          snapshot.docs.map((doc) {

        return doc.data();

      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();

    loadRdv();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF8FAFC),

      appBar: AppBar(

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        elevation: 0,

        centerTitle: true,

        title: const Text(
          "📅 Liste Rendez-vous",
        ),
      ),

      body: Column(
        children: [

          // ❤️ CALENDAR
          Container(

            margin:
                const EdgeInsets.all(15),

            padding:
                const EdgeInsets.all(10),

            decoration: BoxDecoration(

              gradient: LinearGradient(

                colors: [
                  Colors.white,
                  Colors.red.shade50,
                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                      28),

              boxShadow: [

                BoxShadow(
                  color: Colors.red
                      .withOpacity(0.1),

                  blurRadius: 20,

                  offset:
                      const Offset(0, 8),
                ),
              ],
            ),

            child: TableCalendar(

              firstDay:
                  DateTime.utc(
                      2020, 1, 1),

              lastDay:
                  DateTime.utc(
                      2030, 12, 31),

              focusedDay:
                  focusedDay,

              availableGestures:
                  AvailableGestures.all,

              // ❤️ EVENTS
              eventLoader: (day) {

                return allRdv.where((rdv) {

                  DateTime rdvDate =
                      DateFormat(
                              "d/M/yyyy")
                          .parse(
                              rdv["date"]);

                  return isSameDay(
                    rdvDate,
                    day,
                  );

                }).toList();
              },

              selectedDayPredicate:
                  (day) {

                return isSameDay(
                  selectedDay,
                  day,
                );
              },

              onDaySelected: (
                selected,
                focused,
              ) {

                setState(() {

                  selectedDay =
                      selected;

                  focusedDay =
                      focused;
                });
              },

              calendarStyle:
                  CalendarStyle(

                markerDecoration:
                    const BoxDecoration(

                  color: Colors.red,
                  shape:
                      BoxShape.circle,
                ),

                markersMaxCount: 1,

                todayDecoration:
                    BoxDecoration(
  color: const Color(0xFF4A90E2),
  shape: BoxShape.circle,
),

                selectedDecoration:
                    BoxDecoration(

                  gradient:
                      const LinearGradient(

                    colors: [
                      Colors.redAccent,
                      Colors.orange,
                    ],
                  ),

                  shape:
                      BoxShape.circle,

                  boxShadow: [

                    BoxShadow(
                      color: Colors.red
                          .withOpacity(
                              0.5),

                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ❤️ LISTE
          Expanded(

            child:
                StreamBuilder<
                    QuerySnapshot>(

              stream:
                  FirebaseFirestore
                      .instance
                      .collection(
                          "rendezvous")
                      .snapshots(),

              builder: (
                context,
                snapshot,
              ) {

                if (!snapshot.hasData) {

                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                // ❤️ FILTER DATE
                final filtered =
                    docs.where((doc) {

                  final data =
                      doc.data()
                          as Map<String,
                              dynamic>;

                  final rdvDate =
                      data["date"] ??
                          "";

                  final parts =
                      rdvDate.split("/");

                  if (parts.length !=
                      3) {
                    return false;
                  }

                  final day =
                      int.parse(
                          parts[0]);

                  final month =
                      int.parse(
                          parts[1]);

                  final year =
                      int.parse(
                          parts[2]);

                  final rdvDay =
                      DateTime(
                    year,
                    month,
                    day,
                  );

                  return isSameDay(
                    rdvDay,
                    selectedDay,
                  );

                }).toList();

                // ❤️ SORT TIME
                filtered.sort((a, b) {

                  final ta =
                      ((a.data()
                              as Map<String,
                                  dynamic>)["time"] ??
                          "");

                  final tb =
                      ((b.data()
                              as Map<String,
                                  dynamic>)["time"] ??
                          "");

                  return ta.compareTo(
                      tb);
                });

                // ❤️ EMPTY
                if (filtered.isEmpty) {

                  return Center(

                    child: Column(

                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [

                        Icon(
                          Icons.calendar_month,
                          size: 80,
                          color:
                              Colors.grey
                                  .shade400,
                        ),

                        const SizedBox(
                            height: 15),

                        Text(

                          "Aucun rendez-vous",

                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,

                            color:
                                Colors.grey
                                    .shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [

                    // ❤️ COUNT CARD
                    Container(

                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),

                      padding:
                          const EdgeInsets.all(
                              18),

                      decoration:
                          BoxDecoration(

                        gradient:
                            const LinearGradient(

                          colors: [
                            Colors.redAccent,
                            Colors.orange,
                          ],
                        ),

                        borderRadius:
                            BorderRadius.circular(
                                22),

                        boxShadow: [

                          BoxShadow(
                            color: Colors.red
                                .withOpacity(
                                    0.3),

                            blurRadius: 15,
                          )
                        ],
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.calendar_today,
                            color:
                                Colors.white,
                            size: 30,
                          ),

                          const SizedBox(
                              width: 15),

                          Expanded(

                            child: Text(

                              "Aujourd’hui : ${filtered.length} rendez-vous",

                              style:
                                  const TextStyle(

                                color:
                                    Colors.white,

                                fontSize: 20,

                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ❤️ LISTVIEW
                    Expanded(

                      child:
                          ListView.builder(

                        padding:
                            const EdgeInsets
                                .all(15),

                        itemCount:
                            filtered.length,

                        itemBuilder: (
                          context,
                          index,
                        ) {

                          final data =
                              filtered[index]
                                      .data()
                                  as Map<String,
                                      dynamic>;

                          return Container(

                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 18,
                            ),

                            padding:
                                const EdgeInsets
                                    .all(18),

                            decoration:
                                BoxDecoration(

                              gradient:
                                  LinearGradient(

                                colors:

                                    index == 0

                                    ? [
                                        Colors.red
                                            .shade100,
                                        Colors.white,
                                      ]

                                    : [
                                        Colors.white,
                                        Colors.grey
                                            .shade50,
                                      ],
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          24),

                              boxShadow: [

                                BoxShadow(
                                  color: Colors
                                      .black12,

                                  blurRadius:
                                      10,

                                  offset:
                                      const Offset(
                                          0,
                                          5),
                                )
                              ],
                            ),

                            child: Row(
                              children: [

                                // ❤️ AVATAR
                                CircleAvatar(
  radius: 30,
  backgroundColor: const Color(0xFFEFF6FF),

  child: const Icon(
    Icons.person,
    color: Color(0xFF4A90E2),
    size: 30,
  ),
),

                                const SizedBox(
                                    width: 18),

                                // ❤️ INFOS
                                Expanded(

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      // ❤️ PATIENT NAME
                                      Text(

                                        data["patientName"] ??
                                            "Patient",

                                        style:
                                            const TextStyle(

                                          fontSize:
                                              20,

                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              4),

                                      // ❤️ SPECIALITY
                                      Text(

                                        "Consultation médicale",

                                        style:
                                            TextStyle(

                                          color: Colors
                                              .grey
                                              .shade600,

                                          fontSize:
                                              13,
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              10),

                                      // ❤️ TIME
                                      Container(

                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              12,

                                          vertical:
                                              6,
                                        ),

                                        decoration:
                                            BoxDecoration(

                                          color: Colors
                                              .white,

                                          borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                        ),

                                        child: Text(

                                          "⏰ ${data["time"]}",

                                          style:
                                              const TextStyle(

                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              10),

                                      // ❤️ NOTE
                                      Text(
                                        "📝 ${data["note"]}",
                                      ),

                                      // ❤️ NEXT RDV
                                      if (index ==
                                          0)

                                        Container(

                                          margin:
                                              const EdgeInsets.only(
                                            top: 12,
                                          ),

                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal:
                                                14,

                                            vertical:
                                                6,
                                          ),

                                          decoration:
                                              BoxDecoration(

                                            gradient:
                                                const LinearGradient(

                                              colors: [
                                                Colors.redAccent,
                                                Colors.orange,
                                              ],
                                            ),

                                            borderRadius:
                                                BorderRadius.circular(
                                                    25),
                                          ),

                                          child:
                                              const Text(

                                            "Prochain rendez-vous",

                                            style:
                                                TextStyle(

                                              color:
                                                  Colors.white,

                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

IconButton(
  icon: const Icon(
    Icons.delete,
    color: Colors.red,
    size: 28,
  ),

  onPressed: () {

    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),

        content: const Text(
          "Voulez-vous supprimer ce rendez-vous ?",
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
    .collection("rendezvous")
    .doc(filtered[index].id)
    .delete();

    await loadRdv();

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
                          );
                        },
                      ),
                    ),
                  ],

                );
              },
            ),
          ),
        ],
      ),
    );
  }
}