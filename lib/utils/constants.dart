// ignore_for_file: non_constant_identifier_names, camel_case_types, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// region Theme
class myThemeData {
  static final TextStyle boldBlack18 = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 18,
      fontFamily: GoogleFonts.inconsolata().fontFamily);
  static final TextStyle boldBlack16 = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      fontFamily: GoogleFonts.inconsolata().fontFamily);
  static final TextStyle boldBlack14 = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      fontFamily: GoogleFonts.inconsolata().fontFamily);
  static final TextStyle boldBlack12 = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      fontFamily: GoogleFonts.inconsolata().fontFamily);

  static const MaterialColor darkBlue = MaterialColor(0xFF007AA1, {
    50: Color(0xFF007AA1),
    100: Color(0xFF007AA1),
    200: Color(0xFF007AA1),
    300: Color(0xFF007AA1),
    400: Color(0xFF007AA1),
    500: Color(0xFF007AA1),
    600: Color(0xFF007AA1),
    700: Color(0xFF007AA1),
    800: Color(0xFF007AA1),
    900: Color(0xFF007AA1),
  });

  static const MaterialColor koyuGolden = MaterialColor(0xFF007AA1, {
    50: Color(0xFF007AA1),
    100: Color(0xFF007AA1),
    200: Color(0xFF007AA1),
    300: Color(0xFF007AA1),
    400: Color(0xFF007AA1),
    500: Color(0xFF007AA1),
    600: Color(0xFF007AA1),
    700: Color(0xFF007AA1),
    800: Color(0xFF007AA1),
    900: Color(0xFF007AA1),
  });

  static const MaterialColor acikGolden = MaterialColor(0xFF009AA4, {
    50: Color(0xFF009AA4),
    100: Color(0xFF009AA4),
    200: Color(0xFF009AA4),
    300: Color(0xFF009AA4),
    400: Color(0xFF009AA4),
    500: Color(0xFF009AA4),
    600: Color(0xFF009AA4),
    700: Color(0xFF009AA4),
    800: Color(0xFF009AA4),
    900: Color(0xFF009AA4),
  });
}
// endregion

// region Data

Map<String, bool> cekilecekTablolar = {
  // V_AllItems in hepsi
  "L_Units": true, // id, unitcode, unitname
  "X_Branchs": true, // branchno, name
  "CRD_Items": true, // çekilmeyecek
  "CRD_StockWareHouse": true, // id, name
  "CRD_Cari": true, // id, code, name, taxnumber, TaxOffice, tckno
  "CRD_ItemBarcodes": true, // çekilmeyecek
  "X_Types": true, // çekilmeyecek
  "X_Settings": true, // çekilmeyecek
  "X_Users": true, // çekilmeyecek
  "TRN_EtiketBasim": false, // çekilmeyecek
  "TRN_EtiketBasimEmirleri": false, // çekilmeyecek
  "TRN_StockTrans":
      false, // id, ficheno, invoiceid, cariid, branch, type, satus, transdate, notes, currencyid, currencyrate, stockwarehouseid, deststockwarehouseid, createdby, createddate, goldensync
  "TRN_StockTransLines":
      false // id, date, direction, status invoiceid stocktransid, productid serino beden renk type productype lineexp amount unitid unitprice currencyid currencyrate taxrate branch goldensync stockwarehouseid deststockwarehouseid createdby createddate
};

Map malzemeFisleriTypeleri = {
  0: "Receipt waybill",
  1: "Sales Waybill",
  2: "Warehouse Transfer",
  10: "Purchase Return",
  11: "Sales Refund",
  14: "Count Slip",
};

List<Map<String, dynamic>> ip_port = [
  {
    "key": "remote_ip",
    "label": "Remote IP",
    "type": "String",
    "validator": "IPvalidator"
  },
  {
    "key": "local_ip",
    "label": "Local ip",
    "type": "String",
    "validator": "IPvalidator"
  },
  {
    "key": "remote_port",
    "label": "Remote Port",
    "type": "int",
    "validator": "PORTvalidator"
  },
  {
    "key": "local_port",
    "label": "Local Port",
    "type": "int",
    "validator": "PORTvalidator"
  }
];
// endregion

// region Functions
validateIP(text) {
  if (text != "") {
    List _ = text.split(".");
    bool state = true;
    for (var element in _) {
      try {
        int.parse(element.toString());
      } catch (e) {
        state = false;
      }
      if (element.toString().length > 3) {
        state = false;
      }
    }
    if (state) {
      return null;
    } else {
      return "Wrong ip format";
    }
  } else {
    return "Null value cannot be entered";
  }
}

validatePORT(text) {
  try {
    int.parse(text);
    if (text.toString().length > 5 ||
        text.toString().isEmpty ||
        int.parse(text) > 65536) {
      return "Wrong port format";
    } else {
      return null;
    }
  } catch (e) {
    return "Wrong port format";
  }
}
// endregion

// region Settings
bool loggedIn = false;
int USERID = 0;
// endregion
