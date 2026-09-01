import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/library_validators.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';

class RecordHistory {
  const RecordHistory(this._repository);

  final LibraryRepository _repository;

  Future<void> call(LibraryMovie movie) {
    LibraryValidators.validateSnapshot(movie);
    return _repository.recordHistory(movie);
  }
}
