import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Counter Value:',
            ),
            Text(
              '$_counter',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('increment_button'), // Add a key here
              onPressed: () {
                setState(() {
                  _counter++;
                });
              },
              child: const Text('Increment'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('second_screen_button'), // Add a key here
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SecondScreen()));
              },
              child: const Text('Go to Second Screen'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'This is the Second Screen!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('back_button'), // Add this key
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to First Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
