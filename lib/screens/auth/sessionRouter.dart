import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/business/form.dart';
import 'package:vyaparsetu/screens/business/list.dart';
import 'package:vyaparsetu/screens/home/home.dart';

/// After signing in: create a first business, pick one, or open the app.
Future<void> openAfterSignIn(BuildContext context) async {
  final business = context.read<Core>().business;
  final navigator = Navigator.of(context);

  await business.fetchBusinesses();

  final Widget next;
  if (business.businesses.isEmpty) {
    next = const BusinessFormScreen(isOnboarding: true);
  } else if (business.selectedBusiness != null) {
    next = const HomeScreen();
  } else {
    next = const BusinessListScreen(isRoot: true);
  }
  navigator.pushAndRemoveUntil(getPageRoute(next), (_) => false);
}
