import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/services/phone_service.dart';
import '../../../model/available_orders.dart';

class ShippingDetailsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ShippingDetailsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.h),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomText(
                      text: AppLocalizations.of(context)!.shippingDetails,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
            ),
            Padding(
              padding: EdgeInsets.all(16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.name,
                    order.shippingName ?? 'N/A',
                  ),
                  _buildPhoneRow(context),
                  _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.address,
                    _formatAddress(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAddress() {
    final parts = [order.shippingAddress1, order.shippingAddress2]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  Widget _buildPhoneRow(BuildContext context) {
    final phone = order.shippingPhone?.trim() ?? '';
    if (phone.isEmpty) {
      return _buildDetailRow(
        context,
        AppLocalizations.of(context)!.phone,
        'N/A',
      );
    }

    return InkWell(
      onTap: () => _callCustomer(context, phone),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            CustomText(
              text: AppLocalizations.of(context)!.phone,
              fontSize: 14.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: CustomText(
                text: phone,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                textAlign: TextAlign.end,
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.call, color: Colors.white, size: 18.sp),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callCustomer(BuildContext context, String phone) async {
    try {
      await PhoneService.makePhoneCall(phone);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phone')));
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: label,
            fontSize: 14.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: CustomText(
              text: value,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
