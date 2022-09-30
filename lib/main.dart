// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:nodemobile/utils/constants.dart';
import 'package:nodemobile/utils/contants/routes.dart';
import 'package:permission_handler/permission_handler.dart';

import 'utils/database_helper.dart';
import 'utils/helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initApp();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(App());
}

Future _initApp() async {
  await Permission.storage.request();
  await Permission.camera.request();
  await Permission.manageExternalStorage.request();
  await Permission.location.request();
  await Permission.locationAlways.request();
  await Permission.locationWhenInUse.request();
  await Permission.appTrackingTransparency.request();
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  late Shared _shared;
  late DatabaseHelper _databaseHelper;
  // late Logger _logger;

  @override
  void initState() {
    _shared = Shared();
    _shared.initShared();
    _databaseHelper = DatabaseHelper();
    _databaseHelper.initDatabase();
    // _logger = Logger();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          // scaffoldBackgroundColor: myThemeData.acikGolden,
          scaffoldBackgroundColor: Colors.grey.shade100,
          primaryColor: Colors.grey.shade100,
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade200,
              border: InputBorder.none),
          appBarTheme: ThemeData.light().appBarTheme.copyWith(
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: myThemeData.koyuGolden,
              titleTextStyle: myThemeData.boldBlack18
                  .copyWith(fontSize: 20, color: Colors.white),
              toolbarTextStyle: TextTheme(
                      headline6: myThemeData.boldBlack18
                          .copyWith(fontSize: 20, color: Colors.white))
                  .bodyText2),
          primarySwatch: myThemeData.darkBlue,
          canvasColor: Colors.grey.shade100,
          iconTheme: const IconThemeData(color: Colors.white)),
      darkTheme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.home.routeName,
      routes: Routes.routes,
    );
  }
}
