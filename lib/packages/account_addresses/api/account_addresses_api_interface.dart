import 'package:komodo_dex/packages/account_addresses/models/wallet_address.dart';

abstract class AccountAddressesApiInterface {
  Future<void> create(WalletAddress walletAddress);
  Future<void> update(String walletId, String address,
      {WalletAddress updateFields});
  Future<void> deleteOne(String walletId, String address);
  Future<void> deleteAll(String walletId);
  Future<WalletAddress> readOne(String walletId, String address);
  Future<List<WalletAddress>> readAll(String walletId);
  Stream<WalletAddress> watchAll(String walletId);
}
