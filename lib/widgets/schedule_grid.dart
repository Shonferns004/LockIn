import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class ScheduleGrid extends StatelessWidget {
  const ScheduleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final week = app.currentWeek;
        if (week == null) return const SizedBox.shrink();
        DateTime? parseDate(String raw) {
          if (raw.isEmpty) return null;
          final parsed = DateTime.tryParse(raw);
          if (parsed == null) return null;
          return DateTime(parsed.year, parsed.month, parsed.day);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = (constraints.maxWidth - 36) / 7;
            final isCompact = cellWidth < 48;
            final orderedDays = week.days.toList()
              ..sort((a, b) => a.day.compareTo(b.day));
            final skippedDates = app.skippedDates.toSet();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app.weekDateRangeLabel(app.currentWeekView),
                      style: AppTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'CALENDAR',
                      style: AppTheme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: isCompact ? 0.78 : 0.9,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, i) {
                    if (i >= orderedDays.length) return const SizedBox.shrink();
                    final day = orderedDays[i];
                    final dayIdx = day.day - 1;
                    final completed = app.isCompleted(dayIdx);
                    final isSelected = app.selectedDay == dayIdx;
                    final date = parseDate(day.scheduledDate);
                    if (date == null) return const SizedBox.shrink();
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final today = DateTime.now().toLocal();
                    final todayOnly =
                        DateTime(today.year, today.month, today.day);
                    final isToday = DateUtils.isSameDay(date, todayOnly);
                    final isFuture = date.isAfter(todayOnly);
                    final isSkipped = skippedDates.contains(dateKey);

                    return GestureDetector(
                      onTap: () => app.selectDay(dayIdx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        decoration: BoxDecoration(
                          color: day.isRest
                              ? AppTheme.surfaceContainerLow
                              : isSkipped
                                  ? AppTheme.errorContainer
                                      .withValues(alpha: 0.18)
                                  : completed
                                      ? AppTheme.primaryContainer
                                          .withValues(alpha: 0.18)
                                      : AppTheme.surfaceBright,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : isToday
                                    ? AppTheme.secondary
                                    : isSkipped
                                        ? AppTheme.error
                                        : completed
                                            ? AppTheme.primaryFixedDim
                                            : AppTheme.border,
                            width: isSelected ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isSelected ? neoShadow() : null,
                        ),
                        transform: isSelected
                            ? Matrix4.translationValues(-2, -2, 0)
                            : Matrix4.identity(),
                        child: Stack(
                          children: [
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat('EEE')
                                          .format(date)
                                          .toUpperCase(),
                                      style: AppTheme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontSize: isCompact ? 7 : 8,
                                        color: day.isRest
                                            ? AppTheme.outline
                                            : isToday
                                                ? AppTheme.secondary
                                                : isSkipped
                                                    ? AppTheme.error
                                                    : (completed
                                                        ? AppTheme.primary
                                                        : AppTheme
                                                            .onSurfaceVariant),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      DateFormat('d').format(date),
                                      style: AppTheme.textTheme.headlineMedium
                                          ?.copyWith(
                                        fontSize: isCompact ? 13 : 15,
                                        color: day.isRest
                                            ? AppTheme.outline
                                            : isToday
                                                ? AppTheme.secondary
                                                : isSkipped
                                                    ? AppTheme.error
                                                    : (completed
                                                        ? AppTheme.primary
                                                        : AppTheme
                                                            .onBackground),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      day.title.length > 5
                                          ? day.title.substring(0, 5)
                                          : day.title,
                                      style: AppTheme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontSize: isCompact ? 7 : 8,
                                        color: isFuture
                                            ? AppTheme.outline
                                            : isSkipped
                                                ? AppTheme.error
                                                : (completed
                                                    ? AppTheme.primary
                                                    : AppTheme
                                                        .onSurfaceVariant),
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isSkipped)
                              const Positioned(
                                right: 4,
                                top: 4,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: AppTheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
