// ignore_for_file: file_names, library_prefixes, library_private_types_in_public_api, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import "package:nodemobile/utils/constants.dart" as staticData;
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:nodemobile/widgets/arama_sayfasi.dart';
import 'package:nodemobile/widgets/my_divider.dart';

class Ayarlar extends StatefulWidget {
  const Ayarlar({Key? key}) : super(key: key);

  @override
  _AyarlarState createState() => _AyarlarState();
}

class _AyarlarState extends State<Ayarlar> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final List<Widget> _formWidgets = [];
  late Shared _shared;

  String _branchName = "";
  String _girisDepoName = "";
  String _cikisDepoName = "";

  @override
  void initState() {
    _shared = Shared();
    _formWidgets.addAll(_connectionWidgets());
    _initDefaults();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_key.currentState!.validate()) {
                _key.currentState!.save();
                Navigator.pop(context);
                showMyToast("Settings saved");
              }
            },
            label: const Text("Save")),
        body: Padding(
          padding: EdgeInsets.all(boyutY(context, 2)),
          child: Form(
            key: _key,
            child: ListView(children: [
              Column(children: _formWidgets),
              OutlinedButton(
                  onPressed: () async {
                    myDataTable branchList = await _databaseHelper.execute(
                        sql: "select BranchNo,Name from X_Branchs");
                    // ignore: use_build_context_synchronously
                    List branch = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AramaSayfasi(
                                  label: "Choose Branch",
                                  data: branchList,
                                  aranacakColumnlar: const [1],
                                )));
                    _shared.setData("BranchNo", branch[0]);
                    await _initDefaults();
                  },
                  child: Text("Branch: " + _branchName)),
              OutlinedButton(
                  onPressed: () async {
                    myDataTable girisDepoList = await _databaseHelper.execute(
                        sql: "select ID,Name from CRD_StockWareHouse");
                    // ignore: use_build_context_synchronously
                    List girisDepo = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AramaSayfasi(
                                label: "Choose Warehouse (Entry)",
                                data: girisDepoList,
                                aranacakColumnlar: const [1])));
                    _shared.setData("DestStockWareHouseID", girisDepo[0]);
                    await _initDefaults();
                  },
                  child: Text("Warehouse (Entry) : " + _girisDepoName)),
              OutlinedButton(
                  onPressed: () async {
                    myDataTable cikisDepoList = await _databaseHelper.execute(
                        sql: "select ID,Name from CRD_StockWareHouse");
                    // ignore: use_build_context_synchronously
                    List cikisDepo = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AramaSayfasi(
                                label: "Choose Warehouse (Exit)",
                                data: cikisDepoList,
                                aranacakColumnlar: const [1])));
                    _shared.setData("StockWareHouseID", cikisDepo[0]);
                    await _initDefaults();
                  },
                  child: Text("Warehouse (Exit): " + _cikisDepoName)),
              myDivider(axis: Axis.horizontal),

              // veri tabanını aktar ve güncelle
              TextButton.icon(
                  onPressed: () async {
                    showMyToast("Database update has started !");
                    staticData.cekilecekTablolar.forEach((key, value) async {
                      await _databaseHelper.createTable(context, key, false);
                    });
                    await DatabaseHelper.syncCRD();
                    await DatabaseHelper.syncAllTRNMalzeme();
                    await DatabaseHelper.syncAllTRNEtiket();
                    showMyToast("Database update finished");
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text("Transfer and update database")),
              myDivider(axis: Axis.horizontal),

              // web ayarlarını güncelle
              TextFormField(
                  initialValue: _shared
                      .getData("web_url")
                      .toString()
                      .replaceAll("null", ""),
                  decoration: const InputDecoration(label: Text("Web URL")),
                  onSaved: (newValue) => _shared.setData("web_url", newValue)),
              TextFormField(
                  initialValue: _shared.getData("web_username") ??
                      _shared.getData("username"),
                  decoration:
                      const InputDecoration(label: Text("Web Username")),
                  onSaved: (newValue) =>
                      _shared.setData("web_username", newValue)),
              TextFormField(
                  initialValue: _shared.getData("web_password") ??
                      _shared.getData("password"),
                  decoration:
                      const InputDecoration(label: Text("Web Password")),
                  onSaved: (newValue) =>
                      _shared.setData("web_password", newValue))
            ]),
          ),
        ));
  }

  List<Widget> _connectionWidgets() => createForms(_shared);

  _initDefaults() async {
    myDataTable branchTable = await _databaseHelper.execute(
        sql: "select Name from X_Branchs where BranchNo = ?",
        args: [_shared.getData("BranchNo")]);
    myDataTable girisDepoTable = await _databaseHelper.execute(
        sql: "select Name from CRD_StockWareHouse where ID = ?",
        args: [_shared.getData("DestStockWareHouseID")]);
    myDataTable cikisDepoTable = await _databaseHelper.execute(
        sql: "select Name from CRD_StockWareHouse where ID = ?",
        args: [_shared.getData("StockWareHouseID")]);
    setState(() {
      _branchName = branchTable.rows[0][0];
      _girisDepoName = girisDepoTable.rows[0][0];
      _cikisDepoName = cikisDepoTable.rows[0][0];
    });
    return "";
  }
}
