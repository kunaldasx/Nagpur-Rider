import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
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
    Locale('hi'),
    Locale('fr'),
    Locale('ar'),
    Locale('te'),
    Locale('gu'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hyper Local Delivery'**
  String get appTitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @pleaseSelectACountry.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get pleaseSelectACountry;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @pleaseEnterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhoneNumber;

  /// No description provided for @phoneNumberMustBeAtLeast10Digits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be at least 10 digits'**
  String get phoneNumberMustBeAtLeast10Digits;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @passwordMustBeAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMustBeAtLeast8Characters;

  /// No description provided for @passwordMustContainUppercaseLowercaseAndNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain uppercase, lowercase and number'**
  String get passwordMustContainUppercaseLowercaseAndNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterYourAddress;

  /// No description provided for @pleaseEnterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address'**
  String get pleaseEnterYourAddress;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @enterYourVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Enter your vehicle type'**
  String get enterYourVehicleType;

  /// No description provided for @pleaseEnterYourVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Please enter your vehicle type'**
  String get pleaseEnterYourVehicleType;

  /// No description provided for @driverLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Driver License Number'**
  String get driverLicenseNumber;

  /// No description provided for @enterYourLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your license number'**
  String get enterYourLicenseNumber;

  /// No description provided for @pleaseEnterYourLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your license number'**
  String get pleaseEnterYourLicenseNumber;

  /// No description provided for @deliveryZone.
  ///
  /// In en, this message translates to:
  /// **'Delivery Zone'**
  String get deliveryZone;

  /// No description provided for @selectYourDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'Select your delivery zone'**
  String get selectYourDeliveryZone;

  /// No description provided for @pleaseSelectYourDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'Please select your delivery zone'**
  String get pleaseSelectYourDeliveryZone;

  /// No description provided for @uploadDriverLicense.
  ///
  /// In en, this message translates to:
  /// **'Upload Driver License'**
  String get uploadDriverLicense;

  /// No description provided for @uploadVehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Upload Vehicle Registration'**
  String get uploadVehicleRegistration;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have account?'**
  String get dontHaveAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @vehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformation;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @documentUpload.
  ///
  /// In en, this message translates to:
  /// **'Document Upload'**
  String get documentUpload;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get storagePermissionDenied;

  /// No description provided for @noFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'No files selected'**
  String get noFilesSelected;

  /// No description provided for @filePickerPluginNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'File picker plugin not available. Please rebuild the app.'**
  String get filePickerPluginNotAvailable;

  /// No description provided for @errorPickingFile.
  ///
  /// In en, this message translates to:
  /// **'Error picking file: {error}'**
  String errorPickingFile(Object error);

  /// No description provided for @pleaseEnterAValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterAValidPhoneNumber;

  /// No description provided for @pleaseUploadAtLeastOneDriverLicenseFile.
  ///
  /// In en, this message translates to:
  /// **'Please upload at least one driver license file'**
  String get pleaseUploadAtLeastOneDriverLicenseFile;

  /// No description provided for @pleaseUploadAtLeastOneVehicleRegistrationFile.
  ///
  /// In en, this message translates to:
  /// **'Please upload at least one vehicle registration file'**
  String get pleaseUploadAtLeastOneVehicleRegistrationFile;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @deliveryZones.
  ///
  /// In en, this message translates to:
  /// **'Delivery Zones'**
  String get deliveryZones;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @enterYourDetailsBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter your details below'**
  String get enterYourDetailsBelow;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry! Enter your email and we\'ll send you instructions to reset your password.'**
  String get forgotPasswordDescription;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @emailSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email sent successfully'**
  String get emailSentSuccessfully;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @availableOrders.
  ///
  /// In en, this message translates to:
  /// **'Available Orders'**
  String get availableOrders;

  /// No description provided for @noAvailableOrders.
  ///
  /// In en, this message translates to:
  /// **'No Available Orders'**
  String get noAvailableOrders;

  /// No description provided for @ordersWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Orders will appear here when available'**
  String get ordersWillAppearHere;

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String ordersCount(Object count);

  /// No description provided for @expectedEarning.
  ///
  /// In en, this message translates to:
  /// **'Expected Earning'**
  String get expectedEarning;

  /// No description provided for @myEarnings.
  ///
  /// In en, this message translates to:
  /// **'My Earnings'**
  String get myEarnings;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @perPage.
  ///
  /// In en, this message translates to:
  /// **'Per Page'**
  String get perPage;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String orderNumber(Object orderId);

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceled;

  /// No description provided for @baseFee.
  ///
  /// In en, this message translates to:
  /// **'Base Fee'**
  String get baseFee;

  /// No description provided for @storePickup.
  ///
  /// In en, this message translates to:
  /// **'Store Pickup'**
  String get storePickup;

  /// No description provided for @distanceFee.
  ///
  /// In en, this message translates to:
  /// **'Distance Fee'**
  String get distanceFee;

  /// No description provided for @incentive.
  ///
  /// In en, this message translates to:
  /// **'Incentive'**
  String get incentive;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date;

  /// No description provided for @noEarningsYet.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get noEarningsYet;

  /// No description provided for @completeDeliveriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete some deliveries to see your earnings here'**
  String get completeDeliveriesMessage;

  /// No description provided for @errorLoadingEarnings.
  ///
  /// In en, this message translates to:
  /// **'Error loading earnings'**
  String get errorLoadingEarnings;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drop;

  /// No description provided for @pickupFrom.
  ///
  /// In en, this message translates to:
  /// **'Pickup from'**
  String get pickupFrom;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @minsAway.
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins away'**
  String minsAway(Object minutes);

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @accepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting...'**
  String get accepting;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @storePickupCoordinatesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Store pickup coordinates not available'**
  String get storePickupCoordinatesNotAvailable;

  /// No description provided for @noCoordinatesAvailableForMapView.
  ///
  /// In en, this message translates to:
  /// **'No coordinates available for map view'**
  String get noCoordinatesAvailableForMapView;

  /// No description provided for @routeDetailsNotAvailableForMapView.
  ///
  /// In en, this message translates to:
  /// **'Route details not available for map view'**
  String get routeDetailsNotAvailableForMapView;

  /// No description provided for @navigationError.
  ///
  /// In en, this message translates to:
  /// **'Navigation error: {error}'**
  String navigationError(Object error);

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No Orders Found'**
  String get noOrdersFound;

  /// No description provided for @noOrdersAcceptedYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t accepted any orders yet'**
  String get noOrdersAcceptedYet;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeAppLanguage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @changeAppColors.
  ///
  /// In en, this message translates to:
  /// **'Change app theme'**
  String get changeAppColors;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInfo;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'documents'**
  String get documents;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipCode;

  /// No description provided for @vehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get vehicleNumber;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model'**
  String get vehicleModel;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Color'**
  String get vehicleColor;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// No description provided for @insuranceNumber.
  ///
  /// In en, this message translates to:
  /// **'Insurance Number'**
  String get insuranceNumber;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatus;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @shippingDetails.
  ///
  /// In en, this message translates to:
  /// **'Shipping Details'**
  String get shippingDetails;

  /// No description provided for @storeDetails.
  ///
  /// In en, this message translates to:
  /// **'Store Details'**
  String get storeDetails;

  /// No description provided for @paymentInformation.
  ///
  /// In en, this message translates to:
  /// **'Payment Information'**
  String get paymentInformation;

  /// No description provided for @pricingDetails.
  ///
  /// In en, this message translates to:
  /// **'Pricing Details'**
  String get pricingDetails;

  /// No description provided for @earningsDetails.
  ///
  /// In en, this message translates to:
  /// **'Earnings Details'**
  String get earningsDetails;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @finalTotal.
  ///
  /// In en, this message translates to:
  /// **'Final Total'**
  String get finalTotal;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @onlinePayment.
  ///
  /// In en, this message translates to:
  /// **'Online Payment'**
  String get onlinePayment;

  /// No description provided for @perStorePickupFee.
  ///
  /// In en, this message translates to:
  /// **'Per Store Pickup Fee'**
  String get perStorePickupFee;

  /// No description provided for @distanceBasedFee.
  ///
  /// In en, this message translates to:
  /// **'Distance Based Fee'**
  String get distanceBasedFee;

  /// No description provided for @perOrderIncentive.
  ///
  /// In en, this message translates to:
  /// **'Per Order Incentive'**
  String get perOrderIncentive;

  /// No description provided for @collectAllItems.
  ///
  /// In en, this message translates to:
  /// **'Collect All Items'**
  String get collectAllItems;

  /// No description provided for @viewPickupRoute.
  ///
  /// In en, this message translates to:
  /// **'View Pickup Route'**
  String get viewPickupRoute;

  /// No description provided for @deliveredAllOrder.
  ///
  /// In en, this message translates to:
  /// **'Delivered all order'**
  String get deliveredAllOrder;

  /// No description provided for @collectItemsIndividually.
  ///
  /// In en, this message translates to:
  /// **'Collect Items Individually'**
  String get collectItemsIndividually;

  /// No description provided for @itemCollected.
  ///
  /// In en, this message translates to:
  /// **'Item collected successfully'**
  String get itemCollected;

  /// No description provided for @itemDelivered.
  ///
  /// In en, this message translates to:
  /// **'Item delivered successfully'**
  String get itemDelivered;

  /// No description provided for @allItemsCollected.
  ///
  /// In en, this message translates to:
  /// **'All items collected successfully!'**
  String get allItemsCollected;

  /// No description provided for @noItemsToCollect.
  ///
  /// In en, this message translates to:
  /// **'No items to collect'**
  String get noItemsToCollect;

  /// No description provided for @errorCollectingItems.
  ///
  /// In en, this message translates to:
  /// **'Error collecting items: {error}'**
  String errorCollectingItems(Object error);

  /// No description provided for @pleaseEnterValidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get pleaseEnterValidOtp;

  /// No description provided for @otpRequired.
  ///
  /// In en, this message translates to:
  /// **'OTP Required'**
  String get otpRequired;

  /// No description provided for @itemOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'Item OTP Required'**
  String get itemOtpRequired;

  /// No description provided for @deliveryOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'Delivery OTP Required'**
  String get deliveryOtpRequired;

  /// No description provided for @customerOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer OTP Required'**
  String get customerOtpRequired;

  /// No description provided for @pleaseEnterOtpFromCustomer.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP from customer:'**
  String get pleaseEnterOtpFromCustomer;

  /// No description provided for @pleaseEnterOtpForItem.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP for this item:'**
  String get pleaseEnterOtpForItem;

  /// No description provided for @enterDeliveryOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Delivery OTP'**
  String get enterDeliveryOtp;

  /// No description provided for @enterItemOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Item OTP'**
  String get enterItemOtp;

  /// No description provided for @enterCustomerOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Customer OTP'**
  String get enterCustomerOtp;

  /// No description provided for @verifyAndDeliver.
  ///
  /// In en, this message translates to:
  /// **'Verify & Deliver'**
  String get verifyAndDeliver;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @otpVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP verified successfully!'**
  String get otpVerifiedSuccessfully;

  /// No description provided for @noOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'No OTP required for this item'**
  String get noOtpRequired;

  /// No description provided for @cashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash Collected'**
  String get cashCollected;

  /// No description provided for @pleaseCollectCash.
  ///
  /// In en, this message translates to:
  /// **'Please collect the cash from the customer before proceeding.'**
  String get pleaseCollectCash;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order Completed!'**
  String get orderCompleted;

  /// No description provided for @allItemsDeliveredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All items have been delivered successfully!'**
  String get allItemsDeliveredSuccessfully;

  /// No description provided for @yourEarningsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Your Earnings Breakdown'**
  String get yourEarningsBreakdown;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get deliver;

  /// No description provided for @collect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collect;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @kmFromCustomer.
  ///
  /// In en, this message translates to:
  /// **'{distance} km from customer'**
  String kmFromCustomer(Object distance);

  /// No description provided for @collectedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Collect All Items ({collected}/{total})'**
  String collectedItemsCount(Object collected, Object total);

  /// No description provided for @collectItemsIndividuallyCount.
  ///
  /// In en, this message translates to:
  /// **'Collect Items Individually ({collected}/{total})'**
  String collectItemsIndividuallyCount(Object collected, Object total);

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @documentViewer.
  ///
  /// In en, this message translates to:
  /// **'Document Viewer'**
  String get documentViewer;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get inactive;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @pockets.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get pockets;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @withdrawalHistory.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal History'**
  String get withdrawalHistory;

  /// No description provided for @createWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Create Withdrawal'**
  String get createWithdrawal;

  /// No description provided for @withdrawalAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Amount'**
  String get withdrawalAmount;

  /// No description provided for @bankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetails;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @ifscCode.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get ifscCode;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderName;

  /// No description provided for @requestWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Request Withdrawal'**
  String get requestWithdrawal;

  /// No description provided for @withdrawalRequested.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Requested Successfully'**
  String get withdrawalRequested;

  /// No description provided for @minimumWithdrawalAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal amount is ₹100'**
  String get minimumWithdrawalAmount;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @smsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get smsNotifications;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionRequired;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermissionRequired;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get storagePermissionRequired;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required'**
  String get microphonePermissionRequired;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'This app needs {permission} permission to function properly.'**
  String permissionExplanation(Object permission);

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get required;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get invalidPassword;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid OTP'**
  String get invalidOtp;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @invalidAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid account number'**
  String get invalidAccountNumber;

  /// No description provided for @invalidIfscCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid IFSC code'**
  String get invalidIfscCode;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today:'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(Object hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(Object count);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(Object count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String monthsAgo(Object months);

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{years} years ago'**
  String yearsAgo(Object years);

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}'**
  String currency(Object amount);

  /// No description provided for @currencyWithSymbol.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}'**
  String currencyWithSymbol(Object amount);

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @goToMap.
  ///
  /// In en, this message translates to:
  /// **'Go to Map'**
  String get goToMap;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @allItemsCollectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All items collected successfully!'**
  String get allItemsCollectedSuccessfully;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @orderCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'You have completed this order successfully!'**
  String get orderCompletedSuccessfully;

  /// No description provided for @storePickupFee.
  ///
  /// In en, this message translates to:
  /// **'Store Pickup Fee'**
  String get storePickupFee;

  /// No description provided for @orderIncentive.
  ///
  /// In en, this message translates to:
  /// **'Order Incentive'**
  String get orderIncentive;

  /// No description provided for @itemDeliveredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item delivered successfully'**
  String get itemDeliveredSuccessfully;

  /// No description provided for @itemCollectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item collected successfully'**
  String get itemCollectedSuccessfully;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All Done'**
  String get allDone;

  /// No description provided for @totalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total Distance'**
  String get totalDistance;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// No description provided for @verificationApproved.
  ///
  /// In en, this message translates to:
  /// **'Verification Approved'**
  String get verificationApproved;

  /// No description provided for @verificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get verificationRejected;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get documentType;

  /// No description provided for @selectDocument.
  ///
  /// In en, this message translates to:
  /// **'Select Document'**
  String get selectDocument;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document Uploaded Successfully'**
  String get documentUploaded;

  /// No description provided for @documentUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Document Upload Failed'**
  String get documentUploadFailed;

  /// No description provided for @pleaseSelectDocument.
  ///
  /// In en, this message translates to:
  /// **'Please select a document'**
  String get pleaseSelectDocument;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go Offline'**
  String get goOffline;

  /// No description provided for @deliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Delivery Partner'**
  String get deliveryPartner;

  /// No description provided for @updatePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your personal details'**
  String get updatePersonalDetails;

  /// No description provided for @updatePhoneAndEmail.
  ///
  /// In en, this message translates to:
  /// **'Update phone and email'**
  String get updatePhoneAndEmail;

  /// No description provided for @updateVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Update vehicle details'**
  String get updateVehicleDetails;

  /// No description provided for @manageDeliveryAreas.
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery areas'**
  String get manageDeliveryAreas;

  /// No description provided for @checkVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Check your verification status'**
  String get checkVerificationStatus;

  /// No description provided for @uploadAndManageDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload and manage documents'**
  String get uploadAndManageDocuments;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @driverLicenseRequired.
  ///
  /// In en, this message translates to:
  /// **'Driver license number is required'**
  String get driverLicenseRequired;

  /// No description provided for @vehicleTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type is required'**
  String get vehicleTypeRequired;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @mobileNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileNumberRequired;

  /// No description provided for @mobileNumberMinLength.
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be at least 10 digits'**
  String get mobileNumberMinLength;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validEmailRequired;

  /// No description provided for @countryRequired.
  ///
  /// In en, this message translates to:
  /// **'Country is required'**
  String get countryRequired;

  /// No description provided for @phoneAndEmail.
  ///
  /// In en, this message translates to:
  /// **'Phone & Email'**
  String get phoneAndEmail;

  /// No description provided for @locationInformation.
  ///
  /// In en, this message translates to:
  /// **'Location Information'**
  String get locationInformation;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @profilePicturePreview.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture Preview'**
  String get profilePicturePreview;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File: {fileName}'**
  String file(Object fileName);

  /// No description provided for @useImageAsProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Do you want to use this image as your profile picture?'**
  String get useImageAsProfilePicture;

  /// No description provided for @useThisImage.
  ///
  /// In en, this message translates to:
  /// **'Use This Image'**
  String get useThisImage;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(Object error);

  /// No description provided for @uploadingProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Uploading profile picture...'**
  String get uploadingProfilePicture;

  /// No description provided for @profilePictureUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile picture uploaded successfully!'**
  String get profilePictureUploadedSuccessfully;

  /// No description provided for @failedToUploadProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile picture: {error}'**
  String failedToUploadProfilePicture(Object error);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @editInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit Information'**
  String get editInformation;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Profile'**
  String get errorLoadingProfile;

  /// No description provided for @contactInformationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Contact information updated successfully!'**
  String get contactInformationUpdated;

  /// No description provided for @removeDocument.
  ///
  /// In en, this message translates to:
  /// **'Remove Document'**
  String get removeDocument;

  /// No description provided for @removeDocumentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this {documentTitle}? This action cannot be undone.'**
  String removeDocumentConfirmation(Object documentTitle);

  /// No description provided for @fileSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'File size must be less than 10MB'**
  String get fileSizeLimit;

  /// No description provided for @documentUrlNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Document URL is not available'**
  String get documentUrlNotAvailable;

  /// No description provided for @zoneInformation.
  ///
  /// In en, this message translates to:
  /// **'Zone Information'**
  String get zoneInformation;

  /// No description provided for @zoneName.
  ///
  /// In en, this message translates to:
  /// **'Zone Name'**
  String get zoneName;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @driverLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver License'**
  String get driverLicense;

  /// No description provided for @driverLicenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of your driver license'**
  String get driverLicenseDescription;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @notUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not Uploaded'**
  String get notUploaded;

  /// No description provided for @replaceDocument.
  ///
  /// In en, this message translates to:
  /// **'Replace Document'**
  String get replaceDocument;

  /// No description provided for @viewDocument.
  ///
  /// In en, this message translates to:
  /// **'View Document'**
  String get viewDocument;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @manageProfileInformation.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile information'**
  String get manageProfileInformation;

  /// No description provided for @manageNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotificationPreferences;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @supportAndHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get supportAndHelp;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @getHelpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get getHelpAndSupport;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @reachOutToOurTeam.
  ///
  /// In en, this message translates to:
  /// **'Reach out to our team'**
  String get reachOutToOurTeam;

  /// No description provided for @readTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Read our terms and conditions'**
  String get readTermsAndConditions;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicy;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @signOutOfAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfAccount;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {languageName}'**
  String languageChangedTo(Object languageName);

  /// No description provided for @zoneSlug.
  ///
  /// In en, this message translates to:
  /// **'Zone Slug'**
  String get zoneSlug;

  /// No description provided for @radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// No description provided for @deliveryCharges.
  ///
  /// In en, this message translates to:
  /// **'Delivery Charges'**
  String get deliveryCharges;

  /// No description provided for @regularDeliveryCharges.
  ///
  /// In en, this message translates to:
  /// **'Regular Delivery Charges'**
  String get regularDeliveryCharges;

  /// No description provided for @rushDeliveryCharges.
  ///
  /// In en, this message translates to:
  /// **'Rush Delivery Charges'**
  String get rushDeliveryCharges;

  /// No description provided for @freeDeliveryAmount.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery Amount'**
  String get freeDeliveryAmount;

  /// No description provided for @deliveryTimes.
  ///
  /// In en, this message translates to:
  /// **'Delivery Times'**
  String get deliveryTimes;

  /// No description provided for @regularDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Regular Delivery Time'**
  String get regularDeliveryTime;

  /// No description provided for @rushDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Rush Delivery Time'**
  String get rushDeliveryTime;

  /// No description provided for @verificationComplete.
  ///
  /// In en, this message translates to:
  /// **'Verification Complete'**
  String get verificationComplete;

  /// No description provided for @accountVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully verified'**
  String get accountVerifiedSuccessfully;

  /// No description provided for @verificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Verification Details'**
  String get verificationDetails;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @verificationProcess.
  ///
  /// In en, this message translates to:
  /// **'Verification Process'**
  String get verificationProcess;

  /// No description provided for @documentManagement.
  ///
  /// In en, this message translates to:
  /// **'Document Management'**
  String get documentManagement;

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} Documents'**
  String documentsCount(Object count, Object total);

  /// No description provided for @vehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration'**
  String get vehicleRegistration;

  /// No description provided for @vehicleRegistrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of your vehicle registration'**
  String get vehicleRegistrationDescription;

  /// No description provided for @documentGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Document Guidelines'**
  String get documentGuidelines;

  /// No description provided for @photoQuality.
  ///
  /// In en, this message translates to:
  /// **'Photo Quality'**
  String get photoQuality;

  /// No description provided for @photoQualityDescription.
  ///
  /// In en, this message translates to:
  /// **'Ensure photos are clear and well-lit'**
  String get photoQualityDescription;

  /// No description provided for @readableText.
  ///
  /// In en, this message translates to:
  /// **'Readable Text'**
  String get readableText;

  /// No description provided for @readableTextDescription.
  ///
  /// In en, this message translates to:
  /// **'All text should be clearly visible'**
  String get readableTextDescription;

  /// No description provided for @yourEarnings.
  ///
  /// In en, this message translates to:
  /// **'Your Earnings'**
  String get yourEarnings;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @handlingCharges.
  ///
  /// In en, this message translates to:
  /// **'Handling Charges'**
  String get handlingCharges;

  /// No description provided for @perStoreDropOffFee.
  ///
  /// In en, this message translates to:
  /// **'Per Store Drop-off Fee'**
  String get perStoreDropOffFee;

  /// No description provided for @bufferTime.
  ///
  /// In en, this message translates to:
  /// **'Buffer Time'**
  String get bufferTime;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @zoneStatus.
  ///
  /// In en, this message translates to:
  /// **'Zone Status'**
  String get zoneStatus;

  /// No description provided for @verificationRemarks.
  ///
  /// In en, this message translates to:
  /// **'Verification Remarks'**
  String get verificationRemarks;

  /// No description provided for @verificationSteps.
  ///
  /// In en, this message translates to:
  /// **'Verification Steps'**
  String get verificationSteps;

  /// No description provided for @documentReview.
  ///
  /// In en, this message translates to:
  /// **'Document Review'**
  String get documentReview;

  /// No description provided for @documentReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Our team will review your submitted documents'**
  String get documentReviewDescription;

  /// No description provided for @verificationCompleteStep.
  ///
  /// In en, this message translates to:
  /// **'Verification Complete'**
  String get verificationCompleteStep;

  /// No description provided for @verificationCompleteStepDescription.
  ///
  /// In en, this message translates to:
  /// **'Your account will be verified and activated'**
  String get verificationCompleteStepDescription;

  /// No description provided for @nextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next Steps'**
  String get nextSteps;

  /// No description provided for @verificationRemark.
  ///
  /// In en, this message translates to:
  /// **'Verification Remark'**
  String get verificationRemark;

  /// No description provided for @fileFormat.
  ///
  /// In en, this message translates to:
  /// **'File Format'**
  String get fileFormat;

  /// No description provided for @fileFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'Use JPG, PNG, or PDF format'**
  String get fileFormatDescription;

  /// No description provided for @securityDescription.
  ///
  /// In en, this message translates to:
  /// **'Your documents are securely stored'**
  String get securityDescription;

  /// No description provided for @uploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Upload Progress'**
  String get uploadProgress;

  /// No description provided for @allDocumentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'All Documents Uploaded'**
  String get allDocumentsUploaded;

  /// No description provided for @allDocumentsUploadedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your profile is complete and ready for verification'**
  String get allDocumentsUploadedDescription;

  /// No description provided for @documentInformation.
  ///
  /// In en, this message translates to:
  /// **'Document Information'**
  String get documentInformation;

  /// No description provided for @documentUrl.
  ///
  /// In en, this message translates to:
  /// **'Document URL'**
  String get documentUrl;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @openInBrowserDescription.
  ///
  /// In en, this message translates to:
  /// **'View document in external browser'**
  String get openInBrowserDescription;

  /// No description provided for @downloadDocument.
  ///
  /// In en, this message translates to:
  /// **'Download Document'**
  String get downloadDocument;

  /// No description provided for @downloadDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'Save document to your device'**
  String get downloadDocumentDescription;

  /// No description provided for @shareDocument.
  ///
  /// In en, this message translates to:
  /// **'Share Document'**
  String get shareDocument;

  /// No description provided for @shareDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'Share document with others'**
  String get shareDocumentDescription;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get available;

  /// No description provided for @tapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get tapToCopy;

  /// No description provided for @copyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get copyUrl;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocument;

  /// No description provided for @jpegImage.
  ///
  /// In en, this message translates to:
  /// **'JPEG Image'**
  String get jpegImage;

  /// No description provided for @pngImage.
  ///
  /// In en, this message translates to:
  /// **'PNG Image'**
  String get pngImage;

  /// No description provided for @wordDocument.
  ///
  /// In en, this message translates to:
  /// **'Word Document'**
  String get wordDocument;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'document'**
  String document(Object index);

  /// No description provided for @openingInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opening {documentTitle} in browser...'**
  String openingInBrowser(Object documentTitle);

  /// No description provided for @downloadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Downloading {documentTitle}...'**
  String downloadingDocument(Object documentTitle);

  /// No description provided for @sharingDocument.
  ///
  /// In en, this message translates to:
  /// **'Sharing {documentTitle}...'**
  String sharingDocument(Object documentTitle);

  /// No description provided for @urlCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'URL copied to clipboard'**
  String get urlCopiedToClipboard;

  /// No description provided for @failedToLoadDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Document'**
  String get failedToLoadDocument;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @earningsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Earnings Analytics'**
  String get earningsAnalytics;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @ordersDelivered.
  ///
  /// In en, this message translates to:
  /// **'Orders Delivered'**
  String get ordersDelivered;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @checkPastDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Check past deliveries'**
  String get checkPastDeliveries;

  /// No description provided for @cannotGoOfflineWithPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'You cannot go offline with pending orders'**
  String get cannotGoOfflineWithPendingOrders;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @cashCollection.
  ///
  /// In en, this message translates to:
  /// **'Cash Collection'**
  String get cashCollection;

  /// No description provided for @allCashCollection.
  ///
  /// In en, this message translates to:
  /// **'All Cash Collection'**
  String get allCashCollection;

  /// No description provided for @filterCashCollections.
  ///
  /// In en, this message translates to:
  /// **'Filter Cash Collections'**
  String get filterCashCollections;

  /// No description provided for @submissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Submission Status'**
  String get submissionStatus;

  /// No description provided for @dateRangeLast.
  ///
  /// In en, this message translates to:
  /// **'Date Range (Last)'**
  String get dateRangeLast;

  /// No description provided for @cashSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Cash Submitted'**
  String get cashSubmitted;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining Amount'**
  String get remainingAmount;

  /// No description provided for @noCashCollectionYet.
  ///
  /// In en, this message translates to:
  /// **'No cash collection yet'**
  String get noCashCollectionYet;

  /// No description provided for @completeDeliveriesToSeeYourCashCollection.
  ///
  /// In en, this message translates to:
  /// **'Complete deliveries to see your cash collection'**
  String get completeDeliveriesToSeeYourCashCollection;

  /// No description provided for @completeDeliveriesToSeeCashCollection.
  ///
  /// In en, this message translates to:
  /// **'Complete deliveries to see your cash collection'**
  String get completeDeliveriesToSeeCashCollection;

  /// No description provided for @errorLoadingCashCollection.
  ///
  /// In en, this message translates to:
  /// **'Error loading cash collection'**
  String get errorLoadingCashCollection;

  /// No description provided for @partiallySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Partially Submitted'**
  String get partiallySubmitted;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @last30Minutes.
  ///
  /// In en, this message translates to:
  /// **'30 Min'**
  String get last30Minutes;

  /// No description provided for @last1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get last1Hour;

  /// No description provided for @last5Hours.
  ///
  /// In en, this message translates to:
  /// **'5 Hours'**
  String get last5Hours;

  /// No description provided for @last1Day.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get last1Day;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get last30Days;

  /// No description provided for @last365Days.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get last365Days;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @pleaseEnterOtpFromCustomerForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP from customer for delivery:'**
  String get pleaseEnterOtpFromCustomerForDelivery;

  /// No description provided for @pleaseEnterOtpForThisItem.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP for this item:'**
  String get pleaseEnterOtpForThisItem;

  /// No description provided for @unknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get unknownItem;

  /// No description provided for @earningsSummary.
  ///
  /// In en, this message translates to:
  /// **'Earnings Summary'**
  String get earningsSummary;

  /// No description provided for @averageEarnings.
  ///
  /// In en, this message translates to:
  /// **'Average Earnings'**
  String get averageEarnings;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'deliveries'**
  String get deliveries;

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @gigs.
  ///
  /// In en, this message translates to:
  /// **'Gigs'**
  String get gigs;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data available for {period}'**
  String noDataForPeriod(Object period);

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @itemId.
  ///
  /// In en, this message translates to:
  /// **'Item ID'**
  String get itemId;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @locationIssue.
  ///
  /// In en, this message translates to:
  /// **'Location Issue'**
  String get locationIssue;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get noteOptional;

  /// No description provided for @addNoteForWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Add a note for your withdrawal request...'**
  String get addNoteForWithdrawal;

  /// No description provided for @toResolveThisIssue.
  ///
  /// In en, this message translates to:
  /// **'To resolve this issue:'**
  String get toResolveThisIssue;

  /// No description provided for @moveToCoveredDeliveryArea.
  ///
  /// In en, this message translates to:
  /// **'• Move to a covered delivery area'**
  String get moveToCoveredDeliveryArea;

  /// No description provided for @checkDeliveryZoneInProfile.
  ///
  /// In en, this message translates to:
  /// **'• Check your delivery zone in Profile > Delivery Zones'**
  String get checkDeliveryZoneInProfile;

  /// No description provided for @ensureGpsEnabledAccurate.
  ///
  /// In en, this message translates to:
  /// **'• Ensure GPS is enabled and accurate'**
  String get ensureGpsEnabledAccurate;

  /// No description provided for @viewDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'View Delivery Zone'**
  String get viewDeliveryZone;

  /// No description provided for @confirmArrival.
  ///
  /// In en, this message translates to:
  /// **'Confirm Arrival'**
  String get confirmArrival;

  /// No description provided for @arrivalConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Arrival Confirmed'**
  String get arrivalConfirmed;

  /// No description provided for @continueToDelivery.
  ///
  /// In en, this message translates to:
  /// **'Continue to Delivery'**
  String get continueToDelivery;

  /// No description provided for @arrivalNextStepHint.
  ///
  /// In en, this message translates to:
  /// **'Next: verify items and complete the delivery'**
  String get arrivalNextStepHint;

  /// No description provided for @routeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String routeMinutes(int count);

  /// No description provided for @fastestRoute.
  ///
  /// In en, this message translates to:
  /// **'Fastest route'**
  String get fastestRoute;

  /// No description provided for @routeMinutesSlower.
  ///
  /// In en, this message translates to:
  /// **'{count} min slower'**
  String routeMinutesSlower(int count);

  /// No description provided for @tapRouteToSwitch.
  ///
  /// In en, this message translates to:
  /// **'Tap a route on the map to switch'**
  String get tapRouteToSwitch;

  /// No description provided for @haveYouReachedAddress.
  ///
  /// In en, this message translates to:
  /// **'Have you reached the delivery address?'**
  String get haveYouReachedAddress;

  /// No description provided for @yesImHere.
  ///
  /// In en, this message translates to:
  /// **'Yes, I\'m Here'**
  String get yesImHere;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @pleaseEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP'**
  String get pleaseEnterOtp;

  /// No description provided for @otpMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'OTP must be 6 digits'**
  String get otpMustBe6Digits;

  /// No description provided for @otpVerifiedSuccessfullyDeliveryCompleted.
  ///
  /// In en, this message translates to:
  /// **'OTP verified successfully! Delivery completed.'**
  String get otpVerifiedSuccessfullyDeliveryCompleted;

  /// No description provided for @pickupRoute.
  ///
  /// In en, this message translates to:
  /// **'Pickup Route'**
  String get pickupRoute;

  /// No description provided for @storePickupRoute.
  ///
  /// In en, this message translates to:
  /// **'Store Pickup Route'**
  String get storePickupRoute;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @deliveryRoute.
  ///
  /// In en, this message translates to:
  /// **'Delivery Route'**
  String get deliveryRoute;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @loadingMap.
  ///
  /// In en, this message translates to:
  /// **'Loading map...'**
  String get loadingMap;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @youAreCurrentlyOffline.
  ///
  /// In en, this message translates to:
  /// **'You are currently offline'**
  String get youAreCurrentlyOffline;

  /// No description provided for @goOnlineToStartReceivingOrders.
  ///
  /// In en, this message translates to:
  /// **'Go online to start receiving delivery orders'**
  String get goOnlineToStartReceivingOrders;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnline;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;

  /// No description provided for @documentUploadDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload your driver license and vehicle registration documents'**
  String get documentUploadDescription;

  /// No description provided for @withdrawalRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Request'**
  String get withdrawalRequest;

  /// No description provided for @adminRemark.
  ///
  /// In en, this message translates to:
  /// **'Admin Remark'**
  String get adminRemark;

  /// No description provided for @requestId.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestId;

  /// No description provided for @requestNote.
  ///
  /// In en, this message translates to:
  /// **'Request Note'**
  String get requestNote;

  /// No description provided for @processedAt.
  ///
  /// In en, this message translates to:
  /// **'Processed At'**
  String get processedAt;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedAt;

  /// No description provided for @rushDelivery.
  ///
  /// In en, this message translates to:
  /// **'Rush Delivery'**
  String get rushDelivery;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Orders'**
  String get errorLoadingOrders;

  /// No description provided for @noImagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailable;

  /// No description provided for @loadingWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Loading your withdrawals...'**
  String get loadingWithdrawals;

  /// No description provided for @withdrawEarningsToBank.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your earnings to your bank account'**
  String get withdrawEarningsToBank;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @noWithdrawalsYet.
  ///
  /// In en, this message translates to:
  /// **'No Withdrawals Yet'**
  String get noWithdrawalsYet;

  /// No description provided for @noWithdrawalsYetDescription.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made any withdrawal requests yet.\nTap the button below to request your first withdrawal.'**
  String get noWithdrawalsYetDescription;

  /// No description provided for @gigsDescription.
  ///
  /// In en, this message translates to:
  /// **'Find and manage your gig opportunities'**
  String get gigsDescription;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @selectPreferredAppearance.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred app appearance'**
  String get selectPreferredAppearance;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @cleanBrightInterface.
  ///
  /// In en, this message translates to:
  /// **'Clean and bright interface'**
  String get cleanBrightInterface;

  /// No description provided for @easyOnEyesLowLight.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes in low light'**
  String get easyOnEyesLowLight;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @hyperLocal.
  ///
  /// In en, this message translates to:
  /// **'NagpurMart-Rider'**
  String get hyperLocal;

  /// No description provided for @collectItemsStores.
  ///
  /// In en, this message translates to:
  /// **'Collect items from stores'**
  String get collectItemsStores;

  /// No description provided for @searchOrders.
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get searchOrders;

  /// No description provided for @noDeliveredOrders.
  ///
  /// In en, this message translates to:
  /// **'No Completed Orders'**
  String get noDeliveredOrders;

  /// No description provided for @noDeliveredOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t completed any orders yet'**
  String get noDeliveredOrdersYet;

  /// No description provided for @deliveredOn.
  ///
  /// In en, this message translates to:
  /// **'Completed On'**
  String get deliveredOn;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @overallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @basedOnReviews.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} reviews'**
  String basedOnReviews(Object count);

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @beFirstToLeaveReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to leave a review!'**
  String get beFirstToLeaveReview;

  /// No description provided for @noRatingsDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No ratings data available'**
  String get noRatingsDataAvailable;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(Object message);

  /// No description provided for @mostHelpful.
  ///
  /// In en, this message translates to:
  /// **'Most Helpful'**
  String get mostHelpful;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See Less'**
  String get seeLess;

  /// No description provided for @star5.
  ///
  /// In en, this message translates to:
  /// **'5★'**
  String get star5;

  /// No description provided for @star4.
  ///
  /// In en, this message translates to:
  /// **'4★'**
  String get star4;

  /// No description provided for @star3.
  ///
  /// In en, this message translates to:
  /// **'3★'**
  String get star3;

  /// No description provided for @star2.
  ///
  /// In en, this message translates to:
  /// **'2★'**
  String get star2;

  /// No description provided for @star1.
  ///
  /// In en, this message translates to:
  /// **'1★'**
  String get star1;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get checkInternetConnection;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @exitAppConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the app?'**
  String get exitAppConfirmation;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @activateStatusToSeeOrders.
  ///
  /// In en, this message translates to:
  /// **'Please activate your status to see your orders'**
  String get activateStatusToSeeOrders;

  /// No description provided for @activateStatusToSeeAvailableOrders.
  ///
  /// In en, this message translates to:
  /// **'Please activate your status to see available orders'**
  String get activateStatusToSeeAvailableOrders;

  /// No description provided for @tapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToView;

  /// No description provided for @feeds.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get feeds;

  /// No description provided for @noChartDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No chart data available'**
  String get noChartDataAvailable;

  /// No description provided for @errorLoadingChartData.
  ///
  /// In en, this message translates to:
  /// **'Error loading chart data'**
  String get errorLoadingChartData;

  /// No description provided for @noDataAvailableForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data available for {period}'**
  String noDataAvailableForPeriod(Object period);

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @uploadDocumentsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please upload your driver license and vehicle registration documents to complete the verification process.'**
  String get uploadDocumentsMessage;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// No description provided for @verificationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification was rejected. Please review the remarks above and resubmit your documents.'**
  String get verificationRejectedMessage;

  /// No description provided for @verificationPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification is currently under review'**
  String get verificationPendingMessage;

  /// No description provided for @verificationRejectedMessageShort.
  ///
  /// In en, this message translates to:
  /// **'Your verification was not approved'**
  String get verificationRejectedMessageShort;

  /// No description provided for @verificationCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully verified'**
  String get verificationCompleteMessage;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown Status'**
  String get unknownStatus;

  /// No description provided for @verificationStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Verification status is unknown'**
  String get verificationStatusUnknown;

  /// No description provided for @noProfileFound.
  ///
  /// In en, this message translates to:
  /// **'No Profile Found'**
  String get noProfileFound;

  /// No description provided for @unableToLoadVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Unable to load verification status. Please try again.'**
  String get unableToLoadVerificationStatus;

  /// No description provided for @noDriverLicenseDocuments.
  ///
  /// In en, this message translates to:
  /// **'No driver license documents found'**
  String get noDriverLicenseDocuments;

  /// No description provided for @driverLicenseDocuments.
  ///
  /// In en, this message translates to:
  /// **'Driver License Documents'**
  String get driverLicenseDocuments;

  /// No description provided for @documentsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} document{count, plural, =1 {} other {s}}'**
  String documentsFound(num count);

  /// No description provided for @driverLicenseDocument.
  ///
  /// In en, this message translates to:
  /// **'Driver License {index}'**
  String driverLicenseDocument(Object index);

  /// No description provided for @noVehicleRegistrationDocuments.
  ///
  /// In en, this message translates to:
  /// **'No vehicle registration documents found'**
  String get noVehicleRegistrationDocuments;

  /// No description provided for @vehicleRegistrationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration Documents'**
  String get vehicleRegistrationDocuments;

  /// No description provided for @vehicleRegistrationDocument.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration {index}'**
  String vehicleRegistrationDocument(Object index);

  /// No description provided for @viewDocuments.
  ///
  /// In en, this message translates to:
  /// **'View Documents'**
  String get viewDocuments;

  /// No description provided for @accountInactive.
  ///
  /// In en, this message translates to:
  /// **'Account Inactive'**
  String get accountInactive;

  /// No description provided for @activateAccountToViewOrders.
  ///
  /// In en, this message translates to:
  /// **'You need to activate your account to view and accept available orders'**
  String get activateAccountToViewOrders;

  /// No description provided for @activateAccount.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activateAccount;

  /// No description provided for @tapPowerButtonToGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Tap the power button in the header to go online'**
  String get tapPowerButtonToGoOnline;

  /// No description provided for @googleMapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps. Please install Google Maps app or try again.'**
  String get googleMapsError;

  /// No description provided for @documentLbl.
  ///
  /// In en, this message translates to:
  /// **'document'**
  String get documentLbl;

  /// No description provided for @pickupOrders.
  ///
  /// In en, this message translates to:
  /// **'Pickup Orders'**
  String get pickupOrders;

  /// No description provided for @availPickupOrders.
  ///
  /// In en, this message translates to:
  /// **'Available Pickup Orders'**
  String get availPickupOrders;

  /// No description provided for @noReturnOrdersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Pickup Orders Available'**
  String get noReturnOrdersAvailable;

  /// No description provided for @activateAccountToViewPickupOrders.
  ///
  /// In en, this message translates to:
  /// **'You need to activate your account to view and accept pickup orders'**
  String get activateAccountToViewPickupOrders;

  /// No description provided for @noPickupOrders.
  ///
  /// In en, this message translates to:
  /// **'No Pickup Orders'**
  String get noPickupOrders;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @deliveredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Delivered Successfully'**
  String get deliveredSuccessfully;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @deliveredToSeller.
  ///
  /// In en, this message translates to:
  /// **'Delivered to Seller'**
  String get deliveredToSeller;

  /// No description provided for @returnDetails.
  ///
  /// In en, this message translates to:
  /// **'Return Details'**
  String get returnDetails;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @refundAmt.
  ///
  /// In en, this message translates to:
  /// **'Refund Amount'**
  String get refundAmt;

  /// No description provided for @pickupDetails.
  ///
  /// In en, this message translates to:
  /// **'Pickup Details'**
  String get pickupDetails;

  /// No description provided for @goToCustomerLocation.
  ///
  /// In en, this message translates to:
  /// **'Go to Customer Location'**
  String get goToCustomerLocation;

  /// No description provided for @goToSellerLocation.
  ///
  /// In en, this message translates to:
  /// **'Go to Seller Location'**
  String get goToSellerLocation;

  /// No description provided for @noDetailsFound.
  ///
  /// In en, this message translates to:
  /// **'No details found'**
  String get noDetailsFound;

  /// No description provided for @baseFees.
  ///
  /// In en, this message translates to:
  /// **'Base Fee'**
  String get baseFees;

  /// No description provided for @pickupFees.
  ///
  /// In en, this message translates to:
  /// **'Pickup Fee'**
  String get pickupFees;

  /// No description provided for @distanceFees.
  ///
  /// In en, this message translates to:
  /// **'Distance Fee'**
  String get distanceFees;

  /// No description provided for @sellerComment.
  ///
  /// In en, this message translates to:
  /// **'Seller Comment'**
  String get sellerComment;

  /// No description provided for @allEarnings.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allEarnings;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @periodEarnings.
  ///
  /// In en, this message translates to:
  /// **'Period Earnings'**
  String get periodEarnings;

  /// No description provided for @earningsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Earnings Breakdown'**
  String get earningsBreakdown;

  /// No description provided for @orderEarnings.
  ///
  /// In en, this message translates to:
  /// **'Order Earnings'**
  String get orderEarnings;

  /// No description provided for @baseAndDistanceFees.
  ///
  /// In en, this message translates to:
  /// **'Base & Distance Fees'**
  String get baseAndDistanceFees;

  /// No description provided for @perStoreCharges.
  ///
  /// In en, this message translates to:
  /// **'Per Store Charges'**
  String get perStoreCharges;

  /// No description provided for @incentives.
  ///
  /// In en, this message translates to:
  /// **'Incentives'**
  String get incentives;

  /// No description provided for @bonusAndRewards.
  ///
  /// In en, this message translates to:
  /// **'Bonus & Rewards'**
  String get bonusAndRewards;

  /// No description provided for @dailyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Daily Breakdown'**
  String get dailyBreakdown;

  /// No description provided for @avgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg/Day'**
  String get avgPerDay;

  /// No description provided for @bestDay.
  ///
  /// In en, this message translates to:
  /// **'Best Day'**
  String get bestDay;

  /// No description provided for @daysActive.
  ///
  /// In en, this message translates to:
  /// **'Days Active'**
  String get daysActive;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @weekN.
  ///
  /// In en, this message translates to:
  /// **'Week {weekNumber}'**
  String weekN(Object weekNumber);

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get feed;

  /// No description provided for @chooseYourPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseYourPreferredLanguage;

  /// No description provided for @noAssignedOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No assigned orders yet'**
  String get noAssignedOrdersYet;

  /// No description provided for @noInProgressOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders in progress'**
  String get noInProgressOrders;

  /// No description provided for @noCompletedOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t completed any orders yet'**
  String get noCompletedOrdersYet;

  /// No description provided for @noCanceledOrders.
  ///
  /// In en, this message translates to:
  /// **'No canceled orders'**
  String get noCanceledOrders;

  /// No description provided for @deliveryZonesNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Delivery zones have not been configured yet.'**
  String get deliveryZonesNotConfigured;

  /// No description provided for @noDeliveryZonesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No delivery zones available'**
  String get noDeliveryZonesAvailable;

  /// No description provided for @unableToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get unableToLoadData;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No Data Yet'**
  String get noDataYet;

  /// No description provided for @checkConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again'**
  String get checkConnectionAndTryAgain;

  /// No description provided for @dataWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your information will appear here soon'**
  String get dataWillAppearHere;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @selectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Type'**
  String get selectVehicleType;

  /// No description provided for @pleaseSelectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Please select vehicle type'**
  String get pleaseSelectVehicleType;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location Service Disabled'**
  String get locationServiceDisabled;

  /// No description provided for @locationServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'GPS is required to track your delivery progress. Please enable location services to continue.'**
  String get locationServiceDescription;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'This app needs location permission to track your delivery in real-time.'**
  String get locationPermissionDescription;

  /// No description provided for @locationPermissionPermanentDescription.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please enable it from app settings to continue.'**
  String get locationPermissionPermanentDescription;

  /// No description provided for @todayEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today Earnings'**
  String get todayEarnings;

  /// No description provided for @codPayment.
  ///
  /// In en, this message translates to:
  /// **'COD Payment'**
  String get codPayment;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @myOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'My Order Details'**
  String get myOrderDetails;

  /// No description provided for @deliveredOrders.
  ///
  /// In en, this message translates to:
  /// **'Delivered Orders'**
  String get deliveredOrders;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Product Price'**
  String get productPrice;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String distanceKm(String distance);

  /// No description provided for @here.
  ///
  /// In en, this message translates to:
  /// **'Here'**
  String get here;

  /// No description provided for @declineOrder.
  ///
  /// In en, this message translates to:
  /// **'Decline Order'**
  String get declineOrder;

  /// No description provided for @orderNo.
  ///
  /// In en, this message translates to:
  /// **'Order no.'**
  String get orderNo;

  /// No description provided for @orderDeliveredLabel.
  ///
  /// In en, this message translates to:
  /// **'ORDER DELIVERED'**
  String get orderDeliveredLabel;

  /// No description provided for @orderCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'ORDER CANCEL'**
  String get orderCancelLabel;

  /// No description provided for @paymentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment mode:'**
  String get paymentModeLabel;

  /// No description provided for @deliveredTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivered Time - {time}'**
  String deliveredTimeLabel(String time);

  /// No description provided for @rateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Rate Customer'**
  String get rateCustomer;

  /// No description provided for @cancelByLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel by:'**
  String get cancelByLabel;

  /// No description provided for @whyLabel.
  ///
  /// In en, this message translates to:
  /// **'Why?:'**
  String get whyLabel;

  /// No description provided for @minsShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins'**
  String minsShort(String minutes);

  /// No description provided for @orderDeclinedHidden.
  ///
  /// In en, this message translates to:
  /// **'Order removed from your list'**
  String get orderDeclinedHidden;

  /// No description provided for @supportNumberUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Support number not available'**
  String get supportNumberUnavailable;

  /// No description provided for @rateCustomerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Customer rating will be available soon'**
  String get rateCustomerComingSoon;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startNavigation;

  /// No description provided for @routeSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get routeSteps;

  /// No description provided for @exitNavigation.
  ///
  /// In en, this message translates to:
  /// **'Exit navigation'**
  String get exitNavigation;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Re-centre'**
  String get recenter;

  /// No description provided for @thenLabel.
  ///
  /// In en, this message translates to:
  /// **'Then'**
  String get thenLabel;

  /// No description provided for @arriveAtDestination.
  ///
  /// In en, this message translates to:
  /// **'Arrive at destination'**
  String get arriveAtDestination;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @kmPerHour.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get kmPerHour;

  /// No description provided for @waitingForGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS signal'**
  String get waitingForGps;

  /// No description provided for @toDestination.
  ///
  /// In en, this message translates to:
  /// **'To {address}'**
  String toDestination(String address);

  /// No description provided for @youHaveArrived.
  ///
  /// In en, this message translates to:
  /// **'You\'ve arrived'**
  String get youHaveArrived;

  /// No description provided for @muteVoice.
  ///
  /// In en, this message translates to:
  /// **'Mute voice'**
  String get muteVoice;

  /// No description provided for @unmuteVoice.
  ///
  /// In en, this message translates to:
  /// **'Unmute voice'**
  String get unmuteVoice;

  /// No description provided for @routeOverview.
  ///
  /// In en, this message translates to:
  /// **'Route overview'**
  String get routeOverview;

  /// No description provided for @customerPhoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Customer phone number not available'**
  String get customerPhoneUnavailable;

  /// No description provided for @returnPickup.
  ///
  /// In en, this message translates to:
  /// **'Return Pickup'**
  String get returnPickup;

  /// No description provided for @returnStepPickup.
  ///
  /// In en, this message translates to:
  /// **'Step 1 · Pickup from customer'**
  String get returnStepPickup;

  /// No description provided for @returnStepToSeller.
  ///
  /// In en, this message translates to:
  /// **'Step 2 · Return to seller'**
  String get returnStepToSeller;

  /// No description provided for @arrivedAtCustomer.
  ///
  /// In en, this message translates to:
  /// **'Arrived at customer'**
  String get arrivedAtCustomer;

  /// No description provided for @arrivedAtSeller.
  ///
  /// In en, this message translates to:
  /// **'Arrived at seller'**
  String get arrivedAtSeller;

  /// No description provided for @returnItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Return items ({count})'**
  String returnItemsCount(int count);

  /// No description provided for @collectTheseItems.
  ///
  /// In en, this message translates to:
  /// **'Collect these items'**
  String get collectTheseItems;

  /// No description provided for @carryingItems.
  ///
  /// In en, this message translates to:
  /// **'Carrying ({count})'**
  String carryingItems(int count);

  /// No description provided for @handOverTo.
  ///
  /// In en, this message translates to:
  /// **'Hand over to {name}'**
  String handOverTo(String name);

  /// No description provided for @iHaveReachedCustomer.
  ///
  /// In en, this message translates to:
  /// **'I\'ve reached customer'**
  String get iHaveReachedCustomer;

  /// No description provided for @iHaveReachedSeller.
  ///
  /// In en, this message translates to:
  /// **'I\'ve reached seller'**
  String get iHaveReachedSeller;

  /// No description provided for @haveYouReachedCustomer.
  ///
  /// In en, this message translates to:
  /// **'Have you reached the customer? They will be notified that you are here for the return pickup.'**
  String get haveYouReachedCustomer;

  /// No description provided for @haveYouReachedSeller.
  ///
  /// In en, this message translates to:
  /// **'Have you reached the seller\'s store?'**
  String get haveYouReachedSeller;

  /// No description provided for @customerNotifiedRiderHere.
  ///
  /// In en, this message translates to:
  /// **'Customer notified: your rider is here for the return pickup'**
  String get customerNotifiedRiderHere;

  /// No description provided for @notifyingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Notifying customer…'**
  String get notifyingCustomer;

  /// No description provided for @customerNotifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t notify the customer. Please call them.'**
  String get customerNotifyFailed;

  /// No description provided for @notifyAgain.
  ///
  /// In en, this message translates to:
  /// **'Notify again'**
  String get notifyAgain;

  /// No description provided for @callCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call customer'**
  String get callCustomer;

  /// No description provided for @swipePackageCollected.
  ///
  /// In en, this message translates to:
  /// **'Swipe: Package collected'**
  String get swipePackageCollected;

  /// No description provided for @swipeDeliveredToSeller.
  ///
  /// In en, this message translates to:
  /// **'Swipe: Delivered to seller'**
  String get swipeDeliveredToSeller;

  /// No description provided for @returnCompleted.
  ///
  /// In en, this message translates to:
  /// **'Return completed'**
  String get returnCompleted;

  /// No description provided for @returnDeliveredSummary.
  ///
  /// In en, this message translates to:
  /// **'Return #{id} delivered to seller'**
  String returnDeliveredSummary(String id);

  /// No description provided for @backToOrders.
  ///
  /// In en, this message translates to:
  /// **'Back to orders'**
  String get backToOrders;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'fr',
    'gu',
    'hi',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
