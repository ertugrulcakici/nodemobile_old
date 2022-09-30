// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/my_divider.dart';

List<String> tables = [
  "L_Units",
  "CRD_Items",
  "X_Types",
  "X_Settings",
  "TRN_StockTrans"
];

class BaglantiAyarlari extends StatefulWidget {
  @override
  _BaglantiAyarlariState createState() => _BaglantiAyarlariState();
}

class _BaglantiAyarlariState extends State<BaglantiAyarlari> {
  late Shared shared;
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  @override
  void initState() {
    shared = Shared();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _save,
          child: const Icon(Icons.save),
        ),
        extendBody: true,
        body: Padding(
          padding: EdgeInsets.all(boyutOran(context) * 15),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: _key,
                  child: Column(
                    children: [
                      _createTextField(
                          key: "remote_ip", type: "String", label: "IP"),
                      _createTextField(
                          key: "remote_port", type: "int", label: "Port"),
                      myDivider(
                          axis: Axis.horizontal, gradient: true, thickness: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    try {
      _key.currentState!.save();
      showMyToast("Settings saved");
    } catch (e) {
      showMyToast("Error: ${e.toString()}");
    }
  }

  _createTextField(
      {required String key, required String type, required String label}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: boyutY(context, 1)),
      child: TextFormField(
        decoration: InputDecoration(
            border: const OutlineInputBorder(), labelText: label),
        initialValue: shared.getData(key).toString(),
        onSaved: (newValue) {
          if (type == "int") {
            shared.setData(key, int.parse(newValue!.toString()));
          } else if (type == "double") {
            shared.setData(key, double.parse(newValue!.toString()));
          } else if (type == "String") {
            shared.setData(key, newValue!.toString());
          } else {
            shared.setData(key, newValue!.toString());
          }
        },
      ),
    );
  }
}
