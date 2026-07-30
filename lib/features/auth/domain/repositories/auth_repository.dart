import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/firebase_login_request.dart';
import '../../../../core/data/models/requests/go_phone_otp_request.dart';
import '../../../../core/data/models/requests/go_phone_verify_otp_request.dart';
import '../../../../core/data/models/requests/set_name_request.dart';
import '../../../../core/data/models/responses/onboarding_banners_response.dart';
import '../../../../core/data/models/responses/set_name_response.dart';
import '../../../../core/data/models/responses/firebase_login_response.dart';
import '../../../../core/data/models/responses/phone_verify_otp_response.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/errors/failures.dart';
import '../entities/social_auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, FirebaseLoginResponseModel?>> firebaseLogin({
    required FirebaseLoginRequest request,
  });

  Future<Either<Failure, FirebaseLoginResponseModel?>> exchangeFirebaseSession({
    String? name,
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, SendOtpResponse?>> sendPhoneOtp({
    required GoPhoneOtpRequest request,
  });

  Future<Either<Failure, SendOtpResponse?>> resendPhoneOtp({
    required GoPhoneOtpRequest request,
  });

  Future<Either<Failure, PhoneVerifyOtpResponseModel?>> verifyPhoneOtp({
    required GoPhoneVerifyOtpRequest request,
  });

  Future<Either<Failure, SetNameResponseModel?>> setName({
    required SetNameRequest request,
  });

  Future<Either<Failure, String>> refreshToken();

  Future<Either<Failure, bool>> logout();

  Future<Either<Failure, List<OnboardingBannerItem>>> getOnboardingBanners();

  Future<Either<Failure, SocialAuthUser>> signInWithApple();

  Future<Either<Failure, SocialAuthUser>> signInWithFacebook();

  Future<Either<Failure, SocialAuthUser>> signInWithGoogle();

  Future<Either<Failure, void>> signOutFirebase();
}
