import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

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
  _MissionState({required String url}) : _url = url;

  late WebViewController _controller;
  final String _url;
  late Map<String, dynamic> _json;
  List<dynamic> _steps = [];
  int _step = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("Channel",
          onMessageReceived: (JavaScriptMessage message) {
        debugPrint('''
          open mission
          message received ${message.message}
        ''');
        // injectJavascript(controller, message.message);
        callScript(message.message);
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

            String currentStepScript = _steps[_step];
            String currentStepUrl = getArchitectureValue(
                currentStepScript.replaceFirst("script", "url"));
            RegExp regExp = RegExp(r"^" + currentStepUrl);

            if (regExp.hasMatch(url)) {
              debugPrint('''
                match
              ''');
              String script =
                  buildImport(getArchitectureValue(currentStepScript));
              _controller.runJavaScript(script);
              _step++;
            }
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
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('Error occurred on page: ${error.response?.statusCode}');
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            // openDialog(request);
          },
        ),
      );

    getArchitecture(_url).then((json) {
      _json = json;
      _controller.loadRequest(Uri.parse(json['url']));
      _steps = json['steps'];
    });
  }

  /// architecture 를 api 통신하여 가져옵니다
  Future<Map<String, dynamic>> getArchitecture(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      // return MissionDTO.fromJson(jsonDecode(response.body));
      return jsonDecode(response.body);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load architecture');
    }
  }

  /// code 에 해당되는 값을 _json 에서 가져옵니다
  /// ex) search.url
  getArchitectureValue(String code) {
    List<String> keys = code.split('.');
    dynamic currentValue = _json;
    for (String key in keys) {
      if (_json is Map<String, dynamic> && currentValue.containsKey(key)) {
        currentValue = currentValue[key];
      } else {
        return null; // 경로가 유효하지 않으면 null 반환
      }
    }
    return currentValue;
  }

  /// @[import:$path] 형식을 $path 에 해당 되는 값으로 변환 합니다
  /// ex) @[import:search.base]
  buildImport(String text) {
    RegExp regExp = RegExp(r'@\[(?:import:)(.*?)\]');
    if (regExp.hasMatch(text)) {
      Iterable<Match> matches = regExp.allMatches(text);
      for (var match in matches) {
        String? import = match.group(1);
        if (import != null) {
          text = text.replaceFirst(
              "@[import:$import]", getArchitectureValue(import));
        }
      }
    }
    return text;
  }

  injectJavascript(WebViewController controller, String script) async {
    debugPrint('''
      injectJavascript
    ''');
    controller.runJavaScript('''
    ''');
  }

  callScript(String javascriptMessage) {
    if (mounted) {
      setState(() {
        // script = javascriptMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
