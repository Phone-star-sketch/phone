import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ViewChart extends StatefulWidget {
  const ViewChart(this.titles, this.values, {super.key});
  final List<String> titles;
  final List<int> values;

  @override
  State<StatefulWidget> createState() => PieChart2State(titles, values);
}

class PieChart2State extends State {
  PieChart2State(
    this.titles,
    this.values,
  );
  final List<String> titles;
  final List<int> values;
  List<Color> colors = [];
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    for (var i = 0; i < titles.length; i++) {
      //colors.add(Colors.primaries[Random().nextInt(Colors.primaries.length)]);
      colors.add(Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
          .withOpacity(1.0));
    }
    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 100,
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                        itemCount: titles.length,
                        itemBuilder: (context, index) {
                          totalAmount = totalAmount + values[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                  width: 10, height: 10, color: colors[index]),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: Text(
                                  '${titles[index]} (${values[index]})',
                                  style: TextStyle(
                                      color: colors[index], fontSize: 20),
                                ),
                              ),
                            ],
                          );
                        }),
                  ),
                  Divider(),
                  Text('المجموع : $totalAmount')
                ],
              ),
            ),
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 10,
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: 0.6,
                      child: Container(
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.red),
                          //width: 1000,
                          //height: 1000,
                          child: Image.asset(
                            //width: 1000,
                            //height: 1000,
                            "images/nb_logo.png",
                          )),
                    ),
                  ),
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 5,
                      centerSpaceRadius: 200,
                      sections: showingSections(colors, titles, values),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections(
      List<Color> colors, List<String> titles, List<int> values) {
    int total = 0;
    for (var value in values) {
      total = total + value;
    }
    return List.generate(titles.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      final ratio = ((values[i] / total) * 100).toStringAsFixed(0);
      const shadows = [Shadow(color: Colors.white, blurRadius: 10)];
      print('debug');
      return PieChartSectionData(
        color: colors[i],
        value: ratio == '0' ? 0 : double.parse(values[i].toString()),
        title: ratio == '0' ? null : '(${values[i]}) $ratio%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      );
    });
  }
}
