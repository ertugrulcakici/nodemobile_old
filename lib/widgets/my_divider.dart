import 'package:flutter/material.dart';

Widget myDivider(
    {bool gradient = false, required Axis axis, double thickness = 0.5}) {
  return Container(
    margin: EdgeInsets.zero,
    height: axis == Axis.horizontal ? thickness : double.infinity,
    width: axis == Axis.horizontal ? double.infinity : thickness,
    decoration: gradient == true
        ? BoxDecoration(
            gradient: LinearGradient(
            colors: const [Colors.white, Colors.black, Colors.white],
            begin: axis == Axis.horizontal
                ? Alignment.centerLeft
                : Alignment.topCenter,
            end: axis == Axis.horizontal
                ? Alignment.centerRight
                : Alignment.bottomCenter,
          ))
        : const BoxDecoration(color: Colors.black),
  );
}
