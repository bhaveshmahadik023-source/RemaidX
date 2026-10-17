
import 'G1_Setting.dart';

import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/place.dart';

import 'B4_Map_overview.dart';
import 'C2_Map_picker.dart';
import 'C3_Search_results.dart';

// Main screen after login
// 0 = Reminders
// 1 = Map
// 2 = Settings
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _RemindersTab(),
          MapOverviewPage(showNav: false),
          G1Settings(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: kTealLight,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications, color: kTeal),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: kTeal),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: kTeal),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Temporary Reminders tab
class _RemindersTab extends StatefulWidget {
  const _RemindersTab();

  @override
  State<_RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<_RemindersTab> {
  PickedPlace? _last;

  Future<void> _openSearch() async {
    final p = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchResultsPage(),
      ),
    );

    if (p != null) {
      setState(() => _last = p);
    }
  }

  Future<void> _openMap() async {
    final p = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerPage(),
      ),
    );

    if (p != null) {
      setState(() => _last = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text(
          'RemindX',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reminders list will come here (B1)',
                style: TextStyle(color: kTextGrey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _openSearch,
                icon: const Icon(Icons.search),
                label: const Text('Test: Search place (C3)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Test: Map picker (C2)'),
              ),
              const SizedBox(height: 24),
              if (_last != null) ...[
                Text(
                  _last!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_last!.lat.toStringAsFixed(5)}, '
                  '${_last!.lng.toStringAsFixed(5)}',
                  style: const TextStyle(color: kTextGrey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}