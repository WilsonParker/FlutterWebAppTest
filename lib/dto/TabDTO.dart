import 'TabItemDTO.dart';

class TabDTO {
  final String url;
  final String base;
  final TabItemDTO home;
  final TabItemDTO tidings;
  final TabItemDTO menu;
  final TabItemDTO review;
  final TabItemDTO picture;
  final TabItemDTO map;
  final TabItemDTO around;
  final TabItemDTO info;

  const TabDTO({
    required this.url,
    required this.base,
    required this.home,
    required this.tidings,
    required this.menu,
    required this.review,
    required this.picture,
    required this.map,
    required this.around,
    required this.info,
  });

  factory TabDTO.fromJson(Map<String, dynamic> json) {
    return TabDTO(
      url: json['url'],
      base: json['base'],
      home: TabItemDTO.fromJson(json['home']),
      tidings: TabItemDTO.fromJson(json['tidings']),
      menu: TabItemDTO.fromJson(json['menu']),
      review: TabItemDTO.fromJson(json['review']),
      picture: TabItemDTO.fromJson(json['picture']),
      map: TabItemDTO.fromJson(json['map']),
      around: TabItemDTO.fromJson(json['around']),
      info: TabItemDTO.fromJson(json['info']),
    );
  }
}
