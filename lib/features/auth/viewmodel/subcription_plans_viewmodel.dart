import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/auth_repository.dart';

class SubscriptionViewModel extends GetxController {
  final IAuthRepository _authRepository;
  final storage = GetStorage();
  var isLoading = false.obs;

  SubscriptionViewModel(this._authRepository);

  Future<Map<String, dynamic>> purchasePlan(String planName) async {
    try {
      isLoading.value = true;
      final response = await _authRepository.purchaseSubscription(planName);
      if (response != null && response['success'] == true && response['data'] != null) {

        await storage.write('lastPurchase', {
          'plan': planName,
          'transactionId': response['data']['transactionId'],
          'paymentUrl': response['data']['paymentUrl'],
          'amount': response['data']['amount'],
        });
        return {'success': true, 'data': response['data']};
      } else {
        return {'success': false, 'message': response?['message'] ?? 'Lỗi không xác định'};
      }
    } catch (e) {
      debugPrint("Purchase exception: $e");
      return {'success': false, 'message': e.toString()};
    } finally {
      isLoading.value = false;
    }
  }


}