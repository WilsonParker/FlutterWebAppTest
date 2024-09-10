import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/inapp_mission_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'enum/page_type.dart';

class MissionInApp extends StatefulWidget {
  const MissionInApp(
      {super.key, required this.url, required this.parentController});

  final WebViewController parentController;
  final String url;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MissionInApp> createState() =>
      _MissionInAppState(initUrl: url, parentController: parentController);
}

class _MissionInAppState extends State<MissionInApp> {
  _MissionInAppState({required this.initUrl, required this.parentController});

  final WebViewController parentController;
  final String initUrl;
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
  String url = "";
  String _lastUrl = "";
  List<dynamic> _steps = [];
  int _step = 0;
  String _currentStep = '';
  String _lastStep = '';
  DateTime? _missionStart;

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
    _service.buildArchitecture(initUrl).then((json) {
      url = json['url'];
      _steps = json['steps'];
      _currentStep = _steps[_step];
      _service.log("load initWebController");

      // Web 과 통신 하는 channel 등록
      webViewController.addJavaScriptHandler(
          handlerName: 'Channel',
          callback: (args) {
            _service.log("channel data = $args}");

            var hook = args[1] ?? null;
            var carry = args[2] ?? null;

            callHook(data) {
              var future = data == null
                  ? webViewController.evaluateJavascript(
                      source: "$hook('$carry')")
                  : webViewController.evaluateJavascript(
                      source: "$hook('${jsonEncode(data)}', '$carry')");
              future.then((result) {
                _service.log("channel evaluateJavascript = $result}");
              });
            }

            callEvent(key) {
              switch (key) {
                case 'getCookies':
                  _service.getCookies(webViewController).then((data) {
                    callHook(data);
                  });
                  break;
                case 'pageFinished':
                  _service.log('run pageFinished');
                  webViewController
                      .getUrl()
                      .then((url) => onPageFinished(url.toString()))
                      .then((data) {
                        _service.log('pageFinished');
                        callHook(data);
                      });
                  break;
                case 'decreaseStep':
                  decreaseStep();
                  callHook(null);
                  break;
                case 'increaseStep':
                  increaseStep();
                  callHook(null);
                  break;
                case 'clearLastUrl':
                  clearLastUrl();
                  callHook(null);
                  break;
                case 'setMissionStart':
                  _missionStart = DateTime.timestamp();
                  break;
                case 'getMissionStart':
                  callHook(_missionStart);
                  break;
                case 'closeAndMove':
                  parentController.loadRequest(Uri.parse(carry));
                  Navigator.pop(context);
                  break;
              }
            }

            callEvent(args[0]);
          });

      // webview url 로 이동
      webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    });
  }

  increaseStep() {
    _service.log("_lastStepScript $_lastStep");
    _service.log("_currentStepScript $_currentStep");
    _service.log("_step $_step");
    if (_lastStep != _currentStep && _steps.length > _step + 1) {
      _step++;
      _lastStep = _currentStep;
      _currentStep = _steps[_step];
    }

    _service.log("_lastStepScript 2 $_lastStep");
    _service.log("_currentStepScript 2 $_currentStep");
    _service.log("_step 2 $_step");
  }

  decreaseStep() {
    _step--;
    _currentStep = _steps[_step];
    _lastStep = '';
    clearLastUrl();
  }

  clearLastUrl() {
    _service.log('''
        clearLastUrl
      ''');
    _lastUrl = '';
  }

  onPageFinished(String url, [String? after = null]) async {
    String currentStepUrl = _service.getStepUrl(_steps[_step]);
    RegExp regExp = RegExp(r"^" + currentStepUrl);
    _service.log('''
        _currentStep
        $_currentStep
      ''');
    _service.log('''
        Page Finished
        $url
      ''');
    _service.log('''
        Page last url
        $_lastUrl
      ''');

    // script 를 실행하기 위한 url 조건이 충족할 경우
    if (regExp.hasMatch(url) && url != _lastUrl) {
      _service.log(''' match''');
      webViewController
          .evaluateJavascript(source: _service.buildImportCode(_currentStep))
          .then((result) {
            _lastUrl = url;
            increaseStep();
            if (after != null) {
              webViewController.evaluateJavascript(source: _service.convertImport(after));
            }
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
              _service.isValidStep(controller, _currentStep, _lastStep, PageType.basic, (after) => onPageFinished(url.toString(), after));
            });
          }
        },
        onUpdateVisitedHistory: (controller, url, isReload) {
          _service.log("onUpdateVisitedHistory $url");
          _service.isValidStep(controller, _currentStep, _lastStep, PageType.wait, (after) => onPageFinished(url.toString(), after));
        },
        onConsoleMessage: (controller, consoleMessage) {
          if (kDebugMode) {
            // print(consoleMessage);
          }
        },
      ),
    );
  }
}
