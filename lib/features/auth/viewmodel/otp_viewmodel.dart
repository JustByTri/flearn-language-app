import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/auth_repository.dart';



class OtpViewModel extends GetxController {
    final IAuthRepository _authRepository;

    OtpViewModel(this._authRepository);

    var isLoading = false.obs;

    Future<void> confirmEmail(String otp) async {
        try {
            isLoading.value = true;
            final response = await _authRepository.confirmEmail(otp);
            if (response.isSuccess) {
                print("Email confirmation successful");
            } else {
                print("Email confirmation failed - isSuccess: ${response.isSuccess}");
            }


        } catch (e) {
            print(" Confirm email exception: $e");
        } finally {
            isLoading.value = false;
        }
    }

    Future<void> resendOtp(String email) async {
        try {
            isLoading.value = true;
            await _authRepository.resendOtp(email);
            print("Resend OTP successful");
        } catch (e) {
            print("Resend OTP exception: $e");
            rethrow;
        } finally {
            isLoading.value = false;
        }
    }

}
