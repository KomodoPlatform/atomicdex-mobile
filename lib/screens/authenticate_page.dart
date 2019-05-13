import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/authenticate_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/screens/bloc_login_page.dart';
import 'package:komodo_dex/screens/new_account_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticatePage extends StatefulWidget {
  @override
  _AuthenticatePageState createState() => _AuthenticatePageState();
}

class _AuthenticatePageState extends State<AuthenticatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          SizedBox(
            height: 40,
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                    height: 100,
                    width: 100,
                    child: Image.asset("assets/logo_kmd.png")),
                SizedBox(
                  height: 25,
                ),
                Text(
                  AppLocalizations.of(context).appName,
                  style: Theme.of(context).textTheme.title,
                )
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 52, right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0)),
                        color: Theme.of(context).buttonColor,
                        disabledColor: Theme.of(context).disabledColor,
                        child: Text(
                          AppLocalizations.of(context).login.toUpperCase(),
                          style: Theme.of(context).textTheme.button,
                        ),
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BlocLoginPage()),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0)),
                        disabledColor: Theme.of(context).disabledColor,
                        child: Text(
                          AppLocalizations.of(context).newAccount.toUpperCase(),
                          style: Theme.of(context).textTheme.button,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NewAccountPage()),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: 100,
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
