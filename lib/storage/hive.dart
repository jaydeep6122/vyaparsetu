import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/storage/hive/user.dart';
import 'package:vyaparsetu/storage/hive/preferences.dart';

Future<void> openAllBoxes() async {
  await Future.wait([
    CacheBox.open(),
    UserBox.open(),
    PreferencesBox.open(),
  ]);
}

Future<void> clearBoxes() async {
  await Future.wait([
    CacheBox.clear(),
    UserBox.clear(),
  ]);
}
