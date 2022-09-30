// ignore_for_file: must_be_immutable, camel_case_types, use_key_in_widget_constructors, prefer_interpolation_to_compose_strings, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:nodemobile/utils/helpers.dart';

class myColorPicker extends StatefulWidget {
  String title;

  int R;
  int G;
  int B;
  double O;

  myColorPicker(this.title, this.R, this.G, this.B, this.O);

  getValues() => [R, G, B, O];

  @override
  _myColorPickerState createState() => _myColorPickerState();
}

class _myColorPickerState extends State<myColorPicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.title,
            style: TextStyle(
                color: Color.fromRGBO(widget.R.toInt(), widget.G.toInt(),
                    widget.B.toInt(), widget.O))),
        SizedBox(height: boyutY(context, 5)),
        Slider(
            activeColor: Colors.red,
            inactiveColor: Colors.red,
            label: "Value: " + widget.R.toStringAsFixed(2),
            value: widget.R.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: _changeR),
        Slider(
            activeColor: Colors.green,
            inactiveColor: Colors.green,
            label: "Value: " + widget.G.toStringAsFixed(2),
            value: widget.G.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: _changeG),
        Slider(
            activeColor: Colors.blue,
            inactiveColor: Colors.blue,
            label: "Value: " + widget.B.toStringAsFixed(2),
            value: widget.B.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: _changeB),
        Slider(
            activeColor: Colors.black,
            inactiveColor: Colors.black,
            label: "Value: " + widget.O.toStringAsFixed(2),
            value: widget.O,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: _changeO),
      ],
    );
  }

  _changeR(double value) => setState(() => widget.R = value.toInt());

  _changeG(double value) => setState(() => widget.G = value.toInt());

  _changeB(double value) => setState(() => widget.B = value.toInt());

  _changeO(double value) => setState(() => widget.O = value);
}
