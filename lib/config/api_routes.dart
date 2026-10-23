import 'package:nagpur_rider/config/constant.dart';

String loginApi = '${baseUrl}login';
String qrLoginApi = '${baseUrl}login/qr';
String logoutApi = '${baseUrl}logout';
String registerApi = '${baseUrl}register';
String deliveryZoneApi = '${deliveryZoneUrl}delivery-zone';
String deliveryBoyStatusApi = '${baseUrl}status/update';
String deliveryBoyProfileApi = '${baseUrl}profile';
String availableOrdersStatusApi = '${baseUrl}orders/available';
String myOrdersApi = '${baseUrl}orders/my';
String acceptOrderApi = '${baseUrl}orders';
String updateCurrentLocationApi = '${baseUrl}update-current-location';
String updateFcmTokenApi = '${baseUrl}fcm-token';
String itemsCollectedApi = '${baseUrl}order-items';
String orderDetailsApi = '${baseUrl}orders';
String getReturnOrdersApi = '${baseUrl}return-pickups/available';
String acceptReturnOrderApi = '${baseUrl}return-pickups/';
String updateReturnOrderApi = '${baseUrl}return-pickups/';
String listPickupsApi = '${baseUrl}return-pickups/my';
String pickupDetailsApi = '${baseUrl}return-pickups/';

String createWithdrawalsReqApi = '${baseUrl}withdrawals';
String getWithdrawalsApi = '${baseUrl}withdrawals';
String getWithdrawalByIdApi = '${baseUrl}withdrawals';
String getSystemSettingApi = '${deliveryZoneUrl}settings';
String getDeliveryBoySettingsApi = '${deliveryZoneUrl}settings';

String getEarningsApi = '${baseUrl}earnings';
String getEarningsStatsApi = '${baseUrl}earnings/statistics';
String getEarningsDateRangeApi = '${baseUrl}earnings';

String getCashCollectionApi = '${baseUrl}cash-collections';
String getCashCollectionStatisticsApi = '${baseUrl}cash-collection/statistics';

String getHomeStatsApi = '${baseUrl}home';

String ratingApi = '${baseUrl}feedback/ratings';
String feedbackApi = '${baseUrl}feedback';
String notificationsApi = '${baseUrl}notifications';

String customSendOtpApi = '${deliveryZoneUrl}auth/send-otp';
String customVerifyOtpApi = '${deliveryZoneUrl}auth/verify-otp';
