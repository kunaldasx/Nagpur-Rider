import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/screens/auth/view/forgot_password_page.dart';
import 'package:nagpur_rider/screens/auth/view/login_approval_pending_page.dart';
import 'package:nagpur_rider/screens/auth/view/login_page.dart';
import 'package:nagpur_rider/screens/auth/view/qr_login_page.dart';
import 'package:nagpur_rider/screens/auth/view/phone_login_page.dart';
import 'package:nagpur_rider/screens/auth/view/phone_otp_verification_page.dart';
import 'package:nagpur_rider/screens/auth/view/register_page.dart';
import 'package:nagpur_rider/screens/dashboard/view/notification_list_page.dart';
import 'package:nagpur_rider/screens/feed_page/model/available_orders.dart';
import 'package:nagpur_rider/screens/feed_page/model/return_orders_list_model.dart';
import 'package:nagpur_rider/screens/feed_page/view/home_page.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/delivery_map/pickup_order_map_page.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/delivery_map/pickup_route_map_page.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/store_pickup_route/map_delivery_page.dart';
import 'package:nagpur_rider/screens/feed_page/view/order_detail/order_details_page.dart';
import 'package:nagpur_rider/screens/feed_page/view/pickup_order/pickup_order_details_page.dart';
import 'package:nagpur_rider/screens/feed_page/view/rider_orders_page.dart';
import 'package:nagpur_rider/screens/pockets/view/pockets_page.dart';
import 'package:nagpur_rider/screens/splash_screen/splash_screen.dart';
import 'package:nagpur_rider/utils/widgets/bottombar.dart';

import '../screens/pockets/cash_collection/view/cash_collection_page.dart';
import '../screens/pockets/cash_collection/view/all_cash_collection_page.dart';
import '../screens/pockets/earnings/view/all_earnings_page.dart';
import '../screens/pockets/earnings/view/earnings_list_page.dart';
import '../screens/pockets/withdrawal/view/withdrawal_history_page.dart';
import '../screens/inactive_delievryboy/view/view_history_of_orders.dart';

import '../screens/auth/widgets/delivery_zone_screen.dart';
import '../screens/feed_page/bloc/order_details_bloc/order_details_bloc.dart';

import '../screens/settings/view/settings.dart';
import '../screens/settings/view/profile_page.dart';
import '../screens/settings/view/profile_widgets/contact_info_page.dart';
import '../screens/settings/view/profile_widgets/delivery_zone_page.dart';
import '../screens/settings/view/profile_widgets/documents_page.dart';
import '../screens/settings/view/profile_widgets/personal_info_page.dart';
import '../screens/settings/view/profile_widgets/vehicle_info_page.dart';
import '../screens/settings/view/profile_widgets/verification_status_page.dart';
import '../screens/settings/view/terms_privacy_page.dart';
import '../screens/dashboard/view/ratings_page.dart';
import '../screens/settings/view/my_orders.dart';
import '../screens/delivery_zones/view/delivery_zone_list_page.dart';
import '../screens/delivery_zones/view/delivery_zone_details_page.dart';
import '../screens/delivery_zones/model/delivery_zone_model.dart';

Page platformPage(Widget child) {
  if (Platform.isIOS) {
    return CupertinoPage(child: child);
  } else {
    return MaterialPage(child: child);
  }
}

class AppRoutes {
  static const String splashScreen = '/';
  static const String login = '/login';
  static const String qrLogin = '/qr-login';
  static const String loginApprovalPending = '/login-approval-pending';
  static const String phoneOtpVerification = '/phone-otp-verification';
  static const String phoneLogin = '/phone-login';
  static const String forgotPassword = '/forgot-password';
  static const String register = '/register';
  static const String home = '/home';
  static const String deliveryZone = '/deliveryZone';
  static const String dashboard = '/dashboard';

  static const String feed = '/feed';
  static const String gigs = '/gigs';
  static const String pockets = '/pockets';
  static const String more = '/settings';

  static const String pickupRouteMap = '/pickup-route-map';
  static const String pickupOrderMap = '/pickup-order-map';
  static const String orderDetails = '/order-details';
  static const String mapDelivery = '/map-delivery';
  static const String profile = '/profile';
  static const String personalInfo = '/personal-info';
  static const String contactInfo = '/contact-info';
  static const String vehicleInfo = '/vehicle-info';
  static const String deliveryZonePage = '/delivery-zone';
  static const String verificationStatus = '/verification-status';
  static const String documents = '/documents';
  static const String earnings = '/earnings';
  static const String allEarnings = '/all-earnings';
  static const String cashCollection = '/cash-collection';
  static const String allCashCollection = '/all-cash-collection';
  static const String withdrawalHistory = '/withdrawal-history';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String viewHistory = '/view-history';
  static const String notificationTest = '/notification-test';
  static const String ratings = '/ratings';
  static const String myOrders = '/my-orders';
  static const String notifications = '/notifications';
  static const String pickupOrderDetails = '/pickup-order-details';
  static const String deliveryZoneList = '/delivery-zone-list';
  static const String deliveryZoneDetails = '/delivery-zone-details';
}

class MyAppRoute {
  static GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splashScreen,

    routes: [
      GoRoute(
        name: 'splashScreen',
        path: AppRoutes.splashScreen,
        pageBuilder: (context, state) => platformPage(SplashScreen()),
      ),

      GoRoute(
        name: 'login',
        path: AppRoutes.login,
        pageBuilder: (context, state) => platformPage(LoginPage()),
      ),

      GoRoute(
        name: 'qrLogin',
        path: AppRoutes.qrLogin,
        pageBuilder: (context, state) => platformPage(const QrLoginPage()),
      ),

      GoRoute(
        name: 'loginApprovalPending',
        path: AppRoutes.loginApprovalPending,
        pageBuilder:
            (context, state) => platformPage(const LoginApprovalPendingPage()),
      ),

      GoRoute(
        name: 'phoneLogin',
        path: AppRoutes.phoneLogin,
        pageBuilder: (context, state) => platformPage(const PhoneLoginPage()),
      ),

      GoRoute(
        name: 'phoneOtpVerification',
        path: AppRoutes.phoneOtpVerification,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return platformPage(
            PhoneOTPVerificationPage(
              verificationId: extra['verificationId'] as String,
              phoneNumber: extra['phoneNumber'] as String,
              isRegistration: extra['isRegistration'] as bool? ?? false,
              registrationData:
                  extra['registrationData'] as Map<String, dynamic>?,
            ),
          );
        },
      ),

      GoRoute(
        name: 'forgotPassword',
        path: AppRoutes.forgotPassword,
        pageBuilder:
            (context, state) => platformPage(const ForgotPasswordPage()),
      ),

      GoRoute(
        name: 'register',
        path: AppRoutes.register,
        pageBuilder: (context, state) => platformPage(RegisterPage()),
      ),

      GoRoute(
        name: 'deliveryZone',
        path: AppRoutes.deliveryZone,
        pageBuilder: (context, state) => platformPage(DeliveryZoneScreen()),
      ),

      GoRoute(
        name: 'dashboard',
        path: AppRoutes.dashboard,
        redirect: (context, state) {
          return AppRoutes.home;
        },
      ),

      GoRoute(
        name: 'pickupRouteMap',
        path: AppRoutes.pickupRouteMap,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final order = params['order'] as Orders;
          final bloc = params['bloc'] as OrderDetailsBloc?;

          return platformPage(PickupRouteMapPage(order: order, bloc: bloc));
        },
      ),

      GoRoute(
        name: 'orderDetails',
        path: AppRoutes.orderDetails,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final orderId = params['orderId'] as int;
          final from = params['from'] as bool;
          final sourceTab = params['sourceTab'] as int?;
          final arrivalConfirmed = params['arrivalConfirmed'] as bool?;
          return platformPage(
            OrderDetailsPageWithBloc(
              orderId: orderId,
              from: from,
              sourceTab: sourceTab,
              arrivalConfirmed: arrivalConfirmed,
            ),
          );
        },
      ),

      GoRoute(
        name: 'pickup-order-details',
        path: AppRoutes.pickupOrderDetails,

        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final returnId = params['returnId'];

          return platformPage(PickupOrderDetailsPage(returnId: returnId));
        },
      ),

      GoRoute(
        name: 'pickupOrderMap',
        path: AppRoutes.pickupOrderMap,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final pickup = params['pickup'] as Pickups;
          final locationType = params['locationType'] as String? ?? 'customer';

          return platformPage(
            PickupOrderMapPage(pickup: pickup, locationType: locationType),
          );
        },
      ),

      GoRoute(
        name: 'mapDelivery',
        path: AppRoutes.mapDelivery,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final order = params['order'] as Orders;
          return platformPage(
            MapDeliveryPage(order: order, currentLat: '0', currentLng: '0'),
          );
        },
      ),

      GoRoute(
        name: 'profile',
        path: AppRoutes.profile,
        pageBuilder: (context, state) => platformPage(const ProfilePage()),
      ),

      GoRoute(
        name: 'personalInfo',
        path: AppRoutes.personalInfo,
        pageBuilder: (context, state) => platformPage(const PersonalInfoPage()),
      ),

      GoRoute(
        name: 'contactInfo',
        path: AppRoutes.contactInfo,
        pageBuilder: (context, state) => platformPage(const ContactInfoPage()),
      ),

      GoRoute(
        name: 'vehicleInfo',
        path: AppRoutes.vehicleInfo,
        pageBuilder: (context, state) => platformPage(const VehicleInfoPage()),
      ),

      GoRoute(
        name: 'deliveryZonePage',
        path: AppRoutes.deliveryZonePage,
        pageBuilder: (context, state) => platformPage(const DeliveryZonePage()),
      ),

      GoRoute(
        name: 'verificationStatus',
        path: AppRoutes.verificationStatus,
        pageBuilder:
            (context, state) => platformPage(const VerificationStatusPage()),
      ),

      GoRoute(
        name: 'documents',
        path: AppRoutes.documents,
        pageBuilder: (context, state) => platformPage(const DocumentsPage()),
      ),

      GoRoute(
        name: 'earnings',
        path: AppRoutes.earnings,
        pageBuilder:
            (context, state) => platformPage(const EarningsListPageWithBloc()),
      ),

      GoRoute(
        name: 'allEarnings',
        path: AppRoutes.allEarnings,
        pageBuilder:
            (context, state) => platformPage(const AllEarningsPageWithBloc()),
      ),

      GoRoute(
        name: 'cashCollection',
        path: AppRoutes.cashCollection,
        pageBuilder:
            (context, state) =>
                platformPage(const CashCollectionPageWithBloc()),
      ),

      GoRoute(
        name: 'allCashCollection',
        path: AppRoutes.allCashCollection,
        pageBuilder:
            (context, state) =>
                platformPage(const AllCashCollectionPageWithBloc()),
      ),

      GoRoute(
        name: 'withdrawalHistory',
        path: AppRoutes.withdrawalHistory,
        pageBuilder:
            (context, state) =>
                platformPage(const WithdrawalHistoryPageWithBloc()),
      ),

      GoRoute(
        name: 'viewHistory',
        path: AppRoutes.viewHistory,
        pageBuilder:
            (context, state) =>
                platformPage(const ViewHistoryOfOrdersWithBloc()),
      ),

      GoRoute(
        name: 'ratings',
        path: AppRoutes.ratings,
        pageBuilder: (context, state) => platformPage(const RatingsPage()),
      ),

      GoRoute(
        name: 'myOrders',
        path: AppRoutes.myOrders,
        pageBuilder:
            (context, state) => platformPage(
              MyOrdersPage(initialTabStatus: state.extra as String?),
            ),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return BottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            name: 'home',
            path: AppRoutes.home,
            pageBuilder: (context, state) {
              return platformPage(const StatisticsHomePage());
            },
          ),

          GoRoute(
            name: 'feed',
            path: AppRoutes.feed,
            pageBuilder: (context, state) {
              final tabIndex = int.tryParse(
                state.uri.queryParameters['tab'] ?? '0',
              );
              return platformPage(RiderOrdersPage(initialTab: tabIndex ?? 0));
            },
          ),

          GoRoute(
            name: 'pockets',
            path: AppRoutes.pockets,
            pageBuilder: (context, state) => platformPage(const PocketsPage()),
          ),

          GoRoute(
            name: 'settings',
            path: AppRoutes.more,
            pageBuilder: (context, state) => platformPage(const MorePage()),
          ),
        ],
      ),

      GoRoute(
        name: 'terms',
        path: AppRoutes.terms,
        pageBuilder:
            (context, state) =>
                platformPage(const TermsPrivacyPage(isTerms: true)),
      ),

      GoRoute(
        name: 'privacy',
        path: AppRoutes.privacy,
        pageBuilder:
            (context, state) =>
                platformPage(const TermsPrivacyPage(isTerms: false)),
      ),

      GoRoute(
        name: 'notifications',
        path: AppRoutes.notifications,
        pageBuilder:
            (context, state) => platformPage(const NotificationListPage()),
      ),

      GoRoute(
        name: 'deliveryZoneList',
        path: AppRoutes.deliveryZoneList,
        pageBuilder: (context, state) {
          final isSelectionMode =
              (state.extra as Map<String, dynamic>?)?['isSelectionMode']
                  as bool? ??
              false;
          return platformPage(
            DeliveryZoneListPage(isSelectionMode: isSelectionMode),
          );
        },
      ),

      GoRoute(
        name: 'deliveryZoneDetails',
        path: '${AppRoutes.deliveryZoneDetails}/:zoneId',
        pageBuilder: (context, state) {
          final zoneId = int.parse(state.pathParameters['zoneId']!);
          final zone = state.extra as DeliveryZoneModel?;
          return platformPage(
            DeliveryZoneDetailsPage(zoneId: zoneId, zone: zone),
          );
        },
      ),
    ],
  );
}
