import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/enum/page_type.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class BaseMissionService {
  late Map<String, dynamic> _arc;

  /// @[import:$path] 형식을 $path 에 해당 되는 값으로 변환 합니다
  /// ex) @[import:search.base]
  buildImport(String code) {
    return convertImport(getArchitectureValue(code) ?? '');
  }

  //  @[import:$path] 형식을 $path 에 해당 되는 값으로 변환 합니다
  convertImport(String script) {
    RegExp regExp = RegExp(r'@\[(?:import:)(.*?)\]');
    if (regExp.hasMatch(script)) {
      Iterable<Match> matches = regExp.allMatches(script);
      for (var match in matches) {
        String? import = match.group(1);
        if (import != null) {
          script = script.replaceFirst("@[import:$import]", getArchitectureValue(import) ?? '');}
      }
    }
    return script;
  }

  // json 에서 code 에 해당하는 갑을 제공
  String? getArchitectureValue(String code) {
    List<String> keys = code.split('.');
    dynamic currentValue = _arc;
    for (String key in keys) {
      if (currentValue is Map<String, dynamic> &&
          currentValue.containsKey(key)) {
        currentValue = currentValue[key];
      } else {
        return null;
      }
    }
    return currentValue;
  }

  /// architecture 를 api 통신하여 가져옵니다
  Future<Map<String, dynamic>> buildArchitecture(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      // return MissionDTO.fromJson(jsonDecode(response.body));
      _arc = jsonDecode(response.body);
      return _arc;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load architecture');
    }
  }

  replaceStepUrl(String step) {
    return step.replaceFirst("script", "url");
  }

  replaceStepType(String step) {
    return "${step.replaceFirst("script", "type")}.name";
  }

  replaceStepTypeScript(String step) {
    return "${step.replaceFirst("script", "type")}.script";
  }

  getStepUrl(String step) {
    return getArchitectureValue(replaceStepUrl(step));
  }

  getStepType(String step) {
    return getArchitectureValue(replaceStepType(step));
  }

  getStepTypeScript(String step) {
    return getArchitectureValue(replaceStepTypeScript(step));
  }

  // 올바른 step 인지 확인
  void isValidStep(InAppWebViewController controller, String step, PageType type, Function callback) {
    // if (getStepType(step) == type.name) {
      String stepType = getStepType(step);
      String stepScript = getStepTypeScript(step);
      String script = hasImport(stepScript) ? hasScript(stepScript) ? buildImport(stepScript) : convertImport(stepScript) : stepScript;

      // 페이지 유형이 기본 일 경우

      log("isValidStep ${step}");
      log("isValidStep ${stepType}");
      log("isValidStep ${type.name}");

      // step 이 올바를 경우
      if(type == PageType.basic && stepType == PageType.basic.name) {
        log("isValidStep is equal");
        controller.evaluateJavascript(source: script).then((result) {
          log("isValidStep result $result");
          if(result) {
            callback();
          }
        });
      } else if(type == PageType.wait && stepType == PageType.wait.name) {
        log("isValidStep is not equal ${script}");
        controller.evaluateJavascript(source: script);
    }
  }

  bool hasScript(String code) {
    return code.contains('.script');
  }

  bool hasImport(String code) {
    // Check if the string contains '@import'
    return code.contains('@[import');
  }

  log(String $message) {
    debugPrint($message);
  }
}
