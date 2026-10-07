import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/utils/open_link.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/about_us.dart';
import '../../data/social_link.dart';
import '../providers/company_info_providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('About us')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(socialLinksProvider)
            ..invalidate(aboutUsProvider);
          await ref.read(aboutUsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const _AboutSection(),
            const _SocialLinksSection(),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Contact us'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/contact'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Frequently asked questions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/faq'),
            ),
            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('Own a restaurant?'),
              subtitle: const Text('Add it to HARA'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/submit-restaurant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutUsProvider);

    return aboutAsync.when(
      data: (about) => _AboutContent(about: about),
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorView(
          message: apiErrorMessage(error),
          onRetry: () => ref.invalidate(aboutUsProvider),
        ),
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent({required this.about});

  final AboutUs about;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (about.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'More about us is coming soon.',
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final logoUri = about.logoUri;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (logoUri != null) ...[
            SizedBox(
              height: 96,
              child: Image.network(
                logoUri.toString(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (about.companyName.trim().isNotEmpty)
            Text(about.companyName, style: textTheme.headlineSmall, textAlign: TextAlign.center),
          if (about.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(about.description, style: textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}

class _SocialLinksSection extends ConsumerWidget {
  const _SocialLinksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Social links are a bonus on this screen, so while they load, or if they fail, show nothing
    // rather than blocking or cluttering the rest of the page. A link that can't be opened (a typo
    // or a non-web address typed by the admin) would be a dead row, so it is left out too.
    final links = (ref.watch(socialLinksProvider).valueOrNull ?? const <SocialLink>[])
        .where((link) => link.uri != null)
        .toList();
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text('Follow us', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        for (final link in links)
          ListTile(
            leading: Icon(_iconFor(link.platform)),
            title: Text(link.platform.label),
            subtitle: Text(link.url),
            onTap: () => openLink(context, link.uri!),
          ),
      ],
    );
  }

  IconData _iconFor(SocialPlatform platform) => switch (platform) {
        SocialPlatform.facebook => Icons.facebook,
        SocialPlatform.instagram => Icons.camera_alt_outlined,
        SocialPlatform.youTube => Icons.play_circle_outline,
        SocialPlatform.tikTok => Icons.music_note_outlined,
        SocialPlatform.linkedIn => Icons.business_center_outlined,
        SocialPlatform.x => Icons.alternate_email,
        SocialPlatform.website => Icons.public,
        SocialPlatform.other => Icons.link,
      };
}
