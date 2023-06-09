import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../blocs/dialog_bloc.dart';
import '../../../../localizations.dart';
import '../../../../model/market.dart';
import '../../../../model/order.dart';
import '../../../../model/swap.dart';
import '../../../../utils/utils.dart';
import '../../../../widgets/custom_simple_dialog.dart';
import '../../../../widgets/auto_scroll_text.dart';

class Filters extends StatefulWidget {
  const Filters({
    this.items,
    this.activeFilters,
    this.onChange,
    this.filter,
    this.showStatus = false,
  });

  final List<dynamic> items;
  final Function(ActiveFilters) onChange;
  final Function filter;
  final ActiveFilters activeFilters;
  final bool showStatus;

  @override
  _FiltersState createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  ActiveFilters _filters;

  @override
  Widget build(BuildContext context) {
    _filters ??= widget.activeFilters;

    return Column(
      children: [
        _buildCoinFilter(Market.SELL),
        const SizedBox(height: 12),
        _buildCoinFilter(Market.BUY),
        const SizedBox(height: 12),
        _buildDateFilter(DateFilterType.START),
        const SizedBox(height: 12),
        _buildDateFilter(DateFilterType.END),
        const SizedBox(height: 12),
        _buildTypeFilter(),
        if (widget.showStatus) ...{
          const SizedBox(height: 12),
          _buildStatusFilter(),
        },
        const SizedBox(height: 20),
        _buildClearAllButton(),
      ],
    );
  }

  Widget _buildClearAllButton() {
    return Row(children: [
      const Expanded(child: SizedBox()),
      TextButton(
        child: Row(
          children: [
            Text(AppLocalizations.of(context).filtersClearAll.toUpperCase()),
            const SizedBox(width: 8),
            Icon(Icons.clear)
          ],
        ),
        onPressed: () {
          setState(() {
            _filters = ActiveFilters();
          });
          widget.onChange(_filters);
        },
      ),
    ]);
  }

  Widget _buildStatusFilter() {
    final Status current = _filters.status;
    final Color color =
        current == null ? Theme.of(context).textTheme.bodyText1.color : null;

    return Row(children: [
      Expanded(
        child: Text(
          AppLocalizations.of(context).filtersStatus + ':',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
      InkWell(
        onTap: () => _openStatusDialog(),
        child: Container(
          width: 100,
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
          decoration: BoxDecoration(
              border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          )),
          child: Row(
            children: [
              Expanded(
                child: AutoScrollText(
                  text: current == null
                      ? AppLocalizations.of(context).filtersAll
                      : current == Status.SWAP_SUCCESSFUL
                          ? AppLocalizations.of(context).filtersSuccessful
                          : AppLocalizations.of(context).filtersFailed,
                  style: TextStyle(color: color),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: color,
              )
            ],
          ),
        ),
      ),
      _buildIndividualClearButtonHelper(
        onPresseed: current == null
            ? null
            : () {
                setState(() {
                  _filters.status = null;
                });
                _filters.matches = widget.filter(widget.items).length;
                widget.onChange(_filters);
              },
      ),
    ]);
  }

  void _openStatusDialog() {
    final Status temp = _filters.status;
    _filters.status = Status.SWAP_SUCCESSFUL;
    final int successfulPredictor = widget.filter(widget.items).length;
    _filters.status = Status.SWAP_FAILED;
    final int failedPredictor = widget.filter(widget.items).length;
    _filters.status = temp;

    dialogBloc.dialog = showDialog<void>(
        context: context,
        builder: (context) {
          return CustomSimpleDialog(
            hasHorizontalPadding: false,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _filters.status = null);
                  _filters.matches = widget.filter(widget.items).length;
                  widget.onChange(_filters);
                  dialogBloc.closeDialog(context);
                },
                child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(AppLocalizations.of(context).filtersAll)),
              ),
              InkWell(
                onTap: () {
                  setState(() => _filters.status = Status.SWAP_SUCCESSFUL);
                  _filters.matches = widget.filter(widget.items).length;
                  widget.onChange(_filters);
                  dialogBloc.closeDialog(context);
                },
                child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(AppLocalizations.of(context).filtersSuccessful),
                        Text(
                          ' ($successfulPredictor)',
                          style: Theme.of(context).textTheme.caption,
                        )
                      ],
                    )),
              ),
              InkWell(
                onTap: () {
                  setState(() => _filters.status = Status.SWAP_FAILED);
                  _filters.matches = widget.filter(widget.items).length;
                  widget.onChange(_filters);
                  dialogBloc.closeDialog(context);
                },
                child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(AppLocalizations.of(context).filtersFailed),
                        Text(
                          ' ($failedPredictor)',
                          style: Theme.of(context).textTheme.caption,
                        )
                      ],
                    )),
              ),
            ],
          );
        }).then((dynamic _) => dialogBloc.dialog = null);
  }

  Widget _buildDateFilter(DateFilterType dateType) {
    final DateTime current =
        dateType == DateFilterType.START ? _filters.start : _filters.end;
    final Color color =
        current == null ? Theme.of(context).textTheme.bodyText1.color : null;

    return Row(children: [
      Expanded(
        child: Text(
          dateType == DateFilterType.START
              ? '${AppLocalizations.of(context).filtersFrom}:'
              : '${AppLocalizations.of(context).filtersTo}:',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
      InkWell(
        onTap: () => _openDateDialog(dateType),
        child: Container(
          width: 100,
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
          decoration: BoxDecoration(
              border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          )),
          child: Row(
            children: [
              Expanded(
                child: AutoScrollText(
                  text:
                      current == null ? '-' : DateFormat.yMd().format(current),
                  style: TextStyle(color: color),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: color,
              )
            ],
          ),
        ),
      ),
      _buildIndividualClearButtonHelper(
        onPresseed: current == null
            ? null
            : () {
                setState(() {
                  dateType == DateFilterType.START
                      ? _filters.start = null
                      : _filters.end = null;
                });
                _filters.matches = widget.filter(widget.items).length;
                widget.onChange(_filters);
              },
      )
    ]);
  }

  Future<void> _openDateDialog(DateFilterType dateType) async {
    final bool typeIsStart = dateType == DateFilterType.START;

    final DateTime first = DateTime.parse('20100101');
    final DateTime today = DateTime.now();
    final date = await showDatePicker(
        context: context,
        firstDate: typeIsStart ? first : (_filters.start ?? first),
        lastDate: typeIsStart ? (_filters.end ?? today) : today,
        initialDate: (typeIsStart ? _filters.start : _filters.end) ??
            (_filters.end ?? today),
        helpText: (typeIsStart
                ? AppLocalizations.of(context).filtersFrom
                : AppLocalizations.of(context).filtersTo)
            .toUpperCase());

    if (date is DateTime) {
      setState(() {
        dateType == DateFilterType.START
            ? _filters.start = date
            : _filters.end = date
                .add(const Duration(days: 1) - const Duration(milliseconds: 1));
      });
      _filters.matches = widget.filter(widget.items).length;
      widget.onChange(_filters);
    }
  }

  Widget _buildTypeFilter() {
    final OrderType current = widget.activeFilters.type;
    final Color color =
        current == null ? Theme.of(context).textTheme.bodyText1.color : null;

    return Row(children: [
      Expanded(
        child: Text(
          AppLocalizations.of(context).filtersType + ':',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
      InkWell(
        onTap: () => _openTypeDialog(),
        child: Container(
          width: 100,
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
          decoration: BoxDecoration(
              border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          )),
          child: Row(
            children: [
              Expanded(
                child: AutoScrollText(
                  text: current == null
                      ? AppLocalizations.of(context).filtersAll
                      : current == OrderType.MAKER
                          ? AppLocalizations.of(context).filtersMaker
                          : AppLocalizations.of(context).filtersTaker,
                  style: TextStyle(color: color),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: color,
              )
            ],
          ),
        ),
      ),
      _buildIndividualClearButtonHelper(
        onPresseed: current == null
            ? null
            : () {
                setState(() {
                  _filters.type = null;
                });
                _filters.matches = widget.filter(widget.items).length;
                widget.onChange(_filters);
              },
      ),
    ]);
  }

  void _openTypeDialog() {
    final OrderType temp = _filters.type;
    _filters.type = OrderType.MAKER;
    final int makerPredictor = widget.filter(widget.items).length;
    _filters.type = OrderType.TAKER;
    final int takerPredictor = widget.filter(widget.items).length;
    _filters.type = temp;

    dialogBloc.dialog = showDialog<void>(
        context: context,
        builder: (context) {
          return CustomSimpleDialog(
            hasHorizontalPadding: false,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _filters.type = null);
                  _filters.matches = widget.filter(widget.items).length;
                  widget.onChange(_filters);
                  dialogBloc.closeDialog(context);
                },
                child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(AppLocalizations.of(context).all)),
              ),
              InkWell(
                onTap: () {
                  setState(() => _filters.type = OrderType.MAKER);
                  _filters.matches = widget.filter(widget.items).length;
                  widget.onChange(_filters);
                  dialogBloc.closeDialog(context);
                },
                child: Container(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(AppLocalizations.of(context).filtersMaker),
                        Text(
                          ' ($makerPredictor)',
                          style: Theme.of(context).textTheme.caption,
                        )
                      ],
                    )),
              ),
              InkWell(
                onTap: () {
                  setState(() => _filters.type = OrderType.TAKER);
                  _filters.matches = widget.filter(widget.items).length;
                  widget.onChange(_filters);
                  dialogBloc.closeDialog(context);
                },
                child: Container(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(AppLocalizations.of(context).filtersTaker),
                        Text(
                          ' ($takerPredictor)',
                          style: Theme.of(context).textTheme.caption,
                        )
                      ],
                    )),
              ),
            ],
          );
        }).then((dynamic _) => dialogBloc.dialog = null);
  }

  Widget _buildCoinFilter(Market market) {
    final String current =
        market == Market.SELL ? _filters.sellCoin : _filters.receiveCoin;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            market == Market.SELL
                ? AppLocalizations.of(context).filtersSell + ':'
                : AppLocalizations.of(context).filtersReceive + ':',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        _buildCoinSelect(market),
        _buildIndividualClearButtonHelper(
          onPresseed: current == null
              ? null
              : () {
                  setState(() {
                    market == Market.SELL
                        ? _filters.sellCoin = null
                        : _filters.receiveCoin = null;
                  });
                  _filters.matches = widget.filter(widget.items).length;
                  widget.onChange(_filters);
                },
        )
      ],
    );
  }

  Widget _buildCoinSelect(Market market) {
    final String current =
        market == Market.SELL ? _filters.sellCoin : _filters.receiveCoin;
    final Color color =
        current == null ? Theme.of(context).textTheme.bodyText1.color : null;

    return InkWell(
      onTap: () => _openCoinsDialog(market),
      child: Container(
        width: 100,
        padding: EdgeInsets.fromLTRB(0, 6, 0, 6),
        decoration: BoxDecoration(
            border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.secondary.withAlpha(150),
            width: 1,
          ),
        )),
        child: Row(
          children: [
            CircleAvatar(
              radius: 7,
              backgroundColor: color?.withAlpha(50),
              backgroundImage:
                  current != null ? AssetImage(getCoinIconPath(current)) : null,
            ),
            SizedBox(width: 4),
            Expanded(
              child: AutoScrollText(
                text: current ?? AppLocalizations.of(context).filtersAll,
                style: TextStyle(color: color),
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: color,
            )
          ],
        ),
      ),
    );
  }

  void _openCoinsDialog(Market market) {
    final List<String> coins = _getCoins(market);

    final List<Widget> items = coins.map((String coin) {
      final String temp =
          market == Market.SELL ? _filters.sellCoin : _filters.receiveCoin;
      market == Market.SELL
          ? _filters.sellCoin = coin
          : _filters.receiveCoin = coin;
      final int predictor = widget.filter(widget.items).length;
      market == Market.SELL
          ? _filters.sellCoin = temp
          : _filters.receiveCoin = temp;

      return InkWell(
        onTap: () {
          setState(() {
            market == Market.SELL
                ? _filters.sellCoin = coin
                : _filters.receiveCoin = coin;
          });
          _filters.matches = widget.filter(widget.items).length;
          widget.onChange(_filters);
          dialogBloc.closeDialog(context);
        },
        child: Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 8,
                backgroundImage: AssetImage(getCoinIconPath(coin)),
              ),
              SizedBox(width: 4),
              Text(coin),
              SizedBox(width: 4),
              Text(
                ' ($predictor)',
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
        ),
      );
    }).toList();

    items.insert(
        0,
        InkWell(
          onTap: () {
            setState(() {
              market == Market.SELL
                  ? _filters.sellCoin = null
                  : _filters.receiveCoin = null;
            });
            _filters.matches = widget.filter(widget.items).length;
            widget.onChange(_filters);
            dialogBloc.closeDialog(context);
          },
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 8,
                    backgroundColor: Theme.of(context).highlightColor),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).filtersAll),
              ],
            ),
          ),
        ));

    dialogBloc.dialog = showDialog<void>(
        context: context,
        builder: (context) {
          return CustomSimpleDialog(
            hasHorizontalPadding: false,
            children: items,
          );
        }).then((dynamic _) => dialogBloc.dialog = null);
  }

  List<String> _getCoins(Market market) {
    final List<String> list = [];

    for (dynamic item in widget.items) {
      if (item is Order) {
        String coin;
        switch (market) {
          case Market.SELL:
            coin = item.orderType == OrderType.MAKER ? item.base : item.rel;
            break;
          case Market.BUY:
            coin = item.orderType == OrderType.MAKER ? item.rel : item.base;
            break;
        }
        if (!list.contains(coin)) list.add(coin);
      } else if (item is Swap) {
        String coin;
        switch (market) {
          case Market.SELL:
            coin = item.isMaker ? item.makerAbbr : item.takerAbbr;
            break;
          case Market.BUY:
            coin = item.isMaker ? item.takerAbbr : item.makerAbbr;
            break;
        }
        if (!list.contains(coin)) list.add(coin);
      }
    }

    return list;
  }

  Widget _buildIndividualClearButtonHelper(
      {@required VoidCallback onPresseed}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.clear),
      iconSize: 12,
      splashRadius: 12,
      constraints: BoxConstraints.tightFor(width: 24, height: 24),
      onPressed: onPresseed,
    );
  }
}

class ActiveFilters {
  ActiveFilters({
    this.matches,
    this.sellCoin,
    this.receiveCoin,
    this.start,
    this.end,
    this.type,
    this.status,
  });

  int matches;
  String sellCoin;
  String receiveCoin;
  DateTime start;
  DateTime end;
  OrderType type;
  Status status;

  bool get anyActive =>
      sellCoin != null ||
      receiveCoin != null ||
      type != null ||
      start != null ||
      end != null ||
      status != null;
}

enum DateFilterType { START, END }
