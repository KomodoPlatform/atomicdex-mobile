abstract class ZCoinActivationEvent {
  const ZCoinActivationEvent();
}

/// Activates any requested ZCoins not already activated
class ZCoinActivationRequested extends ZCoinActivationEvent {}

/// Sets the list of requested ZCoins to activate.
/// Must call [ZCoinActivationRequested] to activate the coins.
class ZCoinActivationSetRequestedCoins extends ZCoinActivationEvent {
  const ZCoinActivationSetRequestedCoins(this.coins);

  final List<String> coins;
}

class ZCoinActivationStatusRequested extends ZCoinActivationEvent {}

