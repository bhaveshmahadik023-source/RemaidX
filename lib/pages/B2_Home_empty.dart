
import 'D1_shop search_form.dart';
import 'package:flutter/material.dart';


const Color primaryTeal = Color(0xFF117C75);
const Color lightTeal = Color(0xFFE5F4F1);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryTeal,
      ),
    );
  }

  
void selectReminder(String title) {
  if (title == 'Find shops for me') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShopSearchPage(),
      ),
    );
    return;
  }

  showMessage('$title selected. Connection will be added later.');
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Top header
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 54,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search reminders...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'My reminders',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        title: Text(
                          'Filter reminders',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.list),
                        title: const Text('All reminders'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('Location reminders'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.alarm),
                        title: const Text('Daily alarms'),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.filter_list, size: 29),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) searchController.clear();
              });
            },
            icon: Icon(isSearching ? Icons.close : Icons.search, size: 28),
          ),
          const SizedBox(width: 5),
        ],
      ),

      // Home page content
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 100),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 125,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Empty state illustration
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 176,
                            height: 176,
                            decoration: const BoxDecoration(
                              color: lightTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 116,
                            height: 116,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Icon(
                            Icons.location_on_outlined,
                            color: primaryTeal,
                            size: 36,
                          ),
                          const Positioned(
                            top: 24,
                            right: 18,
                            child: Icon(
                              Icons.alarm,
                              color: Color(0xFFBF7900),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    const Text(
                      'No reminders yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Add your first reminder in one of three ways',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF656565),
                      ),
                    ),

                    const SizedBox(height: 30),

                    ReminderOption(
                      icon: Icons.location_on_outlined,
                      title: 'I know the place',
                      iconColor: primaryTeal,
                      backgroundColor: lightTeal,
                      onTap: () => selectReminder('I know the place'),
                    ),

                    const SizedBox(height: 12),

                    ReminderOption(
                      icon: Icons.storefront_outlined,
                      title: 'Find shops for me',
                      iconColor: const Color(0xFF6155CC),
                      backgroundColor: const Color(0xFFEFEDFF),
                      onTap: () => selectReminder('Find shops for me'),
                    ),

                    const SizedBox(height: 12),

                    ReminderOption(
                      icon: Icons.alarm,
                      title: 'Daily alarm',
                      iconColor: const Color(0xFFBF7900),
                      backgroundColor: const Color(0xFFFFEDCC),
                      onTap: () => selectReminder('Daily alarm'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // Floating add button
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Create a reminder',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: primaryTeal,
                            ),
                            title: const Text('I know the place'),
                            onTap: () {
                              Navigator.pop(context);
                              selectReminder('I know the place');
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.storefront_outlined,
                              color: Color(0xFF6155CC),
                            ),
                            title: const Text('Find shops for me'),
                            onTap: () {
                              Navigator.pop(context);
                              selectReminder('Find shops for me');
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.alarm,
                              color: Color(0xFFBF7900),
                            ),
                            title: const Text('Daily alarm'),
                            onTap: () {
                              Navigator.pop(context);
                              selectReminder('Daily alarm');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 32),
            )
          : null,

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E5E4)),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 7, bottom: 4),
            child: Row(
              children: [
                _navItem(0, Icons.notifications_none_rounded, 'Reminders'),
                _navItem(1, Icons.map_outlined, 'Map'),
                _navItem(2, Icons.settings_suggest_outlined, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => selectedIndex = index);
          if (index != 0) {
            showMessage('$label screen will be connected later.');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 76,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? lightTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                size: 27,
                color: selected
                    ? primaryTeal
                    : const Color(0xFF657371),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? primaryTeal
                    : const Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const ReminderOption({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD8DEDE)),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 30,
                color: Color(0xFF667371),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
