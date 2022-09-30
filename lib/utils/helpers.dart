// ignore_for_file: non_constant_identifier_names, library_prefixes, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:core';
import 'dart:developer' as dv;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:nodemobile/utils/constants.dart' as staticData;
import 'package:nodemobile/widgets/my_divider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

boyutX(context, ratio) => (MediaQuery.of(context).size.width / 100) * ratio;

boyutY(context, ratio) => (MediaQuery.of(context).size.height / 100) * ratio;

boyutOran(context, [ratio]) => ratio == null
    ? double.parse((boyutY(context, 100) / boyutX(context, 100)).toString())
    : double.parse(((boyutY(context, 100) / boyutX(context, 100)) / 100 * ratio)
        .toString());

showMyToast(message, {bool error = false}) async {
  await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM_LEFT,
      backgroundColor: error == false ? Colors.white70 : Colors.redAccent,
      textColor: error == false ? Colors.black : Colors.white,
      fontSize: 16.0);
}

showMyStack(
    {required BuildContext context,
    String message = "",
    String? actionText,
    Function? actionFunc,
    bool? error}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error == true ? Colors.red : Colors.black,
      content: Text(message),
      action: actionText != null
          ? SnackBarAction(
              textColor: Colors.white,
              label: actionText,
              onPressed: () {
                if (actionFunc != null) {
                  actionFunc.call();
                }
              })
          : null));
}

String MSSQLtoSQLiteType(String type) {
  Map<String, dynamic> types = {
    "char": "TEXT",
    "bit": "INTEGER",
    "int": "INTEGER",
    "double": "REAL",
    "float": "REAL",
    "date": "INTEGER",
    "decimal": "REAL",
    "image": "BLOB"
  };
  bool broken = false;
  types.forEach((key, value) {
    if (type.toLowerCase().contains(key)) {
      if (!broken) {
        type = value;
      } else {
        broken = false;
      }
    }
  });
  return type;
}

List<Widget> createForms(Shared shared, {bool setup = false}) {
  List<Widget> _ = [];
  var data = staticData.ip_port;
  for (var element in data) {
    var _value = shared.getData(element["key"]);

    _.add(TextFormField(
      keyboardType: TextInputType.number,
      initialValue: setup == true
          ? element["key"].toString().contains("ip")
              ? "192.168.1."
              : "27110"
          : _value == null
              ? ""
              : _value.toString(),
      onSaved: (data) {
        if (element["type"] == "int") {
          shared.setData(element["key"], int.parse(data.toString()));
        }
        if (element["type"] == "String") {
          shared.setData(element["key"], data);
        }
      },
      validator: (text) {
        if (element["validator"] == "IPvalidator") {
          return staticData.validateIP(text);
        }
        if (element["validator"] == "PORTvalidator") {
          return staticData.validatePORT(text);
        }
        if (element["validator"] == null) return null;
        return null;
      },
      decoration: InputDecoration(
        labelText: element["label"],
        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),borderSide: BorderSide(color: Colors.grey,width: 1))
      ),
    ));
    if (!setup) {
      _.add(myDivider(axis: Axis.horizontal, gradient: true));
    }
  }
  return _;
}

class Shared {
  static Shared? _shared;
  static SharedPreferences? _mySharedPreferences;

  factory Shared() {
    if (_shared == null) {
      _shared = Shared._internal();
      return _shared!;
    } else {
      return _shared!;
    }
  }

  Shared._internal();

  Future<bool> check() async {
    if (_mySharedPreferences == null) {
      await initShared();
    }
    if (_mySharedPreferences!.get("setup") == null) {
      return false;
    } else {
      return true;
    }
  }

  initShared() async =>
      _mySharedPreferences = await SharedPreferences.getInstance();

  clear() => _mySharedPreferences!.clear();

  getData(String key, [type]) {
    if (type == null) return _mySharedPreferences!.get(key);
    if (type.runtimeType == int) return _mySharedPreferences!.getInt(key);
    if (type.runtimeType == double) return _mySharedPreferences!.getDouble(key);
    if (type.runtimeType == String) return _mySharedPreferences!.getString(key);
  }

  // datanın türünü fonksiyonu kullanırken ayarlıyoruz
  setData(String key, dynamic data) {
    if (data.runtimeType == bool) _mySharedPreferences!.setBool(key, data);
    if (data.runtimeType == int) _mySharedPreferences!.setInt(key, data);
    if (data.runtimeType == double) _mySharedPreferences!.setDouble(key, data);
    if (data.runtimeType == String) {
      _mySharedPreferences!.setString(key, data.toString());
    }
  }
}

// class Logger {
//
//   static Logger? _logger;
//   static File? _error;
//   static File? _successful;
//
//   factory Logger() {
//     if (_logger == null) {
//       print("logger oluştu");
//       _logger = Logger._initializeLogger();
//       return _logger!;
//     }
//     else {
//       return _logger!;
//     }
//
//   }
//
//   Logger._initializeLogger() {
//     getExternalStorageDirectory().then((Directory? value) {
//       Directory dir = Directory(value!.path+"/logs/"+DateTime.now().year.toString()+"."+DateTime.now().month.toString()+"."+DateTime.now().day.toString());
//       dir.create(recursive: true);
//       _error = File(join(dir.path, "error.txt"));
//       _successful = File(join(dir.path, "successful.txt"));
//     });
//     print("Logger kuruldu");
//   }
//
//   logError(title,e) async => _error!.writeAsString(DateTime.now().hour.toString()+":"+DateTime.now().minute.toString()+":"+DateTime.now().second.toString()+": "+ title+": "+e.toString()+"\n",mode: FileMode.append);
//   logSuccessful(text) async => _successful!.writeAsString(DateTime.now().hour.toString()+":"+DateTime.now().minute.toString()+":"+DateTime.now().second.toString()+": "+ text+"\n",mode: FileMode.append);
//
// }

Color randomColor({double opacity = 1.0}) => Color.fromRGBO(
    Random().nextInt(255),
    Random().nextInt(255),
    Random().nextInt(255),
    opacity);

Future<bool> eskiDBUyarisi(BuildContext context) async {
  Shared _shared = Shared();
  return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
              title: const Text("Warning!"),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        "The database connection could not be established. Now, continuing with old data."),
                    Text(
                        "The last update time: ${_shared.getData("lastDBUpdateTime")}")
                  ]),
              actions: [
                TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Ok")),
                TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Try again")),
              ]));
}

Future<int?> getIstanbulUnixtime() async {
  try {
    String _data = (await get(
            Uri.parse("http://worldtimeapi.org/api/timezone/Europe/Istanbul")))
        .body;
    return json.decode(_data)["unixtime"];
  } catch (e) {
    return null;
  }
}

Future<bool> getAndWriteIstanbulUnixtime() async {
  try {
    dv.log("1");
    int _unixtime = await getIstanbulUnixtime() as int;
    dv.log("2");
    String _dir =
        "/${(await getExternalStorageDirectory())!.path.split("/").getRange(1, 4).join("/")}/";
    dv.log("3");
    try {
      dv.log("4");
      await Permission.storage.request();
      dv.log("5");
      await Permission.manageExternalStorage.request();
      dv.log("6");
      File _file = File("${_dir}unixtime.txt");
      dv.log("7");
      dv.log("ss${await Permission.manageExternalStorage.status}");
      Permission.manageExternalStorage.request();
      _file.writeAsStringSync(_unixtime.toString(), flush: true);
      dv.log("8");
      return true;
    } catch (e) {
      return false;
    }
  } catch (e) {
    return false;
  }
}

String encrypt(String value) {
  int _toplam = 0;
  String _alfabe = "0987654321xqzyvüutşsrpöonmlkjiıhğgfedçcba";
  for (var element in value.characters) {
    _toplam += _alfabe.indexOf(element) * value.length * value.length;
  }
  return _toplam.toString();
}
