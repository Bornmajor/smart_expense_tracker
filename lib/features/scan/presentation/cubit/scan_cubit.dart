import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/receipt_source.dart';
import '../../domain/usecases/scan_receipt.dart';
import 'scan_state.dart';

/// Runs one scan, step by step, and tells the screen where it is.
///
/// A photo from the camera stops at [ScanPreview] so the user can use it or
/// retake it. A file was chosen on purpose, so it is read
/// straight away.
class ScanCubit extends Cubit<ScanState> {
  ScanCubit(this._scan) : super(const ScanWorking(ScanStage.picking));

  final ScanReceipt _scan;

  /// Where the current photo came from, so Retake opens the same place.
  ReceiptSource _source = ReceiptSource.camera;

  /// True while the camera or Files app is open or a photo is being read. A
  /// second tap during that time is ignored.
  bool _running = false;

  /// Opens the camera or the Files app.
  Future<void> start(ReceiptSource source) => _run(() async {
    _source = source;
    emit(const ScanWorking(ScanStage.picking));

    final picked = await _scan.pick(source);
    if (isClosed) {
      // The screen was left while the camera was open.
      if (picked is Success<String>) await _scan.discard(picked.value);
      return;
    }

    switch (picked) {
      case null:
        emit(const ScanCancelled());
      case Failure(failure: final ScanFailure failure):
        emit(ScanFailed(failure.problem));
      case Failure():
        emit(const ScanFailed(ScanProblem.cameraUnavailable));
      case Success(value: final path) when source == ReceiptSource.camera:
        emit(ScanPreview(path));
      case Success(value: final path):
        await _read(path);
    }
  });

  /// Shows a photo that was taken before Android restarted the app. It came
  /// from the camera, so it gets the same preview as any camera photo.
  void resume(String photoPath) {
    if (_running) return;
    _source = ReceiptSource.camera;
    emit(ScanPreview(photoPath, recovered: true));
  }

  /// The user is happy with the previewed photo: read it.
  Future<void> confirm() {
    final current = state;
    if (current is! ScanPreview) return Future.value();
    return _run(() => _read(current.photoPath));
  }

  /// The user does not want the previewed photo: delete it and open the camera
  /// (or the Files app) again.
  Future<void> retake() async {
    final current = state;
    if (current is! ScanPreview || _running) return;
    await _scan.discard(current.photoPath);
    await start(_source);
  }

  Future<void> _read(String photoPath) async {
    emit(const ScanWorking(ScanStage.reading));

    final result = await _scan.read(photoPath);
    if (isClosed) {
      // Nobody is looking any more, so nobody will use the photo.
      if (result is Success) await _scan.discard(photoPath);
      return;
    }

    switch (result) {
      case Success(:final value):
        emit(ScanDone(value));
      case Failure(failure: final ScanFailure failure):
        emit(ScanFailed(failure.problem));
      case Failure():
        emit(const ScanFailed(ScanProblem.unreadable));
    }
  }

  /// Runs one step at a time. Anything that goes wrong that the use case did
  /// not expect is a bug: it is reported, and the screen still moves on to a
  /// failure instead of spinning forever.
  Future<void> _run(Future<void> Function() action) async {
    if (_running) return;
    _running = true;
    try {
      await action();
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      if (!isClosed) emit(const ScanFailed(ScanProblem.unreadable));
    } finally {
      _running = false;
    }
  }

  @override
  Future<void> close() async {
    final current = state;
    // Left while previewing: the photo is not going anywhere.
    if (current is ScanPreview) await _scan.discard(current.photoPath);
    return super.close();
  }
}
