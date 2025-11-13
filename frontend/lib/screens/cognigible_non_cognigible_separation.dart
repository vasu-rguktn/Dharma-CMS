// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class CognigibleNonCognigibleSeparationScreen extends StatelessWidget {
//   final String classification;
//   const CognigibleNonCognigibleSeparationScreen({super.key, required this.classification});

//   static CognigibleNonCognigibleSeparationScreen fromRouteSettings(BuildContext context, GoRouterState state) {
//     final q = state.extra as Map<String, dynamic>?;
//     return CognigibleNonCognigibleSeparationScreen(
//       classification: q?['classification'] as String? ?? '',
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String upper = (classification).toUpperCase();
//     final bool isNonCognizable = upper.contains('NON-COGNIZABLE');
//     final bool isCognizable = !isNonCognizable && RegExp(r'\bCOGNIZABLE\b').hasMatch(upper);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FE),
//       appBar: AppBar(
//         title: const Text('Offence Classification'),
//         backgroundColor: const Color(0xFFFC633C),
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 30.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 isCognizable
//                     ? 'This case is classified as\n\nCOGNIZABLE'
//                     : 'This case is classified as\n\nNON-COGNIZABLE',
//                 style: TextStyle(
//                   fontSize: 22,
//                   color: isCognizable ? Colors.green[700] : Colors.red[700],
//                   fontWeight: FontWeight.w700,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 50),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => isCognizable
//                       ? context.go('/petitions')
//                       : context.go('/dashboard'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFFC633C),
//                     padding: const EdgeInsets.symmetric(vertical: 18),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     isCognizable ? 'File a Case' : 'Go to Dashboard',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CognigibleNonCognigibleSeparationScreen extends StatelessWidget {
  final String classification;
  final Map<String, dynamic>? complaintData; // added

  const CognigibleNonCognigibleSeparationScreen({
    super.key,
    required this.classification,
    this.complaintData,
  });

  static CognigibleNonCognigibleSeparationScreen fromRouteSettings(
      BuildContext context, GoRouterState state) {
    final q = state.extra as Map<String, dynamic>?;
    return CognigibleNonCognigibleSeparationScreen(
      classification: q?['classification'] as String? ?? '',
      complaintData: q?['complaintData'] as Map<String, dynamic>?, // extract
    );
  }

  @override
  Widget build(BuildContext context) {
    final String upper = (classification).toUpperCase();
    final bool isNonCognizable = upper.contains('NON-COGNIZABLE');
    final bool isCognizable =
        !isNonCognizable && RegExp(r'\bCOGNIZABLE\b').hasMatch(upper);

    // when user taps "File a Case"
    // Convert complaintData to the keys CreatePetitionForm expects
    // (complaintType, fullName, phone, address, details)
    final petitionData = {
      'complaintType': complaintData?['complaintType']??complaintData?['complaint_type']??'' ,
      'fullName': complaintData?['fullName'] ?? complaintData?['full_name'] ?? complaintData?['name'] ?? '',
      'phone': complaintData?['phone'] ?? complaintData?['phoneNumber'] ?? complaintData?['phone_number'] ?? '',
      'address': complaintData?['address'] ?? complaintData?['addr'] ?? complaintData?['location'] ?? '',
      'details': complaintData?['details'] ?? complaintData?['summary'] ?? complaintData?['complaint'] ?? '',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        title: const Text('Offence Classification'),
        backgroundColor: const Color(0xFFFC633C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Main Classification Text ---
              Text(
                isCognizable
                    ? 'This case is classified as\n\nCOGNIZABLE'
                    : 'This case is classified as\n\nNON-COGNIZABLE',
                style: TextStyle(
                  fontSize: 22,
                  color: isCognizable ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              // --- Show extra message for NON-COGNIZABLE ---
              if (isNonCognizable) ...[
                const SizedBox(height: 20),
                Text(
                  'Please Contact To the Officer...',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[1000],
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 50),

              // --- Action Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isCognizable) {
                      // navigate and pass the mapped data
                      context.go('/petitions/create', extra: petitionData);
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC633C),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isCognizable ? 'File a Case' : 'Go to Dashboard',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
