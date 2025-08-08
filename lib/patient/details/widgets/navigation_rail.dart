import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design_system/design_system_screen.dart' show DesignTokens;

class NavigationSection {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String emoji;

  NavigationSection({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.emoji,
  });
}

class PatientNavigationRail extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final int selectedIndex;
  final List<NavigationSection> sections;
  final Function(int) onSectionChanged;

  const PatientNavigationRail({
    Key? key,
    required this.patientData,
    required this.selectedIndex,
    required this.sections,
    required this.onSectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        boxShadow: [
          BoxShadow(
            color: DesignTokens.shadowDark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар пациента вверху
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                _buildCompactAvatar(patientData['photoUrl'], patientData: patientData),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        DesignTokens.textSecondary.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Навигационные элементы
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sections.length,
              separatorBuilder: (context, index) {
                // Добавляем разделители между группами секций
                if (index == 0 || index == 2 || index == 4) {
                  return Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          DesignTokens.textSecondary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              itemBuilder: (context, index) {
                final section = sections[index];
                final isSelected = selectedIndex == index;
                
                return _buildNavItem(
                  icon: isSelected ? section.activeIcon : section.icon,
                  label: section.label,
                  emoji: section.emoji,
                  isSelected: isSelected,
                  onTap: () => onSectionChanged(index),
                );
              },
            ),
          ),
          
          // Разделитель перед кнопкой назад
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  DesignTokens.textSecondary.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Кнопка выхода/назад внизу
          Container(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.textSecondary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                iconSize: 18,
                color: DesignTokens.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Назад',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Элемент навигации
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? DesignTokens.background 
                  : DesignTokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? DesignTokens.accentPrimary.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: DesignTokens.shadowDark.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: DesignTokens.shadowLight.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: DesignTokens.shadowDark.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Эмодзи или иконка
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: isSelected ? 26 : 22,
                  ),
                  child: Text(emoji),
                ),
                const SizedBox(height: 6),
                // Подпись
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected 
                        ? DesignTokens.accentPrimary 
                        : DesignTokens.textSecondary.withOpacity(0.8),
                    letterSpacing: isSelected ? 0.3 : 0,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Компактный аватар для боковой панели
  Widget _buildCompactAvatar(String? photoUrl, {Map<String, dynamic>? patientData}) {
    Color borderColor = DesignTokens.accentPrimary;
    if (patientData != null) {
      if (patientData['hotPatient'] == true) {
        borderColor = DesignTokens.accentDanger;
      } else if (patientData['secondStage'] == true) {
        borderColor = DesignTokens.accentSuccess;
      } else if (patientData['waitingList'] == true) {
        borderColor = DesignTokens.accentWarning;
      }
    }
    
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: DesignTokens.surface,
          child: photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Text('👤', style: TextStyle(fontSize: 24)),
                  ),
                  // Performance optimizations
                  memCacheHeight: 200,
                  memCacheWidth: 200,
                  fadeInDuration: const Duration(milliseconds: 200),
                )
              : const Center(
                  child: Text('👤', style: TextStyle(fontSize: 24)),
                ),
        ),
      ),
    );
  }
}