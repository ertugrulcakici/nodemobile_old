// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:nodemobile/login.dart';
import 'package:nodemobile/pages/Perakende/Etiket_basim/etiket_basim.dart';
import 'package:nodemobile/pages/Perakende/fiyat_gor.dart';
import 'package:nodemobile/pages/Stoklar/Malzeme_fisleri/malzeme_fisleri_main.dart';
import 'package:nodemobile/pages/Stoklar/Stok_listesi/stok_listesi.dart';
import 'package:nodemobile/pages/anasayfa.dart';
import 'package:nodemobile/pages/ayarlar.dart';

class Routes {
  static final Map<String, WidgetBuilder> routes = {
    home.routeName: home.routeFunction,
    login.routeName: login.routeFunction,
    stok_listesi.routeName: stok_listesi.routeFunction,
    malzeme_fisleri.routeName: malzeme_fisleri.routeFunction,
    etiket_basim.routeName: etiket_basim.routeFunction,
    ayarlar.routeName: ayarlar.routeFunction,
    fiyat_gor.routeName: fiyat_gor.routeFunction
  };

  static final RouteObj home = RouteObj("/", Anasayfa(), "Home page");
  static final RouteObj login = RouteObj("/login", Login(), "Login screen");
  static final RouteObj stok_listesi =
      RouteObj("/stok_listesi", const StokListesi(), "Stock list");
  static final RouteObj malzeme_fisleri = RouteObj("/malzeme_fisleri",
      MalzemeFisleriMain(), "Goods acceptance and material transactions");
  static final RouteObj etiket_basim =
      RouteObj("/etiket_basim", const EtiketBasim(), "Label printing");
  static final RouteObj ayarlar =
      RouteObj("/ayarlar", const Ayarlar(), "Settings");
  static final RouteObj fiyat_gor =
      RouteObj("/fiyat_gor", FiyatGor(), "Product price");
}

class RouteObj {
  final String routeName;
  final Widget widget;
  final String label;
  get routeFunction => (BuildContext context) => widget;

  RouteObj(this.routeName, this.widget, this.label);

  Future<void> pushNamed(BuildContext context) async {
    await Navigator.pushNamed(context, routeName);
  }

  Future<void> pushAndRemoveUntil(BuildContext context) async {
    await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => routeFunction),
        (Route<dynamic> route) => false);
  }

  Future<void> pushReplacementNamed(BuildContext context) async {
    await Navigator.pushReplacementNamed(context, routeName);
  }
}
