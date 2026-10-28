import 'package:flutter/services.dart';

class SpeechService {
  const SpeechService();

  static const _channel = MethodChannel('app.aksharamala/speech');

  Future<bool> speak(String text, String locale) async {
    try {
      return await _channel.invokeMethod<bool>('speak', {
            'text': text,
            'locale': locale,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on Object {
      // Speech is an enhancement; unsupported voices never block learning.
    }
  }
}
