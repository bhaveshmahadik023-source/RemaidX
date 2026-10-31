import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remindx/pages/C1_Place_form.dart';
import 'package:remindx/pages/E1_Alarm_form.dart';
import 'package:remindx/pages/G1_Setting.dart';
import 'D1_shop search_form.dart';
import 'reminder_map_screen.dart';
import 'package:remindx/services/alarm_service.dart';
import 'B4_Map_overview.dart';

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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryTeal,
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get remindersStream {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> dailyAlarmsStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .snapshots();
  }

  Future<void> completeReminder(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMessage('Please log in first.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(id)
          .update({
        'status': 'done',
        'completedAt': FieldValue.serverTimestamp(),
      });

      showMessage('Task marked as completed.');
    } catch (e) {
      showMessage('Could not complete task: $e');
    }
  }

  Future<void> deleteReminder(
    String id, {
    required bool isDailyAlarm,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMessage('Please log in first.');
        return;
      }

      if (isDailyAlarm) {
        await AlarmService.cancel(id);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(id)
            .delete();
      } else {
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(id)
            .delete();
      }

      showMessage('Reminder deleted successfully.');
    } catch (e) {
      showMessage('Could not delete reminder: $e');
    }
  }

  void openPlaceForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const C1PlaceForm(),
      ),
    );
  }

  void openShopSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShopSearchPage(),
      ),
    );
  }

  void openDailyAlarmForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DailyAlarmPage(),
      ),
    );
  }

  void openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const G1Settings(),
      ),
    );
  }

  void openAddReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DEDE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'What do you want to add?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 20),
                ReminderOption(
                  icon: Icons.location_on_outlined,
                  title: 'I know the place',
                  subtitle: 'Choose a place and your task',
                  iconColor: primaryTeal,
                  backgroundColor: lightTeal,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openPlaceForm();
                  },
                ),
                const SizedBox(height: 12),
                ReminderOption(
                  icon: Icons.storefront_outlined,
                  title: 'Find shops for me',
                  subtitle: 'Tell us what to buy and the city',
                  iconColor: const Color(0xFF6155CC),
                  backgroundColor: const Color(0xFFEFEDFF),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openShopSearch();
                  },
                ),
                const SizedBox(height: 12),
                ReminderOption(
                  icon: Icons.alarm,
                  title: 'Daily alarm',
                  subtitle: 'Repeat a task at a fixed time',
                  iconColor: const Color(0xFFBF7900),
                  backgroundColor: const Color(0xFFFFEDCC),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openDailyAlarmForm();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Map tab: show the map screen instead of the reminders list.
    if (selectedIndex == 1) {
      return MapOverviewPage(
        showNav: true,
        onTab: (index) {
          if (index == 2) {
            setState(() {
              selectedIndex = 0;
            });
            openSettings();
            return;
          }

          setState(() {
            selectedIndex = index;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                onChanged: (_) => setState(() {}),
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
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        title: Text(
                          'Filter reminders',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.list),
                        title: const Text('All reminders'),
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                        ),
                        title: const Text('Location reminders'),
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                      ListTile(
                        leading: const Icon(Icons.alarm),
                        title: const Text('Daily alarms'),
                        onTap: () => Navigator.pop(sheetContext),
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

                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              size: 28,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),

      body: SafeArea(
        child: _buildRemindersBody(),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddReminderSheet,
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Add reminder',
        child: const Icon(Icons.add, size: 32),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE0E5E4),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 7,
              bottom: 4,
            ),
            child: Row(
              children: [
                _navItem(
                  0,
                  Icons.notifications_none_rounded,
                  'Reminders',
                ),
                _navItem(
                  1,
                  Icons.map_outlined,
                  'Map',
                ),
                _navItem(
                  2,
                  Icons.settings_suggest_outlined,
                  'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersBody() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please log in.'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: remindersStream,
      builder: (context, placeSnapshot) {
        if (placeSnapshot.hasError) {
          return const Center(
            child: Text('Unable to load reminders.'),
          );
        }

        if (placeSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryTeal,
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: dailyAlarmsStream(user.uid),
          builder: (context, alarmSnapshot) {
            if (alarmSnapshot.hasError) {
              return const Center(
                child: Text('Unable to load daily alarms.'),
              );
            }

            if (alarmSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryTeal,
                ),
              );
            }

            final items = <Map<String, dynamic>>[];

            for (final doc in placeSnapshot.data?.docs ?? []) {
              items.add({
                'id': doc.id,
                'data': doc.data(),
                'isDailyAlarm': false,
              });
            }

            for (final doc in alarmSnapshot.data?.docs ?? []) {
              items.add({
                'id': doc.id,
                'data': doc.data(),
                'isDailyAlarm': true,
              });
            }

            final query = searchController.text.toLowerCase();

            final filtered = items.where((item) {
              final data =
                  item['data'] as Map<String, dynamic>;

              final title = (data['title'] ?? '')
                  .toString()
                  .toLowerCase();

              final place = (data['placeName'] ?? '')
                  .toString()
                  .toLowerCase();

              return title.contains(query) ||
                  place.contains(query);
            }).toList();

            filtered.sort((a, b) {
              final ad =
                  a['data'] as Map<String, dynamic>;
              final bd =
                  b['data'] as Map<String, dynamic>;

              final at = ad['createdAt'];
              final bt = bd['createdAt'];

              if (at is Timestamp && bt is Timestamp) {
                return bt.compareTo(at);
              }

              if (at is Timestamp) return -1;
              if (bt is Timestamp) return 1;

              return 0;
            });

            if (items.isEmpty) {
              return _emptyState();
            }

            if (filtered.isEmpty) {
              return const Center(
                child: Text('No matching reminders found.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                100,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];

                final data =
                    item['data'] as Map<String, dynamic>;

                final isDaily =
                    item['isDailyAlarm'] as bool;

                String? timeLabel;
                String? daysLabel;

                if (isDaily) {
                  final hour =
                      (data['hour'] as num?)?.toInt() ?? 0;

                  final minute =
                      (data['minute'] as num?)?.toInt() ?? 0;

                  final h12 =
                      hour % 12 == 0 ? 12 : hour % 12;

                  timeLabel =
                      '$h12:${minute.toString().padLeft(2, '0')} '
                      '${hour < 12 ? 'AM' : 'PM'}';

                  final days =
                      (data['days'] as List<dynamic>? ?? [])
                          .whereType<num>()
                          .map((day) => day.toInt())
                          .toSet();

                  const dayNames = <int, String>{
                    1: 'Mon',
                    2: 'Tue',
                    3: 'Wed',
                    4: 'Thu',
                    5: 'Fri',
                    6: 'Sat',
                    7: 'Sun',
                  };

                  if (days.length == 7) {
                    daysLabel = 'Every day';
                  } else if (days.isEmpty) {
                    daysLabel = 'No days selected';
                  } else {
                    daysLabel = dayNames.entries
                        .where(
                          (entry) => days.contains(entry.key),
                        )
                        .map((entry) => entry.value)
                        .join(', ');
                  }
                }

                return _reminderCard(
                  id: item['id'] as String,
                  title: (data['title'] ??
                          'Untitled reminder')
                      .toString(),
                  place: isDaily
                      ? 'Daily alarm'
                      : (data['placeName'] ??
                              'Unknown place')
                          .toString(),
                  address: (data['address'] ?? '').toString(),
                  radius: data['radiusM'] ??
                      data['radiusMeters'],
                  alertType:
                      (data['alertType'] ?? 'Message')
                          .toString(),
                  lat: (data['lat'] as num?)?.toDouble(),
                  lng: (data['lng'] as num?)?.toDouble(),
                  status:
                      (data['status'] ?? 'active').toString(),
                  isDailyAlarm: isDaily,
                  timeLabel: timeLabel,
                  daysLabel: daysLabel,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        25,
        20,
        100,
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
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
            subtitle: 'Choose a place and your task',
            iconColor: primaryTeal,
            backgroundColor: lightTeal,
            onTap: openPlaceForm,
          ),
          const SizedBox(height: 12),
          ReminderOption(
            icon: Icons.storefront_outlined,
            title: 'Find shops for me',
            subtitle: 'Tell us what to buy and the city',
            iconColor: const Color(0xFF6155CC),
            backgroundColor: const Color(0xFFEFEDFF),
            onTap: openShopSearch,
          ),
          const SizedBox(height: 12),
          ReminderOption(
            icon: Icons.alarm,
            title: 'Daily alarm',
            subtitle: 'Repeat a task at a fixed time',
            iconColor: const Color(0xFFBF7900),
            backgroundColor: const Color(0xFFFFEDCC),
            onTap: openDailyAlarmForm,
          ),
        ],
      ),
    );
  }

  Widget _reminderCard({
    required String id,
    required String title,
    required String place,
    required String address,
    required dynamic radius,
    required String alertType,
    required double? lat,
    required double? lng,
    required String status,
    required bool isDailyAlarm,
    String? timeLabel,
    String? daysLabel,
  }) {
    final isCompleted = status == 'done';

    return Card(
      color: Colors.white,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFD8DEDE),
        ),
      ),
      child: InkWell(
        onTap: isDailyAlarm
            ? null
            : () {
                if (lat == null || lng == null) {
                  showMessage(
                    'This reminder has no location.',
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReminderMapScreen(
                      title: title,
                      placeName: place,
                      lat: lat,
                      lng: lng,
                      radiusM:
                          (radius as num?)?.toInt() ?? 700,
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDailyAlarm
                      ? const Color(0xFFFFEDCC)
                      : lightTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDailyAlarm
                      ? Icons.alarm
                      : Icons.location_on_outlined,
                  color: isDailyAlarm
                      ? const Color(0xFFBF7900)
                      : primaryTeal,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isCompleted
                            ? Colors.black54
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place,
                      style: const TextStyle(
                        fontSize: 15,
                        color: primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isDailyAlarm && timeLabel != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBF7900),
                        ),
                      ),
                      if (daysLabel != null)
                        Text(
                          daysLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                    if (!isDailyAlarm && address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    if (!isDailyAlarm) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Radius: ${radius ?? 700} m • Alert: $alertType',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    if (isCompleted) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F5E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 15,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isDailyAlarm && !isCompleted)
                IconButton(
                  tooltip: 'Complete task',
                  onPressed: () => completeReminder(id),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2E7D32),
                    size: 28,
                  ),
                ),
              IconButton(
                tooltip: 'Delete reminder',
                onPressed: () => deleteReminder(
                  id,
                  isDailyAlarm: isDailyAlarm,
                ),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    String label,
  ) {
    final selected = selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 2) {
            openSettings();
            return;
          }

          setState(() {
            selectedIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 76,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? lightTeal
                    : Colors.transparent,
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
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
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
  final String subtitle;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const ReminderOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
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
          constraints: const BoxConstraints(
            minHeight: 86,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD8DEDE),
            ),
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
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF656565),
                      ),
                    ),
                  ],
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