// ignore_for_file: non_constant_identifier_names, must_call_super, no_leading_underscores_for_local_identifiers, prefer_interpolation_to_compose_strings, use_build_context_synchronously, library_private_types_in_public_api

import 'package:animated_card/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:nodemobile/pages/Stoklar/Stok_listesi/stok_karti_ekle.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/baglanti_control.dart';
import 'package:nodemobile/widgets/sayfaya_git.dart';

class StokListesi extends StatefulWidget {
  const StokListesi({Key? key}) : super(key: key);

  @override
  _StokListesiState createState() => _StokListesiState();
}

class _StokListesiState extends State<StokListesi> {
  List allData = [];
  List matchedData = [];
  List<String> searchData = [];

  bool _absorbing = true;

  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late myDataTable X_Types;
  late myDataTable CRD_Items;
  late myDataTable L_Units;

  bool searchIsActive = false;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Widget _body = Center(
      child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [CircularProgressIndicator(), Text("Loading data...")],
  ));

  @override
  void initState() {
    _initAll();
  }

  @override
  Widget build(BuildContext context) {
    return SayfayaGit(
      route: "/",
      child: BaglantiControl(
        child: Scaffold(
            appBar: AppBar(
              title: AbsorbPointer(
                absorbing: _absorbing,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _textEditingController,
                  onChanged: _onChanged,
                  onSubmitted: _onSubmit,
                  decoration: const InputDecoration(hintText: "Search"),
                ),
              ),
              actions: [
                PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                          value: "ekle",
                          child: Row(children: const [
                            Text("Add"),
                            Icon(Icons.add, color: Colors.black)
                          ]))
                    ];
                  },
                  onSelected: (value) {
                    switch (value) {
                      case "ekle":
                        {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return StokKartiEkle(duzenleme: false);
                            },
                          )).then((value) {
                            Navigator.pushReplacementNamed(
                                context, "/stok_listesi");
                          });
                        }
                        break;
                    }
                  },
                )
              ],
            ),
            body: _body),
      ),
    );
  }

  Future _initAll() async {
    if (!await DatabaseHelper.syncCRD()) {
      showMyToast("Could not connect to server. Continuing from old data.");
    }
    await _initDatabases();

    allData.addAll(CRD_Items.rows);

    for (var element in allData) {
      List _ = [];
      for (var elementID in [1, 2]) {
        _.add(element[elementID]);
      }
      searchData.add(_.join(" ").toLowerCase());
    }
    matchedData.addAll(allData);
    _initBody();
  }

  _initDatabases() async {
    X_Types = await _databaseHelper.execute(sql: "select * from X_Types");
    CRD_Items = await _databaseHelper.execute(
        sql:
            "select ID,Name,Barcode,UnitPrice,StokAdeti,UnitID from CRD_Items");
    L_Units = await _databaseHelper.execute(sql: "select * from L_Units");
  }

  _initBody() {
    setState(() {
      _absorbing = false;
      _body = ListView.builder(
          itemBuilder: (context, index) {
            String subtitle = "";
            subtitle += "Barcode: " +
                matchedData[index][2]
                    .toString()
                    .replaceAll("null", "Data not found") +
                "\n";
            subtitle += "Price: " +
                matchedData[index][3]
                    .toString()
                    .replaceAll("null", "Data not found") +
                "\n";
            subtitle += "Unit: " +
                L_Units.rowsBy({"ID": matchedData[index][5]})[0]["UnitCode"]
                    .toString()
                    .replaceAll("null", "Data not found") +
                "\n";
            subtitle += "Stock count: " +
                matchedData[index][4]
                    .toString()
                    .replaceAll("null", "Data not found") +
                "\n";
            return AnimatedCard(
              keepAlive: true,
              direction: index % 2 == 0
                  ? AnimatedCardDirection.left
                  : AnimatedCardDirection.right,
              initDelay: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 300),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade200,
                    child: Text(matchedData[index][1][0],
                        style: const TextStyle(color: Colors.white))),
                title: Text(matchedData[index][1]),
                subtitle: Text(subtitle),
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                    return StokKartiEkle(
                      duzenleme: true,
                      id: matchedData[index][0],
                    );
                  }));
                  await Navigator.pushReplacementNamed(
                      context, "/stok_listesi");
                },
              ),
            );
          },
          itemCount: matchedData.length);
    });
  }

  void _onSubmit(String value) {
    {
      setState(() {
        searchIsActive = false;
        _focusNode.unfocus();
        _initBody();
      });
    }
  }

  void _onChanged(String value) {
    matchedData.clear();
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
    _initBody();
  } // {
  //     setState(() {
  //       matchedData.clear();
  //       allData.forEach((element) {
  //           if (element["Name"].toString().toLowerCase().contains(value.toLowerCase())) {
  //             matchedData.add(element);
  //           }
  //
  //       });
  //       _initBody();
  //     });
  // }

}
