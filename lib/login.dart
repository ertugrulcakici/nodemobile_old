// ignore_for_file: non_constant_identifier_names, use_key_in_widget_constructors, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, library_private_types_in_public_api, sort_child_properties_last

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodemobile/pages/setup_screen.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:path_provider/path_provider.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool done = false;

  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Shared _shared;
  final TextEditingController _usernameCT = TextEditingController();
  final TextEditingController _passwordCT = TextEditingController();
  final TextEditingController _licenseTextController = TextEditingController();
  bool _beniHatirla = false;

  @override
  void initState() {
    _shared = Shared();
    _shared.check().then((value) async {
      if (value) {
        // daha önce kurulduysa
        if (await _databaseHelper.createTable(context, "X_Users", true) ==
            false) {
          showMyToast("User information could not be updated", error: true);
        } else {
          showMyToast("User informations updated");
        }
        setState(() {
          if (_shared.getData("benihatirla") == null) {
            _shared.setData("benihatirla", false);
            _beniHatirla = false;
          } else {
            _beniHatirla = _shared.getData("benihatirla");
            if (_beniHatirla == true) {
              _usernameCT.text = _shared.getData("username").toString();
              _passwordCT.text = _shared.getData("password").toString();
            }
          }
        });
      } else {
        // setupsa
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return setupScreen();
        }));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool cikis = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Are you sure you want to exit ? "),
                actions: [
                  TextButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      label: const Text("Evet"),
                      icon: const Icon(Icons.logout, color: Colors.grey)),
                  TextButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      label: const Text("Hayır"),
                      icon: const Icon(Icons.cancel, color: Colors.red)),
                ],
              );
            });
        return Future.value(cikis);
      },
      child: Scaffold(
        body: Stack(children: [
          Center(
              child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                    child: Image.asset("assets/images/logo.png"),
                    height: boyutY(context, 35)),
                SizedBox(height: boyutY(context, 5)),
                TextField(
                  controller: _usernameCT,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                SizedBox(height: boyutY(context, 2)),
                TextField(
                    controller: _passwordCT,
                    decoration: const InputDecoration(labelText: "Password"),
                    keyboardType: TextInputType.visiblePassword,
                    obscuringCharacter: "*",
                    obscureText: true),
                CheckboxListTile(
                  title: const Text("Remember me"),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _beniHatirla,
                  onChanged: (value) {
                    setState(() {
                      _beniHatirla = value!;
                      _shared.setData("benihatirla", value);
                    });
                  },
                ),
                OutlinedButton.icon(
                    onPressed: _girisYap,
                    label: const Text("Login"),
                    icon: const Icon(Icons.login))
              ],
            ),
          )),
          Positioned(
              right: boyutY(context, 3),
              bottom: boyutY(context, 3),
              child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.black,
                    size: 64,
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Scaffold(
                        floatingActionButton: FloatingActionButton.extended(
                            icon: const Icon(Icons.save),
                            onPressed: () async {
                              if (_key.currentState!.validate()) {
                                _key.currentState!.save();
                                if (await _databaseHelper.createTable(
                                        context, "X_Users", true) ==
                                    false) {
                                  showMyToast(
                                      "User information could not be updated",
                                      error: true);
                                } else {
                                  showMyToast("User information updated");
                                }
                                Navigator.pop(context);
                              }
                            },
                            label: const Text("Save")),
                        body: Form(
                          key: _key,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: createForms(_shared, setup: false),
                            ),
                          ),
                        ),
                      );
                    }));
                  }))
        ]),
      ),
    );
  }

  _girisYap() async {
    if (!(await _checkLicenseValid())) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      var _androidInfo = await deviceInfo.androidInfo;
      bool? _activated = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Your trial has expired !"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _licenseTextController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        labelText: "Licanse key"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("ID: ${_androidInfo.androidId.toString()}"),
                      IconButton(
                          tooltip: "Copy",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: _androidInfo.androidId.toString()));
                            showMyToast("Copied !");
                          },
                          icon: const Icon(
                            Icons.copy,
                            color: Colors.grey,
                          )),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () async {
                      if (encrypt(_androidInfo.androidId.toString()) ==
                          _licenseTextController.text) {
                        File _file = File(
                            "/${(await getExternalStorageDirectory())!.path.split("/").getRange(1, 4).join("/")}/unixtime.txt");
                        await _file.delete();
                        showMyToast("Licanse has activited !");
                        Navigator.pop(context, true);
                      } else {
                        showMyToast("Licanse key is not valid", error: true);
                      }
                    },
                    child: const Text("Active"))
              ],
            );
          });
      if (_activated == true) {
        _girisYap();
      }
    } else {
      String _query =
          "select ID from X_Users where LogonName='${_usernameCT.text}' and Password='${_passwordCT.text}';";
      myDataTable result = await _databaseHelper.execute(sql: _query);
      if (result.rows.isEmpty) {
        // şifre bulunamayınca
        showMyToast("Username or password is wrong !", error: true);
        setState(() {
          _usernameCT.text = "";
          _passwordCT.text = "";
        });
      } else {
        // şifre bulunca
        setState(() {
          loggedIn = true;
          USERID = result.rows[0][0];
          _shared.setData("username", _usernameCT.text);
          _shared.setData("password", _passwordCT.text);
          Navigator.pushReplacementNamed(context, "/");
        });
      }
    }
  }

  Future<bool> _checkLicenseValid() async {
    File _file = File(
        "/${(await getExternalStorageDirectory())!.path.split("/").getRange(1, 4).join("/")}/unixtime.txt");
    if (_file.existsSync()) {
      int? _unixtime = await getIstanbulUnixtime();
      int _start_unixtime = int.parse(_file.readAsStringSync());
      if (_unixtime != null) {
        DateTime _start_unixtime_time =
            DateTime.fromMillisecondsSinceEpoch(_start_unixtime * 1000);
        DateTime _unixtime_time =
            DateTime.fromMillisecondsSinceEpoch(_unixtime * 1000);
        int _timeDelta = _unixtime_time.difference(_start_unixtime_time).inDays;
        if (_timeDelta >= 15) {
          return false;
        }
      }
    }
    return true;
  }
}
