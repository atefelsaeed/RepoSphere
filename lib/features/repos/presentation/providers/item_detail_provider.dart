import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/git_provider_factory.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/item_detail_entity.dart';

/// Detail (description, diff, comments) of an inbox item, loaded on demand
/// from the account that owns it.
final itemDetailProvider =
    FutureProvider.autoDispose.family<ItemDetail, InboxItem>((ref, item) async {
  final provider = ref.watch(providerForConnectionProvider(item.connectionId));
  if (provider == null) {
    throw StateError('That account is no longer connected.');
  }
  return provider.getItemDetail(item);
});
