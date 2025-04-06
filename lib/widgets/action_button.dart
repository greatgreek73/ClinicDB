import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final bool useGradient;

  const ActionButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.useGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        gradient: useGradient ? AppTheme.primaryGradient : null,
        color: useGradient ? null : AppTheme.primaryColor,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.largeRadius),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppTheme.lightTextColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.lightTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

// Виджет анимированной кнопки действия с эффектом нажатия
class AnimatedActionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final bool useGradient;

  const AnimatedActionButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.useGradient = true,
  }) : super(key: key);

  @override
  _AnimatedActionButtonState createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ActionButton(
              title: widget.title,
              icon: widget.icon,
              onPressed: () {}, // Пустая функция, так как обрабатываем нажатие выше
              useGradient: widget.useGradient,
            ),
          );
        },
      ),
    );
  }
}
