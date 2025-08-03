import 'package:flutter/material.dart';
import 'design_system_screen.dart' show DesignTokens, NeoCard;

/// Расширенные компоненты для карточной системы страницы пациента
/// 
/// Этот файл содержит специализированные виджеты, которые используются
/// в новой карточной системе организации информации о пациентах.

/// Карточка с заголовком и иконкой для единообразного оформления секций
class CardSection extends StatelessWidget {
  final String title;
  final String icon;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  const CardSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок секции
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: DesignTokens.h2),
                ),
                if (actions != null) ...actions!,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения ключ-значение информации в неоморфном стиле
class InfoPair extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;
  final EdgeInsetsGeometry? padding;

  const InfoPair({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard.inset(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: DesignTokens.body.copyWith(
                  color: valueColor ?? DesignTokens.textPrimary,
                  fontWeight: valueFontWeight ?? FontWeight.w600,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения метрики с акцентным цветом
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard.inset(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: DesignTokens.h2.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: DesignTokens.small.copyWith(
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: DesignTokens.small.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для статусных бэйджей
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isActive;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : DesignTokens.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : DesignTokens.shadowDark.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: DesignTokens.small.copyWith(
          color: isActive ? color : DesignTokens.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Виджет для переключателей в неоморфном стиле
class NeoToggle extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool?) onChanged;
  final String? subtitle;

  const NeoToggle({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: DesignTokens.small.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: DesignTokens.accentPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет для пустых состояний
class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard.inset(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: DesignTokens.small.copyWith(
                  color: DesignTokens.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет для элементов истории/временной линии
class TimelineItem extends StatelessWidget {
  final String date;
  final String title;
  final String? subtitle;
  final String? details;
  final Color? accentColor;
  final VoidCallback? onTap;

  const TimelineItem({
    super.key,
    required this.date,
    required this.title,
    this.subtitle,
    this.details,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeoCard.inset(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Индикатор
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor ?? DesignTokens.accentPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Основная информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: DesignTokens.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            date,
                            style: DesignTokens.small.copyWith(
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                      if (details != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          details!,
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет для загрузки с неоморфным оформлением
class NeoLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const NeoLoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size ?? 32,
              height: size ?? 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DesignTokens.accentPrimary,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: DesignTokens.body.copyWith(
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Расширенная сетка для информации
class InfoGrid extends StatelessWidget {
  final List<InfoGridItem> items;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const InfoGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
    this.childAspectRatio = 3.0,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InfoPair(
          label: item.label,
          value: item.value,
          valueColor: item.valueColor,
          valueFontWeight: item.valueFontWeight,
        );
      },
    );
  }
}

/// Элемент сетки информации
class InfoGridItem {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;

  const InfoGridItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
  });
}

/// Виджет для группировки статусов
class StatusGroup extends StatelessWidget {
  final List<StatusGroupItem> items;
  final WrapAlignment alignment;

  const StatusGroup({
    super.key,
    required this.items,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: alignment,
      children: items.map((item) {
        return StatusBadge(
          text: item.text,
          color: item.color,
          isActive: item.isActive,
        );
      }).toList(),
    );
  }
}

/// Элемент группы статусов
class StatusGroupItem {
  final String text;
  final Color color;
  final bool isActive;

  const StatusGroupItem({
    required this.text,
    required this.color,
    this.isActive = true,
  });
}
