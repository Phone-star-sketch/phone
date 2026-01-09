import 'package:flutter/material.dart';

class MoneyDisplay extends StatelessWidget {
  final double value;
  final double size;
  final Color textColor;
  final String title;
  final Function()? onAdd;
  final Function()? onSubtraction;

  const MoneyDisplay({
    super.key,
    required this.value,
    this.size = 50,
    this.textColor = Colors.black,
    this.onAdd,
    this.onSubtraction,
    this.title = "",
  });

  @override
  Widget build(BuildContext context) {
    bool isNeg = value < 0;
    int a = value.toInt().abs();
    int b = ((value - value.toInt()) * 100).toInt().abs();

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(size + 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 1),
                    color: (value > 10)
                        ? Colors.greenAccent[100]
                        : (value > 0)
                            ? Colors.yellowAccent
                            : Colors.redAccent,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        b.toString(),
                        style: TextStyle(fontSize: size / 2, color: textColor),
                      ),
                      Text(
                        ".",
                        style: TextStyle(fontSize: size, color: textColor),
                      ),
                      Text(
                        a.toString(),
                        style: TextStyle(
                          fontSize: size,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        isNeg ? "" : "",
                        style: TextStyle(fontSize: size, color: textColor),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          "جنيه",
                          style:
                              TextStyle(fontSize: size / 3, color: textColor),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onAdd,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Text(
                  "تسديد",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onSubtraction,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Text(
                  "اضافة مبلغ",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
