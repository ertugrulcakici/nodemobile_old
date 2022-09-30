// ignore_for_file: non_constant_identifier_names, camel_case_types, use_key_in_widget_constructors, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nodemobile/pages/Stoklar/Stok_listesi/stok_karti_ekle.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/arama_sayfasi.dart';
import 'package:nodemobile/widgets/baglanti_control.dart';

class FiyatGor extends StatefulWidget {
  @override
  FiyatGorState createState() => FiyatGorState();
}

class FiyatGorState extends State<FiyatGor> {
  String _lastBarcode = "";
  bool _stillSearching = true;
  String _hint = "";

  late myDataTable DATA;

  final _player = AudioPlayer();

  bool _connection = false;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final FocusNode _barcodeFocus = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();

  Urun urun = Urun();

  @override
  void initState() {
    _player.setAsset("assets/audio/urun_bulunamadi.mp3");
    _player.load();
    _initData();
    Future.delayed(
        const Duration(milliseconds: 300), () => _barcodeFocus.requestFocus());
    super.initState();
  }

  setData(bool value) {
    _connection = value;
  }

  @override
  Widget build(BuildContext context) {
    return BaglantiControl(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            if (urun.ID != null) {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          StokKartiEkle(duzenleme: true, id: urun.ID)));
              await _initData();
              setState(() {
                urun = Urun();
              });
              _urunBilgisiniGetir(_lastBarcode);
            }
          },
          label: const Text("Edit"),
          icon: const Icon(Icons.edit),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: boyutY(context, 5)),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextField(
                  onTap: () {
                    if (!_stillSearching) {
                      _barcodeController.text = "";
                      _barcodeFocus.unfocus();
                      _barcodeFocus.requestFocus();
                      _stillSearching = true;
                    }
                  },
                  onSubmitted: _urunBilgisiniGetir,
                  focusNode: _barcodeFocus,
                  controller: _barcodeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      fillColor: myThemeData.koyuGolden,
                      filled: true,
                      hintText: _hint,
                      hintStyle: const TextStyle(color: Colors.white),
                      prefixIcon: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          onPressed: _tara),
                      suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          onPressed: _aramaListesindenBul))),
              myInfoText(mesaj: "Name", data: urun.ad),
              myInfoText(mesaj: "Unit", data: urun.birim),
              myInfoText(mesaj: "KDV (Purchase)", data: urun.alisKDV),
              myInfoText(mesaj: "KDV (Sale)", data: urun.satisKDV),
              myInfoText(mesaj: "Price", data: urun.satisFiyati),
              myInfoText(mesaj: "Stock count", data: urun.stokAdeti),
              myInfoText(
                  mesaj: "Unit multiplier (Weight)", data: urun.birimCarpani),
              myInfoText(mesaj: "Special code", data: urun.ozelKod),
              myInfoText(mesaj: "Type", data: urun.tip),
            ],
          ),
        ),
      ),
    );
  }

  Future _tara() async {
    String _scanResult = await FlutterBarcodeScanner.scanBarcode(
        "#ff00ff", "Cancel", false, ScanMode.DEFAULT);
    if (_scanResult != "-1") {
      _urunBilgisiniGetir(_scanResult);
    } else {
      setState(() {
        urun = Urun();
      });
      _barcodeFocus.unfocus();
      Future.delayed(const Duration(milliseconds: 300),
          () => _barcodeFocus.requestFocus());
    }
  }

  _aramaListesindenBul() async {
    List _data = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AramaSayfasi(
                  label: "Chose product",
                  data: DATA,
                  aranacakColumnlar: const [0, 1],
                  altsatirlar: const {0: "Barcode"},
                )));
    _urunBilgisiniGetir(_data[0]);
    Future.delayed(
        const Duration(milliseconds: 300), () => _barcodeFocus.unfocus());
  }

  Future _urunBilgisiniGetir(String _barcode) async {
    if (_connection) {
      // online
      String _query = """
select 
	I.Name ad,
	L.UnitName birim,
	I.TaxRate satiskdv,
	I.TaxRateToptan aliskdv,
	I.UnitPrice fiyat,
	I.StokAdeti stokadeti,
	I.AgirlikGr birimcarpani,
	I.OzelKod ozelkod,
	X.Name type,
  I.ID Id
from ((CRD_Items I inner join L_Units L on I.UnitID = L.ID) inner join X_Types X on I.Type = X.Code And TableName='TRN_StockTransLines' And ColumnsName='ProductType') where I.Barcode='$_barcode';
    """;

      List _data = await DatabaseHelper.sendQuery(query: _query, dimension: 1);
      setState(() {
        if (_data.length > 1) {
          urun = Urun(
              ad: _string(_data[0]),
              birim: _string(_data[1]),
              satisKDV: _double(_data[2]),
              alisKDV: _double(_data[3]),
              satisFiyati: _double(_data[4]),
              stokAdeti: _double(_data[5]),
              birimCarpani: _double(_data[6]),
              ozelKod: _string(_data[7]),
              tip: _string(_data[8]),
              ID: int.parse(_data[9]));
        } else {
          _urunBilgisiBulunamadi();
        }
      });
    } else {
      // offline
      List _ = DATA.rowsBy({"Barcode": _barcode});
      if (_.isNotEmpty) {
        Map _data = _[0];
        setState(() {
          urun = Urun(
              ad: _data["ad"],
              alisKDV: _data["aliskdv"],
              satisFiyati: _data["fiyat"],
              satisKDV: _data["satiskdv"],
              ozelKod: _data["ozelkod"],
              birimCarpani: _data["birimcarpani"],
              stokAdeti: _data["stokadeti"],
              tip: _data["type"],
              birim: _data["birim"],
              ID: _data["Id"]);
        });
      } else {
        _urunBilgisiBulunamadi();
      }
    }
    _lastBarcode = _barcode;
    _hint = "Last scanned barcode: " + _lastBarcode;
    _stillSearching = false;
  }

  String? _string(String _data) {
    if (_data.isNotEmpty) {
      return _data;
    } else {
      return null;
    }
  }

  double? _double(String _data) {
    try {
      return double.parse(_data.replaceAll(",", "."));
    } catch (e) {
      return null;
    }
  }

  Future _initData() async {
    await DatabaseHelper.syncCRD();
    String _query = """
      select 
  I.Barcode Barcode,
	I.Name ad,
	L.UnitName birim,
	I.TaxRate satiskdv,
	I.TaxRateToptan aliskdv,
	I.UnitPrice fiyat,
	I.StokAdeti stokadeti,
	I.AgirlikGr birimcarpani,
	I.OzelKod ozelkod,
	X.Name type,
	I.ID Id
from ((CRD_Items I inner join L_Units L on I.UnitID = L.ID) inner join X_Types X on I.Type = X.Code And TableName='TRN_StockTransLines' And ColumnsName='ProductType')""";
    DATA = await _databaseHelper.execute(sql: _query);
  }

  _urunBilgisiBulunamadi() {
    setState(() {
      urun = Urun();
      _barcodeFocus.unfocus();
      Future.delayed(const Duration(milliseconds: 300),
          () => _barcodeFocus.requestFocus());
    });
    _player.play();
    _player.load();
  }
}

class myInfoText extends StatelessWidget {
  final String mesaj;
  final data;
  const myInfoText({required this.mesaj, this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: boyutY(context, 1)),
      decoration: const BoxDecoration(color: myThemeData.koyuGolden),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Center(
              child: Text(mesaj,
                  style: myThemeData.boldBlack18
                      .copyWith(fontSize: 22, color: Colors.white))),
          const SizedBox(height: 10),
          Text(
            data == null ? "No data found" : data.toString(),
            style: myThemeData.boldBlack16.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          )
        ]),
      ),
    );
  }
}

class Urun {
  int? ID;
  String? ad;
  String? birim;
  double? alisKDV;
  double? satisKDV;
  double? satisFiyati;
  double? stokAdeti;
  double? birimCarpani;
  String? ozelKod;
  String? tip;
  Urun(
      {this.ID,
      this.ad,
      this.birim,
      this.alisKDV,
      this.satisKDV,
      this.satisFiyati,
      this.stokAdeti,
      this.birimCarpani,
      this.ozelKod,
      this.tip});

  @override
  String toString() {
    return """
  ID: $ID,
  Name: $ad,
  Unit: $birim,
  Purchase vat: $alisKDV,
  Sales vat: $satisKDV
  Stock quantity: $stokAdeti,
  Unit multiplier: $birimCarpani
  Special code $ozelKod
  Type: $tip
  """;
  }
}
