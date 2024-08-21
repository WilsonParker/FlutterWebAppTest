import 'SubTabDTO.dart';

class TabItemDTO {
  final String script;
  final String? url;
  final SubTabDTO? subTab;

  const TabItemDTO({
    required this.script,
    required this.url,
    required this.subTab,
  });

  factory TabItemDTO.fromJson(Map<String, dynamic> json) {
    return TabItemDTO(
      script: json['script'],
      url: json['url'],
      subTab: SubTabDTO.fromJson(json['sub-tabs'] ?? {})
    );
  }
}
