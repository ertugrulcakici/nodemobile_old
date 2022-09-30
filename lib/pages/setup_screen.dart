// ignore_for_file: camel_case_types, use_key_in_widget_constructors, use_build_context_synchronously, no_leading_underscores_for_local_identifiers, prefer_interpolation_to_compose_strings, library_private_types_in_public_api

import 'dart:developer';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/arama_sayfasi.dart';

class setupScreen extends StatefulWidget {
  @override
  _setupScreenState createState() => _setupScreenState();
}

class _setupScreenState extends State<setupScreen> {
  String _licanseText = "";
  String _androidID = "";
  late Shared _shared;
  late List forms;
  late GlobalKey<FormState> _key;
  late DatabaseHelper _databaseHelper;

  @override
  void initState() {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    deviceInfo.androidInfo.then((value) {
      setState(() {
        _androidID = value.androidId.toString();
      });
    });
    _databaseHelper = DatabaseHelper();
    _key = GlobalKey<FormState>();
    _shared = Shared();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_key.currentState!.validate()) {
            _key.currentState!.save();
            if (await _checkLicanse()) {
              await _save();
            } else {
              // lisans doğrulanmazsa
              showMyToast("Invalid license key", error: true);
              bool? _continue = await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                          "Would you like to continue with the demo version ?"),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              Navigator.pop(context, true);
                            },
                            child: const Text("Yes")),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text("I have a license key")),
                      ],
                    );
                  });
              if (_continue == true) {
                if (await getAndWriteIstanbulUnixtime()) {
                  await _save();
                } else {
                  showMyToast("Check your internet connection and try again",
                      error: true);
                }
              }
            }
          }
        },
        label: const Text("Save"),
        icon: const Icon(Icons.check),
      ),
      body: ListView(children: [
        Image.asset("assets/images/logo.png"),
        Container(
          constraints: BoxConstraints(maxWidth: boyutX(context, 70)),
          child: Card(
              elevation: 12,
              child: Align(
                  alignment: Alignment.topCenter,
                  child: Form(
                      key: _key,
                      child: Padding(
                          padding: EdgeInsets.all(boyutY(context, 5)),
                          child: Column(
                            children: [
                              ...createForms(_shared, setup: true),
                              TextFormField(
                                onSaved: (newValue) {
                                  _licanseText = newValue.toString();
                                },
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.vpn_key_outlined),
                                    labelText: "License key"),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("ID: " + _androidID),
                                  IconButton(
                                      tooltip: "Copy",
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: _androidID));
                                        showMyToast("Copied to clipboard");
                                      },
                                      icon: const Icon(
                                        Icons.copy,
                                        color: Colors.grey,
                                      )),
                                ],
                              ),
                            ],
                          ))))),
        ),
      ]),
    );
  }

  Future<bool> _checkLicanse() async {
    if (_licanseText == encrypt(_androidID)) {
      return true;
    } else {
      return false;
    }
  }

  Future _save() async {
    var data = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => DatabaseDownloadScreen()));
    if (!(await _databaseHelper.executeCommit(
        sql:
            """create view if not exists V_AllItems as select ID,Name,Barcode,UnitID,Active,Code,OzelKod,Name2,TradeMark,Type,TaxRate,TaxRateToptan,UnitPrice,UnitPrice2,UnitPrice3,AlisFiyati,PakettekiMiktar,AgirlikGr,StokAdeti,StokGiris,StokCikis,CreatedDate,ModifiedDate,ModifiedBy,CreatedBy,UrunRenk,HedefKarMarji, 1 as Miktar, '' as Aciklama,0 as VaryantID from CRD_Items
UNION ALL
SELECT        I.ID, I.Name, IB.Barkod AS Barcode, I.UnitID, I.Active, I.Code, I.OzelKod, I.Name2, I.TradeMark, I.Type, I.TaxRate,I.TaxRateToptan, IB.Fiyat AS UnitPrice, IB.Fiyat2 AS UnitPrice2, IB.Fiyat3 AS UnitPrice3, I.AlisFiyati * IB.Miktar AS Expr1, I.PakettekiMiktar, 
                         I.AgirlikGr, I.StokAdeti, I.StokGiris, I.StokCikis, I.CreatedDate, I.ModifiedDate, I.ModiFiedBy, I.CreatedBy, IB.Renk AS UrunRenk, I.HedefKarMarji, IB.Miktar, IB.Aciklama,IB.ID as VaryantID 
FROM            CRD_Items AS I INNER JOIN
                         CRD_ItemBarcodes AS IB ON I.ID = IB.UrunID"""))) {
      showMyToast("Error while saving data", error: true);
      return;
    }
    if (data == true) {
      // defaultları kuruyor
      try {
        myDataTable branchList = await _databaseHelper.execute(
            sql: "select BranchNo,Name from X_Branchs");
        List branch = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AramaSayfasi(
                    label: "Choose branch",
                    data: branchList,
                    aranacakColumnlar: const [1])));
        _shared.setData("BranchNo", branch[0]);

        myDataTable girisDepoList = await _databaseHelper.execute(
            sql: "select ID,Name from CRD_StockWareHouse");
        List girisDepo = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AramaSayfasi(
                    label: "Choose warehouse (Entry)",
                    data: girisDepoList,
                    aranacakColumnlar: const [1])));
        _shared.setData("DestStockWareHouseID", girisDepo[0]);

        myDataTable cikisDepoList = await _databaseHelper.execute(
            sql: "select ID,Name from CRD_StockWareHouse");
        List cikisDepo = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AramaSayfasi(
                    label: "Choose warehouse (out)",
                    data: cikisDepoList,
                    aranacakColumnlar: const [1])));
        _shared.setData("StockWareHouseID", cikisDepo[0]);

        _shared.setData("setup", true);
        _shared.setData(
            "lastDBUpdateTime",
            DateTime.fromMillisecondsSinceEpoch(
                    DateTime.now().millisecondsSinceEpoch)
                .toString());
        Navigator.pop(context, true);
      } catch (e) {
        log("Hata verdi: ${e.toString()}");
        Navigator.pop(context);
      }
    } else {
      showMyToast(data);
    }
    // indirme bitince
  }
}
