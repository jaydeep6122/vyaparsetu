import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';

void showSuccessToast(String message, {int durationSeconds = 3}) {
  Flushbar(
    message: message,
    backgroundColor: AppTheme.success,
    duration: Duration(seconds: durationSeconds),
    flushbarStyle: FlushbarStyle.FLOATING,
    messageColor: Colors.white,
    borderRadius: BorderRadius.circular(7),
    margin: const EdgeInsets.symmetric(horizontal: 5).copyWith(bottom: 5),
    padding: const EdgeInsets.symmetric(vertical: 15).copyWith(left: 15),
    animationDuration: const Duration(milliseconds: 400),
    forwardAnimationCurve: Curves.decelerate,
    isDismissible: true,
  ).show(navigatorKey.currentContext!);
}

void showErrorToast(String message, {int durationSeconds = 3}) {
  Flushbar(
    message: message,
    backgroundColor: AppTheme.error,
    duration: Duration(seconds: durationSeconds),
    flushbarStyle: FlushbarStyle.FLOATING,
    messageColor: Colors.white,
    borderRadius: BorderRadius.circular(7),
    margin: const EdgeInsets.symmetric(horizontal: 5).copyWith(bottom: 5),
    padding: const EdgeInsets.symmetric(vertical: 15).copyWith(left: 15),
    animationDuration: const Duration(milliseconds: 400),
    forwardAnimationCurve: Curves.decelerate,
    isDismissible: true,
  ).show(navigatorKey.currentContext!);
}

void showInfoToast(String message, {int durationSeconds = 3}) {
  Flushbar(
    message: message,
    backgroundColor: AppTheme.info,
    duration: Duration(seconds: durationSeconds),
    flushbarStyle: FlushbarStyle.FLOATING,
    messageColor: Colors.white,
    borderRadius: BorderRadius.circular(7),
    margin: const EdgeInsets.symmetric(horizontal: 5).copyWith(bottom: 5),
    padding: const EdgeInsets.symmetric(vertical: 15).copyWith(left: 15),
    animationDuration: const Duration(milliseconds: 400),
    forwardAnimationCurve: Curves.decelerate,
    icon: const Icon(Icons.info, color: Colors.white),
    isDismissible: true,
  ).show(navigatorKey.currentContext!);
}
