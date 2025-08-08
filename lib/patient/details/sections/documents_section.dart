import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;

class DocumentsSection extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final int selectedIndex;

  const DocumentsSection({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _DocumentsSectionState createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> with AutomaticKeepAliveClientMixin<DocumentsSection> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Only build heavy image widgets when this section is visible (selectedIndex == 4)
    final isVisible = widget.selectedIndex == 4;
    if (!isVisible) {
      return Container(
        key: ValueKey<int>(4),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Container(
      key: ValueKey<int>(4),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Основное фото
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Главное фото пациента
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👤', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text('Фото пациента', style: DesignTokens.h3),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildMainPhoto(widget.patientData['photoUrl']),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Дополнительные фото
              Expanded(
                child: NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('📸', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Text('Дополнительные фото', style: DesignTokens.h3),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildPhotosGrid(widget.patientData, context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainPhoto(String? photoUrl) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.shadowDark.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: photoUrl != null
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: DesignTokens.background,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: DesignTokens.background,
                  child: const Center(
                    child: Text('👤', style: TextStyle(fontSize: 64)),
                  ),
                ),
                // Performance optimizations
                memCacheHeight: 400,
                memCacheWidth: 400,
                fadeInDuration: const Duration(milliseconds: 200),
              )
            : Container(
                color: DesignTokens.background,
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 64)),
                ),
              ),
      ),
    );
  }
  
  Widget _buildPhotosGrid(Map<String, dynamic> patientData, BuildContext context) {
    final List<dynamic> additionalPhotos = patientData['additionalPhotos'] ?? [];

    if (additionalPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет дополнительных фотографий',
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: additionalPhotos.length,
      itemBuilder: (context, index) {
        final photo = additionalPhotos[index];
        return InkWell(
          onTap: () => _showImageDialog(context, photo),
          child: NeoCard.inset(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: photo['url'],
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: DesignTokens.textMuted,
                  ),
                ),
                // Performance optimizations for grid view
                memCacheHeight: 300,
                memCacheWidth: 300,
                fadeInDuration: const Duration(milliseconds: 150),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: DesignTokens.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: CachedNetworkImage(
                      imageUrl: photo['url'],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                      // No memory cache restrictions for full view
                      fadeInDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                ),
                if (photo['description'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    photo['description'],
                    style: DesignTokens.body,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  DateFormat('dd.MM.yyyy').format((photo['dateAdded'] as Timestamp).toDate()),
                  style: DesignTokens.small.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                NeoButton(
                  label: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}