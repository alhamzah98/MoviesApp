import 'package:movies_app/features/library/domain/library_validators.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';

class ObserveIsInWatchlist {
  const ObserveIsInWatchlist(this._repository);

  final LibraryRepository _repository;

  Stream<bool> call(int movieId) {
    LibraryValidators.validateMovieId(movieId);
    return _repository.observeIsInWatchlist(movieId);
  }
}
