import 'package:flutter_application_1/dto/ScriptDTO.dart';

class SearchDTO {

  final String url;
  final String base;
  final String script;

  const SearchDTO({
    required this.url,
    required this.base,
    required this.script,
  });

  factory SearchDTO.fromJson(Map<String, dynamic> json) {
    return SearchDTO(
      url: json['url'],
      base: json['base'],
      script: json['script'],
    );
  }
}
