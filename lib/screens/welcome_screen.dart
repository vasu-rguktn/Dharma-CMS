import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // 🖼️ Header with SVG and Logo
          Container(
            height: screenHeight * 0.4, // Aligned with SvgPicture
            width: double.infinity,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/login_design.svg',
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: screenHeight * 0.4,
                ),
                Center(
                  child: Image.asset(
                    'assets/police_logo.png',
                    fit: BoxFit.contain,
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Error loading logo: $error',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFD32F2F), // Red shade for error
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 📏 Gap between image and text
          const SizedBox(height: 50),
          // 📱 Content Area
          Expanded(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Text(
                          "Dharma Portal",
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12), // Increased from 8 for balance
                        const Text(
                          "Digital hub for Andhra Pradesh police records, Management and analytics",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced from 20 for tighter layout
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _showLoginPopup(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFFC633C), // Red theme
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced from 20
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showRegisterPopup(context);
                              },
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFC633C), // Red theme
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32), // Reduced from 50 for balance
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Explicit border radius
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16), // Add 16px horizontal margins
          child: Container(
            width: MediaQuery.of(context).size.width, // Full width within margins
            height: 250, // Increased height
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15), // Match dialog's border radius
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login', extra: {'userType': 'citizen'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC633C), // Red theme
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Citizen",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login', extra: {'userType': 'police'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC633C), // Red theme
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Police",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRegisterPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Explicit border radius
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16), // Add 16px horizontal margins
          child: Container(
            width: MediaQuery.of(context).size.width, // Full width within margins
            height: 250, // Increased height
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15), // Match dialog's border radius
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/signup', extra: {'userType': 'citizen'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC633C), // Red theme
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Citizen",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: null, // Disabled for Police
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C), // Darker red for disabled
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Police",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}