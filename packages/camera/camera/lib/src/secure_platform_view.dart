import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef SecuredCameraPreviewCreatedCallback = void Function(SecuredCameraPreviewController controller);

class SecuredCameraPreviewController {
  late MethodChannel _channel;

  SecuredCameraPreviewController(int id) {
    _channel = MethodChannel('MagicView/$id');
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'sendFromNative':
        String text = call.arguments as String;
        return Future.value("Text from native: $text");
    }
  }

  Future<void> receiveFromFlutter(String text) async {
    try {
      final String result = await _channel.invokeMethod('receiveFromFlutter', {"text": text});
      print("Result from native: $result");
    } on PlatformException catch (e) {
      print("Error from native: $e.message");
    }
  }

  Future<void> makeSecure() async {
    try {
      final String result = await _channel.invokeMethod('makeSecure');
      print("Result from native: $result");
    } on PlatformException catch (e) {
      print("Error from native: $e.message");
    }
  }
}

class SecuredCameraPreview extends StatelessWidget {
  static const StandardMessageCodec _decoder = StandardMessageCodec();

  final SecuredCameraPreviewCreatedCallback onViewCreated;

  const SecuredCameraPreview({
    Key? key,
    required this.onViewCreated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, String> args = {"someInit": "initData"};
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'MagicPlatformView',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: args,
        creationParamsCodec: _decoder,
      );
    }
    return UiKitView(
      viewType: 'MagicPlatformView',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: args,
      creationParamsCodec: _decoder,
    );
  }

  void _onPlatformViewCreated(int id) {
    final controller = SecuredCameraPreviewController(id);
    onViewCreated(controller);
  }
}
