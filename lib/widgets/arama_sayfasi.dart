// ignore_for_file: must_be_immutable, use_key_in_widget_constructors, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, prefer_interpolation_to_compose_strings, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';

class AramaSayfasi extends StatefulWidget {
  Map<int, String>? altsatirlar = {};
  List<int> aranacakColumnlar;
  String label;
  var data;

  /// aranacakColumnlar -> Aranacak columnlar
  /// Displays -> key, hangi sıradaki data; value, datanın solundaki açıklaması
  /// label -> Üstte çıkacak label
  /// data -> ya myDataTable ya da List
  /// Eğer hiç display seçilmezse 1. de ne varsa onu gösterir
  AramaSayfasi(
      {required this.label,
      required this.data,
      required this.aranacakColumnlar,
      this.altsatirlar});

  @override
  _AramaSayfasiState createState() => _AramaSayfasiState();
}

class _AramaSayfasiState extends State<AramaSayfasi> {
  List allData = [];
  List matchedData = [];
  List<String> searchData = [];

  @override
  void initState() {
    initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: SafeArea(
        child: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        matchedData.clear();
                      });
                      List<String> _values = value.toLowerCase().split(" ");

                      for (int index = 0; index < searchData.length; index++) {
                        int len = 0;
                        for (String _value in _values) {
                          if (searchData[index].contains(_value)) {
                            len++;
                          }
                        }
                        if (len == _values.length) {
                          matchedData.add(allData[index]);
                        }
                      }
                    },
                    decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        border: const OutlineInputBorder(),
                        labelText: widget.label),
                  ),
                  Expanded(
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: matchedData.length,
                        itemBuilder: (context, index) {
                          String explanation = "";
                          List _explanation = [];
                          if (widget.altsatirlar != null) {
                            widget.altsatirlar!.forEach((key, value) {
                              _explanation.add(value +
                                  ": " +
                                  matchedData[index][key].toString());
                            });
                          }
                          explanation = _explanation.join("\n");
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            tileColor: index % 2 == 0
                                ? myThemeData.acikGolden
                                : Colors.white,
                            onTap: () =>
                                Navigator.pop(context, matchedData[index]),
                            title: matchedData[index].length > 1
                                ? Text(matchedData[index][1].toString())
                                : Text(matchedData[index][0].toString()),
                            subtitle:
                                explanation != "" ? Text(explanation) : null,
                          );
                        }),
                  ),
                ]))),
      ),
    );
  }

  void initData() async {
    if (widget.data is myDataTable) {
      allData.addAll(widget.data.rows);
    } else {
      allData.addAll(widget.data);
    }
    for (var element in allData) {
      List _ = [];
      for (var elementID in widget.aranacakColumnlar) {
        _.add(element[elementID]);
      }
      searchData.add(_.join(" ").toLowerCase());
    }
    matchedData.addAll(allData);
  }
}
