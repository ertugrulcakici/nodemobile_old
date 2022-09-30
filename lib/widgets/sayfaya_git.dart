// ignore_for_file: must_be_immutable, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';

class SayfayaGit extends StatefulWidget {
  String route;
  Widget child;
  SayfayaGit({required this.child, required this.route});

  @override
  _SayfayaGitState createState() => _SayfayaGitState();
}

class _SayfayaGitState extends State<SayfayaGit> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: widget.child,
      onWillPop: () {
        Navigator.pushNamedAndRemoveUntil(
            context, widget.route, (route) => false);
        return Future.value(false);
      },
    );
  }
}
