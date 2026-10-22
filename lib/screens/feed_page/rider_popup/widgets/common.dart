import 'package:flutter/material.dart';
import 'package:nagpur_rider/config/colors.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/utils/currency_formatter.dart';
import 'package:nagpur_rider/utils/services/phone_service.dart';

/// Pieces shared by the incoming-order card and the bag scan panel.

bool isDarkOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color popupSurface(BuildContext context) =>
    isDarkOf(context) ? AppColors.darkCardColor : Colors.white;

Color popupMutedSurface(BuildContext context) =>
    isDarkOf(context) ? AppColors.darkBackgroundColor : const Color(0xFFF4F6FB);

Color popupOutline(BuildContext context) =>
    isDarkOf(context) ? AppColors.darkBorderColor : AppColors.borderColor;

String paymentLabel(String method) {
  switch (method.toLowerCase()) {
    case 'cod':
      return 'Cash on delivery';
    case '':
      return '—';
    default:
      return method[0].toUpperCase() + method.substring(1);
  }
}

String formatPopupAmount(BuildContext context, num amount) {
  try {
    return CurrencyFormatter.formatAmount(context, amount);
  } catch (_) {
    // No SystemSettingsBloc above (e.g. tests).
    return '₹$amount';
  }
}

/// Rounded section with a small caps title.
class PopupSection extends StatelessWidget {
  final String title;
  final Widget child;

  const PopupSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: popupMutedSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: popupOutline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// A name with an optional call button.
class ContactRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String phone;
  final String? subtitle;

  const ContactRow({
    super.key,
    required this.icon,
    required this.name,
    required this.phone,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (phone.isNotEmpty)
                  Text(phone, style: theme.textTheme.bodySmall),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton.filledTonal(
              tooltip: 'Call',
              visualDensity: VisualDensity.compact,
              onPressed: () => PhoneService.makePhoneCall(phone),
              icon: const Icon(Icons.call, size: 18),
            ),
        ],
      ),
    );
  }
}

/// One assigned bag: its barcode and whether it's been scanned.
class BagRow extends StatelessWidget {
  final RiderSellerOrder sellerOrder;

  const BagRow({super.key, required this.sellerOrder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bag = sellerOrder.bag!;
    final done = bag.isPickedUp;
    final color = done ? Colors.green.shade600 : AppColors.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: popupSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.shopping_bag_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bag.hasKnownBarcode)
                  SelectableText(
                    bag.barcode,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  Text(
                    done ? 'Bag scanned' : 'Sealed bag · barcode on the bag',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (sellerOrder.sellerName.isNotEmpty)
                  Text(
                    sellerOrder.sellerName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              done ? 'Picked up' : 'To scan',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PopupItemRow extends StatelessWidget {
  final RiderPopupItem item;

  const PopupItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: popupOutline(context))),
      ),
      child: Row(
        children: [
          _ItemThumbnail(imageUrl: item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    if (item.variantName.isNotEmpty) item.variantName,
                    'Qty ${item.quantity}',
                    if (item.storeName.isNotEmpty) item.storeName,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatPopupAmount(context, item.subtotal),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemThumbnail extends StatelessWidget {
  final String imageUrl;

  const _ItemThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      Icons.inventory_2_outlined,
      color: Theme.of(context).hintColor,
    );
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: popupOutline(context)),
        color: Theme.of(context).colorScheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child:
          imageUrl.isEmpty
              ? placeholder
              : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
    );
  }
}

class PopupPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const PopupPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.primaryColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class PopupOutlinedButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  const PopupOutlinedButton({
    super.key,
    this.label,
    this.icon,
    this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkOf(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon),
        if (icon != null && label != null) const SizedBox(width: 6),
        if (label != null)
          Flexible(
            child: Text(
              label!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black87,
          side: BorderSide(
            color: isDark ? AppColors.darkBorderColor : Colors.grey.shade400,
          ),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child:
            tooltip != null ? Tooltip(message: tooltip!, child: child) : child,
      ),
    );
  }
}

class PopupBottomBar extends StatelessWidget {
  final Widget child;

  const PopupBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: popupMutedSurface(context),
        border: Border(top: BorderSide(color: popupOutline(context))),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
