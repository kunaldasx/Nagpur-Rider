const String appName = 'nagpurmart.in Rider';
const String packageName = 'com.nagpur.rider';
const String domainBaseUrl = 'https://admin.nagpurmart.in';
const String baseUrl = '$domainBaseUrl/api/delivery-boy/';
const String deliveryZoneUrl = '$domainBaseUrl/api/';
const String defaultTheme = 'light';

class MapKeys {
  // Signing-certificate SHA-1s sent with Routes API requests, needed when the
  // key is restricted to Android apps. Release is the upload key; if the app is
  // signed by Google Play App Signing, add Play's app-signing SHA-1 instead.
  static const String androidCertSha1Debug =
      'BA71D3C4A7EBD69540215468BE0547B2E83AFFE3';
  static const String androidCertSha1Release =
      'FDFAFF3507B8983F6CC2366F2BC2D5F54D89F709';

  static String androidMapKey = 'AIzaSyDhYooWhZHc9Doc01SFFxpUS2wuRPqYnno';
  static String iosMapKey = 'AIzaSyDhYooWhZHc9Doc01SFFxpUS2wuRPqYnno';
}
