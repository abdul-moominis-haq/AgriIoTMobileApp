import 'package:flutter/material.dart';

class UiHelper{


  static void showSnackbar(BuildContext context, {required String message}){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}