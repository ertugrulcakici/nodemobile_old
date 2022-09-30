// ignore_for_file: non_constant_identifier_names, camel_case_types, unused_local_variable, use_key_in_widget_constructors, empty_catches, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers, prefer_interpolation_to_compose_strings, depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/extentions.dart';
import 'package:nodemobile/utils/helpers.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// Logger _logger = Logger();
Shared _shared = Shared();

class DatabaseHelper {
  // region Kurucular
  static DatabaseHelper? _databaseHelper;
  static Database? _database;

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper._internal();
      return _databaseHelper!;
    } else {
      return _databaseHelper!;
    }
  }

  DatabaseHelper._internal();

  void initDatabase() async {
    Directory? path = await getExternalStorageDirectory();
    String dbPath = join(path!.path, "database.db");
    _database = await openDatabase(dbPath);
  }

  Future<bool> createTable(context, String tableName, bool withData) async {
    try {
      List schemeData = List.from(await getSchemaData(tableName));
      List primaryQueryList = List.empty(growable: true);
      List primary = List.empty(growable: true);
      for (var element in schemeData) {
        if (element[3] == true) {
          primaryQueryList.add(
              '"${element[0]}" ${element[1]}${element[2] == false ? " NOT NULL" : ""}');
          String query = '"${element[0]}"';
          if (element[4]) query += " AUTOINCREMENT";
          primary.add(query);
        }
      }
      await _databaseHelper!.execute(
          sql:
              'CREATE TABLE IF NOT EXISTS "$tableName" (${primaryQueryList.join(",")}, PRIMARY KEY(${primary.join(",")}))');
      List<String> queries = [];
      for (var element in schemeData) {
        String query =
            'ALTER TABLE $tableName add "${element[0]}" ${element[1]}${element[2] == false ? " NOT NULL" : ""}';
        queries.add(query);
      }
      await _databaseHelper!.executeMany(queries);

      if (withData == true) {
        List tableData = await getTableData(tableName);
        if (tableData.isNotEmpty) {
          fillTable(tableName, schemeData, tableData);
        }
      }
      log("$tableName tablosu aktarıldı");
      return true;
    } catch (e) {
      log("$tableName tablosu aktarma hatası: $e");
      return false;
    }
  }

  Future<List> getTableData(String tableName) async =>
      await DatabaseHelper.sendQuery(query: "select * from $tableName");

  Future<List> getSchemaData(String tableName) async {
    List _schemeData = await DatabaseHelper.sendQuery(
        args: [tableName],
        query:
            "SELECT c.name 'Column Name', t.Name 'Data type', c.is_nullable, ISNULL(i.is_primary_key, 0) 'Primary Key', c.is_identity AS 'is_identity' FROM sys.columns c INNER JOIN sys.types t ON c.user_type_id = t.user_type_id LEFT OUTER JOIN sys.index_columns ic  LEFT OUTER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id ON ic.object_id = c.object_id AND ic.column_id = c.column_id AND i.is_primary_key=1 WHERE c.object_id = OBJECT_ID('?');");
    List schemeData = [];
    for (var element in _schemeData) {
      List column = [];
      for (int i = 0; i < 5; i++) {
        switch (i) {
          case 0:
            column.add(element[0]);
            break;
          case 1:
            column.add(MSSQLtoSQLiteType(element[1]));
            break;
          case 2:
            column.add(element[2].toString().toLowerCase().contains("false")
                ? false
                : true);
            break;
          case 3:
            column.add(element[3].toString().toLowerCase().contains("false")
                ? false
                : true);
            break;
          case 4:
            column.add(element[4].toString().toLowerCase().contains("false")
                ? false
                : true);
            break;
        }
      }
      schemeData.add(column);
    }
    return schemeData;
  }

  fillTable(String tableName, List schemeData, List tableData) async {
    List columns = [];
    List columnsTypes = [];
    for (var element in schemeData) {
      columns.add(element[0]);
      columnsTypes.add(element[1]);
    }
    List<String> queries = [];
    for (var row in tableData) {
      List newdata = [];
      int len = (row as List).length;
      for (int i = 0; i < len; i++) {
        switch (columnsTypes[i]) {
          case "INTEGER":
            {
              try {
                newdata.add(row[i].toString().toInt(forDatabase: true));
              } catch (e) {
                log("inte dönüşemeyen değer: ${row[i].toString()}");
              }
            }
            break;
          case "REAL":
            newdata.add(row[i].toString().toDouble(forDatabase: true));
            break;
          case "TEXT":
            newdata.add(row[i].toString().toMyString());
            break;
          case "BLOB":
            newdata.add(row[i].toString().toMyString());
            break;
          default:
            log("Veri çevirme hatası !!!!!!!");
            break;
        }
      }
      String query =
          "insert into $tableName (${columns.join(",")}) VALUES (${newdata.join(",")})";
      queries.add(query);
      // await _databaseHelper!.execute(sql: query,commit: true);
    }
    // await compute(_databaseHelper!.executeList,queries);
    await _databaseHelper!.executeMany(queries);
  }
  // endregion

  // region Local database sorguları
  executeMany(List<String> queries) async {
    try {
      await _database!.transaction((txn) async {
        Batch batch = txn.batch();
        for (String query in queries) {
          batch.execute(query);
        }
        batch.commit(continueOnError: true, noResult: true);
      });
    } catch (e) {
      log("Çoklu sorgu çalıştırma hatası: $e");
    }
  }

  Future<bool> executeCommit({required String sql, List? args}) async {
    try {
      await _database!.execute(sql, args);
      return true;
    } catch (e) {
      log("Veritabanı hatası (executeCommit): ${e.toString()}");
      return false;
    }
  }

  Future<myDataTable> execute({required String sql, List? args}) async =>
      myDataTable(await _database!.rawQuery(sql, args));
  // endregion

  // region Uzak database sorguları

  // region Senkron
  static Future<bool> syncCRD() async {
    bool swState = await DatabaseHelper.checkServerConnection();
    if (!swState) return false;

    String _lastUpdate = _shared.getData("lastDBUpdateTime");

    List CRD_Items_schema = await _databaseHelper!.getSchemaData("CRD_Items");
    List CRD_Cari_schema = await _databaseHelper!.getSchemaData("CRD_Cari");

    List CRD_Items_updated = await DatabaseHelper.sendQuery(
        query:
            "select * from CRD_Items where CreatedDate > '$_lastUpdate' or ModifiedDate > '$_lastUpdate';");
    List CRD_Cari_updated = await DatabaseHelper.sendQuery(
        query:
            "select * from CRD_Cari where CreatedDate > '$_lastUpdate' or ModifiedDate > '$_lastUpdate';");

    List CRD_Cari_deleted = await DatabaseHelper.sendQuery(
        query:
            "select ISNULL(RecordID,0) from TRN_Logs where LogTitle='Silindi' and ModuleTable='CariHesap' ;",
        dimension: 1);
    List CRD_Items_deleted = await DatabaseHelper.sendQuery(
        query:
            "select ISNULL(RecordID,0) from TRN_Logs where LogTitle='Silindi' and ModuleTable='StokKarti';",
        dimension: 1);

    // deletedler
    for (var element in CRD_Cari_deleted) {
      try {
        if (element == null || element == "") continue;
        final _result = await _databaseHelper!
            .execute(sql: "delete from CRD_Cari where ID = $element");
      } catch (e) {
        log(e.toString());
      }
    }
    for (var element in CRD_Items_deleted) {
      try {
        final _result = await _databaseHelper!
            .execute(sql: "delete from CRD_Items where ID = $element");
      } catch (e) {
        log(e.toString());
      }
    }

    // updatedler
    for (var element in CRD_Cari_updated) {
      try {
        final _result = await _databaseHelper!.execute(
            sql: "delete from CRD_Cari where ID = ${int.parse(element[0])}");
      } catch (e) {
        log(e.toString());
      }
    }
    for (var element in CRD_Items_updated) {
      try {
        final _result = await _databaseHelper!.execute(
            sql: "delete from CRD_Items where ID = ${int.parse(element[0])}");
      } catch (e) {
        log(e.toString());
      }
    }

    // fill tableler
    try {
      final _result = await _databaseHelper!
          .fillTable("CRD_Cari", CRD_Cari_schema, CRD_Cari_updated);
    } catch (e) {
      log(e.toString());
    }
    try {
      final _result = await _databaseHelper!
          .fillTable("CRD_Items", CRD_Items_schema, CRD_Items_updated);
    } catch (e) {
      log(e.toString());
    }

    _shared.setData(
        "lastDBUpdateTime",
        DateTime.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch)
            .toString());

    return true;
  }

  static Future syncAllTRNEtiket() async {
    myDataTable fisNolar = await _databaseHelper!
        .execute(sql: "select FisNo from TRN_EtiketBasim where GoldenSync=0");
    for (var fisNoSatir in fisNolar.rows) {
      await DatabaseHelper.syncOneTRNEtiket(fisNoSatir[0]);
    }
    return true;
  }

  static Future syncAllTRNMalzeme() async {
    myDataTable IDler = await _databaseHelper!.execute(
        sql:
            "select ID from TRN_StockTrans where GoldenSync=0 and Cancelled=1");
    for (var id in IDler.rows) {
      await DatabaseHelper.syncOneTRNMalzeme(id[0]);
    }
    return true;
  }

  static Future<bool> syncOneTRNEtiket(String fisNo) async {
    myDataTable _baslikTable = await _databaseHelper!
        .execute(sql: "select * from TRN_EtiketBasim where FisNo='$fisNo'");
    myDataTable _satirlarTable = await _databaseHelper!.execute(
        sql: "select * from TRN_EtiketBasimEmirleri where FisNo='$fisNo'");

    var _baslik = _baslikTable.data[0];
    String _baslikQuery = """
    insert into TRN_EtiketBasim (FisNo,Tarih,DegisiklikSebebi,CreatedDate,Uygulandi,Branch,GoldenSync,CreatedBy) VALUES (
      '${_baslik["FisNo"]}',
      '${DateTime.fromMillisecondsSinceEpoch(_baslik["Tarih"])}',
      '${_baslik["DegisiklikSebebi"]}',
      '${DateTime.fromMillisecondsSinceEpoch(_baslik["CreatedDate"])}',
      0,
      ${_baslik["Branch"]},
      1,
      $USERID
    );
    """;

    String _satirlarQuery = "";
    for (var _data in _satirlarTable.data) {
      _satirlarQuery +=
          "insert into TRN_EtiketBasimEmirleri (ProductID,Tarih,Fiyat,EskiFiyat,EtiketBasildi,FisNo,Barkod,EtiketSayisi,GoldenSync,FisID,CreatedBy,CreatedDate) VALUES (${_data["ProductID"]},'${DateTime.fromMillisecondsSinceEpoch(_data["Tarih"])}',${_data["Fiyat"]},${_data["EskiFiyat"]},0,'$fisNo','${_data["Barkod"]}',${_data["EtiketSayisi"]},1,@DataID,${_data["CreatedBy"]},${_data["CreatedDate"]});";
    }

    String _query = """
    
    SET XACT_ABORT ON;

    BEGIN TRANSACTION
       DECLARE @DataID int;
       $_baslikQuery
       SELECT @DataID = scope_identity();
       $_satirlarQuery
    COMMIT
    
    SET XACT_ABORT OFF;
    """;
    bool _result = await DatabaseHelper.sendData(query: _query);

    if (_result) {
      await _databaseHelper!.executeCommit(
          sql: "update TRN_EtiketBasim set GoldenSync=1 where FisNo='$fisNo'");
      await _databaseHelper!.executeCommit(
          sql:
              "update TRN_EtiketBasimEmirleri set GoldenSync=1 where FisNo='$fisNo'");
    }
    return _result;
  }

  static Future syncOneTRNMalzeme(int ID) async {
    log("trn id : $ID");
    myDataTable _baslikTable = await _databaseHelper!
        .execute(sql: "select * from TRN_StockTrans where ID=$ID");
    myDataTable _satirlarTable = await _databaseHelper!.execute(
        sql: "select * from TRN_StockTransLines where StockTransID = $ID");
    if (_satirlarTable.data.isEmpty) {
      return "No row found";
    }

    String _baslikQuery = "";
    String _satirlarQuery = "";
    String _query = "";

    try {
      var _baslik = _baslikTable.data[0];
      _baslikQuery = """
    insert into TRN_StockTrans (FicheNo,CariID,Branch,Type,Status,TransDate,Notes,StockWareHouseID,DestStockWareHouseID,CreatedBy,CreatedDate,Cancelled,GoldenSync,SpeCode) VALUES (
    '${_baslik["FicheNo"]}',
    ${_baslik["CariID"]},
    ${_baslik["Branch"]},
    ${_baslik["Type"]},
    ${_baslik["Status"]},
    '${DateTime.fromMillisecondsSinceEpoch(_baslik["TransDate"])}',
    '${_baslik["Notes"]}',
    ${_baslik["StockWareHouseID"]},
    ${_baslik["DestStockWareHouseID"]},
    ${_baslik["CreatedBy"]},
    '${DateTime.fromMillisecondsSinceEpoch(_baslik["CreatedDate"])}',
    0,
    1,
    ${_baslik["SpeCode"]}
    );
    """;

      _satirlarQuery = "";
      for (var _data in _satirlarTable.data) {
        _satirlarQuery +=
            "insert into TRN_StockTransLines (Date,Direction,Status,StockTransID,ProductID,SeriNo,Type,ProductType,Amount,UnitID,TaxRate,Branch,GoldenSync,StockWareHouseID,DestStockWareHouseID,Cancelled,FisNo,CreatedBy,CreatedDate) VALUES ('${DateTime.fromMillisecondsSinceEpoch(_data["Date"])}',${_data["Direction"]},${_data["Status"]},@DataID,${_data["ProductID"]},'${_data["SeriNo"]}',${_data["Type"]},${_data["ProductType"]},${_data["Amount"]},${_data["UnitID"]},${_data["TaxRate"]},${_data["Branch"]},1,${_data["StockWareHouseID"]},${_data["DestStockWareHouseID"]},0,${_data["FisNo"]},${_data["CreatedBy"]},'${DateTime.fromMillisecondsSinceEpoch(_data["CreatedDate"])}');";
      }
      _query = """
    
    SET XACT_ABORT ON;

    BEGIN TRANSACTION
       DECLARE @DataID int;
       $_baslikQuery
       SELECT @DataID = scope_identity();
       $_satirlarQuery
    COMMIT
    
    SET XACT_ABORT OFF;
    """;
    } catch (e) {
      return "Transfer failed: $e";
    }
    log("query is \n" + _query);
    bool _result = await DatabaseHelper.sendData(query: _query);
    if (_result) {
      await _databaseHelper!.executeCommit(
          sql:
              "update TRN_StockTrans set GoldenSync=1,Cancelled=0 where ID=$ID");
      await _databaseHelper!.executeCommit(
          sql:
              "update TRN_StockTransLines set GoldenSync=1,Cancelled=0 where StockTransID=$ID");
    }
    return _result;
  }
  // endregion

  // region Data yollamaları
  static Future<List> sendQuery(
      {required String query, args, dimension}) async {
    // sorgunun içerisindeki her bir ? için sırayla argsdaki elemanları ? yerine koyar
    if (args != null) {
      args.forEach((element) => query = query.replaceFirst("?", element));
    }

    Socket? soket = await DatabaseHelper._serverSocket();

    if (soket == null) {
      return [];
    }

    soket.write("3" + (query.length + 1).toString());
    sleep(const Duration(milliseconds: 200));
    soket.write("0" + query);

    String data = "";
    await soket.listen((Uint8List buffer) {
      String _buffer = const Utf8Decoder(allowMalformed: true).convert(buffer);
      // String _buffer = String.fromCharCodes(buffer);
      data += _buffer;
    }, onError: (error, StackTrace trace) {
      showMyToast(
          "Data receiving error: ${error.toString()} Source: ${trace.toString()}");
    }).asFuture<void>();
    try {
      soket.close();
    } catch (e) {}

    List bodyList = [];

    for (var element in data.split("~*|")) {
      if (dimension == null || dimension == 2) {
        bodyList.add(element.split("|-|"));
      } else {
        bodyList.addAll(element.split("|-|"));
      }
    }
    return bodyList;
  }

  static Future<bool> sendData({required String query, dimension}) async {
    Socket? soket = await DatabaseHelper._serverSocket();
    if (soket == null) {
      return false;
    }
    soket.write("3" + (query.length + 1).toString());
    sleep(const Duration(milliseconds: 200));
    soket.write("1" + query);

    String data = "";
    await soket.listen((Uint8List buffer) {
      String _buffer = const Utf8Decoder(allowMalformed: true).convert(buffer);
      // String _buffer = String.fromCharCodes(buffer);
      data += _buffer;
    }, onError: (error, StackTrace trace) {
      showMyToast(
          "Data receiving error: ${error.toString()} Source: ${trace.toString()}");
    }).asFuture<void>();
    try {
      soket.close();
    } catch (e) {
      log("Socket got error while shutting down: " + e.toString());
    }
    return data == "TAMAM";
  }
  // endregion

  // region Bağlantı
  static Future<bool> checkServerConnection() async {
    Socket? soket;
    ConnectivityResult connection = await Connectivity().checkConnectivity();
    if ((connection == ConnectivityResult.wifi ||
            connection == ConnectivityResult.mobile) ==
        false) {
      return false;
    }
    soket = await DatabaseHelper._serverSocket();
    if (soket == null) {
      return false;
    }
    soket.write("2");
    String data = "";
    await soket.listen((Uint8List buffer) {
      String _buffer = const Utf8Decoder(allowMalformed: true).convert(buffer);
      data += _buffer;
    }, onError: (error, StackTrace trace) {
      showMyToast(
          "Data receiving error: ${error.toString()} Source: ${trace.toString()}");
    }).asFuture<void>();
    try {
      soket.close();
    } catch (e) {}
    return data == "TAMAM";
  }

  static Future<Socket?> _serverSocket() async {
    String remote_ip = _shared.getData("remote_ip");
    int remote_port = _shared.getData("remote_port");
    String local_ip = _shared.getData("local_ip");
    int local_port = _shared.getData("local_port");
    try {
      return await Socket.connect(local_ip, local_port,
          timeout: const Duration(
              milliseconds: 200)); // İLERDE SIKINTI ÇIKARIRSA YÜKSELT
    } catch (e) {
      try {
        return await Socket.connect(remote_ip, remote_port,
            timeout: const Duration(
                milliseconds: 200)); // İLERDE SIKINTI ÇIKARIRSA YÜKSELT
      } catch (e) {
        return null;
      }
    }
  }
  // endregion

  static Crud get CRUD => Crud();

  // endregion
}

class myDataTable {
  /// Olduğu gibi sqlite den çeken sorguyu verir. Liste içinde her satırı key value şeklinde verir. List<Map<column,value>>
  List data = List.empty(growable: true);

  void addData(_data) {
    List _tempList = List.from(data, growable: true);
    _tempList.add(_data);
    data = _tempList;
  }

  /// Sadece columnları liste şeklinde verir
  List get columns => data.first.keys;
  List get rows {
    List _ = [];
    for (var element in data) {
      element = element as Map;
      List wrapper = [];
      element.forEach((key, value) {
        wrapper.add(value);
      });
      _.add(wrapper);
    }
    return _;
    // List.generate(data.length, (index) => (data[index] as Map).values);
  }

  List<Map> get getData {
    return (data as List<Map>);
  }

  /// verilen koşula uyan satırları key value şeklinde liste içinde getirir
  List rowsBy(Map<String, dynamic> constraint, {bool? or}) {
    List _ = [];
    for (Map row in data) {
      bool correct = true;
      constraint.forEach((key, value) {
        if (value.runtimeType.toString().toLowerCase().contains("list")) {
          correct = false;
          for (var oneValue in (value as List)) {
            if (row[key] == oneValue) {
              correct = true;
            }
          }
        } else {
          if (row[key] != value) {
            correct = false;
          }
        }
      });
      if (correct) {
        _.add(row);
      }
    }
    return _;
  }

  myDataTable(this.data);

  @override
  String toString() =>
      "Columns: ${columns.toString()}\nRows: ${rows.toString()}";
}

class DatabaseDownloadScreen extends StatefulWidget {
  @override
  _DatabaseDownloadScreenState createState() => _DatabaseDownloadScreenState();
}

class _DatabaseDownloadScreenState extends State<DatabaseDownloadScreen> {
  bool done = false;
  double value = 0;

  late var popStatus;
  String status = "Welcome.\n Please wait while we download the database.";

  @override
  Widget build(BuildContext context) {
    if (done == false) {
      _initDatabase(context);
      done = true;
    }
    return WillPopScope(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: boyutY(context, 5)),
                Text(status, textAlign: TextAlign.center),
                SizedBox(height: boyutY(context, 5)),
                LinearProgressIndicator(value: value)
              ],
            ),
          ),
        ),
      ),
      onWillPop: () {
        return Future.value(false);
      },
    );
  }

  void _initDatabase(context) async {
    if (await DatabaseHelper.checkServerConnection()) {
      DatabaseHelper _databaseHelper = DatabaseHelper();
      int i = 0;
      for (MapEntry element in cekilecekTablolar.entries) {
        if (mounted) {
          setState(() {
            status = "${element.key} table is downloading...";
          });
        }
        await _databaseHelper.createTable(context, element.key, element.value);
        if (mounted) {
          setState(() {
            try {
              value = (i + 1) * (1 / cekilecekTablolar.length);
              if (value > 1.0) {
                value = 1;
              }
              status = "${element.key} table is downloaded.";
            } catch (e) {
              log("Error while refreshing screen: ${e.toString()}");
            }
          });
        }
        i++;
      }
      Navigator.pop(context, true);
    } else {
      Navigator.pop(
          context, "Setup was failed due to database connection error.");
    }
  }
}

class Crud {
  Future<bool> deleteById({required int ID, required String tableName}) async =>
      await DatabaseHelper.sendData(
          query: "delete from $tableName where ID=$ID");
  Future<bool> deleteWhere(
          {required String where, required String tableName}) async =>
      await DatabaseHelper.sendData(
          query: "delete from $tableName where $where");

  Future<bool> updateById(
      {required int ID,
      required Map<String, dynamic> data,
      required String tableName}) async {
    List<String> _ = [];
    data.forEach((key, value) {
      _.add(key + "=" + value.toString());
    });
    String query = """
    update $tableName set 
    ${data.makePair(marker: "=", end: ",")}
    where ID=$ID;
    """;
    return await DatabaseHelper.sendData(query: query);
  }

  Future<bool> updateWhere(
          {required var where,
          required Map<String, dynamic> data,
          required String tableName}) async =>
      await DatabaseHelper.sendData(
          query:
              "update $tableName set ${data.makePair(marker: "=", end: " ,")} where ${where is Map ? where.makePair(marker: "=", end: " and ") : where} ;");

  Future<bool> insert(
      {required String tableName, required Map<String, dynamic> data}) async {
    List tables = data.keys.toList();
    List values = data.values.toList();
    String query =
        "insert into $tableName (${tables.join(", ")}) VALUES (${values.join(", ")});";
    return DatabaseHelper.sendData(query: query);
  }
}
