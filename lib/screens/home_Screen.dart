import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          MaterialButton(
              onPressed: () => Navigator.pushNamed(context, '/advertiser'),
              child: const Text('Host')),
          MaterialButton(
              onPressed: () => Navigator.pushNamed(context, '/browser'),
              child: const Text('Receiver')),
        ]),
      ),
    );
  }
}
