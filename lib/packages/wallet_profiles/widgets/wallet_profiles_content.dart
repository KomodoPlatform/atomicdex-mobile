import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:komodo_dex/common_widgets/app_logo.dart';
import 'package:komodo_dex/packages/wallet_profiles/bloc/wallet_profiles_bloc.dart';
import 'package:komodo_dex/packages/wallet_profiles/state/wallet_profiles_state.dart';
import 'package:komodo_dex/packages/wallet_profiles/widgets/wallet_profile_tile.dart';
import 'package:komodo_dex/screens/authentification/authenticate_page.dart';
import 'package:komodo_dex/widgets/select_language_button.dart';

class WalletProfilesContent extends StatelessWidget {
  const WalletProfilesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<WalletProfilesBloc>(
      context,
      listen: true,
    );

    final state = bloc.state as WalletProfilesLoadSuccess;
    return Column(
      // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      children: [
        SizedBox(height: 160, child: AppLogo.full()),
        // Let system handle the language selection
        // Align(
        //     alignment: Alignment.centerRight,
        //     child: const SelectLanguageButton()),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CreateWalletButton(),
            SizedBox(width: 16),
            RestoreButton()
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          // ListView is wrapped in a Material widget to prevent the Ink of the
          // ListTile from being drawn beyond the ListView. This is a know
          // bug in Flutter: https://github.com/flutter/flutter/issues/86584
          child: Material(
            color: Colors.transparent,
            child: ListView.builder(
              addRepaintBoundaries: false,
              itemCount: state.wallets.length,
              itemBuilder: (context, index) {
                final walletProfile = state.wallets[index];
                return WalletProfileTile(
                  key: Key('wallet-profile-tile-${walletProfile.id}'),
                  walletProfile: walletProfile,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _welcomeAsset(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? 'assets/svg_light/welcome_wallet.svg'
          : 'assets/svg/welcome_wallet.svg';
}
