import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/enum/page_type.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class BaseMissionService {
  late Map<String, dynamic> _arc;

  /// @[import:$path] 형식을 $path 에 해당 되는 값으로 변환 합니다
  /// ex) @[import:search.base]
  buildImport(String script) {
    return convertImport(getArchitectureValue(script) ?? '');
  }

  buildImportCode(String code) {
    return buildImport("$code.script");
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
      if (currentValue is Map<String, dynamic> && currentValue.containsKey(key)) {
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

  getCurrentStepScript(List<dynamic> steps, int step) {
    return "${steps[step]}.script";
  }

  getStepScript(String step) {
    return getArchitectureValue("$step.script");
  }

  getStepUrl(String step) {
    return getArchitectureValue("$step.url");
  }

  getStepTypeScript(String step, PageType type) {
    return getArchitectureValue("$step.type.${type.name}.script");
  }

  hasStepType(String step, PageType type) {
    return getArchitectureValue("$step.type.${type.name}.script") != null;
  }

  // 올바른 step 인지 확인
  void isValidStep(InAppWebViewController controller, String step, String lastStep, PageType type, Function callback) {
      log("isValidStep ${step}");
      log("isValidStep ${lastStep}");
      log("isValidStep ${type.name}");
      log("isValidStep ${hasStepType(step, PageType.basic)}");

      if(type == PageType.basic && hasStepType(step, PageType.basic)) {
        String stepScript = getStepTypeScript(step, PageType.basic);
        String script = hasImport(stepScript) ? hasScript(stepScript) ? buildImport(stepScript) : convertImport(stepScript) : stepScript;
        log("isValidStep stepScript $stepScript");
        log("isValidStep script $script");
        controller.evaluateJavascript(source: script).then((result) {
          log("isValidStep result $result");
          if(result) {
            callback();
          }
        });
      } else if(type == PageType.wait && hasStepType(step, PageType.wait)) {
        String stepScript = getStepTypeScript(step, PageType.wait);
        String script = hasImport(stepScript) ? hasScript(stepScript) ? buildImport(stepScript) : convertImport(stepScript) : stepScript;
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
