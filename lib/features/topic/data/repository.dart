import '../model/topic.dart';

abstract class IRepository{
  Future<List<TopicModel>> getTopic();
}