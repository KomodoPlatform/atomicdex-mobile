import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/authenticate_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/screens/authentification/authenticate_page.dart';
import 'package:komodo_dex/screens/authentification/create_password_page.dart';
import 'package:komodo_dex/screens/authentification/pin_page.dart';
import 'package:komodo_dex/services/market_maker_service.dart';
import 'package:komodo_dex/utils/encryption_tool.dart';
import 'package:komodo_dex/widgets/shared_preferences_builder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockScreen extends StatefulWidget {
  final PinStatus pinStatus;
  final Widget child;
  final Function onSuccess;

  LockScreen({this.pinStatus = PinStatus.NORMAL_PIN, this.child, this.onSuccess});

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String password;

  @override
  Widget build(BuildContext context) {
    final ScreenArguments args = ModalRoute.of(context).settings.arguments;
    password = args?.password;
    return StreamBuilder<bool>(
      stream: authBloc.outIsLogin,
      initialData: authBloc.isLogin,
      builder: (context, isLogin) {
        return StreamBuilder(
          initialData: authBloc.pinStatus,
          stream: authBloc.outpinStatus,
          builder: (context, outShowCreatePin) {
            if (outShowCreatePin.hasData &&
                (outShowCreatePin.data == PinStatus.NORMAL_PIN)) {
              if (isLogin.hasData && isLogin.data) {
                return StreamBuilder(
                    initialData: authBloc.isPinShow,
                    stream: authBloc.outShowPin,
                    builder: (context, outShowPin) {
                      return SharedPreferencesBuilder(
                        pref: 'switch_pin',
                        builder: (context, switchPinData){
                          if (outShowPin.hasData &&
                              outShowPin.data &&
                              switchPinData.hasData &&
                              switchPinData.data) {
                            return Stack(
                              children: <Widget>[
                                FutureBuilder(
                                  future: _checkBiometrics(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (snapshot.hasData && snapshot.data) {
                                      print(snapshot.data);
                                      _authenticateBiometrics();
                                      return Container();
                                    }
                                    return Container();
                                  },
                                ),
                                PinPage(
                                  title:
                                      AppLocalizations.of(context).lockScreen,
                                  subTitle:
                                      AppLocalizations.of(context).enterPinCode,
                                  isConfirmPin: widget.pinStatus,
                                  isFromChangingPin: false,
                                  onSuccess: widget.onSuccess,
                                ),
                              ],
                            );
                          } else {
                            if (widget.child == null && (widget.pinStatus == PinStatus.DISABLED_PIN || widget.pinStatus == PinStatus.DISABLED_PIN_BIOMETRIC))
                              return PinPage(
                                  title:
                                      AppLocalizations.of(context).lockScreen,
                                  subTitle:
                                      AppLocalizations.of(context).enterPinCode,
                                  isConfirmPin: widget.pinStatus,
                                  isFromChangingPin: false,
                                );
                            else
                              return widget.child;
                          }
                        },
                      );
                    });
              } else {
                return AuthenticatePage();
              }
            } else {
              return PinPage(
                title: AppLocalizations.of(context).createPin,
                subTitle: AppLocalizations.of(context).enterPinCode,
                firstCreationPin: true,
                isConfirmPin: PinStatus.CREATE_PIN,
                password: password,
                isFromChangingPin: false,
              );
            }
          },
        );
      },
    );
  }

  Future<bool> _authenticateBiometrics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("switch_pin_biometric")) {
      var localAuth = LocalAuthentication();

      bool didAuthenticate = await localAuth.authenticateWithBiometrics(
          stickyAuth: true,
          localizedReason: AppLocalizations.of(context).lockScreenAuth);
      if (didAuthenticate) {
        if (widget.pinStatus == PinStatus.DISABLED_PIN) {
          SharedPreferences.getInstance().then((data) {
            data.setBool("switch_pin", false);
          });
          Navigator.pop(context);
        }
        authBloc.showPin(false);
        if (widget.pinStatus == PinStatus.NORMAL_PIN && !mm2.ismm2Running) {
          await authBloc.login(await new EncryptionTool().read("passphrase"), null);
        }
      }
      return didAuthenticate;
    } else {
      return false;
    }
  }

  Future<bool> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      print(canCheckBiometrics);
    } on PlatformException catch (e) {
      print(e);
    }
    return canCheckBiometrics;
  }
}