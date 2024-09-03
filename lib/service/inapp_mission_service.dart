import 'dart:async';

import 'package:flutter_application_1/service/base_mission_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class InAppMissionService extends BaseMissionService {
  final CookieManager _cookieManager = CookieManager.instance();

  Future getCookie(InAppWebViewController controller, String name) {
    return controller.getUrl().then((url) {
      if (url != null) {
        return _cookieManager.getCookies(url: url).then((cookies) {
          for (Cookie cookie in cookies) {
            if (cookie.name == name) {
              return cookie;
            }
          }
        });
      }
      return null;
    });
  }

  // success : function (Response response)
  // error : function (Response response)
  getMemberInformation(InAppWebViewController controller, Function success, Function error) async {
    Cookie? aut = await getCookie(controller, 'NID_AUT');
    Cookie? ses = await getCookie(controller, 'NID_SES');

    String url = "https://new-m.pay.naver.com/api/common/member";
    final Response response =
        await http.get(Uri.parse(url), headers: <String, String>{
      "Cookie": "NID_AUT=${aut?.value};NID_SES=${ses?.value}",
    });

    if (response.statusCode == 200) {
      success(response);
    } else {
      error(response);
    }
  }

  onHistoryChanged(InAppWebViewController controller, String url, Function loaded) async {
    log("onUpdateVisitedHistory : $url");
    bool isLoaded = await waitForLoading(controller);
    if (isLoaded) {
      loaded(url);
    } else {
      log('Loading did not complete within 10 seconds.');
    }
  }


  Future<bool> waitForLoading(InAppWebViewController controller) async {
    const maxWaitTime = Duration(seconds: 10);
    const checkInterval = Duration(milliseconds: 500);
    final stopwatch = Stopwatch()..start();

    controller.evaluateJavascript(source: "").then((result) {

    });
    bool isLoaded = false;
    while (!isLoaded) {
      // 500ms 간격으로 상태를 체크합니다.
      await Future.delayed(checkInterval);

      // 최대 대기 시간을 초과한 경우 false를 반환합니다.
      if (stopwatch.elapsed > maxWaitTime) {
        stopwatch.stop();
        return false;
      }
    }

    stopwatch.stop();
    return true;
  }

  getCookies(InAppWebViewController controller) async {
    Cookie? aut = await getCookie(controller, 'NID_AUT');
    Cookie? ses = await getCookie(controller, 'NID_SES');
    return {
      'NID_AUT': aut?.value,
      'NID_SES': ses?.value,
    };
  }
}
