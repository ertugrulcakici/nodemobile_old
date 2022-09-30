// ignore_for_file: camel_case_types, must_be_immutable, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nodemobile/utils/helpers.dart';

class myFloatingActionButton extends StatefulWidget {
  String mesaj;
  List mesajlar;
  List fonksiyonlar;

  myFloatingActionButton(
      {required this.mesaj,
      required this.mesajlar,
      required this.fonksiyonlar});

  @override
  _myFloatingActionButtonState createState() => _myFloatingActionButtonState();
}

class _myFloatingActionButtonState extends State<myFloatingActionButton> {
  @override
  Widget build(BuildContext context) {
    return SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: boyutOran(context) * 10),
        // marginEnd: boyutX(context, 4),
        // marginBottom: boyutX(context, 4),
        curve: Curves.bounceIn,
        overlayColor: Colors.grey,
        overlayOpacity: 0.4,
        tooltip: widget.mesaj,
        label: Text(widget.mesaj),
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 8.0,
        shape: const CircleBorder(),
        // orientation: SpeedDialOrientation.Up,
        // childMarginBottom: 2,
        // childMarginTop: 2,
        children: List.generate(widget.mesajlar.length, (index) {
          return SpeedDialChild(
            child: const Icon(Icons.add),
            backgroundColor: Colors.grey.withOpacity(0.2),
            label: widget.mesajlar[index],
            elevation: 0,
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: widget.fonksiyonlar[index],
          );
        }));
  }
}
