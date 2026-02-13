import re

# Read the English file as the base template
with open('lib/l10n/app_localizations_en.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Change class name from English to Hindi
content = content.replace('class AppLocalizationsEn extends AppLocalizations {', 
                         'class AppLocalizationsHi extends AppLocalizations {')
content = content.replace("AppLocalizationsEn([String locale = 'en'])", 
                         "AppLocalizationsHi([String locale = 'hi'])")
content = content.replace("/// The translations for English (`en`).", 
                         "/// The translations for Hindi (`hi`).")

# Comprehensive English to Hindi translation dictionary
translations = {
    # App basics
    "Dharma CMS": "धर्म CMS",
    "Dharma": "धर्म",
    "Dharma Portal": "धर्म पोर्टल",
    "Digital hub for Andhra Pradesh Police records, management and analytics": "आंध्र प्रदेश पुलिस रिकॉर्ड, प्रबंधन और विश्लेषण के लिए डिजिटल हब",
    
    # Auth
    "Login as": "के रूप में लॉगिन करें",
    "Register as": "के रूप में पंजीकरण करें",
    "Citizen": "नागरिक",
    "Police": "पुलिस",
    "Don't have an account?": "खाता नहीं है?",
    "Register": "पंजीकरण करें",
    "Login": "लॉगिन",
    "Logout": "लॉगआउट",
    "Sign In": "साइन इन करें",
    "Sign Out": "साइन आउट करें",
    "Forgot Password?": "पासवर्ड भूल गए?",
    
    # Form fields
    "Full Name": "पूरा नाम",
    "Email": "ईमेल",
    "Phone": "फोन",
    "Date of Birth (YYYY-MM-DD)": "जन्म तिथि (YYYY-MM-DD)",
    "Gender": "लिंग",
    "Male": "पुरुष",
    "Female": "महिला",
    "Other": "अन्य",
    "Next": "अगला",
    "Previous": "पिछला",
    "Username *": "उपयोगकर्ता नाम *",
    "Password": "पासवर्ड",
    "Confirm Password": "पासवर्ड की पुष्टि करें",
    "Phone Number": "फोन नंबर",
    
    # Address
    "Address Details": "पता विवरण",
    "House No": "मकान नंबर",
    "City/Town": "शहर/कस्बा",
    "District": "जिला",
    "State": "राज्य",
    "Country": "देश",
    "Pincode": "पिनकोड",
    "Police Station": "पुलिस स्टेशन",
    "Address": "पता",
    
    # Validation messages
    "Please enter your name": "कृपया अपना नाम दर्ज करें",
    "Name can only contain letters and spaces": "नाम में केवल अक्षर और स्थान हो सकते हैं",
    "Please enter your email": "कृपया अपना ईमेल दर्ज करें",
    "Please enter a valid email": "कृपया एक मान्य ईमेल दर्ज करें",
    "Please enter your phone number": "कृपया अपना फोन नंबर दर्ज करें",
    "Please enter a valid phone number": "कृपया एक मान्य फोन नंबर दर्ज करें",
    "Please select your date of birth": "कृपया अपनी जन्म तिथि चुनें",
    "Enter date in YYYY-MM-DD format": "YYYY-MM-DD प्रारूप में तिथि दर्ज करें",
    "Please select your gender": "कृपया अपना लिंग चुनें",
    "Please fill all fields correctly": "कृपया सभी फ़ील्ड सही ढंग से भरें",
    "Please enter your house number": "कृपया अपना मकान नंबर दर्ज करें",
    "Enter your city": "अपना शहर दर्ज करें",
    "Enter your district": "अपना जिला दर्ज करें",
    "Enter your state": "अपना राज्य दर्ज करें",
    "Enter your country": "अपना देश दर्ज करें",
    "Please enter your pincode": "कृपया अपना पिनकोड दर्ज करें",
    "Enter a valid 6-digit pincode": "एक मान्य 6 अंकों का पिनकोड दर्ज करें",
    "Enter police station": "पुलिस स्टेशन दर्ज करें",
    "Enter username (min 4 characters)": "उपयोगकर्ता नाम दर्ज करें (न्यूनतम 4 अक्षर)",
    "Enter username": "उपयोगकर्ता नाम दर्ज करें",
    "Username must be at least 4 characters": "उपयोगकर्ता नाम कम से कम 4 अक्षरों का होना चाहिए",
    "Enter password (min 6 characters)": "पासवर्ड दर्ज करें (न्यूनतम 6 अक्षर)",
    "Enter password": "पासवर्ड दर्ज करें",
    "Password must be at least 6 characters": "पासवर्ड कम से कम 6 अक्षरों का होना चाहिए",
    "Re-enter password": "पासवर्ड फिर से दर्ज करें",
    "Confirm your password": "अपने पासवर्ड की पुष्टि करें",
    "Passwords do not match": "पासवर्ड मेल नहीं खाते",
    
    # Errors
    "Error: Personal data not provided": "त्रुटि: व्यक्तिगत डेटा प्रदान नहीं किया गया",
    "Error: Required data not provided": "त्रुटि: आवश्यक डेटा प्रदान नहीं किया गया",
    "Error: Invalid email provided": "त्रुटि: अमान्य ईमेल प्रदान किया गया",
    "Error: Failed to create user": "त्रुटि: उपयोगकर्ता बनाने में विफल",
    "Registration successful!": "पंजीकरण सफल!",
    "The email is already registered.": "यह ईमेल पहले से पंजीकृत है।",
    "The email address is invalid.": "ईमेल पता अमान्य है।",
    "The password is too weak.": "पासवर्ड बहुत कमजोर है।",
    "An unexpected error occurred.": "एक अप्रत्याशित त्रुटि हुई।",
    "Please fix the errors in the form": "कृपया फॉर्म में त्रुटियों को ठीक करें",
    
    # Home/Dashboard
    "Welcome to Dharma CMS": "धर्म CMS में आपका स्वागत है",
    "Cases": "मामले",
    "Complaints": "शिकायतें",
    "Petitions": "याचिकाएं",
    "Settings": "सेटिंग्स",
    "Language": "भाषा",
    "Dashboard": "डैशबोर्ड",
    "Your Legal Assistance Hub": "आपका कानूनी सहायता केंद्र",
    "Police Command Centre": "पुलिस कमांड सेंटर",
    "Quick Actions": "त्वरित कार्रवाई",
    "Recent Activity": "हाल की गतिविधि",
    "No recent activity": "कोई हाल की गतिविधि नहीं",
    "Total Cases": "कुल मामले",
    "Active Cases": "सक्रिय मामले",
    "Closed Cases": "बंद मामले",
    "Total Petitions": "कुल याचिकाएं",
    
    # AI Chat - CRITICAL STRINGS
    "AI Chatbot Details": "AI चैटबॉट विवरण",
    "Citizen Details": "नागरिक विवरण",
    "Complaint Type": "शिकायत का प्रकार",
    "Details": "विवरण",
    "Formal Complaint Summary": "औपचारिक शिकायत सारांश",
    "Offence Classification": "अपराध वर्गीकरण",
    "This case is classified as": "यह मामला इस रूप में वर्गीकृत है",
    "COGNIZABLE": "संज्ञेय",
    "NON-COGNIZABLE": "गैर-संज्ञेय",
    "Please Contact To the Officer...": "कृपया अधिकारी से संपर्क करें...",
    "File a Case": "मामला दर्ज करें",
    "Go to Dashboard": "डैशबोर्ड पर जाएं",
    
    # AI Tools
    "AI Chat": "AI चैट",
    "Legal Queries": "कानूनी प्रश्न",
    "View Cases": "मामले देखें",
    "Legal Section Suggestions": "कानूनी धारा सुझाव",
    "Document Drafting": "दस्तावेज़ मसौदा",
    "Chargesheet Gen": "आरोपपत्र निर्माण",
    "Chargesheet Vetting": "आरोपपत्र जांच",
    "Witness Prep": "गवाह तैयारी",
    "Media Analysis": "मीडिया विश्लेषण",
    "Case Journal": "मामला जर्नल",
    "Case Management": "मामला प्रबंधन",
    "AI Tools": "AI उपकरण",
    
    # Actions
    "New Case": "नया मामला",
    "All Cases": "सभी मामले",
    "No cases found": "कोई मामला नहीं मिला",
    "Raise Complaint": "शिकायत दर्ज करें",
    "My Saved Complaints": "मेरी सहेजी गई शिकायतें",
    "No saved complaints": "कोई सहेजी गई शिकायत नहीं",
    "AI Legal Assistant": "AI कानूनी सहायक",
    "Type a message...": "एक संदेश टाइप करें...",
    "Ask legal questions and get AI-powered answers": "कानूनी प्रश्न पूछें और AI-संचालित उत्तर प्राप्त करें",
    "Submit Query": "प्रश्न सबमिट करें",
    "Enter your legal question here...": "अपना कानूनी प्रश्न यहां दर्ज करें...",
    "Previous Queries": "पिछले प्रश्न",
    "No queries yet": "अभी तक कोई प्रश्न नहीं",
    "Submit your first legal query above": "ऊपर अपना पहला कानूनी प्रश्न सबमिट करें",
    
    # Common actions
    "Save": "सहेजें",
    "Cancel": "रद्द करें",
    "Delete": "हटाएं",
    "Edit": "संपादित करें",
    "Close": "बंद करें",
    "Submit": "सबमिट करें",
    "Search": "खोजें",
    "Filter": "फ़िल्टर",
    "Notifications": "सूचनाएं",
    "Dark Mode": "डार्क मोड",
    "About": "के बारे में",
    "Privacy Policy": "गोपनीयता नीति",
    "Terms of Service": "सेवा की शर्तें",
    "Profile Information": "प्रोफ़ाइल जानकारी",
    "Are you sure you want to sign out?": "क्या आप वाकई साइन आउट करना चाहते हैं?",
    
    # AI Legal Chat - THE MOST CRITICAL STRINGS
    "Want to utilise this feature?": "क्या आप इस सुविधा का उपयोग करना चाहते हैं?",
    "Utilise": "उपयोग करें",
    "Skip": "छोड़ें",
    "What is your full name?": "आपका पूरा नाम क्या है?",
    "Where do you live (place / area)?": "आप कहां रहते हैं (स्थान / क्षेत्र)?",
    "What is your phone number?": "आपका फोन नंबर क्या है?",
    "What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)": "आप किस प्रकार की शिकायत दर्ज करना चाहते हैं? (चोरी, उत्पीड़न, लापता व्यक्ति, आदि)",
    "Please describe your complaint in detail.": "कृपया अपनी शिकायत का विस्तार से वर्णन करें।",
    "Loading...": "लोड हो रहा है...",
    "Please enter your answer": "कृपया अपना उत्तर दर्ज करें",
    "Voice input (coming soon)": "वॉइस इनपुट (जल्द आ रहा है)",
    
    # THE THREE CRITICAL STRINGS FROM THE SCREENSHOT
    "Welcome to Dharma": "धर्म में आपका स्वागत है",
    "Let us begin...": "आइए शुरू करें...",
    
    "Complaint Summary:": "शिकायत सारांश:",
    "Sorry, something went wrong. Please try again later.": "क्षमा करें, कुछ गलत हो गया। कृपया बाद में पुनः प्रयास करें।",
}

# Apply all translations
for english, hindi in translations.items():
    # Use word boundary matching to avoid partial replacements
    content = content.replace(f"=> '{english}'", f"=> '{hindi}'")
    content = content.replace(f'=> "{english}"', f'=> "{hindi}"')
    content = content.replace(f"'{english}'", f"'{hindi}'")

# Write the Hindi file
with open('lib/l10n/app_localizations_hi.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Created Hindi localization file with {len(translations)} translations")
print("File: lib/l10n/app_localizations_hi.dart")
