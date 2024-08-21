class ScriptDTO {
  final String base;
  final String script;

  const ScriptDTO({
    required this.base,
    required this.script,
  });

  factory ScriptDTO.fromJson(Map<String, dynamic> json) {
    return ScriptDTO(
      base: json['base'],
      script: json['script'],
    );
  }
}
