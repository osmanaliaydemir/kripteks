import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Kripteks'**
  String get appName;

  /// Label for the dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Label for the bots tab
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get bots;

  /// Label for the tools tab
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// Label for the wallet tab
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// Label for the settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for total balance
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// Label for available balance
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Label for locked balance
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// Label for active profit and loss
  ///
  /// In en, this message translates to:
  /// **'Active PNL'**
  String get activePnl;

  /// Title for transaction history section
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// Filter option for all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Label for deposit action
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// Label for withdraw action
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// Status label for online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Status label for offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Label for login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Label for sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Label for forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Text for account creation prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Title for network error
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// Description for network error
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get networkErrorDescription;

  /// Message when no transactions are found
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// Label for bot investment
  ///
  /// In en, this message translates to:
  /// **'Bot Investment'**
  String get botInvestment;

  /// Label for bot return
  ///
  /// In en, this message translates to:
  /// **'Bot Return'**
  String get botReturn;

  /// Label for transaction fee
  ///
  /// In en, this message translates to:
  /// **'Transaction Fee'**
  String get fee;

  /// Title for profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Error message when profile fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileLoadError;

  /// Label for exchange connection
  ///
  /// In en, this message translates to:
  /// **'Exchange Connection'**
  String get exchangeConnection;

  /// Status label for connected state
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Status label for not connected state
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// Label for updating API keys
  ///
  /// In en, this message translates to:
  /// **'Update API Keys'**
  String get updateApiKeys;

  /// Label for API key field
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// Label for secret key field
  ///
  /// In en, this message translates to:
  /// **'Secret Key'**
  String get secretKey;

  /// Label for cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Message when API keys are updated
  ///
  /// In en, this message translates to:
  /// **'API keys updated'**
  String get apiKeysUpdated;

  /// Label for application
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get app;

  /// Title for notifications screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Subtitle for notifications screen
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationsSubtitle;

  /// Title for update password screen
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// Subtitle for update password screen
  ///
  /// In en, this message translates to:
  /// **'Change account password'**
  String get updatePasswordSubtitle;

  /// Label for logout button
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Message for logout confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// Title for profile edit screen
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// Label for first name field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Error message when first name is missing
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// Label for last name field
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Error message when last name is missing
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// Message when profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// Title for change password screen
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Label for current password field
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Error message when current password is missing
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// Label for new password field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Error message when new password is missing
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// Error message for password length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthError;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPassword;

  /// Error message when confirmation is missing
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// Error message when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Message when password is updated
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// Error message for incorrect password
  ///
  /// In en, this message translates to:
  /// **'Incorrect current password'**
  String get passwordError;

  /// Helper text for password requirements
  ///
  /// In en, this message translates to:
  /// **'Your new password must be at least 6 characters long.'**
  String get passwordInfo;

  /// Title for notification settings
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Info text for notifications
  ///
  /// In en, this message translates to:
  /// **'Get notified about bot activities and important updates.'**
  String get notificationsInfo;

  /// Header for bot notifications section
  ///
  /// In en, this message translates to:
  /// **'Bot Notifications'**
  String get botNotifications;

  /// Label for buy signals toggle
  ///
  /// In en, this message translates to:
  /// **'Buy Signals'**
  String get buySignals;

  /// Description for buy signals toggle
  ///
  /// In en, this message translates to:
  /// **'Get notified when bot buys'**
  String get buySignalsSubtitle;

  /// Label for sell signals toggle
  ///
  /// In en, this message translates to:
  /// **'Sell Signals'**
  String get sellSignals;

  /// Description for sell signals toggle
  ///
  /// In en, this message translates to:
  /// **'Get notified when bot sells'**
  String get sellSignalsSubtitle;

  /// Label for stop loss toggle
  ///
  /// In en, this message translates to:
  /// **'Stop Loss'**
  String get stopLoss;

  /// Description for stop loss toggle
  ///
  /// In en, this message translates to:
  /// **'Get notified when stop loss triggers'**
  String get stopLossSubtitle;

  /// Label for take profit toggle
  ///
  /// In en, this message translates to:
  /// **'Take Profit'**
  String get takeProfit;

  /// Description for take profit toggle
  ///
  /// In en, this message translates to:
  /// **'Get notified when take profit target reached'**
  String get takeProfitSubtitle;

  /// Header for system notifications section
  ///
  /// In en, this message translates to:
  /// **'System Notifications'**
  String get systemNotifications;

  /// Label for general notifications toggle
  ///
  /// In en, this message translates to:
  /// **'General Notifications'**
  String get generalNotifications;

  /// Description for general notifications toggle
  ///
  /// In en, this message translates to:
  /// **'System updates and announcements'**
  String get generalNotificationsSubtitle;

  /// Label for error notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Error Notifications'**
  String get errorNotifications;

  /// Description for error notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Get notified about critical errors'**
  String get errorNotificationsSubtitle;

  /// Title for the login screen
  ///
  /// In en, this message translates to:
  /// **'Login to Kripteks'**
  String get loginTitle;

  /// Hint text for email input
  ///
  /// In en, this message translates to:
  /// **'example@mail.com'**
  String get emailHint;

  /// Error message when email is missing
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Error message when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// Error message when password is missing
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Title for the signup screen
  ///
  /// In en, this message translates to:
  /// **'Sign up for Kripteks'**
  String get signupTitle;

  /// Label for full name input
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Hint text for full name input
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get fullNameHint;

  /// Error message when full name is missing
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// Link text for existing users
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Message displayed when registration is disabled
  ///
  /// In en, this message translates to:
  /// **'Registration is not active yet.'**
  String get registrationDisabled;

  /// Label for biometric login toggle
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// Description for biometric login toggle
  ///
  /// In en, this message translates to:
  /// **'Login with FaceID or TouchID'**
  String get biometricLoginSubtitle;

  /// Hint text for current password input
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get currentPasswordHint;

  /// Hint text for new password input
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get newPasswordHint;

  /// Hint text for confirm password input
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get confirmPasswordHint;

  /// Information text for API key screen
  ///
  /// In en, this message translates to:
  /// **'We need your Binance Spot API keys for transactions. Please ensure the keys have Spot & Margin Trading permissions enabled.'**
  String get apiKeyInfo;

  /// Hint for API Key input
  ///
  /// In en, this message translates to:
  /// **'Enter your Binance API Key'**
  String get apiKeyHint;

  /// Hint for Secret Key input
  ///
  /// In en, this message translates to:
  /// **'Enter your Binance Secret Key'**
  String get secretKeyHint;

  /// Error message for missing API Key
  ///
  /// In en, this message translates to:
  /// **'API Key is required'**
  String get apiKeyRequired;

  /// Error message for missing Secret Key
  ///
  /// In en, this message translates to:
  /// **'Secret Key is required'**
  String get secretKeyRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
