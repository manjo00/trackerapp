import 'package:flutter/material.dart';

import '../../../../core/utils/week_utils.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_session_model.dart';
import '../../data/models/workout_session_model.dart';

/// "This Week" attendance — one chip per program session, filled when a
/// workout was logged for it this week. Shared by the Workout home screen
/// and the Home dashboard's workout block.
class WeekAttendanceStrip extends StatelessWidget {
  const WeekAttendanceStrip(
      {required this.program, required this.loggedIds, super.key});

  final ProgramModel program;
  final Set<int> loggedIds;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doneCount =
        program.sessions.where((s) => loggedIds.contains(s.id)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('This Week',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text(
                '$doneCount/${program.sessions.length} done',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withAlpha(160)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: program.sessions.map((s) {
              final logged = loggedIds.contains(s.id);
              return _AttendanceChip(session: s, logged: logged);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Program-session ids that have a workout logged within the current week
/// (first day per the week-start setting).
Set<int> loggedThisWeek(
    List<WorkoutSessionModel> sessions, {required bool sundayStart}) {
  final weekStart = startOfWeek(DateTime.now(), sundayStart: sundayStart);
  final ids = <int>{};
  for (final s in sessions) {
    final d = DateTime.tryParse(s.date);
    if (d == null) continue;
    if (s.programSessionId != null && !d.isBefore(weekStart)) {
      ids.add(s.programSessionId!);
    }
  }
  return ids;
}

class _AttendanceChip extends StatelessWidget {
  const _AttendanceChip({required this.session, required this.logged});

  final ProgramSessionModel session;
  final bool logged;

  @override
  Widget build(BuildContext context) {
    final color = session.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: logged ? color : color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(logged ? 0 : 120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            logged ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: logged ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(
            session.name,
            style: TextStyle(
              color: logged ? Colors.white : color,
              fontWeight: logged ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
          if (session.weekDayLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              session.weekDayLabel,
              style: TextStyle(
                color: (logged ? Colors.white : color).withAlpha(180),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
