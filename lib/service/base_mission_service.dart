import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BaseMissionService {
  late Map<String, dynamic> _arc;

  /// @[import:$path] 형식을 $path 에 해당 되는 값으로 변환 합니다
  /// ex) @[import:search.base]
  buildImport(String code) {
    String script = getArchitectureValue(code);
    RegExp regExp = RegExp(r'@\[(?:import:)(.*?)\]');
    if (regExp.hasMatch(script)) {
      Iterable<Match> matches = regExp.allMatches(script);
      for (var match in matches) {
        String? import = match.group(1);
        if (import != null) {
          script = script.replaceFirst(
              "@[import:$import]", getArchitectureValue(import));
        }
      }
    }
    return script;
  }

  // json 에서 code 에 해당하는 갑을 제공
  getArchitectureValue(String code) {
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
    return step.replaceFirst("script", "type");
  }

  getStepUrl(String step) {
    return getArchitectureValue(replaceStepUrl(step));
  }

  getStepType(String step) {
    return getArchitectureValue(replaceStepType(step));
  }

  log(String $message) {
    debugPrint($message);
  }
}
