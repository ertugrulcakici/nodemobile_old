// ignore_for_file: must_be_immutable, use_key_in_widget_constructors, sort_child_properties_last, library_private_types_in_public_api

import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/material.dart';
import 'package:nodemobile/utils/database_helper.dart';
import 'package:nodemobile/utils/helpers.dart';

class BaglantiControl extends StatefulWidget {
  Widget child;
  bool? exitWhenOffline = false;
  String? message;

  BaglantiControl({required this.child, this.exitWhenOffline, this.message});

  @override
  _BaglantiControlState createState() => _BaglantiControlState();
}

class _BaglantiControlState extends State<BaglantiControl> {
  bool _serverConnected = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _checkOnce().then((value) {
      _start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
              child: AbsorbPointer(
                absorbing: true,
                child: _hasStarted
                    ? cup.CupertinoSwitch(
                        trackColor: Colors.red,
                        value: _serverConnected,
                        onChanged: (value) {})
                    : const CircularProgressIndicator(),
              ),
              bottom: 10,
              left: 10)
        ],
      ),
    );
  }

  Future _checkOnce() async {
    if (await DatabaseHelper.checkServerConnection()) {
      _serverConnected = true;
    } else {
      _serverConnected = false;
    }
    _hasStarted = true;
    return;
  }

  _start() async {
    while (true) {
      if (mounted) {
        if (await DatabaseHelper.checkServerConnection()) {
          _serverConnected = true;
        } else {
          _serverConnected = false;
          if (widget.exitWhenOffline == true) {
            showMyToast(widget.message, error: true);
            Navigator.pop(context);
          }
        }
        if (mounted) {
          setState(() {});
        }
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}
