// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'हाइपर लोकल डिलीवरी';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get enterYourFullName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get pleaseEnterYourFullName => 'कृपया अपना पूरा नाम दर्ज करें';

  @override
  String get nameMustBeAtLeast2Characters =>
      'नाम कम से कम 2 अक्षरों का होना चाहिए';

  @override
  String get email => 'ईमेल';

  @override
  String get enterYourEmail => 'अपना ईमेल दर्ज करें';

  @override
  String get pleaseEnterYourEmail => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get pleaseEnterAValidEmail => 'कृपया एक वैध ईमेल दर्ज करें';

  @override
  String get country => 'देश';

  @override
  String get pleaseSelectACountry => 'कृपया एक देश चुनें';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get enterYourPhoneNumber => 'अपना फोन नंबर दर्ज करें';

  @override
  String get pleaseEnterYourPhoneNumber => 'कृपया अपना फोन नंबर दर्ज करें';

  @override
  String get phoneNumberMustBeAtLeast10Digits =>
      'फोन नंबर कम से कम 10 अंकों का होना चाहिए';

  @override
  String get password => 'पासवर्ड';

  @override
  String get enterYourPassword => 'अपना पासवर्ड दर्ज करें';

  @override
  String get pleaseEnterYourPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get passwordMustBeAtLeast8Characters =>
      'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get passwordMustContainUppercaseLowercaseAndNumber =>
      'पासवर्ड में बड़े अक्षर, छोटे अक्षर और संख्याएं होनी चाहिए';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get confirmYourPassword => 'अपने पासवर्ड की पुष्टि करें';

  @override
  String get pleaseConfirmYourPassword => 'कृपया अपने पासवर्ड की पुष्टि करें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get address => 'पता';

  @override
  String get enterYourAddress => 'अपना पता दर्ज करें';

  @override
  String get pleaseEnterYourAddress => 'कृपया अपना पता दर्ज करें';

  @override
  String get vehicleType => 'वाहन का प्रकार';

  @override
  String get enterYourVehicleType => 'अपना वाहन प्रकार दर्ज करें';

  @override
  String get pleaseEnterYourVehicleType => 'कृपया अपना वाहन प्रकार दर्ज करें';

  @override
  String get driverLicenseNumber => 'ड्राइवर लाइसेंस नंबर';

  @override
  String get enterYourLicenseNumber => 'अपना लाइसेंस नंबर दर्ज करें';

  @override
  String get pleaseEnterYourLicenseNumber =>
      'कृपया अपना लाइसेंस नंबर दर्ज करें';

  @override
  String get deliveryZone => 'डिलीवरी जोन';

  @override
  String get selectYourDeliveryZone => 'अपना डिलीवरी जोन चुनें';

  @override
  String get pleaseSelectYourDeliveryZone => 'कृपया अपना डिलीवरी जोन चुनें';

  @override
  String get uploadDriverLicense => 'ड्राइवर लाइसेंस अपलोड करें';

  @override
  String get uploadVehicleRegistration => 'वाहन पंजीकरण अपलोड करें';

  @override
  String get alreadyHaveAccount => 'पहले से ही खाता है?';

  @override
  String get login => 'लॉगिन';

  @override
  String get submit => 'सबमिट करें';

  @override
  String get dontHaveAccount => 'खाता नहीं है?';

  @override
  String get register => 'रजिस्टर';

  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';

  @override
  String get contactInformation => 'संपर्क जानकारी';

  @override
  String get vehicleInformation => 'वाहन जानकारी';

  @override
  String get security => 'सुरक्षा';

  @override
  String get documentUpload => 'दस्तावेज अपलोड';

  @override
  String get storagePermissionDenied => 'स्टोरेज अनुमति अस्वीकृत';

  @override
  String get noFilesSelected => 'कोई फ़ाइल चयनित नहीं';

  @override
  String get filePickerPluginNotAvailable =>
      'फ़ाइल पिकर प्लगइन उपलब्ध नहीं है। कृपया ऐप को पुनर्निर्मित करें।';

  @override
  String errorPickingFile(Object error) {
    return 'फ़ाइल चुनने में त्रुटि: $error';
  }

  @override
  String get pleaseEnterAValidPhoneNumber =>
      'कृपया एक मान्य फ़ोन नंबर दर्ज करें';

  @override
  String get pleaseUploadAtLeastOneDriverLicenseFile =>
      'कृपया कम से कम एक ड्राइवर लाइसेंस फ़ाइल अपलोड करें';

  @override
  String get pleaseUploadAtLeastOneVehicleRegistrationFile =>
      'कृपया कम से कम एक वाहन पंजीकरण फ़ाइल अपलोड करें';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get retry => 'फिर से प्रयास करें';

  @override
  String get deliveryZones => 'डिलीवरी जोन';

  @override
  String get welcomeBack => 'वापस आने के लिए स्वागत है';

  @override
  String get enterYourDetailsBelow => 'अपना विवरण नीचे दर्ज करें';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get forgotPasswordDescription =>
      'चिंता मत करो! अपना ईमेल दर्ज करें और हम आपको अपना पासवर्ड रीसेट करने के निर्देश भेजेंगे।';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get emailSentSuccessfully => 'ईमेल सफलतापूर्वक भेजा गया';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get home => 'होम';

  @override
  String get orders => 'ऑर्डर';

  @override
  String get earnings => 'कमाई';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get orderDetails => 'ऑर्डर विवरण';

  @override
  String get availableOrders => 'उपलब्ध ऑर्डर';

  @override
  String get noAvailableOrders => 'कोई उपलब्ध ऑर्डर नहीं';

  @override
  String get ordersWillAppearHere => 'ऑर्डर यहां उपलब्ध होने पर दिखाई देंगे';

  @override
  String ordersCount(Object count) {
    return '$count ऑर्डर';
  }

  @override
  String get expectedEarning => 'अपेक्षित कमाई';

  @override
  String get myEarnings => 'मेरी कमाई';

  @override
  String get totalEarnings => 'कुल कमाई';

  @override
  String get totalOrders => 'कुल ऑर्डर';

  @override
  String get perPage => 'प्रति पेज';

  @override
  String orderNumber(Object orderId) {
    return 'ऑर्डर #$orderId';
  }

  @override
  String get pending => 'लंबित';

  @override
  String get paid => 'भुगतान किया गया';

  @override
  String get assigned => 'नियत';

  @override
  String get inProgress => 'प्रगति पर';

  @override
  String get canceled => 'रद्द किया गया';

  @override
  String get baseFee => 'बेस शुल्क';

  @override
  String get storePickup => 'स्टोर पिकअप';

  @override
  String get distanceFee => 'दूरी शुल्क';

  @override
  String get incentive => 'प्रोत्साहन';

  @override
  String get total => 'कुल';

  @override
  String get date => 'तारीख:';

  @override
  String get noEarningsYet => 'अभी तक कमाई नहीं';

  @override
  String get completeDeliveriesMessage =>
      'अपनी कमाई देखने के लिए कुछ डिलीवरी पूरी करें';

  @override
  String get errorLoadingEarnings => 'कमाई लोड करने में त्रुटि';

  @override
  String get drop => 'ड्रॉप';

  @override
  String get pickupFrom => 'से पिकअप';

  @override
  String get store => 'स्टोर';

  @override
  String minsAway(Object minutes) {
    return '$minutes मिनट दूर';
  }

  @override
  String get acceptOrder => 'ऑर्डर स्वीकार करें';

  @override
  String get accepting => 'स्वीकार कर रहा है...';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get storePickupCoordinatesNotAvailable =>
      'स्टोर पिकअप के लिए निर्देशांक उपलब्ध नहीं';

  @override
  String get noCoordinatesAvailableForMapView =>
      'मानचित्र दृश्य के लिए कोई निर्देशांक उपलब्ध नहीं';

  @override
  String get routeDetailsNotAvailableForMapView =>
      'मानचित्र दृश्य के लिए मार्ग विवरण उपलब्ध नहीं';

  @override
  String navigationError(Object error) {
    return 'नेविगेशन त्रुटि: $error';
  }

  @override
  String get myOrders => 'मेरे ऑर्डर';

  @override
  String get noOrdersFound => 'कोई ऑर्डर नहीं मिला';

  @override
  String get noOrdersAcceptedYet =>
      'आपने अभी तक कोई ऑर्डर स्वीकार नहीं किया है';

  @override
  String get delivered => 'डिलीवर हुआ';

  @override
  String get outForDelivery => 'डिलीवरी के लिए बाहर';

  @override
  String get km => 'किमी';

  @override
  String get items => 'आइटम';

  @override
  String get confirmed => 'पुष्टि की गई';

  @override
  String get preparing => 'तैयार हो रहा है';

  @override
  String get ready => 'तैयार';

  @override
  String get appSettings => 'ऐप सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get changeAppLanguage => 'ऐप की भाषा बदलें';

  @override
  String get theme => 'थीम';

  @override
  String get changeAppColors => 'ऐप की थीम बदलें';

  @override
  String get personalInfo => 'व्यक्तिगत जानकारी';

  @override
  String get vehicleInfo => 'वाहन की जानकारी';

  @override
  String get contactInfo => 'संपर्क जानकारी';

  @override
  String get documents => 'दस्तावेज़';

  @override
  String get verificationStatus => 'सत्यापन स्थिति';

  @override
  String get editProfile => 'प्रोफाइल संपादित करें';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get firstName => 'पहला नाम';

  @override
  String get lastName => 'अंतिम नाम';

  @override
  String get phone => 'फोन';

  @override
  String get city => 'शहर';

  @override
  String get state => 'राज्य';

  @override
  String get zipCode => 'पिन कोड';

  @override
  String get vehicleNumber => 'वाहन संख्या';

  @override
  String get vehicleModel => 'वाहन का मॉडल';

  @override
  String get vehicleColor => 'वाहन का रंग';

  @override
  String get licenseNumber => 'लाइसेंस नंबर';

  @override
  String get insuranceNumber => 'बीमा संख्या';

  @override
  String get orderStatus => 'ऑर्डर स्थिति';

  @override
  String get collected => 'संग्रहित';

  @override
  String get orderItems => 'ऑर्डर आइटम';

  @override
  String get customerDetails => 'ग्राहक विवरण';

  @override
  String get shippingDetails => 'शिपिंग विवरण';

  @override
  String get storeDetails => 'स्टोर विवरण';

  @override
  String get paymentInformation => 'भुगतान जानकारी';

  @override
  String get pricingDetails => 'मूल्य निर्धारण विवरण';

  @override
  String get earningsDetails => 'कमाई विवरण';

  @override
  String get subtotal => 'उप-कुल';

  @override
  String get totalPayable => 'कुल देय';

  @override
  String get finalTotal => 'अंतिम कुल';

  @override
  String get paymentMethod => 'भुगतान विधि';

  @override
  String get paymentStatus => 'भुगतान स्थिति';

  @override
  String get cashOnDelivery => 'कैश ऑन डिलीवरी';

  @override
  String get onlinePayment => 'ऑनलाइन भुगतान';

  @override
  String get perStorePickupFee => 'प्रति स्टोर पिकअप शुल्क';

  @override
  String get distanceBasedFee => 'दूरी आधारित शुल्क';

  @override
  String get perOrderIncentive => 'प्रति ऑर्डर प्रोत्साहन';

  @override
  String get collectAllItems => 'सभी आइटम एकत्रित करें';

  @override
  String get viewPickupRoute => 'पिकअप मार्ग देखें';

  @override
  String get deliveredAllOrder => 'सभी ऑर्डर पहुंचाए गए';

  @override
  String get collectItemsIndividually => 'आइटम अलग-अलग एकत्रित करें';

  @override
  String get itemCollected => 'आइटम सफलतापूर्वक एकत्रित किया गया';

  @override
  String get itemDelivered => 'आइटम सफलतापूर्वक पहुंचाया गया';

  @override
  String get allItemsCollected => 'सभी आइटम सफलतापूर्वक एकत्रित किए गए!';

  @override
  String get noItemsToCollect => 'एकत्रित करने के लिए कोई आइटम नहीं';

  @override
  String errorCollectingItems(Object error) {
    return 'आइटम एकत्र करने में त्रुटि: $error';
  }

  @override
  String get pleaseEnterValidOtp => 'कृपया एक वैध 6-अंकीय OTP दर्ज करें';

  @override
  String get otpRequired => 'OTP आवश्यक';

  @override
  String get itemOtpRequired => 'आइटम OTP आवश्यक';

  @override
  String get deliveryOtpRequired => 'डिलीवरी OTP आवश्यक';

  @override
  String get customerOtpRequired => 'ग्राहक OTP आवश्यक';

  @override
  String get pleaseEnterOtpFromCustomer => 'कृपया ग्राहक से OTP दर्ज करें:';

  @override
  String get pleaseEnterOtpForItem => 'कृपया इस आइटम के लिए OTP दर्ज करें:';

  @override
  String get enterDeliveryOtp => 'डिलीवरी OTP दर्ज करें';

  @override
  String get enterItemOtp => 'आइटम OTP दर्ज करें';

  @override
  String get enterCustomerOtp => 'ग्राहक OTP दर्ज करें';

  @override
  String get verifyAndDeliver => 'सत्यापित करें और पहुंचाएं';

  @override
  String get verifyOtp => 'OTP सत्यापित करें';

  @override
  String get verifying => 'सत्यापित कर रहा है...';

  @override
  String get otpVerifiedSuccessfully => 'OTP सफलतापूर्वक सत्यापित!';

  @override
  String get noOtpRequired => 'इस आइटम के लिए कोई OTP आवश्यक नहीं';

  @override
  String get cashCollected => 'नकद एकत्रित किया गया';

  @override
  String get pleaseCollectCash =>
      'कृपया आगे बढ़ने से पहले ग्राहक से नकद एकत्र करें।';

  @override
  String get amount => 'राशि';

  @override
  String get orderCompleted => 'ऑर्डर पूरा हुआ!';

  @override
  String get allItemsDeliveredSuccessfully =>
      'सभी आइटम सफलतापूर्वक पहुंचाए गए!';

  @override
  String get yourEarningsBreakdown => 'आपकी कमाई का विवरण';

  @override
  String get goToHome => 'होम पर जाएं';

  @override
  String get done => 'हो गया';

  @override
  String get ok => 'ठीक है';

  @override
  String get deliver => 'पहुंचाएं';

  @override
  String get collect => 'संग्रह करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get warning => 'चेतावनी';

  @override
  String get info => 'जानकारी';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get na => 'उपलब्ध नहीं';

  @override
  String kmFromCustomer(Object distance) {
    return 'ग्राहक से $distance किमी';
  }

  @override
  String collectedItemsCount(Object collected, Object total) {
    return 'सभी आइटम एकत्रित करें ($collected/$total)';
  }

  @override
  String collectItemsIndividuallyCount(Object collected, Object total) {
    return 'आइटम अलग-अलग एकत्रित करें ($collected/$total)';
  }

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get currentPassword => 'वर्तमान पासवर्ड';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get documentViewer => 'दस्तावेज व्यूअर';

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get pockets => 'कमाई';

  @override
  String get balance => 'शेष राशि';

  @override
  String get withdraw => 'निकासी';

  @override
  String get withdrawalHistory => 'निकासी इतिहास';

  @override
  String get createWithdrawal => 'निकासी बनाएं';

  @override
  String get withdrawalAmount => 'निकासी राशि';

  @override
  String get bankDetails => 'बैंक विवरण';

  @override
  String get accountNumber => 'खाता संख्या';

  @override
  String get ifscCode => 'IFSC कोड';

  @override
  String get bankName => 'बैंक का नाम';

  @override
  String get accountHolderName => 'खाता धारक का नाम';

  @override
  String get requestWithdrawal => 'निकासी का अनुरोध करें';

  @override
  String get withdrawalRequested => 'निकासी सफलतापूर्वक अनुरोध की गई';

  @override
  String get minimumWithdrawalAmount => 'न्यूनतम निकासी राशि ₹100 है';

  @override
  String get insufficientBalance => 'अपर्याप्त शेष राशि';

  @override
  String get light => 'हल्का';

  @override
  String get dark => 'गहरा';

  @override
  String get system => 'सिस्टम';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get pushNotifications => 'पुश सूचनाएं';

  @override
  String get emailNotifications => 'ईमेल सूचनाएं';

  @override
  String get smsNotifications => 'SMS सूचनाएं';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get about => 'के बारे में';

  @override
  String get version => 'संस्करण';

  @override
  String get support => 'समर्थन';

  @override
  String get contactUs => 'हमसे संपर्क करें';

  @override
  String get rateApp => 'ऐप को रेट करें';

  @override
  String get shareApp => 'ऐप साझा करें';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get remove => 'हटाएं';

  @override
  String get search => 'खोजें';

  @override
  String get filter => 'फ़िल्टर';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get refresh => 'रिफ्रेश करें';

  @override
  String get close => 'बंद करें';

  @override
  String get back => 'वापस';

  @override
  String get next => 'अगला';

  @override
  String get previous => 'पिछला';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get noData => 'कोई डेटा उपलब्ध नहीं';

  @override
  String get noInternet => 'इंटरनेट कनेक्शन नहीं';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get permissionDenied => 'अनुमति अस्वीकृत';

  @override
  String get locationPermissionRequired => 'स्थान अनुमति आवश्यक है';

  @override
  String get cameraPermissionRequired => 'कैमरा अनुमति आवश्यक है';

  @override
  String get storagePermissionRequired => 'स्टोरेज अनुमति आवश्यक है';

  @override
  String get microphonePermissionRequired => 'माइक्रोफोन अनुमति आवश्यक है';

  @override
  String get permissionRequired => 'अनुमति आवश्यक';

  @override
  String permissionExplanation(Object permission) {
    return 'इस ऐप को सही तरीके से काम करने के लिए $permission अनुमति की आवश्यकता है।';
  }

  @override
  String get grantPermission => 'अनुमति दें';

  @override
  String get goToSettings => 'सेटिंग्स पर जाएं';

  @override
  String get later => 'बाद में';

  @override
  String get required => 'यह फ़ील्ड आवश्यक है';

  @override
  String get invalidEmail => 'कृपया एक वैध ईमेल पता दर्ज करें';

  @override
  String get invalidPhone => 'कृपया एक वैध फोन नंबर दर्ज करें';

  @override
  String get invalidPassword => 'पासवर्ड कम से कम 6 अक्षर लंबा होना चाहिए';

  @override
  String get invalidOtp => 'कृपया एक वैध OTP दर्ज करें';

  @override
  String get invalidAmount => 'कृपया एक वैध राशि दर्ज करें';

  @override
  String get invalidAccountNumber => 'कृपया एक वैध खाता संख्या दर्ज करें';

  @override
  String get invalidIfscCode => 'कृपया एक वैध IFSC कोड दर्ज करें';

  @override
  String get today => 'आज:';

  @override
  String get yesterday => 'कल';

  @override
  String get tomorrow => 'कल';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get lastWeek => 'पिछले सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get lastMonth => 'पिछले महीने';

  @override
  String get thisYear => 'इस साल';

  @override
  String get lastYear => 'पिछले साल';

  @override
  String get justNow => 'अभी-अभी';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours घंटे पहले';
  }

  @override
  String daysAgo(Object count) {
    return '$count दिन पहले';
  }

  @override
  String weeksAgo(Object count) {
    return '$count सप्ताह पहले';
  }

  @override
  String monthsAgo(Object months) {
    return '$months महीने पहले';
  }

  @override
  String yearsAgo(Object years) {
    return '$years साल पहले';
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
  String get status => 'स्थिति';

  @override
  String get approved => 'स्वीकृत';

  @override
  String get rejected => 'अस्वीकृत';

  @override
  String get completed => 'पूरा हुआ';

  @override
  String get cancelled => 'रद्द';

  @override
  String get processing => 'प्रक्रियाधीन';

  @override
  String get shipped => 'शिप किया गया';

  @override
  String get returned => 'वापस';

  @override
  String get refunded => 'धनवापसी';

  @override
  String get goToMap => 'मानचित्र पर जाएं';

  @override
  String get sixDigitCode => '6-अंकीय कोड';

  @override
  String get allItemsCollectedSuccessfully =>
      'सभी आइटम सफलतापूर्वक एकत्र किए गए!';

  @override
  String get congratulations => 'बधाई हो!';

  @override
  String get orderCompletedSuccessfully =>
      'आपने इस ऑर्डर को सफलतापूर्वक पूरा कर लिया है!';

  @override
  String get storePickupFee => 'स्टोर पिकअप शुल्क';

  @override
  String get orderIncentive => 'ऑर्डर प्रोत्साहन';

  @override
  String get itemDeliveredSuccessfully => 'आइटम सफलतापूर्वक पहुंचाया गया';

  @override
  String get itemCollectedSuccessfully => 'आइटम सफलतापूर्वक एकत्रित किया गया';

  @override
  String get customer => 'ग्राहक';

  @override
  String get name => 'नाम';

  @override
  String get allDone => 'सब हो गया';

  @override
  String get totalDistance => 'कुल दूरी';

  @override
  String get orderId => 'ऑर्डर आईडी';

  @override
  String get verificationPending => 'सत्यापन लंबित';

  @override
  String get verificationApproved => 'सत्यापन स्वीकृत';

  @override
  String get verificationRejected => 'सत्यापन अस्वीकृत';

  @override
  String get uploadDocument => 'दस्तावेज अपलोड करें';

  @override
  String get documentType => 'दस्तावेज प्रकार';

  @override
  String get selectDocument => 'दस्तावेज़ चुनें';

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get documentUploaded => 'दस्तावेज़ सफलतापूर्वक अपलोड किया गया';

  @override
  String get documentUploadFailed => 'दस्तावेज़ अपलोड विफल';

  @override
  String get pleaseSelectDocument => 'कृपया एक दस्तावेज़ चुनें';

  @override
  String get goOffline => 'ऑफ़लाइन जाएं';

  @override
  String get deliveryPartner => 'डिलीवरी पार्टनर';

  @override
  String get updatePersonalDetails => 'अपनी व्यक्तिगत जानकारी अपडेट करें';

  @override
  String get updatePhoneAndEmail => 'फ़ोन और ईमेल अपडेट करें';

  @override
  String get updateVehicleDetails => 'वाहन की जानकारी अपडेट करें';

  @override
  String get manageDeliveryAreas => 'अपने डिलीवरी क्षेत्रों का प्रबंधन करें';

  @override
  String get checkVerificationStatus => 'अपनी सत्यापन स्थिति की जांच करें';

  @override
  String get uploadAndManageDocuments => 'दस्तावेज़ अपलोड और प्रबंधन करें';

  @override
  String get fullNameRequired => 'पूरा नाम आवश्यक है';

  @override
  String get addressRequired => 'पता आवश्यक है';

  @override
  String get driverLicenseRequired => 'ड्राइवर लाइसेंस नंबर आवश्यक है';

  @override
  String get vehicleTypeRequired => 'वाहन प्रकार आवश्यक है';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberRequired => 'मोबाइल नंबर आवश्यक है';

  @override
  String get mobileNumberMinLength => 'मोबाइल नंबर कम से कम 10 अंक होना चाहिए';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get emailRequired => 'ईमेल आवश्यक है';

  @override
  String get validEmailRequired => 'कृपया एक वैध ईमेल पता दर्ज करें';

  @override
  String get countryRequired => 'देश आवश्यक है';

  @override
  String get phoneAndEmail => 'फोन और ईमेल';

  @override
  String get locationInformation => 'स्थान जानकारी';

  @override
  String get personalDetails => 'व्यक्तिगत विवरण';

  @override
  String get profilePicturePreview => 'प्रोफ़ाइल पिक्चर पूर्वावलोकन';

  @override
  String file(Object fileName) {
    return 'फ़ाइल: $fileName';
  }

  @override
  String get useImageAsProfilePicture =>
      'क्या आप इस छवि को अपनी प्रोफ़ाइल पिक्चर के रूप में उपयोग करना चाहते हैं?';

  @override
  String get useThisImage => 'इस छवि का उपयोग करें';

  @override
  String failedToPickImage(Object error) {
    return 'छवि चुनने में विफल: $error';
  }

  @override
  String get uploadingProfilePicture => 'प्रोफ़ाइल पिक्चर अपलोड हो रहा है...';

  @override
  String get profilePictureUploadedSuccessfully =>
      'प्रोफ़ाइल पिक्चर सफलतापूर्वक अपलोड किया गया!';

  @override
  String failedToUploadProfilePicture(Object error) {
    return 'प्रोफ़ाइल पिक्चर अपलोड करने में विफल: $error';
  }

  @override
  String get saving => 'सहेज रहा है...';

  @override
  String get editInformation => 'जानकारी संपादित करें';

  @override
  String get notProvided => 'प्रदान नहीं किया गया';

  @override
  String get errorLoadingProfile => 'प्रोफ़ाइल लोड करने में त्रुटि';

  @override
  String get contactInformationUpdated =>
      'संपर्क जानकारी सफलतापूर्वक अपडेट हो गई!';

  @override
  String get removeDocument => 'दस्तावेज हटाएं';

  @override
  String removeDocumentConfirmation(Object documentTitle) {
    return 'क्या आप वाकई इस $documentTitle को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';
  }

  @override
  String get fileSizeLimit => 'फ़ाइल का आकार 10MB से कम होना चाहिए';

  @override
  String get documentUrlNotAvailable => 'दस्तावेज़ URL उपलब्ध नहीं है';

  @override
  String get zoneInformation => 'जोन जानकारी';

  @override
  String get zoneName => 'जोन का नाम';

  @override
  String get currentStatus => 'वर्तमान स्थिति';

  @override
  String get requiredDocuments => 'आवश्यक दस्तावेज़';

  @override
  String get driverLicense => 'ड्राइवर लाइसेंस';

  @override
  String get driverLicenseDescription =>
      'अपने ड्राइवर लाइसेंस की स्पष्ट तस्वीर अपलोड करें';

  @override
  String get uploaded => 'अपलोड किया गया';

  @override
  String get notUploaded => 'अपलोड नहीं किया गया';

  @override
  String get replaceDocument => 'दस्तावेज बदलें';

  @override
  String get viewDocument => 'दस्तावेज देखें';

  @override
  String get verified => 'सत्यापित';

  @override
  String get accountSettings => 'खाता सेटिंग्स';

  @override
  String get manageProfileInformation => 'अपनी प्रोफ़ाइल जानकारी प्रबंधित करें';

  @override
  String get manageNotificationPreferences =>
      'सूचना प्राथमिकताएं प्रबंधित करें';

  @override
  String get darkTheme => 'डार्क थीम';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get supportAndHelp => 'सहायता और समर्थन';

  @override
  String get helpCenter => 'सहायता केंद्र';

  @override
  String get getHelpAndSupport => 'सहायता और समर्थन प्राप्त करें';

  @override
  String get contactSupport => 'समर्थन से संपर्क करें';

  @override
  String get reachOutToOurTeam => 'हमारी टीम से संपर्क करें';

  @override
  String get readTermsAndConditions => 'हमारी शर्तें और स्थितियां पढ़ें';

  @override
  String get readPrivacyPolicy => 'हमारी गोपनीयता नीति पढ़ें';

  @override
  String get accountActions => 'खाता कार्य';

  @override
  String get signOutOfAccount => 'अपने खाते से साइन आउट करें';

  @override
  String get areYouSureLogout => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String languageChangedTo(Object languageName) {
    return 'भाषा $languageName में बदल दी गई';
  }

  @override
  String get zoneSlug => 'जोन स्लग';

  @override
  String get radius => 'त्रिज्या';

  @override
  String get deliveryCharges => 'डिलीवरी शुल्क';

  @override
  String get regularDeliveryCharges => 'नियमित डिलीवरी शुल्क';

  @override
  String get rushDeliveryCharges => 'तेज डिलीवरी शुल्क';

  @override
  String get freeDeliveryAmount => 'मुफ्त डिलीवरी राशि';

  @override
  String get deliveryTimes => 'डिलीवरी समय';

  @override
  String get regularDeliveryTime => 'नियमित डिलीवरी समय';

  @override
  String get rushDeliveryTime => 'तेज डिलीवरी समय';

  @override
  String get verificationComplete => 'सत्यापन पूर्ण';

  @override
  String get accountVerifiedSuccessfully =>
      'आपका खाता सफलतापूर्वक सत्यापित हो गया है';

  @override
  String get verificationDetails => 'सत्यापन विवरण';

  @override
  String get accountStatus => 'खाता स्थिति';

  @override
  String get verificationProcess => 'सत्यापन प्रक्रिया';

  @override
  String get documentManagement => 'दस्तावेज प्रबंधन';

  @override
  String documentsCount(Object count, Object total) {
    return '$count में से $total दस्तावेज';
  }

  @override
  String get vehicleRegistration => 'वाहन पंजीकरण';

  @override
  String get vehicleRegistrationDescription =>
      'वाहन पंजीकरण की स्पष्ट तस्वीर अपलोड करें';

  @override
  String get documentGuidelines => 'दस्तावेज़ दिशानिर्देश';

  @override
  String get photoQuality => 'फोटो की गुणवत्ता';

  @override
  String get photoQualityDescription =>
      'सुनिश्चित करें कि फोटो स्पष्ट और अच्छी तरह से रोशन हों';

  @override
  String get readableText => 'पठनीय पाठ';

  @override
  String get readableTextDescription =>
      'सभी पाठ स्पष्ट रूप से दिखाई देने चाहिए';

  @override
  String get yourEarnings => 'आपकी कमाई';

  @override
  String get additionalInformation => 'अतिरिक्त जानकारी';

  @override
  String get handlingCharges => 'हैंडलिंग शुल्क';

  @override
  String get perStoreDropOffFee => 'प्रति स्टोर ड्रॉप-ऑफ शुल्क';

  @override
  String get bufferTime => 'बफर समय';

  @override
  String get enabled => 'सक्षम';

  @override
  String get disabled => 'अक्षम';

  @override
  String get zoneStatus => 'जोन स्थिति';

  @override
  String get verificationRemarks => 'सत्यापन टिप्पणियां';

  @override
  String get verificationSteps => 'सत्यापन चरण';

  @override
  String get documentReview => 'दस्तावेज समीक्षा';

  @override
  String get documentReviewDescription =>
      'हमारी टीम आपके जमा किए गए दस्तावेजों की समीक्षा करेगी';

  @override
  String get verificationCompleteStep => 'सत्यापन पूर्ण';

  @override
  String get verificationCompleteStepDescription =>
      'आपका खाता सत्यापित और सक्रिय किया जाएगा';

  @override
  String get nextSteps => 'अगले कदम';

  @override
  String get verificationRemark => 'सत्यापन टिप्पणी';

  @override
  String get fileFormat => 'फ़ाइल प्रारूप';

  @override
  String get fileFormatDescription => 'JPG, PNG, या PDF प्रारूप का उपयोग करें';

  @override
  String get securityDescription =>
      'आपके दस्तावेज़ सुरक्षित रूप से संग्रहीत किए जाते हैं';

  @override
  String get uploadProgress => 'अपलोड प्रगति';

  @override
  String get allDocumentsUploaded => 'सभी दस्तावेज़ अपलोड किए गए';

  @override
  String get allDocumentsUploadedDescription =>
      'आपकी प्रोफ़ाइल पूरी है और सत्यापन के लिए तैयार है';

  @override
  String get documentInformation => 'दस्तावेज जानकारी';

  @override
  String get documentUrl => 'दस्तावेज URL';

  @override
  String get actions => 'कार्रवाई';

  @override
  String get openInBrowser => 'ब्राउज़र में खोलें';

  @override
  String get openInBrowserDescription => 'बाहरी ब्राउज़र में दस्तावेज देखें';

  @override
  String get downloadDocument => 'दस्तावेज डाउनलोड करें';

  @override
  String get downloadDocumentDescription => 'दस्तावेज को अपने डिवाइस पर सहेजें';

  @override
  String get shareDocument => 'दस्तावेज साझा करें';

  @override
  String get shareDocumentDescription => 'दस्तावेज को दूसरों के साथ साझा करें';

  @override
  String get available => 'उपलब्ध';

  @override
  String get tapToCopy => 'कॉपी करने के लिए टैप करें';

  @override
  String get copyUrl => 'URL कॉपी करें';

  @override
  String get pdfDocument => 'PDF दस्तावेज';

  @override
  String get jpegImage => 'JPEG छवि';

  @override
  String get pngImage => 'PNG छवि';

  @override
  String get wordDocument => 'Word दस्तावेज';

  @override
  String document(Object index) {
    return 'दस्तावेज़ $index';
  }

  @override
  String openingInBrowser(Object documentTitle) {
    return 'ब्राउज़र में $documentTitle खोल रहा है...';
  }

  @override
  String downloadingDocument(Object documentTitle) {
    return '$documentTitle डाउनलोड कर रहा है...';
  }

  @override
  String sharingDocument(Object documentTitle) {
    return '$documentTitle साझा कर रहा है...';
  }

  @override
  String get urlCopiedToClipboard => 'URL क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get failedToLoadDocument => 'दस्तावेज लोड करने में विफल';

  @override
  String get goBack => 'वापस जाएं';

  @override
  String get earningsAnalytics => 'कमाई विश्लेषण';

  @override
  String get performanceMetrics => 'प्रदर्शन मेट्रिक्स';

  @override
  String get ordersDelivered => 'ऑर्डर वितरित';

  @override
  String get averageRating => 'औसत रेटिंग';

  @override
  String get quickActions => 'त्वरित कार्रवाई';

  @override
  String get viewHistory => 'इतिहास देखें';

  @override
  String get checkPastDeliveries => 'पिछली डिलीवरी देखें';

  @override
  String get cannotGoOfflineWithPendingOrders =>
      'पेंडिंग ऑर्डर के साथ आप ऑफलाइन नहीं जा सकते';

  @override
  String get failedToUpdateStatus => 'स्टेटस अपडेट करने में विफल';

  @override
  String get cashCollection => 'नकद संग्रह';

  @override
  String get allCashCollection => 'सभी नकद संग्रह';

  @override
  String get filterCashCollections => 'नकद संग्रह फ़िल्टर करें';

  @override
  String get submissionStatus => 'प्रस्तुति स्थिति';

  @override
  String get dateRangeLast => 'तिथि सीमा (अंतिम)';

  @override
  String get cashSubmitted => 'नकद प्रस्तुत किया गया';

  @override
  String get remainingAmount => 'शेष राशि';

  @override
  String get noCashCollectionYet => 'अभी तक कोई नकद संग्रह नहीं';

  @override
  String get completeDeliveriesToSeeYourCashCollection =>
      'अपना नकद संग्रह देखने के लिए डिलीवरी पूरी करें';

  @override
  String get completeDeliveriesToSeeCashCollection =>
      'नकद संग्रह देखने के लिए डिलीवरी पूरी करें';

  @override
  String get errorLoadingCashCollection => 'नकद संग्रह लोड करने में त्रुटि';

  @override
  String get partiallySubmitted => 'आंशिक रूप से प्रस्तुत';

  @override
  String get submitted => 'प्रस्तुत किया गया';

  @override
  String get last30Minutes => '30 मिनट';

  @override
  String get last1Hour => '1 घंटा';

  @override
  String get last5Hours => '5 घंटे';

  @override
  String get last1Day => 'आज';

  @override
  String get last7Days => 'सप्ताह';

  @override
  String get last30Days => 'महीना';

  @override
  String get last365Days => 'वर्ष';

  @override
  String get call => 'कॉल करें';

  @override
  String get apply => 'लागू करें';

  @override
  String get all => 'सभी';

  @override
  String get order => 'ऑर्डर';

  @override
  String get pleaseEnterOtpFromCustomerForDelivery =>
      'कृपया डिलीवरी के लिए ग्राहक से OTP दर्ज करें:';

  @override
  String get pleaseEnterOtpForThisItem => 'कृपया इस आइटम के लिए OTP दर्ज करें:';

  @override
  String get unknownItem => 'अज्ञात आइटम';

  @override
  String get earningsSummary => 'कमाई सारांश';

  @override
  String get averageEarnings => 'औसत कमाई';

  @override
  String get deliveries => 'डिलीवरी';

  @override
  String get todaysProgress => 'आज की प्रगति';

  @override
  String get trips => 'यात्राएँ';

  @override
  String get sessions => 'सेशन्स';

  @override
  String get gigs => 'गिग्स';

  @override
  String get periodWeek => 'सप्ताह';

  @override
  String get periodMonth => 'महीना';

  @override
  String get periodYear => 'वर्ष';

  @override
  String noDataForPeriod(Object period) {
    return '$period के लिए कोई डेटा उपलब्ध नहीं';
  }

  @override
  String get noDataAvailable => 'कोई डेटा उपलब्ध नहीं है';

  @override
  String get itemId => 'आइटम आईडी';

  @override
  String get quantity => 'मात्रा';

  @override
  String get locationIssue => 'स्थान संबंधी समस्या';

  @override
  String get noteOptional => 'नोट (वैकल्पिक)';

  @override
  String get addNoteForWithdrawal =>
      'अपने निकासी अनुरोध के लिए एक नोट जोड़ें...';

  @override
  String get toResolveThisIssue => 'इस समस्या को हल करने के लिए:';

  @override
  String get moveToCoveredDeliveryArea =>
      '• किसी कवर किए गए डिलीवरी क्षेत्र में जाएँ';

  @override
  String get checkDeliveryZoneInProfile =>
      '• प्रोफ़ाइल > डिलीवरी ज़ोन में अपनी डिलीवरी ज़ोन जांचें';

  @override
  String get ensureGpsEnabledAccurate =>
      '• सुनिश्चित करें कि GPS सक्षम और सटीक है';

  @override
  String get viewDeliveryZone => 'डिलीवरी ज़ोन देखें';

  @override
  String get confirmArrival => 'आगमन की पुष्टि करें';

  @override
  String get arrivalConfirmed => 'आगमन की पुष्टि हुई';

  @override
  String get continueToDelivery => 'डिलीवरी जारी रखें';

  @override
  String get arrivalNextStepHint => 'अगला: आइटम जांचें और डिलीवरी पूरी करें';

  @override
  String routeMinutes(int count) {
    return '$count मिनट';
  }

  @override
  String get fastestRoute => 'सबसे तेज़ रास्ता';

  @override
  String routeMinutesSlower(int count) {
    return '$count मिनट धीमा';
  }

  @override
  String get tapRouteToSwitch => 'बदलने के लिए मैप पर रास्ता टैप करें';

  @override
  String get haveYouReachedAddress => 'क्या आप डिलीवरी पते पर पहुंच गए हैं?';

  @override
  String get yesImHere => 'हाँ, मैं यहाँ हूँ';

  @override
  String get enterOtp => 'OTP दर्ज करें';

  @override
  String get pleaseEnterOtp => 'कृपया OTP दर्ज करें';

  @override
  String get otpMustBe6Digits => 'OTP 6 अंकों का होना चाहिए';

  @override
  String get otpVerifiedSuccessfullyDeliveryCompleted =>
      'OTP सफलतापूर्वक सत्यापित! डिलीवरी पूरी हुई।';

  @override
  String get pickupRoute => 'पिकअप मार्ग';

  @override
  String get storePickupRoute => 'स्टोर पिकअप मार्ग';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get deliveryRoute => 'डिलीवरी मार्ग';

  @override
  String get deliveryAddress => 'डिलीवरी पता';

  @override
  String get loadingMap => 'मानचित्र लोड हो रहा है...';

  @override
  String get offlineMode => 'ऑफ़लाइन मोड';

  @override
  String get youAreCurrentlyOffline => 'आप वर्तमान में ऑफ़लाइन हैं';

  @override
  String get goOnlineToStartReceivingOrders =>
      'डिलीवरी ऑर्डर प्राप्त करना शुरू करने के लिए ऑनलाइन जाएँ';

  @override
  String get goOnline => 'ऑनलाइन जाएं';

  @override
  String get average => 'औसत';

  @override
  String get profileInformation => 'प्रोफ़ाइल जानकारी';

  @override
  String get notSet => 'सेट नहीं';

  @override
  String get monday => 'सोम';

  @override
  String get tuesday => 'मंगल';

  @override
  String get wednesday => 'बुध';

  @override
  String get thursday => 'गुरु';

  @override
  String get friday => 'शुक्र';

  @override
  String get saturday => 'शनि';

  @override
  String get sunday => 'रवि';

  @override
  String get documentUploadDescription =>
      'अपना ड्राइवर लाइसेंस और वाहन पंजीकरण दस्तावेज अपलोड करें';

  @override
  String get withdrawalRequest => 'निकासी अनुरोध';

  @override
  String get adminRemark => 'एडमिन टिप्पणी';

  @override
  String get requestId => 'अनुरोध आईडी';

  @override
  String get requestNote => 'अनुरोध नोट';

  @override
  String get processedAt => 'संसाधित किया गया';

  @override
  String get transactionId => 'लेन-देन आईडी';

  @override
  String get createdAt => 'बनाया गया';

  @override
  String get updatedAt => 'अपडेट किया गया';

  @override
  String get rushDelivery => 'तत्काल डिलीवरी';

  @override
  String get errorLoadingOrders => 'ऑर्डर लोड करने में त्रुटि';

  @override
  String get noImagesAvailable => 'कोई छवियां उपलब्ध नहीं';

  @override
  String get loadingWithdrawals => 'आपके निकासी लोड हो रहे हैं...';

  @override
  String get withdrawEarningsToBank =>
      'अपनी कमाई को अपने बैंक खाते में निकालें';

  @override
  String get submitting => 'सबमिट हो रहा है...';

  @override
  String get submitRequest => 'अनुरोध सबमिट करें';

  @override
  String get noWithdrawalsYet => 'अभी तक कोई निकासी नहीं';

  @override
  String get noWithdrawalsYetDescription =>
      'आपने अभी तक कोई निकासी अनुरोध नहीं किया है।\nअपना पहला निकासी अनुरोध करने के लिए नीचे दिए गए बटन पर टैप करें';

  @override
  String get gigsDescription => 'अपने गिग अवसरों को खोजें और प्रबंधित करें';

  @override
  String get themeSettings => 'थीम सेटिंग्स';

  @override
  String get chooseTheme => 'थीम चुनें';

  @override
  String get selectPreferredAppearance => 'अपनी पसंदीदा ऐप की उपस्थिति चुनें';

  @override
  String get lightTheme => 'लाइट थीम';

  @override
  String get cleanBrightInterface => 'स्वच्छ और चमकदार इंटरफेस';

  @override
  String get easyOnEyesLowLight => 'कम रोशनी में आंखों के लिए आसान';

  @override
  String get preview => 'पूर्वावलोकन';

  @override
  String get hyperLocal => 'हाइपर लोकल';

  @override
  String get collectItemsStores => 'स्टोर से आइटम इकट्ठा करें';

  @override
  String get searchOrders => 'ऑर्डर खोजें...';

  @override
  String get noDeliveredOrders => 'कोई पूरा किया गया ऑर्डर नहीं';

  @override
  String get noDeliveredOrdersYet => 'आपने अभी तक कोई ऑर्डर पूरा नहीं किया है';

  @override
  String get deliveredOn => 'पूरा किया गया';

  @override
  String get feedback => 'प्रतिक्रिया';

  @override
  String get overallRating => 'कुल रेटिंग';

  @override
  String basedOnReviews(Object count) {
    return '$count समीक्षाओं के आधार पर';
  }

  @override
  String get noReviewsYet => 'अभी तक कोई समीक्षा नहीं';

  @override
  String get beFirstToLeaveReview => 'समीक्षा छोड़ने वाले पहले व्यक्ति बनें!';

  @override
  String get noRatingsDataAvailable => 'कोई रेटिंग डेटा उपलब्ध नहीं है';

  @override
  String errorMessage(Object message) {
    return 'त्रुटि: $message';
  }

  @override
  String get mostHelpful => 'सबसे सहायक';

  @override
  String get latest => 'नवीनतम';

  @override
  String get positive => 'सकारात्मक';

  @override
  String get negative => 'नकारात्मक';

  @override
  String get seeMore => 'और देखें';

  @override
  String get seeLess => 'कम देखें';

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
  String get noInternetConnection => 'कोई इंटरनेट कनेक्शन नहीं';

  @override
  String get checkInternetConnection =>
      'कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get exitApp => 'ऐप से बाहर निकलें';

  @override
  String get exitAppConfirmation => 'क्या आप वाकई ऐप से बाहर निकलना चाहते हैं?';

  @override
  String get exit => 'बाहर निकलें';

  @override
  String get refreshing => 'रिफ्रेश हो रहा है...';

  @override
  String get activateStatusToSeeOrders =>
      'कृपया अपना स्टेटस सक्रिय करें ताकि आप अपने ऑर्डर देख सकें';

  @override
  String get activateStatusToSeeAvailableOrders =>
      'कृपया अपना स्टेटस सक्रिय करें ताकि आप उपलब्ध ऑर्डर देख सकें';

  @override
  String get tapToView => 'देखने के लिए टैप करें';

  @override
  String get feeds => 'कार्य';

  @override
  String get noChartDataAvailable => 'कोई चार्ट डेटा उपलब्ध नहीं है';

  @override
  String get errorLoadingChartData => 'चार्ट डेटा लोड करने में त्रुटि';

  @override
  String noDataAvailableForPeriod(Object period) {
    return '$period के लिए कोई डेटा उपलब्ध नहीं है';
  }

  @override
  String get week => 'सप्ताह';

  @override
  String get month => 'महीना';

  @override
  String get year => 'साल';

  @override
  String get updating => 'अपडेट हो रहा है...';

  @override
  String get actionRequired => 'कार्रवाई आवश्यक';

  @override
  String get uploadDocumentsMessage =>
      'कृपया अपना ड्राइवर लाइसेंस और वाहन पंजीकरण दस्तावेज़ अपलोड करें ताकि सत्यापन प्रक्रिया पूरी हो सके।';

  @override
  String get verificationFailed => 'सत्यापन विफल';

  @override
  String get verificationRejectedMessage =>
      'आपका सत्यापन अस्वीकृत कर दिया गया था। कृपया ऊपर दी गई टिप्पणियों की समीक्षा करें और अपने दस्तावेज़ फिर से जमा करें।';

  @override
  String get verificationPendingMessage =>
      'आपका सत्यापन वर्तमान में समीक्षा के अधीन है';

  @override
  String get verificationRejectedMessageShort =>
      'आपका सत्यापन स्वीकृत नहीं किया गया था';

  @override
  String get verificationCompleteMessage =>
      'आपका खाता सफलतापूर्वक सत्यापित कर दिया गया है';

  @override
  String get unknownStatus => 'अज्ञात स्थिति';

  @override
  String get verificationStatusUnknown => 'सत्यापन स्थिति अज्ञात है';

  @override
  String get noProfileFound => 'कोई प्रोफ़ाइल नहीं मिली';

  @override
  String get unableToLoadVerificationStatus =>
      'सत्यापन स्थिति लोड करने में असमर्थ। कृपया पुनः प्रयास करें।';

  @override
  String get noDriverLicenseDocuments =>
      'कोई ड्राइवर लाइसेंस दस्तावेज़ नहीं मिले';

  @override
  String get driverLicenseDocuments => 'ड्राइवर लाइसेंस दस्तावेज़';

  @override
  String documentsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '',
      one: '',
    );
    return '$count दस्तावेज़$_temp0';
  }

  @override
  String driverLicenseDocument(Object index) {
    return 'ड्राइवर लाइसेंस $index';
  }

  @override
  String get noVehicleRegistrationDocuments =>
      'कोई वाहन पंजीकरण दस्तावेज़ नहीं मिले';

  @override
  String get vehicleRegistrationDocuments => 'वाहन पंजीकरण दस्तावेज़';

  @override
  String vehicleRegistrationDocument(Object index) {
    return 'वाहन पंजीकरण $index';
  }

  @override
  String get viewDocuments => 'दस्तावेज़ देखें';

  @override
  String get accountInactive => 'खाता निष्क्रिय';

  @override
  String get activateAccountToViewOrders =>
      'उपलब्ध ऑर्डर देखने और स्वीकार करने के लिए आपको अपना खाता सक्रिय करना होगा';

  @override
  String get activateAccount => 'खाता सक्रिय करें';

  @override
  String get tapPowerButtonToGoOnline =>
      'ऑनलाइन जाने के लिए हेडर में पावर बटन पर टैप करें';

  @override
  String get googleMapsError =>
      'Google Maps नहीं खोल सके। कृपया Google Maps ऐप इंस्टॉल करें या पुनः प्रयास करें।';

  @override
  String get documentLbl => 'दस्तावेज़';

  @override
  String get pickupOrders => 'पिकअप ऑर्डर';

  @override
  String get availPickupOrders => 'उपलब्ध पिकअप ऑर्डर';

  @override
  String get noReturnOrdersAvailable => 'कोई पिकअप ऑर्डर उपलब्ध नहीं';

  @override
  String get activateAccountToViewPickupOrders =>
      'पिकअप ऑर्डर देखने और स्वीकार करने के लिए आपको अपना खाता सक्रिय करना होगा';

  @override
  String get noPickupOrders => 'कोई पिकअप ऑर्डर नहीं';

  @override
  String get item => 'आइटम';

  @override
  String get deliveredSuccessfully => 'सफलतापूर्वक डिलीवर किया गया';

  @override
  String get updateStatus => 'स्थिति अपडेट करें';

  @override
  String get pickup => 'पिकअप';

  @override
  String get deliveredToSeller => 'विक्रेता को डिलीवर किया गया';

  @override
  String get returnDetails => 'वापसी विवरण';

  @override
  String get reason => 'कारण';

  @override
  String get refundAmt => 'रिफंड राशि';

  @override
  String get pickupDetails => 'पिकअप विवरण';

  @override
  String get goToCustomerLocation => 'ग्राहक के स्थान पर जाएँ';

  @override
  String get goToSellerLocation => 'विक्रेता के स्थान पर जाएँ';

  @override
  String get noDetailsFound => 'कोई विवरण नहीं मिला';

  @override
  String get baseFees => 'बेस फ़ीस';

  @override
  String get pickupFees => 'पिकअप फ़ीस';

  @override
  String get distanceFees => 'दूरी शुल्क';

  @override
  String get sellerComment => 'विक्रेता टिप्पणी';

  @override
  String get allEarnings => 'सभी';

  @override
  String get day => 'दिन';

  @override
  String get periodEarnings => 'अवधि की कमाई';

  @override
  String get earningsBreakdown => 'कमाई का विवरण';

  @override
  String get orderEarnings => 'ऑर्डर कमाई';

  @override
  String get baseAndDistanceFees => 'बेस और दूरी शुल्क';

  @override
  String get perStoreCharges => 'प्रति स्टोर शुल्क';

  @override
  String get incentives => 'प्रोत्साहन';

  @override
  String get bonusAndRewards => 'बोनस और पुरस्कार';

  @override
  String get dailyBreakdown => 'दैनिक विवरण';

  @override
  String get avgPerDay => 'औसत/दिन';

  @override
  String get bestDay => 'सर्वश्रेष्ठ दिन';

  @override
  String get daysActive => 'सक्रिय दिन';

  @override
  String get allTime => 'सभी समय';

  @override
  String weekN(Object weekNumber) {
    return 'सप्ताह $weekNumber';
  }

  @override
  String get feed => 'ऑर्डर';

  @override
  String get chooseYourPreferredLanguage => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get noAssignedOrdersYet => 'अभी तक कोई निर्दिष्ट आदेश नहीं';

  @override
  String get noInProgressOrders => 'कोई आदेश प्रगति पर नहीं है';

  @override
  String get noCompletedOrdersYet => 'आपने अभी तक कोई ऑर्डर पूरा नहीं किया है';

  @override
  String get noCanceledOrders => 'कोई रद्द आदेश नहीं';

  @override
  String get deliveryZonesNotConfigured =>
      'डिलीवरी ज़ोन अभी तक कॉन्फ़िगर नहीं किए गए हैं।';

  @override
  String get noDeliveryZonesAvailable => 'कोई डिलीवरी ज़ोन उपलब्ध नहीं';

  @override
  String get unableToLoadData => 'डेटा लोड करने में असमर्थ';

  @override
  String get noDataYet => 'अभी तक कोई डेटा नहीं';

  @override
  String get checkConnectionAndTryAgain =>
      'अपने कनेक्शन की जांच करें और पुन: प्रयास करें';

  @override
  String get dataWillAppearHere => 'आपकी जानकारी जल्द ही यहां दिखाई देगी';

  @override
  String get pullToRefresh => 'रीफ़्रेश करने के लिए खींचें';

  @override
  String get selectVehicleType => 'वाहन का प्रकार चुनें';

  @override
  String get pleaseSelectVehicleType => 'कृपया वाहन का प्रकार चुनें';

  @override
  String get locationServiceDisabled => 'स्थान सेवा अक्षम';

  @override
  String get locationServiceDescription =>
      'आपकी डिलीवरी प्रगति को ट्रैक करने के लिए जीपीएस आवश्यक है। कृपया स्थान सेवाओं को जारी रखने के लिए सक्षम करें।';

  @override
  String get enable => 'सक्षम';

  @override
  String get locationPermissionDenied => 'स्थान की अनुमति अस्वीकृत';

  @override
  String get locationPermissionDescription =>
      'इस ऐप को वास्तविक समय में आपकी डिलीवरी को ट्रैक करने के लिए स्थान अनुमति की आवश्यकता है।';

  @override
  String get locationPermissionPermanentDescription =>
      'स्थान की अनुमति स्थायी रूप से अस्वीकार कर दी गई है. जारी रखने के लिए कृपया इसे ऐप सेटिंग से सक्षम करें।';

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
