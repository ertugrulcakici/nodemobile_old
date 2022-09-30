// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/contants/routes.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/main_drawer.dart';
import 'package:web_browser/web_browser.dart';

class Anasayfa extends StatefulWidget {
  @override
  _AnasayfaState createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  Widget body = const Center(child: CircularProgressIndicator());
  late Shared _shared;

  @override
  void initState() {
    _shared = Shared();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (loggedIn == false) {
      Future.delayed(const Duration(milliseconds: 200),
          () => Routes.login.pushReplacementNamed(context));
    }
    return WillPopScope(
      onWillPop: _exit,
      child: Scaffold(
        drawer: const mainDrawer(),
        appBar: AppBar(
            title: const Text("NodeMobile Hand Terminal"), centerTitle: true),
        body: Center(
            child: GridView.count(crossAxisCount: 2, children: [
          anaEkranButon(
              label: Routes.stok_listesi.label,
              path: Routes.stok_listesi.routeName,
              icon: Icons.check_box),
          anaEkranButon(
              label: Routes.malzeme_fisleri.label,
              path: Routes.malzeme_fisleri.routeName,
              icon: Icons.receipt_long_sharp),
          anaEkranButon(
              label: Routes.etiket_basim.label,
              path: Routes.etiket_basim.routeName,
              icon: Icons.print),
          anaEkranButon(
              label: Routes.fiyat_gor.label,
              path: Routes.fiyat_gor.routeName,
              icon: Icons.monetization_on_sharp),
          anaEkranButon(
              label: Routes.ayarlar.label,
              path: Routes.ayarlar.routeName,
              icon: Icons.settings),
          Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return SafeArea(
                      child: Scaffold(
                        body: Center(
                          child: WebBrowser(
                              javascriptEnabled: true,
                              debuggingEnabled: false,
                              interactionSettings:
                                  const WebBrowserInteractionSettings(
                                topBar: null,
                                bottomBar: null,
                              ),
                              // iframeSettings: WebBrowserIFrameSettings(
                              // ),
                              initialUrl:
                                  "${_shared.getData("web_url")}?username=${_shared.getData("web_username")}&password=${_shared.getData("web_password")}"),
                        ),
                      ),
                    );
                  }));
                },
                child: Card(
                  elevation: 3,
                  child: Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.web, size: 48, color: Colors.black),
                      Text("Web application",
                          textAlign: TextAlign.center,
                          style: myThemeData.boldBlack18
                              .copyWith(color: Colors.black)),
                    ],
                  )),
                )),
          ),
        ])),
      ),
    );
  }

  Widget anaEkranButon(
      {required String label,
      required var icon,
      String? path,
      String? errorMessage}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
          onTap: () {
            if (path != null) {
              Navigator.pushNamed(context, path);
            }
            if (errorMessage != null) {
              showMyToast(errorMessage);
            }
          },
          child: Card(
            elevation: 3,
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.black,
                ),
                Text(label,
                    textAlign: TextAlign.center,
                    style:
                        myThemeData.boldBlack18.copyWith(color: Colors.black)),
              ],
            )),
          )),
    );
  }

  Future<bool> _exit() async {
    bool cikis = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Are you sure you want to exit ? "),
            actions: [
              TextButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  label: const Text("Yes"),
                  icon: const Icon(Icons.logout, color: Colors.grey)),
              TextButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  label: const Text("No"),
                  icon: const Icon(Icons.cancel, color: Colors.red)),
            ],
          );
        });
    return Future.value(cikis);
  }
}
