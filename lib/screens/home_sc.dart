import 'package:flutter/material.dart';
import 'input_sc.dart';
import 'history_sc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // History is rebuilt every time you open the tab, so it always shows fresh data.
      // Trade-off: text typed in the New tab is cleared when you switch tabs.
      body: _index == 0 ? const InputScreen() : const HistoryScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'New'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}