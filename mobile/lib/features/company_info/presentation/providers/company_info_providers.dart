import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/about_us.dart';
import '../../data/company_info_repository.dart';
import '../../data/contact_info.dart';
import '../../data/social_link.dart';

final aboutUsProvider = FutureProvider.autoDispose<AboutUs>(
  (ref) => ref.watch(companyInfoRepositoryProvider).getAboutUs(),
);

final contactsProvider = FutureProvider.autoDispose<List<ContactInfo>>(
  (ref) => ref.watch(companyInfoRepositoryProvider).getContacts(),
);

final socialLinksProvider = FutureProvider.autoDispose<List<SocialLink>>(
  (ref) => ref.watch(companyInfoRepositoryProvider).getSocialLinks(),
);
