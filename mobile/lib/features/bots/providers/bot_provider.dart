import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/bot_service.dart';
import '../models/bot_model.dart';

final botServiceProvider = Provider<BotService>((ref) {
  final dio = ref.watch(dioProvider);
  return BotService(dio);
});

final botListProvider = FutureProvider.autoDispose<List<Bot>>((ref) async {
  final botService = ref.watch(botServiceProvider);
  return botService.getBots();
});

final botDetailProvider = FutureProvider.family.autoDispose<Bot, String>((
  ref,
  id,
) async {
  final botService = ref.watch(botServiceProvider);
  return botService.getBot(id);
});
