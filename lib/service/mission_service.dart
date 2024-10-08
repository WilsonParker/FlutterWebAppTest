import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/base_mission_service.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class MissionService extends BaseMissionService {
  Future<Object> getCookie(WebViewController controller) async {
    final cookies = await controller.runJavaScriptReturningResult(
      'document.cookie',
    );

    await controller.runJavaScript(
      'Channel.postMessage(document.cookie);',
    );
    return cookies;
  }

  Future<Map<String, dynamic>> getShoppingPage(
      WebViewController controller) async {
    return getCookie(controller).then((cookie) async {
      // String url = "https://new-m.pay.naver.com/api/timeline/v2/advanced-search?serviceCategory=SHOPPING&requestUrl=https://new-m.pay.naver.com/historybenefit/paymenthistory?serviceCategory=SHOPPING&from=MOBILE_PAYMENT_HISTORY";
      String url = "https://new-m.pay.naver.com/api/common/member";
      // String url = "https://m.naver.com/preview/index.json?bizTalk=yes";

      final response = await http.get(Uri.parse(url), headers: <String, String>{
        // "User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
        // "Referer" : "https://new-m.pay.naver.com/pcpay?page=1",
        // "Content-Type" : "application/json; charset=utf-8",
        "Cookie": cookie.toString(),
        // "Cookie": "NID_AUT=OGw1CVn1fSI4Nqm53vGGYl2JOrOd9cKxQ8zGVW6x5HvIub7T11dqIpc076AZxqFr; NID_SES=AAABgPu1JsmGeJkgDh4Cn2h7KuSiGm4dZ/DLqu84/9ItyJa0nI8ll7kXIkumgaHAkNWaLQLAjiLMILuQz7aV95Gk7iLdd3cx+tfFTAxg9j7QwWw3pPhIpXtohpY0nfgliE/SHuzDsqxExffv9YeDyMP2rmejEkGXznZrtN6cmc96khM3FfmYwswxuSq7sWD9+1sNBW1O4jtiJcf8UFd8Y+m1Nr3xSUxiJ5XY14mdABjxBcFENQ2hthp6WKd8R9KcNX2kGieC5DqjxzbCokU5u4Y4rK9LaYjDfwqpQToSe8FZpHWZV2neEvDa0B5Q4K+5c9tyr7b/zX+5ldL8UuEUf951FbyP4tdVTPqfObc3vLPEk0CMxWwqH6jZfByG+A0mZUxhI7b1HqwE1c0lFIcm9fMSrDUXe+Sm6r6Tg5p6Jz5V/BGlWKTpgLvb2iHUDTOG936gnXOEJUybetpKBfTrp6XgIIifW5a9pvC/5OAJ/L0p0ZrVjNNkPJVqoK2Pf/4q2LWyVQ==",
      });

      log('''
      // NID_AUT 값이 없음
      cookie ${cookie.toString()}
    ''');

      // NAC=v2GpBQwzXwmQ; NNB=5YU3IWSPFHGWM; NACT=1; nid_inf=271612173; NID_AUT=ApyJpw364NGvU4/Cf8gmceTVSM2fnc9QIrAflh7zVLBE/xGFbW8unbkXQbW85BVO; NID_SES=AAABgAuR/fvNLMycIyliwJf+PYU40uJ211j8G6xYq5gyUmZ6DJ/7Z0J/u57OppVj+5vusmO4OOu/vNyNb4bwJu3NdfzUqJv55ofIGR8wH1bTzbvrM3dv1ma4IoRUh4j/yHbAdiiAFLKTQcLBbRhH196U3+qjzpnnNsdgFIQn5MBBi9W2qHZpC94KdepP6Isch+vJqQSGdj4t5CiGXQ7PLrruhX3RYpmbQOfHaPujM5w1XwIQydqGVWSSdvb4zAOVsDaRap/1sjn4Jo2vOz7RWF1+6BnsGM9GftHLsdDY74kdA5Ultm5S/JGpXHBt6WkM51XUiGscjvusXAnrrcRsriF+gN6X9g9Gifn2uoHopKMU6vLCQSMSMWasc9SD2bClmFyukb3LpznKZGky2W4v1x8DzqhyOqrYVv9X5xUIJC/e45yaEu+gFpR4ymwRQCcR2F0YtMT/DrOQ7oOnHPN7PJv3olm41roi6eg6+jCganbeAgsXAEv9PJ+aLCwUq8kLLLOznw==; NID_JKL=/aXpJc8Y/fOzt3SbwyOV2wNVo6aQ74DcCitR7ITyZII=; BUC=0BXZbZomzwpsSX6kV1NkwReMJAiNKQw4dBicW1tqdpQ=
      // NNB=CQAR4TKLPHCWM; MM_PF=SEARCH; BNB_FINANCE_HOME_TOOLTIP_PAYMENT=true; BNB_FINANCE_HOME_TOOLTIP_ESTATE=true; BNB_FINANCE_HOME_TOOLTIP_STOCK=true; NID_JKL=gJV6KYBQVZuSjuHj1g69QudYOonfpyIQRPMZ55ev1uo=; NID_SES=AAABgpvBmNZwf8cLM6895JlDtbNMtdICrW7rgFYac9A5J0XsS/cuFQQoFCDrGnoteExkGNQucSzdeHwWvaaKEEIvU5DbwcAHC1uA6v/buCS1Fmuhc7vX7V288x8u5hu031uS8JsDe/dqJzLqcIJdfOa9VrzUF4EJs5BpOPR+PbuiY9fMkuB9LU5CjI+88oPF6Jsh6OfBmVUSTmcqyOE7DEjddjdZF2ABwse6v+FxxuP8Q7hUSayq+5eTqqi3d9QRC+1afccC55i7bcZvZRFvnalkT5lNN7QjPSocDMKboYewbHPAKWd/vNjedLO+KJVrEAFwK6GsbAeo54yhlw5UPVaMgBBiwGXghm/7P8Ur+HbCEsZ7c4JCjk2qlMaWG6W8Ne9+rbMlp036SFEcPBJDEKVinF/IyjRQjAsLD8+FjRo/PyoYFQ9jhHYno/R/BBTMmA1HoxHGWukYwfycUKnNgVbhRS735u15hQI03wj88F0hLXJEd8E73uwxra8RWGgCs1GHhQyXqvMjSItmNQi9V9VujrI=; nid_inf=271601234; page_uid=iV03ulpr4boss7xvVsVssssstYV-385707; NAC=z41LBQQsdQOG; NACT=1; MM_search_homefeed=true
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        // return MissionDTO.fromJson(jsonDecode(response.body));
        log('''
          getShoppingPage ${response.body}
        ''');
        log('''
          getShoppingPage ${response.headers}
        ''');
        log('''
          getShoppingPage ${response.headers['set-cookie']}
        ''');
        return jsonDecode(response.body);
      } else {
        log('''
          getShoppingPage ${response.statusCode}
          getShoppingPage ${response.body}
        ''');
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Failed to load api');
      }
    });
  }

}
