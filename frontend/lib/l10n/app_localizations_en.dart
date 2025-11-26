// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dharma CMS';


  String get dharma => 'Dharma';

  @override
  String get dharmaPortal => 'Dharma Portal';

  @override
  String get welcomeDescription => 'Digital hub for Andhra Pradesh police records, management and analytics';

  @override
  String get loginAs => 'Login as';

  @override
  String get registerAs => 'Register as';

  @override
  String get citizen => 'Citizen';

  @override
  String get police => 'Police';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get register => 'Register';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get dateOfBirth => 'Date of Birth (YYYY-MM-DD)';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get nameOnlyLetters => 'Name can only contain letters and spaces';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPhone => 'Please enter your phone number';

  @override
  String get pleaseEnterValidPhone => 'Please enter a valid phone number';

  @override
  String get pleaseSelectDOB => 'Please select your date of birth';

  @override
  String get enterValidDateFormat => 'Enter date in YYYY-MM-DD format';

  @override
  String get pleaseSelectGender => 'Please select your gender';

  @override
  String get fillFieldsCorrectly => 'Please fill all fields correctly';

  @override
  String get addressDetails => 'Address Details';

  @override
  String get houseNo => 'House No';

  @override
  String get cityTown => 'City/Town';

  @override
  String get district => 'District';

  @override
  String get state => 'State';

  @override
  String get country => 'Country';

  @override
  String get pincode => 'Pincode';

  @override
  String get policeStation => 'Police Station';

  @override
  String get enterHouseNumber => 'Please enter your house number';

  @override
  String get enterCity => 'Enter your city';

  @override
  String get enterDistrict => 'Enter your district';

  @override
  String get enterState => 'Enter your state';

  @override
  String get enterCountry => 'Enter your country';

  @override
  String get enterPincode => 'Please enter your pincode';

  @override
  String get enterValidPincode => 'Enter a valid 6-digit pincode';

  @override
  String get enterPoliceStation => 'Enter police station';

  @override
  String get personalDataNotProvided => 'Error: Personal data not provided';

  @override
  String get loginDetails => 'Login Details';

  @override
  String get username => 'Username *';

  @override
  String get enterUsername => 'Enter username (min 4 characters)';

  @override
  String get usernameEmpty => 'Enter username';

  @override
  String get usernameMinLength => 'Username must be at least 4 characters';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter password (min 6 characters)';

  @override
  String get passwordEmpty => 'Enter password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reenterPassword => 'Re-enter password';

  @override
  String get confirmPasswordEmpty => 'Confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get dataNotProvided => 'Error: Required data not provided';

  @override
  String get invalidEmail => 'Error: Invalid email provided';

  @override
  String get failedToCreateUser => 'Error: Failed to create user';

  @override
  String get registrationSuccessful => 'Registration successful!';

  @override
  String get emailAlreadyRegistered => 'The email is already registered.';

  @override
  String get invalidEmailAddress => 'The email address is invalid.';

  @override
  String get weakPassword => 'The password is too weak.';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get fixFormErrors => 'Please fix the errors in the form';

  @override
  String get welcomeMessage => 'Welcome to Dharma CMS';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get cases => 'Cases';

  @override
  String get complaints => 'Complaints';

  @override
  String get petitions => 'Petitions';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get aiChatbotDetails => 'AI Chatbot Details';

  @override
  String get citizenDetails => 'Citizen Details';

  @override
  String get address => 'Address';

  @override
  String get complaintType => 'Complaint Type';

  @override
  String get details => 'Details';

  @override
  String get formalComplaintSummary => 'Formal Complaint Summary';

  @override
  String get offenceClassification => 'Offence Classification';

  @override
  String get thisCaseIsClassifiedAs => 'This case is classified as';

  @override
  String get cognizable => 'COGNIZABLE';

  @override
  String get nonCognizable => 'NON-COGNIZABLE';

  @override
  String get pleaseContactOfficer => 'Please Contact To the Officer...';

  @override
  String get fileACase => 'File a Case';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get legalAssistanceHub => 'Your Legal Assistance Hub';

  @override
  String get policeCommandCentre => 'Police Command Centre';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get totalCases => 'Total Cases';

  @override
  String get activeCases => 'Active Cases';

  @override
  String get closedCases => 'Closed Cases';

  @override
  String get totalPetitions => 'Total Petitions';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get legalQueries => 'Legal Queries';

  @override
  String get viewCases => 'View Cases';

  @override
  String get legalSuggestion => 'Legal Suggestion';

  @override
  String get documentDrafting => 'Document Drafting';

  @override
  String get chargesheetGen => 'Chargesheet Gen';

  @override
  String get chargesheetVetting => 'Chargesheet Vetting';

  @override
  String get witnessPrep => 'Witness Prep';

  @override
  String get mediaAnalysis => 'Media Analysis';

  @override
  String get caseJournal => 'Case Journal';

  @override
  String get caseManagement => 'Case Management';

  @override
  String get aiTools => 'AI Tools';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get newCase => 'New Case';

  @override
  String get allCases => 'All Cases';

  @override
  String get noCasesFound => 'No cases found';

  @override
  String get raiseComplaint => 'Raise Complaint';

  @override
  String get mySavedComplaints => 'My Saved Complaints';

  @override
  String get noSavedComplaints => 'No saved complaints';

  @override
  String get aiLegalAssistant => 'AI Legal Assistant';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get askLegalQuestions => 'Ask legal questions and get AI-powered answers';

  @override
  String get submitQuery => 'Submit Query';

  @override
  String get enterLegalQuestion => 'Enter your legal question here...';

  @override
  String get previousQueries => 'Previous Queries';

  @override
  String get noQueriesYet => 'No queries yet';

  @override
  String get submitFirstQuery => 'Submit your first legal query above';

  @override
  String get legalSectionSuggester => 'Legal Section Suggester';

  @override
  String get firDetails => 'FIR Details';

  @override
  String get incidentDetails => 'Incident Details';

  @override
  String get generateSuggestions => 'Generate Suggestions';

  @override
  String get aiDocumentDrafter => 'AI Document Drafter';

  @override
  String get caseData => 'Case Data';

  @override
  String get recipientType => 'Recipient Type';

  @override
  String get medicalOfficer => 'Medical Officer';

  @override
  String get forensicExpert => 'Forensic Expert';

  @override
  String get generateDraft => 'Generate Draft';

  @override
  String get chargesheetGenerator => 'Chargesheet Generator';

  @override
  String get evidenceSummary => 'Evidence Summary';

  @override
  String get generateChargesheet => 'Generate Chargesheet';

  @override
  String get chargesheetContent => 'Chargesheet Content';

  @override
  String get vetChargesheet => 'Vet Chargesheet';

  @override
  String get witnessPreparation => 'Witness Preparation';

  @override
  String get witnessName => 'Witness Name';

  @override
  String get witnessStatement => 'Witness Statement';

  @override
  String get prepareQuestions => 'Prepare Questions';

  @override
  String get uploadMedia => 'Upload Media';

  @override
  String get analyzeMedia => 'Analyze Media';

  @override
  String get caseDetails => 'Case Details';

  @override
  String get status => 'Status';

  @override
  String get description => 'Description';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get submit => 'Submit';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get notifications => 'Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get about => 'About';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get areYouSureSignOut => 'Are you sure you want to sign out?';
  
  @override
  String get wantToUtiliseFeature => 'Want to utilise this feature?';
  
  @override
  String get utilise => 'Utilise';
  
  @override
  String get skip => 'Skip';
  
  @override
  String get fullNameQuestion => 'What is your full name?';
  
  @override
  String get addressQuestion => 'Where do you live (place / area)?';
  
  @override
  String get phoneQuestion => 'What is your phone number?';
  
  @override
  String get complaintTypeQuestion => 'What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)';
  
  @override
  String get detailsQuestion => 'Please describe your complaint in detail.';
  
  @override
  String get loading => 'Loading...';
  
  @override
  String get pleaseEnterYourAnswer => 'Please enter your answer';
  
  @override
  String get voiceInputComingSoon => 'Voice input (coming soon)';
  
  @override
  String get welcomeToDharma => 'Welcome to Dharma';
  
  @override
  String get letUsBegin => 'Let us begin...';
  
  @override
  String pleaseAnswerAllQuestions(String missing) => 'Please answer all questions before submitting. Missing: $missing';
  
  @override
  String get complaintSummary => 'Complaint Summary:';
  
  @override
  String classification(String classification) => 'Classification: $classification';
  
  @override
  String get somethingWentWrong => 'Sorry, something went wrong. Please try again later.';
  
  @override
  String unexpectedErrorMessage(String error) => 'Unexpected error: $error';

  @override
  String get viewAndManageComplaints => 'View and manage your saved complaint drafts';

  @override
  String get savedComplaintsAppearHere => 'Your saved complaint drafts will appear here';

  @override
  String get untitledComplaint => 'Untitled Complaint';

  @override
  String get draft => 'Draft';

  @override
  String get deleteComplaint => 'Delete Complaint';

  @override
  String get deleteComplaintConfirmation => 'Are you sure you want to delete this complaint?';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get petitionTypeLabel => 'Petition Type(Theft/Robery, etc) *';

  @override
  String get required => 'Required';

  @override
  String get yourNameLabel => 'Your Name *';

  @override
  String get phoneNumberLabel => 'Phone Number *';

  @override
  String get enterTenDigitNumber => 'Enter 10-digit number';

  @override
  String get addressLabel => 'Address *';

  @override
  String get petitionDetails => 'Petition Details';

  @override
  String get groundsReasonsLabel => 'Grounds / Reasons *';

  @override
  String get handwrittenDocuments => 'HandWritten Documents';

  @override
  String get uploadDocuments => 'Upload Documents';

  @override
  String filesCount(int count) => '$count file(s)';

  @override
  String get extractedText => 'Extracted Text';

  @override
  String get createPetition => 'Create Petition';

  @override
  String get petitionCreatedSuccessfully => 'Petition created successfully!';

  @override
  String get failedToCreatePetition => 'Failed to create petition';

  @override
  String get noTextExtracted => 'No text extracted from document';

  @override
  String ocrFailed(String error) => 'OCR failed: $error';

  @override
  String get petitionManagement => 'Petition Management';

  @override
  String get myPetitions => 'My Petitions';

  @override
  String get createNew => 'Create New';

  @override
  String get noPetitionsYet => 'No Petitions Yet';

  @override
  String get createFirstPetition => 'Create your first petition using the "Create New" tab';

  @override
  String createdDate(String date) => 'Created: $date';

  @override
  String nextHearingDate(String date) => 'Next Hearing: $date';

  @override
  String get petitioner => 'Petitioner';

  @override
  String get firNumber => 'FIR Number';

  @override
  String get grounds => 'Grounds';

  @override
  String get prayerReliefSought => 'Prayer / Relief Sought';

  @override
  String get filingDate => 'Filing Date';

  @override
  String get nextHearing => 'Next Hearing';

  @override
  String get orderDate => 'Order Date';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get extractedTextFromDocuments => 'Extracted Text from Documents';

  @override
  String get noDocumentsUploaded => 'No Documents Uploaded...';

  @override
  String get createFirstCase => 'Create your first case to get started';

  @override
  String get createNewCase => 'Create New Case';

  @override
  String get fir => 'FIR';






}
