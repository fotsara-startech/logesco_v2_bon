import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/language_controller.dart';

/// Widget de sélection de langue
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanguageController());

    return Obx(() {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.language, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'language_app'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Option Français
              _buildLanguageOption(
                context: context,
                controller: controller,
                languageCode: 'fr',
                flag: '🇫🇷',
                name: 'Français',
                isSelected: controller.currentLanguage.value == 'fr',
              ),

              const SizedBox(height: 12),

              // Option English
              _buildLanguageOption(
                context: context,
                controller: controller,
                languageCode: 'en',
                flag: '🇬🇧',
                name: 'English',
                isSelected: controller.currentLanguage.value == 'en',
              ),

              const SizedBox(height: 12),

              // Option Español
              _buildLanguageOption(
                context: context,
                controller: controller,
                languageCode: 'es',
                flag: '🇪🇸',
                name: 'Español',
                isSelected: controller.currentLanguage.value == 'es',
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required LanguageController controller,
    required String languageCode,
    required String flag,
    required String name,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => controller.changeLanguage(languageCode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
