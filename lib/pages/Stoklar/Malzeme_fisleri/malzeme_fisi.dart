// ignore_for_file: non_constant_identifier_names, must_be_immutable, camel_case_types, must_call_super, empty_catches, library_prefixes, use_key_in_widget_constructors, import_of_legacy_library_into_null_safe, use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nodemobile/pages/Stoklar/Stok_listesi/stok_karti_ekle.dart';
import 'package:nodemobile/utils/constants.dart' as staticData;
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/extentions.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/arama_sayfasi.dart';
import 'package:vibration/vibration.dart';

typedef Urun = Map<String, dynamic>;

class MalzemeFisi extends StatefulWidget {
  bool duzenleme;
  int tur;
  int? ID;

  MalzemeFisi({required this.duzenleme, this.ID, required this.tur});

  @override
  _MalzemeFisiState createState() => _MalzemeFisiState();
}

class _MalzemeFisiState extends State<MalzemeFisi> {
  //region Değişkenler

  //region CRUD işlemleri için
  late int direction;
  bool defaultDone = false;

  Urun? urun;

  List<Urun> urunler = List.empty(growable: true);

  Map<String, dynamic> urunData = {};
  Map<String, Map> data = {};

  String SpeCode = "";
  // endregion

  // region databaseler
  late myDataTable ItemData;
  late myDataTable FullItemData;
  late myDataTable X_Branchs;
  late myDataTable X_Types;
  late myDataTable CRD_StockWareHouse;
  late myDataTable CRD_Cari;
  // endregion

  // region otomatikler
  bool autoMiktar = false;
  bool autoScan = false;
  // endregion

  // region textler
  String _mesaj = "Product name will be shown here";

  String cariButonText = "Not choised yet";
  String girisDepoText = "Not choised yet";
  String cikisDepoText = "Not choised yet";
  String aciklamaText = "Not choised yet";
  String branchText = "Not choised yet";
  String turText = "Not choised yet";
  String ficheNo = "Not choised yet";
  //endregion

  // region başlık türleri
  // başlık
  List<Map> turler = [
    {"Name": "Purchase Returns", "ID": 0},
    {"Name": "Purchase Waybill", "ID": 1},
    {"Name": "Sales Returns", "ID": 2},
    {"Name": "Sales Waybill", "ID": 3},
    {"Name": "Warehouse Transfers", "ID": 4},
    {"Name": "Sales receipt", "ID": 5},
  ];

  // sayfa indexi: turlerin id si
  Map<int, List<int>> sahipOlunanTurler = {
    0: [0, 1],
    1: [2, 3],
    2: [4],
    3: [5]
  };

  // sayfa indexi: giriş deposu tür vb.
  Map<int, List<int>> sahipOlunanInputlar = {
    0: [1, 2, 3],
    1: [1, 2, 3],
    2: [2, 3],
    3: [2, 3],
  };

  List<Widget> baslikWidgetleri = [];

  // endregion

  // region controllerler
  final TextEditingController _textEditingControllerAciklama =
      TextEditingController();
  final TextEditingController _textEditingControllerFicheNo =
      TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController();
  // endregion

  // region focusnodeler
  final FocusNode _miktarFocus = FocusNode();
  final FocusNode _barcodeFocus = FocusNode();
  final FocusNode _aciklamaFocus = FocusNode();
  // endregion

  // region sabitler
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Shared _shared = Shared();
  final _player = AudioPlayer();
  // endregion
  //endregion

  @override
  void initState() {
    _player.setAsset("assets/audio/urun_bulunamadi.mp3");
    _player.load();
    _initBaslik();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingControllerAciklama.dispose();
    _textEditingControllerFicheNo.dispose();
    _barcodeController.dispose();
    _miktarController.dispose();
    _miktarFocus.dispose();
    _barcodeFocus.dispose();
    _aciklamaFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.duzenleme && urunler.isNotEmpty) {
          bool? deger = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                actions: [
                  TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      label: const Text("Transfer"),
                      icon: const Icon(Icons.check, color: Colors.green)),
                  TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      label: const Text("Continue without transfer"),
                      icon: const Icon(Icons.cancel, color: Colors.red)),
                ],
                title: const Text("Transfer this voucher to remote server ?"),
              );
            },
          );
          if (deger is bool && deger == true) {
            Navigator.pop(context, widget.ID);
          }
          if (deger is bool && deger == false) {
            Navigator.pop(context);
          }
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        // floatingActionButton: FloatingActionButton(onPressed: () async
        // {
        //   showMyToast("Ürün eklenmeye başladı");
        //   String _barcodesString = "select ID,Name,Barcode,UnitID,Aciklama,Miktar from V_AllItems limit 1000 ";
        //   myDataTable _data = await _databaseHelper.execute(sql: _barcodesString);
        //   for(int i = 0; i < 1000; i++ ){
        //     Map _urun = _data.data[i];
        //     String _query = """insert into TRN_StockTransLines (Date,Direction,Status,StockTransID,ProductID,SeriNo,Type,ProductType,Amount,UnitID,TaxRate,Branch,GoldenSync,Cancelled,StockWareHouseID,DestStockWareHouseID,FisNo,CreatedBy,CreatedDate) VALUES (
        //       1634199953805,
        //       1,
        //       1,
        //       ${widget.ID},
        //       ${_urun["ID"]},
        //       '${_urun["Barcode"]}',
        //       ${widget.tur},
        //       14,
        //       100,
        //       ${_urun["UnitID"]},
        //       ${direction == 1 ? _urun["TaxRateToptan"] : direction == -1 ? _urun["TaxRate"] : 0},
        //       ${data["Branch"]!["ID"]},
        //       0,
        //       1,
        //       ${data["CikisDepo"] != null ? data["CikisDepo"]!["ID"] : null},
        //       ${data["GirisDepo"] != null ? data["GirisDepo"]!["ID"] : null},
        //       '$SpeCode',
        //       $USERID,
        //       ${DateTime.now().millisecondsSinceEpoch}
        //       )""";
        //     await _databaseHelper.executeCommit(sql: _query);
        //     // print(_urun);
        //   }
        //   showMyToast("Ürün eklenme bitti");
        //
        // },child: Icon(Icons.add)),
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.save, size: 32),
              onPressed: () async {
                if (widget.duzenleme && urunler.isNotEmpty) {
                  bool? deger = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        actions: [
                          TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              label: const Text("Transfer"),
                              icon:
                                  const Icon(Icons.check, color: Colors.green)),
                          TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              label: const Text("Continue without transfer"),
                              icon:
                                  const Icon(Icons.cancel, color: Colors.red)),
                        ],
                        title: const Text(
                            "Transfer this voucher to remote server ?"),
                      );
                    },
                  );
                  if (deger is bool && deger == true) {
                    Navigator.pop(context, widget.ID);
                  }
                  if (deger is bool && deger == false) {
                    Navigator.pop(context);
                  }
                }
                //   return Future.value(false); // burayı bir üst satırdan getirdim (if içinden son satırdan)
                //  else {
                //   return Future.value(true);
                // }
              }),
          actions: [
            TextButton.icon(
                onPressed: () async {
                  if (widget.duzenleme != true) {
                    // fiş başlığı eklenmemişse
                    showMyToast(
                        "Inventory card cannot be added without creating a receipt header.",
                        error: true);
                    return;
                  }
                  // fiş başlığı eklenmişse
                  var data = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              StokKartiEkle(duzenleme: false)));
                  await DatabaseHelper.syncCRD();
                  if (data != null || data != false) {
                    // ürün eklenmişse
                    Map urun = (await _databaseHelper.execute(
                            sql:
                                "select ID,Name,Barcode,UnitID,Type,TaxRate,TaxRateToptan,UnitPrice,AlisFiyati,StokAdeti,Aciklama,Miktar from V_AllItems where Barcode=${data["Barcode"]}"))
                        .data[0];
                    urun = UrunOlustur(
                        ID: urun["ID"],
                        UnitID: urun["UnitID"],
                        barkod: urun["Barcode"],
                        Name: urun["Name"],
                        Miktar: urun["Miktar"],
                        Aciklama: urun["Aciklama"]);

                    _mesajiDegistir(urun["Name"]);
                    _barcodeController.text = urun["barkod"];
                    ItemData.addData({
                      "ID": urun["ID"],
                      "Name": urun["Name"],
                      "Barcode": urun["Barcode"],
                      "UnitID": urun["UnitID"],
                      "Aciklama": urun["Aciklama"],
                      "Miktar": urun["Miktar"]
                    });
                    FullItemData.addData(urun);
                    if (autoMiktar == true) {
                      if (_urununMiktariniAta(_miktarController.text)) {
                        _urunEkle();
                      }
                    } else {
                      _formIslemi(mfocus: true);
                    }
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  "Add stock card",
                  style: staticData.myThemeData.boldBlack16
                      .copyWith(color: Colors.white),
                )),
            SizedBox(width: boyutX(context, 10)),
            Transform.rotate(
              angle: 45 * 3.14 / 180,
              child: IconButton(
                  onPressed: () async {
                    bool confirm = await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Are you sure want to exit ? "),
                            content: const Text(
                                "Data in this form will not be recorded ! "),
                            actions: [
                              TextButton.icon(
                                  onPressed: () => Navigator.pop(context, true),
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  label: const Text("Approve")),
                              TextButton.icon(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  label: const Text("Cancel")),
                            ],
                          );
                        });
                    if (confirm) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.add, size: 32)),
            ),
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Column(children: [
              ExpansionTile(
                  initiallyExpanded: widget.duzenleme ? false : true,
                  maintainState: true,
                  title: const Text("Receipt header"),
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: baslikWidgetleri)
                  ]),
              AbsorbPointer(
                absorbing: !widget.duzenleme,
                child: ExpansionTile(
                  initiallyExpanded: widget.duzenleme ? true : false,
                  maintainState: true,
                  title: const Text("Add product"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_mesaj,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 20, color: Colors.red)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 80,
                          child: TextField(
                              onSubmitted: _barcodeSubmit,
                              focusNode: _barcodeFocus,
                              controller: _barcodeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  prefixIcon: IconButton(
                                      icon: const Icon(Icons.camera_alt),
                                      onPressed: _tara),
                                  suffixIcon: IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: _aramaListesindenBul))),
                        ),
                        Expanded(
                            flex: 20,
                            child: cupertino.CupertinoSwitch(
                                value: autoScan,
                                onChanged: (value) {
                                  setState(() {
                                    autoScan = value;
                                  });
                                }))
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            flex: 80,
                            child: TextField(
                                controller: _miktarController,
                                keyboardType: TextInputType.number,
                                focusNode: _miktarFocus,
                                decoration:
                                    const InputDecoration(labelText: "Count"),
                                onSubmitted: _miktarSubmit)),
                        Expanded(
                          flex: 20,
                          child: cupertino.CupertinoSwitch(
                              value: autoMiktar,
                              onChanged: (value) {
                                setState(() {
                                  autoMiktar = value;
                                });
                              }),
                        )
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      height: boyutY(context, 5),
                      color: staticData.myThemeData.koyuGolden,
                      child: const Center(
                          child: Icon(Icons.format_line_spacing_sharp)),
                    ),
                    Container(
                      constraints:
                          BoxConstraints(maxHeight: boyutY(context, 80)),
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            Urun urun = urunler.reversed.toList()[index];
                            return Dismissible(
                              key: UniqueKey(),
                              confirmDismiss: (direction) async {
                                return await _urunSil(urun["ID"]);
                              },
                              background: Container(
                                color: Colors.red,
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(Icons.delete),
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                child: const Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.delete),
                                ),
                              ),
                              child: Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  tileColor: index % 2 == 0
                                      ? staticData.myThemeData.acikGolden
                                      : Colors.white,
                                  onTap: () => _urunGuncelle(urun["ID"]),
                                  onLongPress: () => _urunSil(urun["ID"]),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(urun["Name"],
                                          style: staticData
                                              .myThemeData.boldBlack18),
                                      Text("Count: ${urun["miktar"]}",
                                          style: staticData
                                              .myThemeData.boldBlack16),
                                      Text("Barcode: ${urun["barkod"]}",
                                          style: staticData
                                              .myThemeData.boldBlack16),
                                      Text(
                                          "PM: ${urun["Miktar"].toString().replaceAll("null", "-")}",
                                          style: staticData
                                              .myThemeData.boldBlack16),
                                      Text(
                                          "Description: ${urun["Aciklama"].toString().replaceAll("null", "-")}",
                                          style: staticData
                                              .myThemeData.boldBlack16),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          itemCount: urunler.length),
                    )
                  ],
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }

  // region Başlık fonksiyonları
  void _initBaslik() async {
    if (defaultDone == false) {
      await _initDefaults();

      defaultDone = true;
    }

    baslikWidgetleri.clear();

    TextField aciklamaTextInput = TextField(
      focusNode: _aciklamaFocus,
      onSubmitted: (value) {
        _onayla();
      },
      controller: _textEditingControllerAciklama,
      decoration: const InputDecoration(
          border: OutlineInputBorder(), labelText: "Description"),
    );

    TextField ficheNoTextInput = TextField(
      textInputAction: TextInputAction.next,
      controller: _textEditingControllerFicheNo,
      decoration: const InputDecoration(
          border: OutlineInputBorder(), labelText: "Receipt number"),
    );

    TextButton cariSecici = TextButton.icon(
        icon: const Icon(Icons.edit),
        onPressed: _cariSecici,
        label: Text("Current: $cariButonText"));

    TextButton girisDepoSecici = TextButton.icon(
        icon: const Icon(Icons.edit),
        onPressed: _girisDepoSecici,
        label: Text("Entrance warehouse: $girisDepoText"));

    TextButton cikisDepoSecici = TextButton.icon(
        icon: const Icon(Icons.edit),
        onPressed: _cikisDepoSecici,
        label: Text("Exit warehouse: $cikisDepoText"));

    TextButton branchSecici = TextButton.icon(
        icon: const Icon(Icons.edit),
        onPressed: _branchSecici,
        label: Text("Branch: $branchText"));

    Text turSecici = Text("Type: $turText",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.blue));

    TextButton onaylaButton = TextButton.icon(
        icon: const Icon(Icons.check),
        onPressed: _onayla,
        label: const Text("Approve"));

    baslikWidgetleri.add(turSecici);
    baslikWidgetleri.add(branchSecici);

    switch (widget.tur) {
      case 0:
        {
          baslikWidgetleri.add(cariSecici);
          baslikWidgetleri.add(girisDepoSecici);
        }
        break;
      case 1:
        {
          baslikWidgetleri.add(cariSecici);
          baslikWidgetleri.add(cikisDepoSecici);
        }
        break;
      case 2:
        {
          baslikWidgetleri.add(girisDepoSecici);
          baslikWidgetleri.add(cikisDepoSecici);
        }
        break;
      case 10:
        {
          baslikWidgetleri.add(cariSecici);
          baslikWidgetleri.add(cikisDepoSecici);
        }
        break;
      case 11:
        {
          baslikWidgetleri.add(cariSecici);
          baslikWidgetleri.add(girisDepoSecici);
        }
        break;
      case 14:
        {
          baslikWidgetleri.add(girisDepoSecici);
        }
        break;
    }

    baslikWidgetleri.add(ficheNoTextInput);
    baslikWidgetleri.add(aciklamaTextInput);
    baslikWidgetleri.add(onaylaButton);
  }

  _cariSecici() async {
    myDataTable cariler =
        await _databaseHelper.execute(sql: "select ID,Name from CRD_Cari");
    List cari = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AramaSayfasi(
                label: "Choose current",
                aranacakColumnlar: const [1],
                data: cariler)));
    data["Cari"] = {"ID": cari[0], "Name": cari[1]};

    setState(() {
      cariButonText = cari[1];
      _initBaslik();
    });
  }

  _branchSecici() async {
    myDataTable branchler = await _databaseHelper.execute(
        sql: "select BranchNo,Name from X_Branchs");
    List branch = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AramaSayfasi(
                label: "Choose branch",
                aranacakColumnlar: const [1],
                data: branchler)));

    data["Branch"] = {
      "ID": branch[0],
      "Name": branch[1],
    };

    setState(() {
      branchText = branch[1];
      _initBaslik();
    });
  }

  _cikisDepoSecici() async {
    myDataTable cikisDepolar = await _databaseHelper.execute(
        sql: "select ID,Name from CRD_StockWareHouse");
    List cikisDepo = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AramaSayfasi(
                label: "Choose exit warehouse",
                aranacakColumnlar: const [1],
                data: cikisDepolar)));

    data["CikisDepo"] = {"ID": cikisDepo[0], "Name": cikisDepo[1]};

    setState(() {
      cikisDepoText = cikisDepo[1];
      _initBaslik();
    });
  }

  _girisDepoSecici() async {
    myDataTable girisDepolar = await _databaseHelper.execute(
        sql: "select ID,Name from CRD_StockWareHouse");
    List girisDepo = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AramaSayfasi(
                label: "Choose entrance warehouse",
                aranacakColumnlar: const [1],
                data: girisDepolar)));
    data["GirisDepo"] = {"ID": girisDepo[0], "Name": girisDepo[1]};

    setState(() {
      girisDepoText = girisDepo[1];
      _initBaslik();
    });
  }

  _onayla() async {
    String query = "";
    // myDataTable directionTable = await _databaseHelper.execute(sql: "select Direction from X_Types where TableName = 'TRN_StockTrans' and ColumnsName = 'Type' and Code = ${widget.tur}");
    // direction = directionTable.rows[0][0];

    int? cariID;
    if (data["Cari"] != null) {
      cariID = data["Cari"]!["ID"];
    }
    int branchID = data["Branch"]!["ID"];
    if (direction == -1) {
      data["GirisDepo"]!["ID"] = 0;
    } else if (direction == 1) {
      data["CikisDepo"]!["ID"] = 0;
    }
    if (widget.duzenleme == false) {
      // yeni fiş oluşturma
      SpeCode = DateTime.now().millisecondsSinceEpoch.toString();
      query =
          """insert into TRN_StockTrans (FicheNo, CariID, Branch, Type, Status, TransDate, Notes, StockWareHouseID, DestStockWareHouseID, CreatedBy, CreatedDate, GoldenSync, Cancelled, SpeCode)
          VALUES (
          '${_textEditingControllerFicheNo.text}',
          $cariID,
          $branchID,
          ${widget.tur},
          1,
          ${DateTime.now().millisecondsSinceEpoch},
          '${_textEditingControllerAciklama.text}',
          ${data["CikisDepo"]!["ID"]},
          ${data["GirisDepo"]!["ID"]},
          $USERID,
          ${DateTime.now().millisecondsSinceEpoch},
          0,
          1,
          '$SpeCode'
          )
          """;
      if (await _databaseHelper.executeCommit(sql: query)) {
        myDataTable value = await _databaseHelper.execute(
            sql: "select max(ID) from TRN_StockTrans");
        setState(() {
          widget.ID = value.rows[0][0];
          widget.duzenleme = true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Receipt added successfully."),
            action: SnackBarAction(
              onPressed: () {},
              label: "Okey",
            ),
          ));
        });
      } else {
        showMyToast("Adding receipt failed.");
      }
    } else {
      // fişi düzenleme
      query = """update TRN_StockTrans set 
      FicheNo='${_textEditingControllerFicheNo.text}',
      CariID=$cariID,
      Branch=$branchID,
      Type=${widget.tur},
      Status=1,
      TransDate=${DateTime.now().millisecondsSinceEpoch},
      Notes='${_textEditingControllerAciklama.text}',
      StockWareHouseID=${data["CikisDepo"]!["ID"]},
      DestStockWareHouseID=${data["GirisDepo"]!["ID"]},
      ModifiedBy=$USERID,
      ModifiedDate=${DateTime.now().millisecondsSinceEpoch},
      GoldenSync=0,
      Cancelled=1 where ID=${widget.ID}
      """;
      if (await _databaseHelper.executeCommit(sql: query)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Receipt updated successfully."),
          action: SnackBarAction(
            onPressed: () {},
            label: "Okey",
          ),
        ));
      } else {
        showMyToast("Receipt update failed.");
      }
    }
    _aciklamaFocus.unfocus();
  }
  // endregion

  // region TextField fonksiyonları
  _tara() async {
    String scanResult = await FlutterBarcodeScanner.scanBarcode(
        "#ff00ff", "Cancel", false, ScanMode.DEFAULT);
    if (scanResult != "-1") {
      if (_urunBilgisiniDoldur(scanResult)) {
        _barcodeController.text = scanResult;
        if (autoMiktar == true) {
          if (_urununMiktariniAta(_miktarController.text)) {
            _urunEkle();
          }
        } else {
          _formIslemi(mfocus: true);
        }
      } else {
        _formIslemi(bfocus: false);
        _formIslemi(bfocus: true);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 300),
          () => _barcodeFocus.requestFocus());
    }
  }

  void _aramaListesindenBul() async {
    List data = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AramaSayfasi(
                  label: "Choose product",
                  data: ItemData,
                  aranacakColumnlar: const [1, 2, 4, 5],
                  altsatirlar: const {
                    2: "Barcode",
                    4: "Description",
                    5: "Count"
                  },
                )));
    urun = UrunOlustur(
        ID: data[0],
        Name: data[1],
        barkod: data[2],
        UnitID: data[3],
        Aciklama: data[4],
        Miktar: data[5]);
    _mesajiDegistir(urun!["Name"]);
    _barcodeController.text = urun!["barkod"];
    if (autoMiktar == true) {
      if (_urununMiktariniAta(_miktarController.text)) {
        _urunEkle();
      }
    } else {
      _formIslemi(mfocus: true);
    }
  }

  void _barcodeSubmit(barkod) {
    if (_urunBilgisiniDoldur(barkod)) {
      if (autoMiktar == false) {
        _formIslemi(mfocus: true);
      } else {
        if (_urununMiktariniAta(_miktarController.text)) {
          _urunEkle();
        }
      }
    }
  }

  void _miktarSubmit(value) {
    if (urun != null) {
      if (_urunBilgisiniDoldur(_barcodeController.text)) {
        if (_urununMiktariniAta(value)) {
          _urunEkle();
        } else {
          _formIslemi(mfocus: false, mClear: true);
          _formIslemi(mfocus: true);
        }
      } else {
        _mesajiDegistir("Product data not found", titresim: true, ses: true);
        _formIslemi(bClear: true, bfocus: true);
      }
    } else {
      _mesajiDegistir("Product data not found", titresim: true, ses: true);
      _formIslemi(bClear: true, bfocus: true);
    }
  }
  // endregion

  // region Data fonksiyonları
  _initDefaults() async {
    await _initDatabases();
    if (!mounted) return;
    if (widget.duzenleme == false) {
      int BranchNo = _shared.getData("BranchNo");
      int DestStockWareHouseID = _shared.getData("DestStockWareHouseID");
      int StockWareHouseID = _shared.getData("StockWareHouseID");
      myDataTable branchTable = await _databaseHelper.execute(
          sql: "select Name from X_Branchs where BranchNo = ?",
          args: [BranchNo]);
      myDataTable girisDepoTable = await _databaseHelper.execute(
          sql: "select Name from CRD_StockWareHouse where ID = ?",
          args: [DestStockWareHouseID]);
      myDataTable cikisDepoTable = await _databaseHelper.execute(
          sql: "select Name from CRD_StockWareHouse where ID = ?",
          args: [StockWareHouseID]);

      setState(() {
        turText = staticData.malzemeFisleriTypeleri[widget.tur];
        data["Tür"] = {
          "Name": staticData.malzemeFisleriTypeleri[widget.tur],
          "ID": widget.tur
        };
      });

      setState(() {
        branchText = branchTable.rows[0][0];
        girisDepoText = girisDepoTable.rows[0][0];
        cikisDepoText = cikisDepoTable.rows[0][0];

        data["Branch"] = {"ID": BranchNo, "Name": branchText};
        data["GirisDepo"] = {"ID": DestStockWareHouseID, "Name": girisDepoText};
        data["CikisDepo"] = {"ID": StockWareHouseID, "Name": cikisDepoText};
      });
    } else {
      // düzenlemeyse

      myDataTable _item = (await _databaseHelper.execute(
          sql: "select * from TRN_StockTrans where ID = ${widget.ID}"));
      Map item = _item.getData[0];
      SpeCode = item["SpeCode"];
      setState(() {
        // açıklama ve fishe no
        _textEditingControllerAciklama.text = item["Notes"];
        _textEditingControllerFicheNo.text = item["FicheNo"];

        //tür
        turText = staticData.malzemeFisleriTypeleri[widget.tur];
        data["Tür"] = {
          "Name": staticData.malzemeFisleriTypeleri[widget.tur],
          "ID": widget.tur
        };

        // branch
        branchText = X_Branchs.rowsBy({"BranchNo": item["Branch"]})[0]["Name"];
        data["Branch"] = {"ID": item["Branch"], "Name": branchText};

        // depolar
        if (direction == -1) {
          cikisDepoText =
              CRD_StockWareHouse.rowsBy({"ID": item["StockWareHouseID"]})[0]
                  ["Name"];
          data["CikisDepo"] = {
            "ID": item["StockWareHouseID"],
            "Name": cikisDepoText
          };
        } else if (direction == 1) {
          girisDepoText =
              CRD_StockWareHouse.rowsBy({"ID": item["DestStockWareHouseID"]})[0]
                  ["Name"];
          data["GirisDepo"] = {
            "ID": item["DestStockWareHouseID"],
            "Name": girisDepoText
          };
        } else {
          girisDepoText =
              CRD_StockWareHouse.rowsBy({"ID": item["DestStockWareHouseID"]})[0]
                  ["Name"];
          cikisDepoText =
              CRD_StockWareHouse.rowsBy({"ID": item["StockWareHouseID"]})[0]
                  ["Name"];
          data["GirisDepo"] = {
            "ID": item["DestStockWareHouseID"],
            "Name": girisDepoText
          };
          data["CikisDepo"] = {
            "ID": item["StockWareHouseID"],
            "Name": cikisDepoText
          };
        }

        // Cari
        if (item["CariID"] != null && item["CariID"] > 0) {
          data["Cari"] = {
            "ID": item["CariID"],
            "Name": CRD_Cari.rowsBy({"ID": item["CariID"]})[0]["Name"]
          };
          cariButonText = CRD_Cari.rowsBy({"ID": item["CariID"]})[0]["Name"];
        }
      });

      // urunleriGetir // ürünleri getirirken joinden alsıon nameyi
      String query =
          "select T.ID,T.Amount, T.SeriNo,T.UnitID,V.Aciklama, V.Miktar, V.Name from TRN_StockTransLines as T inner join V_AllItems as V ON T.SeriNo = V.Barcode where T.StockTransID=${widget.ID} ORDER BY DATE DESC";
      myDataTable _data = await _databaseHelper.execute(sql: query);
      showMyToast("Product loading...");
      for (var urun in _data.data) {
        urunler.add(UrunOlustur(
            ID: urun["ID"],
            Name: urun["Name"],
            miktar: urun["Amount"],
            UnitID: urun["UnitID"],
            barkod: urun["SeriNo"].toString(),
            Aciklama: urun["Aciklama"],
            Miktar: urun["Miktar"]));
      }
      showMyToast("Products loaded ");
      setState(() {});
    }
  }

  _initDatabases() async {
    ItemData = await _databaseHelper.execute(
        sql: "select ID,Name,Barcode,UnitID,Aciklama,Miktar from V_AllItems");
    FullItemData = await _databaseHelper.execute(
        sql:
            "select ID,Name,Barcode,UnitID,Type,TaxRate,TaxRateToptan,UnitPrice,AlisFiyati,StokAdeti,Aciklama,Miktar from V_AllItems");
    CRD_Cari =
        await _databaseHelper.execute(sql: "select ID,Name from CRD_Cari");
    CRD_StockWareHouse = await _databaseHelper.execute(
        sql: "select ID,Name from CRD_StockWareHouse");
    X_Branchs = await _databaseHelper.execute(
        sql: "select BranchNo,Name from X_Branchs");
    X_Types = await _databaseHelper.execute(sql: "select * from X_Types");

    direction = X_Types.rowsBy({"Code": widget.tur})[0]["Direction"];
  }

  Future _urunEkle() async {
    String checkOldQuery =
        "select ID,Amount from TRN_StockTransLines where StockTransID=${widget.ID} and SeriNo='${_barcodeController.text}'";
    myDataTable old = await _databaseHelper.execute(sql: checkOldQuery);
    if (old.rows.isNotEmpty) {
      // Eski bir ürün bulunduysa
      if (await _databaseHelper.executeCommit(
          sql:
              "update TRN_StockTransLines set ModifiedBy=$USERID , ModifiedDate = ${DateTime.now().millisecondsSinceEpoch} , Date = ${DateTime.now().millisecondsSinceEpoch} , Amount = ${_miktarController.text.toDouble() + old.data[0]["Amount"]} where ID=${old.data[0]["ID"]} and SeriNo='${_barcodeController.text}'")) {
        showMyStack(
            context: context,
            message: "An existing product has been updated",
            actionText: "Okey");
        late Urun element;
        for (int i = 0; i < urunler.length; i++) {
          if (urunler[i]["barkod"] == _barcodeController.text) {
            element = urunler[i];
          }
        }
        setState(() {
          urunler.remove(element);
          element["miktar"] =
              _miktarController.text.toDouble() + old.data[0]["Amount"];
          urunler.add(element);
        });
      } else {
        showMyStack(
            context: context,
            message: "An existing product has not been updated",
            error: true);
      }
    } else {
      // Hiç ürün bulunmadıysa
      Map urun = FullItemData.rowsBy({"Barcode": _barcodeController.text})[0];
      // double _miktar = _miktarController.text.toDouble(forDatabase: true);
      int now = DateTime.now().millisecondsSinceEpoch;
      String query =
          """insert into TRN_StockTransLines (Date,Direction,Status,StockTransID,ProductID,SeriNo,Type,ProductType,Amount,UnitID,TaxRate,Branch,GoldenSync,Cancelled,StockWareHouseID,DestStockWareHouseID,FisNo,CreatedBy,CreatedDate) VALUES (
        $now,
        $direction,
        1,
        ${widget.ID},
        ${urun["ID"]},
        '${_barcodeController.text}',
        ${widget.tur},
        ${urun["Type"]},
        ${urun["miktar"]},
        ${urun["UnitID"]},
        ${direction == 1 ? urun["TaxRateToptan"] : direction == -1 ? urun["TaxRate"] : 0},
        ${data["Branch"]!["ID"]},
        0,
        1,
        ${data["CikisDepo"] != null ? data["CikisDepo"]!["ID"] : 0},
        ${data["GirisDepo"] != null ? data["GirisDepo"]!["ID"] : 0},
        '$SpeCode',
        $USERID,
        ${DateTime.now().millisecondsSinceEpoch}
        )""";

      /// burada hala eklenecekler olabilir
      if ((await _databaseHelper.executeCommit(sql: query))) {
        urunler.add(UrunOlustur(
            ID: urun["ID"],
            UnitID: urun["UnitID"],
            barkod: _barcodeController.text,
            Name: urun["Name"],
            miktar: urun["miktar"],
            Miktar: urun["Miktar"],
            Aciklama: urun["Aciklama"]));
        showMyStack(
            context: context, message: "Product added", actionText: "Okey");
        // urun ekle
      }
    }
    _formIslemi(mClear: !autoMiktar, bClear: true, mesajClear: true);
    if (autoScan == true) {
      _formIslemi(bfocus: false);
      _tara();
    } else {
      _formIslemi(bfocus: true);
    }
  }

  Future<bool> _urunSil(int ID) async {
    bool statement = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Row(children: const [
              Text("Careful"),
              Text(" !!!", style: TextStyle(color: Colors.red, fontSize: 26))
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Approve")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel")),
            ],
            content: const Text("Are you sure want to delete ?"));
      },
    );
    if (statement) {
      if ((await _databaseHelper.executeCommit(
          sql: "delete from TRN_StockTransLines where ID=$ID"))) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("1 row deleted")));
        late Urun _element;
        for (var element in urunler) {
          if (element["ID"] == ID) {
            _element = element;
          }
        }
        urunler.remove(_element);
        if (mounted) {
          setState(() {});
        }
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  _urunGuncelle(int ID) async {
    late Urun urunEski;
    late Urun urunYeni;
    for (var element in urunler) {
      if (element["ID"] == ID) {
        urunEski = element;
        urunYeni = element;
      }
    }

    String? message = await showDialog(
        context: context,
        builder: (context) {
          return guncellemeDialogu(urun: urunYeni);
        });
    if (message != null) {
      // güncelleme yapıldıysa
      if ((await _databaseHelper.executeCommit(
          sql:
              "update TRN_StockTransLines set ModifiedBy=$USERID , ModifiedDate = ${DateTime.now().millisecondsSinceEpoch} , Date=${DateTime.now().millisecondsSinceEpoch} , Amount = ${urunYeni["miktar"]} where ID=$ID"))) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        setState(() {
          urunler.remove(urunEski);
          urunler.add(urunYeni);
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Update failed")));
      }
    }
  }

  bool _urununMiktariniAta(String miktar) {
    if (urun != null) {
      try {
        if (double.parse(miktar.replaceAll(",", ".")) != 0) {
          urun!["miktar"] = double.parse(miktar.replaceAll(",", "."));
          return true;
        } else {
          _mesajiDegistir("Not valid product count", titresim: true);
          _formIslemi(mfocus: false);
          _formIslemi(mClear: true, mfocus: true);
          return false;
        }
      } catch (e) {
        _mesajiDegistir("Not valid product count", titresim: true);
        _formIslemi(mfocus: false);
        _formIslemi(mClear: true, mfocus: true);
        return false;
      }
    } else {
      _mesajiDegistir("Product data not found", titresim: true, ses: true);
      _formIslemi(bClear: true, bfocus: true);
      return false;
    }
  }

  bool _urunBilgisiniDoldur(String barcode) {
    if (barcode == "") {
      _formIslemi(bfocus: true, bClear: true);
      urun = null;
      return false;
    }
    List _ = ItemData.rowsBy({"Barcode": barcode});
    if (_.isNotEmpty) {
      try {
        Map urun = _[0];
        urun = UrunOlustur(
            ID: urun["ID"],
            barkod: urun["Barcode"],
            UnitID: urun["UnitID"],
            Name: urun["Name"],
            Aciklama: urun["Aciklama"],
            Miktar: urun["Miktar"]);
        _mesajiDegistir(urun["Name"]);
        return true;
      } catch (e) {
        _mesajiDegistir("Product data not found: ${e.toString()}",
            titresim: true, ses: true);
        _formIslemi(bfocus: true, bClear: true);
        return false;
      }
    } else {
      _mesajiDegistir("Product data not found", titresim: true, ses: true);
      _formIslemi(bfocus: true, bClear: true);
      urun = null;
      return false;
    }
  }
  // endregion

  // region Form ile ilgili
  _mesajiDegistir(String mesaj, {bool? titresim, bool? ses}) async {
    setState(() {
      _mesaj = mesaj;
    });

    if (ses == true) {
      _player.play();
      _player.load();
    }

    if (titresim == true) {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate();
      }
    }
  }

  _formIslemi(
      {bool dataClear = false,
      bool mesajClear = false,
      bool bClear = false,
      bool mClear = false,
      bool bfocus = false,
      bool mfocus = false}) {
    setState(() {
      if (mesajClear) {
        _mesaj = "Product name will be here";
      }
      if (bClear) {
        _barcodeController.text = "";
      }
      if (mClear) {
        _miktarController.text = "";
      }
      if (bfocus) {
        Future.delayed(const Duration(milliseconds: 400), () {
          _barcodeFocus.requestFocus();
        });
      } else {
        _barcodeFocus.unfocus();
      }
      if (mfocus) {
        Future.delayed(const Duration(milliseconds: 400), () {
          _miktarFocus.requestFocus();
        });
      } else {
        _miktarFocus.unfocus();
      }
      if (dataClear) {
        urun = null;
      }
    });
  }
  // endregion

}

// region Models
Urun UrunOlustur(
    {required ID,
    miktar,
    required UnitID,
    required barkod,
    required Name,
    Aciklama,
    Miktar}) {
  Urun urun = {"ID": ID, "UnitID": UnitID, "barkod": barkod, "Name": Name};
  if (miktar != null) {
    urun["miktar"] = miktar;
  }
  if (Aciklama != null) {
    urun["aciklama"] = miktar;
  }
  if (Miktar != null) {
    urun["Miktar"] = Miktar;
  } // varyant miktarı
  return urun;
}

class guncellemeDialogu extends StatefulWidget {
  Urun urun;
  guncellemeDialogu({required this.urun});

  @override
  _guncellemeDialoguState createState() => _guncellemeDialoguState();
}

class _guncellemeDialoguState extends State<guncellemeDialogu> {
  final FocusNode _guncellemeFocus = FocusNode();
  final TextEditingController _guncellemeController = TextEditingController();
  double yeniSayi = 0.0;

  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 400), () {
      _guncellemeFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        height: boyutY(context, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(widget.urun["Name"], textAlign: TextAlign.center),
            Text(
                "Count: ${widget.urun["miktar"]} + $yeniSayi = ${(widget.urun["miktar"]! + yeniSayi).toStringAsFixed(2)}"),
            TextField(
                onChanged: (value) {
                  setState(() {
                    try {
                      setState(() {
                        yeniSayi = double.parse(value.replaceAll(",", "."));
                      });
                    } catch (e) {}
                  });
                },
                keyboardType: TextInputType.number,
                focusNode: _guncellemeFocus,
                controller: _guncellemeController,
                decoration: const InputDecoration(labelText: "Miktar")),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                OutlinedButton(
                    onPressed: () async {
                      widget.urun["miktar"] =
                          _guncellemeController.text.toDouble();
                      Navigator.pop(context,
                          "Update successful. New value: ${widget.urun["miktar"]}");
                    },
                    child: const Text("Make new quantity")),
                OutlinedButton(
                    onPressed: () async {
                      // hata  var diye kapadığım yer
                      double eski = widget.urun["miktar"]!;
                      widget.urun["miktar"] = widget.urun["miktar"]! +
                          _guncellemeController.text.toDouble();
                      Navigator.pop(context,
                          "Update was successfull. New value: ${widget.urun["miktar"]!} ($eski + ${widget.urun["miktar"]! - eski})");
                    },
                    child: const Text("Add to exists one")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
 // endregion