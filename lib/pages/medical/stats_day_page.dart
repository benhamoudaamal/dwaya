import 'package:flutter/material.dart';
class StatsDayPage extends StatelessWidget {

  final DateTime selectedDate;

  final List history;

  const StatsDayPage({
    super.key,
    required this.selectedDate,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {

    int pris = history.where(
      (h) => h["status"] == "pris",
    ).length;

    int pasPris = history.where(
      (h) => h["status"] == "pas_pris",
    ).length;

    int attente = history.where(
      (h) => h["status"] == "waiting",
    ).length;
    int total = history.length;

double prisPercent =
    total == 0 ? 0 : (pris / total) * 100;

double pasPrisPercent =
    total == 0 ? 0 : (pasPris / total) * 100;

double attentePercent =
    total == 0 ? 0 : (attente / total) * 100;

    return Scaffold(

      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.green,

        title: Text(
          "📊 Statistiques",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // 📅 DATE
            Container(
              width: double.infinity,
             padding: const EdgeInsets.symmetric(
  horizontal: 15,
  vertical: 10,
),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  )
                ],
              ),

              child: Text(
                "📅 ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ PRIS
            buildStatCard(
  "Pris (${prisPercent.toStringAsFixed(0)}%)",
  pris,
  Colors.green,
  Icons.check_circle,
),

            const SizedBox(height: 15),

            // ❌ PAS PRIS
            buildStatCard(
  "Pas pris (${pasPrisPercent.toStringAsFixed(0)}%)",
  pasPris,
  Colors.red,
  Icons.cancel,
),

            const SizedBox(height: 15),

            // ⏳ ATTENTE
            buildStatCard(
  "En attente (${attentePercent.toStringAsFixed(0)}%)",
  attente,
  Colors.grey,
  Icons.access_time,
),

            const SizedBox(height: 25),

            // 📋 LISTE
            Expanded(
              child: ListView.builder(

                itemCount: history.length,

                itemBuilder: (context, index) {

                  final h = history[index];

                  return Container(

                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),

                    padding:
                        const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                        )
                      ],
                    ),

                    child: Row(
                      children: [

                        const Icon(
                          Icons.medication,
                          color: Colors.green,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(
                                h["name"],
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              Text(
                                "⏰ ${h["time"]}",
                              ),

                              Text(
                                "🌞 ${h["moment"]}",
                              ),
                            ],
                          ),
                        ),

                        Text(

  h["status"] == "pris"
      ? "✅ Pris"

      : h["status"] == "pas_pris"
          ? "❌ Pas pris"
          : "⏳ En attente",

  style: TextStyle(

    color:

    h["status"] == "pris"
        ? Colors.green

        : h["status"] == "pas_pris"
            ? Colors.red
            : Colors.grey,

    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard(
    String title,
    int number,
    Color color,
    IconData icon,
  ) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: color.withOpacity(0.15),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: color,

            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              title,

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          Text(
            number.toString(),

            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}