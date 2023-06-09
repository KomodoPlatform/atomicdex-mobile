import 'package:flutter/material.dart';
import '../../../../../../blocs/swap_bloc.dart';
import '../../../../../../localizations.dart';
import '../../../../../../model/order_book_provider.dart';
import '../../../../../markets/coin_select.dart';
import '../../../../../../widgets/custom_simple_dialog.dart';
import 'package:provider/provider.dart';

class InProgressPopup extends StatefulWidget {
  const InProgressPopup({Key key, this.onDone}) : super(key: key);

  final Function onDone;

  @override
  _InProgressPopupState createState() => _InProgressPopupState();
}

class _InProgressPopupState extends State<InProgressPopup> {
  OrderBookProvider orderBookProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    orderBookProvider = Provider.of<OrderBookProvider>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await orderBookProvider.subscribeDepth(
          swapBloc.sellCoinBalance.coin.abbr, CoinType.base);
      widget.onDone();
    });

    return CustomSimpleDialog(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(
                width: 16,
              ),
              Text(
                AppLocalizations.of(context).loadingOrderbook,
                style: Theme.of(context).textTheme.bodyText2,
              )
            ],
          ),
        ),
      ],
    );
  }
}
