import 'package:flutter/material.dart';
import '../blocs/dialog_bloc.dart';
import '../blocs/orders_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/swap_bloc.dart';
import '../localizations.dart';
import '../widgets/custom_simple_dialog.dart';

void showCancelOrderDialog({BuildContext context, Key key, String uuid}) {
  if (!settingsBloc.showCancelOrderDialog) {
    ordersBloc.cancelOrder(uuid);
    return;
  }
  bool askCancelOrderAgain = true;
  dialogBloc.dialog = showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return StreamBuilder<List<String>>(
              initialData: swapBloc.currentSwaps,
              stream: swapBloc.outCurrentSwaps,
              builder: (context, snapshot) {
                return CustomSimpleDialog(
                  title: Row(
                    children: <Widget>[
                      Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      Text(AppLocalizations.of(context).cancelOrder),
                    ],
                  ),
                  children: <Widget>[
                    Text(AppLocalizations.of(context).confirmCancel),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, top: 6.0),
                      child: Text(AppLocalizations.of(context).noteOnOrder),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          height: 24.0,
                          width: 24.0,
                          child: Checkbox(
                              key: const Key('cancel-order-ask-again'),
                              value: !askCancelOrderAgain,
                              onChanged: (val) {
                                setState(() {
                                  askCancelOrderAgain = !askCancelOrderAgain;
                                });
                              }),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                askCancelOrderAgain = !askCancelOrderAgain;
                              });
                            },
                            child: Text(
                                AppLocalizations.of(context).dontAskAgain)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          key: const Key('settings-cancel-order-no'),
                          onPressed: () => dialogBloc.closeDialog(context),
                          child: Text(
                            AppLocalizations.of(context).no,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          key: key ?? const Key('confirm-button-key'),
                          onPressed: snapshot.data.contains(uuid)
                              ? null
                              : () {
                                  settingsBloc.setShowCancelOrderDialog(
                                      askCancelOrderAgain);
                                  dialogBloc.closeDialog(context);
                                  ordersBloc.cancelOrder(uuid);
                                },
                          child: Text(
                            AppLocalizations.of(context).yes,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              });
        });
      }).then((dynamic _) => dialogBloc.dialog = null);
}
