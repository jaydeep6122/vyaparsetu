import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart' as el;
import 'package:url_launcher/url_launcher.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/components/appButton.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _launchStore() async {
    final Uri url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.vyaparsetu.app',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch store URL';
      }
    } catch (_) {
      // Fail-safe if store can't open
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final locale = el.EasyLocalization.of(context)?.currentLocale?.languageCode ?? 'en';
    String title = 'Update Required';
    String message =
        'A new version of Vyapar Setu is available with critical enhancements. Please update to continue using the application.';
    String buttonText = 'UPDATE NOW';

    if (locale == 'hi') {
      title = 'अपडेट आवश्यक है';
      message =
          'महत्वपूर्ण सुधारों के साथ व्यापार सेतु का एक नया संस्करण उपलब्ध है। कृपया एप्लिकेशन का उपयोग जारी रखने के लिए अपडेट करें।';
      buttonText = 'अभी अपडेट करें';
    } else if (locale == 'gu') {
      title = 'અપડેટ જરૂરી છે';
      message =
          'મહત્વપૂર્ણ સુધારાઓ સાથે વ્યાપાર સેતુનું નવું સંસ્કરણ ઉપલબ્ધ છે. કૃપા કરીને એપ્લિકેશનનો ઉપયોગ ચાલુ રાખવા માટે અપડેટ કરો.';
      buttonText = 'હમણાં અપડેટ કરો';
    }

    return WillPopScope(
      onWillPop: () async => false, // Prevents user from going back
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Beautiful Illustration or Icon Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.primaryDark : AppTheme.primary)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 60,
                      color: isDark ? AppTheme.accentDark : AppTheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                AppButton(
                  text: buttonText,
                  onPressed: _launchStore,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
