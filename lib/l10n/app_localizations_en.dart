// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hyper Local Delivery';

  @override
  String get createAccount => 'Create Account';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get pleaseEnterYourFullName => 'Please enter your full name';

  @override
  String get nameMustBeAtLeast2Characters =>
      'Name must be at least 2 characters';

  @override
  String get email => 'Email';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterAValidEmail => 'Please enter a valid email';

  @override
  String get country => 'Country';

  @override
  String get pleaseSelectACountry => 'Please select a country';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterYourPhoneNumber => 'Enter your phone number';

  @override
  String get pleaseEnterYourPhoneNumber => 'Please enter your phone number';

  @override
  String get phoneNumberMustBeAtLeast10Digits =>
      'Phone number must be at least 10 digits';

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get passwordMustBeAtLeast8Characters =>
      'Password must be at least 8 characters';

  @override
  String get passwordMustContainUppercaseLowercaseAndNumber =>
      'Password must contain uppercase, lowercase and number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get pleaseConfirmYourPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get address => 'Address';

  @override
  String get enterYourAddress => 'Enter your address';

  @override
  String get pleaseEnterYourAddress => 'Please enter your address';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get enterYourVehicleType => 'Enter your vehicle type';

  @override
  String get pleaseEnterYourVehicleType => 'Please enter your vehicle type';

  @override
  String get driverLicenseNumber => 'Driver License Number';

  @override
  String get enterYourLicenseNumber => 'Enter your license number';

  @override
  String get pleaseEnterYourLicenseNumber => 'Please enter your license number';

  @override
  String get deliveryZone => 'Delivery Zone';

  @override
  String get selectYourDeliveryZone => 'Select your delivery zone';

  @override
  String get pleaseSelectYourDeliveryZone => 'Please select your delivery zone';

  @override
  String get uploadDriverLicense => 'Upload Driver License';

  @override
  String get uploadVehicleRegistration => 'Upload Vehicle Registration';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get login => 'Login';

  @override
  String get submit => 'Submit';

  @override
  String get dontHaveAccount => 'Don\'t have account?';

  @override
  String get register => 'Register';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get vehicleInformation => 'Vehicle Information';

  @override
  String get security => 'Security';

  @override
  String get documentUpload => 'Document Upload';

  @override
  String get storagePermissionDenied => 'Storage permission denied';

  @override
  String get noFilesSelected => 'No files selected';

  @override
  String get filePickerPluginNotAvailable =>
      'File picker plugin not available. Please rebuild the app.';

  @override
  String errorPickingFile(Object error) {
    return 'Error picking file: $error';
  }

  @override
  String get pleaseEnterAValidPhoneNumber =>
      'Please enter a valid phone number';

  @override
  String get pleaseUploadAtLeastOneDriverLicenseFile =>
      'Please upload at least one driver license file';

  @override
  String get pleaseUploadAtLeastOneVehicleRegistrationFile =>
      'Please upload at least one vehicle registration file';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get retry => 'Retry';

  @override
  String get deliveryZones => 'Delivery Zones';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get enterYourDetailsBelow => 'Enter your details below';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordDescription =>
      'Don\'t worry! Enter your email and we\'ll send you instructions to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get emailSentSuccessfully => 'Email sent successfully';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get home => 'Home';

  @override
  String get orders => 'Orders';

  @override
  String get earnings => 'Earnings';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get availableOrders => 'Available Orders';

  @override
  String get noAvailableOrders => 'No Available Orders';

  @override
  String get ordersWillAppearHere => 'Orders will appear here when available';

  @override
  String ordersCount(Object count) {
    return '$count orders';
  }

  @override
  String get expectedEarning => 'Expected Earning';

  @override
  String get myEarnings => 'My Earnings';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get perPage => 'Per Page';

  @override
  String orderNumber(Object orderId) {
    return 'Order #$orderId';
  }

  @override
  String get pending => 'Pending';

  @override
  String get paid => 'Paid';

  @override
  String get assigned => 'Assigned';

  @override
  String get inProgress => 'In Progress';

  @override
  String get canceled => 'Canceled';

  @override
  String get baseFee => 'Base Fee';

  @override
  String get storePickup => 'Store Pickup';

  @override
  String get distanceFee => 'Distance Fee';

  @override
  String get incentive => 'Incentive';

  @override
  String get total => 'Total';

  @override
  String get date => 'Date:';

  @override
  String get noEarningsYet => 'No earnings yet';

  @override
  String get completeDeliveriesMessage =>
      'Complete some deliveries to see your earnings here';

  @override
  String get errorLoadingEarnings => 'Error loading earnings';

  @override
  String get drop => 'Drop';

  @override
  String get pickupFrom => 'Pickup from';

  @override
  String get store => 'Store';

  @override
  String minsAway(Object minutes) {
    return '$minutes mins away';
  }

  @override
  String get acceptOrder => 'Accept Order';

  @override
  String get accepting => 'Accepting...';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get storePickupCoordinatesNotAvailable =>
      'Store pickup coordinates not available';

  @override
  String get noCoordinatesAvailableForMapView =>
      'No coordinates available for map view';

  @override
  String get routeDetailsNotAvailableForMapView =>
      'Route details not available for map view';

  @override
  String navigationError(Object error) {
    return 'Navigation error: $error';
  }

  @override
  String get myOrders => 'My Orders';

  @override
  String get noOrdersFound => 'No Orders Found';

  @override
  String get noOrdersAcceptedYet => 'You haven\'t accepted any orders yet';

  @override
  String get delivered => 'Delivered';

  @override
  String get outForDelivery => 'Out for Delivery';

  @override
  String get km => 'km';

  @override
  String get items => 'items';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get preparing => 'Preparing';

  @override
  String get ready => 'Ready';

  @override
  String get appSettings => 'App Settings';

  @override
  String get language => 'Language';

  @override
  String get changeAppLanguage => 'Change app language';

  @override
  String get theme => 'Theme';

  @override
  String get changeAppColors => 'Change app theme';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get vehicleInfo => 'Vehicle Information';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get documents => 'documents';

  @override
  String get verificationStatus => 'Verification Status';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phone => 'Phone';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get zipCode => 'Zip Code';

  @override
  String get vehicleNumber => 'Vehicle Number';

  @override
  String get vehicleModel => 'Vehicle Model';

  @override
  String get vehicleColor => 'Vehicle Color';

  @override
  String get licenseNumber => 'License Number';

  @override
  String get insuranceNumber => 'Insurance Number';

  @override
  String get orderStatus => 'Order Status';

  @override
  String get collected => 'Collected';

  @override
  String get orderItems => 'Order Items';

  @override
  String get customerDetails => 'Customer Details';

  @override
  String get shippingDetails => 'Shipping Details';

  @override
  String get storeDetails => 'Store Details';

  @override
  String get paymentInformation => 'Payment Information';

  @override
  String get pricingDetails => 'Pricing Details';

  @override
  String get earningsDetails => 'Earnings Details';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get totalPayable => 'Total Payable';

  @override
  String get finalTotal => 'Final Total';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get onlinePayment => 'Online Payment';

  @override
  String get perStorePickupFee => 'Per Store Pickup Fee';

  @override
  String get distanceBasedFee => 'Distance Based Fee';

  @override
  String get perOrderIncentive => 'Per Order Incentive';

  @override
  String get collectAllItems => 'Collect All Items';

  @override
  String get viewPickupRoute => 'View Pickup Route';

  @override
  String get deliveredAllOrder => 'Delivered all order';

  @override
  String get collectItemsIndividually => 'Collect Items Individually';

  @override
  String get itemCollected => 'Item collected successfully';

  @override
  String get itemDelivered => 'Item delivered successfully';

  @override
  String get allItemsCollected => 'All items collected successfully!';

  @override
  String get noItemsToCollect => 'No items to collect';

  @override
  String errorCollectingItems(Object error) {
    return 'Error collecting items: $error';
  }

  @override
  String get pleaseEnterValidOtp => 'Please enter a valid 6-digit OTP';

  @override
  String get otpRequired => 'OTP Required';

  @override
  String get itemOtpRequired => 'Item OTP Required';

  @override
  String get deliveryOtpRequired => 'Delivery OTP Required';

  @override
  String get customerOtpRequired => 'Customer OTP Required';

  @override
  String get pleaseEnterOtpFromCustomer => 'Please enter OTP from customer:';

  @override
  String get pleaseEnterOtpForItem => 'Please enter OTP for this item:';

  @override
  String get enterDeliveryOtp => 'Enter Delivery OTP';

  @override
  String get enterItemOtp => 'Enter Item OTP';

  @override
  String get enterCustomerOtp => 'Enter Customer OTP';

  @override
  String get verifyAndDeliver => 'Verify & Deliver';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get verifying => 'Verifying...';

  @override
  String get otpVerifiedSuccessfully => 'OTP verified successfully!';

  @override
  String get noOtpRequired => 'No OTP required for this item';

  @override
  String get cashCollected => 'Cash Collected';

  @override
  String get pleaseCollectCash =>
      'Please collect the cash from the customer before proceeding.';

  @override
  String get amount => 'Amount';

  @override
  String get orderCompleted => 'Order Completed!';

  @override
  String get allItemsDeliveredSuccessfully =>
      'All items have been delivered successfully!';

  @override
  String get yourEarningsBreakdown => 'Your Earnings Breakdown';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get done => 'Done';

  @override
  String get ok => 'OK';

  @override
  String get deliver => 'Deliver';

  @override
  String get collect => 'Collect';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get unknown => 'Unknown';

  @override
  String get na => 'N/A';

  @override
  String kmFromCustomer(Object distance) {
    return '$distance km from customer';
  }

  @override
  String collectedItemsCount(Object collected, Object total) {
    return 'Collect All Items ($collected/$total)';
  }

  @override
  String collectItemsIndividuallyCount(Object collected, Object total) {
    return 'Collect Items Individually ($collected/$total)';
  }

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get documentViewer => 'Document Viewer';

  @override
  String get active => 'ACTIVE';

  @override
  String get inactive => 'INACTIVE';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get pockets => 'Earnings';

  @override
  String get balance => 'Balance';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get withdrawalHistory => 'Withdrawal History';

  @override
  String get createWithdrawal => 'Create Withdrawal';

  @override
  String get withdrawalAmount => 'Withdrawal Amount';

  @override
  String get bankDetails => 'Bank Details';

  @override
  String get accountNumber => 'Account Number';

  @override
  String get ifscCode => 'IFSC Code';

  @override
  String get bankName => 'Bank Name';

  @override
  String get accountHolderName => 'Account Holder Name';

  @override
  String get requestWithdrawal => 'Request Withdrawal';

  @override
  String get withdrawalRequested => 'Withdrawal Requested Successfully';

  @override
  String get minimumWithdrawalAmount => 'Minimum withdrawal amount is ₹100';

  @override
  String get insufficientBalance => 'Insufficient balance';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get smsNotifications => 'SMS Notifications';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get support => 'Support';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get rateApp => 'Rate App';

  @override
  String get shareApp => 'Share App';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get refresh => 'Refresh';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get confirm => 'Confirm';

  @override
  String get noData => 'No data available';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get locationPermissionRequired => 'Location permission is required';

  @override
  String get cameraPermissionRequired => 'Camera permission is required';

  @override
  String get storagePermissionRequired => 'Storage permission is required';

  @override
  String get microphonePermissionRequired =>
      'Microphone permission is required';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String permissionExplanation(Object permission) {
    return 'This app needs $permission permission to function properly.';
  }

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get later => 'Later';

  @override
  String get required => 'This field is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get invalidPhone => 'Please enter a valid phone number';

  @override
  String get invalidPassword => 'Password must be at least 6 characters long';

  @override
  String get invalidOtp => 'Please enter a valid OTP';

  @override
  String get invalidAmount => 'Please enter a valid amount';

  @override
  String get invalidAccountNumber => 'Please enter a valid account number';

  @override
  String get invalidIfscCode => 'Please enter a valid IFSC code';

  @override
  String get today => 'Today:';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get lastYear => 'Last Year';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes minutes ago';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String daysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String weeksAgo(Object count) {
    return '$count weeks ago';
  }

  @override
  String monthsAgo(Object months) {
    return '$months months ago';
  }

  @override
  String yearsAgo(Object years) {
    return '$years years ago';
  }

  @override
  String currency(Object amount) {
    return '₹$amount';
  }

  @override
  String currencyWithSymbol(Object amount) {
    return '₹$amount';
  }

  @override
  String get status => 'Status';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get processing => 'Processing';

  @override
  String get shipped => 'Shipped';

  @override
  String get returned => 'Returned';

  @override
  String get refunded => 'Refunded';

  @override
  String get goToMap => 'Go to Map';

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String get allItemsCollectedSuccessfully =>
      'All items collected successfully!';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get orderCompletedSuccessfully =>
      'You have completed this order successfully!';

  @override
  String get storePickupFee => 'Store Pickup Fee';

  @override
  String get orderIncentive => 'Order Incentive';

  @override
  String get itemDeliveredSuccessfully => 'Item delivered successfully';

  @override
  String get itemCollectedSuccessfully => 'Item collected successfully';

  @override
  String get customer => 'Customer';

  @override
  String get name => 'Name';

  @override
  String get allDone => 'All Done';

  @override
  String get totalDistance => 'Total Distance';

  @override
  String get orderId => 'Order ID';

  @override
  String get verificationPending => 'Verification Pending';

  @override
  String get verificationApproved => 'Verification Approved';

  @override
  String get verificationRejected => 'Verification Rejected';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String get documentType => 'Document Type';

  @override
  String get selectDocument => 'Select Document';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get documentUploaded => 'Document Uploaded Successfully';

  @override
  String get documentUploadFailed => 'Document Upload Failed';

  @override
  String get pleaseSelectDocument => 'Please select a document';

  @override
  String get goOffline => 'Go Offline';

  @override
  String get deliveryPartner => 'Delivery Partner';

  @override
  String get updatePersonalDetails => 'Update your personal details';

  @override
  String get updatePhoneAndEmail => 'Update phone and email';

  @override
  String get updateVehicleDetails => 'Update vehicle details';

  @override
  String get manageDeliveryAreas => 'Manage your delivery areas';

  @override
  String get checkVerificationStatus => 'Check your verification status';

  @override
  String get uploadAndManageDocuments => 'Upload and manage documents';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get driverLicenseRequired => 'Driver license number is required';

  @override
  String get vehicleTypeRequired => 'Vehicle type is required';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get mobileNumberRequired => 'Mobile number is required';

  @override
  String get mobileNumberMinLength =>
      'Mobile number must be at least 10 digits';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get validEmailRequired => 'Please enter a valid email address';

  @override
  String get countryRequired => 'Country is required';

  @override
  String get phoneAndEmail => 'Phone & Email';

  @override
  String get locationInformation => 'Location Information';

  @override
  String get personalDetails => 'Personal Details';

  @override
  String get profilePicturePreview => 'Profile Picture Preview';

  @override
  String file(Object fileName) {
    return 'File: $fileName';
  }

  @override
  String get useImageAsProfilePicture =>
      'Do you want to use this image as your profile picture?';

  @override
  String get useThisImage => 'Use This Image';

  @override
  String failedToPickImage(Object error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get uploadingProfilePicture => 'Uploading profile picture...';

  @override
  String get profilePictureUploadedSuccessfully =>
      'Profile picture uploaded successfully!';

  @override
  String failedToUploadProfilePicture(Object error) {
    return 'Failed to upload profile picture: $error';
  }

  @override
  String get saving => 'Saving...';

  @override
  String get editInformation => 'Edit Information';

  @override
  String get notProvided => 'Not provided';

  @override
  String get errorLoadingProfile => 'Error Loading Profile';

  @override
  String get contactInformationUpdated =>
      'Contact information updated successfully!';

  @override
  String get removeDocument => 'Remove Document';

  @override
  String removeDocumentConfirmation(Object documentTitle) {
    return 'Are you sure you want to remove this $documentTitle? This action cannot be undone.';
  }

  @override
  String get fileSizeLimit => 'File size must be less than 10MB';

  @override
  String get documentUrlNotAvailable => 'Document URL is not available';

  @override
  String get zoneInformation => 'Zone Information';

  @override
  String get zoneName => 'Zone Name';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get requiredDocuments => 'Required Documents';

  @override
  String get driverLicense => 'Driver License';

  @override
  String get driverLicenseDescription =>
      'Upload a clear photo of your driver license';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get notUploaded => 'Not Uploaded';

  @override
  String get replaceDocument => 'Replace Document';

  @override
  String get viewDocument => 'View Document';

  @override
  String get verified => 'Verified';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get manageProfileInformation => 'Manage your profile information';

  @override
  String get manageNotificationPreferences => 'Manage notification preferences';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get supportAndHelp => 'Support & Help';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get getHelpAndSupport => 'Get help and support';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get reachOutToOurTeam => 'Reach out to our team';

  @override
  String get readTermsAndConditions => 'Read our terms and conditions';

  @override
  String get readPrivacyPolicy => 'Read our privacy policy';

  @override
  String get accountActions => 'Account Actions';

  @override
  String get signOutOfAccount => 'Sign out of your account';

  @override
  String get areYouSureLogout => 'Are you sure you want to logout?';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String languageChangedTo(Object languageName) {
    return 'Language changed to $languageName';
  }

  @override
  String get zoneSlug => 'Zone Slug';

  @override
  String get radius => 'Radius';

  @override
  String get deliveryCharges => 'Delivery Charges';

  @override
  String get regularDeliveryCharges => 'Regular Delivery Charges';

  @override
  String get rushDeliveryCharges => 'Rush Delivery Charges';

  @override
  String get freeDeliveryAmount => 'Free Delivery Amount';

  @override
  String get deliveryTimes => 'Delivery Times';

  @override
  String get regularDeliveryTime => 'Regular Delivery Time';

  @override
  String get rushDeliveryTime => 'Rush Delivery Time';

  @override
  String get verificationComplete => 'Verification Complete';

  @override
  String get accountVerifiedSuccessfully =>
      'Your account has been successfully verified';

  @override
  String get verificationDetails => 'Verification Details';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get verificationProcess => 'Verification Process';

  @override
  String get documentManagement => 'Document Management';

  @override
  String documentsCount(Object count, Object total) {
    return '$count of $total Documents';
  }

  @override
  String get vehicleRegistration => 'Vehicle Registration';

  @override
  String get vehicleRegistrationDescription =>
      'Upload a clear photo of your vehicle registration';

  @override
  String get documentGuidelines => 'Document Guidelines';

  @override
  String get photoQuality => 'Photo Quality';

  @override
  String get photoQualityDescription => 'Ensure photos are clear and well-lit';

  @override
  String get readableText => 'Readable Text';

  @override
  String get readableTextDescription => 'All text should be clearly visible';

  @override
  String get yourEarnings => 'Your Earnings';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get handlingCharges => 'Handling Charges';

  @override
  String get perStoreDropOffFee => 'Per Store Drop-off Fee';

  @override
  String get bufferTime => 'Buffer Time';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get zoneStatus => 'Zone Status';

  @override
  String get verificationRemarks => 'Verification Remarks';

  @override
  String get verificationSteps => 'Verification Steps';

  @override
  String get documentReview => 'Document Review';

  @override
  String get documentReviewDescription =>
      'Our team will review your submitted documents';

  @override
  String get verificationCompleteStep => 'Verification Complete';

  @override
  String get verificationCompleteStepDescription =>
      'Your account will be verified and activated';

  @override
  String get nextSteps => 'Next Steps';

  @override
  String get verificationRemark => 'Verification Remark';

  @override
  String get fileFormat => 'File Format';

  @override
  String get fileFormatDescription => 'Use JPG, PNG, or PDF format';

  @override
  String get securityDescription => 'Your documents are securely stored';

  @override
  String get uploadProgress => 'Upload Progress';

  @override
  String get allDocumentsUploaded => 'All Documents Uploaded';

  @override
  String get allDocumentsUploadedDescription =>
      'Your profile is complete and ready for verification';

  @override
  String get documentInformation => 'Document Information';

  @override
  String get documentUrl => 'Document URL';

  @override
  String get actions => 'Actions';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get openInBrowserDescription => 'View document in external browser';

  @override
  String get downloadDocument => 'Download Document';

  @override
  String get downloadDocumentDescription => 'Save document to your device';

  @override
  String get shareDocument => 'Share Document';

  @override
  String get shareDocumentDescription => 'Share document with others';

  @override
  String get available => 'AVAILABLE';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get pdfDocument => 'PDF Document';

  @override
  String get jpegImage => 'JPEG Image';

  @override
  String get pngImage => 'PNG Image';

  @override
  String get wordDocument => 'Word Document';

  @override
  String document(Object index) {
    return 'document';
  }

  @override
  String openingInBrowser(Object documentTitle) {
    return 'Opening $documentTitle in browser...';
  }

  @override
  String downloadingDocument(Object documentTitle) {
    return 'Downloading $documentTitle...';
  }

  @override
  String sharingDocument(Object documentTitle) {
    return 'Sharing $documentTitle...';
  }

  @override
  String get urlCopiedToClipboard => 'URL copied to clipboard';

  @override
  String get failedToLoadDocument => 'Failed to Load Document';

  @override
  String get goBack => 'Go Back';

  @override
  String get earningsAnalytics => 'Earnings Analytics';

  @override
  String get performanceMetrics => 'Performance Metrics';

  @override
  String get ordersDelivered => 'Orders Delivered';

  @override
  String get averageRating => 'Average Rating';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get viewHistory => 'View History';

  @override
  String get checkPastDeliveries => 'Check past deliveries';

  @override
  String get cannotGoOfflineWithPendingOrders =>
      'You cannot go offline with pending orders';

  @override
  String get failedToUpdateStatus => 'Failed to update status';

  @override
  String get cashCollection => 'Cash Collection';

  @override
  String get allCashCollection => 'All Cash Collection';

  @override
  String get filterCashCollections => 'Filter Cash Collections';

  @override
  String get submissionStatus => 'Submission Status';

  @override
  String get dateRangeLast => 'Date Range (Last)';

  @override
  String get cashSubmitted => 'Cash Submitted';

  @override
  String get remainingAmount => 'Remaining Amount';

  @override
  String get noCashCollectionYet => 'No cash collection yet';

  @override
  String get completeDeliveriesToSeeYourCashCollection =>
      'Complete deliveries to see your cash collection';

  @override
  String get completeDeliveriesToSeeCashCollection =>
      'Complete deliveries to see your cash collection';

  @override
  String get errorLoadingCashCollection => 'Error loading cash collection';

  @override
  String get partiallySubmitted => 'Partially Submitted';

  @override
  String get submitted => 'Submitted';

  @override
  String get last30Minutes => '30 Min';

  @override
  String get last1Hour => '1 Hour';

  @override
  String get last5Hours => '5 Hours';

  @override
  String get last1Day => 'Today';

  @override
  String get last7Days => 'Week';

  @override
  String get last30Days => 'Month';

  @override
  String get last365Days => 'Year';

  @override
  String get call => 'Call';

  @override
  String get apply => 'Apply';

  @override
  String get all => 'All';

  @override
  String get order => 'Order';

  @override
  String get pleaseEnterOtpFromCustomerForDelivery =>
      'Please enter OTP from customer for delivery:';

  @override
  String get pleaseEnterOtpForThisItem => 'Please enter OTP for this item:';

  @override
  String get unknownItem => 'Unknown Item';

  @override
  String get earningsSummary => 'Earnings Summary';

  @override
  String get averageEarnings => 'Average Earnings';

  @override
  String get deliveries => 'deliveries';

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String get trips => 'Trips';

  @override
  String get sessions => 'Sessions';

  @override
  String get gigs => 'Gigs';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String noDataForPeriod(Object period) {
    return 'No data available for $period';
  }

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get itemId => 'Item ID';

  @override
  String get quantity => 'Quantity';

  @override
  String get locationIssue => 'Location Issue';

  @override
  String get noteOptional => 'Note (Optional)';

  @override
  String get addNoteForWithdrawal =>
      'Add a note for your withdrawal request...';

  @override
  String get toResolveThisIssue => 'To resolve this issue:';

  @override
  String get moveToCoveredDeliveryArea => '• Move to a covered delivery area';

  @override
  String get checkDeliveryZoneInProfile =>
      '• Check your delivery zone in Profile > Delivery Zones';

  @override
  String get ensureGpsEnabledAccurate => '• Ensure GPS is enabled and accurate';

  @override
  String get viewDeliveryZone => 'View Delivery Zone';

  @override
  String get confirmArrival => 'Confirm Arrival';

  @override
  String get arrivalConfirmed => 'Arrival Confirmed';

  @override
  String get continueToDelivery => 'Continue to Delivery';

  @override
  String get arrivalNextStepHint =>
      'Next: verify items and complete the delivery';

  @override
  String routeMinutes(int count) {
    return '$count min';
  }

  @override
  String get fastestRoute => 'Fastest route';

  @override
  String routeMinutesSlower(int count) {
    return '$count min slower';
  }

  @override
  String get tapRouteToSwitch => 'Tap a route on the map to switch';

  @override
  String get haveYouReachedAddress => 'Have you reached the delivery address?';

  @override
  String get yesImHere => 'Yes, I\'m Here';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get pleaseEnterOtp => 'Please enter the OTP';

  @override
  String get otpMustBe6Digits => 'OTP must be 6 digits';

  @override
  String get otpVerifiedSuccessfullyDeliveryCompleted =>
      'OTP verified successfully! Delivery completed.';

  @override
  String get pickupRoute => 'Pickup Route';

  @override
  String get storePickupRoute => 'Store Pickup Route';

  @override
  String get viewDetails => 'View Details';

  @override
  String get deliveryRoute => 'Delivery Route';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get loadingMap => 'Loading map...';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get youAreCurrentlyOffline => 'You are currently offline';

  @override
  String get goOnlineToStartReceivingOrders =>
      'Go online to start receiving delivery orders';

  @override
  String get goOnline => 'Go Online';

  @override
  String get average => 'Average';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get notSet => 'Not set';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String get documentUploadDescription =>
      'Upload your driver license and vehicle registration documents';

  @override
  String get withdrawalRequest => 'Withdrawal Request';

  @override
  String get adminRemark => 'Admin Remark';

  @override
  String get requestId => 'Request ID';

  @override
  String get requestNote => 'Request Note';

  @override
  String get processedAt => 'Processed At';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get createdAt => 'Created';

  @override
  String get updatedAt => 'Updated';

  @override
  String get rushDelivery => 'Rush Delivery';

  @override
  String get errorLoadingOrders => 'Error Loading Orders';

  @override
  String get noImagesAvailable => 'No images available';

  @override
  String get loadingWithdrawals => 'Loading your withdrawals...';

  @override
  String get withdrawEarningsToBank =>
      'Withdraw your earnings to your bank account';

  @override
  String get submitting => 'Submitting...';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get noWithdrawalsYet => 'No Withdrawals Yet';

  @override
  String get noWithdrawalsYetDescription =>
      'You haven\'t made any withdrawal requests yet.\nTap the button below to request your first withdrawal.';

  @override
  String get gigsDescription => 'Find and manage your gig opportunities';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get selectPreferredAppearance =>
      'Select your preferred app appearance';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get cleanBrightInterface => 'Clean and bright interface';

  @override
  String get easyOnEyesLowLight => 'Easy on the eyes in low light';

  @override
  String get preview => 'Preview';

  @override
  String get hyperLocal => 'NagpurMart-Rider';

  @override
  String get collectItemsStores => 'Collect items from stores';

  @override
  String get searchOrders => 'Search orders...';

  @override
  String get noDeliveredOrders => 'No Completed Orders';

  @override
  String get noDeliveredOrdersYet => 'You haven\'t completed any orders yet';

  @override
  String get deliveredOn => 'Completed On';

  @override
  String get feedback => 'Feedback';

  @override
  String get overallRating => 'Overall Rating';

  @override
  String basedOnReviews(Object count) {
    return 'Based on $count reviews';
  }

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get beFirstToLeaveReview => 'Be the first to leave a review!';

  @override
  String get noRatingsDataAvailable => 'No ratings data available';

  @override
  String errorMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get mostHelpful => 'Most Helpful';

  @override
  String get latest => 'Latest';

  @override
  String get positive => 'Positive';

  @override
  String get negative => 'Negative';

  @override
  String get seeMore => 'See More';

  @override
  String get seeLess => 'See Less';

  @override
  String get star5 => '5★';

  @override
  String get star4 => '4★';

  @override
  String get star3 => '3★';

  @override
  String get star2 => '2★';

  @override
  String get star1 => '1★';

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get checkInternetConnection =>
      'Please check your internet connection and try again.';

  @override
  String get exitApp => 'Exit App';

  @override
  String get exitAppConfirmation => 'Are you sure you want to exit the app?';

  @override
  String get exit => 'Exit';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get activateStatusToSeeOrders =>
      'Please activate your status to see your orders';

  @override
  String get activateStatusToSeeAvailableOrders =>
      'Please activate your status to see available orders';

  @override
  String get tapToView => 'Tap to view';

  @override
  String get feeds => 'Feeds';

  @override
  String get noChartDataAvailable => 'No chart data available';

  @override
  String get errorLoadingChartData => 'Error loading chart data';

  @override
  String noDataAvailableForPeriod(Object period) {
    return 'No data available for $period';
  }

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get updating => 'Updating...';

  @override
  String get actionRequired => 'Action Required';

  @override
  String get uploadDocumentsMessage =>
      'Please upload your driver license and vehicle registration documents to complete the verification process.';

  @override
  String get verificationFailed => 'Verification Failed';

  @override
  String get verificationRejectedMessage =>
      'Your verification was rejected. Please review the remarks above and resubmit your documents.';

  @override
  String get verificationPendingMessage =>
      'Your verification is currently under review';

  @override
  String get verificationRejectedMessageShort =>
      'Your verification was not approved';

  @override
  String get verificationCompleteMessage =>
      'Your account has been successfully verified';

  @override
  String get unknownStatus => 'Unknown Status';

  @override
  String get verificationStatusUnknown => 'Verification status is unknown';

  @override
  String get noProfileFound => 'No Profile Found';

  @override
  String get unableToLoadVerificationStatus =>
      'Unable to load verification status. Please try again.';

  @override
  String get noDriverLicenseDocuments => 'No driver license documents found';

  @override
  String get driverLicenseDocuments => 'Driver License Documents';

  @override
  String documentsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count document$_temp0';
  }

  @override
  String driverLicenseDocument(Object index) {
    return 'Driver License $index';
  }

  @override
  String get noVehicleRegistrationDocuments =>
      'No vehicle registration documents found';

  @override
  String get vehicleRegistrationDocuments => 'Vehicle Registration Documents';

  @override
  String vehicleRegistrationDocument(Object index) {
    return 'Vehicle Registration $index';
  }

  @override
  String get viewDocuments => 'View Documents';

  @override
  String get accountInactive => 'Account Inactive';

  @override
  String get activateAccountToViewOrders =>
      'You need to activate your account to view and accept available orders';

  @override
  String get activateAccount => 'Activate Account';

  @override
  String get tapPowerButtonToGoOnline =>
      'Tap the power button in the header to go online';

  @override
  String get googleMapsError =>
      'Could not open Google Maps. Please install Google Maps app or try again.';

  @override
  String get documentLbl => 'document';

  @override
  String get pickupOrders => 'Pickup Orders';

  @override
  String get availPickupOrders => 'Available Pickup Orders';

  @override
  String get noReturnOrdersAvailable => 'No Pickup Orders Available';

  @override
  String get activateAccountToViewPickupOrders =>
      'You need to activate your account to view and accept pickup orders';

  @override
  String get noPickupOrders => 'No Pickup Orders';

  @override
  String get item => 'Item';

  @override
  String get deliveredSuccessfully => 'Delivered Successfully';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get pickup => 'Pickup';

  @override
  String get deliveredToSeller => 'Delivered to Seller';

  @override
  String get returnDetails => 'Return Details';

  @override
  String get reason => 'Reason';

  @override
  String get refundAmt => 'Refund Amount';

  @override
  String get pickupDetails => 'Pickup Details';

  @override
  String get goToCustomerLocation => 'Go to Customer Location';

  @override
  String get goToSellerLocation => 'Go to Seller Location';

  @override
  String get noDetailsFound => 'No details found';

  @override
  String get baseFees => 'Base Fee';

  @override
  String get pickupFees => 'Pickup Fee';

  @override
  String get distanceFees => 'Distance Fee';

  @override
  String get sellerComment => 'Seller Comment';

  @override
  String get allEarnings => 'All';

  @override
  String get day => 'Day';

  @override
  String get periodEarnings => 'Period Earnings';

  @override
  String get earningsBreakdown => 'Earnings Breakdown';

  @override
  String get orderEarnings => 'Order Earnings';

  @override
  String get baseAndDistanceFees => 'Base & Distance Fees';

  @override
  String get perStoreCharges => 'Per Store Charges';

  @override
  String get incentives => 'Incentives';

  @override
  String get bonusAndRewards => 'Bonus & Rewards';

  @override
  String get dailyBreakdown => 'Daily Breakdown';

  @override
  String get avgPerDay => 'Avg/Day';

  @override
  String get bestDay => 'Best Day';

  @override
  String get daysActive => 'Days Active';

  @override
  String get allTime => 'All Time';

  @override
  String weekN(Object weekNumber) {
    return 'Week $weekNumber';
  }

  @override
  String get feed => 'Orders';

  @override
  String get chooseYourPreferredLanguage => 'Choose your preferred language';

  @override
  String get noAssignedOrdersYet => 'No assigned orders yet';

  @override
  String get noInProgressOrders => 'No orders in progress';

  @override
  String get noCompletedOrdersYet => 'You haven\'t completed any orders yet';

  @override
  String get noCanceledOrders => 'No canceled orders';

  @override
  String get deliveryZonesNotConfigured =>
      'Delivery zones have not been configured yet.';

  @override
  String get noDeliveryZonesAvailable => 'No delivery zones available';

  @override
  String get unableToLoadData => 'Unable to load data';

  @override
  String get noDataYet => 'No Data Yet';

  @override
  String get checkConnectionAndTryAgain =>
      'Please check your connection and try again';

  @override
  String get dataWillAppearHere => 'Your information will appear here soon';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get selectVehicleType => 'Select Vehicle Type';

  @override
  String get pleaseSelectVehicleType => 'Please select vehicle type';

  @override
  String get locationServiceDisabled => 'Location Service Disabled';

  @override
  String get locationServiceDescription =>
      'GPS is required to track your delivery progress. Please enable location services to continue.';

  @override
  String get enable => 'Enable';

  @override
  String get locationPermissionDenied => 'Location Permission Denied';

  @override
  String get locationPermissionDescription =>
      'This app needs location permission to track your delivery in real-time.';

  @override
  String get locationPermissionPermanentDescription =>
      'Location permission is permanently denied. Please enable it from app settings to continue.';

  @override
  String get todayEarnings => 'Today Earnings';

  @override
  String get codPayment => 'COD Payment';

  @override
  String get viewAll => 'View All';

  @override
  String get myOrderDetails => 'My Order Details';

  @override
  String get deliveredOrders => 'Delivered Orders';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get productPrice => 'Product Price';

  @override
  String distanceKm(String distance) {
    return 'Distance: $distance km';
  }

  @override
  String get here => 'Here';

  @override
  String get declineOrder => 'Decline Order';

  @override
  String get orderNo => 'Order no.';

  @override
  String get orderDeliveredLabel => 'ORDER DELIVERED';

  @override
  String get orderCancelLabel => 'ORDER CANCEL';

  @override
  String get paymentModeLabel => 'Payment mode:';

  @override
  String deliveredTimeLabel(String time) {
    return 'Delivered Time - $time';
  }

  @override
  String get rateCustomer => 'Rate Customer';

  @override
  String get cancelByLabel => 'Cancel by:';

  @override
  String get whyLabel => 'Why?:';

  @override
  String minsShort(String minutes) {
    return '$minutes mins';
  }

  @override
  String get orderDeclinedHidden => 'Order removed from your list';

  @override
  String get supportNumberUnavailable => 'Support number not available';

  @override
  String get rateCustomerComingSoon => 'Customer rating will be available soon';
}
