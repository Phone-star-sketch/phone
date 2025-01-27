import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ViewChart extends StatefulWidget {
  const ViewChart(this.titles, this.values, {super.key});
  final List<String> titles;
  final List<int> values;

  @override
  State<StatefulWidget> createState() => _ViewChartState(titles, values);
}

class _ViewChartState extends State {
  _ViewChartState(this.titles, this.values);
  final List<String> titles;
  final List<int> values;
  List<Color> colors = [];
  int touchedIndex = -1;
  late double totalAmount;

  @override
  void initState() {
    super.initState();
    totalAmount = values.fold(0, (sum, value) => sum + value).toDouble();
    _generateColors();
  }

  void _generateColors() {
    // Generate visually pleasing colors
    colors = List.generate(titles.length, (index) {
      return HSLColor.fromAHSL(
        1.0,
        (index * 360 / titles.length).toDouble(),
        0.7,
        0.5,
      ).toColor();
    });
  }

  Widget _buildLegendItem(int index) {
    final value = values[index];
    final percentage = totalAmount > 0 
        ? ((value / totalAmount) * 100).toStringAsFixed(1)
        : '0.0';

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: touchedIndex == index 
            ? colors[index].withOpacity(0.15) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors[index].withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colors[index],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[index].withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '${titles[index]} (${values[index]})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: touchedIndex == index ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors[index],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total at build time
    totalAmount = values.fold(0, (sum, value) => sum + value).toDouble();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxWidth < constraints.maxHeight;
        final isMobile = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Title and Total
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'إحصائيات',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'المجموع: ${totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Chart and Legend
              Expanded(
                child: isMobile || isPortrait
                    ? Column(
                        children: [
                          Expanded(child: _buildChart()),
                          SizedBox(height: 16),
                          Expanded(child: _buildLegend()),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildChart()),
                          SizedBox(width: 24),
                          SizedBox(
                            width: 300,
                            child: _buildLegend(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    touchedIndex = pieTouchResponse?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: _generateSections(),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics, size: 32, color: Colors.red),
                SizedBox(height: 8),
                Text(
                  'الإجمالي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  totalAmount.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: titles.length,
        itemBuilder: (context, index) => _buildLegendItem(index),
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    double total = values.fold(0, (sum, item) => sum + item);
    if (total == 0) total = 1; // Prevent division by zero

    return List.generate(titles.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final value = values[i].toDouble();
      
      // Calculate percentage safely
      final percentage = total > 0 
          ? ((value / total) * 100).toStringAsFixed(1)
          : '0.0';

      return PieChartSectionData(
        color: colors[i],
        value: value,
        title: value > 0 ? '$percentage%' : '',  // Only show percentage if value > 0
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: isTouched && value > 0 ? _Badge(
          '${titles[i]}\n${value.toInt()}',  // Show both title and value
          size: 40,
          borderColor: colors[i],
        ) : null,
        badgePositionPercentageOffset: 1.2,
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });
  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * 0.2,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}
