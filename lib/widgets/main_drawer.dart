// ignore_for_file: must_be_immutable, camel_case_types, use_key_in_widget_constructors, sort_child_properties_last, library_private_types_in_public_api

import 'package:animated_card/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:nodemobile/utils/helpers.dart';

class mainDrawer extends StatefulWidget {
  const mainDrawer({Key? key}) : super(key: key);

  @override
  _mainDrawerState createState() => _mainDrawerState();
}

class _mainDrawerState extends State<mainDrawer> {
  // late Logger _logger;
  @override
  void initState() {
    // _logger = Logger();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 4,
      child: ListView(
        children: [
          const UserAccountsDrawerHeader(
              accountName:
                  Text("", style: TextStyle(color: Colors.black, fontSize: 22)),
              accountEmail: Text("", style: TextStyle(color: Colors.black)),
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/logo.png"),
                      fit: BoxFit.fitWidth))),
          myExpansionTile(title: "Stocks", icon: Icons.check_box, children: [
            myListTile(
                title: "Stock list",
                icon: Icons.check_box,
                path: "/stok_listesi"),
            myListTile(
                title: "Goods acceptance and material transactions",
                icon: Icons.receipt_long_sharp,
                path: "/malzeme_fisleri"),
          ]),
          myExpansionTile(
              title: "Retail",
              icon: Icons.shopping_cart_outlined,
              children: [
                myListTile(
                  title: "Label printing and price change slips",
                  icon: Icons.print,
                  function: () {
                    showMyToast("The under construction");
                  },
                ),
                myListTile(
                  title: "Missing list",
                  icon: Icons.list_alt_sharp,
                  function: () {
                    showMyToast("The under construction");
                  },
                ),
                myListTile(
                  title: "See price",
                  icon: Icons.monetization_on_sharp,
                  function: () {
                    showMyToast("The under construction");
                  },
                ),
              ]),
          myListTile(
            icon: Icons.settings,
            title: "Settings",
            path: "/ayarlar",
          ),
        ],
      ),
    );
  }
}

class myExpansionTile extends StatelessWidget {
  String title;
  List<Widget> children;
  IconData? icon;

  myExpansionTile({required this.title, required this.children, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: AnimatedCard(
        initDelay: const Duration(milliseconds: 0),
        duration: const Duration(milliseconds: 400),
        direction: AnimatedCardDirection.left,
        child: ExpansionTile(
            title: Text(title),
            children: children,
            leading: icon == null ? null : Icon(icon, color: Colors.black)),
      ),
    );
  }
}

class myListTile extends StatelessWidget {
  String? path;
  IconData? icon;
  String title;
  Function? function;

  myListTile({this.function, this.path, this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    if (function != null && path != null) {
      throw "Aynı anda hem fonksiyon hem yol verilemez";
    }
    return Padding(
        padding: const EdgeInsets.all(10),
        child: AnimatedCard(
          initDelay: const Duration(milliseconds: 0),
          duration: const Duration(milliseconds: 400),
          direction: AnimatedCardDirection.left,
          child: ListTile(
            onTap: () {
              if (path != null) Navigator.pushNamed(context, path!);
              if (function != null) function!();
            },
            title: Text(title),
            leading: icon == null
                ? null
                : Icon(
                    icon,
                    color: Colors.black,
                  ),
          ),
        ));
  }
}
