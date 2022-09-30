// ignore_for_file: non_constant_identifier_names, must_be_immutable, camel_case_types, library_prefixes, use_key_in_widget_constructors, no_leading_underscores_for_local_identifiers, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nodemobile/pages/Stoklar/Malzeme_fisleri/malzeme_fisi.dart';
import 'package:nodemobile/pages/Stoklar/Malzeme_fisleri/malzeme_fisleri_main.dart';
import 'package:nodemobile/utils/constants.dart' as staticData;
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/extentions.dart';
import 'package:nodemobile/utils/helpers.dart';

class MalzemeFisleriListesi extends StatefulWidget {
  Map<String, myDataTable> data;
  List fisIDleri;
  int sayfaIndexi;
  PageStorageKey? pageStorageKey;

  MalzemeFisleriListesi({
    this.pageStorageKey,
    required this.data,
    required this.fisIDleri,
    required this.sayfaIndexi,
  });

  @override
  MalzemeFisleriListesiState createState() => MalzemeFisleriListesiState();
}

class MalzemeFisleriListesiState extends State<MalzemeFisleriListesi> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Widget> cards = [];
  Widget body = const Center(child: CircularProgressIndicator());
  myDataTable? TRN_StockTrans;
  myDataTable? X_Types_TRN_StockTrans;
  myDataTable? X_Branchs;
  myDataTable? CRD_StockWareHouse;
  myDataTable? CRD_Cari;

  @override
  void initState() {
    super.initState();
    setState(() {
      verileriGetir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: widget.pageStorageKey,
        body: ListView.builder(
            itemBuilder: (context, index) {
              return cards[index];
            },
            itemCount: cards.length));
  }

  verileriGetir() {
    TRN_StockTrans = widget.data["TRN_StockTrans"];
    X_Types_TRN_StockTrans = widget.data["X_Types_TRN_StockTrans"];
    X_Branchs = widget.data["X_Branchs"];
    CRD_StockWareHouse = widget.data["CRD_StockWareHouse"];
    CRD_Cari = widget.data["CRD_Cari"];

    TRN_StockTrans!.rowsBy({"Type": widget.fisIDleri}).forEach((element) {
      int ID = element["ID"];

      int turID = element["Type"];

      List _cariBaslik = CRD_Cari!.rowsBy({"ID": element["CariID"]});
      String? cariBaslik =
          _cariBaslik.length != 1 ? null : _cariBaslik[0]["Name"];

      List _branch = X_Branchs!.rowsBy({"BranchNo": element["Branch"]});
      String? branch = _branch.length != 1 ? null : _branch[0]["Name"];

      List _tur = X_Types_TRN_StockTrans!.rowsBy({"Code": element["Type"]});
      String tur =
          _tur.length != 1 ? "Tür bilgisi bulunamadı" : _tur[0]["Name"];

      String? tarihsaat = element["TransDate"] == null
          ? null
          : (element["TransDate"] as int).toDateTimeString();

      String? girisDepo = CRD_StockWareHouse!
                  .rowsBy({"ID": element["DestStockWareHouseID"]}).length ==
              1
          ? CRD_StockWareHouse!
              .rowsBy({"ID": element["DestStockWareHouseID"]})[0]["Name"]
          : null;
      String? cikisDepo = CRD_StockWareHouse!
                  .rowsBy({"ID": element["StockWareHouseID"]}).length ==
              1
          ? CRD_StockWareHouse!.rowsBy({"ID": element["StockWareHouseID"]})[0]
              ["Name"]
          : null;
      String? aciklamalar = element["Notes"];

      int goldenSYNC = element["GoldenSync"];

      List _direction =
          X_Types_TRN_StockTrans!.rowsBy({"Code": element["Type"]});
      int? direction =
          _direction.length == 1 ? _direction[0]["Direction"] : null;
      Icon? directionIcon;
      if (direction != null) {
        switch (direction) {
          case 1:
            directionIcon = const Icon(Icons.call_made, color: Colors.blue);
            break;
          case 0:
            directionIcon = const Icon(Icons.check_box_outline_blank);
            break;
          case -1:
            directionIcon = const Icon(Icons.call_received, color: Colors.red);
            break;
          case -2:
            directionIcon = const Icon(Icons.remove, color: Colors.white);
            break;
        }
      } else {
        directionIcon = null;
      }

      cards.add(myStokTransKarti(
        databaseHelper: _databaseHelper,
        ID: ID,
        sayfaIndexi: widget.sayfaIndexi,
        cariBaslik: cariBaslik,
        branch: branch,
        tur: tur,
        turID: turID,
        tarihsaat: tarihsaat,
        girisDepo: girisDepo,
        cikisDepo: cikisDepo,
        aciklamalar: aciklamalar,
        goldenSYNC: goldenSYNC,
        directionIcon: directionIcon,
      ));
    });
  }
}

class myStokTransKarti extends StatefulWidget {
  DatabaseHelper databaseHelper;
  int ID;
  int sayfaIndexi;
  String? cariBaslik;
  String? branch;
  String? girisDepo;
  String? cikisDepo;
  String? aciklamalar;
  String? tur;
  int turID;
  String? tarihsaat;
  Icon? directionIcon;
  int goldenSYNC;
  String info = "";

  myStokTransKarti({
    required this.databaseHelper,
    required this.ID,
    required this.sayfaIndexi,
    this.cariBaslik,
    this.branch,
    this.girisDepo,
    this.cikisDepo,
    this.aciklamalar,
    this.tur,
    required this.turID,
    this.tarihsaat,
    this.directionIcon,
    required this.goldenSYNC,
  }) {
    Map _ = {
      "Type: ": tur,
      "\nBranch: ": branch,
      "\nWarehouse (Entry): ": girisDepo,
      "\nWarehouse (Exit): ": cikisDepo,
      "\nDescriptions: ": aciklamalar,
      "\nDate: ": tarihsaat
    };
    _.forEach((key, value) {
      if (value != null && value.toString().replaceAll(" ", "").isNotEmpty) {
        info += key;
        info += value;
      }
    });
  }

  @override
  _myStokTransKartiState createState() => _myStokTransKartiState();
}

class _myStokTransKartiState extends State<myStokTransKarti> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: widget.cariBaslik != null ? Text(widget.cariBaslik!) : null,
        leading: widget.directionIcon!,
        onLongPress: () async {
          if (widget.goldenSYNC == 1) {
            showMyToast(
                "This voucher cannot be deleted because it is transferred to the remote server",
                error: true);
          } else {
            bool _confirm = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Are you sure you want to delete ?"),
                    actions: [
                      TextButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.check, color: Colors.green),
                          label: const Text("Yes")),
                      TextButton.icon(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text("No"))
                    ],
                  );
                });
            if (_confirm) {
              log("Silme yeri");
              await widget.databaseHelper.executeCommit(
                  sql: "delete from TRN_StockTrans where ID=${widget.ID}");
              await widget.databaseHelper.executeCommit(
                  sql:
                      "delete from TRN_StockTransLines where StockTransID=${widget.ID}");
              showMyToast("Deleted successfully");
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) {
                return MalzemeFisleriMain(widget.sayfaIndexi);
              }));
            }
          }
        },
        trailing: widget.goldenSYNC == 0
            ? IconButton(
                onPressed: () async {
                  var _result =
                      await DatabaseHelper.syncOneTRNMalzeme(widget.ID);
                  if (_result is bool && _result == true) {
                    showMyToast(
                        "Successfully transferred to the remote server");
                    setState(() {
                      widget.goldenSYNC = 1;
                    });
                  } else if (_result is String && _result.contains("failed")) {
                    showMyToast(_result, error: true);
                  } else if (_result is String) {
                    showMyToast(_result);
                  } else {
                    showMyToast("Transfer failed: $_result", error: true);
                  }
                },
                icon: const Icon(Icons.cloud_upload_outlined,
                    color: staticData.myThemeData.darkBlue))
            : const Icon(Icons.check, color: staticData.myThemeData.darkBlue),
        // tileColor: goldenSYNC == 1 ? Colors.green : Colors.teal.shade500,
        subtitle: Text(widget.info),
        onTap: () async {
          if (widget.goldenSYNC == 1) {
            showMyToast("This voucher has already transferred to the server",
                error: true);
          } else {
            int? id = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MalzemeFisi(
                        duzenleme: true, tur: widget.turID, ID: widget.ID)));
            if (id is int) {
              // fişi düzenleyip geri dönünce
              var _result = await DatabaseHelper.syncOneTRNMalzeme(id);
              if (_result is String) {
                showMyToast(_result);
              } else if (_result == true) {
                showMyToast("Transfer ok");
                setState(() {
                  widget.goldenSYNC = 1;
                });
              } else {
                showMyToast("Transfer failed", error: true);
              }
            }
          }
        },
      ),
    );
  }
}
