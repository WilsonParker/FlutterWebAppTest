import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

import 'dto/MissionDTO.dart';

class Mission extends StatefulWidget {
  const Mission({super.key, required this.url});

  final String url;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Mission> createState() => _MissionState(url: url);
}

class _MissionState extends State<Mission> {
  _MissionState({required this.url});

  late WebViewController controller;
  final String url;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("channel",
          onMessageReceived: (JavaScriptMessage message) {
            debugPrint('''
    open mission
    message received ${message.message}
    ''');
            injectJavascript(controller, message.message);
          })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            debugPrint('''
    page start $url
    ''');
          },
          onPageFinished: (String url) {
            debugPrint('''
    page finish $url
    ''');
            // injectJavascript(controller);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
        ),
      );

    getArchitecture(url).then((dto) {
            debugPrint('''
            url ${dto.url}
            ''');
      controller
        ..loadRequest(Uri.parse(dto.url));
    });
  }

  Future<MissionDTO> getArchitecture(String url) async {
    final response =  await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return MissionDTO.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  injectJavascript(WebViewController controller, String script) async {
    debugPrint('''
      injectJavascript
    ''');
    controller.runJavaScript('''
    setTabColor("지도");
    channel.postMessage(333);
''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
