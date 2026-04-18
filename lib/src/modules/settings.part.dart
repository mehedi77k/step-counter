part of 'package:step_counter_app/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});

  final StepTrackerController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    await widget.controller.refreshStepAlertSettings();
    await widget.controller.refreshBackgroundStatus();
  }

  Future<void> _openBackgroundProtectionScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackgroundProtectionScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _pickQuietStart() async {
    final controller = widget.controller;
    final selected = await showTimePicker(
      context: context,
      initialTime: controller.stepAlertQuietStart,
      helpText: 'Quiet Hours Start',
    );
    if (selected != null) {
      await controller.setQuietHoursRange(selected, controller.stepAlertQuietEnd);
    }
  }

  Future<void> _pickQuietEnd() async {
    final controller = widget.controller;
    final selected = await showTimePicker(
      context: context,
      initialTime: controller.stepAlertQuietEnd,
      helpText: 'Quiet Hours End',
    );
    if (selected != null) {
      await controller.setQuietHoursRange(controller.stepAlertQuietStart, selected);
    }
  }

  String _fmt(TimeOfDay t) => MaterialLocalizations.of(context).formatTimeOfDay(t);

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return RefreshIndicator(
              color: const Color(0xFF3248E8),
              onRefresh: _refreshAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF2B3357) : const Color(0xFFE4E7FA),
                          foregroundColor: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _refreshAll,
                        icon: const Icon(Icons.refresh_rounded),
                        color: scheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BACKGROUND PROTECTION',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF4A4674),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Some phones stop tracking after recent-app removal unless battery/autostart settings are adjusted.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFBAC0DE) : const Color(0xFF55527A),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LabelValue(
                          label: 'Battery Optimization',
                          value: controller.ignoringBatteryOptimizations ? 'Unrestricted' : 'Optimized',
                        ),
                        _LabelValue(
                          label: 'Background Restriction',
                          value: controller.backgroundRestricted ? 'Restricted' : 'Not Restricted',
                        ),
                        _LabelValue(
                          label: 'Service Status',
                          value: controller.serviceRunning ? 'Running' : 'Stopped',
                        ),
                        _LabelValue(
                          label: 'Device Brand',
                          value: controller.autoStartVendor.toUpperCase(),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _openBackgroundProtectionScreen,
                          icon: const Icon(Icons.shield_moon_outlined),
                          label: const Text('Open Background Protection Guide'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STEP ALERTS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            color: Color(0xFF4A4674),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: controller.stepAlertEnabled,
                          activeThumbColor: const Color(0xFF3248E8),
                          title: Text(
                            'Notify Every ${controller.stepAlertInterval} Steps',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            controller.stepAlertEnabled
                                ? 'Milestone notifications are active at every ${controller.stepAlertInterval} steps.'
                                : 'Step milestone notifications are currently off.',
                          ),
                          onChanged: controller.setStepAlertEnabled,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Interval',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            DropdownButton<int>(
                              value: controller.stepAlertInterval,
                              items: const [500, 1000, 2000]
                                  .map(
                                    (v) => DropdownMenuItem<int>(
                                      value: v,
                                      child: Text('$v steps'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: controller.stepAlertEnabled
                                  ? (value) {
                                      if (value != null) {
                                        controller.setStepAlertInterval(value);
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: controller.stepAlertQuietHoursEnabled,
                          activeThumbColor: const Color(0xFF3248E8),
                          title: const Text(
                            'Quiet Hours',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            controller.stepAlertQuietHoursEnabled
                                ? 'No milestone alerts from ${_fmt(controller.stepAlertQuietStart)} to ${_fmt(controller.stepAlertQuietEnd)}.'
                                : 'Notifications allowed any time.',
                          ),
                          onChanged: controller.stepAlertEnabled ? controller.setQuietHoursEnabled : null,
                        ),
                        if (controller.stepAlertEnabled && controller.stepAlertQuietHoursEnabled)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickQuietStart,
                                  icon: const Icon(Icons.bedtime_outlined),
                                  label: Text('Start ${_fmt(controller.stepAlertQuietStart)}'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickQuietEnd,
                                  icon: const Icon(Icons.wb_sunny_outlined),
                                  label: Text('End ${_fmt(controller.stepAlertQuietEnd)}'),
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
          },
        ),
      ),
    );
  }
}

class BackgroundProtectionScreen extends StatelessWidget {
  const BackgroundProtectionScreen({required this.controller, super.key});

  final StepTrackerController controller;

  String _batterySummary() {
    if (controller.ignoringBatteryOptimizations) {
      return 'Great: this app is already set to Unrestricted / Don\'t optimize.';
    }
    return 'Action needed: set this app to Unrestricted / Don\'t optimize.';
  }

  String _brandGuidance(String vendor) {
    final key = vendor.toLowerCase();
    if (key.contains('xiaomi') || key.contains('redmi') || key.contains('poco')) {
      return 'Xiaomi/MIUI: Security app > Autostart ON, Battery > No restrictions, then lock app in Recents.';
    }
    if (key.contains('oppo') || key.contains('oneplus') || key.contains('realme')) {
      return 'Oppo/Realme/OnePlus: App battery usage > Allow background activity, set to Unrestricted, enable Auto-launch.';
    }
    if (key.contains('vivo') || key.contains('iqoo')) {
      return 'Vivo/iQOO: iManager > Background power consumption management > Allow app always run in background.';
    }
    if (key.contains('samsung')) {
      return 'Samsung: Battery > Background usage limits > Never sleeping apps, and set Battery to Unrestricted.';
    }
    if (key.contains('huawei') || key.contains('honor')) {
      return 'Huawei/Honor: App launch > Manage manually, allow Auto-launch, Secondary launch, Run in background.';
    }
    return 'Open app battery settings and set this app to Unrestricted/Don\'t optimize. Then allow background activity.';
  }

  Future<void> _verifyNow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await controller.ensureBackgroundServiceRunning();
    final ok = controller.serviceRunning &&
        controller.ignoringBatteryOptimizations &&
        !controller.backgroundRestricted;
    final message = ok
        ? 'Background protection looks good on this device.'
        : 'Some protections are still missing. Please finish the actions above.';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Protection'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WHY TRACKING MAY STOP',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF4A4674)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Android battery management can pause or kill background services on some devices, especially after removing the app from recent apps.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFBBC1DE) : const Color(0xFF55527A),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _batterySummary(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUICK ACTIONS',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF4A4674)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: controller.requestIgnoreBatteryOptimization,
                            icon: const Icon(Icons.battery_charging_full_rounded),
                            label: const Text('Request Unrestricted'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.openBatteryOptimizationSettings,
                            icon: const Icon(Icons.settings_applications_rounded),
                            label: const Text('Open Battery Settings'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.openAutoStartSettings,
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            label: const Text('Open Auto-start'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.openBackgroundRestrictionSettings,
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Open App Background'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.ensureBackgroundServiceRunning,
                            icon: const Icon(Icons.health_and_safety_outlined),
                            label: const Text('Recheck Tracking Service'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MANUFACTURER NOTES',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF4A4674)),
                      ),
                      const SizedBox(height: 10),
                      _LabelValue(label: 'Detected Brand', value: controller.autoStartVendor.toUpperCase()),
                      const SizedBox(height: 8),
                      Text(
                        _brandGuidance(controller.autoStartVendor),
                        style: TextStyle(
                          color: isDark ? const Color(0xFFBBC1DE) : const Color(0xFF55527A),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'BEST FLOW',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF4A4674)),
                      ),
                      SizedBox(height: 10),
                      Text('1) Grant Activity + Notification permissions.'),
                      SizedBox(height: 4),
                      Text('2) Set battery mode to Unrestricted / Don\'t optimize.'),
                      SizedBox(height: 4),
                      Text('3) Enable Auto-start and allow background activity.'),
                      SizedBox(height: 4),
                      Text('4) Keep service notification visible.'),
                      SizedBox(height: 4),
                      Text('5) After major OS update/reboot, re-open app once to verify service health.'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _verifyNow(context),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('I Applied Changes, Verify Now'),
                ),
                const SizedBox(height: 14),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ANDROID LIMITATIONS',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF4A4674)),
                      ),
                      SizedBox(height: 10),
                      Text('Force-stop from App Info cannot be bypassed. User must open app again.'),
                      SizedBox(height: 4),
                      Text('Some OEM cleaners may still delay or kill background tracking despite correct setup.'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
