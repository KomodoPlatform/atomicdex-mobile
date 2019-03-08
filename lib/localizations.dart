import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/messages_all.dart';

class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name =
        locale.countryCode == null ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return new AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get createPin => Intl.message('Create PIN', name: 'createPin');

  String get enterPinCode =>
      Intl.message('Enter your PIN code', name: 'enterPinCode');

  String get login => Intl.message('login', name: 'login');

  String get newAccount => Intl.message('new account', name: 'newAccount');

  String get newAccountUpper =>
      Intl.message('New Account', name: 'newAccountUpper');

  String addingCoinSuccess(String name) => Intl.message(
        'Added $name successfully !',
        name: 'addingCoinSuccess',
        args: [name],
      );

  String get addCoin => Intl.message('Add coin', name: 'addCoin');

  String numberAssets(String assets) =>
      Intl.message("$assets Assets", args: [assets], name: 'numberAssets');

  String get enterSeedPhrase =>
      Intl.message('Enter Your Seed Phrase', name: 'enterSeedPhrase');

  String get exampleHintSeed =>
      Intl.message('Example: over cake age ...', name: 'exampleHintSeed');

  String get confirm => Intl.message('confirm', name: 'confirm');

  String get buy => Intl.message('Buy', name: 'buy');

  String get sell => Intl.message('Sell', name: 'sell');

  String shareAddress(String coinName, String address) =>
      Intl.message('My $coinName address: \n$address',
          args: [coinName, address], name: 'shareAddress');

  String get withdraw => Intl.message('Withdraw', name: 'withdraw');

  String get errorValueEmpty =>
      Intl.message("Value is too high or low", name: 'errorValueEmpty');

  String get amount => Intl.message('Amount', name: 'amount');

  String get addressSend =>
      Intl.message('Address To Send', name: 'addressSend');

  String withdrawValue(String amount, String coinName) =>
      Intl.message('WITHDRAW $amount $coinName',
          args: [amount, coinName], name: 'withdrawValue');

  String get errorTryLater =>
      Intl.message('Error, please try later.', name: 'errorTryLater');

  String get withdrawConfirm =>
      Intl.message('Withdraw confirm', name: 'withdrawConfirm');

  String get close => Intl.message('Close', name: 'close');

  String get confirmSeed => Intl.message('Confirm Seed', name: 'confirmSeed');

  String get seedPhraseTitle =>
      Intl.message('Seed Phrase for Your Portfolio', name: 'seedPhraseTitle');

  String get getBackupPhrase =>
      Intl.message('Important: please back up your seed phrase now!',
          name: 'getBackupPhrase');

  String get recommendSeedMessage =>
      Intl.message('We recommend storing it offline.',
          name: 'recommendSeedMessage');

  String get next => Intl.message('next', name: 'next');

  String get confirmPin => Intl.message('Confirm PIN', name: 'confirmPin');

  String get errorTryAgain =>
      Intl.message('Error, please try again', name: 'errorTryAgain');

  String get settings => Intl.message('Settings', name: 'settings');

  String get security => Intl.message('Security', name: 'security');

  String get activateAccessPin =>
      Intl.message('Activate PIN access', name: 'activateAccessPin');

  String get lockScreen => Intl.message('Lock Screen', name: 'lockScreen');

  String get changePin => Intl.message('Change PIN', name: 'changePin');

  String get logout => Intl.message('Logout', name: 'logout');

  String get max => Intl.message('MAX', name: 'max');

  String get amountToSell =>
      Intl.message('Amount To Sell', name: 'amountToSell');

  String get youWillReceived =>
      Intl.message('You will receive: ', name: 'youWillReceived');

  String get selectCoinToSell =>
      Intl.message('Select the coin you want to SELL',
          name: 'selectCoinToSell');

  String get selectCoinToBuy =>
      Intl.message('Select the coin you want to BUY', name: 'selectCoinToBuy');

  String get swap => Intl.message('swap', name: 'swap');

  String get buySuccessWaiting =>
      Intl.message('Order matched, please wait', name: 'buySuccessWaiting');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
