// ignore_for_file: non_constant_identifier_names, must_be_immutable, import_of_legacy_library_into_null_safe, use_key_in_widget_constructors, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, prefer_interpolation_to_compose_strings, use_build_context_synchronously

import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/arama_sayfasi.dart';
import 'package:nodemobile/widgets/my_divider.dart';
import 'package:vibration/vibration.dart';

//baslik
// branch date değişiklik sebebi fis no

//satir
// barkod crd listesinden seçilicek
// seçilen crd nin id si satirin product id sine eklenecek -> emirler tablosuna yani
// fiyatı değişiklikse textboxa otomatik alsın değilse boş getirsin
// emirlerde branch varsa ekle
// emirlerde barcode kısmına itemin barkodunu ekle
class EtiketBasimForm extends StatefulWidget {
  // etiket basim -- fiyat değişiklik

  bool fiyatDegisiklik;

  EtiketBasimForm({required this.fiyatDegisiklik});

  @override
  _EtiketBasimFormState createState() => _EtiketBasimFormState();
}

class _EtiketBasimFormState extends State<EtiketBasimForm> {
  bool autoScan = false;
  bool autoMiktar = true;

  final _player = AudioPlayer();

  Urun? urun;
  List<Urun> urunler = [];

  late myDataTable X_Branchs;
  late myDataTable TRN_EtiketBasim;
  late myDataTable TRN_EtiketBasimEmirleri;
  late myDataTable CRD_Items;

  final GlobalKey<FormFieldState> _formKey = GlobalKey<FormFieldState>();

  final TextEditingController _fisNoController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController();

  late DatabaseHelper _databaseHelper;
  late Shared _shared;

  final FocusNode _barcodeFocus = FocusNode();
  final FocusNode _fiyatFocus = FocusNode();
  final FocusNode _miktarFocus = FocusNode();

  Map baslikData = {
    "Branch": {"ID": 0, "Name": ""}
  };

  @override
  void initState() {
    _player.setAsset("assets/audio/urun_bulunamadi.mp3");
    _player.load();
    _databaseHelper = DatabaseHelper();
    _shared = Shared();
    _initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (urunler.isEmpty) return Future.value(true);
        bool _confirm = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                actions: [
                  TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      label: const Text("Approve"),
                      icon: const Icon(Icons.check, color: Colors.green)),
                  TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      label: const Text("Cancel"),
                      icon: const Icon(Icons.cancel, color: Colors.red)),
                ],
                title: const Text(
                    "Save this voucher and transfer it to the remote server?"),
                content: const Text("This data cannot be edited later!"),
              );
            });
        if (_confirm) {
          await _kaydet();
          Navigator.pop(context, true);
        }
        return Future.value(_confirm);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.save, size: 32),
              onPressed: () async {
                bool? _confirm = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Are you sure you want to save?"),
                        content:
                            const Text("This data cannot be edited later!"),
                        actions: [
                          TextButton.icon(
                              onPressed: () => Navigator.pop(context, true),
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              label: const Text("Yes")),
                          TextButton.icon(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text("No")),
                        ],
                      );
                    });
                if (_confirm == true) {
                  await _kaydet();
                }
              }),
          actions: [
            Transform.rotate(
              angle: 45 * 3.14 / 180,
              child: IconButton(
                  onPressed: () async {
                    bool _confirm = await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              title: const Text(
                                  "Are you sure you want to exit? ? "),
                              content: const Text(
                                  "Data in this form will not be recorded ! "),
                              actions: [
                                TextButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    label: const Text("Approve")),
                                TextButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    label: const Text("Cancel")),
                              ]);
                        });
                    if (_confirm) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.add, size: 32)),
            )
          ],
        ),
        body: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextField(
                    enabled: false,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "Fiş No"),
                    controller: _fisNoController),
                TextButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: _branchSecici,
                    label: Text("Branch: ${baslikData["Branch"]["Name"]}")),
                myDivider(axis: Axis.horizontal, gradient: true),
                Form(
                    key: _formKey,
                    child: Column(children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 80,
                            child: TextFormField(
                              onFieldSubmitted: _urunBilgisiniGetir,
                              focusNode: _barcodeFocus,
                              controller: _barcodeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: "Barcode",
                                  prefixIcon: IconButton(
                                      icon: const Icon(Icons.camera_alt),
                                      onPressed: _tara),
                                  suffixIcon: IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: _urunSecici)),
                            ),
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
                            child: TextFormField(
                              onFieldSubmitted: (value) async {
                                urun!.miktar =
                                    double.parse(value.replaceAll(",", "."));
                                if (widget.fiyatDegisiklik) {
                                  Future.delayed(
                                      const Duration(milliseconds: 300), () {
                                    _fiyatFocus.requestFocus();
                                  });
                                } else {
                                  await _satirEkle();
                                }
                              },
                              focusNode: _miktarFocus,
                              keyboardType: cupertino.TextInputType.number,
                              controller: _miktarController,
                              textInputAction: widget.fiyatDegisiklik
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Count"),
                            ),
                          ),
                          Expanded(
                              flex: 20,
                              child: cupertino.CupertinoSwitch(
                                  value: autoMiktar,
                                  onChanged: (value) {
                                    setState(() {
                                      autoMiktar = value;
                                    });
                                  }))
                        ],
                      ),
                      TextFormField(
                        keyboardType: cupertino.TextInputType.number,
                        readOnly: !widget.fiyatDegisiklik,
                        focusNode: _fiyatFocus,
                        decoration: InputDecoration(
                            hintText: widget.fiyatDegisiklik
                                ? ""
                                : "This place cannot be edited in the label printing slip",
                            border: const OutlineInputBorder(),
                            labelText: "Price "),
                        controller: _fiyatController,
                        onFieldSubmitted: (value) => _satirEkle(),
                      ),
                    ])),
                Expanded(
                  child: ListView.builder(
                      itemBuilder: (context, index) {
                        Urun _urun = urunler.reversed.toList()[index];
                        return Dismissible(
                          key: UniqueKey(),
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
                          confirmDismiss: (direction) async {
                            bool _confirm = await _urunSil(_urun.ID);
                            if (_confirm) {
                              setState(() {
                                urunler.remove(_urun);
                              });
                            }
                            return _confirm;
                          },
                          child: ListTile(
                            title: Text(_urun.name),
                            subtitle: Text(
                                "Barcode: ${_urun.barkod}\nCount: ${_urun.miktar}\nPrice: ${_urun.fiyat}"),
                            onTap: () async {
                              bool? _confirm = await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(_urun.name),
                                      content: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("Old count: ${_urun.miktar}"),
                                            Text(
                                                "Will be added: ${_miktarController.text}"),
                                            Text(
                                                "New count: ${_urun.miktar!.toDouble() + double.parse(_miktarController.text.replaceAll(",", "."))}",
                                                style: myThemeData.boldBlack18)
                                          ]),
                                      actions: [
                                        TextButton.icon(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            icon: const Icon(Icons.check,
                                                color: Colors.green),
                                            label: const Text("Approve")),
                                        TextButton.icon(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            icon: const Icon(Icons.cancel,
                                                color: Colors.red),
                                            label: const Text("Cancel"))
                                      ],
                                    );
                                  });
                              if (_confirm == true) {
                                setState(() {
                                  urunler.remove(_urun);
                                  _urun.miktar = _urun.miktar! +
                                      double.parse(_miktarController.text
                                          .replaceAll(",", "."));
                                  urunler.add(_urun);
                                });
                              }
                            },
                            onLongPress: () async {
                              bool _confirm = await _urunSil(_urun.ID);
                              if (_confirm) {
                                setState(() {
                                  urunler.remove(_urun);
                                });
                              }
                            },
                          ),
                        );
                      },
                      itemCount: urunler.length,
                      shrinkWrap: true),
                ),
              ],
            )),
      ),
    );
  }

  Future _initData() async {
    CRD_Items = await _databaseHelper.execute(
        sql: "select ID,Name,Barcode,UnitPrice from CRD_Items");
    X_Branchs = await _databaseHelper.execute(sql: "select * from X_Branchs");
    TRN_EtiketBasimEmirleri = await _databaseHelper.execute(
        sql: "select * from TRN_EtiketBasimEmirleri");
    TRN_EtiketBasim = await _databaseHelper.execute(
        sql: "select * from TRN_EtiketBasim ORDER BY ID DESC");

    Map _branch =
        X_Branchs.rowsBy({"BranchNo": _shared.getData("BranchNo")})[0];
    myDataTable _idTable = await _databaseHelper.execute(
        sql: "select IFNULL(MAX(ID),0) ID from TRN_EtiketBasim");

    setState(() {
      baslikData["Branch"] = {
        "ID": _branch["BranchNo"],
        "Name": _branch["Name"],
      };
      baslikData["ID"] = _idTable.data.first["ID"];

      _fisNoController.text = DateTime.now().millisecondsSinceEpoch.toString() +
          "-" +
          baslikData["ID"].toString();
      _miktarController.text = "1";
      Future.delayed(const Duration(milliseconds: 300), () {
        _barcodeFocus.requestFocus();
      });
    });
  }

  Future _urunSecici() async {
    List _data =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return AramaSayfasi(
          data: CRD_Items,
          aranacakColumnlar: const [1, 2],
          label: "Chose product",
          altsatirlar: const {
            2: "Barcode",
          });
    }));
    _urunBilgisiniGetir(_data[2]);
  }

  Future _branchSecici() async {
    List _data =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return AramaSayfasi(
          label: "Branch", data: X_Branchs, aranacakColumnlar: const [1]);
    }));
    setState(() {
      baslikData["Branch"] = {
        "ID": _data[0],
        "Name": _data[1],
      };
    });
  }

  Future _tara() async {
    String _scanResult = await FlutterBarcodeScanner.scanBarcode(
        "#ff00ff", "Cancel", false, ScanMode.DEFAULT);
    if (_scanResult != "-1") {
      _urunBilgisiniGetir(_scanResult);
      Future.delayed(const Duration(milliseconds: 300), () {
        _miktarFocus.requestFocus();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        _barcodeFocus.requestFocus();
      });
    }
  }

  Future _urunBilgisiniGetir(String barcode) async {
    try {
      setState(() {
        Map _data = CRD_Items.rowsBy({"Barcode": barcode})[0];
        urun = Urun(
            ID: _data["ID"],
            name: _data["Name"],
            barkod: _data["Barcode"],
            fiyat: _data["UnitPrice"]);
        _barcodeController.text = urun!.barkod;
        _fiyatController.text = urun!.fiyat.toString();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (autoMiktar) {
            urun!.miktar =
                double.parse(_miktarController.text.replaceAll(",", "."));
            if (widget.fiyatDegisiklik) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _fiyatFocus.requestFocus();
              });
            } else {
              _satirEkle();
            }
          } else {
            Future.delayed(const Duration(milliseconds: 300), () {
              _miktarFocus.requestFocus();
            });
          }
        });
      });
    } catch (e) {
      _player.play();
      _player.load();
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate();
        showMyToast("No product information found");
      } else {
        showMyToast("No product information found");
      }
      _barcodeController.text = "";
      _fiyatController.text = "";
      Future.delayed(const Duration(milliseconds: 300),
          () => _barcodeFocus.requestFocus());
    }
  }

  Future _kaydet() async {
    if (urunler.isEmpty) {
      showMyToast("Unable to insert voucher because no rows were found",
          error: true);
      return false;
    }

    int _date = DateTime.now().millisecondsSinceEpoch;
    await _databaseHelper.executeCommit(sql: """
      insert into TRN_EtiketBasim (FisNo,Tarih,DegisiklikSebebi,CreatedDate,Uygulandi,Branch,GoldenSync,CreatedBy) VALUES (
      '${_fisNoController.text}',
      $_date,
      '${widget.fiyatDegisiklik ? "Fiyat Değişikliği" : "Etiket basım emri"}',
      $_date,
      0,
      ${baslikData["Branch"]["ID"]},
      0,
      $USERID
      )
    """);

    for (Urun element in urunler) {
      await _databaseHelper.execute(sql: """
              insert into TRN_EtiketBasimEmirleri (ProductID,Tarih,Fiyat,EskiFiyat,EtiketBasildi,FisNo,Barkod,EtiketSayisi,GoldenSync,CreatedBy) VALUES (
              ${element.ID},
              '${DateTime.now().millisecondsSinceEpoch}',
              ${element.fiyat},
              ${CRD_Items.rowsBy({"ID": element.ID})[0]["UnitPrice"]},
              0,
              '${_fisNoController.text}',
              '${element.barkod}',
              ${element.miktar},
              0,
              $USERID
              )
            """);
    }
    showMyToast("Voucher successfully added");
    Navigator.pop(context, true);
  }

  _satirEkle() async {
    try {
      urun!.fiyat = double.parse(_fiyatController.text.replaceAll(",", "."));
    } catch (e) {
      showMyToast("Wrong quantity format", error: true);
      return false;
    }
    bool _firstTime = true;

    for (var element in urunler) {
      if (element.barkod == urun!.barkod) {
        _firstTime = false;
      }
    }
    if (urun!.fiyat != null && urun!.miktar != null && urun != null) {
      if (_firstTime) {
        urunler.add(urun!);
      } else {
        bool _confirm = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(urun!.name),
                content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Old count: ${urun!.miktar}"),
                      Text("Will be added: ${_miktarController.text}"),
                      Text(
                          "New count: ${urun!.miktar!.toDouble() + double.parse(_miktarController.text.replaceAll(",", "."))}",
                          style: myThemeData.boldBlack18)
                    ]),
                actions: [
                  TextButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text("Approve")),
                  TextButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text("Cancel"))
                ],
              );
            });
        if (_confirm) {
          for (var element in urunler) {
            if (element.barkod == urun!.barkod) {
              double _miktar = urun!.miktar! + element.miktar!;
              element.miktar = _miktar;
            }
          }
        }
      }
      showMyStack(context: context, message: "1 row added");
      urun = null;
      _barcodeController.text = "";
      _fiyatController.text = "";
      if (autoMiktar == false) {
        _miktarController.text = "1";
      }

      if (autoScan) {
        _tara();
      } else {
        Future.delayed(const Duration(milliseconds: 300),
            () => _barcodeFocus.requestFocus());
      }
    } else {
      showMyToast("Please fill all fields", error: true);
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate();
      }
    }
    setState(() {});
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
                TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    label: const Text("Delete"),
                    icon: const Icon(Icons.delete, color: Colors.red)),
                TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    label: const Text("Cancel"),
                    icon: const Icon(Icons.cancel, color: Colors.blue)),
              ],
              content: const Text("Are you sure wanted to delete ?"));
        });

    return statement;
  }
}

class Urun {
  int ID;
  double? miktar;
  double? fiyat;
  String barkod;
  String name;

  Urun(
      {required this.ID,
      this.miktar,
      this.fiyat,
      required this.barkod,
      required this.name});

  @override
  String toString() =>
      "ID: ${ID}Count: $miktar\nPrice: $fiyat\nBarcode: $barkod\nName: $name";
}
