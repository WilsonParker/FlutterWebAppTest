import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/dto/TabDTO.dart';

import 'SearchDTO.dart';

class MissionDTO {
  final String _url;
  final SearchDTO _search;
  final TabDTO _tab;
  final List<dynamic> _steps;

  const MissionDTO({
    required String url,
    required SearchDTO search,
    required TabDTO tab,
    required List<dynamic> steps,
  }) : _steps = steps, _tab = tab, _search = search, _url = url;

  String get url => _url;
  SearchDTO get search => _search;
  TabDTO get tab => _tab;
  List<dynamic> get steps => _steps;

  factory MissionDTO.fromJson(Map<String, dynamic> json) {
    debugPrint('''
    ${json['steps']}
    ''');
    return MissionDTO(
            url: json['url'],
            search: SearchDTO.fromJson(json['search']),
            tab: TabDTO.fromJson(json['tab']),
            steps: json['steps'],
          );
  }
}
