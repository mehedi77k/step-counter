part of 'package:step_counter_app/main.dart';

class _TopHeader extends StatelessWidget {
  const _TopHeader({this.compact = false, this.onSettingsTap});

  final bool compact;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoTextStyle = TextStyle(
      color: scheme.primary,
      fontWeight: FontWeight.w800,
      fontSize: compact ? 18 : 30,
    );

    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 16 : 22,
          backgroundColor: isDark ? const Color(0xFF2A3050) : const Color(0xFFE2E7FF),
          child: CircleAvatar(
            radius: compact ? 14 : 20,
            backgroundColor: isDark ? const Color(0xFF323A5C) : const Color(0xFFDEE4FF),
            child: Icon(
              Icons.person,
              color: scheme.primary,
              size: compact ? 16 : 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            if (compact) ...[
              Icon(Icons.bolt, color: scheme.primary, size: 14),
              const SizedBox(width: 6),
            ],
            Text('Step Counter', style: logoTextStyle),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSettingsTap,
          child: Icon(
            Icons.settings,
            color: isDark ? const Color(0xFFC0C5DD) : const Color(0xFF7A7A87),
            size: compact ? 20 : 30,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF2D3352) : const Color(0xFFE2DEFA)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x3A000000) : const Color(0x120E164E),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.unit,
    this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String value;
  final String unit;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconBg,
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFBFC4E7) : const Color(0xFF46426F),
                  letterSpacing: 2,
                  height: 1.25,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFFE7E9FF) : const Color(0xFF1F1C50),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFD4D8F7) : const Color(0xFF272453),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF2B3357) : const Color(0xFFE3E7FA))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? scheme.primary : (isDark ? const Color(0xFFA8AECD) : const Color(0xFF9A9AA8))),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: selected ? scheme.primary : (isDark ? const Color(0xFFA8AECD) : const Color(0xFF9A9AA8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  const _PillBtn({required this.title, required this.active, this.onTap});

  final String title;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3248E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF4A4775),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _DayStyle extends TextStyle {
  const _DayStyle({bool active = false})
      : super(
          fontSize: 16,
          color: active ? const Color(0xFF2040E0) : const Color(0xFF3E3B6C),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        );
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x228FA0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: Color(0xFFDCE2FF), fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: Icon(icon, color: const Color(0xFF3146E6)),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF63607F))),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 170;
        final labelSize = isNarrow ? 12.0 : 14.0;
        final valueSize = isNarrow ? 16.0 : 18.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Flexible(
                flex: 4,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: const Color(0xFF4A4674), fontSize: labelSize),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}
