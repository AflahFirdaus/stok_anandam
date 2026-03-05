import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:stok_anandam/features/canvas/data/canvas_repository.dart';
import 'package:dio/dio.dart';

import 'canvas_list_event.dart';
import 'canvas_list_state.dart';

class CanvasListBloc extends Bloc<CanvasListEvent, CanvasListState> {
  CanvasListBloc({CanvasRepository? repository})
      : _repository = repository ?? CanvasRepository(),
        super(const CanvasListInitial()) {
    on<CanvasListRequested>(_onRequested);
  }

  final CanvasRepository _repository;

  Future<void> _onRequested(CanvasListRequested event, Emitter<CanvasListState> emit) async {
    emit(const CanvasListLoading());
    try {
      final result = await _repository.getList(
        page: event.page,
        size: event.size,
        sortBy: event.sortBy,
        direction: event.direction,
        search: event.search.isEmpty ? null : event.search,
      );
      emit(CanvasListLoaded(
        items: result.items,
        page: event.page,
        size: event.size,
        totalPages: result.totalPages,
        totalElements: result.totalElements,
        sortBy: event.sortBy,
        direction: event.direction,
        search: event.search,
      ));
    } on DioException catch (e) {
      emit(CanvasListError(AppErrors.userMessageFromDio(e)));
    } catch (e) {
      emit(CanvasListError(AppErrors.userMessageFromException(e)));
    }
  }
}
