import 'package:equatable/equatable.dart';
import 'package:stok_anandam/features/canvas/models/data_canvasing_model.dart';

abstract class CanvasListState extends Equatable {
  const CanvasListState();
  @override
  List<Object?> get props => [];
}

class CanvasListInitial extends CanvasListState {
  const CanvasListInitial();
}

class CanvasListLoading extends CanvasListState {
  const CanvasListLoading();
}

class CanvasListLoaded extends CanvasListState {
  const CanvasListLoaded({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.sortBy,
    required this.direction,
    required this.search,
  });
  final List<DataCanvasingItem> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final String sortBy;
  final String direction;
  final String search;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, sortBy, direction, search];
}

class CanvasListError extends CanvasListState {
  const CanvasListError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
