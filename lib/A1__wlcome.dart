
import 'package:flutter/material.dart';

class welcomepage extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const welcomepage({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  State<welcomepage> createState() => _welcomepageState();
}

class _welcomepageState extends State<welcomepage> {
  final Color primaryColor = const Color(0xFF11857D);
  final Color textColor = const Color(0xFF101820);
  final Color subtitleColor = const Color(0xFF667085);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // MAP ILLUSTRATION
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDED),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 20,
                          right: 32,
                          child: Container(
                            width: 123,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBE6BD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 25,
                          bottom: 40,
                          child: Container(
                            width: 90,
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBE6BD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 75,
                          left: -20,
                          right: -20,
                          child: Transform.rotate(
                            angle: 0.03,
                            child: Container(
                              height: 11,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 170,
                          left: -20,
                          right: -20,
                          child: Transform.rotate(
                            angle: -0.03,
                            child: Container(
                              height: 10,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),

                        Positioned(
                          top: -20,
                          bottom: -20,
                          left: 125,
                          child: Transform.rotate(
                            angle: -0.04,
                            child: Container(
                              width: 10,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),

                        Positioned(
                          top: -20,
                          bottom: -20,
                          right: 112,
                          child: Transform.rotate(
                            angle: 0.05,
                            child: Container(
                              width: 10,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 95,
                          top: -30,
                          child: Transform.rotate(
                            angle: -0.75,
                            child: Container(
                              width: 10,
                              height: 380,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),

                        Center(
                          child: Container(
                            width: 176,
                            height: 176,
                            decoration: BoxDecoration(
                              color: const Color(0x3311857D),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        Center(
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Remind me when I arrive',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Pick a place, find shops or set a daily alarm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: subtitleColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 28),

                _optionCard(
                  icon: Icons.location_on_outlined,
                  iconBackground: const Color(0xFFE5F5F3),
                  iconColor: primaryColor,
                  title: 'I know the place',
                  subtitle: 'Add a place and your task',
                ),

                const SizedBox(height: 14),

                _optionCard(
                  icon: Icons.storefront_outlined,
                  iconBackground: const Color(0xFFEEEEFF),
                  iconColor: const Color(0xFF5B4BC4),
                  title: 'Find shops for me',
                  subtitle: 'Tell us what to buy, we suggest shops',
                ),

                const SizedBox(height: 14),

                _optionCard(
                  icon: Icons.alarm_outlined,
                  iconBackground: const Color(0xFFFFEDC9),
                  iconColor: const Color(0xFFD48A00),
                  title: 'Daily alarm',
                  subtitle: 'Repeat a task at a fixed time',
                ),

                const SizedBox(height: 36),

                // GET STARTED -> SIGN UP
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: widget.onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Get started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // EXISTING ACCOUNT -> LOGIN
                TextButton(
                  onPressed: widget.onLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                  child: const Text(
                    'I already have an account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      height: 87,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFD8DDDD),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 29,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
