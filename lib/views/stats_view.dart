import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:phone_system_app/models/client.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  Map<String, double> data = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final stats = await Client.getAccountStats();
      setState(() {
        data = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات الحسابات')),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'توزيع العملاء حسب الحسابات',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: PieChart(
                        chartValuesOptions: const ChartValuesOptions(
                          showChartValueBackground: true,
                          showChartValues: true,
                          showChartValuesInPercentage: true,
                          showChartValuesOutside: false,
                          decimalPlaces: 1,
                        ),
                        legendOptions: const LegendOptions(
                          legendPosition: LegendPosition.right,
                          showLegendsInRow: false,
                          legendTextStyle: TextStyle(fontSize: 16),
                        ),
                        animationDuration: const Duration(seconds: 2),
                        chartLegendSpacing: 32,
                        dataMap: data,
                        colorList: const [
                          Colors.blue,
                          Colors.green,
                          Colors.red,
                          Colors.yellow,
                          Colors.purple,
                          Colors.orange,
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
