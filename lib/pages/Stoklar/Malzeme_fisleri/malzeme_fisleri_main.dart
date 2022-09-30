// ignore_for_file: non_constant_identifier_names, must_be_immutable, use_key_in_widget_constructors, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:nodemobile/pages/Stoklar/Malzeme_fisleri/malzeme_fisi.dart';
import 'package:nodemobile/pages/Stoklar/Malzeme_fisleri/malzeme_fisleri_listesi.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/baglanti_control.dart';
import 'package:nodemobile/widgets/sayfaya_git.dart';

class MalzemeFisleriMain extends StatefulWidget {
  int? initialPage;
  MalzemeFisleriMain([this.initialPage]);
  @override
  MalzemeFisleriMainState createState() => MalzemeFisleriMainState();
}

class MalzemeFisleriMainState extends State<MalzemeFisleriMain>
    with TickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();

  late PageController _pageController;
  late TabController _tabController;

  late DatabaseHelper _databaseHelper;
  double layoutSize = 15;

  final PageStorageKey _pageStorageKeyAlis = const PageStorageKey("Alis");
  final PageStorageKey _pageStorageKeySatis = const PageStorageKey("Satis");
  final PageStorageKey _pageStorageKeyDepoTransferleri =
      const PageStorageKey("DepoTransferleri");
  final PageStorageKey _pageStorageKeySayimFisi =
      const PageStorageKey("SayimFisi");

  @override
  void initState() {
    _databaseHelper = DatabaseHelper();

    _pageController = PageController(initialPage: 0);
    _tabController = TabController(length: 4, vsync: this);

    DatabaseHelper.syncCRD().then((value) {
      if (!value) {
        showMyToast("Could not connect to server. Continuing from old data");
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SayfayaGit(
      route: "/",
      child: BaglantiControl(
        child: Scaffold(
            key: _globalKey,
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  if (_tabController.index == 0 || _tabController.index == 1) {
                    int? tur = await _showChoices(context);
                    if (tur != null) {
                      // ignore: use_build_context_synchronously
                      int? id = await Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return MalzemeFisi(duzenleme: false, tur: tur);
                        },
                      ));
                      if (id is int) {
                        var _result =
                            await DatabaseHelper.syncOneTRNMalzeme(id);
                        if (_result is String) {
                          showMyToast(_result);
                        } else if (_result == true) {
                          showMyToast("Transfer done!");
                        } else {
                          showMyToast("Transfer unsuccessfull!", error: true);
                        }
                      }
                      await _yenile();
                    }
                  }

                  // depo transveri ve sayım fişinde çalışıyor
                  else {
                    int? id = await Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return MalzemeFisi(
                          duzenleme: false,
                          tur: _tabController.index == 2 ? 2 : 14);
                    }));
                    if (id is int) {
                      await DatabaseHelper.syncOneTRNMalzeme(id);
                    }
                    await _yenile();
                  }
                },
                label: const Text("Add receipt"),
                icon: const Icon(Icons.add)),
            extendBodyBehindAppBar: false,
            // drawer: mainDrawer(),
            appBar: AppBar(
              actions: [
                IconButton(
                    tooltip: "Refresh",
                    onPressed: _yenile,
                    icon: const Icon(Icons.refresh, color: Colors.white)),
                const IconButton(
                    tooltip: "Update all",
                    onPressed: DatabaseHelper.syncAllTRNMalzeme,
                    icon: Icon(Icons.cloud_upload, color: Colors.white)),
              ],
              elevation: 0,
              primary: true,
              centerTitle: true,
              title: const Text("Material receipts"),
              bottom: TabBar(
                labelStyle:
                    myThemeData.boldBlack14.copyWith(color: Colors.white),
                labelColor: Colors.white,
                isScrollable: true,
                controller: _tabController,
                tabs: const [
                  Tab(text: "Purchasing"),
                  Tab(text: "Selling"),
                  Tab(text: "Warehouse transfers"),
                  Tab(text: "Count slips"),
                ],
                onTap: (value) {
                  _tabController.animateTo(value);
                  _pageController.animateToPage(value,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.linear);
                },
              ),
            ),
            body: FutureBuilder(
                builder: (context, snapshot) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (widget.initialPage is int) {
                      _pageController.jumpToPage(widget.initialPage!);
                    }
                    widget.initialPage = null;
                  });
                  return PageView(
                    onPageChanged: (value) {
                      setState(() {
                        _tabController.animateTo(value);
                      });
                    },
                    controller: _pageController,
                    children: snapshot.hasData
                        ? [
                            MalzemeFisleriListesi(
                                pageStorageKey: _pageStorageKeyAlis,
                                fisIDleri: const [0, 10],
                                sayfaIndexi: 0,
                                data: (snapshot.data
                                    as Map<String, myDataTable>)),
                            MalzemeFisleriListesi(
                                pageStorageKey: _pageStorageKeySatis,
                                fisIDleri: const [1, 11],
                                sayfaIndexi: 1,
                                data: (snapshot.data
                                    as Map<String, myDataTable>)),
                            MalzemeFisleriListesi(
                                pageStorageKey: _pageStorageKeyDepoTransferleri,
                                fisIDleri: const [2],
                                sayfaIndexi: 2,
                                data: (snapshot.data
                                    as Map<String, myDataTable>)),
                            MalzemeFisleriListesi(
                                pageStorageKey: _pageStorageKeySayimFisi,
                                fisIDleri: const [14],
                                sayfaIndexi: 3,
                                data:
                                    (snapshot.data as Map<String, myDataTable>))
                          ]
                        : [
                            const Center(child: CircularProgressIndicator()),
                            const Center(child: CircularProgressIndicator()),
                            const Center(child: CircularProgressIndicator()),
                            const Center(child: CircularProgressIndicator())
                          ],
                  );
                },
                future: _initData())),
      ),
    );
  }

  Future<int?> _showChoices(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            color: Colors.black.withOpacity(0.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Choose type",
                    style: Theme.of(context)
                        .textTheme
                        .headline3!
                        .copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  InkWell(
                      onTap: () {
                        Navigator.pop(
                            context, _tabController.index == 0 ? 0 : 1);
                      },
                      child: Container(
                          margin: EdgeInsets.symmetric(
                              vertical: boyutY(context, 2)),
                          decoration: const BoxDecoration(
                              color: myThemeData.acikGolden,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          height: boyutY(context, 10),
                          width: boyutX(context, 90),
                          child: Center(
                              child: Text(
                                  _tabController.index == 0
                                      ? "Alış irsaliye (Mal kabul)"
                                      : "Satış irsaliye",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5!
                                      .copyWith(color: Colors.white))))),
                  InkWell(
                      onTap: () {
                        Navigator.pop(
                            context, _tabController.index == 0 ? 10 : 11);
                      },
                      child: Container(
                          margin: EdgeInsets.symmetric(
                              vertical: boyutY(context, 2)),
                          decoration: const BoxDecoration(
                              color: myThemeData.acikGolden,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          height: boyutY(context, 10),
                          width: boyutX(context, 90),
                          child: Center(
                              child: Text(
                                  _tabController.index == 0
                                      ? "Alış iade"
                                      : "Satış iade",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5!
                                      .copyWith(color: Colors.white)))))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, myDataTable>> _initData() async {
    myDataTable TRN_StockTrans = await _databaseHelper.execute(
        sql:
            "select ID,FicheNo,CariID,Branch,Type,TransDate,Notes,StockWareHouseID,DestStockWareHouseID,Cancelled,GoldenSync from TRN_StockTrans ORDER BY ID DESC");
    myDataTable X_Types =
        await _databaseHelper.execute(sql: "select * from X_Types");
    myDataTable X_Types_TRN_StockTrans =
        myDataTable(X_Types.rowsBy({"TableName": "TRN_StockTrans"}));
    myDataTable X_Branchs = await _databaseHelper.execute(
        sql: "select BranchNo,Name from X_Branchs");
    myDataTable CRD_StockWareHouse = await _databaseHelper.execute(
        sql: "select ID,Name,DepoNo,Branch from CRD_StockWareHouse");
    myDataTable CRD_Cari =
        await _databaseHelper.execute(sql: "select ID,Name from CRD_Cari");
    return {
      "TRN_StockTrans": TRN_StockTrans,
      "X_Branchs": X_Branchs,
      "X_Types_TRN_StockTrans": X_Types_TRN_StockTrans,
      "CRD_StockWareHouse": CRD_StockWareHouse,
      "CRD_Cari": CRD_Cari
    };
  }

  _yenile() async {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) {
        return MalzemeFisleriMain(_tabController.index);
      },
    ));
  }
}
