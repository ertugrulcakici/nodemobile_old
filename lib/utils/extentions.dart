// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:developer';

import 'package:nodemobile/utils/database_helper.dart';

extension ToDateTimeExtention on int {
  DateTime toDateTime() => DateTime.fromMillisecondsSinceEpoch(this);
  String toDateTimeString({bool tarih = true, bool saat = true}) {
    String _date = DateTime.fromMillisecondsSinceEpoch(this).toString();
    if (tarih == true && saat == false) {
      return _date.split(" ")[0];
    }
    if (tarih == false && saat == true) {
      return _date.split(" ")[1].split(".")[0];
    }
    if (tarih == true && saat == true) {
      return _date.split(".")[0];
    }
    return "";
  }
}

extension ToDateTime on String {
  int? toDateTimeEpoch({bool gunayyil = false}) {
    if (toDateTime(gunayyil: gunayyil) != null) {
      return toDateTime(gunayyil: gunayyil)!.millisecondsSinceEpoch;
    } else {
      return null;
    }
  }

  DateTime? toDateTime({bool gunayyil = false}) {
    if (split(" ").length > 1) {
      // hem tarih hem saat
      String tarih = split(" ")[0].replaceAll(" ", "");
      List _tarih = [];
      if (tarih.contains(".")) {
        _tarih.addAll(tarih.split("."));
      }
      if (tarih.contains("-")) {
        _tarih.addAll(tarih.split("-"));
      }
      int gun = 0;
      int ay = 0;
      int yil = 0;
      if (gunayyil) {
        gun = int.parse(_tarih[0]);
        ay = int.parse(_tarih[1]);
        yil = int.parse(_tarih[2]);
      } else {
        yil = int.parse(_tarih[0]);
        ay = int.parse(_tarih[1]);
        gun = int.parse(_tarih[2]);
      }
      List saat = split(" ")[1].replaceAll(" ", "").split(":");
      return DateTime(yil, ay, gun, int.parse(saat[0]), int.parse(saat[1]),
          int.parse(saat[2]));
    } else {
      if ((".".allMatches(this).length == 2 ||
              ".".allMatches(this).length == 1) ||
          ("-".allMatches(this).length == 2 ||
              "-".allMatches(this).length == 1)) {
        // sadece tarih
        String _ = replaceAll(" ", "");
        List tarih = [];
        if (_.contains(".")) {
          tarih.addAll(_.split("."));
        } else if (_.contains("-")) {
          tarih.addAll(_.split("-"));
        }

        if (gunayyil) {
          int gun = int.parse(tarih[0]);
          int ay = int.parse(tarih[1]);
          int yil = int.parse(tarih[2]);
          return DateTime(yil, ay, gun);
        } else {
          int yil = int.parse(tarih[0]);
          int ay = int.parse(tarih[1]);
          int gun = int.parse(tarih[2]);
          return DateTime(yil, ay, gun);
        }
      }
    }
    return null;
  }
}

extension ToNumExtention on String {
  toDouble({bool? forDatabase}) {
    if (toString().isEmpty ||
        toString().toLowerCase().contains("null") ||
        toString().toLowerCase().contains("none") ||
        toString().isEmpty) {
      if (forDatabase == true) {
        return "null";
      } else {
        return 0.0;
      }
    } else {
      try {
        return double.parse(toString().replaceAll(",", "."));
      } catch (e) {
        log("${toString()} i Double ye dönüştürme hatası: ${e.toString()}");
        return 0.0;
      }
    }
  }

  toInt({bool? forDatabase}) {
    if (toString().isEmpty ||
        toString().toLowerCase().contains("null") ||
        toString().toLowerCase().contains("none") ||
        toString().isEmpty) {
      if (forDatabase == true) {
        return "null";
      } else {
        return 0;
      }
    }

    /// BİT LER İÇİN ///
    else if (toString().toLowerCase().contains("false")) {
      return 0;
    } else if (toString().toLowerCase().contains("true")) {
      return 1;
    }

    /// BİT LER İÇİN ///

    /// tarihler için
    else {
      if ((length == 19 || length == 18 || length == 17) &&
          ":".allMatches(this).length == 2 &&
          ".".allMatches(this).length == 2) {
        List _ = split(" ");
        List<String> tarih = (_[0] as String).split(".");
        List<String> saat = (_[1] as String).split(":");

        return DateTime(
                int.parse(tarih[2]),
                int.parse(tarih[1]),
                int.parse(tarih[0]),
                int.parse(saat[0]),
                int.parse(saat[1]),
                int.parse(saat[2]))
            .millisecondsSinceEpoch;
        // return DateTime.parse("${tarih[2]}-${tarih[1]}-${tarih[0].length == 2 ? tarih[0] : '0'+tarih[0]} ${saat[0]}:${saat[1]}:${saat[2]}").millisecondsSinceEpoch;
      } else {
        try {
          return int.parse(toString());
        } catch (e) {
          log("int e dönüştürme hatası: ${e.toString()} int değer: ${toString()}");
          return 0;
        }
      }
    }
  }

  toMyString() {
    if (toString().isEmpty ||
        toString().toLowerCase().contains("null") ||
        toString().toLowerCase().contains("none") ||
        toString().isEmpty) {
      return "null";
    } else {
      return "'${toString().replaceAll("'", "''")}'";
    }
  }
}

extension ToListExtention on List {
  myDataTable toDataTable() {
    return myDataTable(this);
  }
}

extension MapToString on Map {
  String makePair({required String marker, required String end}) {
    List _ = [];
    forEach((key, value) {
      _.add(key.toString() + marker + value.toString());
    });
    return _.join(end);
  }
}
