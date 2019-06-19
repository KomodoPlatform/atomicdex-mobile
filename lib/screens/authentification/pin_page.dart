import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/authenticate_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/services/db/database.dart';
import 'package:komodo_dex/services/market_maker_service.dart';
import 'package:komodo_dex/utils/encryption_tool.dart';
import 'package:pin_code_view/pin_code_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinPage extends StatefulWidget {
  final bool firstCreationPin;
  @required
  final String title;
  @required
  final String subTitle;
  @required
  final PinStatus isConfirmPin;
  final String code;
  final bool isFromChangingPin;
  final String password;
  final VoidCallback onSuccess;

  @override
  _PinPageState createState() => _PinPageState();

  const PinPage(
      {this.firstCreationPin,
      this.title,
      this.subTitle,
      this.isConfirmPin,
      this.isFromChangingPin,
      this.password,
      this.onSuccess,
      this.code});
}

class _PinPageState extends State<PinPage> {
  String _error = "";
  bool isLoading = false;

  @override
  void initState() {
    if (widget.isConfirmPin == PinStatus.CONFIRM_PIN) {
      authBloc.showPin(false);
    }
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        resizeToAvoidBottomPadding: false,
        body: !isLoading
            ? Stack(
                children: <Widget>[
                  new PinCode(
                    obscurePin: true,
                    title: Text(
                      widget.title,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold),
                    ),
                    error: _error,
                    subTitle: Text(
                      widget.subTitle,
                      style: TextStyle(color: Colors.white),
                    ),
                    codeLength: 6,
                    onCodeEntered: (code) async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      switch (widget.isConfirmPin) {
                        case PinStatus.CREATE_PIN:
                          await prefs.setString("pin_create", code);
                          MaterialPageRoute materialPage = MaterialPageRoute(
                              builder: (context) => PinPage(
                                    title:
                                        AppLocalizations.of(context).confirmPin,
                                    subTitle: AppLocalizations.of(context)
                                        .enterPinCode,
                                    code: code,
                                    isConfirmPin: PinStatus.CONFIRM_PIN,
                                    password: widget.password,
                                    isFromChangingPin: widget.isFromChangingPin,
                                  ));

                          if (widget.firstCreationPin != null &&
                              widget.firstCreationPin) {
                            Navigator.push(context, materialPage);
                          } else {
                            Navigator.pushReplacement(context, materialPage);
                          }
                          break;
                        case PinStatus.CONFIRM_PIN:
                          if (prefs.getString('pin_create') ==
                              code.toString()) {
                            var wallet = await DBProvider.db.getCurrentWallet();
                            setState(() {
                              isLoading = true;
                            });
                            if (wallet != null) {
                              await new EncryptionTool().writeData(
                                  KeyEncryption.PIN,
                                  wallet,
                                  widget.password,
                                  code.toString());
                            }

                            await new EncryptionTool().write("pin", code.toString());
                            authBloc.showPin(false);
                            authBloc.updateStatusPin(PinStatus.NORMAL_PIN);
                            if (!widget.isFromChangingPin)
                              await authBloc.login(
                                  await new EncryptionTool().read("passphrase"),
                                  widget.password);
                            Navigator.pop(context);
                            setState(() {
                              isLoading = false;
                            });
                          } else {
                            _errorPin();
                          }
                          break;
                        case PinStatus.NORMAL_PIN:
                          if (await _isPinCorrect(code)) {
                            authBloc.showPin(false);
                            if (!mm2.ismm2Running) {
                              await authBloc.login(
                                  await new EncryptionTool().read("passphrase"), null);
                            }
                            if (widget.onSuccess != null) {
                              widget.onSuccess();
                            }
                          } else {
                            _errorPin();
                          }
                          break;
                        case PinStatus.DISABLED_PIN:
                          if (await _isPinCorrect(code)) {
                            SharedPreferences.getInstance().then((data) {
                              data.setBool("switch_pin", false);
                            });
                            Navigator.pop(context);
                          } else {
                            _errorPin();
                          }
                          break;
                        case PinStatus.DISABLED_PIN_BIOMETRIC:
                          if (await _isPinCorrect(code)) {
                            SharedPreferences.getInstance().then((data) {
                              data.setBool("switch_pin_biometric", false);
                            });
                            Navigator.pop(context);
                          } else {
                            _errorPin();
                          }
                          break;
                        case PinStatus.CHANGE_PIN:
                          if (await _isPinCorrect(code)) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PinPage(
                                          title: AppLocalizations.of(context)
                                              .createPin,
                                          subTitle: AppLocalizations.of(context)
                                              .enterPinCode,
                                          isConfirmPin: PinStatus.CREATE_PIN,
                                          password: widget.password,
                                          isFromChangingPin: true,
                                        )));
                          } else {
                            _errorPin();
                          }
                          break;
                      }
                    },
                  ),
                  Positioned(
                    bottom: 28,
                    left: 75,
                    child: InkWell(
                      onTap: () {
                        authBloc.logout();
                        authBloc.showPin(false);
                        if (widget.isConfirmPin != PinStatus.CREATE_PIN &&
                            widget.isConfirmPin != PinStatus.NORMAL_PIN) {
                          Navigator.pop(context);
                        }
                      },
                      child: Icon(
                        Icons.exit_to_app,
                        color: Colors.red.withOpacity(0.7),
                        size: 32,
                      ),
                    ),
                  )
                ],
              )
            : _buildLoading());
  }

  _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(
            height: 8,
          ),
          Text("Configuring your wallet, please wait...")
        ],
      ),
    );
  }

  _errorPin() {
    setState(() {
      _error = AppLocalizations.of(context).errorTryAgain;
    });
  }

  Future<bool> _isPinCorrect(String code) async {
    return await new EncryptionTool().read("pin") == code.toString();
  }
}