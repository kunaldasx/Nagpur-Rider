import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';

import '../../../../../utils/widgets/toast_message.dart';
import '../../../bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import '../../../bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';
import '../../../model/return_orders_list_model.dart';
import '../../../repo/return_order_repo.dart';

/// A verified handoff, or the server's current pickup after a stale transition.
class ReturnHandoffResult {
  final Pickups pickup;
  final String message;
  final bool verified;

  const ReturnHandoffResult({
    required this.pickup,
    required this.message,
    required this.verified,
  });
}

/// All return status controls use this dialog; a swipe alone never updates status.
Future<ReturnHandoffResult?> showReturnHandoffDialog(
  BuildContext context, {
  required Pickups pickup,
  required String status,
}) async {
  final result = await showDialog<ReturnHandoffResult>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) =>
            ReturnHandoffDialog(returnId: pickup.id.toString(), status: status),
  );
  if (result == null || !context.mounted) return result;
  ToastManager.show(
    context: context,
    message: result.message,
    type: result.verified ? ToastType.success : ToastType.error,
  );
  // A map can also be opened outside the orders dashboard.
  final listBloc = context.read<PickupOrderListBloc?>();
  listBloc?.add(FetchPickupOrders(forceRefresh: true));
  return result;
}

class ReturnHandoffDialog extends StatefulWidget {
  final String returnId;
  final String status;
  final ReturnOrderRepo? repository;

  const ReturnHandoffDialog({
    super.key,
    required this.returnId,
    required this.status,
    this.repository,
  });

  @override
  State<ReturnHandoffDialog> createState() => _ReturnHandoffDialogState();
}

class _ReturnHandoffDialogState extends State<ReturnHandoffDialog> {
  final _form = GlobalKey<FormState>();
  final _otp = TextEditingController();
  late final UpdateReturnOrderStatusBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = UpdateReturnOrderStatusBloc(repository: widget.repository);
  }

  @override
  void dispose() {
    _otp.dispose();
    _bloc.close();
    super.dispose();
  }

  void _submit() {
    if (_bloc.state is UpdateReturnOrderStatusLoading ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    _bloc.add(
      UpdateReturnOrderStatus(
        returnId: widget.returnId,
        status: widget.status,
        otp: _otp.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customer = widget.status == 'picked_up';
    return BlocConsumer<
      UpdateReturnOrderStatusBloc,
      UpdateReturnOrderStatusState
    >(
      bloc: _bloc,
      listener: (context, state) {
        if (state is UpdateReturnOrderStatusSuccess) {
          Navigator.pop(
            context,
            ReturnHandoffResult(
              pickup: state.pickup,
              message: state.message,
              verified: true,
            ),
          );
        } else if (state is UpdateReturnOrderStatusFailed &&
            state.pickup != null) {
          Navigator.pop(
            context,
            ReturnHandoffResult(
              pickup: state.pickup!,
              message: state.error,
              verified: false,
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is UpdateReturnOrderStatusLoading;
        return PopScope(
          canPop: !loading,
          child: AlertDialog(
            scrollable: true,
            title: Text(
              customer
                  ? l10n.returnCustomerOtpTitle
                  : l10n.returnSellerOtpTitle,
            ),
            content: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    customer
                        ? l10n.returnCustomerOtpHelp
                        : l10n.returnSellerOtpHelp,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('return_otp_input'),
                    controller: _otp,
                    enabled: !loading,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(labelText: l10n.returnOtpLabel),
                    validator:
                        (value) =>
                            RegExp(r'^[0-9]{6}$').hasMatch(value ?? '')
                                ? null
                                : l10n.returnOtpInvalid,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (state is UpdateReturnOrderStatusFailed) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error,
                      key: const ValueKey('return_otp_error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const ValueKey('return_cancel_otp'),
                onPressed: loading ? null : () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const ValueKey('return_verify_otp'),
                onPressed: loading ? null : _submit,
                child:
                    loading
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.returnVerifyingOtp),
                          ],
                        )
                        : Text(l10n.returnVerifyOtp),
              ),
            ],
          ),
        );
      },
    );
  }
}
