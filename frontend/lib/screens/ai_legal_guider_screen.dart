// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class AiLegalGuiderScreen extends StatelessWidget {
//   const AiLegalGuiderScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FE),
//       body: Column(
//         children: [
//           // Orange curved header
//           ClipPath(
//             clipper: _CurvedHeaderClipper(),
//             child: Container(
//               width: double.infinity,
//               color: const Color(0xFFFC633C),
//               padding: const EdgeInsets.only(top: 60, left: 32, right: 32, bottom: 48),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'AI Legal Assistant',
//                     style: theme.textTheme.headlineMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Ask me anything about legal matters',
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.normal,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32.0),
//             child: Column(
//               children: [
//                 Text(
//                   'Want to Utilise this feature',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: const Color(0xFF333652),
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 28),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () => context.go('/ai-legal-chat'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFFC633C),
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           'Utilise',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => context.go('/dashboard'),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           side: const BorderSide(color: Color(0xFFFC633C), width: 2),
//                         ),
//                         child: const Text(
//                           'Skip',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFFFC633C),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 48),
//         ],
//       ),
//     );
//   }
// }

// class _CurvedHeaderClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//     path.lineTo(0, size.height - 45);
//     path.quadraticBezierTo(
//       size.width * 0.30,
//       size.height,
//       size.width * 0.70,
//       size.height - 40,
//     );
//     path.quadraticBezierTo(
//       size.width,
//       size.height - 80,
//       size.width,
//       size.height - 25,
//     );
//     path.lineTo(size.width, 0);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }



import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiLegalGuiderScreen extends StatelessWidget {
  const AiLegalGuiderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      body: Column(
        children: [
          // === Orange curved header ===
          ClipPath(
            clipper: _CurvedHeaderClipper(),
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFC633C),
              padding: const EdgeInsets.only(
                top: 60,
                left: 32,
                right: 32,
                bottom: 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Legal Assistant',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask me anything about legal matters',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === Centered Police Logo ===
          const SizedBox(height: 40),
          Center(
            child: Image.asset(
              'assets/police_logo.png',
              width: MediaQuery.of(context).size.width * 0.45,
              fit: BoxFit.contain,
            ),
          ),

          const Spacer(),

          // === Action Section ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Text(
                  'Want to utilise this feature?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF333652),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Utilise Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/ai-legal-chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC633C),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Utilise',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Skip Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/dashboard'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFFC633C),
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFC633C),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 45);
    path.quadraticBezierTo(
      size.width * 0.30,
      size.height,
      size.width * 0.70,
      size.height - 40,
    );
    path.quadraticBezierTo(
      size.width,
      size.height - 80,
      size.width,
      size.height - 25,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
