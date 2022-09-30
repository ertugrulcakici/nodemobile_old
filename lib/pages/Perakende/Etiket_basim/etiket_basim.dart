// ignore_for_file: non_constant_identifier_names, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:nodemobile/pages/Perakende/Etiket_basim/etiket_basim_form.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/baglanti_control.dart';
import 'package:nodemobile/widgets/sayfaya_git.dart';

class EtiketBasim extends StatefulWidget {
  const EtiketBasim({Key? key}) : super(key: key);

  @override
  _EtiketBasimState createState() => _EtiketBasimState();
}

class _EtiketBasimState extends State<EtiketBasim> {
  final List<Etiket> _etiketler = [];

  late myDataTable CRD_Items;
  late myDataTable TRN_EtiketBasim;
  late myDataTable TRN_EtiketBasimEmirleri;
  late myDataTable X_Branchs;

  late DatabaseHelper _databaseHelper;
  // late Shared _shared;

  bool _initedData = false;

  @override
  void initState() {
    _databaseHelper = DatabaseHelper();
    // _shared = Shared();
    _initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaglantiControl(
      child: SayfayaGit(
        route: "/",
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Label operations"),
            actions: [
              IconButton(
                  tooltip: "Refresh",
                  onPressed: _yenile,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  )),
              IconButton(
                  tooltip: "Refresh all",
                  onPressed: _syncAll,
                  icon: const Icon(Icons.cloud_upload, color: Colors.white)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
              label: const Text("Add"),
              icon: const Icon(Icons.add),
              onPressed: () async {
                bool? _fiyatDegisiklik = await showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        child: Container(
                          color: Colors.black.withOpacity(0.0),
                          height: boyutY(context, 100),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text("Chose type",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline3!
                                        .copyWith(color: Colors.white),
                                    textAlign: TextAlign.center),
                                InkWell(
                                    onTap: () => Navigator.pop(context, false),
                                    child: Container(
                                        margin: EdgeInsets.symmetric(
                                            vertical: boyutY(context, 2)),
                                        decoration: const BoxDecoration(
                                            color: myThemeData.acikGolden,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        height: boyutY(context, 10),
                                        width: boyutX(context, 90),
                                        child: Center(
                                            child: Text(
                                                "Label Printing Receipt",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline5!
                                                    .copyWith(
                                                        color:
                                                            Colors.white))))),
                                InkWell(
                                    onTap: () => Navigator.pop(context, true),
                                    child: Container(
                                        margin: EdgeInsets.symmetric(
                                            vertical: boyutY(context, 2)),
                                        decoration: const BoxDecoration(
                                            color: myThemeData.acikGolden,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        height: boyutY(context, 10),
                                        width: boyutX(context, 90),
                                        child: Center(
                                            child: Text("Price Change Receipt",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline5!
                                                    .copyWith(
                                                        color:
                                                            Colors.white))))),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                if (_fiyatDegisiklik is bool) {
                  if (await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EtiketBasimForm(
                                  fiyatDegisiklik: _fiyatDegisiklik))) ==
                      true) {
                    await _syncAll();
                  } else {
                    _yenile();
                  }
                }
              }),
          body: Stack(
            children: [
              Positioned.fill(
                  child: Container(
                      color: Colors.transparent,
                      height: boyutY(context, 100),
                      width: boyutX(context, 100),
                      child: Center(
                          child: _initedData == false
                              ? const CircularProgressIndicator()
                              : _etiketler.isEmpty
                                  ? const Text("It's still empty")
                                  : null))),
              ListView.builder(
                  itemBuilder: (context, index) {
                    Etiket _etiket = _etiketler.reversed.toList()[index];
                    return Hero(
                      tag: _etiket.fisNo,
                      child: Card(
                          elevation: 0,
                          color: index % 2 == 0
                              ? Colors.grey.shade50
                              : Colors.white,
                          child: ListTile(
                            onTap: () async {
                              myDataTable _satirlar = await _databaseHelper.execute(
                                  sql:
                                      "select * from TRN_EtiketBasimEmirleri where FisNo='${_etiket.fisNo}'");
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Scaffold(
                                    body: Hero(
                                        tag: _etiket.fisNo,
                                        child: ListView.builder(
                                          itemBuilder: (context, index) {
                                            // int _urunID = _satirlar.data[index]["ProductID"];
                                            Map _item = CRD_Items.rowsBy({
                                              "ID": _satirlar.data[index]
                                                  ["ProductID"]
                                            })[0];
                                            // myDataTable _itemData = _databaseHelper.execute(sql: "select * from CRD_Items where ID=$_urunID");
                                            String _subString = "";
                                            _subString +=
                                                "Barcode: ${_item["Barcode"]}\n";
                                            _subString +=
                                                "Price: ${_satirlar.data[index]["Fiyat"]}\n";
                                            _subString +=
                                                "Count: ${_satirlar.data[index]["EtiketSayisi"]}";
                                            return Card(
                                              child: ListTile(
                                                title: Text(_item["Name"]),
                                                subtitle: Text(_subString),
                                              ),
                                            );
                                          },
                                          itemCount: _satirlar.data.length,
                                        )));
                              }));
                            },
                            onLongPress: () async {
                              if (_etiket.GoldenSync) {
                                showMyToast(
                                    "This voucher has been transferred to the server",
                                    error: true);
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text(
                                            "Are you sure you want to delete ?"),
                                        actions: [
                                          TextButton.icon(
                                              onPressed: () async {
                                                if (await _sil(_etiket.fisNo)) {
                                                  showMyStack(
                                                      context: context,
                                                      message:
                                                          "Receipt deleted successfully");
                                                  await _yenile();
                                                } else {
                                                  showMyToast(
                                                      "Receipt could not be deleted",
                                                      error: true);
                                                }
                                              },
                                              icon: const Icon(Icons.check,
                                                  color: Colors.green),
                                              label: const Text("Approve")),
                                          TextButton.icon(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              icon: const Icon(Icons.cancel,
                                                  color: Colors.red),
                                              label: const Text("Cancel")),
                                        ],
                                      );
                                    });
                              }
                            },
                            title: Text("Receipt no: ${_etiket.fisNo}"),
                            subtitle: Text(
                                "Branch name: ${_etiket.isyeri}\nReason for change: ${_etiket.degisiklikSebebi}"),
                            trailing: _etiket.GoldenSync
                                ? AbsorbPointer(
                                    absorbing: true,
                                    child: IconButton(
                                        icon: const Icon(Icons.check,
                                            color: myThemeData.darkBlue),
                                        onPressed: () {}))
                                : IconButton(
                                    onPressed: () async {
                                      if (await DatabaseHelper.syncOneTRNEtiket(
                                          _etiket.fisNo)) {
                                        showMyToast("Transfer successful");
                                        _yenile();
                                      }
                                    },
                                    icon: const Icon(
                                        Icons.cloud_upload_outlined,
                                        color: myThemeData.darkBlue)),
                          )),
                    );
                  },
                  itemCount: _etiketler.length)
            ],
          ),
        ),
      ),
    );
  }

  Future _initData() async {
    if (!await DatabaseHelper.syncCRD()) {
      showMyToast("Could not connect to server. Continuing from old data");
    }
    CRD_Items = await _databaseHelper.execute(sql: "select * from CRD_Items");
    TRN_EtiketBasim =
        await _databaseHelper.execute(sql: "select * from TRN_EtiketBasim");
    X_Branchs = await _databaseHelper.execute(sql: "select * from X_Branchs");
    setState(() {
      _initedData = true;
      for (var element in TRN_EtiketBasim.data) {
        _etiketler.add(Etiket(
            fisNo: element["FisNo"],
            isyeri: X_Branchs.rowsBy({"BranchNo": element["Branch"]})[0]
                ["Name"],
            degisiklikSebebi: element["DegisiklikSebebi"],
            GoldenSync: element["GoldenSync"] == 1 ? true : false));
      }
    });
  }

  Future _yenile() async => await Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const EtiketBasim()));

  Future<bool> _sil(String fisNo) async {
    try {
      await _databaseHelper.execute(
          sql: "delete from TRN_EtiketBasimEmirleri where FisNo='$fisNo'");
      await _databaseHelper.execute(
          sql: "delete from TRN_EtiketBasim where FisNo='$fisNo'");
      return true;
    } catch (e) {
      return false;
    }
  }

  _syncAll() async {
    await DatabaseHelper.syncAllTRNEtiket();
    _yenile();
  }
}

class Etiket {
  String fisNo;
  String isyeri;
  String degisiklikSebebi;
  late bool fiyatDegisiklik;
  bool GoldenSync;

  Etiket(
      {required this.fisNo,
      required this.GoldenSync,
      required this.degisiklikSebebi,
      required this.isyeri}) {
    if (degisiklikSebebi == "Fiyat Değişikliği") {
      fiyatDegisiklik = true;
    } else {
      fiyatDegisiklik = false;
    }
  }
  // Etiket({required this.fisNo,required this.isyeri,required this.degisiklikSebebi, required this.GoldenSync}) {
  //   fiyatDegisiklik = this.degisiklikSebebi == "Fiyat Değişiklik" ? true : false;
  // }
}
