import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/faq_item.dart';
import '../../data/faq_repository.dart';

final faqItemsProvider = FutureProvider.autoDispose<List<FaqItem>>(
  (ref) => ref.watch(faqRepositoryProvider).getFaqItems(),
);
