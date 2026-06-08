import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class StatsPage extends StatelessWidget {
  final List<Map<String, dynamic>> types;

  const StatsPage({super.key, required this.types});

  @override
  Widget build(BuildContext context) {

    // 🔥 نحسب total
    double total = 0;
    for (var t in types) {
      total += (t["count"] ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistiques 📊"),
        backgroundColor: Colors.green,
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade200,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [

            const SizedBox(height: 20),

            // 🔥 TOTAL TODAY
            Text(
              "Total اليوم: ${total.toInt()}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 CHART
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: PieChart(
                  PieChartData(
                    sections: types.map((type) {

                      final value = (type["count"] ?? 0).toDouble();

                      // 🔥 ما نظهروش types فارغين
                      if (value == 0) {
  return PieChartSectionData(
    value: 0.1,
    title: "",
    color: type["color"].withOpacity(0.2),
  );
}

                      return PieChartSectionData(
                        value: value == 0 ? 0.1 : value,
                        title: "${type["name"]}\n${type["count"]}",
                        radius: 90,
                        color: type["color"],
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );

                    }).whereType<PieChartSectionData>().toList(),
                  ),
                ),
              ),
            ),

            // 🔥 LIST DETAILS
            Expanded(
              child: ListView(
                children: types.map((type) {

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: type["color"],
                      child: Icon(type["icon"], color: Colors.white),
                    ),
                    title: Text(type["name"]),
                    trailing: Text("${type["count"]} fois"),
                  );

                }).toList(),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
