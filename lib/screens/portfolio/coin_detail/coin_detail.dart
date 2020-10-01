import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komodo_dex/blocs/coin_detail_bloc.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/blocs/main_bloc.dart';
import 'package:komodo_dex/blocs/settings_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/cex_provider.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/model/error_code.dart';
import 'package:komodo_dex/model/error_string.dart';
import 'package:komodo_dex/model/get_send_raw_transaction.dart';
import 'package:komodo_dex/model/get_withdraw.dart';
import 'package:komodo_dex/model/rewards_provider.dart';
import 'package:komodo_dex/model/send_raw_transaction_response.dart';
import 'package:komodo_dex/model/transaction_data.dart';
import 'package:komodo_dex/model/transactions.dart';
import 'package:komodo_dex/model/withdraw_response.dart';
import 'package:komodo_dex/screens/authentification/lock_screen.dart';
import 'package:komodo_dex/screens/portfolio/coin_detail/steps_withdraw.dart/amount_address_step/amount_address_step.dart';
import 'package:komodo_dex/screens/portfolio/coin_detail/steps_withdraw.dart/build_confirmation_step.dart';
import 'package:komodo_dex/screens/portfolio/coin_detail/steps_withdraw.dart/success_step.dart';
import 'package:komodo_dex/screens/portfolio/rewards_page.dart';
import 'package:komodo_dex/screens/portfolio/transaction_detail.dart';
import 'package:komodo_dex/services/mm.dart';
import 'package:komodo_dex/services/mm_service.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:komodo_dex/widgets/buildRedDot.dart';
import 'package:komodo_dex/widgets/photo_widget.dart';
import 'package:komodo_dex/widgets/secondary_button.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class CoinDetail extends StatefulWidget {
  const CoinDetail({
    this.coinBalance,
    this.isSendIsActive = false,
  });

  final CoinBalance coinBalance;
  final bool isSendIsActive;

  @override
  _CoinDetailState createState() => _CoinDetailState();
}

class _CoinDetailState extends State<CoinDetail> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final FocusNode _focus = FocusNode();
  BuildContext mainContext;
  String fromId;
  bool isExpanded = false;
  bool isLoading = false;
  bool loadingWithdrawDialog = true;
  bool isSendIsActive;
  double elevationHeader = 0.0;
  int currentIndex = 0;
  int limit = 10;
  CoinBalance currentCoinBalance;
  NumberFormat f = NumberFormat('###,###.0#');
  List<Widget> listSteps = <Widget>[];
  Timer timer;
  bool isDeleteLoading = false;
  CexProvider cexProvider;
  bool _shouldRefresh = false;
  bool _isWaiting = false;
  RewardsProvider rewardsProvider;
  Transaction latestTransaction;

  @override
  void initState() {
    isSendIsActive = widget.isSendIsActive;
    currentCoinBalance = widget.coinBalance;
    if (isSendIsActive) {
      setState(() {
        isExpanded = true;
      });
    }
    currentIndex = 0;
    setState(() {
      isLoading = true;
    });
    coinsBloc
        .updateTransactions(currentCoinBalance.coin, limit, null)
        .then((_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
    coinsBloc
        .getLatestTransaction(currentCoinBalance.coin)
        .then((dynamic transactions) {
      if (transactions is Transactions) {
        final Transactions tr = transactions;
        final t = tr.result.transactions[0];
        if (t != null) latestTransaction = t;
      }
    });
    _amountController.addListener(onChange);
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          isLoading = true;
        });
        coinsBloc
            .updateTransactions(currentCoinBalance.coin, limit, fromId)
            .then((_) {
          setState(() {
            isLoading = false;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    if (!isDeleteLoading) {
      coinsBloc.updateCoinBalances();
    }
    _amountController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    coinsBloc.resetTransactions();
    if (timer != null) {
      timer.cancel();
    }
    mainBloc.isUrlLaucherIsOpen = false;
    coinsDetailBloc.resetCustomFee();
    super.dispose();
  }

  void onChange() {
    final String text = _amountController.text.replaceAll(',', '.');
    if (text.isNotEmpty) {
      setState(() {
        if (currentCoinBalance != null &&
            text.isNotEmpty &&
            double.parse(text) >
                double.parse(currentCoinBalance.balance.getBalance())) {
          setMaxValue();
        }
      });
    }
  }

  Future<void> setMaxValue() async {
    _focus.unfocus();
    setState(() {
      _amountController.text = currentCoinBalance.balance.getBalance();
    });
    await Future<dynamic>.delayed(const Duration(milliseconds: 0), () {
      setState(() {
        FocusScope.of(context).requestFocus(_focus);
      });
    });
    coinsDetailBloc.setAmountToSend(_amountController.text);
  }

  @override
  Widget build(BuildContext context) {
    if (listSteps.isEmpty) {
      initSteps();
    }
    cexProvider ??= Provider.of<CexProvider>(context);
    rewardsProvider ??= Provider.of<RewardsProvider>(context);

    return LockScreen(
      context: context,
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          elevation: elevationHeader,
          actions: <Widget>[
            IconButton(
              key: const Key('coin-deactivate'),
              icon: isDeleteLoading
                  ? Container(
                      height: 20,
                      width: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.5,
                      ),
                    )
                  : Icon(Icons.delete),
              onPressed: () async {
                setState(() {
                  isDeleteLoading = true;
                });
                showConfirmationRemoveCoin(context, widget.coinBalance.coin)
                    .then((_) {
                  setState(() {
                    isDeleteLoading = false;
                  });
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () async {
                mainBloc.isUrlLaucherIsOpen = true;
                await Share.share(AppLocalizations.of(context).shareAddress(
                    currentCoinBalance.coin.name,
                    currentCoinBalance.balance.address));
              },
            )
          ],
          title: Row(
            children: <Widget>[
              PhotoHero(
                tag:
                    'assets/${currentCoinBalance.balance.coin.toLowerCase()}.png',
                radius: 16,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(currentCoinBalance.coin.name.toUpperCase()),
            ],
          ),
          centerTitle: false,
          backgroundColor: Color(int.parse(currentCoinBalance.coin.colorCoin)),
        ),
        body: Builder(builder: (BuildContext context) {
          mainContext = context;
          return Column(
            children: <Widget>[
              _buildForm(),
              _buildHeaderCoinDetail(context),
              _shouldRefresh ? _buildNewTransactionsButton() : const SizedBox(),
              _buildSyncChain(),
              _buildTransactionsList(context),
            ],
          );
        }),
      ),
    );
  }

  bool isRefresh = false;

  Widget _buildSyncChain() {
    return StreamBuilder<dynamic>(
        stream: coinsBloc.outTransactions,
        initialData: coinsBloc.transactions,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData && snapshot.data is Transactions) {
            final Transactions tx = snapshot.data;
            final String syncState =
                '${StateOfSync.InProgress.toString().substring(StateOfSync.InProgress.toString().indexOf('.') + 1)}';
            if (tx.result != null &&
                tx.result.syncStatus != null &&
                tx.result.syncStatus.state != null) {
              timer ??= Timer.periodic(const Duration(seconds: 3), (_) async {
                final dynamic transactions = await coinsBloc
                    .getLatestTransaction(currentCoinBalance.coin);
                Transaction newTr;
                if (transactions is Transactions) {
                  final Transactions tr = transactions;
                  final t = tr.result.transactions[0];
                  if (t != null) newTr = t;
                }

                if (_isWaiting) {
                  _refresh();
                } else if (_scrollController.position.pixels == 0.0) {
                  _refresh();
                } else if (latestTransaction == null ||
                    latestTransaction.internalId != newTr.internalId) {
                  _shouldRefresh = true;
                }

                latestTransaction = newTr;
              });

              if (tx.result.syncStatus.state == syncState) {
                String txLeft;
                if (widget.coinBalance.coin.swapContractAddress.isNotEmpty) {
                  txLeft =
                      tx.result.syncStatus.additionalInfo.blocksLeft.toString();
                } else {
                  txLeft = tx.result.syncStatus.additionalInfo.transactionsLeft
                      .toString();
                }
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Theme.of(context).backgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Center(
                          child: Container(
                        height: 20,
                        width: 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1,
                        ),
                      )),
                      const SizedBox(
                        width: 8,
                      ),
                      const Text('Loading...'),
                      Expanded(
                        child: Container(),
                      ),
                      Text(
                          widget.coinBalance.coin.swapContractAddress.isNotEmpty
                              ? 'Syncing $txLeft TXs'
                              : 'Transactions left $txLeft'),
                    ],
                  ),
                );
              }
            }
          }
          return Container();
        });
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        backgroundColor: Theme.of(context).backgroundColor,
        color: Theme.of(context).accentColor,
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          children: <Widget>[
            StreamBuilder<dynamic>(
                stream: coinsBloc.outTransactions,
                initialData: coinsBloc.transactions,
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    _isWaiting = true;
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    _isWaiting = false;
                  }
                  if (snapshot.data is Transactions) {
                    final Transactions transactions = snapshot.data;
                    final String syncState =
                        '${StateOfSync.InProgress.toString().substring(StateOfSync.InProgress.toString().indexOf('.') + 1)}';

                    if (snapshot.hasData &&
                        transactions.result != null &&
                        transactions.result.transactions != null) {
                      if (transactions.result.transactions.isNotEmpty) {
                        //@Slyris plz clean up
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          child: _buildTransactions(
                              context, transactions.result.transactions),
                        );
                      } else if (transactions.result.transactions.isEmpty &&
                          !(transactions.result.syncStatus.state ==
                              syncState)) {
                        return Center(
                            child: Text(
                          AppLocalizations.of(context).noTxs,
                          style: Theme.of(context).textTheme.body2,
                        ));
                      }
                    }
                  } else if (snapshot.data is ErrorCode &&
                      snapshot.data.error != null) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Text(
                        snapshot.data.error.message,
                        style: Theme.of(context).textTheme.body2,
                        textAlign: TextAlign.center,
                      )),
                    );
                  }
                  return Container();
                })
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await coinsBloc.updateTransactions(currentCoinBalance.coin, limit, null);
    setState(() {
      _shouldRefresh = false;
    });
  }

  Widget _buildTransactions(
      BuildContext context, List<Transaction> transactionsData) {
    final List<Widget> transactionsWidget = transactionsData
        .map((Transaction transaction) =>
            _buildItemTransaction(transaction, context))
        .toList();

    transactionsWidget.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Opacity(
          opacity: isLoading ? 1.0 : 00,
          child: const CircularProgressIndicator(),
        ),
      ),
    ));

    return Column(
      children: transactionsWidget,
    );
  }

  Widget _buildItemTransaction(Transaction transaction, BuildContext context) {
    fromId = transaction.internalId;

    final TextStyle subtitle = Theme.of(context)
        .textTheme
        .subtitle
        .copyWith(fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Card(
          elevation: 8.0,
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => TransactionDetail(
                        transaction: transaction,
                        coinBalance: currentCoinBalance)),
              );
            },
            child: Container(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: double.parse(
                                              transaction.myBalanceChange) >
                                          0
                                      ? Colors.green
                                      : Colors.redAccent,
                                  width: 2)),
                          child: double.parse(transaction.myBalanceChange) > 0
                              ? Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                )
                              : Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
                                )),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 8),
                            child: StreamBuilder<bool>(
                                initialData: settingsBloc.showBalance,
                                stream: settingsBloc.outShowBalance,
                                builder: (BuildContext context,
                                    AsyncSnapshot<bool> snapshot) {
                                  final amount =
                                      deci(transaction.myBalanceChange);
                                  String amountString = deci2s(amount);
                                  if (snapshot.hasData &&
                                      snapshot.data == false) {
                                    amountString =
                                        (amount.toDouble() < 0 ? '-' : '') +
                                            '**.**';
                                  }
                                  return AutoSizeText(
                                    '${amount.toDouble() > 0 ? '+' : ''}$amountString ${currentCoinBalance.coin.abbr}',
                                    maxLines: 1,
                                    style: subtitle,
                                    textAlign: TextAlign.end,
                                  );
                                }),
                          ),
                          StreamBuilder<bool>(
                              initialData: settingsBloc.showBalance,
                              stream: settingsBloc.outShowBalance,
                              builder: (BuildContext context,
                                  AsyncSnapshot<bool> snapshot) {
                                if (currentCoinBalance.priceForOne == null) {
                                  return const Padding(
                                      padding: EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          bottom: 16,
                                          top: 8),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                      ));
                                } else {
                                  final usdAmount =
                                      deci(currentCoinBalance.priceForOne) *
                                          deci(transaction.myBalanceChange);
                                  if (usdAmount != deci(0)) {
                                    bool hidden = false;
                                    if (snapshot.hasData &&
                                        snapshot.data == false) {
                                      hidden = true;
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          bottom: 16,
                                          top: 8),
                                      child: Text(
                                        cexProvider.convert(
                                          usdAmount.toDouble(),
                                          hidden: hidden,
                                        ),
                                        style:
                                            Theme.of(context).textTheme.body2,
                                      ),
                                    );
                                  }
                                  return Container();
                                }
                              }),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  color: Theme.of(context).backgroundColor,
                  height: 1,
                  width: double.infinity,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          transaction.getTimeFormat(),
                          style: Theme.of(context).textTheme.body2,
                        ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          return transaction.confirmations > 0
                              ? Container(
                                  height: 12,
                                  width: 12,
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(16)),
                                      color: Colors.green),
                                )
                              : Container(
                                  height: 12,
                                  width: 12,
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(16)),
                                      color: Colors.red),
                                );
                        },
                      )
                    ],
                  ),
                )
              ],
            )),
          )),
    );
  }

  Widget _buildHeaderCoinDetail(BuildContext mContext) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: StreamBuilder<List<CoinBalance>>(
              initialData: coinsBloc.coinBalance,
              stream: coinsBloc.outCoins,
              builder: (BuildContext context,
                  AsyncSnapshot<List<CoinBalance>> snapshot) {
                if (snapshot.hasData) {
                  for (CoinBalance coinBalance in snapshot.data) {
                    if (coinBalance.coin.abbr == currentCoinBalance.coin.abbr) {
                      currentCoinBalance = coinBalance;
                    }
                  }

                  return StreamBuilder<bool>(
                      initialData: settingsBloc.showBalance,
                      stream: settingsBloc.outShowBalance,
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        String coinBalance =
                            currentCoinBalance.balance.getBalance();
                        final String coinBalanceUsd =
                            currentCoinBalance.getBalanceUSD();
                        bool hidden = false;
                        if (snapshot.hasData && snapshot.data == false) {
                          coinBalance = '**.**';
                          hidden = true;
                        }
                        return Column(
                          children: <Widget>[
                            Text(
                              coinBalance +
                                  ' ' +
                                  currentCoinBalance.balance.coin.toString(),
                              style: Theme.of(context).textTheme.title,
                              textAlign: TextAlign.center,
                            ),
                            Text(cexProvider.convert(
                              double.parse(coinBalanceUsd),
                              hidden: hidden,
                            ))
                          ],
                        );
                      });
                } else {
                  return Container();
                }
              }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const SizedBox(
              width: 16,
            ),
            _buildButtonLight(StatusButton.RECEIVE, mContext),
            const SizedBox(
              width: 8,
            ),
            currentCoinBalance.coin.abbr == 'KMD' &&
                    double.parse(currentCoinBalance.balance.getBalance()) >= 10
                ? _buildButtonLight(StatusButton.CLAIM, mContext)
                : Container(),
            const SizedBox(
              width: 8,
            ),
            double.parse(currentCoinBalance.balance.getBalance()) > 0
                ? _buildButtonLight(StatusButton.SEND, mContext)
                : Container(),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        const SizedBox(
          height: 16,
        )
      ],
    );
  }

  Widget _buildButtonLight(StatusButton statusButton, BuildContext mContext) {
    if (currentIndex == 3 && statusButton == StatusButton.SEND) {
      _closeAfterAWait();
    }

    String text = '';
    switch (statusButton) {
      case StatusButton.RECEIVE:
        text = AppLocalizations.of(context).receive;
        break;
      case StatusButton.SEND:
        text = isExpanded
            ? AppLocalizations.of(context).close.toUpperCase()
            : AppLocalizations.of(context).send.toUpperCase();
        break;
      case StatusButton.CLAIM:
        text = AppLocalizations.of(context).claim.toUpperCase();
        return Expanded(
            child: Stack(
          children: <Widget>[
            SecondaryButton(
              text: text,
              onPressed: () {
                rewardsProvider.update();
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => RewardsPage()),
                );
              },
            ),
            if (rewardsProvider.needClaim)
              buildRedDot(
                context,
                right: null,
                left: 14,
                top: 20,
              )
          ],
        ));
    }

    return Expanded(
      child: SecondaryButton(
        text: text,
        onPressed: () {
          switch (statusButton) {
            case StatusButton.RECEIVE:
              showAddressDialog(mContext, currentCoinBalance.balance.address,
                  widget.coinBalance.coin);
              break;
            case StatusButton.SEND:
              if (currentIndex == 3) {
                setState(() {
                  isExpanded = false;
                  _waitForInit();
                });
              } else {
                setState(() {
                  elevationHeader == 8.0
                      ? elevationHeader = 8.0
                      : elevationHeader = 0.0;
                  isExpanded = !isExpanded;
                });
              }
              break;
            default:
          }
        },
      ),
    );
  }

  Widget _buildForm() {
    return AnimatedCrossFade(
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
      firstChild: Container(),
      secondChild: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Card(
            margin:
                const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 16),
            elevation: 8.0,
            child: SingleChildScrollView(child: listSteps[currentIndex])),
      ),
    );
  }

  Widget _buildNewTransactionsButton() {
    return InkWell(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.blue,
        child: Row(
          children: <Widget>[
            Icon(Icons.refresh),
            const SizedBox(
              width: 8.0,
            ),
            const Text('Latest Transactions'),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
      onTap: () async {
        await _refresh();
        _scrollController.position.jumpTo(0.0);
      },
    );
  }

  void catchError(BuildContext mContext) {
    resetSend();
    Scaffold.of(mContext).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      backgroundColor: Theme.of(context).errorColor,
      content: Text(AppLocalizations.of(mContext).errorTryLater),
    ));
  }

  void resetSend() {
    setState(() {
      currentIndex = 0;
      isExpanded = false;
      initSteps();
    });
  }

  Future<void> _closeAfterAWait() async {
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          isExpanded = false;
          _waitForInit();
        });
      }
    });
  }

  Future<void> _waitForInit() async {
    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        coinsDetailBloc.resetCustomFee();
        currentIndex = 0;
        initSteps();
      });
    });
  }

  void initSteps() {
    _amountController.clear();
    _addressController.clear();
    listSteps.clear();
    listSteps.add(AmountAddressStep(
      coin: widget.coinBalance.coin,
      onCancel: () {
        setState(() {
          isExpanded = false;
          _waitForInit();
        });
      },
      isERCToken: widget.coinBalance.coin.swapContractAddress.isNotEmpty,
      onConfirm: () async {
        setState(() {
          isExpanded = false;
          listSteps.add(BuildConfirmationStep(
            coinBalance: currentCoinBalance,
            amountToPay: _amountController.text,
            addressToSend: _addressController.text,
            onCancel: () {
              setState(() {
                isExpanded = false;
                _waitForInit();
              });
            },
            onNoInternet: () {
              Scaffold.of(mainContext).showSnackBar(SnackBar(
                duration: const Duration(seconds: 2),
                backgroundColor: Theme.of(context).errorColor,
                content: Text(AppLocalizations.of(mainContext).noInternet),
              ));
            },
            onStepChange: (int step) {
              setState(() {
                currentIndex = step;
              });
            },
            onLoadingStep: () {
              setState(() {
                isSendIsActive = false;
              });
              listSteps.add(Container(
                  height: 100,
                  width: double.infinity,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )));
              setState(() {
                currentIndex = 2;
              });

              final Fee fee = Fee();
              if (coinsDetailBloc.customFee != null) {
                if (widget.coinBalance.coin.swapContractAddress.isNotEmpty) {
                  fee.type = 'EthGas';
                  fee.gas = coinsDetailBloc.customFee.gas;
                  fee.gasPrice = coinsDetailBloc.customFee.gasPrice;
                } else {
                  fee.type = 'UtxoFixed';
                  fee.amount = coinsDetailBloc.customFee.amount;
                }
              }
              ApiProvider()
                  .postWithdraw(
                      MMService().client,
                      GetWithdraw(
                          userpass: MMService().userpass,
                          fee: fee,
                          coin: widget.coinBalance.coin.abbr,
                          to: _addressController.text,
                          amount: _amountController.text,
                          max: double.parse(
                                  widget.coinBalance.balance.getBalance()) ==
                              double.parse(_amountController.text)))
                  .then((dynamic data) {
                if (data is WithdrawResponse) {
                  ApiProvider()
                      .postRawTransaction(
                          MMService().client,
                          GetSendRawTransaction(
                              coin: widget.coinBalance.coin.abbr,
                              txHex: data.txHex))
                      .then((dynamic dataRawTx) {
                    if (dataRawTx is SendRawTransactionResponse &&
                        dataRawTx.txHash.isNotEmpty) {
                      setState(() {
                        coinsBloc.updateCoinBalances();
                        Future<dynamic>.delayed(const Duration(seconds: 5), () {
                          coinsBloc.updateCoinBalances();
                        });
                        listSteps.add(SuccessStep(
                          txHash: dataRawTx.txHash,
                        ));
                        setState(() {
                          currentIndex = 3;
                        });
                      });
                    } else if (dataRawTx is ErrorString &&
                        dataRawTx.error.contains('gas is too low')) {
                      resetSend();
                      final String gas = dataRawTx.error
                          .substring(
                              dataRawTx.error.indexOf(
                                      r':', dataRawTx.error.indexOf(r'"')) +
                                  1,
                              dataRawTx.error
                                  .indexOf(r',', dataRawTx.error.indexOf(r'"')))
                          .trim();
                      Scaffold.of(mainContext).showSnackBar(SnackBar(
                        duration: const Duration(seconds: 2),
                        backgroundColor: Theme.of(context).errorColor,
                        content: Text(
                          AppLocalizations.of(mainContext)
                              .errorNotEnoughtGas(gas),
                        ),
                      ));
                    } else {
                      catchError(mainContext);
                    }
                  }).catchError((dynamic onError) {
                    catchError(mainContext);
                  });
                } else {
                  catchError(mainContext);
                }
              }).catchError((dynamic onError) {
                catchError(mainContext);
              });
            },
            onError: () {
              catchError(mainContext);
            },
            onSuccessStep: (String txHash) {
              listSteps.add(SuccessStep(
                txHash: txHash,
              ));
            },
          ));
        });
        setState(() {
          currentIndex = 1;
          isExpanded = true;
        });
      },
      onMaxValue: setMaxValue,
      focusNode: _focus,
      addressController: _addressController,
      amountController: _amountController,
      balance: double.parse(widget.coinBalance.balance.getBalance()),
    ));
  }
}

enum StatusButton { SEND, RECEIVE, CLAIM }
