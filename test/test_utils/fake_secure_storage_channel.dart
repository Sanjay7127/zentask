import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs an in-memory mock handler for `flutter_secure_storage`'s
/// method channel, so [SecureKeyService] (and anything built on
/// `FlutterSecureStorage`) can be exercised in a plain `flutter test`
/// run with no real platform keychain/keystore available.
void installFakeSecureStorageChannel(TestDefaultBinaryMessenger messenger) {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};

  messenger.setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'read':
        return store[call.arguments['key'] as String];
      case 'write':
        store[call.arguments['key'] as String] = call.arguments['value'] as String;
        return null;
      case 'delete':
        store.remove(call.arguments['key'] as String);
        return null;
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(call.arguments['key'] as String);
      case 'readAll':
        return store;
      default:
        return null;
    }
  });
}
