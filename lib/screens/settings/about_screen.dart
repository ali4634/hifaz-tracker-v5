import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/glass_card.dart';

/// About screen: app icon, features and developer contact info.
/// Ported from v4's AboutScreen and restyled for the glass UI.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('about'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gradA, AppColors.gradB],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.t('appName'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primarySoft,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${l10n.t('tagline')} · v${AppConstants.appVersion}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.t('aboutUs'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('aboutUsContent'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('aboutUsTagline'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primarySoft,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.t('appFeatures'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.people_rounded,
            title: l10n.t('featureStudentMgmt'),
            desc: l10n.t('featureStudentMgmtDesc'),
            color: AppColors.info,
          ),
          const SizedBox(height: 8),
          _FeatureTile(
            icon: Icons.auto_stories_rounded,
            title: l10n.t('featureLessonTracking'),
            desc: l10n.t('featureLessonTrackingDesc'),
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _FeatureTile(
            icon: Icons.donut_large_rounded,
            title: l10n.t('featureAnalytics'),
            desc: l10n.t('featureAnalyticsDesc'),
            color: AppColors.warning,
          ),
          const SizedBox(height: 8),
          _FeatureTile(
            icon: Icons.picture_as_pdf_rounded,
            title: l10n.t('featurePdfReports'),
            desc: l10n.t('featurePdfReportsDesc'),
            color: AppColors.danger,
          ),
          const SizedBox(height: 8),
          _FeatureTile(
            icon: Icons.chat_rounded,
            title: l10n.t('featureWhatsApp'),
            desc: l10n.t('featureWhatsAppDesc'),
            color: AppColors.indigo,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.t('developerInfo'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.gradA, AppColors.gradB],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.t('developerName'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.t('developerRole'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _ContactTile(
                  icon: Icons.chat_rounded,
                  color: AppColors.primary,
                  label: 'WhatsApp',
                  value: '+92-3149663093',
                  onTap: () =>
                      _launchUrl(context, 'https://wa.me/923149663093'),
                ),
                const SizedBox(height: 10),
                _ContactTile(
                  icon: Icons.email_rounded,
                  color: AppColors.info,
                  label: 'Email',
                  value: 'muhammadali46@gmail.com',
                  onTap: () => _launchUrl(
                    context,
                    'mailto:muhammadali46@gmail.com?subject=Hifaz Tracker Support',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.t('donationTitle'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              children: [
                Icon(
                  Icons.volunteer_activism_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('donationMessage'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _DonationDetail(
                  label: l10n.t('donationAccountLabel'),
                  value: 'Amir Rehman',
                ),
                const SizedBox(height: 8),
                _DonationDetail(
                  label: l10n.t('donationAccountNumber'),
                  value: '03137578574',
                ),
                const SizedBox(height: 8),
                _DonationDetail(
                  label: l10n.t('donationBankName'),
                  value: 'JazzCash',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.t('donationNote'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(context, 'https://wa.me/923149663093'),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: Text(l10n.t('supportViaWhatsApp')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              l10n.t('madeWithLove'),
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              l10n.t('rightsReserved'),
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignore — deep links may be unavailable on desktop platforms.
    }
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationDetail extends StatelessWidget {
  final String label;
  final String value;

  const _DonationDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
