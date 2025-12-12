import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String userInput = "";
  String result = "0";

  final List<String> buttons = [
    "C", "⌫", "%", "/",
    "7", "8", "9", "×",
    "4", "5", "6", "-",
    "1", "2", "3", "+",
    "0", ".", "=", 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    userInput,
                    style: const TextStyle(color: Colors.white70, fontSize: 28),
                  ),
                  Text(
                    result,
                    style: const TextStyle(color: Colors.white, fontSize: 48),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: GridView.builder(
              itemCount: buttons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemBuilder: (context, index) {
                return calculatorButton(buttons[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget calculatorButton(String text) {
    Color btnColor = Colors.grey.shade900;
    Color txtColor = Colors.white;

    if (text == "C") {
      btnColor = Colors.redAccent;
    } else if (text == "=") {
      btnColor = Colors.blueAccent;
    } else if (["/", "×", "-", "+"].contains(text)) {
      btnColor = Colors.orangeAccent;
    }

    return InkWell(
      onTap: () {
        setState(() {
          handleInput(text);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: txtColor, fontSize: 26),
          ),
        ),
      ),
    );
  }

  void handleInput(String value) {
    if (value == "C") {
      userInput = "";
      result = "0";
    } else if (value == "⌫") {
      if (userInput.isNotEmpty) {
        userInput = userInput.substring(0, userInput.length - 1);
      }
    } else if (value == "=") {
      calculateResult();
    } else if (value == "×") {
      userInput += "*";
    } else {
      userInput += value;
    }
  }

  void calculateResult() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(userInput);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      result = eval.toString();
    } catch (e) {
      result = "Error";
    }
  }
}
