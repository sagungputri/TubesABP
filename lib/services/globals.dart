import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Change this based on your setup
const String baseURL = "http://10.0.2.2:8000/api"; // Android Emulator
// const String baseURL = "http://192.168.x.x:8000/api"; // Real device

const Map<String, String> headers = {"Content-Type": "application/json"};

errorSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: Colors.red,
    content: Text(text),
    duration: const Duration(seconds: 1),
  ));
}
