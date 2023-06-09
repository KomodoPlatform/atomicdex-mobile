import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../localizations.dart';
import '../../../../model/order.dart';
import '../../../dex/orders/maker/maker_order_details_page.dart';
import '../../../dex/orders/maker/order_fill.dart';
import '../../../../services/db/database.dart';
import '../../../../utils/utils.dart';
import '../../../../widgets/cancel_order_dialog.dart';

class BuildItemMaker extends StatefulWidget {
  const BuildItemMaker(this.order);

  final Order order;

  @override
  _BuildItemMakerState createState() => _BuildItemMakerState();
}

class _BuildItemMakerState extends State<BuildItemMaker> {
  bool isNoteExpanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) =>
                MakerOrderDetailsPage(widget.order.uuid),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            widget.order.base,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 4),
                          _buildIcon(widget.order.base),
                        ],
                      ),
                      Text(
                        '~${formatPrice(widget.order.baseAmount, 8)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Icon(Icons.swap_horiz),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _buildIcon(widget.order.rel),
                          const SizedBox(width: 4),
                          Text(
                            widget.order.rel,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      Text(
                        '~${formatPrice(widget.order.relAmount, 8)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    DateFormat('dd MMM yyyy HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            widget.order.createdAt * 1000)),
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              FutureBuilder<String>(
                  future: Db.getNote('maker_${widget.order.uuid}'),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox();
                    }

                    return InkWell(
                      onTap: () {
                        setState(() {
                          isNoteExpanded = !isNoteExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                snapshot.data,
                                style: Theme.of(context).textTheme.bodyText1,
                                maxLines: isNoteExpanded ? null : 1,
                                overflow: isNoteExpanded
                                    ? null
                                    : TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OrderFill(
                    widget.order,
                    size: 15,
                  ),
                  widget.order.cancelable
                      ? SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed: () => showCancelConfirmation(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(24)),
                                color: Colors.transparent,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                      AppLocalizations.of(context)
                                          .cancel
                                          .toUpperCase(),
                                      style:
                                          Theme.of(context).textTheme.bodyText1)
                                ],
                              ),
                            ),
                          ),
                        )
                      : SizedBox()
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCancelConfirmation(BuildContext mContext) {
    showCancelOrderDialog(
      context: mContext,
      key: const Key('settings-cancel-order-yes'),
      uuid: widget.order.uuid,
    );
  }

  Widget _buildIcon(String coin) {
    return CircleAvatar(
      maxRadius: 12,
      backgroundColor: Colors.transparent,
      backgroundImage: AssetImage(getCoinIconPath(coin)),
    );
  }
}
