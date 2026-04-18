part of 'package:step_counter_app/main.dart';

class StepTrackerController extends ChangeNotifier {
  static const _keyLastSensorSteps = 'last_sensor_steps';
  static const _keyDailySteps = 'daily_steps';
  static const _keyDailyDate = 'daily_date';
  static const _keyWeekHistoryData = 'week_history_data';
  static const _keyHourlyActivityDate = 'hourly_activity_date';
  static const _keyHourlyActivityData = 'hourly_activity_data';
  static const _keyGoal = 'daily_goal';
  static const _keyWidgetGuideSeen = 'widget_guide_seen';
  static const _keyWidgetLockEnabled = 'widget_lock_enabled';
  static const _keyStepAlertEnabled = 'step_alert_enabled';
  static const _keyStepAlertInterval = 'step_alert_interval';
  static const _keyStepAlertQuietEnabled = 'step_alert_quiet_enabled';
  static const _keyStepAlertQuietStart = 'step_alert_quiet_start_min';
  static const _keyStepAlertQuietEnd = 'step_alert_quiet_end_min';
  static const _defaultGoal = 10000;
  static const MethodChannel _serviceChannel = MethodChannel('step_counter/bg_service');
  static const EventChannel _stepEventChannel = EventChannel('step_counter/step_updates');

  StreamSubscription<StepCount>? _subscription;
  StreamSubscription<dynamic>? _stepEventsSubscription;
  Timer? _androidPoller;
  int _stepsToday = 0;
  Map<String, int> _weeklyHistory = <String, int>{};
  List<int> _hourlyActivity = List<int>.filled(24, 0);
  int _goal = _defaultGoal;
  bool _widgetGuideSeen = false;
  bool _lockScreenWidgetEnabled = false;
  bool _statusChecksLoading = false;
  bool _stepAlertEnabled = true;
  int _stepAlertInterval = 1000;
  bool _stepAlertQuietHoursEnabled = false;
  TimeOfDay _stepAlertQuietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _stepAlertQuietEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _ignoringBatteryOptimizations = true;
  bool _backgroundRestricted = false;
  bool _autoStartSettingsAvailable = false;
  bool _serviceRunning = true;
  String _autoStartVendor = 'android';
  bool _ready = false;
  String _status = 'Starting sensor...';

  int get goal => _goal;
  bool get widgetGuideSeen => _widgetGuideSeen;
  bool get lockScreenWidgetEnabled => _lockScreenWidgetEnabled;
  bool get statusChecksLoading => _statusChecksLoading;
  bool get stepAlertEnabled => _stepAlertEnabled;
  int get stepAlertInterval => _stepAlertInterval;
  bool get stepAlertQuietHoursEnabled => _stepAlertQuietHoursEnabled;
  TimeOfDay get stepAlertQuietStart => _stepAlertQuietStart;
  TimeOfDay get stepAlertQuietEnd => _stepAlertQuietEnd;
  bool get ignoringBatteryOptimizations => _ignoringBatteryOptimizations;
  bool get backgroundRestricted => _backgroundRestricted;
  bool get autoStartSettingsAvailable => _autoStartSettingsAvailable;
  bool get serviceRunning => _serviceRunning;
  String get autoStartVendor => _autoStartVendor;
  int get stepsToday => _stepsToday;
  int stepsForDate(DateTime date) {
    final stamp = _stampForDate(date);
    if (stamp == _todayStamp()) {
      return _stepsToday;
    }
    return _weeklyHistory[stamp] ?? 0;
  }

  List<int> stepsForLastDays(int days) {
    final now = DateTime.now();
    return List<int>.generate(days, (index) {
      final day = now.subtract(Duration(days: days - 1 - index));
      return stepsForDate(day);
    });
  }

  List<int> get weeklySteps {
    final now = DateTime.now();
    return List<int>.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final stamp = _stampForDate(day);
      if (index == 6) {
        return _stepsToday;
      }
      return _weeklyHistory[stamp] ?? 0;
    });
  }

  List<int> get hourlyActivity => List<int>.unmodifiable(_hourlyActivity);
  bool get ready => _ready;
  String get status => _status;

  double get distanceKm => _stepsToday * 0.00075;
  int get calories => (_stepsToday * 0.04).round();
  int get activeMinutes {
    if (_stepsToday <= 0) {
      return 0;
    }
    // Keep activity minutes responsive so small movement updates are visible quickly.
    return max(1, (_stepsToday / 120).ceil());
  }

  double get progress => (_stepsToday / _goal).clamp(0.0, 1.0);

  Future<void> init() async {
    final granted = await _requestPermission();
    if (!granted) {
      _status = 'Motion permission is required for real-time step counting.';
      _ready = true;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = _todayStamp();
    _goal = prefs.getInt(_keyGoal) ?? _defaultGoal;
    _stepAlertEnabled = prefs.getBool(_keyStepAlertEnabled) ?? true;
    _stepAlertInterval = prefs.getInt(_keyStepAlertInterval) ?? 1000;
    _stepAlertQuietHoursEnabled = prefs.getBool(_keyStepAlertQuietEnabled) ?? false;
    _stepAlertQuietStart = _timeFromMinutes(prefs.getInt(_keyStepAlertQuietStart) ?? 1320);
    _stepAlertQuietEnd = _timeFromMinutes(prefs.getInt(_keyStepAlertQuietEnd) ?? 420);
    _widgetGuideSeen = prefs.getBool(_keyWidgetGuideSeen) ?? true;
    _lockScreenWidgetEnabled = prefs.getBool(_keyWidgetLockEnabled) ?? true;
    if (!_widgetGuideSeen) {
      _widgetGuideSeen = true;
      await prefs.setBool(_keyWidgetGuideSeen, true);
    }
    if (!_lockScreenWidgetEnabled) {
      _lockScreenWidgetEnabled = true;
      await prefs.setBool(_keyWidgetLockEnabled, true);
    }
    _stepsToday = prefs.getInt(_keyDailySteps) ?? 0;
    _weeklyHistory = _readWeekHistory(prefs);
    _hourlyActivity = _readHourlyActivity(prefs);

    await _rolloverDayIfNeeded(prefs, today, persistedTodaySteps: _stepsToday);
    _stepsToday = prefs.getInt(_keyDailySteps) ?? _stepsToday;

    if (prefs.getString(_keyHourlyActivityDate) != today) {
      _hourlyActivity = List<int>.filled(24, 0);
      await _saveHourlyActivity(prefs, today);
    }

    _weeklyHistory[today] = _stepsToday;
    _pruneWeekHistory();
    await _saveWeekHistory(prefs);

    _ready = true;
    _status = 'Syncing 24h tracker...';
    notifyListeners();

    if (Platform.isAndroid) {
      await _startAndroidForegroundService();
      _attachAndroidStepStream();
      await _refreshAndroidSteps();
      await refreshStepAlertSettings();
      await refreshBackgroundStatus();
      _androidPoller = Timer.periodic(const Duration(seconds: 3), (_) {
        _refreshAndroidSteps();
      });
      return;
    }

    _subscription = Pedometer.stepCountStream.listen((event) async {
      final prefsInner = await SharedPreferences.getInstance();
      final todayStamp = _todayStamp();
      final lastSensor = prefsInner.getInt(_keyLastSensorSteps);
      int storedSteps = prefsInner.getInt(_keyDailySteps) ?? 0;

      await _rolloverDayIfNeeded(prefsInner, todayStamp, persistedTodaySteps: storedSteps);
      storedSteps = prefsInner.getInt(_keyDailySteps) ?? 0;

      if (lastSensor == null) {
        _stepsToday = storedSteps;
        _status = '24h tracking ready';
        _ready = true;
        await prefsInner.setInt(_keyLastSensorSteps, event.steps);
        await prefsInner.setInt(_keyDailySteps, _stepsToday);
        _weeklyHistory[todayStamp] = _stepsToday;
        await _saveWeekHistory(prefsInner);
        notifyListeners();
        return;
      }

      var delta = event.steps - lastSensor;
      if (delta < 0) {
        // Step counter can reset after reboot; continue counting from fresh baseline.
        delta = event.steps;
      }

      _stepsToday = max(0, storedSteps + delta);
      if (delta > 0) {
        _recordHourlyActivity(delta, DateTime.now());
        await _saveHourlyActivity(prefsInner, todayStamp);
      }
      _status = '24h tracking active';
      _ready = true;
      await prefsInner.setInt(_keyLastSensorSteps, event.steps);
      await prefsInner.setInt(_keyDailySteps, _stepsToday);
      await prefsInner.setString(_keyDailyDate, todayStamp);
      _weeklyHistory[todayStamp] = _stepsToday;
      await _saveWeekHistory(prefsInner);
      notifyListeners();
    }, onError: (error) {
      _status = 'Step sensor unavailable on this device.';
      _ready = true;
      notifyListeners();
    });
  }

  Future<void> requestPinWidget() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _serviceChannel.invokeMethod('requestPinWidget');
    } on PlatformException {
      _status = 'Widget pin request is not supported on this device.';
      notifyListeners();
    }
  }

  Future<void> refreshStepAlertSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final result = await _serviceChannel.invokeMapMethod<String, dynamic>('getStepAlertSettings');
      _stepAlertEnabled = result?['enabled'] == true;
      _stepAlertInterval = (result?['interval'] as int?) ?? 1000;
      _stepAlertQuietHoursEnabled = result?['quietEnabled'] == true;
      _stepAlertQuietStart = _timeFromMinutes((result?['quietStartMin'] as int?) ?? 1320);
      _stepAlertQuietEnd = _timeFromMinutes((result?['quietEndMin'] as int?) ?? 420);
      notifyListeners();
    } on PlatformException {
      _status = 'Could not load step alert settings.';
      notifyListeners();
    }
  }

  Future<void> setStepAlertEnabled(bool value) async {
    _stepAlertEnabled = value;
    notifyListeners();

    await _saveStepAlertPrefs();
    await _syncStepAlertSettings();
  }

  Future<void> refreshBackgroundStatus() async {
    if (!Platform.isAndroid) {
      return;
    }

    _statusChecksLoading = true;
    notifyListeners();

    try {
      final result = await _serviceChannel.invokeMapMethod<String, dynamic>('getBackgroundStatus');
      _ignoringBatteryOptimizations = result?['ignoringBatteryOptimizations'] == true;
      _backgroundRestricted = result?['backgroundRestricted'] == true;
      _autoStartSettingsAvailable = result?['autoStartSettingsAvailable'] == true;
      _serviceRunning = result?['serviceRunning'] == true;
      _autoStartVendor = (result?['autoStartVendor'] ?? 'android').toString();
    } on PlatformException {
      _status = 'Background health check unavailable.';
    } finally {
      _statusChecksLoading = false;
      notifyListeners();
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _serviceChannel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException {
      _status = 'Could not open battery optimization settings.';
      notifyListeners();
    }
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _serviceChannel.invokeMethod('requestIgnoreBatteryOptimization');
    } on PlatformException {
      _status = 'Could not request battery optimization exemption.';
      notifyListeners();
    }
  }

  Future<void> openAutoStartSettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _serviceChannel.invokeMethod('openAutoStartSettings');
    } on PlatformException {
      _status = 'Could not open auto-start settings.';
      notifyListeners();
    }
  }

  Future<void> openBackgroundRestrictionSettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _serviceChannel.invokeMethod('openBackgroundRestrictionSettings');
    } on PlatformException {
      _status = 'Could not open app background settings.';
      notifyListeners();
    }
  }

  Future<void> setStepAlertInterval(int value) async {
    _stepAlertInterval = value;
    notifyListeners();

    await _saveStepAlertPrefs();
    await _syncStepAlertSettings();
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    _stepAlertQuietHoursEnabled = value;
    notifyListeners();

    await _saveStepAlertPrefs();
    await _syncStepAlertSettings();
  }

  Future<void> setQuietHoursRange(TimeOfDay start, TimeOfDay end) async {
    _stepAlertQuietStart = start;
    _stepAlertQuietEnd = end;
    notifyListeners();

    await _saveStepAlertPrefs();
    await _syncStepAlertSettings();
  }

  Future<void> _saveStepAlertPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStepAlertEnabled, _stepAlertEnabled);
    await prefs.setInt(_keyStepAlertInterval, _stepAlertInterval);
    await prefs.setBool(_keyStepAlertQuietEnabled, _stepAlertQuietHoursEnabled);
    await prefs.setInt(_keyStepAlertQuietStart, _timeToMinutes(_stepAlertQuietStart));
    await prefs.setInt(_keyStepAlertQuietEnd, _timeToMinutes(_stepAlertQuietEnd));
  }

  Future<void> _syncStepAlertSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _serviceChannel.invokeMethod('setStepAlertSettings', {
        'enabled': _stepAlertEnabled,
        'interval': _stepAlertInterval,
        'quietEnabled': _stepAlertQuietHoursEnabled,
        'quietStartMin': _timeToMinutes(_stepAlertQuietStart),
        'quietEndMin': _timeToMinutes(_stepAlertQuietEnd),
      });
    } on PlatformException {
      _status = 'Could not save step alert settings.';
      notifyListeners();
    }
  }

  Future<void> openLockScreenSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _serviceChannel.invokeMethod('openLockScreenSettings');
    } on PlatformException {
      _status = 'Could not open lock screen settings.';
      notifyListeners();
    }
  }

  int _timeToMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  TimeOfDay _timeFromMinutes(int minuteOfDay) {
    final normalized = minuteOfDay % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  Future<void> setWidgetGuideSeen(bool value) async {
    _widgetGuideSeen = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWidgetGuideSeen, value);
    notifyListeners();
  }

  Future<void> setLockScreenWidgetEnabled(bool value) async {
    _lockScreenWidgetEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWidgetLockEnabled, value);
    notifyListeners();

    if (Platform.isAndroid) {
      try {
        await _serviceChannel.invokeMethod('refreshWidget');
      } on PlatformException {
        // Ignore refresh failures; widget can refresh on next sensor event.
      }
    }
  }

  void _attachAndroidStepStream() {
    if (!Platform.isAndroid || _stepEventsSubscription != null) {
      return;
    }

    _stepEventsSubscription = _stepEventChannel.receiveBroadcastStream().listen((event) async {
      if (event is! Map) {
        return;
      }

      final nextStepsRaw = event['steps'];
      if (nextStepsRaw is! int) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final today = _todayStamp();
      await _rolloverDayIfNeeded(
        prefs,
        today,
        persistedTodaySteps: prefs.getInt(_keyDailySteps) ?? _stepsToday,
      );

      final previousSteps = _stepsToday;
      final nextSteps = max(0, nextStepsRaw);
      if (nextSteps > previousSteps) {
        _recordHourlyActivity(nextSteps - previousSteps, DateTime.now());
        await _saveHourlyActivity(prefs, today);
      }

      _stepsToday = nextSteps;
      await prefs.setString(_keyDailyDate, today);
      await prefs.setInt(_keyDailySteps, _stepsToday);
      _weeklyHistory[today] = _stepsToday;
      await _saveWeekHistory(prefs);
      _ready = true;
      _status = '24h background tracking active';
      notifyListeners();
    }, onError: (_) {
      _status = 'Waiting for Android step service...';
      _ready = true;
      notifyListeners();
    });
  }

  Future<void> _startAndroidForegroundService() async {
    try {
      final started = await _serviceChannel.invokeMethod<bool>('startService') ?? false;
      if (started) {
        _status = '24h background tracking active';
      } else {
        _status = 'Background start blocked by system. Enable auto-start and battery unrestricted mode.';
      }
      notifyListeners();
    } on PlatformException {
      _status = 'Background service start failed. Open app to track live.';
      notifyListeners();
    }
  }

  Future<void> ensureBackgroundServiceRunning() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _startAndroidForegroundService();
    await _refreshAndroidSteps();
    await refreshBackgroundStatus();
  }

  Future<void> _refreshAndroidSteps() async {
    try {
      final result = await _serviceChannel.invokeMethod<int>('getTodaySteps');
      final prefs = await SharedPreferences.getInstance();
      final today = _todayStamp();

      await _rolloverDayIfNeeded(
        prefs,
        today,
        persistedTodaySteps: prefs.getInt(_keyDailySteps) ?? _stepsToday,
      );
      _ensureActivityDate(prefs, today);

      final nextSteps = max(0, result ?? 0);
      final previousSteps = _stepsToday;
      final wasReady = _ready;
      final previousStatus = _status;

      if (nextSteps > previousSteps) {
        _recordHourlyActivity(nextSteps - previousSteps, DateTime.now());
        await _saveHourlyActivity(prefs, today);
      } else if (nextSteps < previousSteps) {
        final savedDate = prefs.getString(_keyDailyDate);
        if (savedDate != today) {
          _hourlyActivity = List<int>.filled(24, 0);
          await _saveHourlyActivity(prefs, today);
        }
      }

      _stepsToday = nextSteps;
      await prefs.setString(_keyDailyDate, today);
      await prefs.setInt(_keyDailySteps, _stepsToday);
      _weeklyHistory[today] = _stepsToday;
      await _saveWeekHistory(prefs);
      _ready = true;
      _status = '24h background tracking active';
      if (nextSteps != previousSteps || !wasReady || previousStatus != _status) {
        notifyListeners();
      }
    } on PlatformException {
      _ready = true;
      _status = 'Waiting for Android step service...';
      notifyListeners();
    }
  }

  void _recordHourlyActivity(int delta, DateTime timestamp) {
    if (delta <= 0) {
      return;
    }
    final hour = timestamp.hour.clamp(0, 23);
    _hourlyActivity[hour] = _hourlyActivity[hour] + delta;
  }

  void _ensureActivityDate(SharedPreferences prefs, String today) {
    final activityDate = prefs.getString(_keyHourlyActivityDate);
    if (activityDate == today) {
      return;
    }
    _hourlyActivity = List<int>.filled(24, 0);
  }

  List<int> _readHourlyActivity(SharedPreferences prefs) {
    final raw = prefs.getString(_keyHourlyActivityData);
    if (raw == null || raw.isEmpty) {
      return List<int>.filled(24, 0);
    }

    final parsed = raw.split(',').map((e) => int.tryParse(e) ?? 0).toList();
    if (parsed.length < 24) {
      parsed.addAll(List<int>.filled(24 - parsed.length, 0));
    }
    return parsed.take(24).toList();
  }

  Future<void> _saveHourlyActivity(SharedPreferences prefs, String today) async {
    await prefs.setString(_keyHourlyActivityDate, today);
    await prefs.setString(_keyHourlyActivityData, _hourlyActivity.join(','));
  }

  Map<String, int> _readWeekHistory(SharedPreferences prefs) {
    final raw = prefs.getString(_keyWeekHistoryData);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }

    final result = <String, int>{};
    for (final pair in raw.split(';')) {
      if (pair.isEmpty || !pair.contains(':')) {
        continue;
      }
      final parts = pair.split(':');
      if (parts.length != 2) {
        continue;
      }
      final steps = int.tryParse(parts[1]) ?? 0;
      result[parts[0]] = max(0, steps);
    }
    return result;
  }

  Future<void> _saveWeekHistory(SharedPreferences prefs) async {
    _pruneWeekHistory();
    final encoded = _weeklyHistory.entries.map((e) => '${e.key}:${e.value}').join(';');
    await prefs.setString(_keyWeekHistoryData, encoded);
  }

  void _pruneWeekHistory() {
    final now = DateTime.now();
    final keep = <String>{
      for (int i = 0; i < 62; i++) _stampForDate(now.subtract(Duration(days: i))),
    };
    _weeklyHistory.removeWhere((key, _) => !keep.contains(key));
  }

  Future<void> _rolloverDayIfNeeded(
    SharedPreferences prefs,
    String today, {
    required int persistedTodaySteps,
  }) async {
    final savedDate = prefs.getString(_keyDailyDate);
    if (savedDate == null) {
      await prefs.setString(_keyDailyDate, today);
      return;
    }

    if (savedDate == today) {
      return;
    }

    _weeklyHistory[savedDate] = max(0, persistedTodaySteps);
    _pruneWeekHistory();
    await _saveWeekHistory(prefs);

    _stepsToday = 0;
    _hourlyActivity = List<int>.filled(24, 0);
    await prefs.setString(_keyDailyDate, today);
    await prefs.setInt(_keyDailySteps, 0);
    await _saveHourlyActivity(prefs, today);
  }

  Future<void> setGoal(int value) async {
    final clamped = value.clamp(5000, 25000);
    if (clamped == _goal) {
      return;
    }

    _goal = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGoal, _goal);
  }

  Future<bool> _requestPermission() async {
    final motion = await Permission.activityRecognition.request();
    if (Platform.isAndroid) {
      // Android 13+ requires notification permission for foreground service notification.
      await Permission.notification.request();
    }
    return motion.isGranted || motion.isLimited;
  }

  String _todayStamp() {
    return _stampForDate(DateTime.now());
  }

  String _stampForDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stepEventsSubscription?.cancel();
    _androidPoller?.cancel();
    super.dispose();
  }
}
