import 'package:movies_app/features/library/domain/library_validators.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';

class RemoveFromWatchlist {
  const RemoveFromWatchlist(this._repository);

  final LibraryRepository _repository;

  Future<void> call(int movieId) {
    LibraryValidators.validateMovieId(movieId);
    return _repository.removeFromWatchlist(movieId);
  }
}
