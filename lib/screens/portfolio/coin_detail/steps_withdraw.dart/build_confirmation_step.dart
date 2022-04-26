import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/coin_detail_bloc.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/blocs/main_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/model/error_string.dart';
import 'package:komodo_dex/model/get_withdraw.dart';
import 'package:komodo_dex/model/withdraw_response.dart';
import 'package:komodo_dex/services/mm.dart';
import 'package:komodo_dex/services/mm_service.dart';
import 'package:komodo_dex/widgets/primary_button.dart';
import 'package:komodo_dex/widgets/secondary_button.dart';

class BuildConfirmationStep extends StatefulWidget {
  const BuildConfirmationStep({
    Key key,
    this.coinBalance,
    this.amountToPay,
    this.addressToSend,
    this.onCancel,
    this.onError,
    this.onNoInternet,
    this.onConfirmPressed,
  }) : super(key: key);

  final Function onCancel;
  final Function onNoInternet;
  final Function onError;
  final Function(WithdrawResponse) onConfirmPressed;
  final CoinBalance coinBalance;
  final String amountToPay;
  final String addressToSend;

  @override
  _BuildConfirmationStepState createState() => _BuildConfirmationStepState();
}

class _BuildConfirmationStepState extends State<BuildConfirmationStep> {
  bool _showDetailedError = false;
  dynamic _withdrawResponse;

  bool closeStep = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Fee customFee;
      if (coinsDetailBloc.customFee != null) {
        final String coinType = widget.coinBalance.coin.type;
        if (coinType == 'erc' || coinType == 'bep' || coinType == 'plg') {
          customFee = Fee(
            type: 'EthGas',
            gas: coinsDetailBloc.customFee.gas,
            gasPrice: coinsDetailBloc.customFee.gasPrice,
          );
        } else {
          customFee = Fee(
            type: 'UtxoFixed',
            amount: coinsDetailBloc.customFee.amount,
          );
        }
      }

      ApiProvider()
          .postWithdraw(
              mmSe.client,
              GetWithdraw(
                userpass: mmSe.userpass,
                fee: customFee,
                coin: widget.coinBalance.coin.abbr,
                to: widget.addressToSend,
                amount: widget.amountToPay,
                max: double.parse(widget.coinBalance.balance.getBalance()) ==
                    double.parse(widget.amountToPay),
              ))
          .then((dynamic res) {
        setState(() => _withdrawResponse = res);
      }).catchError((dynamic onError) {
        setState(() => _withdrawResponse = onError);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_withdrawResponse is WithdrawResponse) {
      final CoinAmt fee = _extractFee(_withdrawResponse);

      if (fee == null) {
        return _buildErrorMessage();
      }

      final bool needGas = fee.coin != widget.coinBalance.coin.abbr;
      bool isGasActive = false;
      bool notEnoughGas = false;

      double amountToPay = double.parse(widget.amountToPay);
      double amountUserReceive = amountToPay;
      if (!needGas) amountToPay += fee.amount;
      final double userBalance = widget.coinBalance.balance.balance.toDouble();

      if (amountToPay > userBalance) {
        amountToPay = userBalance;
        if (!needGas) amountUserReceive -= fee.amount;
      }

      bool isButtonActive;
      if (needGas) {
        final CoinBalance gasBalance = coinsBloc.getBalanceByAbbr(fee.coin);
        isGasActive = gasBalance != null;
        if (isGasActive && fee.amount > gasBalance.balance.balance.toDouble()) {
          notEnoughGas = true;
        }

        isButtonActive = isGasActive && (!notEnoughGas) && amountToPay > 0;
      } else {
        isButtonActive = amountToPay > 0;
      }

      return closeStep
          ? SizedBox()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).youAreSending,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        amountToPay.toStringAsFixed(8),
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        widget.coinBalance.coin.abbr,
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '- ',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      Text(
                        fee.amount.toStringAsFixed(8),
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        needGas
                            ? AppLocalizations.of(context).gasFee(fee.coin)
                            : AppLocalizations.of(context).networkFee,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ],
                  ),
                  if (needGas && isGasActive && notEnoughGas)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context).notEnoughGas(fee.coin),
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(color: Theme.of(context).errorColor),
                        ),
                      ],
                    ),
                  if (needGas && !isGasActive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context).gasNotActive(fee.coin),
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(color: Theme.of(context).errorColor),
                        ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: Theme.of(context)
                          .textSelectionTheme
                          .selectionColor
                          .withOpacity(0.4),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        amountUserReceive.toStringAsFixed(8),
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          widget.coinBalance.coin.abbr,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    AppLocalizations.of(context).toAddress,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  AutoSizeText(
                    widget.addressToSend,
                    style: Theme.of(context).textTheme.bodyText2,
                    maxLines: 1,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SecondaryButton(
                          text:
                              AppLocalizations.of(context).cancel.toUpperCase(),
                          onPressed: () {
                            setState(() {
                              closeStep = true;
                            });
                            widget.onCancel();
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: Builder(builder: (BuildContext context) {
                          return PrimaryButton(
                            key: const Key('primary-button-confirm'),
                            text: AppLocalizations.of(context)
                                .confirm
                                .toUpperCase(),
                            onPressed: isButtonActive
                                ? () {
                                    _onPressedConfirmWithdraw(
                                        amountUserReceive.toDouble());
                                  }
                                : null,
                          );
                        }),
                      ),
                    ],
                  )
                ],
              ),
            );
    } else if (_withdrawResponse == null) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return _buildErrorMessage();
    }
  }

  Widget _buildErrorMessage() {
    final String detailedMessage =
        _withdrawResponse is ErrorString ? _withdrawResponse.error : null;

    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 48, 12, 12),
        child: Column(
          children: [
            Text(
              detailedMessage != null && _showDetailedError
                  ? detailedMessage
                  : AppLocalizations.of(context).withdrawConfirmError,
              style: TextStyle(color: Theme.of(context).errorColor),
            ),
            SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: AppLocalizations.of(context).back.toUpperCase(),
                    onPressed: widget.onCancel,
                  ),
                ),
                if (detailedMessage != null && !_showDetailedError) ...{
                  SizedBox(width: 8),
                  Expanded(
                    child: SecondaryButton(
                      text: AppLocalizations.of(context).details.toUpperCase(),
                      onPressed: () {
                        setState(() => _showDetailedError = true);
                      },
                    ),
                  ),
                }
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPressedConfirmWithdraw(double sendAmount) async {
    if (mainBloc.networkStatus != NetworkStatus.Online) {
      widget.onNoInternet();
    } else if (_withdrawResponse is WithdrawResponse) {
      widget.onConfirmPressed(_withdrawResponse);
    } else {
      widget.onError();
    }
  }

  CoinAmt _extractFee(WithdrawResponse res) {
    String coin = res.feeDetails.coin ?? '';
    if (coin.isEmpty) coin = widget.coinBalance.coin.abbr;

    double amount;
    try {
      amount = double.parse(res.feeDetails.amount);
    } catch (_) {
      amount = double.parse(res.feeDetails.totalFee);
    }

    if (amount == null) return null;

    return CoinAmt(
      coin: coin,
      amount: amount,
    );
  }
}

class CoinAmt {
  CoinAmt({this.amount, this.coin});

  double amount;
  String coin;
}
