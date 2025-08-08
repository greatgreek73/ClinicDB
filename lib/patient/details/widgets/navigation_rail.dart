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
          // Аватар пациента вверху (вернули на место)
          Container(
            padding: const EdgeInsets.all(12),
            child: _buildCompactAvatar(patientData['photoUrl'], patientData: patientData),
          ),
          
          const Divider(height: 1),
          
          // Навигационные элементы
          Expanded(
            child: ListView.builder(
              // Performance optimizations
              itemExtent: 56.0, // Fixed height for navigation items
              cacheExtent: 200.0, // Cache content outside visible area
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sections.length,
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
          
          // Кнопка выхода/назад внизу
          Container(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                iconSize: 20,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? DesignTokens.background : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? DesignTokens.innerShadows(blur: 8, offset: 4)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Эмодзи или иконка
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 24 : 20,
                  ),
                ),
                const SizedBox(height: 4),
                // Подпись
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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