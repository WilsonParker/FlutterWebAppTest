import 'package:flutter_application_1/dto/ScriptDTO.dart';

class SearchDTO {

  final String url;
  final ScriptDTO script;

  const SearchDTO({
    required this.url,
    required this.script,
  });

  factory SearchDTO.fromJson(Map<String, dynamic> json) {
    return SearchDTO(
      url: json['url'],
      script: ScriptDTO.fromJson(json['script'])
    );
  }
}
