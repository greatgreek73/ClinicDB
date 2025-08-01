import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesignTokens {
  // Colors
  static const background = Color(0xFFE0E5EC);
  static const surface = Color(0xFFE0E5EC);
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const textMuted = Color(0xFFA0AEC0);

  static const shadowLight = Color(0xFFFFFFFF);
  static const shadowDark = Color(0xFFA3B1C6);

  static const accentPrimary = Color(0xFF667EEA);
  static const accentSecondary = Color(0xFF764BA2);

  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFEF4444);

  // Дополнительные акцентные цвета под вимоги:
  static const accentSuccess = success;   // зелёный
  static const accentWarning = warning;   // оранжевый/жёлтый
  static const accentDanger  = error;     // красный

  // Typography
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary);
  static const h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary);
  static const h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary);
  static const h4 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary);

  static const body = TextStyle(fontSize: 16, height: 1.6, color: textPrimary);
  static const small = TextStyle(fontSize: 12, color: textMuted);

  // Spacing
  static const s5 = 5.0;
  static const s10 = 10.0;
  static const s15 = 15.0;
  static const s20 = 20.0;
  static const s30 = 30.0;

  static const cornerRadiusCard = 20.0;
  static const cornerRadiusButton = 25.0;

  // Shadows for neumorphism
  static List<BoxShadow> outerShadows({
    double blur = 15,
    double offset = 8,
  }) =>
      [
        BoxShadow(
          color: shadowDark,
          offset: Offset(offset, offset),
          blurRadius: blur,
        ),
        BoxShadow(
          color: shadowLight,
          offset: Offset(-offset, -offset),
          blurRadius: blur,
        ),
      ];

  static List<BoxShadow> innerShadows({
    double blur = 10,
    double offset = 5,
  }) =>
      [
        BoxShadow(
          color: shadowDark,
          offset: Offset(offset, offset),
          blurRadius: blur,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowLight,
          offset: Offset(-offset, -offset),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];
}

// Core components

class NeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool inset;

  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.inset = false,
  });

  // Удобный фабричный конструктор для «вдавленного» состояния
  const NeoCard.inset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  }) : inset = true;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: DesignTokens.surface,
      borderRadius: BorderRadius.circular(DesignTokens.cornerRadiusCard),
      boxShadow: inset ? DesignTokens.innerShadows() : DesignTokens.outerShadows(),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }
}

class NeoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool pressed;

  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = BoxDecoration(
      color: primary ? null : DesignTokens.surface,
      gradient: primary
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [DesignTokens.accentPrimary, Color(0xFF4F46E5)],
            )
          : null,
      borderRadius: BorderRadius.circular(DesignTokens.cornerRadiusButton),
      boxShadow: pressed
          ? DesignTokens.innerShadows(blur: 10, offset: 5)
          : DesignTokens.outerShadows(blur: 10, offset: 5),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.identity()..scale(pressed ? 0.98 : 1.0),
      decoration: baseDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.cornerRadiusButton),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : const Color(0xFF4A5568),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeoAvatar extends StatelessWidget {
  final double size;
  final bool online;
  final Widget? child;

  const NeoAvatar({
    super.key,
    this.size = 80,
    this.online = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: DesignTokens.surface,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: DesignTokens.outerShadows(blur: 15, offset: 8),
          ),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 35),
              child: child ?? const Text('👤'),
            ),
          ),
        ),
        if (online)
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: DesignTokens.success,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.surface,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class NeoTabBar extends StatefulWidget {
  final List<String> tabs;
  final int initialIndex;
  final ValueChanged<int>? onChanged;

  const NeoTabBar({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onChanged,
  });

  @override
  State<NeoTabBar> createState() => _NeoTabBarState();
}

class _NeoTabBarState extends State<NeoTabBar> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s10),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: DesignTokens.outerShadows(blur: 10, offset: 5),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (i) {
          final active = _index == i;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: DesignTokens.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active
                      ? DesignTokens.innerShadows(blur: 10, offset: 5)
                      : DesignTokens.outerShadows(blur: 10, offset: 5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() => _index = i);
                    widget.onChanged?.call(i);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        widget.tabs[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: active ? DesignTokens.accentPrimary : const Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Showcase screen

class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Базовый контейнер с мягким фоном и безопасной областью
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: DesignTokens.background,
        elevation: 0,
        title: const Text('Design System — Neumorphism', style: TextStyle(color: DesignTokens.textPrimary)),
        iconTheme: const IconThemeData(color: DesignTokens.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headings and texts
              Text('Типографика', style: DesignTokens.h1),
              const SizedBox(height: DesignTokens.s10),
              Text('Заголовок H2', style: DesignTokens.h2),
              const SizedBox(height: DesignTokens.s5),
              Text('Заголовок H3', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s5),
              Text('Заголовок H4', style: DesignTokens.h4),
              const SizedBox(height: DesignTokens.s10),
              Text(
                'Базовый текст. Мягкая палитра, хороший контраст и комфортная читаемость на неоморфном фоне.',
                style: DesignTokens.body,
              ),
              const SizedBox(height: DesignTokens.s5),
              Text('Muted подпись/подзаголовок', style: DesignTokens.small),
              const SizedBox(height: DesignTokens.s20),

              // Cards
              Text('Карточки', style: DesignTokens.h2),
              const SizedBox(height: DesignTokens.s10),
              Row(
                children: const [
                  Expanded(
                    child: NeoCard(
                      child: Text('Обычная неоморфная карточка', style: DesignTokens.body),
                    ),
                  ),
                  SizedBox(width: DesignTokens.s15),
                  Expanded(
                    child: NeoCard(
                      inset: true,
                      child: Text('Вдавленная карточка (inset)', style: DesignTokens.body),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s20),

              // Buttons
              Text('Кнопки', style: DesignTokens.h2),
              const SizedBox(height: DesignTokens.s10),
              Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      label: 'Обычная',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s15),
                  Expanded(
                    child: NeoButton(
                      label: 'Нажатая',
                      pressed: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s10),
              Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      label: 'Акцентная',
                      primary: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s15),
                  Expanded(
                    child: NeoButton(
                      label: 'Акцентная (нажатая)',
                      primary: true,
                      pressed: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s20),

              // Avatar
              Text('Аватар', style: DesignTokens.h2),
              const SizedBox(height: DesignTokens.s10),
              Row(
                children: const [
                  NeoAvatar(),
                  SizedBox(width: DesignTokens.s20),
                  NeoAvatar(online: false),
                ],
              ),
              const SizedBox(height: DesignTokens.s20),

              // Tabs
              Text('Табы', style: DesignTokens.h2),
              const SizedBox(height: DesignTokens.s10),
              NeoTabBar(
                tabs: const ['Главная', 'Услуги', 'История'],
                onChanged: (i) {},
              ),
              const SizedBox(height: DesignTokens.s30),

              // Quick actions card demo (2x2)
              Text('Быстрые действия', style: DesignTokens.h2),
              const SizedBox(height: DesignTokens.s10),
              NeoCard(
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: DesignTokens.s10,
                    crossAxisSpacing: DesignTokens.s10,
                    childAspectRatio: 3,
                  ),
                  children: const [
                    _QuickAction(title: 'Запись'),
                    _QuickAction(title: 'Пациенты'),
                    _QuickAction(title: 'Оплаты'),
                    _QuickAction(title: 'Отчёты'),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.s30),

              Center(
                child: NeoButton(
                  label: 'Назад',
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  const _QuickAction({required this.title});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Center(
        child: Text(
          title,
          style: DesignTokens.h4.copyWith(color: DesignTokens.textSecondary),
        ),
      ),
    );
  }
}
