import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('te')
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Dharma CMS'**
  String get appTitle;

  /// Portal title
  ///
  /// In en, this message translates to:
  /// **'Dharma Portal'**
  String get dharmaPortal;

  /// Description text on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Digital hub for Andhra Pradesh police records, management and analytics'**
  String get welcomeDescription;

  /// Login as dialog
  ///
  /// In en, this message translates to:
  /// **'Login as'**
  String get loginAs;

  /// Register as dialog
  ///
  /// In en, this message translates to:
  /// **'Register as'**
  String get registerAs;

  /// Citizen role
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get citizen;

  /// Police role
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// Text shown before register link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Full name field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Date of birth field label
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (YYYY-MM-DD)'**
  String get dateOfBirth;

  /// Gender field label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// Female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// Other gender option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Name field validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// Name field format validation message
  ///
  /// In en, this message translates to:
  /// **'Name can only contain letters and spaces'**
  String get nameOnlyLetters;

  /// Email field required validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Email field format validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Phone field required validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// Phone field format validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhone;

  /// Date of birth required validation message
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get pleaseSelectDOB;

  /// Date format validation message
  ///
  /// In en, this message translates to:
  /// **'Enter date in YYYY-MM-DD format'**
  String get enterValidDateFormat;

  /// Gender field required validation message
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get pleaseSelectGender;

  /// Form validation error message
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields correctly'**
  String get fillFieldsCorrectly;

  /// Address form title
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetails;

  /// House number field label
  ///
  /// In en, this message translates to:
  /// **'House No'**
  String get houseNo;

  /// City/Town field label
  ///
  /// In en, this message translates to:
  /// **'City/Town'**
  String get cityTown;

  /// District field label
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// State field label
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// Country field label
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Pincode field label
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincode;

  /// Police station field label
  ///
  /// In en, this message translates to:
  /// **'Police Station'**
  String get policeStation;

  /// House number validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your house number'**
  String get enterHouseNumber;

  /// City validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your city'**
  String get enterCity;

  /// District validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your district'**
  String get enterDistrict;

  /// State validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your state'**
  String get enterState;

  /// Country validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your country'**
  String get enterCountry;

  /// Pincode required validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your pincode'**
  String get enterPincode;

  /// Pincode format validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit pincode'**
  String get enterValidPincode;

  /// Police station validation message
  ///
  /// In en, this message translates to:
  /// **'Enter police station'**
  String get enterPoliceStation;

  /// Error message when personal data is missing
  ///
  /// In en, this message translates to:
  /// **'Error: Personal data not provided'**
  String get personalDataNotProvided;

  /// Login details form title
  ///
  /// In en, this message translates to:
  /// **'Login Details'**
  String get loginDetails;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get username;

  /// Username field hint
  ///
  /// In en, this message translates to:
  /// **'Enter username (min 4 characters)'**
  String get enterUsername;

  /// Username empty validation message
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get usernameEmpty;

  /// Username minimum length validation message
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 4 characters'**
  String get usernameMinLength;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter password (min 6 characters)'**
  String get enterPassword;

  /// Password empty validation message
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordEmpty;

  /// Password minimum length validation message
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reenterPassword;

  /// Confirm password empty validation message
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordEmpty;

  /// Password match validation message
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Error when required data is missing
  ///
  /// In en, this message translates to:
  /// **'Error: Required data not provided'**
  String get dataNotProvided;

  /// Invalid email error message
  ///
  /// In en, this message translates to:
  /// **'Error: Invalid email provided'**
  String get invalidEmail;

  /// User creation error message
  ///
  /// In en, this message translates to:
  /// **'Error: Failed to create user'**
  String get failedToCreateUser;

  /// Registration success message
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// Email already in use error message
  ///
  /// In en, this message translates to:
  /// **'The email is already registered.'**
  String get emailAlreadyRegistered;

  /// Invalid email format error message
  ///
  /// In en, this message translates to:
  /// **'The email address is invalid.'**
  String get invalidEmailAddress;

  /// Weak password error message
  ///
  /// In en, this message translates to:
  /// **'The password is too weak.'**
  String get weakPassword;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// Form validation error message
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors in the form'**
  String get fixFormErrors;

  /// Welcome message on the home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dharma CMS'**
  String get welcomeMessage;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Cases section title
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get cases;

  /// Complaints section title
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// Petitions section title
  ///
  /// In en, this message translates to:
  /// **'Petitions'**
  String get petitions;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language selection option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Dashboard menu item
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// AI Chatbot Details screen title
  ///
  /// In en, this message translates to:
  /// **'AI Chatbot Details'**
  String get aiChatbotDetails;

  /// Citizen Details section title
  ///
  /// In en, this message translates to:
  /// **'Citizen Details'**
  String get citizenDetails;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Complaint Type label
  ///
  /// In en, this message translates to:
  /// **'Complaint Type'**
  String get complaintType;

  /// Details label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Formal Complaint Summary section title
  ///
  /// In en, this message translates to:
  /// **'Formal Complaint Summary'**
  String get formalComplaintSummary;

  /// Offence Classification section title
  ///
  /// In en, this message translates to:
  /// **'Offence Classification'**
  String get offenceClassification;

  /// Case classification message prefix
  ///
  /// In en, this message translates to:
  /// **'This case is classified as'**
  String get thisCaseIsClassifiedAs;

  /// Cognizable classification
  ///
  /// In en, this message translates to:
  /// **'COGNIZABLE'**
  String get cognizable;

  /// Non-Cognizable classification
  ///
  /// In en, this message translates to:
  /// **'NON-COGNIZABLE'**
  String get nonCognizable;

  /// Message to contact officer
  ///
  /// In en, this message translates to:
  /// **'Please Contact To the Officer...'**
  String get pleaseContactOfficer;

  /// File a case button text
  ///
  /// In en, this message translates to:
  /// **'File a Case'**
  String get fileACase;

  /// Go to dashboard button text
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeUser(String name);

  /// Subtitle for citizen dashboard
  ///
  /// In en, this message translates to:
  /// **'Your Legal Assistance Hub'**
  String get legalAssistanceHub;

  /// Subtitle for police dashboard
  ///
  /// In en, this message translates to:
  /// **'Police Command Centre'**
  String get policeCommandCentre;

  /// Quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Recent activity section
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No recent activity message
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// Total cases stat
  ///
  /// In en, this message translates to:
  /// **'Total Cases'**
  String get totalCases;

  /// Active cases stat
  ///
  /// In en, this message translates to:
  /// **'Active Cases'**
  String get activeCases;

  /// Closed cases stat
  ///
  /// In en, this message translates to:
  /// **'Closed Cases'**
  String get closedCases;

  /// Total petitions stat
  ///
  /// In en, this message translates to:
  /// **'Total Petitions'**
  String get totalPetitions;

  /// AI Chat menu
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// Legal queries menu
  ///
  /// In en, this message translates to:
  /// **'Legal Queries'**
  String get legalQueries;

  /// View cases action
  ///
  /// In en, this message translates to:
  /// **'View Cases'**
  String get viewCases;

  /// Legal Section Suggestions menu
  ///
  /// In en, this message translates to:
  /// **'Legal Section Suggestions'**
  String get legalSuggestion;

  /// Document drafting menu
  ///
  /// In en, this message translates to:
  /// **'Document Drafting'**
  String get documentDrafting;

  /// Chargesheet generation menu
  ///
  /// In en, this message translates to:
  /// **'Chargesheet Gen'**
  String get chargesheetGen;

  /// Chargesheet vetting menu
  ///
  /// In en, this message translates to:
  /// **'Chargesheet Vetting'**
  String get chargesheetVetting;

  /// Witness preparation menu
  ///
  /// In en, this message translates to:
  /// **'Witness Prep'**
  String get witnessPrep;

  /// Media analysis menu
  ///
  /// In en, this message translates to:
  /// **'Media Analysis'**
  String get mediaAnalysis;

  /// Case journal menu
  ///
  /// In en, this message translates to:
  /// **'Case Journal'**
  String get caseJournal;

  /// Case management menu
  ///
  /// In en, this message translates to:
  /// **'Case Management'**
  String get caseManagement;

  /// AI tools section
  ///
  /// In en, this message translates to:
  /// **'AI Tools'**
  String get aiTools;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// New case button
  ///
  /// In en, this message translates to:
  /// **'New Case'**
  String get newCase;

  /// All cases title
  ///
  /// In en, this message translates to:
  /// **'All Cases'**
  String get allCases;

  /// No cases message
  ///
  /// In en, this message translates to:
  /// **'No cases found'**
  String get noCasesFound;

  /// Raise complaint button
  ///
  /// In en, this message translates to:
  /// **'Raise Complaint'**
  String get raiseComplaint;

  /// Saved complaints title
  ///
  /// In en, this message translates to:
  /// **'My Saved Complaints'**
  String get mySavedComplaints;

  /// No complaints message
  ///
  /// In en, this message translates to:
  /// **'No saved complaints'**
  String get noSavedComplaints;

  /// AI assistant title
  ///
  /// In en, this message translates to:
  /// **'AI Legal Assistant'**
  String get aiLegalAssistant;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Legal queries subtitle
  ///
  /// In en, this message translates to:
  /// **'Ask legal questions and get AI-powered answers'**
  String get askLegalQuestions;

  /// Submit query button
  ///
  /// In en, this message translates to:
  /// **'Submit Query'**
  String get submitQuery;

  /// Question input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your legal question here...'**
  String get enterLegalQuestion;

  /// Previous queries section
  ///
  /// In en, this message translates to:
  /// **'Previous Queries'**
  String get previousQueries;

  /// No queries message
  ///
  /// In en, this message translates to:
  /// **'No queries yet'**
  String get noQueriesYet;

  /// First query message
  ///
  /// In en, this message translates to:
  /// **'Submit your first legal query above'**
  String get submitFirstQuery;

  /// Legal suggester title
  ///
  /// In en, this message translates to:
  /// **'Legal Section Suggester'**
  String get legalSectionSuggester;

  /// FIR details label
  ///
  /// In en, this message translates to:
  /// **'FIR Details'**
  String get firDetails;

  /// Incident details label
  ///
  /// In en, this message translates to:
  /// **'Incident Details'**
  String get incidentDetails;

  /// Generate button
  ///
  /// In en, this message translates to:
  /// **'Generate Suggestions'**
  String get generateSuggestions;

  /// Document drafter title
  ///
  /// In en, this message translates to:
  /// **'AI Document Drafter'**
  String get aiDocumentDrafter;

  /// Case data label
  ///
  /// In en, this message translates to:
  /// **'Case Data'**
  String get caseData;

  /// Recipient type label
  ///
  /// In en, this message translates to:
  /// **'Recipient Type'**
  String get recipientType;

  /// Medical officer option
  ///
  /// In en, this message translates to:
  /// **'Medical Officer'**
  String get medicalOfficer;

  /// Forensic expert option
  ///
  /// In en, this message translates to:
  /// **'Forensic Expert'**
  String get forensicExpert;

  /// Generate draft button
  ///
  /// In en, this message translates to:
  /// **'Generate Draft'**
  String get generateDraft;

  /// Chargesheet generator title
  ///
  /// In en, this message translates to:
  /// **'Chargesheet Generator'**
  String get chargesheetGenerator;

  /// Evidence summary label
  ///
  /// In en, this message translates to:
  /// **'Evidence Summary'**
  String get evidenceSummary;

  /// Generate chargesheet button
  ///
  /// In en, this message translates to:
  /// **'Generate Chargesheet'**
  String get generateChargesheet;

  /// Chargesheet content label
  ///
  /// In en, this message translates to:
  /// **'Chargesheet Content'**
  String get chargesheetContent;

  /// Vet chargesheet button
  ///
  /// In en, this message translates to:
  /// **'Vet Chargesheet'**
  String get vetChargesheet;

  /// Witness prep title
  ///
  /// In en, this message translates to:
  /// **'Witness Preparation'**
  String get witnessPreparation;

  /// Witness name label
  ///
  /// In en, this message translates to:
  /// **'Witness Name'**
  String get witnessName;

  /// Witness statement label
  ///
  /// In en, this message translates to:
  /// **'Witness Statement'**
  String get witnessStatement;

  /// Prepare questions button
  ///
  /// In en, this message translates to:
  /// **'Prepare Questions'**
  String get prepareQuestions;

  /// Upload media button
  ///
  /// In en, this message translates to:
  /// **'Upload Media'**
  String get uploadMedia;

  /// Analyze media button
  ///
  /// In en, this message translates to:
  /// **'Analyze Media'**
  String get analyzeMedia;

  /// Case details title
  ///
  /// In en, this message translates to:
  /// **'Case Details'**
  String get caseDetails;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Search label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Filter label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Notifications title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Terms of service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Profile info title
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// Sign out confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;
  
  /// Text shown on AI legal guider screen asking user to utilise feature
  ///
  /// In en, this message translates to:
  /// **'Want to utilise this feature?'**
  String get wantToUtiliseFeature;
  
  /// Utilise button text
  ///
  /// In en, this message translates to:
  /// **'Utilise'**
  String get utilise;
  
  /// Skip button text
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;
  
  /// Question asking for user's full name
  ///
  /// In en, this message translates to:
  /// **'What is your full name?'**
  String get fullNameQuestion;
  
  /// Question asking for user's address
  ///
  /// In en, this message translates to:
  /// **'Where do you live (place / area)?'**
  String get addressQuestion;
  
  /// Question asking for user's phone number
  ///
  /// In en, this message translates to:
  /// **'What is your phone number?'**
  String get phoneQuestion;
  
  /// Question asking for complaint type
  ///
  /// In en, this message translates to:
  /// **'What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)'**
  String get complaintTypeQuestion;
  
  /// Question asking for complaint details
  ///
  /// In en, this message translates to:
  /// **'Please describe your complaint in detail.'**
  String get detailsQuestion;
  
  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;
  
  /// Error message when user doesn't enter an answer
  ///
  /// In en, this message translates to:
  /// **'Please enter your answer'**
  String get pleaseEnterYourAnswer;
  
  /// Tooltip for voice input button
  ///
  /// In en, this message translates to:
  /// **'Voice input (coming soon)'**
  String get voiceInputComingSoon;
  
  /// Welcome message in AI legal chat
  ///
  /// In en, this message translates to:
  /// **'Welcome to NyayaSetu'**
  String get welcomeToDharma;
  
  /// Message shown when starting the chat flow
  ///
  /// In en, this message translates to:
  /// **'Let us begin...'**
  String get letUsBegin;
  
  /// Error message when not all questions are answered
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions before submitting. Missing: {missing}'**
  String pleaseAnswerAllQuestions(String missing);
  
  /// Title for complaint summary section
  ///
  /// In en, this message translates to:
  /// **'Complaint Summary:'**
  String get complaintSummary;
  
  /// Classification label with value
  ///
  /// In en, this message translates to:
  /// **'Classification: {classification}'**
  String classification(String classification);
  
  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Sorry, something went wrong. Please try again later.'**
  String get somethingWentWrong;

  get dharma => null;
  
  /// Unexpected error message with error details
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedErrorMessage(String error);

  /// Subtitle for complaints screen
  ///
  /// In en, this message translates to:
  /// **'View and manage your saved complaint drafts'**
  String get viewAndManageComplaints;

  /// Empty state message for complaints
  ///
  /// In en, this message translates to:
  /// **'Your saved complaint drafts will appear here'**
  String get savedComplaintsAppearHere;

  /// Default title for untitled complaint
  ///
  /// In en, this message translates to:
  /// **'Untitled Complaint'**
  String get untitledComplaint;

  /// Draft status label
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// Delete complaint dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Complaint'**
  String get deleteComplaint;

  /// Delete complaint confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this complaint?'**
  String get deleteComplaintConfirmation;

  /// Basic Information title
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// Petition Type label
  ///
  /// In en, this message translates to:
  /// **'Petition Type(Theft/Robery, etc) *'**
  String get petitionTypeLabel;

  /// Required validation message
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Your Name label
  ///
  /// In en, this message translates to:
  /// **'Your Name *'**
  String get yourNameLabel;

  /// Phone Number label
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumberLabel;

  /// Enter 10-digit number validation message
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit number'**
  String get enterTenDigitNumber;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address *'**
  String get addressLabel;

  /// Petition Details title
  ///
  /// In en, this message translates to:
  /// **'Petition Details'**
  String get petitionDetails;

  /// Grounds / Reasons label
  ///
  /// In en, this message translates to:
  /// **'Grounds / Reasons *'**
  String get groundsReasonsLabel;

  /// Handwritten Documents title
  ///
  /// In en, this message translates to:
  /// **'HandWritten Documents'**
  String get handwrittenDocuments;

  /// Upload Documents button
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// Files count message
  ///
  /// In en, this message translates to:
  /// **'{count} file(s)'**
  String filesCount(int count);

  /// Extracted Text title
  ///
  /// In en, this message translates to:
  /// **'Extracted Text'**
  String get extractedText;

  /// Create Petition button
  ///
  /// In en, this message translates to:
  /// **'Create Petition'**
  String get createPetition;

  /// Petition created successfully message
  ///
  /// In en, this message translates to:
  /// **'Petition created successfully!'**
  String get petitionCreatedSuccessfully;

  /// Failed to create petition message
  ///
  /// In en, this message translates to:
  /// **'Failed to create petition'**
  String get failedToCreatePetition;

  /// No text extracted message
  ///
  /// In en, this message translates to:
  /// **'No text extracted from document'**
  String get noTextExtracted;

  /// OCR failed message
  ///
  /// In en, this message translates to:
  /// **'OCR failed: {error}'**
  String ocrFailed(String error);

  /// Petition Management title
  ///
  /// In en, this message translates to:
  /// **'Petition Management'**
  String get petitionManagement;

  /// My Petitions tab title
  ///
  /// In en, this message translates to:
  /// **'My Petitions'**
  String get myPetitions;

  /// Create New tab title
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No petitions yet message
  ///
  /// In en, this message translates to:
  /// **'No Petitions Yet'**
  String get noPetitionsYet;

  /// Create first petition message
  ///
  /// In en, this message translates to:
  /// **'Create your first petition using the "Create New" tab'**
  String get createFirstPetition;

  /// Created date label
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdDate(String date);

  /// Next Hearing date label
  ///
  /// In en, this message translates to:
  /// **'Next Hearing: {date}'**
  String nextHearingDate(String date);

  /// Petitioner label
  ///
  /// In en, this message translates to:
  /// **'Petitioner'**
  String get petitioner;

  /// FIR Number label
  ///
  /// In en, this message translates to:
  /// **'FIR Number'**
  String get firNumber;

  /// Grounds label
  ///
  /// In en, this message translates to:
  /// **'Grounds'**
  String get grounds;

  /// Prayer / Relief Sought label
  ///
  /// In en, this message translates to:
  /// **'Prayer / Relief Sought'**
  String get prayerReliefSought;

  /// Filing Date label
  ///
  /// In en, this message translates to:
  /// **'Filing Date'**
  String get filingDate;

  /// Next Hearing label
  ///
  /// In en, this message translates to:
  /// **'Next Hearing'**
  String get nextHearing;

  /// Order Date label
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// Order Details label
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// Extracted Text from Documents label
  ///
  /// In en, this message translates to:
  /// **'Extracted Text from Documents'**
  String get extractedTextFromDocuments;

  /// No Documents Uploaded message
  ///
  /// In en, this message translates to:
  /// **'No Documents Uploaded...'**
  String get noDocumentsUploaded;

  /// Create first case message
  ///
  /// In en, this message translates to:
  /// **'Create your first case to get started'**
  String get createFirstCase;

  /// Create new case button label
  ///
  /// In en, this message translates to:
  /// **'Create New Case'**
  String get createNewCase;

  /// FIR label
  ///
  /// In en, this message translates to:
  /// **'FIR'**
  String get fir;

  /// Answered status
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// Query submitted successfully message
  ///
  /// In en, this message translates to:
  /// **'Query submitted successfully!'**
  String get querySubmittedSuccessfully;

  /// Submit a query title
  ///
  /// In en, this message translates to:
  /// **'Submit a Query'**
  String get submitAQuery;

  /// Query details title
  ///
  /// In en, this message translates to:
  /// **'Query Details'**
  String get queryDetails;

  /// Error message when FIR and incident details are missing
  ///
  /// In en, this message translates to:
  /// **'Please enter both FIR and incident details.'**
  String get enterFirAndIncidentDetails;

  /// Success message for Legal Section Suggester generation
  ///
  /// In en, this message translates to:
  /// **'Legal Section Suggester generated.'**
  String get legalSuggestionsGenerated;

  /// Error message for failed suggestions generation
  ///
  /// In en, this message translates to:
  /// **'Failed to generate Legal Section Suggester: {error}'**
  String failedToGenerateSuggestions(String error);

  /// Description for Legal Section Suggestions screen
  ///
  /// In en, this message translates to:
  /// **'Provide FIR and incident details to get AI-powered suggestions for applicable legal sections under BNS, BNSS, BSA, and other special acts.'**
  String get provideFirDetailsDesc;

  /// Hint text for FIR details input
  ///
  /// In en, this message translates to:
  /// **'Enter comprehensive details from the First Information Report...'**
  String get enterFirDetailsHint;

  /// Hint text for incident details input
  ///
  /// In en, this message translates to:
  /// **'Describe the incident in detail, including sequence of events, actions taken, etc...'**
  String get describeIncidentHint;

  /// Processing status message
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Button text to get Legal Section Suggester
  ///
  /// In en, this message translates to:
  /// **'Get Legal Section Suggester'**
  String get getLegalSuggestions;

  /// Analyzing information message
  ///
  /// In en, this message translates to:
  /// **'Analyzing information and generating suggestions...'**
  String get analyzingInformation;

  /// Title for AI Legal Section Suggester result
  ///
  /// In en, this message translates to:
  /// **'AI Legal Section Suggester'**
  String get aiLegalSuggestions;

  /// Description for reviewing suggestions
  ///
  /// In en, this message translates to:
  /// **'Review the suggested legal sections and reasoning. This is for informational purposes only.'**
  String get reviewSuggestionsDesc;

  /// Suggested sections label
  ///
  /// In en, this message translates to:
  /// **'Suggested Sections'**
  String get suggestedSections;

  /// Message when no sections are suggested
  ///
  /// In en, this message translates to:
  /// **'No sections suggested'**
  String get noSectionsSuggested;

  /// Reasoning label
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get reasoning;

  /// Message when no reasoning is provided
  ///
  /// In en, this message translates to:
  /// **'No reasoning provided'**
  String get noReasoningProvided;

  /// Disclaimer for AI generated content
  ///
  /// In en, this message translates to:
  /// **'AI-generated content. Always consult with a legal expert for official advice.'**
  String get aiDisclaimer;

  /// Error message when case data and recipient type are missing
  ///
  /// In en, this message translates to:
  /// **'Please provide case data and select a recipient type.'**
  String get provideCaseDataAndRecipient;

  /// Success message for document draft generation
  ///
  /// In en, this message translates to:
  /// **'Document draft generated.'**
  String get documentDraftGenerated;

  /// Error message for failed draft generation
  ///
  /// In en, this message translates to:
  /// **'Failed to generate document draft: {error}'**
  String failedToGenerateDraft(String error);

  /// Description for document drafting screen
  ///
  /// In en, this message translates to:
  /// **'Generate document drafts based on case data for specific recipients like medical officers or forensic experts.'**
  String get documentDraftingDesc;

  /// Hint text for case data input
  ///
  /// In en, this message translates to:
  /// **'Paste all relevant case data: complaint transcripts, witness statements, FIR details, investigation notes, etc...'**
  String get pasteCaseDataHint;

  /// Hint text for recipient type selection
  ///
  /// In en, this message translates to:
  /// **'Select recipient type'**
  String get selectRecipientType;

  /// Additional instructions label
  ///
  /// In en, this message translates to:
  /// **'Additional Instructions (Optional)'**
  String get additionalInstructionsOptional;

  /// Hint text for additional instructions
  ///
  /// In en, this message translates to:
  /// **'E.g., \'Focus on injuries sustained\', \'Request specific tests for DNA analysis\', \'Keep the tone formal and urgent\'...'**
  String get additionalInstructionsHint;

  /// Drafting status message
  ///
  /// In en, this message translates to:
  /// **'Drafting...'**
  String get drafting;

  /// Button text to draft document
  ///
  /// In en, this message translates to:
  /// **'Draft Document'**
  String get draftDocument;

  /// Drafting wait message
  ///
  /// In en, this message translates to:
  /// **'Drafting document, please wait...'**
  String get draftingWait;

  /// Title for generated document draft
  ///
  /// In en, this message translates to:
  /// **'Generated Document Draft'**
  String get generatedDocumentDraft;

  /// Description for reviewing draft
  ///
  /// In en, this message translates to:
  /// **'Review the generated draft. You can copy and edit it as needed.'**
  String get reviewDraftDesc;

  /// Message when no draft is generated
  ///
  /// In en, this message translates to:
  /// **'No draft generated'**
  String get noDraftGenerated;

  /// Disclaimer for AI generated draft
  ///
  /// In en, this message translates to:
  /// **'AI-generated content. Verify and adapt for official use.'**
  String get aiDraftDisclaimer;

  /// Message when draft is copied
  ///
  /// In en, this message translates to:
  /// **'Draft copied to clipboard'**
  String get draftCopied;

  /// Button text to copy draft
  ///
  /// In en, this message translates to:
  /// **'Copy Draft'**
  String get copyDraft;

  /// Message when files are added
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) added'**
  String filesAdded(int count);

  /// Error message when picking files
  ///
  /// In en, this message translates to:
  /// **'Error picking files: {error}'**
  String errorPickingFiles(String error);

  /// Message to upload at least one document
  ///
  /// In en, this message translates to:
  /// **'Please upload at least one document.'**
  String get pleaseUploadDocument;

  /// Success message for charge sheet generation
  ///
  /// In en, this message translates to:
  /// **'Draft charge sheet generated.'**
  String get draftChargeSheetGenerated;

  /// Error message for failed charge sheet generation
  ///
  /// In en, this message translates to:
  /// **'Failed to generate charge sheet: {error}'**
  String failedToGenerateChargeSheet(String error);

  /// Description for charge sheet generator
  ///
  /// In en, this message translates to:
  /// **'Upload relevant documents (FIR, witness statements, evidence reports in .doc, .docx, .pdf, .txt) and provide additional instructions. The AI will formulate a draft charge sheet based on the provided template.'**
  String get chargesheetGeneratorDesc;

  /// Case documents label
  ///
  /// In en, this message translates to:
  /// **'Case Documents'**
  String get caseDocuments;

  /// Button text to choose files
  ///
  /// In en, this message translates to:
  /// **'Choose Files'**
  String get chooseFiles;

  /// Uploaded files label
  ///
  /// In en, this message translates to:
  /// **'Uploaded Files:'**
  String get uploadedFiles;

  /// Hint text for chargesheet instructions
  ///
  /// In en, this message translates to:
  /// **'E.g., \'Focus on connecting Accused A to the weapon found.\', \'Emphasize the premeditation aspect based on Witness B\'s statement.\'...'**
  String get chargesheetInstructionsHint;

  /// Generating status message
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// Button text to generate draft charge sheet
  ///
  /// In en, this message translates to:
  /// **'Generate Draft Charge Sheet'**
  String get generateDraftChargeSheet;

  /// Generating wait message
  ///
  /// In en, this message translates to:
  /// **'Generating charge sheet, this may take a moment...'**
  String get generatingChargeSheetWait;

  /// Title for generated draft charge sheet
  ///
  /// In en, this message translates to:
  /// **'Generated Draft Charge Sheet'**
  String get generatedDraftChargeSheet;

  /// Description for reviewing charge sheet
  ///
  /// In en, this message translates to:
  /// **'Review the generated draft. This is a starting point and requires legal review and verification against original documents.'**
  String get reviewChargeSheetDesc;

  /// Profile updated success message
  String get profileUpdated;

  /// Message when no charge sheet is generated
  ///
  /// In en, this message translates to:
  /// **'No charge sheet generated'**
  String get noChargeSheetGenerated;

  /// Disclaimer for AI generated charge sheet
  ///
  /// In en, this message translates to:
  /// **'AI-generated content. Must be reviewed and verified by a legal professional.'**
  String get aiChargeSheetDisclaimer;

  /// Message when file content is loaded
  ///
  /// In en, this message translates to:
  /// **'{fileName} content loaded.'**
  String fileContentLoaded(String fileName);

  /// Error message when reading file
  ///
  /// In en, this message translates to:
  /// **'Error reading file: {error}'**
  String errorReadingFile(String error);

  /// Message to upload or paste charge sheet
  ///
  /// In en, this message translates to:
  /// **'Please upload or paste the charge sheet content.'**
  String get pleaseUploadOrPasteChargesheet;

  /// Success message for charge sheet vetting
  ///
  /// In en, this message translates to:
  /// **'Charge sheet vetted and suggestions provided.'**
  String get chargesheetVettedSuccess;

  /// Error message for failed vetting
  ///
  /// In en, this message translates to:
  /// **'Failed to vet charge sheet: {error}'**
  String failedToVetChargesheet(String error);

  /// Title for charge sheet vetting AI
  ///
  /// In en, this message translates to:
  /// **'Charge Sheet Vetting AI'**
  String get chargesheetVettingAI;

  /// Description for vetting screen
  ///
  /// In en, this message translates to:
  /// **'Upload or paste an existing charge sheet. The AI will review it and suggest improvements to strengthen the case.'**
  String get chargesheetVettingDesc;

  /// Label for upload charge sheet
  ///
  /// In en, this message translates to:
  /// **'Upload Charge Sheet (.txt file)'**
  String get uploadChargesheet;

  /// Button text to choose file
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// Message when file is loaded
  ///
  /// In en, this message translates to:
  /// **'File loaded. You can also edit below.'**
  String get fileLoadedEditBelow;

  /// Label for paste charge sheet
  ///
  /// In en, this message translates to:
  /// **'Or Paste Charge Sheet Content'**
  String get orPasteChargesheet;

  /// Hint text for charge sheet content
  ///
  /// In en, this message translates to:
  /// **'Paste the full content of the charge sheet here...'**
  String get pasteChargesheetHint;

  /// Vetting status message
  ///
  /// In en, this message translates to:
  /// **'Vetting...'**
  String get vetting;

  /// Button text to vet charge sheet
  ///
  /// In en, this message translates to:
  /// **'Vet Charge Sheet'**
  String get vetChargeSheet;

  /// Vetting wait message
  ///
  /// In en, this message translates to:
  /// **'Vetting charge sheet, please wait...'**
  String get vettingChargesheetWait;

  /// Title for AI vetting suggestions
  ///
  /// In en, this message translates to:
  /// **'AI Vetting Suggestions'**
  String get aiVettingSuggestions;

  /// Description for reviewing suggestions
  ///
  /// In en, this message translates to:
  /// **'Review the suggestions to improve the charge sheet.'**
  String get reviewSuggestionsToImprove;

  /// Message when no suggestions provided
  ///
  /// In en, this message translates to:
  /// **'No suggestions provided'**
  String get noSuggestionsProvided;

  /// Disclaimer for AI vetting suggestions
  ///
  /// In en, this message translates to:
  /// **'AI-generated suggestions. Legal expertise is required for final decisions.'**
  String get aiVettingDisclaimer;

  /// Message to fill all witness preparation fields
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields: case details, witness statement, and witness name.'**
  String get pleaseFillAllWitnessFields;

  /// Success message for witness preparation
  ///
  /// In en, this message translates to:
  /// **'Witness preparation session complete.'**
  String get witnessPreparationComplete;

  /// Error message for failed witness preparation
  ///
  /// In en, this message translates to:
  /// **'Failed to conduct witness preparation session: {error}'**
  String failedToPrepareWitness(String error);

  /// Title for AI witness preparation
  ///
  /// In en, this message translates to:
  /// **'AI Witness Preparation'**
  String get aiWitnessPreparation;

  /// Description for witness preparation screen
  ///
  /// In en, this message translates to:
  /// **'Simulate a mock trial experience for a witness. The AI assistant will ask potential cross-examination questions.'**
  String get witnessPreparationDesc;

  /// Hint text for witness name
  ///
  /// In en, this message translates to:
  /// **'Enter the witness\\'s full name'**
  String get enterWitnessNameHint;

  /// Hint text for case details
  ///
  /// In en, this message translates to:
  /// **'Provide comprehensive case details: charges, evidence, known facts, etc.'**
  String get caseDetailsHint;

  /// Hint text for witness statement
  ///
  /// In en, this message translates to:
  /// **'Enter the witness\\'s statement that will be used for the mock trial.'**
  String get witnessStatementHint;

  /// Preparing status message
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// Button text to start mock trial
  ///
  /// In en, this message translates to:
  /// **'Start Mock Trial'**
  String get startMockTrial;

  /// Preparing wait message
  ///
  /// In en, this message translates to:
  /// **'Preparing mock trial session...'**
  String get preparingMockTrialWait;

  /// Title for mock trial and feedback
  ///
  /// In en, this message translates to:
  /// **'Mock Trial & Feedback'**
  String get mockTrialAndFeedback;

  /// Description for reviewing mock trial
  ///
  /// In en, this message translates to:
  /// **'Review the mock trial transcript and AI feedback for witness {witnessName}.'**
  String reviewMockTrialFor(String witnessName);

  /// Label for mock trial transcript
  ///
  /// In en, this message translates to:
  /// **'Mock Trial Transcript'**
  String get mockTrialTranscript;

  /// Message when no transcript available
  ///
  /// In en, this message translates to:
  /// **'No transcript available'**
  String get noTranscriptAvailable;

  /// Label for potential weaknesses
  ///
  /// In en, this message translates to:
  /// **'Potential Weaknesses'**
  String get potentialWeaknesses;

  /// Message when no weaknesses identified
  ///
  /// In en, this message translates to:
  /// **'No weaknesses identified'**
  String get noWeaknessesIdentified;

  /// Label for suggested improvements
  ///
  /// In en, this message translates to:
  /// **'Suggested Improvements'**
  String get suggestedImprovements;

  /// Message when no improvements suggested
  ///
  /// In en, this message translates to:
  /// **'No improvements suggested'**
  String get noImprovementsSuggested;

  /// Disclaimer for AI simulation
  ///
  /// In en, this message translates to:
  /// **'This is an AI simulation. Real trial conditions may vary.'**
  String get aiSimulationDisclaimer;

  /// Message for image size limit
  ///
  /// In en, this message translates to:
  /// **'Please select an image smaller than 10MB.'**
  String get imageSizeLimit;

  /// Error message when picking image
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(String error);

  /// Dialog title for selecting image source
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Gallery option
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Camera option
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Message to select image for analysis
  ///
  /// In en, this message translates to:
  /// **'Please select an image to analyze.'**
  String get pleaseSelectImageToAnalyze;

  /// Success message for analysis completion
  ///
  /// In en, this message translates to:
  /// **'Analysis complete. Review the AI-generated findings below.'**
  String get analysisComplete;

  /// Error message for failed media analysis
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze media: {error}'**
  String failedToAnalyzeMedia(String error);

  /// Title for AI Crime Scene Investigator
  ///
  /// In en, this message translates to:
  /// **'AI Crime Scene Investigator'**
  String get aiCrimeSceneInvestigator;

  /// Description for media analysis screen
  ///
  /// In en, this message translates to:
  /// **'Upload an image (max 10MB) for crime scene analysis. The AI will identify elements, describe the scene, and provide a summary.'**
  String get mediaAnalysisDesc;

  /// Label for upload image
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// Button text to choose image
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get chooseImage;

  /// Label for context/instructions
  ///
  /// In en, this message translates to:
  /// **'Context / Specific Instructions (Optional)'**
  String get contextInstructions;

  /// Hint text for context instructions
  ///
  /// In en, this message translates to:
  /// **'E.g., \\'Focus on potential weapons.\\', \\'Is there any sign of forced entry?\\', \\'What is written on the note on the table?\\''**
  String get contextInstructionsHint;

  /// Analyzing status message
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// Button text to analyze image
  ///
  /// In en, this message translates to:
  /// **'Analyze Image'**
  String get analyzeImage;

  /// Analyzing wait message
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing the image, please wait...'**
  String get analyzingImageWait;

  /// Analyzing complexity note
  ///
  /// In en, this message translates to:
  /// **'(This may take a moment depending on image complexity)'**
  String get analyzingComplexityNote;

  /// Title for crime scene analysis report
  ///
  /// In en, this message translates to:
  /// **'Crime Scene Analysis Report'**
  String get crimeSceneAnalysisReport;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// File label
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// Label for identified elements
  ///
  /// In en, this message translates to:
  /// **'Identified Elements'**
  String get identifiedElements;

  /// Count label
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Message when no elements identified
  ///
  /// In en, this message translates to:
  /// **'No specific elements prominently identified or analysis incomplete.'**
  String get noElementsIdentified;

  /// Label for scene narrative
  ///
  /// In en, this message translates to:
  /// **'Scene Narrative (Editable)'**
  String get sceneNarrativeEditable;

  /// Hint for scene narrative
  ///
  /// In en, this message translates to:
  /// **'AI-generated scene narrative will appear here. You can edit it.'**
  String get sceneNarrativeHint;

  /// Label for case file summary
  ///
  /// In en, this message translates to:
  /// **'Case File Summary & Hypotheses (Editable)'**
  String get caseFileSummaryEditable;

  /// Hint for case file summary
  ///
  /// In en, this message translates to:
  /// **'AI-generated summary and hypotheses will appear here. You can edit it.'**
  String get caseFileSummaryHint;

  /// Disclaimer for AI analysis
  ///
  /// In en, this message translates to:
  /// **'AI-generated analysis. Verify with physical investigation.'**
  String get aiAnalysisDisclaimer;

  /// Download button text
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Download feature coming soon message
  ///
  /// In en, this message translates to:
  /// **'Download feature coming soon'**
  String get downloadFeatureComingSoon;

  /// Error message when loading journal
  ///
  /// In en, this message translates to:
  /// **'Error loading journal: {error}'**
  String errorLoadingJournal(String error);

  /// Dialog title for adding journal entry
  ///
  /// In en, this message translates to:
  /// **'Add Journal Entry'**
  String get addJournalEntry;

  /// Label for activity type
  ///
  /// In en, this message translates to:
  /// **'Activity Type'**
  String get activityType;

  /// Activity: FIR Registered
  ///
  /// In en, this message translates to:
  /// **'FIR Registered'**
  String get firRegistered;

  /// Activity: Evidence Collected
  ///
  /// In en, this message translates to:
  /// **'Evidence Collected'**
  String get evidenceCollected;

  /// Activity: Witness Examined
  ///
  /// In en, this message translates to:
  /// **'Witness Examined'**
  String get witnessExamined;

  /// Activity: Arrest Made
  ///
  /// In en, this message translates to:
  /// **'Arrest Made'**
  String get arrestMade;

  /// Activity: Medical Report Obtained
  ///
  /// In en, this message translates to:
  /// **'Medical Report Obtained'**
  String get medicalReportObtained;

  /// Activity: Scene Visited
  ///
  /// In en, this message translates to:
  /// **'Scene Visited'**
  String get sceneVisited;

  /// Activity: Document Submitted
  ///
  /// In en, this message translates to:
  /// **'Document Submitted'**
  String get documentSubmitted;

  /// Activity: Hearing Attended
  ///
  /// In en, this message translates to:
  /// **'Hearing Attended'**
  String get hearingAttended;

  /// Label for entry details
  ///
  /// In en, this message translates to:
  /// **'Entry Details'**
  String get entryDetails;

  /// Hint for entry details
  ///
  /// In en, this message translates to:
  /// **'Describe the activity in detail...'**
  String get entryDetailsHint;

  /// Message to enter entry details
  ///
  /// In en, this message translates to:
  /// **'Please enter entry details'**
  String get pleaseEnterEntryDetails;

  /// Button text to add entry
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// Success message for adding journal entry
  ///
  /// In en, this message translates to:
  /// **'Journal entry added successfully'**
  String get journalEntryAddedSuccess;

  /// Error message for adding entry
  ///
  /// In en, this message translates to:
  /// **'Error adding entry: {error}'**
  String errorAddingEntry(String error);

  /// Description for case journal
  ///
  /// In en, this message translates to:
  /// **'View investigation diaries and case activity logs'**
  String get caseJournalDesc;

  /// Label for select case
  ///
  /// In en, this message translates to:
  /// **'Select Case'**
  String get selectCase;

  /// Message when no cases available
  ///
  /// In en, this message translates to:
  /// **'No cases available. Please register a case first.'**
  String get noCasesAvailable;

  /// Hint for choosing case
  ///
  /// In en, this message translates to:
  /// **'Choose a case to view journal'**
  String get chooseCaseToViewJournal;

  /// Title for investigation diary
  ///
  /// In en, this message translates to:
  /// **'Investigation Diary'**
  String get investigationDiary;

  /// Tooltip for add journal entry
  ///
  /// In en, this message translates to:
  /// **'Add journal entry'**
  String get addJournalEntryTooltip;

  /// Tooltip for open case details
  ///
  /// In en, this message translates to:
  /// **'Open case details'**
  String get openCaseDetails;

  /// Message when no journal entries
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet'**
  String get noJournalEntries;

  /// Description for no journal entries
  ///
  /// In en, this message translates to:
  /// **'Journal entries will appear here as the investigation progresses.'**
  String get noJournalEntriesDesc;

  /// Reference label
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get ref;

  /// Success message for case creation
  ///
  /// In en, this message translates to:
  /// **'Case created successfully!'**
  String get caseCreatedSuccess;

  /// Error message for case creation
  ///
  /// In en, this message translates to:
  /// **'Error creating case: {error}'**
  String errorCreatingCase(String error);

  /// Label for case title
  ///
  /// In en, this message translates to:
  /// **'Case Title *'**
  String get caseTitleRequired;

  /// Hint for case title
  ///
  /// In en, this message translates to:
  /// **'Enter a brief title for the case'**
  String get caseTitleHint;

  /// Validation message for case title
  ///
  /// In en, this message translates to:
  /// **'Please enter a case title'**
  String get pleaseEnterCaseTitle;

  /// Label for FIR number
  ///
  /// In en, this message translates to:
  /// **'FIR Number *'**
  String get firNumberRequired;

  /// Hint for FIR number
  ///
  /// In en, this message translates to:
  /// **'Enter FIR number'**
  String get firNumberHint;

  /// Validation message for FIR number
  ///
  /// In en, this message translates to:
  /// **'Please enter FIR number'**
  String get pleaseEnterFirNumber;

  /// Section title for location details
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locationDetails;

  /// Section title for additional information
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// Label for complainant name
  ///
  /// In en, this message translates to:
  /// **'Complainant Name'**
  String get complainantName;

  /// Hint for complainant name
  ///
  /// In en, this message translates to:
  /// **'Enter complainant name'**
  String get enterComplainantName;

  /// Hint for incident details
  ///
  /// In en, this message translates to:
  /// **'Describe the incident'**
  String get describeIncident;

  /// Button text to create case
  ///
  /// In en, this message translates to:
  /// **'Create Case'**
  String get createCase;

  /// Default user text
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Telugu language option
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Dharma'**
  String get appName;

  /// Application version
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get appVersion;

  /// Application description
  ///
  /// In en, this message translates to:
  /// **'Legal assistance platform powered by AI technology.'**
  String get appDescription;

  /// Confirmation message for sign out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  String get loginWithPhone;
String get mobileNumber;
String get sendOtp;
String get verifyOtp;
String get otpSent;
String get otpResent;
String get enterValidNumber;
String get enterOtp;
String resendIn(int seconds);
String get resendOtp;
String get loginSuccessful;
String get wrongOtp;
String get otpExpired;
String get invalidOtp;
String get backToEmailLogin;
String get emergencyHelplines;
String get sos112;
String get helplineEmergencyAll;
String get helplineEmergencyAllDesc;
String get helplinePolice;
String get helplinePoliceDesc;
String get helplineFire;
String get helplineFireDesc;
String get helplineAmbulance;
String get helplineAmbulanceDesc;
String get helplineAmbulanceAlt;
String get helplineAmbulanceAltDesc;
String get helplineWomen;
String get helplineWomenDesc;
String get helplineDomestic;
String get helplineDomesticDesc;
String get helplineChild;
String get helplineChildDesc;
String get helplineCyber;
String get helplineCyberDesc;
String get support;
String get yourLegalAssistanceHub;

String get inProgress;
String get closed;
String get received;
String get welcome;
String get policeCommandCenter;
String get petitionOverview;
String get recentActivityDescription;
  String get helpline;
String get userNotRegistered;
String get registeredAs;
String get tryingToLoginAs;
String get selectCorrectOption;
String get loginFailed;
String get googleLoginSuccessful;

// Police Login & Registration
String get policeLogin;
String get policeRegistration;
String get policeLoginSuccessful;
String get policeRegisteredSuccessfully;
String get dontHavePoliceAccount;
String get invalidName;
String get invalidEmailShort;
String get passwordMinRequirement;
String get rank;
String get selectRank;
String get selectDistrict;
String get selectPoliceStationText;
String get pleaseSelectAllDropdownFields;
String get searchHint;
String selectLabel(String label);
String get aiInvestigationGuidelines;
String get enterFirNumber;
String get startInvestigation;
String get enterOfficerResponse;
String get errorContactingInvestigationAI;
String get districtAndFirDetails;
String get occurenceOfOffence;
String get dayOfOccurrence;
String get dateTimeFrom;
String get dateTimeTo;
String get selectDateAndTime;
String get timePeriod;
String get priorToDateTimeDetails;
String get beatNumber;
String get placeOfOccurrence;
String get streetVillage;
String get areaMandal;
String get cityDistrict;
String get pin;
String get latitude;
String get longitude;
String get map;
String get viewMap;
String get listening;
String get tapToStopRecording;
String get imageLab;
String get addPolice;
String get submitOfflinePetition;
String get offlinePetitions;
String get assignedPetitions;
String get escalated;
String get viewDetails;
String get filterCasesUsingFilters;
String get yourAccessLevel;
String get ok;

  /// Filters section label in cases screen
  ///
  /// In en, this message translates to:
  /// **'Filters:'**
  String get filters;

  /// Police range filter label
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// Age filter label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// Description for cases screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage and view details of FIRs / Cases you are involved in.'**
  String get casesScreenSubtitle;



  /// Label for crimeScene
  String get crimeScene;

  /// Label for investigation
  String get investigation;

  /// Label for evidence
  String get evidence;

  /// Label for finalReport
  String get finalReport;

  /// Label for editCase
  String get editCase;

  /// Label for caseInformation
  String get caseInformation;

 

  /// Label for year
  String get year;

  /// Label for complaintId
  String get complaintId;

  /// Label for firDate
  String get firDate;

  /// Label for firFiledAt
  String get firFiledAt;



  /// Label for occurrenceOfOffence
  String get occurrenceOfOffence;



  /// Label for from
  String get from;

  /// Label for to
  String get to;
 

  /// Label for distanceFromPS
  String get distanceFromPS;

  /// Label for directionFromPS
  String get directionFromPS;

  /// Label for outsideJurisdiction
  String get outsideJurisdiction;

  /// Label for informationReceivedAtPS
  String get informationReceivedAtPS;

  /// Label for dateTimeReceived
  String get dateTimeReceived;

  /// Label for gdEntryNo
  String get gdEntryNo;

  /// Label for typeOfInformation
  String get typeOfInformation;

  /// Label for complainantInformantDetails
  String get complainantInformantDetails;

  /// Label for name
  String get name;

  /// Label for fatherHusbandName
  String get fatherHusbandName;

  /// Label for dob
  String get dob;

  /// Label for nationality
  String get nationality;

  /// Label for caste
  String get caste;

  /// Label for occupation
  String get occupation;

  
  /// Label for passportNo
  String get passportNo;

  /// Label for passportPlaceOfIssue
  String get passportPlaceOfIssue;

  /// Label for passportDateOfIssue
  String get passportDateOfIssue;

  /// Label for victimDetails
  String get victimDetails;

  /// Label for religion
  String get religion;

  /// Label for complainantAlsoVictim
  String get complainantAlsoVictim;

  /// Label for accusedDetails
  String get accusedDetails;

  /// Label for accused
  String get accused;

  /// Label for propertiesDelayInquest
  String get propertiesDelayInquest;

  /// Label for propertiesInvolved
  String get propertiesInvolved;

  /// Label for totalValueINR
  String get totalValueINR;

  /// Label for delayInReporting
  String get delayInReporting;

  /// Label for inquestReportCaseNo
  String get inquestReportCaseNo;

  /// Label for actsStatement
  String get actsStatement;

  /// Label for actsAndSectionsInvolved
  String get actsAndSectionsInvolved;

  /// Label for complaintStatement
  String get complaintStatement;

  /// Label for briefIncidentDetails
  String get briefIncidentDetails;

  /// Label for actionTakenAndConfirmation
  String get actionTakenAndConfirmation;

  /// Label for actionTaken
  String get actionTaken;

  /// Label for investigatingOfficer
  String get investigatingOfficer;

 
  /// Label for dispatchToCourtDateTime
  String get dispatchToCourtDateTime;

  /// Label for dispatchingOfficer
  String get dispatchingOfficer;

  /// Label for dispatchingOfficerRank
  String get dispatchingOfficerRank;

  /// Label for firReadAndAdmittedCorrect
  String get firReadAndAdmittedCorrect;

  /// Label for copyGivenFreeOfCost
  String get copyGivenFreeOfCost;

  /// Label for roacRecorded
  String get roacRecorded;

  /// Label for signatureThumbImpression
  String get signatureThumbImpression;

  /// Label for yes
  String get yes;

  /// Label for no
  String get no;

  /// Label for crimeScenes
  String get crimeScenes;

  /// Label for addScene
  String get addScene;

  /// Label for noCrimeScenesLinked
  String get noCrimeScenesLinked;

  /// Label for unknownType
  String get unknownType;

  /// Label for deleteScene
  String get deleteScene;

  /// Label for areSureDeleteScene
  String get areSureDeleteScene;

  /// Label for place
  String get place;

  /// Label for physicalEvidence
  String get physicalEvidence;

  /// Label for recorded
  String get recorded;

  /// Label for captureCrimeSceneEvidence
  String get captureCrimeSceneEvidence;

  /// Label for photo
  String get photo;

  /// Label for video
  String get video;

  /// Label for upload
  String get upload;

  /// Label for evidenceFiles
  String get evidenceFiles;

  /// Label for analyzeSceneWithAI
  String get analyzeSceneWithAI;

  /// Label for analyzing
  

  /// Label for aiSceneAnalysis
  String get aiSceneAnalysis;

  /// Label for crimeSceneAnalysisReports
  String get crimeSceneAnalysisReports;

  /// Label for noAnalysisReportsFound
  String get noAnalysisReportsFound;

  /// Label for caseJournalIOsDiary
  String get caseJournalIOsDiary;

  /// Label for noJournalEntriesYet
  String get noJournalEntriesYet;

  /// Label for crimeSceneCaptures
  String get crimeSceneCaptures;

  /// Label for fromInvestigationDiary
  String get fromInvestigationDiary;

  /// Label for fromPetitions
  String get fromPetitions;

  /// Label for forensicAnalysisReports
  String get forensicAnalysisReports;

  /// Label for noEvidenceDocumentsFound
  String get noEvidenceDocumentsFound;

  /// Label for attachedDocumentsWillAppearHere
  String get attachedDocumentsWillAppearHere;

  /// Label for noDocumentsAttachedJournal
  String get noDocumentsAttachedJournal;

  /// Label for noPetitionDocumentsLinked
  String get noPetitionDocumentsLinked;

  /// Label for finalInvestigationReport
  String get finalInvestigationReport;

  /// Label for generatedOn
  String get generatedOn;

  /// Label for noFinalReportAttached
  String get noFinalReportAttached;

  /// Label for onceSomeoneGeneratesReport
  String get onceSomeoneGeneratesReport;

  /// Label for courtReadyReportGenerated
  String get courtReadyReportGenerated;

  /// Label for downloadViewFinalReportPDF
  String get downloadViewFinalReportPDF;

  /// Label for loadingEvidenceFromAllSources
  String get loadingEvidenceFromAllSources;

  /// Label for addCrimeScene
  String get addCrimeScene;

  /// Label for editCrimeScene
  String get editCrimeScene;

  /// Label for crimeType
  String get crimeType;

  /// Label for placeDescription
  String get placeDescription;

  /// Label for physicalEvidenceDescription
  String get physicalEvidenceDescription;

 

  /// Label for crimeSceneAdded
  String get crimeSceneAdded;

  /// Label for crimeSceneUpdated
  String get crimeSceneUpdated;

  /// Label for errorSavingCrimeScene
  String get errorSavingCrimeScene;

  
  

  /// Label for uploadingCapturedEvidence
  String get uploadingCapturedEvidence;

  /// Label for failedUploadEvidence
  String get failedUploadEvidence;

  /// Label for geoTaggedPhotoCaptured
  String get geoTaggedPhotoCaptured;

  /// Label for geoTaggedVideoCaptured
  String get geoTaggedVideoCaptured;

  /// Label for uploadEvidence
  String get uploadEvidence;

  /// Label for chooseFileType
  String get chooseFileType;

  /// Label for image
  String get image;

  /// Label for document
  String get document;

  /// Label for uploadingDocument
  String get uploadingDocument;

  /// Label for failedUploadDocument
  String get failedUploadDocument;

  /// Label for documentUploaded
  String get documentUploaded;

  /// Label for imageUploaded
  String get imageUploaded;

  /// Label for videoUploaded
  String get videoUploaded;

  /// Label for errorUploadingFile
  String get errorUploadingFile;

  /// Label for pleaseCapturUploadEvidenceFirst
  String get pleaseCapturUploadEvidenceFirst;

  /// Label for sceneAnalysisComplete
  String get sceneAnalysisComplete;

  /// Label for analysisError
  String get analysisError;

  /// Label for downloadEvidence
  String get downloadEvidence;

  /// Label for saveToDeviceDownloads
  String get saveToDeviceDownloads;

  /// Label for analyzeWithAI
  String get analyzeWithAI;

  /// Label for getForensicAnalysis
  String get getForensicAnalysis;

  /// Label for downloadReport
  String get downloadReport;

  /// Label for deleteReport
  String get deleteReport;

  /// Label for deleteReportConfirmation
  String get deleteReportConfirmation;

  /// Label for reportDeleted
  String get reportDeleted;

  /// Label for errorDeletingReport
  String get errorDeletingReport;

  /// Label for generatingPDF
  String get generatingPDF;

  /// Label for errorDownloadingPDF
  String get errorDownloadingPDF;

  /// Label for analyzedOn
  String get analyzedOn;

  /// Label for identifiedElements

  /// Label for sceneNarrative
  String get sceneNarrative;

  /// Label for caseFileSummary
  String get caseFileSummary;

  /// Label for filedOn
  String get filedOn;

  /// Label for accessViaFileManager
  String get accessViaFileManager;

  /// Label for evidenceDownloaded
  String get evidenceDownloaded;

  /// Label for savedTo
  String get savedTo;

  /// Label for downloadFailed
  String get downloadFailed;

  /// Label for analysisComplete
  

  /// Label for analysisErrorEvidence
  String get analysisErrorEvidence;

  /// Label for evidenceRemoved
  String get evidenceRemoved;

  /// Title for petition type selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Petition Type'**
  String get selectPetitionType;

  /// Description for petition type selection dialog
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to file your complaint.\n\nAnonymous: Your name and address will not be recorded (only mobile number required).\n\nNormal: All details will be recorded.'**
  String get petitionTypeDescription;

  /// Button text for anonymous petition option
  ///
  /// In en, this message translates to:
  /// **'Anonymous Petition'**
  String get anonymousPetition;

  /// Button text for normal petition option
  ///
  /// In en, this message translates to:
  /// **'Normal Petition'**
  String get normalPetition;

  /// Message confirming anonymous petition mode selection
  ///
  /// In en, this message translates to:
  /// **'You have selected Anonymous Petition Mode. Your name and address will not be recorded.'**
  String get anonymousPetitionConfirm;

  String get incidentDate;

  String get jurisdictionForFilingComplaint;

  String get iAgreeToThe;

  String get termsAndConditions;

}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'te': return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
