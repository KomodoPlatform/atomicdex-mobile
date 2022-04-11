import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komodo_dex/blocs/coin_detail_bloc.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/blocs/main_bloc.dart';
import 'package:komodo_dex/blocs/settings_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/cex_provider.dart';
import 'package:komodo_dex/model/coin.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/model/error_code.dart';
import 'package:komodo_dex/model/error_string.dart';
import 'package:komodo_dex/model/get_send_raw_transaction.dart';
import 'package:komodo_dex/model/rewards_provider.dart';
import 'package:komodo_dex/model/send_raw_transaction_response.dart';
import 'package:komodo_dex/model/transaction_data.dart';
import 'package:komodo_dex/model/transactions.dart';
import 'package:komodo_dex/model/withdraw_response.dart';
import 'package:komodo_dex/screens/authentification/lock_screen.dart';
import 'package:komodo_dex/screens/portfolio/coin_detail/steps_withdraw.dart/amount_address_step/amount_address_step.dart';
import 'package:komodo_dex/screens/portfolio/coin_detail/steps_withdraw.dart/build_confirmation_step.dart';
import 'package:komodo_dex/screens/portfolio/coin_detail/steps_withdraw.dart/success_step.dart';
import 'package:komodo_dex/screens/portfolio/coin_detail/tx_list_item.dart';
import 'package:komodo_dex/screens/portfolio/copy_dialog.dart';
import 'package:komodo_dex/screens/portfolio/faucet_dialog.dart';
import 'package:komodo_dex/screens/portfolio/rewards_page.dart';
import 'package:komodo_dex/services/mm.dart';
import 'package:komodo_dex/services/mm_service.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:komodo_dex/widgets/auto_scroll_text.dart';
import 'package:komodo_dex/widgets/build_red_dot.dart';
import 'package:komodo_dex/widgets/photo_widget.dart';
import 'package:komodo_dex/widgets/secondary_button.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class CoinDetail extends StatefulWidget {
  const CoinDetail({
    this.coinBalance,
    this.isSendIsActive = false,
    this.paymentUriInfo,
  });

  final CoinBalance coinBalance;
  final bool isSendIsActive;
  final PaymentUriInfo paymentUriInfo;

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
  final TextEditingController _cryptoListener =
      TextEditingController(text: 'true');

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
        .then((Transaction t) {
      if (t != null) latestTransaction = t;
    });
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
    _cryptoListener.dispose();
    coinsBloc.resetTransactions();
    if (timer != null) {
      timer.cancel();
    }
    mainBloc.isUrlLaucherIsOpen = false;
    coinsDetailBloc.resetCustomFee();
    super.dispose();
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
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: elevationHeader,
          foregroundColor: ThemeData.estimateBrightnessForColor(
                      Color(int.parse(currentCoinBalance.coin.colorCoin))) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black,
          actions: <Widget>[
            IconButton(
              splashRadius: 24,
              key: const Key('coin-deactivate'),
              icon: isDeleteLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.5,
                      ),
                    )
                  : Icon(Icons.delete),
              onPressed: () async {
                if (widget.coinBalance.coin.isDefault) {
                  await showCantRemoveDefaultCoin(
                      context, widget.coinBalance.coin);
                } else {
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
                }
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
                tag: 'assets/coin-icons/'
                    '${currentCoinBalance.balance.coin.toLowerCase()}.png',
                radius: 16,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: AutoScrollText(
                  text: currentCoinBalance.coin.name.toUpperCase(),
                ),
              ),
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
              if (_shouldRefresh) _buildNewTransactionsButton(),
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
    // Since we currently fetching erc20 transactions history
    // from the http endpoint, sync status indicator is hidden
    // for erc20 tokens
    final String coinType = widget.coinBalance.coin.type;
    if (coinType == 'erc' || coinType == 'bep' || coinType == 'plg') {
      return SizedBox();
    }

    return StreamBuilder<dynamic>(
        stream: coinsBloc.outTransactions,
        initialData: coinsBloc.transactions,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData && snapshot.data is Transactions) {
            final Transactions tx = snapshot.data;
            final String syncState = StateOfSync.InProgress.toString()
                .substring(StateOfSync.InProgress.toString().indexOf('.') + 1);
            if (tx.result != null &&
                tx.result.syncStatus != null &&
                tx.result.syncStatus.state != null) {
              timer ??= Timer.periodic(const Duration(seconds: 3), (_) async {
                final Transaction t = await coinsBloc
                    .getLatestTransaction(currentCoinBalance.coin);

                if (_isWaiting) {
                  _refresh();
                } else if (_scrollController.position.pixels == 0.0) {
                  _refresh();
                } else if (latestTransaction == null ||
                    latestTransaction.internalId != t.internalId) {
                  _shouldRefresh = true;
                }

                latestTransaction = t;
              });

              if (tx.result.syncStatus.state == syncState) {
                final String txLeft = tx
                    .result.syncStatus.additionalInfo.transactionsLeft
                    .toString();

                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Center(
                          child: SizedBox(
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
                      Expanded(child: SizedBox()),
                      Text('Transactions left $txLeft'),
                    ],
                  ),
                );
              }
            }
          }
          return SizedBox();
        });
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          color: Theme.of(context).colorScheme.secondary,
          key: _refreshIndicatorKey,
          onRefresh: _refresh,
          child: StreamBuilder<dynamic>(
              stream: coinsBloc.outTransactions,
              initialData: coinsBloc.transactions,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  _isWaiting = true;
                  return const Center(child: CircularProgressIndicator());
                } else {
                  _isWaiting = false;
                }
                if (snapshot.data is Transactions) {
                  final Transactions transactions = snapshot.data;
                  final String syncState = StateOfSync.InProgress.toString()
                      .substring(
                          StateOfSync.InProgress.toString().indexOf('.') + 1);

                  if (snapshot.hasData &&
                      transactions.result != null &&
                      transactions.result.transactions != null) {
                    if (transactions.result.transactions.isNotEmpty) {
                      //@Slyris plz clean up
                      return ListView.builder(
                        itemCount: transactions.result.transactions.length,
                        itemBuilder: (context, i) => _buildTransactionItem(
                          transactions.result.transactions[i],
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        controller: _scrollController,
                      );
                    } else if (transactions.result.transactions.isEmpty &&
                        !(transactions.result.syncStatus.state == syncState)) {
                      return Center(
                          child: Text(
                        AppLocalizations.of(context).noTxs,
                        style: Theme.of(context).textTheme.bodyText1,
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
                      style: Theme.of(context).textTheme.bodyText1,
                      textAlign: TextAlign.center,
                    )),
                  );
                }
                return SizedBox();
              })),
    );
  }

  Future<void> _refresh() async {
    await coinsBloc.updateTransactions(currentCoinBalance.coin, limit, null);
    if (mounted) {
      setState(() {
        _shouldRefresh = false;
      });
    }
  }

  Widget _buildTransactionItem(Transaction transaction) {
    fromId = transaction.internalId;

    return TransactionListItem(
      transaction: transaction,
      currentCoinBalance: currentCoinBalance,
    );
  }

  Widget _buildHeaderCoinDetail(BuildContext mContext) {
    return Column(
      children: <Widget>[
        if (widget.coinBalance.coin.protocol?.protocolData != null)
          _buildContractAddress(widget.coinBalance.coin.protocol?.protocolData),
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
                      builder: (BuildContext context,
                          AsyncSnapshot<bool> showBalance) {
                        String coinBalance =
                            currentCoinBalance.balance.getBalance();
                        final String unspendableBalance =
                            currentCoinBalance.balance.getUnspendableBalance();
                        final String coinBalanceUsd =
                            currentCoinBalance.getBalanceUSD();
                        bool hidden = false;
                        if (showBalance.hasData && showBalance.data == false) {
                          coinBalance = '**.**';
                          hidden = true;
                        }
                        return Column(
                          children: <Widget>[
                            Text(
                              coinBalance +
                                  ' ' +
                                  currentCoinBalance.balance.coin,
                              style: Theme.of(context).textTheme.headline5,
                              textAlign: TextAlign.center,
                            ),
                            if (double.tryParse(unspendableBalance ?? '0') > 0)
                              Container(
                                padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                child: Text(
                                  '(+${hidden ? '**.**' : unspendableBalance}'
                                  ' ${currentCoinBalance.balance.coin}'
                                  ' ${AppLocalizations.of(context).unspendable})',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            Text(cexProvider.convert(
                              double.parse(coinBalanceUsd),
                              hidden: hidden,
                            )),
                          ],
                        );
                      });
                } else {
                  return SizedBox();
                }
              }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
                child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: _buildButtonLight(StatusButton.RECEIVE, mContext),
            )),
            if (currentCoinBalance.coin.abbr == 'KMD' &&
                double.parse(currentCoinBalance.balance.getBalance()) >= 10)
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildButtonLight(StatusButton.CLAIM, mContext),
              )),
            if (currentCoinBalance.coin.abbr == 'RICK' ||
                currentCoinBalance.coin.abbr == 'MORTY')
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildButtonLight(StatusButton.FAUCET, mContext),
              )),
            if (currentCoinBalance.coin.abbr == 'TKL' ||
                currentCoinBalance.coin.abbr == 'MCL')
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildButtonLight(StatusButton.PUBKEY, mContext),
              )),
            if (double.parse(currentCoinBalance.balance.getBalance()) > 0)
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildButtonLight(StatusButton.SEND, mContext),
              )),
          ],
        ),
        const SizedBox(
          height: 16,
        )
      ],
    );
  }

  Widget _buildContractAddress(ProtocolData protocolData) {
    final platform = protocolData.platform;
    String contractAddress = protocolData.contractAddress;
    String middleUrl = 'address';
    if (platform == 'QTUM') {
      contractAddress = contractAddress.replaceFirst('0x', '');
      middleUrl = 'contract';
    }

    final allCoins = coinsBloc.knownCoins;
    final platformCoin = allCoins[platform];
    final explorerUrl = platformCoin.explorerUrl.first;

    final baseUrl = '$explorerUrl/$middleUrl/$contractAddress';

    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 12),
            Text('Contract:'),
            SizedBox(width: 8),
            Flexible(
              child: Card(
                color: Theme.of(context).cardColor.withAlpha(200),
                child: InkWell(
                  onTap: () => launchURL(baseUrl.replaceAll('//', '/')),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/coin-icons/${platform.toLowerCase()}.png',
                          width: 16,
                          height: 16,
                        ),
                        SizedBox(width: 4),
                        Text('$platform:'),
                        SizedBox(width: 4),
                        Expanded(
                          child: truncateMiddle(contractAddress),
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 16,
                          splashRadius: 12,
                          constraints:
                              BoxConstraints.tightFor(width: 16, height: 16),
                          padding: EdgeInsets.all(0),
                          icon: Icon(Icons.copy_rounded),
                          onPressed: () =>
                              copyToClipBoard(context, contractAddress),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
        ),
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

      case StatusButton.PUBKEY:
        text = AppLocalizations.of(context).pubkey.toUpperCase();
        break;
      case StatusButton.FAUCET:
        text = AppLocalizations.of(context).faucetName;
        break;
      case StatusButton.CLAIM:
        text = AppLocalizations.of(context).claim.toUpperCase();
        return Stack(
          children: <Widget>[
            SecondaryButton(
              text: text,
              textColor: Theme.of(context).textTheme.button.color,
              borderColor: Theme.of(context).colorScheme.secondary,
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
        );
    }

    return SecondaryButton(
      text: text,
      isDarkMode: Theme.of(context).brightness != Brightness.light,
      textColor: Theme.of(context).colorScheme.secondary,
      borderColor: Theme.of(context).colorScheme.secondary,
      onPressed: () {
        switch (statusButton) {
          case StatusButton.RECEIVE:
            showCopyDialog(mContext, currentCoinBalance.balance.address,
                widget.coinBalance.coin);
            break;
          case StatusButton.FAUCET:
            showFaucetDialog(
                context: mContext,
                coin: currentCoinBalance.coin.abbr,
                address: currentCoinBalance.balance.address);
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
          case StatusButton.PUBKEY:
            getPublicKey().then(
                (v) => showCopyDialog(mContext, v, widget.coinBalance.coin));
            break;
          default:
        }
      },
    );
  }

  Future<String> getPublicKey() async {
    final pb = await MM.getPublicKey();
    final String key = pb.result.publicKey;
    return key;
  }

  Widget _buildForm() {
    return AnimatedCrossFade(
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
      firstChild: SizedBox(),
      secondChild: GestureDetector(
        onTap: () {
          unfocusTextField(context);
        },
        child: Card(
            margin:
                const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 16),
            elevation: 8.0,
            child: listSteps[currentIndex]),
      ),
    );
  }

  Widget _buildNewTransactionsButton() {
    return InkWell(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: Theme.of(context).colorScheme.secondary,
        child: Row(
          children: <Widget>[
            Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
            SizedBox(
              width: 8.0,
            ),
            Text(
              'Latest Transactions',
              style: Theme.of(context)
                  .textTheme
                  .button
                  .copyWith(color: Theme.of(context).colorScheme.onSecondary),
            ),
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
    ScaffoldMessenger.of(mContext).showSnackBar(SnackBar(
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

  String convertToCryptoFromFiat() {
    final double price = cexProvider.getUsdPrice(widget.coinBalance.coin.abbr);
    final amountParsed = double.tryParse(_amountController.text) ?? 0.0;
    double amount = amountParsed / price;
    double balance = double.parse(widget.coinBalance.balance.getBalance());
    return balance < amount ? balance.toString() : amount.toString();
  }

  void initSteps() {
    _amountController.clear();
    _addressController.clear();
    listSteps.clear();
    listSteps.add(AmountAddressStep(
      coinBalance: widget.coinBalance,
      paymentUriInfo: widget.paymentUriInfo,
      cryptoListener: _cryptoListener,
      onCancel: () {
        setState(() {
          isExpanded = false;
          _waitForInit();
        });
      },
      onWithdrawPressed: () async {
        setState(() {
          isExpanded = false;
          listSteps.add(BuildConfirmationStep(
            coinBalance: currentCoinBalance,
            amountToPay: _cryptoListener.text == 'true'
                ? _amountController.text
                : convertToCryptoFromFiat(),
            addressToSend: _addressController.text,
            onCancel: () {
              setState(() {
                isExpanded = false;
                _waitForInit();
              });
            },
            onNoInternet: () {
              ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(
                duration: const Duration(seconds: 2),
                backgroundColor: Theme.of(context).errorColor,
                content: Text(AppLocalizations.of(mainContext).noInternet),
              ));
            },
            onError: () {
              catchError(mainContext);
            },
            onConfirmPressed: (WithdrawResponse response) {
              setState(() {
                isSendIsActive = false;
              });

              listSteps.add(SizedBox(
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

              ApiProvider()
                  .postRawTransaction(
                      mmSe.client,
                      GetSendRawTransaction(
                          coin: widget.coinBalance.coin.abbr,
                          txHex: response.txHex))
                  .then((dynamic dataRawTx) {
                if (dataRawTx is SendRawTransactionResponse &&
                    dataRawTx.txHash.isNotEmpty) {
                  coinsBloc.updateCoinBalances();
                  Future<dynamic>.delayed(const Duration(seconds: 5), () {
                    coinsBloc.updateCoinBalances();
                  });

                  setState(() {
                    listSteps.add(SuccessStep(
                      txHash: dataRawTx.txHash,
                    ));

                    currentIndex = 3;
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
                  ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(
                    duration: const Duration(seconds: 2),
                    backgroundColor: Theme.of(context).errorColor,
                    content: Text(
                      AppLocalizations.of(mainContext).errorNotEnoughGas(gas),
                    ),
                  ));
                } else {
                  catchError(mainContext);
                }
              }).catchError((dynamic onError) {
                catchError(mainContext);
              });

              if (response is WithdrawResponse) {
              } else {
                catchError(mainContext);
              }
            },
          ));
        });
        setState(() {
          currentIndex = 1;
          isExpanded = true;
        });
      },
      //  onMaxValue: setMaxValue,
      focusNode: _focus,
      addressController: _addressController,
      amountController: _amountController,
    ));
  }
}

enum StatusButton { SEND, RECEIVE, FAUCET, CLAIM, PUBKEY }
