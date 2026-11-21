import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../domain/entities/recovered_photo.dart';
import '../../domain/entities/receipt_source.dart';
import '../cubit/scan_cubit.dart';
import '../cubit/scan_state.dart';
import '../scan_messages.dart';

/// The screen between "scan a receipt" and the filled-in expense form: shows
/// that the app is working, previews a camera photo, or explains a problem.
/// On success it hands the result to the add-expense form.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.source, this.recoveredPhoto});

  final ReceiptSource source;

  /// A photo kept from before Android closed the app. When set, the screen
  /// opens on its preview instead of opening the camera.
  final RecoveredPhoto? recoveredPhoto;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  void initState() {
    super.initState();
    final recovered = widget.recoveredPhoto;
    if (recovered != null) {
      context.read<ScanCubit>().resume(recovered.path);
    } else {
      context.read<ScanCubit>().start(widget.source);
    }
  }

  void _onStateChanged(BuildContext context, ScanState state) {
    switch (state) {
      case ScanCancelled():
        // Backing out of the picker means "never mind": back to where it began.
        context.pop();
      case ScanDone(:final result):
        context.pushReplacement(AppRoutes.addExpense, extra: result);
      case ScanWorking() || ScanPreview() || ScanFailed():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan receipt')),
      // The app bar handles the top; this keeps the content clear of the
      // gesture bar and any side notch.
      body: SafeArea(
        top: false,
        child: BlocConsumer<ScanCubit, ScanState>(
          listener: _onStateChanged,
          builder: (context, state) => switch (state) {
            ScanWorking(:final stage) => _Working(
              stage: stage,
              source: widget.source,
            ),
            ScanPreview() => _Preview(state: state),
            ScanFailed(:final problem) => _Failed(
              problem: problem,
              source: widget.source,
            ),
            // The listener leaves the screen for these two.
            ScanCancelled() || ScanDone() => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.stage, required this.source});

  final ScanStage stage;
  final ReceiptSource source;

  @override
  Widget build(BuildContext context) {
    final reading = stage == ScanStage.reading;
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const Gap(AppSpacing.xl),
            Text(
              reading
                  ? 'Reading your receipt...'
                  : source == ReceiptSource.camera
                  ? 'Opening the camera...'
                  : 'Opening your photos...',
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (reading) ...[
              const Gap(AppSpacing.sm),
              Text(
                'Everything stays on your phone.',
                style: context.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final ScanPreview state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScanCubit>();
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            maxScale: 6,
            child: Center(
              child: Image.file(
                File(state.photoPath),
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
        ),
        if (state.recovered)
          Padding(
            padding: AppSpacing.screen.copyWith(top: AppSpacing.md),
            child: Text(
              'Your phone seems to have run low on memory while the camera was '
              'open, so the app restarted. This is the photo you took.',
              style: context.text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: AppSpacing.screen.copyWith(top: AppSpacing.md),
          child: Column(
            children: [
              FilledButton(
                onPressed: cubit.confirm,
                child: const Text('Use this photo'),
              ),
              const Gap(AppSpacing.sm),
              OutlinedButton(
                onPressed: cubit.retake,
                child: const Text('Retake'),
              ),
              const Gap(AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.problem, required this.source});

  final ScanProblem problem;
  final ReceiptSource source;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.scheme.onSurfaceVariant,
            ),
            const Gap(AppSpacing.lg),
            Text(
              scanFailureMessage(problem),
              style: context.text.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.xl),
            FilledButton(
              onPressed: () => context.read<ScanCubit>().start(source),
              child: const Text('Try again'),
            ),
            const Gap(AppSpacing.sm),
            TextButton(
              onPressed: () => context.pushReplacement(AppRoutes.addExpense),
              child: const Text('Enter manually'),
            ),
          ],
        ),
      ),
    );
  }
}
