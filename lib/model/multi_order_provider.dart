import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/model/setprice_response.dart';
import 'package:komodo_dex/screens/dex/trade/confirm/protection_control.dart';
import 'package:komodo_dex/screens/dex/get_swap_fee.dart';
import 'package:komodo_dex/services/mm.dart';
import 'package:komodo_dex/services/mm_service.dart';
import 'package:komodo_dex/utils/log.dart';
import 'package:komodo_dex/utils/utils.dart';

import 'error_string.dart';
import 'get_setprice.dart';

class MultiOrderProvider extends ChangeNotifier {
  final AppLocalizations _localizations = AppLocalizations();
  String _baseCoin;
  String _baseCoinError;
  double _sellAmt;
  bool _isMax = false;
  bool _validated = false;

  final Map<String, MultiOrderRelCoin> _relCoins = {};

  String get baseCoin => _baseCoin;
  set baseCoin(String coin) {
    reset();
    _baseCoin = coin;

    notifyListeners();
  }

  void reset() {
    _baseCoin = null;
    _baseCoinError = null;
    _sellAmt = null;
    _isMax = false;
    _validated = false;
    _relCoins.clear();

    notifyListeners();
  }

  bool get validated => _validated;
  set validated(bool val) {
    _validated = val;
    notifyListeners();
  }

  bool get isMax => _isMax;
  set isMax(bool value) {
    _isMax = value;
    notifyListeners();
  }

  double get baseAmt => _sellAmt;
  set baseAmt(double value) {
    _sellAmt = value;
    notifyListeners();
  }

  Map<String, MultiOrderRelCoin> get relCoins => _relCoins;

  bool isRelCoinSelected(String coin) {
    return _relCoins.containsKey(coin);
  }

  void selectRelCoin(String coin, bool val) {
    if (val) {
      if (coin == baseCoin) return;
      if (!isRelCoinSelected(coin)) _relCoins[coin] = null;
    } else {
      _relCoins.remove(coin);
    }

    notifyListeners();
  }

  ProtectionSettings getProtectionSettings(String coin) {
    return relCoins[coin]?.protectionSettings;
  }

  void setProtectionSettings(String coin, ProtectionSettings settings) {
    _relCoins[coin] ??= MultiOrderRelCoin();
    _relCoins[coin].protectionSettings = settings;
    notifyListeners();
  }

  double getRelCoinAmt(String coin) {
    return _relCoins[coin] == null ? null : _relCoins[coin].amount;
  }

  String getError(String coin) {
    if (coin == _baseCoin) return _baseCoinError;

    return _relCoins[coin]?.error;
  }

  void setRelCoinAmt(String coin, double amt) {
    _relCoins[coin] ??= MultiOrderRelCoin();
    _relCoins[coin].amount = amt;
    notifyListeners();
  }

  Future<bool> validate() async {
    bool isValid = true;
    _relCoins.forEach((abbr, coin) => coin.error = null);

    // check if sell amount is empty
    if (baseAmt == null) {
      isValid = false;
      _baseCoinError = _localizations.multiInvalidSellAmt;
    }

    // check if sell amount is lower than available balance
    if (baseAmt != null) {
      final double max = getMaxSellAmt();
      if (baseAmt > max) {
        isValid = false;
        _baseCoinError = _localizations.multiMaxSellAmt +
            ' ${cutTrailingZeros(formatPrice(max, 8))} $baseCoin';
      }
    }

    // check min sell amount
    final double minSellAmt = baseCoin == 'QTUM' ? 3 : 0.00777;
    if (baseAmt != null && baseAmt < minSellAmt) {
      isValid = false;
      _baseCoinError =
          _localizations.multiMinSellAmt + ' $minSellAmt $baseCoin';
    }

    for (String coin in _relCoins.keys) {
      final double relAmt = _relCoins[coin].amount;

      // check for empty amount field
      if (relAmt == null || relAmt == 0) {
        isValid = false;
        _relCoins[coin].error = _localizations.multiInvalidAmt;
      }

      // check for gas balance
      final String gasCoin = coinsBloc.getCoinByAbbr(coin)?.payGasIn;
      if (gasCoin != null) {
        final CoinBalance gasBalance = coinsBloc.getBalanceByAbbr(gasCoin);
        if (gasBalance == null) {
          isValid = false;
          _relCoins[coin].error = _localizations.multiActivateGas(gasCoin);
        } else {
          double gasFee = (await GetSwapFee.gas(coin)).amount;
          if (baseCoin == gasCoin) {
            gasFee = gasFee +
                (await GetSwapFee.tx(baseCoin)).amount +
                GetSwapFee.trading(baseAmt).amount;
          }
          if (gasBalance.balance.balance.toDouble() < gasFee) {
            isValid = false;
            relCoins[coin].error = _localizations.multiLowGas(gasCoin);
          }
        }
      }

      // check min receive amount
      final double minReceiveAmt = baseCoin == 'QTUM' ? 3 : 0.00777;
      if (relAmt != null && relAmt < minReceiveAmt) {
        isValid = false;
        relCoins[coin].error =
            _localizations.multiMinReceiveAmt + ' $minReceiveAmt $coin';
      }
    }

    notifyListeners();

    return isValid;
  }

  Future<void> create() async {
    if (!(await validate())) return;

    final List<String> relCoins = List.from(_relCoins.keys);

    for (String coin in relCoins) {
      final double amount = _relCoins[coin].amount;

      final GetSetPrice getSetPrice = GetSetPrice(
        base: baseCoin,
        rel: coin,
        cancelPrevious: false,
        max: _isMax,
        volume: baseAmt.toString(),
        price: deci2s(deci(amount / baseAmt)),
      );

      if (_relCoins[coin]?.protectionSettings != null) {
        getSetPrice.relNota =
            _relCoins[coin].protectionSettings.requiresNotarization;
        getSetPrice.relConfs =
            _relCoins[coin].protectionSettings.requiredConfirmations;
      }

      final dynamic response = await MM.postSetPrice(mmSe.client, getSetPrice);
      if (response is SetPriceResponse) {
        _relCoins.remove(coin);
      } else if (response is ErrorString) {
        Log(
            'multi_order_provider]',
            'Failed to post setprice:'
                ' ${response.error}');
        _relCoins[coin].error = response.error;
      }
    }

    notifyListeners();
  }

  double getMaxSellAmt() {
    if (baseCoin == null) return null;

    return coinsBloc.getBalanceByAbbr(baseCoin).balance.balance.toDouble();
  }
}

class MultiOrderRelCoin {
  MultiOrderRelCoin({
    this.amount,
    this.protectionSettings,
    this.error,
  });

  double amount;
  ProtectionSettings protectionSettings;
  String error;
}
