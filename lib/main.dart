import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

part 'src/modules/step_tracker_controller.part.dart';
part 'src/modules/settings.part.dart';
part 'src/modules/shared_widgets.part.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const KineticPulseApp());
}

class KineticPulseApp extends StatelessWidget {
  const KineticPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Step Counter',
      themeMode: ThemeMode.system,
      theme: _AppTheme.light,
      darkTheme: _AppTheme.dark,
      home: const HomeShell(),
    );
  }
}

class _AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF3EFFA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3248E8),
      secondary: Color(0xFFF067B3),
      surface: Color(0xFFF9F8FD),
      onSurface: Color(0xFF1E1A4F),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF101327),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7D8BFF),
      secondary: Color(0xFFFF9BD0),
      surface: Color(0xFF1A1F39),
      onSurface: Color(0xFFE7E9FF),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final StepTrackerController controller = StepTrackerController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await controller.init();
    if (!mounted || !Platform.isAndroid || controller.widgetGuideSeen) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWidgetGuideDialog();
    });
  }

  Future<void> _showWidgetGuideDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Home Widget'),
          content: const Text(
            'Pin the Step Counter widget to your home screen for live steps at a glance. You can also enable lock-screen view in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await controller.setWidgetGuideSeen(true);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                await controller.requestPinWidget();
                await controller.setWidgetGuideSeen(true);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Pin Widget'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSettingsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: controller),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final pages = [
          DashboardScreen(controller: controller, onOpenSettings: _openSettingsScreen),
          ActivityScreen(controller: controller, onOpenSettings: _openSettingsScreen),
          GoalsScreen(controller: controller, onOpenSettings: _openSettingsScreen),
        ];

        final navigationBar = Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B203A).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x40000000) : const Color(0x220F1659),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomItem(
                icon: Icons.bolt,
                text: 'DASH',
                selected: currentIndex == 0,
                onTap: () => setState(() => currentIndex = 0),
              ),
              _BottomItem(
                icon: Icons.bar_chart,
                text: 'ACTIVITY',
                selected: currentIndex == 1,
                onTap: () => setState(() => currentIndex = 1),
              ),
              _BottomItem(
                icon: Icons.person,
                text: 'GOALS',
                selected: currentIndex == 2,
                onTap: () => setState(() => currentIndex = 2),
              ),
            ],
          ),
        );

        final pageBody = kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: pages[currentIndex],
                ),
              )
            : pages[currentIndex];

        return Scaffold(
          body: SafeArea(child: pageBody),
          bottomNavigationBar: kIsWeb
              ? Align(
                  alignment: Alignment.center,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: navigationBar,
                  ),
                )
              : navigationBar,
        );
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.controller, required this.onOpenSettings, super.key});

  final StepTrackerController controller;
  final VoidCallback onOpenSettings;

  String get _chipStatus {
    if (controller.status.toLowerCase().contains('live')) {
      return 'ACTIVE';
    }
    if (controller.status.toLowerCase().contains('permission')) {
      return 'PERMISSION';
    }
    return 'SYNCING';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          _TopHeader(onSettingsTap: onOpenSettings),
          const SizedBox(height: 18),
          _ringCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.route,
                  iconBg: const Color(0xFFD8D2FB),
                  title: 'DISTANCE',
                  value: controller.distanceKm.toStringAsFixed(2),
                  unit: 'km',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department,
                  iconBg: const Color(0xFFFFC0E2),
                  title: 'CALORIES',
                  value: controller.calories.toString(),
                  unit: 'kcal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _activeMinutesCard(),
          const SizedBox(height: 16),
          _dateWiseActivityCard(),
        ],
      ),
    );
  }

  Widget _ringCard() {
    return _Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          SizedBox(
            height: 280,
            width: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 260,
                  width: 260,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 14,
                    color: const Color(0xFFD6D0F7),
                  ),
                ),
                SizedBox(
                  height: 260,
                  width: 260,
                  child: CircularProgressIndicator(
                    value: controller.progress,
                    strokeWidth: 14,
                    backgroundColor: Colors.transparent,
                    color: const Color(0xFF3146E6),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat('#,###').format(controller.stepsToday),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1A4B),
                        height: 1,
                      ),
                    ),
                    Text(
                      '/ ${NumberFormat('#,###').format(controller.goal)} steps',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF46426E),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E1F7),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: Color(0xFF2E3EE3),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _chipStatus,
                            style: const TextStyle(
                              color: Color(0xFF2035D2),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeMinutesCard() {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7F8FF6),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.access_time_filled, color: Color(0xFF08188A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ACTIVE MINUTES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3F3C6D),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.activeMinutes} min',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF201E52),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 124,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'GOAL: 60M',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2540DF),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 124,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: (controller.activeMinutes / 60).clamp(0.0, 1.0),
                    color: const Color(0xFF2D43E6),
                    backgroundColor: const Color(0xFFDAD5F7),
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _dateWiseActivityCard() {
    return _DateWiseActivityCard(controller: controller);
  }
}

class _DateWiseActivityCard extends StatefulWidget {
  const _DateWiseActivityCard({required this.controller});

  final StepTrackerController controller;

  @override
  State<_DateWiseActivityCard> createState() => _DateWiseActivityCardState();
}

class _DateWiseActivityCardState extends State<_DateWiseActivityCard> {
  late final PageController _pageController;
  int _currentPage = 6;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    final dailySteps = widget.controller.weeklySteps;
    final selectedDay = days[_currentPage];
    final isToday = selectedDay == today;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF17162A)),
              ),
              const Spacer(),
              Text(
                DateFormat('EEE, d MMM').format(selectedDay),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Color(0xFF213BDE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 204,
            child: PageView.builder(
              controller: _pageController,
              itemCount: days.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final day = days[index];
                final steps = dailySteps[index];
                final distance = steps * 0.00075;
                final calories = (steps * 0.04).round();
                final activeMinutes = steps <= 0 ? 0 : max(1, (steps / 120).ceil());
                final dayIsToday = day == today;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0FC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0DCF8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('EEEE').format(day),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3F3C6D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (dayIsToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1E6FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFF2E46E5),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat('#,###').format(steps),
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1,
                          color: Color(0xFF1F1C50),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'STEPS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Color(0xFF5C5881),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active $activeMinutes min', style: const TextStyle(color: Color(0xFF4A4677), fontSize: 13)),
                          Text('${distance.toStringAsFixed(2)} km', style: const TextStyle(color: Color(0xFF4A4677), fontSize: 13)),
                          Text('$calories kcal', style: const TextStyle(color: Color(0xFF4A4677), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Swipe left: previous date', style: TextStyle(color: Color(0xFF6A668F), fontSize: 11)),
              Text(
                isToday ? 'Right: latest update' : 'Swipe right: newer date',
                style: const TextStyle(color: Color(0xFF6A668F), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 7; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentPage ? const Color(0xFF3348E7) : const Color(0xFFCFCBF1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({required this.controller, required this.onOpenSettings, super.key});

  final StepTrackerController controller;
  final VoidCallback onOpenSettings;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _showMonthly = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final now = DateTime.now();
        final isMonthly = _showMonthly;
        final periodDays = isMonthly ? now.day : 7;
        final periodStart = isMonthly ? DateTime(now.year, now.month, 1) : now.subtract(const Duration(days: 6));

        final dailySteps = isMonthly
            ? List<int>.generate(
                periodDays,
                (index) => controller.stepsForDate(DateTime(now.year, now.month, index + 1)),
              )
            : controller.weeklySteps;

        final dayLabels = isMonthly
            ? List<String>.generate(periodDays, (index) => '${index + 1}')
            : List<String>.generate(
                7,
                (index) => DateFormat('EEE').format(now.subtract(Duration(days: 6 - index))).toUpperCase(),
              );

        int highestDayIndex = 0;
        int highestDay = dailySteps.isEmpty ? 0 : dailySteps.first;
        for (int i = 1; i < dailySteps.length; i++) {
          if (dailySteps[i] > highestDay) {
            highestDay = dailySteps[i];
            highestDayIndex = i;
          }
        }

        final chartSteps = isMonthly
            ? List<int>.generate(max(1, (periodDays / 7).ceil()), (bucket) {
                final startDay = (bucket * 7) + 1;
                final endDay = min(periodDays, startDay + 6);
                var total = 0;
                for (int day = startDay; day <= endDay; day++) {
                  total += dailySteps[day - 1];
                }
                return total;
              })
            : dailySteps;

        final chartLabels = isMonthly
            ? List<String>.generate(chartSteps.length, (index) => 'W${index + 1}')
            : dayLabels;

        final maxChartSteps = chartSteps.isEmpty ? 0 : chartSteps.reduce(max);
        final highestChartIndex = chartSteps.isEmpty ? 0 : chartSteps.indexOf(maxChartSteps);

        final dateRange = '${DateFormat('MMM d').format(periodStart)} - ${DateFormat('MMM d, y').format(now)}';
        final periodTotal = dailySteps.fold<int>(0, (sum, value) => sum + value);
        final periodTarget = controller.goal * max(1, periodDays);
        final periodProgress = (periodTotal / max(1, periodTarget)).clamp(0.0, 1.0);
        final averageSteps = periodTotal ~/ max(1, periodDays);
        final progressLabel = '${(periodProgress * 100).round()}%';
        final highestDayLabel = isMonthly
            ? DateFormat('MMM d').format(DateTime(now.year, now.month, highestDayIndex + 1))
            : dayLabels[highestDayIndex];
        final trendLabel = periodTotal == 0
            ? 'No movement yet'
            : 'Best: $highestDayLabel ${NumberFormat.compact().format(highestDay)}';

        final activeHours = controller.activeMinutes / 60.0;
        final sedentaryHours = max(0.0, 24 - activeHours);
        final activeProgress = (controller.activeMinutes / 180).clamp(0.0, 1.0);
        final sedentaryProgress = (sedentaryHours / 24).clamp(0.0, 1.0);

        return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopHeader(onSettingsTap: widget.onOpenSettings),
          const SizedBox(height: 16),
          Text(
            isMonthly ? 'Monthly Activity' : 'Weekly Activity',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.05),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dateRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF4B4774), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDCD8F6),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    _PillBtn(
                      title: 'WEEK',
                      active: !isMonthly,
                      onTap: () {
                        if (_showMonthly) {
                          setState(() => _showMonthly = false);
                        }
                      },
                    ),
                    _PillBtn(
                      title: 'MONTH',
                      active: isMonthly,
                      onTap: () {
                        if (!_showMonthly) {
                          setState(() => _showMonthly = true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Panel(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: SizedBox(
              height: 286,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NumberFormat('#,###').format(periodTotal),
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Color(0xFF3348E7), height: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMonthly ? 'TOTAL STEPS THIS MONTH' : 'TOTAL STEPS THIS WEEK',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A3669),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trendLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9B2A78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 102,
                    child: maxChartSteps > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (int i = 0; i < chartSteps.length; i++)
                                Container(
                                  width: chartSteps.length >= 7 ? 16 : 24,
                                  height: ((chartSteps[i] / maxChartSteps) * 72).clamp(6, 72),
                                  decoration: BoxDecoration(
                                    color: i == highestChartIndex
                                        ? const Color(0xFF3348E7)
                                        : const Color(0xFFC9C6EE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: Text(
                              isMonthly ? 'No monthly step data yet' : 'No weekly step data yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7A769E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i < chartLabels.length; i++)
                        Expanded(
                          child: Text(
                            chartLabels[i],
                            textAlign: TextAlign.center,
                            style: _DayStyle(active: i == highestChartIndex && maxChartSteps > 0),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.monitor_heart,
                    iconBg: const Color(0xFFC9D3FF),
                    title: 'AVERAGE STEPS',
                    value: NumberFormat('#,###').format(averageSteps),
                    unit: '',
                    subtitle: 'Goal: ${NumberFormat.compact().format(controller.goal)} daily',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.star,
                    iconBg: const Color(0xFFFAC0E6),
                    title: 'HIGHEST DAY',
                    value: NumberFormat('#,###').format(highestDay),
                    unit: '',
                    subtitle: highestDay == 0 ? 'No peak yet' : 'Peak on $highestDayLabel',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${isMonthly ? 'MONTHLY' : 'WEEKLY'} PROGRESS VS.\nGOAL',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                      ),
                    ),
                    Text(
                      '$progressLabel\nComplete',
                      style: const TextStyle(color: Color(0xFF2640E0), fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 16,
                    value: periodProgress,
                    color: const Color(0xFF3147E7),
                    backgroundColor: const Color(0xFFE3DFFB),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current: ${NumberFormat.compact().format(periodTotal)}',
                      style: const TextStyle(color: Color(0xFF4D4878), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Target: ${NumberFormat.compact().format(periodTarget)} steps',
                      style: const TextStyle(color: Color(0xFF4D4878), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '• FOCUS BREAKDOWN',
            style: TextStyle(fontSize: 20, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF4F4A78)),
          ),
          const SizedBox(height: 12),
          _focusItem('Active hours', '${activeHours.toStringAsFixed(1)}h', activeProgress, Icons.directions_run, true),
          const SizedBox(height: 10),
          _focusItem('Sedentary time', '${sedentaryHours.toStringAsFixed(1)}h', sedentaryProgress, Icons.airline_seat_recline_normal, false),
        ],
      ),
    );
      },
    );
  }

  Widget _focusItem(String title, String value, double progress, IconData icon, bool active) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: active ? const Color(0xFFE7ECFF) : const Color(0xFFF1F1F1),
            child: Icon(icon, color: active ? const Color(0xFF2D43E5) : const Color(0xFFA2A2AE)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    color: active ? const Color(0xFF3146E6) : const Color(0xFFC4C4CB),
                    backgroundColor: const Color(0xFFE8E7F3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({required this.controller, required this.onOpenSettings, super.key});

  final StepTrackerController controller;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopHeader(compact: true, onSettingsTap: onOpenSettings),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3147E8), Color(0xFF2D39CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3A1B2CCD),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pushing Boundaries',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'You\'ve reached 85% of your weekly movement goal. Keep the momentum going!',
                  style: TextStyle(color: Color(0xFFE9EBFF), fontSize: 16, height: 1.35),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _StatMini(value: '24', label: 'DAY STREAK'),
                    SizedBox(width: 8),
                    _StatMini(value: '12.4k', label: 'AVG STEPS'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('⚜ Personal Records', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('ALL-TIME PEAK', style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w800, color: Color(0xFF2339DF))),
                SizedBox(height: 6),
                Text('28,452', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                Text('Steps in a single day · June 12, 2023', style: TextStyle(color: Color(0xFF5A567F))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: Icons.route,
            iconBg: const Color(0xFFD8D1FA),
            title: 'TOTAL DISTANCE',
            value: '1,402',
            unit: 'km',
            subtitle: 'Equivalent to walking from Paris to Rome.',
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: Icons.bolt,
            iconBg: const Color(0xFFF9CBEA),
            title: 'ACTIVE MINUTES',
            value: '42.5k',
            unit: '',
            subtitle: 'Total focused activity time since joining.',
          ),
          const SizedBox(height: 12),
          const Text('↗ Weekly Trends', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Steps', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                          Text('Last 7 days', style: TextStyle(color: Color(0xFF5A567E))),
                        ],
                      ),
                    ),
                    Text('+12%', style: TextStyle(color: Color(0xFF1F39E0), fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 130,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final heights = [0.55, 0.43, 0.72, 0.6, 0.84, 0.5, 0.63];
                      return Container(
                        width: 22,
                        height: 120 * heights[index],
                        decoration: BoxDecoration(
                          color: index == 4 ? const Color(0xFF3348E7) : const Color(0xFFABA7E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('🏆 Trophy Cabinet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: const [
              _BadgeItem(title: '10k Step Club', subtitle: 'Unlocked Jun 23', color: Color(0xFFF8F5E6), icon: Icons.stars),
              _BadgeItem(title: '7 Day Streak', subtitle: 'Unlocked Aug 23', color: Color(0xFFF1F6FF), icon: Icons.calendar_today),
              _BadgeItem(title: 'Marathon Month', subtitle: 'Unlocked Oct 23', color: Color(0xFFF8F3FF), icon: Icons.directions_run),
              _BadgeItem(title: 'Nature Walker', subtitle: 'Unlocked Nov 23', color: Color(0xFFF0FAF4), icon: Icons.park),
            ],
          ),
        ],
      ),
    );
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({required this.controller, required this.onOpenSettings, super.key});

  final StepTrackerController controller;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final remaining = max(0, controller.goal - controller.stepsToday);
    final goalProgress = (controller.stepsToday / max(1, controller.goal)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          _TopHeader(onSettingsTap: onOpenSettings),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.track_changes, color: Color(0xFF3248E8)),
                    SizedBox(width: 8),
                    Text('Goal Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  NumberFormat('#,###').format(controller.stepsToday),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF223FE0), height: 1),
                ),
                const Text(
                  'STEPS TODAY',
                  style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w700, color: Color(0xFF4C4875)),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: goalProgress,
                    color: const Color(0xFF3348E7),
                    backgroundColor: const Color(0xFFE3DFFB),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Goal ${NumberFormat.compact().format(controller.goal)}', style: const TextStyle(color: Color(0xFF59557F))),
                    Text('Remaining ${NumberFormat.compact().format(remaining)}', style: const TextStyle(color: Color(0xFF59557F))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackVertically = constraints.maxWidth < 380;

              final statsCard = _Panel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monitor_heart, color: Color(0xFF2640E0)),
                        SizedBox(width: 10),
                        Text('LIVE STATS', style: TextStyle(color: Color(0xFF2C43E4), fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _LabelValue(label: 'Distance', value: '${controller.distanceKm.toStringAsFixed(2)} km'),
                    _LabelValue(label: 'Calories', value: '${controller.calories} kcal'),
                    _LabelValue(label: 'Active', value: '${controller.activeMinutes} min'),
                  ],
                ),
              );

              final progressCard = Container(
                padding: const EdgeInsets.all(16),
                height: 204,
                decoration: BoxDecoration(
                  color: const Color(0xFF3248E8),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x40212B95), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.white),
                        Spacer(),
                        _ActiveChip(label: 'ACTIVE'),
                      ],
                    ),
                    const Spacer(),
                    const Text('Goal Progress', style: TextStyle(color: Color(0xFFE2E7FF), fontSize: 18)),
                    Text(
                      '${(goalProgress * 100).round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                    Text(
                      '${NumberFormat.compact().format(controller.stepsToday)} / ${NumberFormat.compact().format(controller.goal)}',
                      style: const TextStyle(color: Color(0xFFE2E7FF), fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                  ],
                ),
              );

              if (stackVertically) {
                return Column(
                  children: [
                    statsCard,
                    const SizedBox(height: 12),
                    progressCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: statsCard),
                  const SizedBox(width: 14),
                  Expanded(child: progressCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: Color(0xFF9B257A)),
                    const SizedBox(width: 10),
                    const Text('Daily Goals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => controller.setGoal(10000),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA8B4FF),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Text('Reset', style: TextStyle(color: Color(0xFF223FDF), fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Target Steps', style: TextStyle(fontSize: 20, color: Color(0xFF3F3B6B))),
                    ),
                    Text(
                      NumberFormat('#,###').format(controller.goal),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderThemeData(
                    thumbColor: const Color(0xFF3A4EEA),
                    activeTrackColor: const Color(0xFF3A4EEA),
                    inactiveTrackColor: const Color(0xFFE3DDF9),
                    overlayColor: const Color(0x1A3A4EEA),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    min: 5000,
                    max: 25000,
                    value: controller.goal.toDouble(),
                    divisions: 40,
                    label: NumberFormat('#,###').format(controller.goal),
                    onChanged: (value) => controller.setGoal(value.round()),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('REHAB (5K)', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF58537E))),
                    Text('STANDARD (10K)', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF58537E))),
                    Text('ATHLETE (25K)', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF58537E))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


