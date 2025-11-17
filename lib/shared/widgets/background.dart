import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final bool login;
  const Background({super.key, required this.child, this.login = false});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 200,
                color: Colors.white,
                child: const Center(
                  child: SafeArea(
                    child: Image(
                      height: 130,
                      image: AssetImage('assets/logo.png'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: _createCardShape(),
                  child: Center(child: SingleChildScrollView(child: child)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

BoxDecoration _createCardShape() => const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment(0.1, 0.2),
    colors: <Color>[
      Color.fromRGBO(252, 207, 62, 1),
      Color.fromRGBO(250, 129, 36, 1),
    ],
  ),
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(40),
    topRight: Radius.circular(40),
    bottomLeft: Radius.circular(0),
    bottomRight: Radius.circular(0),
  ),
);

// ignore: camel_case_types
