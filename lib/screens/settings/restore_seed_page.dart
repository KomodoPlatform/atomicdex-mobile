import 'package:flutter/material.dart';
import '../../app_config/theme_data.dart';
import '../../blocs/dialog_bloc.dart';
import '../../localizations.dart';
import '../authentification/create_password_page.dart';
import '../../utils/utils.dart';
import '../../widgets/custom_simple_dialog.dart';
import '../../widgets/password_visibility_control.dart';
import '../../widgets/primary_button.dart';
import 'package:bip39/bip39.dart' as bip39;

class RestoreSeedPage extends StatefulWidget {
  @override
  _RestoreSeedPageState createState() => _RestoreSeedPageState();
}

class _RestoreSeedPageState extends State<RestoreSeedPage> {
  TextEditingController controllerSeed = TextEditingController();
  bool _isButtonDisabled = false;
  bool _isLogin;
  bool _isSeedHidden = true;
  bool _checkBox = false;

  @override
  void initState() {
    _isLogin = false;
    _isButtonDisabled = true;
    super.initState();
  }

  @override
  void dispose() {
    controllerSeed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context).login[0].toUpperCase()}${AppLocalizations.of(context).login.substring(1)}'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: <Widget>[
          const SizedBox(height: 32),
          _buildTitle(),
          const SizedBox(height: 64),
          SizedBox(height: 24),
          _buildInputSeed(),
          SizedBox(height: 8),
          _buildCheckBoxCustomSeed(),
          SizedBox(height: 24),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      AppLocalizations.of(context).enterSeedPhrase,
      style: Theme.of(context).textTheme.headline6,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInputSeed() {
    return TextField(
      key: const Key('restore-seed-field'),
      controller: controllerSeed,
      onChanged: (String str) {
        _checkSeed(str);
      },
      autocorrect: false,
      keyboardType: TextInputType.multiline,
      obscureText: _isSeedHidden,
      enableInteractiveSelection: true,
      toolbarOptions: ToolbarOptions(
        paste: controllerSeed.text.isEmpty,
        copy: false,
        cut: false,
        selectAll: false,
      ),
      maxLines: _isSeedHidden ? 1 : null,
      style: Theme.of(context).textTheme.bodyText2,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).exampleHintSeed,
        suffixIcon: PasswordVisibilityControl(
          onVisibilityChange: (bool isObscured) {
            if (mounted)
              setState(() {
                _isSeedHidden = isObscured;
              });
          },
        ),
      ),
    );
  }

  void _checkSeed(String str) {
    if (_checkBox) {
      if (str.isNotEmpty) {
        setState(() {
          _isButtonDisabled = false;
        });
      } else {
        setState(() {
          _isButtonDisabled = true;
        });
      }
    } else {
      if (bip39.validateMnemonic(str)) {
        setState(() {
          _isButtonDisabled = false;
        });
      } else {
        setState(() {
          _isButtonDisabled = true;
        });
      }
    }
  }

  Widget _buildCheckBoxCustomSeed() {
    return CheckboxListTile(
      key: const Key('checkbox-custom-seed'),
      value: _checkBox,
      onChanged: (bool data) async {
        final bool confirmed = await _showCustomSeedWarning(data);
        if (!confirmed) return;
        setState(() {
          _checkBox = !_checkBox;
          _checkSeed(controllerSeed.text);
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.all(0),
      title: Text(
        AppLocalizations.of(context).allowCustomSeed,
        style: Theme.of(context).textTheme.bodyText1,
      ),
    );
  }

  Future<bool> _showCustomSeedWarning(bool value) async {
    if (!value) return true;

    dialogBloc.dialog = Future<void>(() {});
    final bool confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          bool enabled = false;
          return StatefulBuilder(builder: (context, setState) {
            return CustomSimpleDialog(
              title: Text(AppLocalizations.of(context).warning),
              children: [
                Text(AppLocalizations.of(context).customSeedWarning(
                    AppLocalizations.of(context).iUnderstand)),
                Theme(
                  data: Theme.of(context).copyWith(
                      inputDecorationTheme: gefaultUnderlineInputTheme),
                  child: TextField(
                    autofocus: true,
                    onChanged: (String text) {
                      setState(() {
                        enabled = text.trim().toLowerCase() ==
                            AppLocalizations.of(context)
                                .iUnderstand
                                .toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context).cancelButton),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: !enabled
                          ? null
                          : () {
                              Navigator.pop(context, true);
                            },
                      child: Text(AppLocalizations.of(context).okButton),
                    ),
                  ],
                )
              ],
            );
          });
        });
    dialogBloc.dialog = null;

    return confirmed == true;
  }

  Widget _buildConfirmButton() {
    return _isLogin
        ? const Center(child: CircularProgressIndicator())
        : PrimaryButton(
            key: const Key('confirm-seed-button'),
            text: AppLocalizations.of(context).confirm,
            onPressed: _isButtonDisabled ? null : _onLoginPressed);
  }

  void _onLoginPressed() {
    setState(() {
      _isButtonDisabled = true;
      _isLogin = true;
    });
    unfocusEverything();

    Navigator.pushReplacement<dynamic, dynamic>(
      context,
      MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => CreatePasswordPage(
                seed: controllerSeed.text.toString(),
              )),
    );
  }
}
