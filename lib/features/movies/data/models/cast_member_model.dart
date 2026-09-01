import 'package:movies_app/core/utils/json_parsers.dart';
import 'package:movies_app/features/movies/domain/entities/cast_member.dart';

class CastMemberModel {
  const CastMemberModel({
    required this.name,
    this.characterName = '',
    this.urlSmallImage,
    this.imdbCode,
  });

  final String name;
  final String characterName;
  final String? urlSmallImage;
  final String? imdbCode;

  factory CastMemberModel.fromJson(Map<String, dynamic> json) {
    return CastMemberModel(
      name: JsonParsers.asStringOrEmpty(json['name']),
      characterName: JsonParsers.asStringOrEmpty(json['character_name']),
      urlSmallImage: JsonParsers.asString(json['url_small_image']),
      imdbCode: JsonParsers.asString(json['imdb_code']),
    );
  }

  static CastMemberModel? tryParse(Object? value) {
    final map = JsonParsers.asMap(value);
    if (map == null) {
      return null;
    }
    final model = CastMemberModel.fromJson(map);
    if (model.name.trim().isEmpty) {
      return null;
    }
    return model;
  }

  CastMember toEntity() {
    return CastMember(
      name: name,
      characterName: characterName,
      urlSmallImage: urlSmallImage,
      imdbCode: imdbCode,
    );
  }
}
