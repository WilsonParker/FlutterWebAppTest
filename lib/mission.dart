import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/mission_service.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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

  final MissionService _service = MissionService();
  late WebViewController _controller;
  final String _url;
  late Map<String, dynamic> _json;
  List<dynamic> _steps = [];
  int _step = 0;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      // ..setUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36")
      ..clearCache()
      ..clearLocalStorage()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("Channel",
          onMessageReceived: (JavaScriptMessage message) {
        _service.log('''
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
            _service.log('''
              page start $url
            ''');
          },
          onPageFinished: (String url) {
            _service.log('''
              page finish $url
            ''');

            _service.getShoppingPage(_controller);

            String currentStepScript = _steps[_step];
            String currentStepUrl = _service.getArchitectureValue(_json, currentStepScript.replaceFirst("script", "url"));
            RegExp regExp = RegExp(r"^" + currentStepUrl);

            if (regExp.hasMatch(url)) {
              _service.log('''
                match
              ''');
              String script = _service.buildImport(_json, currentStepScript);
              _controller.runJavaScript(script);
              _step++;
            }
          },
          onWebResourceError: (WebResourceError error) {
            _service.log('''
              Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            _service.log('navigation to ${request.url}');
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            _service.log('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError error) {
            _service.log('Error occurred on page: ${error.response?.statusCode}');
          },
          onUrlChange: (UrlChange change) {
            _service.log('url change to ${change.url}');

            RegExp regExp = RegExp(r"^https://m.place.naver.com");

            if (regExp.hasMatch(change.url.toString())) {
              _service.log('''
                change match
              ''');

              Timer(Duration(seconds: 2), () {
                String script = _service.buildImport(_json, "tab.map.sub-tabs.parking.script");
                _controller.runJavaScript(script);
              });
            }
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            // openDialog(request);
          },
        ),
      );

    _service.getArchitecture(_url).then((json) {
      _json = json;

      if (_controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (_controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      _controller.loadRequest(Uri.parse(json['url']));
      _steps = json['steps'];
    });
  }

  injectJavascript(WebViewController controller, String script) async {
    _service.log("injectJavascript");
      controller.runJavaScript('''
    ''');
  }

  callScript(String javascriptMessage) {
    if (mounted) {
      _service.log('''
        javascriptMessage $javascriptMessage
      ''');
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
