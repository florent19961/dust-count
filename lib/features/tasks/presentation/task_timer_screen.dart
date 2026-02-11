import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dust_count/shared/strings.dart';

/// Full-screen stopwatch for timing a task in real time.
///
/// Returns the elapsed duration in minutes (rounded up, min 1) via Navigator.pop.
class TaskTimerScreen extends StatefulWidget {
  /// Name of the task being timed (display only)
  final String taskName;

  const TaskTimerScreen({required this.taskName, super.key});

  @override
  State<TaskTimerScreen> createState() => _TaskTimerScreenState();
}

class _TaskTimerScreenState extends State<TaskTimerScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _togglePause() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
    } else {
      _stopwatch.start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _elapsed = _stopwatch.elapsed;
        });
      });
    }
    setState(() {});
  }

  int get _elapsedMinutes {
    final seconds = _stopwatch.elapsed.inSeconds;
    if (seconds <= 0) return 1;
    return (seconds / 60).ceil();
  }

  Future<void> _confirmStop() async {
    final minutes = _elapsedMinutes;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.timerConfirmStop),
        content: Text(S.timerConfirmStopMessage(minutes)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.stop),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _stopwatch.stop();
      _ticker?.cancel();
      Navigator.pop(context, minutes);
    }
  }

  Future<bool> _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.timerConfirmQuit),
        content: Text(S.timerConfirmQuitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(S.confirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = _stopwatch.isRunning;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldQuit = await _confirmQuit();
        if (shouldQuit && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Task name
                  Text(
                    widget.taskName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.timerRunning,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Timer display
                  Text(
                    _formatDuration(_elapsed),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 64),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause / Resume
                      FilledButton.tonalIcon(
                        onPressed: _togglePause,
                        icon: Icon(
                          isRunning ? Icons.pause : Icons.play_arrow,
                        ),
                        label: Text(isRunning ? S.pause : S.resume),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 56),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Stop
                      FilledButton.icon(
                        onPressed: _confirmStop,
                        icon: const Icon(Icons.stop),
                        label: Text(S.stop),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 56),
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
