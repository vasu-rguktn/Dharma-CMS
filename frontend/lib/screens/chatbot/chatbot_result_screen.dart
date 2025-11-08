// In your chatbot result screen where you handle the "File a Case" button click
void onFileACasePressed() {
  // Validate required data before navigation
  if (detectedComplaintType == null || detectedFullName == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Required information is missing'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final chatbotData = {
    'complaintType': detectedComplaintType ?? '', 
    'fullName': detectedFullName ?? '',           
    'phone': detectedPhoneNumber ?? '',           
    'address': detectedAddress ?? '',             
    'details': detectedDetails ?? '',             
  };

  print('chatbotData -> $chatbotData');
  print('CreatePetitionForm.initialData -> ${widget.initialData}');

  // Use named route for better navigation management
  Navigator.pushNamed(
    context,
    '/create-petition',
    arguments: chatbotData,
  );
}