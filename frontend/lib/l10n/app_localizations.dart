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

  /// Legal suggestion menu
  ///
  /// In en, this message translates to:
  /// **'Legal Suggestion'**
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
