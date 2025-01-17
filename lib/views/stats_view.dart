import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class StatsView extends StatelessWidget {
  StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, double> data = {'مواهب': 12, 'الاخلاص': 88};

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: PieChart(
              chartValuesOptions: const ChartValuesOptions(
                showChartValueBackground: true,
                showChartValues: true,
                showChartValuesInPercentage: false,
                showChartValuesOutside: false,
                decimalPlaces: 1,
              ),
              legendOptions: LegendOptions(
                  legendLabels:
                      data.map((key, value) => MapEntry(key, value.toString())),
                  legendPosition: LegendPosition.left),
              animationDuration: const Duration(seconds: 2),
              chartLegendSpacing: 32,
              totalValue: 100,
              dataMap: data,
            ),
          ),
        ),
      ),
    );
  }
}
