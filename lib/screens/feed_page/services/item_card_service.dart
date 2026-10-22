import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/available_orders.dart';
import '../bloc/items_collected_bloc/items_collected_bloc.dart';
import '../bloc/items_collected_bloc/items_collected_state.dart';
import '../widgets/orderdetails_widgets/item_card.dart';

class ItemCardService {
  static Widget buildItemCard({
    required BuildContext context,
    required Items item,
    required bool from,
    required Set<String> collectedItems,
    required Set<String> deliveredItems,
    required Set<String> otpVerifiedItems,
    required String? currentProcessingItemId,
    required Orders? fetchedOrder,
    required VoidCallback onCollect,
    required VoidCallback onDelivered,
    required VoidCallback onReachedDestination,
    required Function(Items) onItemOtpTap,
    bool hideDeliverButton = false,
  }) {
    return BlocConsumer<ItemsCollectedBloc, ItemsCollectedState>(
      listener: (context, state) {
        // No need to handle state changes here since main BlocConsumer handles it
      },
      builder: (context, state) {
        // Check if item is collected/delivered based strictly on API status
        final bool isCollected =
            item.status?.toLowerCase() == 'collected' ||
            item.status?.toLowerCase() == 'delivered';
        final bool isDelivered = item.status?.toLowerCase() == 'delivered';

        final bool requiresOtp = item.product?.requiresOtp == 1;

        // Check if this specific item is loading OR if all items are being collected
        final bool isCollectingAll = currentProcessingItemId == 'collecting_all' && !isCollected;
        final bool isLoading = (currentProcessingItemId == item.id.toString()) || isCollectingAll;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ItemCard(
            item: item,
            from: from,
            isCollected: isCollected,
            isDelivered: isDelivered,
            isLoading: isLoading,
            orderStatus: fetchedOrder?.status,
            isOtpVerified: item.otpVerified == 1,
            onTap:
                (isCollected && requiresOtp && !isDelivered && !hideDeliverButton)
                    ? () => onItemOtpTap(item)
                    : null,
            onCollect: onCollect,
            onDelivered: onDelivered,
            onReachedDestination: onReachedDestination,
            hideDeliverButton: hideDeliverButton,
          ),
        );
      },
    );
  }
}
