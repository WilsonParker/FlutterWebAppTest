import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/enum/guide_type.dart';
import 'package:flutter_application_1/service/inapp_mission_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MissionInApp extends StatefulWidget {
  const MissionInApp({super.key, required this.url});

  final String url;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MissionInApp> createState() => _MissionInAppState(url: url);
}

class _MissionInAppState extends State<MissionInApp> {
  _MissionInAppState({required String url}) : _initUrl = url;

  final InAppMissionService _service = InAppMissionService();
  final GlobalKey webViewKey = GlobalKey();

  late InAppWebViewController webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;
  double progress = 0;
  final String _initUrl;
  String url = "";
  List<dynamic> _steps = [];
  int _step = 0;
  String _currentStepScript = '';

  @override
  void initState() {
    super.initState();
    initPullController();
  }

  initPullController() {
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
  }

  initWebController() {
    _service.buildArchitecture(_initUrl).then((json) {
      url = json['url'];
      _steps = json['steps'];
      _currentStepScript = _steps[_step];
      _service.log("load initWebController");

      // Web 과 통신 하는 channel 등록
      webViewController.addJavaScriptHandler(
          handlerName: 'Channel',
          callback: (args) {
            _service.log("channel data = $args}");

            var result = switch (args[0]) {
              'getCookies' => _service.getCookies(webViewController),
              'decreaseStep' => _step--,
              _ => null,
            };

            hook(data) {
              webViewController
                  .evaluateJavascript(
                  source: "${args[1]}('${jsonEncode(data)}')")
                  .then((result) {
                _service.log("channel evaluateJavascript = $result}");
              });
            }

            if (result is Future) {
              result.then((data) {
                _service.log("channel result = $data");
                hook(data);
              });
            } else {
              hook('');
            }
          });

      // webview url 로 이동
      webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    });
  }

  onPageFinished(String url) {
    String currentStepUrl = _service.getStepUrl(_currentStepScript);
    RegExp regExp = RegExp(r"^" + currentStepUrl);
    _service.log('''
        _currentStepScript
        $_currentStepScript
      ''');
    _service.log('''
        Page Finished
        $url
      ''');

    // script 를 실행하기 위한 url 조건이 충족할 경우
    if (regExp.hasMatch(url)) {
      _service.log(''' match''');

      String script = _service.buildImport(_currentStepScript);
      webViewController.evaluateJavascript(source: script).then((result) {
        _service.log(''' increase step''');
        _step++;
        _currentStepScript = _steps[_step];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission'),
      ),
      body: InAppWebView(
        key: webViewKey,
        initialSettings: settings,
        pullToRefreshController: pullToRefreshController,
        onWebViewCreated: (controller) {
          webViewController = controller;
          initWebController();
        },
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT);
        },
        /*shouldOverrideUrlLoading: (controller, navigationAction) async {
          var uri = navigationAction.request.url!;

          if (![
            "http",
            "https",
            "file",
            "chrome",
            "data",
            "javascript",
            "about"
          ].contains(uri.scheme)) {
            if (await canLaunchUrl(uri)) {
              // Launch the App
              await launchUrl(
                uri,
              );
              // and cancel the request
              return NavigationActionPolicy.CANCEL;
            }
          }

          return NavigationActionPolicy.ALLOW;
        },*/
        onLoadStop: (controller, url) async {
          pullToRefreshController?.endRefreshing();
        },
        onReceivedError: (controller, request, error) {
          pullToRefreshController?.endRefreshing();
        },
        onProgressChanged: (controller, progress) {
          // finished
          if (progress == 100) {
            pullToRefreshController?.endRefreshing();

            webViewController.getUrl().then((WebUri? url) {
              _service.isValidStep(controller, _currentStepScript, GuideType.basic, () => onPageFinished(url.toString()));
            });
          }
        },
        onUpdateVisitedHistory: (controller, url, isReload) {
          _service.log("onUpdateVisitedHistory $url");
          _service.isValidStep(controller, _currentStepScript, GuideType.wait, () => onPageFinished(url.toString()));
          /*
            _service.onHistoryChanged(controller, url.toString(), (url) {
            });
            */
        },
        onConsoleMessage: (controller, consoleMessage) {
          if (kDebugMode) {
            print(consoleMessage);
          }
        },
      ),
    );
  }
}
