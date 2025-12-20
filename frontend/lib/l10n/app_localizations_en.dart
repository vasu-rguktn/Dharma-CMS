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

  @override
  String get answered => 'Answered';

  @override
  String get querySubmittedSuccessfully => 'Query submitted successfully!';

  @override
  String get submitAQuery => 'Submit a Query';

  @override
  String get queryDetails => 'Query Details';

  @override
  String get enterFirAndIncidentDetails => 'Please enter both FIR and incident details.';

  @override
  String get legalSuggestionsGenerated => 'Legal suggestions generated.';

  @override
  String failedToGenerateSuggestions(String error) {
    return 'Failed to generate legal suggestions: $error';
  }

  @override
  String get provideFirDetailsDesc => 'Provide FIR and incident details to get AI-powered suggestions for applicable legal sections under BNS, BNSS, BSA, and other special acts.';

  @override
  String get enterFirDetailsHint => 'Enter comprehensive details from the First Information Report...';

  @override
  String get describeIncidentHint => 'Describe the incident in detail, including sequence of events, actions taken, etc...';

  @override
  String get processing => 'Processing...';

  @override
  String get getLegalSuggestions => 'Get Legal Suggestions';

  @override
  String get analyzingInformation => 'Analyzing information and generating suggestions...';

  @override
  String get aiLegalSuggestions => 'AI Legal Suggestions';

  @override
  String get reviewSuggestionsDesc => 'Review the suggested legal sections and reasoning. This is for informational purposes only.';

  @override
  String get suggestedSections => 'Suggested Sections';

  @override
  String get noSectionsSuggested => 'No sections suggested';

  @override
  String get reasoning => 'Reasoning';

  @override
  String get noReasoningProvided => 'No reasoning provided';

  @override
  String get aiDisclaimer => 'AI-generated content. Always consult with a legal expert for official advice.';

  @override
  String get provideCaseDataAndRecipient => 'Please provide case data and select a recipient type.';

  @override
  String get documentDraftGenerated => 'Document draft generated.';

  @override
  String failedToGenerateDraft(String error) {
    return 'Failed to generate document draft: $error';
  }

  @override
  String get documentDraftingDesc => 'Generate document drafts based on case data for specific recipients like medical officers or forensic experts.';

  @override
  String get pasteCaseDataHint => 'Paste all relevant case data: complaint transcripts, witness statements, FIR details, investigation notes, etc...';

  @override
  String get selectRecipientType => 'Select recipient type';

  @override
  String get additionalInstructionsOptional => 'Additional Instructions (Optional)';

  @override
  String get additionalInstructionsHint => 'E.g., \'Focus on injuries sustained\', \'Request specific tests for DNA analysis\', \'Keep the tone formal and urgent\'...';

  @override
  String get drafting => 'Drafting...';

  @override
  String get draftDocument => 'Draft Document';

  @override
  String get draftingWait => 'Drafting document, please wait...';

  @override
  String get generatedDocumentDraft => 'Generated Document Draft';

  @override
  String get reviewDraftDesc => 'Review the generated draft. You can copy and edit it as needed.';

  @override
  String get noDraftGenerated => 'No draft generated';

  @override
  String get aiDraftDisclaimer => 'AI-generated content. Verify and adapt for official use.';

  @override
  String get draftCopied => 'Draft copied to clipboard';

  @override
  String get copyDraft => 'Copy Draft';

  @override
  String filesAdded(int count) {
    return '$count file(s) added';
  }

  @override
  String errorPickingFiles(String error) {
    return 'Error picking files: $error';
  }

  @override
  String get pleaseUploadDocument => 'Please upload at least one document.';

  @override
  String get draftChargeSheetGenerated => 'Draft charge sheet generated.';

  @override
  String failedToGenerateChargeSheet(String error) {
    return 'Failed to generate charge sheet: $error';
  }

  @override
  String get chargesheetGeneratorDesc => 'Upload relevant documents (FIR, witness statements, evidence reports in .doc, .docx, .pdf, .txt) and provide additional instructions. The AI will formulate a draft charge sheet based on the provided template.';

  @override
  String get caseDocuments => 'Case Documents';

  @override
  String get chooseFiles => 'Choose Files';

  @override
  String get uploadedFiles => 'Uploaded Files:';

  @override
  String get chargesheetInstructionsHint => 'E.g., \'Focus on connecting Accused A to the weapon found.\', \'Emphasize the premeditation aspect based on Witness B\'s statement.\'...';

  @override
  String get generating => 'Generating...';

  @override
  String get generateDraftChargeSheet => 'Generate Draft Charge Sheet';

  @override
  String get generatingChargeSheetWait => 'Generating charge sheet, this may take a moment...';

  @override
  String get generatedDraftChargeSheet => 'Generated Draft Charge Sheet';

  @override
  String get reviewChargeSheetDesc => 'Review the generated draft. This is a starting point and requires legal review and verification against original documents.';

  @override
  String get noChargeSheetGenerated => 'No charge sheet generated';

  @override
  String get aiChargeSheetDisclaimer => 'AI-generated content. Must be reviewed and verified by a legal professional.';

  @override
  String fileContentLoaded(String fileName) {
    return '$fileName content loaded.';
  }

  @override
  String errorReadingFile(String error) {
    return 'Error reading file: $error';
  }

  @override
  String get pleaseUploadOrPasteChargesheet => 'Please upload or paste the charge sheet content.';

  @override
  String get chargesheetVettedSuccess => 'Charge sheet vetted and suggestions provided.';

  @override
  String failedToVetChargesheet(String error) {
    return 'Failed to vet charge sheet: $error';
  }

  @override
  String get chargesheetVettingAI => 'Charge Sheet Vetting AI';

  @override
  String get chargesheetVettingDesc => 'Upload or paste an existing charge sheet. The AI will review it and suggest improvements to strengthen the case.';

  @override
  String get uploadChargesheet => 'Upload Charge Sheet (.txt file)';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get fileLoadedEditBelow => 'File loaded. You can also edit below.';

  @override
  String get orPasteChargesheet => 'Or Paste Charge Sheet Content';

  @override
  String get pasteChargesheetHint => 'Paste the full content of the charge sheet here...';

  @override
  String get vetting => 'Vetting...';

  @override
  String get vetChargeSheet => 'Vet Charge Sheet';

  @override
  String get vettingChargesheetWait => 'Vetting charge sheet, please wait...';

  @override
  String get aiVettingSuggestions => 'AI Vetting Suggestions';

  @override
  String get reviewSuggestionsToImprove => 'Review the suggestions to improve the charge sheet.';

  @override
  String get noSuggestionsProvided => 'No suggestions provided';

  @override
  String get aiVettingDisclaimer => 'AI-generated suggestions. Legal expertise is required for final decisions.';

  @override
  String get pleaseFillAllWitnessFields => 'Please fill in all fields: case details, witness statement, and witness name.';

  @override
  String get witnessPreparationComplete => 'Witness preparation session complete.';

  @override
  String failedToPrepareWitness(String error) {
    return 'Failed to conduct witness preparation session: $error';
  }

  @override
  String get aiWitnessPreparation => 'AI Witness Preparation';

  @override
  String get witnessPreparationDesc => 'Simulate a mock trial experience for a witness. The AI assistant will ask potential cross-examination questions.';

  @override
  String get enterWitnessNameHint => 'Enter the witness\'s full name';

  @override
  String get caseDetailsHint => 'Provide comprehensive case details: charges, evidence, known facts, etc.';

  @override
  String get witnessStatementHint => 'Enter the witness\'s statement that will be used for the mock trial.';

  @override
  String get preparing => 'Preparing...';

  @override
  String get startMockTrial => 'Start Mock Trial';

  @override
  String get preparingMockTrialWait => 'Preparing mock trial session...';

  @override
  String get mockTrialAndFeedback => 'Mock Trial & Feedback';

  @override
  String reviewMockTrialFor(String witnessName) {
    return 'Review the mock trial transcript and AI feedback for witness $witnessName.';
  }

  @override
  String get mockTrialTranscript => 'Mock Trial Transcript';

  @override
  String get noTranscriptAvailable => 'No transcript available';

  @override
  String get potentialWeaknesses => 'Potential Weaknesses';

  @override
  String get noWeaknessesIdentified => 'No weaknesses identified';

  @override
  String get suggestedImprovements => 'Suggested Improvements';

  @override
  String get noImprovementsSuggested => 'No improvements suggested';

  @override
  String get aiSimulationDisclaimer => 'This is an AI simulation. Real trial conditions may vary.';

  @override
  String get imageSizeLimit => 'Please select an image smaller than 10MB.';

  @override
  String errorPickingImage(String error) {
    return 'Error picking image: $error';
  }

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get pleaseSelectImageToAnalyze => 'Please select an image to analyze.';

  @override
  String get analysisComplete => 'Analysis complete. Review the AI-generated findings below.';

  @override
  String failedToAnalyzeMedia(String error) {
    return 'Failed to analyze media: $error';
  }

  @override
  String get aiCrimeSceneInvestigator => 'AI Crime Scene Investigator';

  @override
  String get mediaAnalysisDesc => 'Upload an image (max 10MB) for crime scene analysis. The AI will identify elements, describe the scene, and provide a summary.';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get chooseImage => 'Choose Image';

  @override
  String get contextInstructions => 'Context / Specific Instructions (Optional)';

  @override
  String get contextInstructionsHint => 'E.g., \'Focus on potential weapons.\', \'Is there any sign of forced entry?\', \'What is written on the note on the table?\'';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get analyzeImage => 'Analyze Image';

  @override
  String get analyzingImageWait => 'AI is analyzing the image, please wait...';

  @override
  String get analyzingComplexityNote => '(This may take a moment depending on image complexity)';

  @override
  String get crimeSceneAnalysisReport => 'Crime Scene Analysis Report';

  @override
  String get date => 'Date';

  @override
  String get file => 'File';

  @override
  String get identifiedElements => 'Identified Elements';

  @override
  String get count => 'Count';

  @override
  String get category => 'Category';

  @override
  String get noElementsIdentified => 'No specific elements prominently identified or analysis incomplete.';

  @override
  String get sceneNarrativeEditable => 'Scene Narrative (Editable)';

  @override
  String get sceneNarrativeHint => 'AI-generated scene narrative will appear here. You can edit it.';

  @override
  String get caseFileSummaryEditable => 'Case File Summary & Hypotheses (Editable)';

  @override
  String get caseFileSummaryHint => 'AI-generated summary and hypotheses will appear here. You can edit it.';

  @override
  String get aiAnalysisDisclaimer => 'AI-generated analysis. Verify with physical investigation.';

  @override
  String get download => 'Download';

  @override
  String get downloadFeatureComingSoon => 'Download feature coming soon';

  @override
  String errorLoadingJournal(String error) {
    return 'Error loading journal: $error';
  }

  @override
  String get addJournalEntry => 'Add Journal Entry';

  @override
  String get activityType => 'Activity Type';

  @override
  String get firRegistered => 'FIR Registered';

  @override
  String get evidenceCollected => 'Evidence Collected';

  @override
  String get witnessExamined => 'Witness Examined';

  @override
  String get arrestMade => 'Arrest Made';

  @override
  String get medicalReportObtained => 'Medical Report Obtained';

  @override
  String get sceneVisited => 'Scene Visited';

  @override
  String get documentSubmitted => 'Document Submitted';

  @override
  String get hearingAttended => 'Hearing Attended';

  @override
  String get entryDetails => 'Entry Details';

  @override
  String get entryDetailsHint => 'Describe the activity in detail...';

  @override
  String get pleaseEnterEntryDetails => 'Please enter entry details';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get journalEntryAddedSuccess => 'Journal entry added successfully';

  @override
  String errorAddingEntry(String error) {
    return 'Error adding entry: $error';
  }

  @override
  String get caseJournalDesc => 'View investigation diaries and case activity logs';

  @override
  String get selectCase => 'Select Case';

  @override
  String get noCasesAvailable => 'No cases available. Please register a case first.';

  @override
  String get chooseCaseToViewJournal => 'Choose a case to view journal';

  @override
  String get investigationDiary => 'Investigation Diary';

  @override
  String get addJournalEntryTooltip => 'Add journal entry';

  @override
  String get openCaseDetails => 'Open case details';

  @override
  String get noJournalEntries => 'No journal entries yet';

  @override
  String get noJournalEntriesDesc => 'Journal entries will appear here as the investigation progresses.';

  @override
  String get ref => 'Ref';

  @override
  String get caseCreatedSuccess => 'Case created successfully!';

  @override
  String errorCreatingCase(String error) {
    return 'Error creating case: $error';
  }

  @override
  String get caseTitleRequired => 'Case Title *';

  @override
  String get caseTitleHint => 'Enter a brief title for the case';

  @override
  String get pleaseEnterCaseTitle => 'Please enter a case title';

  @override
  String get firNumberRequired => 'FIR Number *';

  @override
  String get firNumberHint => 'Enter FIR number';

  @override
  String get pleaseEnterFirNumber => 'Please enter FIR number';

  @override
  String get locationDetails => 'Location Details';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get complainantName => 'Complainant Name';

  @override
  String get enterComplainantName => 'Enter complainant name';

  @override
  String get describeIncident => 'Describe the incident';

  @override
  String get createCase => 'Create Case';

  @override
  String get user => 'User';

  @override
  String get english => 'English';

  @override
  String get telugu => 'Telugu';

  @override
  String get appName => 'Dharma';

  @override
  String get appVersion => '1.0.0';

  @override
  String get appDescription => 'Legal assistance platform powered by AI technology.';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';



@override
String get loginWithPhone => 'Login with Phone';

@override
String get mobileNumber => 'Mobile Number';

@override
String get sendOtp => 'Send OTP';

@override
String get verifyOtp => 'Verify OTP';

@override
String get otpSent => 'OTP sent!';

@override
String get otpResent => 'OTP resent!';

@override
String get enterValidNumber => 'Enter valid 10-digit number';

@override
String get enterOtp => 'Enter 6-digit OTP';

@override
String resendIn(int seconds) => 'Resend in $seconds sec';

@override
String get resendOtp => 'Resend OTP';

@override
String get loginSuccessful => 'Login Successful!';

@override
String get wrongOtp => 'Wrong OTP';

@override
String get otpExpired => 'OTP expired';

@override
String get invalidOtp => 'Invalid OTP';

@override
String get backToEmailLogin => 'Back to Email Login';


@override
String get emergencyHelplines => 'Emergency Helplines';

@override
String get sos112 => 'SOS 112';

@override
String get helplineEmergencyAll => 'Emergency (All-in-One)';

@override
String get helplineEmergencyAllDesc => 'Police, Fire, Ambulance';

@override
String get helplinePolice => 'Police Control Room';

@override
String get helplinePoliceDesc => 'Crime / Emergencies';

@override
String get helplineFire => 'Fire & Rescue';

@override
String get helplineFireDesc => 'Fire accidents & rescue';

@override
String get helplineAmbulance => 'Ambulance';

@override
String get helplineAmbulanceDesc => 'Medical emergencies';

@override
String get helplineAmbulanceAlt => 'Ambulance (Alternative)';

@override
String get helplineAmbulanceAltDesc => 'Emergency medical service';

@override
String get helplineWomen => 'Women Helpline';

@override
String get helplineWomenDesc => 'Support for women safety';

@override
String get helplineDomestic => 'Domestic Violence';

@override
String get helplineDomesticDesc => 'Help against abuse';

@override
String get helplineChild => 'Child Helpline';

@override
String get helplineChildDesc => 'Children in trouble';

@override
String get helplineCyber => 'Cyber Crime';

@override
String get helplineCyberDesc => 'Fraud, cyber threats';

@override
String get support => 'Support';

@override
String get closed => 'Closed'; 

@override
String get inProgress => 'In Progress';

@override
String get yourLegalAssistanceHub => 'Your Legal Assistance Hub';


@override
String get received => 'Received';

@override
String get welcome => 'Welcome';

@override
String get policeCommandCenter => 'Police Command Centre';



@override
String get petitionOverview => 'Petition Overview';


@override

  @override
  String get recentActivityDescription => 'Shows the most recent actions or updates related to your account'; 

  @override
  String get helpline => 'Helpline';

@override
String get userNotRegistered => 'User not registered';

@override
String get registeredAs => 'You are registered as a';

@override
String get tryingToLoginAs => 'but trying to login as a';

@override
String get selectCorrectOption => 'Please select the correct option';

@override
String get loginFailed => 'Login Failed';

@override
String get googleLoginSuccessful => 'Google Login Successful';

// Police Login & Registration
@override
String get policeLogin => 'Police Login';

@override
String get policeRegistration => 'Police Registration';

@override
String get policeLoginSuccessful => 'Police login successful';

@override
String get policeRegisteredSuccessfully => 'Police registered successfully';

@override
String get dontHavePoliceAccount => "Don't have a police account? ";

@override
String get invalidName => 'Invalid name';

@override
String get invalidEmailShort => 'Invalid email';

@override
String get passwordMinRequirement => 'Min 8 chars, 1 number';

@override
String get rank => 'Rank';

@override
String get selectRank => 'Select Rank';

@override
String get selectDistrict => 'Select District';

@override
String get selectPoliceStationText => 'Select Police Station';

@override
String get pleaseSelectAllDropdownFields => 'Please select all dropdown fields';

@override
String get searchHint => 'Search...';

@override
String selectLabel(String label) {
  return 'Select $label';
}

@override
String get aiInvestigationGuidelines => 'AI Investigation Guidelines';

@override
String get enterFirNumber => 'Enter FIR Number (Case ID)';

@override
String get startInvestigation => 'Start Investigation';

@override
String get enterOfficerResponse => 'Enter officer response...';

@override
String get errorContactingInvestigationAI => 'Error contacting investigation AI';

@override
String get districtAndFirDetails => 'District and FIR Details';

@override
String get occurenceOfOffence => 'Occurence of Offence';

@override
String get dayOfOccurrence => 'Day of Occurrence';

@override
String get dateTimeFrom => 'Date/Time From';

@override
String get dateTimeTo => 'Date/Time To';

@override
String get selectDateAndTime => 'Select date and time';

@override
String get timePeriod => 'Time Period';

@override
String get priorToDateTimeDetails => 'Prior to Date/Time (Details)';

@override
String get beatNumber => 'Beat Number';

@override
String get placeOfOccurrence => 'Place of Occurrence';

@override
String get streetVillage => 'Street/Village';

@override
String get areaMandal => 'Area/Mandal';

@override
String get cityDistrict => 'City/District';

@override
String get pin => 'PIN';

@override
String get latitude => 'Latitude';

@override
String get longitude => 'Longitude';

@override
String get map => 'Map';

@override
String get viewMap => 'View Map'; 

@override
String get listening => 'Listening...';

@override
String get tapToStopRecording => 'Tap the microphone icon to stop recording';
}
