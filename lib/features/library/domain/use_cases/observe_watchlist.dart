import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';

class ObserveWatchlist {
  const ObserveWatchlist(this._repository);

  final LibraryRepository _repository;

  Stream<List<LibraryMovie>> call() => _repository.observeWatchlist();
}
