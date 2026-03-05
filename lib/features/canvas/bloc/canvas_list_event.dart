import 'package:equatable/equatable.dart';

abstract class CanvasListEvent extends Equatable {
  const CanvasListEvent();
  @override
  List<Object?> get props => [];
}

/// Memuat list canvas dengan parameter pagination & filter.
class CanvasListRequested extends CanvasListEvent {
  const CanvasListRequested({
    required this.page,
    required this.size,
    required this.sortBy,
    required this.direction,
    required this.search,
  });
  final int page;
  final int size;
  final String sortBy;
  final String direction;
  final String search;

  @override
  List<Object?> get props => [page, size, sortBy, direction, search];
}
