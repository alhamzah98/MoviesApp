import 'package:equatable/equatable.dart';

class CastMember extends Equatable {
  const CastMember({
    required this.name,
    this.characterName = '',
    this.urlSmallImage,
    this.imdbCode,
  });

  final String name;
  final String characterName;
  final String? urlSmallImage;
  final String? imdbCode;

  @override
  List<Object?> get props => [name, characterName, urlSmallImage, imdbCode];
}
