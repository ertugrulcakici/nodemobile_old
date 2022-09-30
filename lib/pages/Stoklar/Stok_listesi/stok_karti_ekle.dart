// ignore_for_file: non_constant_identifier_names, must_be_immutable, use_key_in_widget_constructors, prefer_interpolation_to_compose_strings, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, sort_child_properties_last, library_private_types_in_public_api

import 'dart:developer';

import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/baglanti_control.dart';

class StokKartiEkle extends StatefulWidget {
  int? id;
  bool duzenleme;
  bool? malzemeFisiEkrani = false;

  StokKartiEkle({required this.duzenleme, this.id, this.malzemeFisiEkrani});

  @override
  _StokKartiEkleState createState() => _StokKartiEkleState();
}

class _StokKartiEkleState extends State<StokKartiEkle> {
  final TextEditingController _codController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _alisController = TextEditingController();
  final TextEditingController _satisController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _paketController = TextEditingController();
  final TextEditingController _agirlikController = TextEditingController();
  final TextEditingController _alisFiyatiController = TextEditingController();

  bool _esle = true;
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Shared _shared = Shared();

  late myDataTable L_Units;
  late myDataTable X_Types;

  List L_UnitsList = [];
  List X_TypesList = [];

  int? UnitID;
  int? type;

  @override
  void initState() {
    _initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaglantiControl(
      message: "Could not connect to the server",
      exitWhenOffline: true,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.save, size: 32),
              onPressed: () async {
                await _save();
              }),
          actions: [
            Transform.rotate(
              angle: 45 * 3.14 / 180,
              child: IconButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  icon: const Icon(Icons.add, size: 32)),
            )
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
              vertical: boyutY(context, 3), horizontal: boyutX(context, 5)),
          child: SingleChildScrollView(
              child: Form(
                  key: _globalKey,
                  child: Column(
                    mainAxisAlignment: cup.MainAxisAlignment.start,
                    crossAxisAlignment: cup.CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                          textInputAction: TextInputAction.next,
                          controller: _barcodeController,
                          validator: _stringValidator,
                          decoration: InputDecoration(
                              labelText: "Barcode",
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: () async {
                                  await _tara();
                                },
                              )),
                          onSaved: (newValue) {
                            _data["Barcode"] = "'" + newValue! + "'";
                          },
                          onChanged: (value) {
                            if (_esle) {
                              setState(() => _codController.text = value);
                            }
                          }),
                      TextFormField(
                          textInputAction: TextInputAction.next,
                          controller: _codController,
                          decoration: const InputDecoration(labelText: "Code"),
                          onSaved: (newValue) {
                            _data["Code"] = "'" + newValue! + "'";
                          }),
                      Row(
                        children: [
                          cup.CupertinoSwitch(
                              value: _esle,
                              onChanged: (value) =>
                                  setState(() => _esle = value)),
                          const Text(
                            "Match code with barcode",
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      TextFormField(
                          controller: _adController,
                          textInputAction: TextInputAction.next,
                          validator: _stringValidator,
                          decoration: const InputDecoration(labelText: "Name"),
                          onSaved: (newValue) {
                            _data["Name"] = "'" + newValue! + "'";
                          }),
                      TextFormField(
                          controller: _alisController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          validator: _doubleValidator,
                          decoration:
                              const InputDecoration(labelText: "sales vat"),
                          onSaved: (newValue) {
                            _data["TaxRate"] =
                                double.parse(newValue!.replaceAll(",", "."));
                          }),
                      TextFormField(
                          controller: _satisController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          validator: _doubleValidator,
                          decoration:
                              const InputDecoration(labelText: "Buying KDV"),
                          onSaved: (newValue) {
                            _data["TaxRateToptan"] =
                                double.parse(newValue!.replaceAll(",", "."));
                          }),
                      TextFormField(
                          controller: _fiyatController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Price"),
                          onSaved: (newValue) {
                            try {
                              _data["UnitPrice"] =
                                  double.parse(newValue!.replaceAll(",", "."));
                            } catch (e) {
                              _data["UnitPrice"] = "";
                            }
                          }),
                      TextFormField(
                          controller: _paketController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "Package quantity"),
                          onSaved: (newValue) {
                            try {
                              _data["PakettekiMiktar"] =
                                  double.parse(newValue!.replaceAll(",", "."));
                            } catch (e) {
                              _data["PakettekiMiktar"] = "";
                            }
                          }),
                      TextFormField(
                          controller: _agirlikController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: "Weight"),
                          onSaved: (newValue) {
                            try {
                              _data["AgirlikGr"] =
                                  double.parse(newValue!.replaceAll(",", "."));
                            } catch (e) {
                              _data["AgirlikGr"] = "";
                            }
                          }),
                      TextFormField(
                          controller: _alisFiyatiController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "Purchase price"),
                          onSaved: (newValue) {
                            try {
                              _data["AlisFiyati"] =
                                  double.parse(newValue!.replaceAll(",", "."));
                            } catch (e) {
                              _data["AlisFiyati"] = "";
                            }
                          }),
                      DropdownButtonFormField<dynamic>(
                          hint: const Text("Chose unit"),
                          value: UnitID,
                          validator: (value) {
                            try {
                              int.parse(value.toString());
                              return null;
                            } catch (e) {
                              return "Chose a value";
                            }
                          },
                          onSaved: (value) {
                            _data["UnitID"] = value;
                          },
                          onChanged: (value) {
                            setState(() {
                              UnitID = value;
                            });
                            // _data["UnitID"] = value;
                          },
                          items: L_UnitsList.map((value) {
                            return DropdownMenuItem(
                                child: Text(value[1]), value: value[0]);
                          }).toList()),
                      DropdownButtonFormField<dynamic>(
                          hint: const Text("Type"),
                          value: type,
                          validator: (value) {
                            try {
                              int.parse(value.toString());
                              return null;
                            } catch (e) {
                              return "Choose a value";
                            }
                          },
                          onSaved: (value) {
                            _data["Type"] = value;
                          },
                          onChanged: (value) {
                            setState(() {
                              type = value;
                            });
                            // _data["UnitID"] = value;
                          },
                          items: X_TypesList.map((value) {
                            return DropdownMenuItem(
                                child: Text(value[1]), value: value[0]);
                          }).toList())
                    ],
                  ))),
        ),
      ),
    );
  }

  String? _stringValidator(String? value) {
    if (value != null) {
      if (value.isEmpty) {
        return "Enter a value";
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  String? _doubleValidator(String? value) {
    try {
      double.parse(value!.replaceAll(",", "."));
      return null;
    } catch (e) {
      return "You entered the data in the wrong format";
    }
  }

  _save() async {
    if (_globalKey.currentState!.validate()) {
      _globalKey.currentState!.save();

      String _query = "";
      log(widget.id.toString());

      if (widget.duzenleme) {
        _query =
            "select ID from CRD_Items where Barcode=${_barcodeController.text} and ID <> ${widget.id}";
      } else {
        _query =
            "select ID from CRD_Items where Barcode=${_barcodeController.text}";
      }

      myDataTable _ = await _databaseHelper.execute(sql: _query);

      if (_.rows.isNotEmpty) {
        showMyToast("The product is already registered in the system",
            error: true);
        return;
      }

      _query = "";
      if (widget.duzenleme == false) {
        List _datas = [];
        for (var element in _data.values) {
          if (element.toString().isEmpty) {
            _datas.add("null");
          } else {
            _datas.add(element);
          }
        }
        _query =
            "insert into CRD_Items (${_data.keys.map((e) => e).join(",")}, StokGiris, StokCikis, StokAdeti, Active, CreatedDate, CreatedBy) VALUES (${_datas.map((e) => e).join(", ")}, 0, 0, 0, 1, '${DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch)}', $USERID);";
      } else {
        List _datas = [];
        _data.forEach((key, value) {
          if (value.toString().isNotEmpty) {
            _datas.add("$key=$value");
          } else {
            _datas.add("$key=null");
          }
        });
        _datas.add(
            "ModifiedDate='${DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch)}'");
        _datas.add("ModifiedBy=$USERID");
        _query = """update CRD_Items set
         ${_datas.join(" , ")}
        where ID=${widget.id}""";
      }
      bool _result = await DatabaseHelper.sendData(query: _query);
      if (_result) {
        showMyToast("Successfully saved");
        Navigator.pop(context, _data);
      } else {
        showMyToast("Unsuccesfull", error: true);
      }

      if (_satisController.text != "") {
        _shared.setData("lastTaxRate", _satisController.text);
      }
      if (_alisController.text != "") {
        _shared.setData("lastTaxRateToptan", _alisController.text);
      }
      if (UnitID != null && UnitID is int) {
        _shared.setData("lastUnitID", UnitID);
      }
      if (type != null && type is int) {
        _shared.setData("lasttype", type);
      }
    }
  }

  Future _tara() async {
    String _scanResult = await FlutterBarcodeScanner.scanBarcode(
        "#ff00ff", "Cancel", false, ScanMode.DEFAULT);
    if (_scanResult != "-1") {
      setState(() {
        _barcodeController.text = _scanResult;
        if (_esle) {
          _codController.text = _scanResult;
        }
      });
    }
  }

  _initData() async {
    L_Units =
        await _databaseHelper.execute(sql: "select ID,UnitName from L_Units");
    X_Types = await _databaseHelper.execute(
        sql:
            "select Code,Name from X_Types where TableName='TRN_StockTransLines' and ColumnsName='ProductType'");
    L_UnitsList.addAll(L_Units.rows);
    X_TypesList.addAll(X_Types.rows);
    if (widget.duzenleme) {
      List __item = await DatabaseHelper.sendQuery(
          query:
              "select Code,Barcode,Name,TaxRate,TaxRateToptan,UnitID,UnitPrice,PakettekiMiktar,AgirlikGr,Type,AlisFiyati from CRD_Items where ID=${widget.id}");
      List _item = __item[0];
      setState(() {
        _codController.text = _item[0];
        _barcodeController.text = _item[1];
        _adController.text = _item[2];
        _alisController.text = _item[3];
        _satisController.text = _item[4];
        UnitID = int.parse(_item[5]);
        _data["UnitID"] = UnitID;
        _fiyatController.text = _item[6];
        _paketController.text = _item[7];
        _agirlikController.text = _item[8];
        type = int.parse(_item[9]);
        _data["Type"] = type;
        _alisFiyatiController.text = _item[10];
      });
    } else {
      if (_shared.getData("lastTaxRate") != null) {
        _satisController.text = _shared.getData("lastTaxRate").toString();
      }
      if (_shared.getData("lastTaxRateToptan") != null) {
        _alisController.text = _shared.getData("lastTaxRateToptan").toString();
      }
      if (_shared.getData("lastUnitID") != null) {
        UnitID = _shared.getData("lastUnitID");
      }
      if (_shared.getData("lasttype") != null) {
        type = _shared.getData("lasttype");
      }
    }
  }
}
