import 'dart:io';

import 'package:flearn_app/features/auth/model/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../data/auth_repository.dart';
import '../model/course_purchase_detail.dart';
import '../model/course_purchase_history.dart';
import '../model/purchase_history.dart';
import '../model/subcription_purchase_history.dart';

class UserViewModel extends GetxController {
  final IAuthRepository _authRepository;
  UserViewModel(this._authRepository);
  var user = Rxn<User>();
  var isLoading = false.obs;
  var errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      isLoading.value = true;
      final response = await _authRepository.fetchProfile();
      // Debug logs
      debugPrint('fetchUserInfo - response.isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}, message: ${response.message}');
      debugPrint('fetchUserInfo - response.result: ${response.result}');
      if(response.isSuccess == true && response.result != null) {
        user.value = response.result;
      } else {
        errorMessage.value = response.message ?? 'Failed to fetch user info';
      }
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('fetchUserInfo error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(String fullName, String userName, File? avatar) async {
    try {
      isLoading.value = true;
      final response = await _authRepository.updateProfile(
        fullName: fullName,
        userName: userName,
        avatar: avatar,
      );
      if (response.isSuccess == true) {
        await fetchUserInfo(); // Refresh user info
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      isLoading.value = true;
      final response = await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      if (response.isSuccess == true) {
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to change password';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  var isLoadingPurchases = false.obs;
  var purchaseHistory = <Purchase>[].obs;
  var purchaseMeta = Rxn<PurchaseMeta>();

  Future<void> fetchPurchaseHistory({
    int page = 1,
    int pageSize = 10,
    String sortBy = 'newest',
  }) async {
    try {
      isLoadingPurchases.value = true;
      final resp = await _authRepository.getPurchaseHistory(
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
      );
      final items = (resp?['data'] as List<dynamic>? ?? [])
          .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
          .toList();
      purchaseHistory.assignAll(items);
      purchaseMeta.value = PurchaseMeta.fromJson((resp?['meta'] ?? {}) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('fetchPurchaseHistory error: $e');
      purchaseHistory.clear();
      purchaseMeta.value = null;
    } finally {
      isLoadingPurchases.value = false;
    }
  }


  var refundRequests = <Map<String, dynamic>>[].obs;
  var isLoadingRefundRequests = false.obs;

  Future<void> fetchRefundRequests() async {
    isLoadingRefundRequests.value = true;
    try {
      final list = await _authRepository.fetchRefundRequests();
      refundRequests.assignAll(list);
    } catch (e) {
      refundRequests.clear();
    } finally {
      isLoadingRefundRequests.value = false;
    }
  }

  var isLoadingCoursePurchases = false.obs;
  var coursePurchases = <CoursePurchase>[].obs;
  var coursePurchaseMeta = Rxn<CoursePurchaseMeta>();

  Future<void> fetchCoursePurchaseHistory({
    int page = 1,
    int pageSize = 10,
    String sortBy = 'newest',
  }) async {
    try {
      isLoadingCoursePurchases.value = true;
      final resp = await _authRepository.getCoursePurchaseHistory(
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
      );
      final items = (resp?['data'] as List<dynamic>? ?? [])
          .map((e) => CoursePurchase.fromJson(e as Map<String, dynamic>))
          .toList();
      coursePurchases.assignAll(items);
      coursePurchaseMeta.value = CoursePurchaseMeta.fromJson(resp?['meta'] ?? {});
    } catch (e) {
      debugPrint('fetchCoursePurchaseHistory error: $e');
      coursePurchases.clear();
      coursePurchaseMeta.value = null;
    } finally {
      isLoadingCoursePurchases.value = false;
    }
  }

  var isLoadingSubscriptionPurchases = false.obs;
  var subscriptionPurchases = <SubscriptionPurchase>[].obs;
  var subscriptionPurchaseMeta = Rxn<SubscriptionPurchaseMeta>();

  Future<void> fetchSubscriptionPurchaseHistory({
    int page = 1,
    int pageSize = 10,
    String sortBy = 'newest',
  }) async {
    try {
      isLoadingSubscriptionPurchases.value = true;
      final resp = await _authRepository.getSubscriptionPurchaseHistory(
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
      );
      final items = (resp?['data'] as List<dynamic>? ?? [])
          .map((e) => SubscriptionPurchase.fromJson(e as Map<String, dynamic>))
          .toList();
      subscriptionPurchases.assignAll(items);
      subscriptionPurchaseMeta.value = SubscriptionPurchaseMeta.fromJson(resp?['meta'] ?? {});
    } catch (e) {
      debugPrint('fetchSubscriptionPurchaseHistory error: $e');
      subscriptionPurchases.clear();
      subscriptionPurchaseMeta.value = null;
    } finally {
      isLoadingSubscriptionPurchases.value = false;
    }
  }


  var isLoadingCoursePurchaseDetail = false.obs;
  var coursePurchaseDetail = Rxn<CoursePurchaseDetail>();

  Future<void> fetchCoursePurchaseDetail(String purchaseId) async {
    try {
      isLoadingCoursePurchaseDetail.value = true;
      final resp = await _authRepository.getCoursePurchaseDetail(purchaseId);
      coursePurchaseDetail.value = CoursePurchaseDetail.fromJson(resp?['data'] ?? {});
    } catch (e) {
      debugPrint('fetchCoursePurchaseDetail error: $e');
      coursePurchaseDetail.value = null;
    } finally {
      isLoadingCoursePurchaseDetail.value = false;
    }
  }

}
