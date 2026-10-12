import 'package:remindx/auth_service.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/place.dart';

import 'B4_Map_overview.dart';
import 'C2_Map_picker.dart';
import 'C3_Search_results.dart';

// Main screen after login. It holds the bottom menu and switches the 3 tabs:
//   0 = Reminders (temporary test screen for now)
//   1 = Map (B4)
//   2 = Settings (temporary, only has Log out)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0; // which tab is open

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tabs alive, so the map does not reload on every switch.
      body: IndexedStack(
        index: _index,
        children: const [
          _RemindersTab(),
          MapOverviewPage(showNav: false), // the menu below is ours, not B4's
          _SettingsTab(),
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
              label: 'Reminders'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: kTeal),
              label: 'Map'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: kTeal),
              label: 'Settings'),
        ],
      ),
    );
  }
}

// TEMPORARY: until the real Home (B1) is built, this tab only has
// two buttons to test C3 (search) and C2 (map picker).
class _RemindersTab extends StatefulWidget {
  const _RemindersTab();

  @override
  State<_RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<_RemindersTab> {
  PickedPlace? _last; // the last place returned by C3 or C2

  Future<void> _openSearch() async {
    final p = await Navigator.push<PickedPlace>(
        context, MaterialPageRoute(builder: (_) => const SearchResultsPage()));
    if (p != null) setState(() => _last = p);
  }

  Future<void> _openMap() async {
    final p = await Navigator.push<PickedPlace>(
        context, MaterialPageRoute(builder: (_) => const MapPickerPage()));
    if (p != null) setState(() => _last = p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text('RemindX',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reminders list will come here (B1)',
                  style: TextStyle(color: kTextGrey)),
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
              // Shows what C3 / C2 returned
              if (_last != null) ...[
                Text(_last!.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '${_last!.lat.toStringAsFixed(5)}, ${_last!.lng.toStringAsFixed(5)}',
                    style: const TextStyle(color: kTextGrey)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// TEMPORARY Settings tab: only a Log out button for now (G1 comes later).
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: kTeal, foregroundColor: Colors.white),
          onPressed: () => AuthService().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ),
    );
  }
}