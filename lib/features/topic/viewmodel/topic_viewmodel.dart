import 'package:get/get.dart';

import '../data/repository.dart';
import '../model/topic.dart';



class TopicViewModel extends GetxController {
  final IRepository _authRepository;
  var isLoadingTopics = false.obs;
  var topics = <TopicModel>[].obs;

  TopicViewModel(this._authRepository);

  Future<void> fetchTopics() async {
    try {
      isLoadingTopics.value = true;
      final list = await _authRepository.getTopic();
      topics.assignAll(list);
    } catch (e) {
      print('fetchTopics error: $e');
    } finally {
      isLoadingTopics.value = false;
    }
  }
}