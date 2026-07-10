import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/data/models/requests/firebase_login_request.dart';
import '../../../../core/data/models/requests/go_phone_otp_request.dart';
import '../../../../core/data/models/requests/go_phone_verify_otp_request.dart';
import '../../../../core/data/models/requests/save_user_additional_details_request.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/data/models/responses/onboarding_banners_response.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/apple_sign_in_service.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../../../core/services/facebook_sign_in_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/utils/apple_sign_in_debug_log.dart';
import '../../../../core/utils/apple_sign_in_nonce.dart';
import '../../domain/entities/social_auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/apple_auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../models/social_auth_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.appleSignInService,
    required this.facebookSignInService,
    required this.googleSignInService,
    required this.firebaseAuthDataSource,
    required this.appleAuthLocalDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AppleSignInService appleSignInService;
  final FacebookSignInService facebookSignInService;
  final GoogleSignInService googleSignInService;
  final FirebaseAuthDataSource firebaseAuthDataSource;
  final AppleAuthLocalDataSource appleAuthLocalDataSource;

  @override
  Future<Either<Failure, VerifyOtpResponseModel?>> firebaseLogin({
    required FirebaseLoginRequest request,
  }) async {
    try {
      final result = await remoteDataSource.firebaseLogin(request: request);
      if (result == null) {
        return const Left(
          ServerFailure('Sign-in failed. Please try again.'),
        );
      }
      return Right(result);
    } on DioException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ErrorMapper.mapDioExceptionToFailure(e));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VerifyOtpResponseModel?>> exchangeFirebaseSession({
    String? name,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final idToken = await firebaseAuthDataSource.getIdToken();
      return firebaseLogin(
        request: FirebaseLoginRequest(
          idToken: idToken,
          name: name,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapFirebaseAuthException(e));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return const Left(
        ServerFailure('Sign-in failed. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, SendOtpResponseModel?>> sendPhoneOtp({
    required GoPhoneOtpRequest request,
  }) async {
    try {
      final result = await remoteDataSource.sendPhoneOtp(request: request);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SendOtpResponseModel?>> resendPhoneOtp({
    required GoPhoneOtpRequest request,
  }) async {
    try {
      final result = await remoteDataSource.resendPhoneOtp(request: request);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VerifyOtpResponseModel?>> verifyPhoneOtp({
    required GoPhoneVerifyOtpRequest request,
  }) async {
    try {
      final result = await remoteDataSource.verifyPhoneOtp(request: request);
      if (result == null) {
        return const Left(
          ServerFailure('Phone verification failed. Please try again.'),
        );
      }
      return Right(result);
    } on DioException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ErrorMapper.mapDioExceptionToFailure(e));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> saveUserAdditionalDetails({
    required SaveUserAdditionalDetailsRequest request,
  }) async {
    try {
      final result = await remoteDataSource.saveUserAdditionalDetails(
        request: request,
      );
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final token = await remoteDataSource.refreshToken();
      return Right(token);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await remoteDataSource.logout();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OnboardingBannerItem>>>
  getOnboardingBanners() async {
    try {
      final list = await remoteDataSource.getOnboardingBanners();
      return Right(list);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SocialAuthUser>> signInWithApple() async {
    try {
      appleSignInDebugLog('repository_sign_in_started');
      final rawNonce = generateAppleSignInNonce();
      final hashedNonce = sha256ofString(rawNonce);

      final appleCredential = await appleSignInService.getCredential(
        nonce: hashedNonce,
      );

      final userIdentifier = appleCredential.userIdentifier;
      if (userIdentifier == null || userIdentifier.isEmpty) {
        appleSignInDebugLog(
          'repository_failed',
          metadata: {'reason': 'missing_user_identifier'},
        );
        return const Left(
          AppleSignInFailure('Apple Sign-In failed. Please try again.'),
        );
      }

      await appleAuthLocalDataSource.saveFirstLoginProfile(
        userIdentifier: userIdentifier,
        credential: appleCredential,
      );

      final oauthCredential = firebaseAuthDataSource.buildAppleCredential(
        appleCredential: appleCredential,
        rawNonce: rawNonce,
      );

      final userCredential = await _signInOrLinkAppleCredential(oauthCredential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        appleSignInDebugLog(
          'repository_failed',
          metadata: {'reason': 'firebase_user_null'},
        );
        return const Left(
          FirebaseAuthFailure('Unable to complete Apple Sign-In.'),
        );
      }

      final storedProfile = await appleAuthLocalDataSource.readProfile(
        userIdentifier,
      );

      final socialUser = SocialAuthUserModel.fromFirebaseUser(
        user: firebaseUser,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
        emailOverride: storedProfile?.email ?? appleCredential.email,
        displayNameOverride:
            storedProfile?.displayName ??
            _displayNameFromAppleCredential(appleCredential),
      );

      appleSignInDebugLog(
        'repository_sign_in_succeeded',
        metadata: {
          'isNewUser': socialUser.isNewUser,
          'hasResolvedEmail': _hasValue(socialUser.email),
          'hasResolvedDisplayName': _hasValue(socialUser.displayName),
          'hasStoredProfile': storedProfile != null,
          'hasAppleEmail': _hasValue(appleCredential.email),
          'hasFirebaseEmail': _hasValue(firebaseUser.email),
        },
      );

      return Right(socialUser);
    } on AppleSignInServiceException catch (e, stackTrace) {
      appleSignInDebugLog(
        'repository_failed',
        metadata: {
          'reason': 'apple_service_exception',
          'appleErrorType': e.type.name,
        },
      );
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapAppleSignInException(e));
    } on FirebaseAuthException catch (e, stackTrace) {
      appleSignInDebugLog(
        'repository_failed',
        metadata: {
          'reason': 'firebase_auth_exception',
          'firebaseCode': e.code,
        },
      );
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapFirebaseAuthException(e));
    } catch (e, stackTrace) {
      appleSignInDebugLog(
        'repository_failed',
        metadata: {
          'reason': 'unexpected_exception',
          'errorType': e.runtimeType.toString(),
          'isNetworkError': _isNetworkError(e),
        },
      );
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (_isNetworkError(e)) {
        return const Left(
          NetworkFailure(
            'Network error during Apple Sign-In. Please try again.',
          ),
        );
      }
      return const Left(
        AppleSignInFailure('Apple Sign-In failed. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, SocialAuthUser>> signInWithGoogle() async {
    try {
      final account = await googleSignInService.signIn();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        return const Left(
          FirebaseAuthFailure('Google Sign-In failed. Please try again.'),
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );
      final userCredential =
          await firebaseAuthDataSource.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const Left(
          FirebaseAuthFailure('Unable to complete Google Sign-In.'),
        );
      }

      return Right(
        SocialAuthUserModel.fromFirebaseUser(
          user: firebaseUser,
          isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
          emailOverride: account.email,
          displayNameOverride: account.displayName ?? firebaseUser.displayName,
        ),
      );
    } on GoogleSignInServiceException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapGoogleSignInException(e));
    } on FirebaseAuthException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapFirebaseAuthException(e));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (_isNetworkError(e)) {
        return const Left(
          NetworkFailure(
            'Network error during Google Sign-In. Please try again.',
          ),
        );
      }
      return const Left(
        FirebaseAuthFailure('Google Sign-In failed. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> signOutFirebase() async {
    try {
      await firebaseAuthDataSource.signOut();
      return const Right(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapFirebaseAuthException(e));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return const Left(
        FirebaseAuthFailure('Unable to sign out. Please try again.'),
      );
    }
  }

  Future<UserCredential> _signInOrLinkAppleCredential(
    AuthCredential credential,
  ) async {
    final currentUser = firebaseAuthDataSource.currentUser;
    appleSignInDebugLog(
      'firebase_auth_route_selected',
      metadata: {'hasCurrentFirebaseUser': currentUser != null},
    );

    if (currentUser != null) {
      try {
        return await firebaseAuthDataSource.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        appleSignInDebugLog(
          'firebase_link_skipped',
          metadata: {'firebaseCode': e.code},
        );
        if (e.code != 'provider-already-linked' &&
            e.code != 'credential-already-in-use') {
          rethrow;
        }
      }
    }

    try {
      return await firebaseAuthDataSource.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'account-exists-with-different-credential') {
        rethrow;
      }

      appleSignInDebugLog(
        'firebase_account_exists_with_different_credential',
        metadata: {
          'hasCurrentFirebaseUser': firebaseAuthDataSource.currentUser != null,
        },
      );

      if (firebaseAuthDataSource.currentUser != null) {
        return firebaseAuthDataSource.linkWithCredential(credential);
      }

      throw FirebaseAuthException(
        code: e.code,
        message:
            'An account already exists with this email. Sign in with your original method first.',
      );
    }
  }

  String? _displayNameFromAppleCredential(
    AuthorizationCredentialAppleID credential,
  ) {
    final parts = <String>[
      if (credential.givenName != null && credential.givenName!.trim().isNotEmpty)
        credential.givenName!.trim(),
      if (credential.familyName != null &&
          credential.familyName!.trim().isNotEmpty)
        credential.familyName!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  Failure _mapGoogleSignInException(GoogleSignInServiceException exception) {
    switch (exception.type) {
      case GoogleSignInErrorType.canceled:
        return const AppleSignInFailure('Sign-in cancelled', isCancelled: true);
      case GoogleSignInErrorType.configurationError:
      case GoogleSignInErrorType.unsupported:
      case GoogleSignInErrorType.other:
        return const FirebaseAuthFailure(
          'Google Sign-In failed. Please try again.',
        );
    }
  }

  Failure _mapAppleSignInException(AppleSignInServiceException exception) {
    switch (exception.type) {
      case AppleSignInErrorType.cancelled:
        return const AppleSignInFailure('Sign-in cancelled', isCancelled: true);
      case AppleSignInErrorType.notHandled:
      case AppleSignInErrorType.notInteractive:
      case AppleSignInErrorType.failed:
      case AppleSignInErrorType.unknown:
        return const AppleSignInFailure(
          'Apple Sign-In failed. Please try again.',
        );
    }
  }

  Failure _mapFirebaseAuthException(FirebaseAuthException exception) {
    if (exception.code == 'account-exists-with-different-credential') {
      return const AccountLinkingFailure(
        'An account already exists with this email. Sign in with your original method first.',
      );
    }

    if (exception.code == 'network-request-failed') {
      return const NetworkFailure(
        'Network error during Apple Sign-In. Please try again.',
      );
    }

    return FirebaseAuthFailure(
      'Apple Sign-In failed. Please try again.',
      code: exception.code,
    );
  }

  bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection');
  }

  @override
  Future<Either<Failure, SocialAuthUser>> signInWithFacebook() async {
    try {
      final facebookSignInResult = await facebookSignInService.signIn();
      final oauthCredential = _buildFacebookCredential(facebookSignInResult);

      final userCredential = await _signInOrLinkFacebookCredential(oauthCredential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Left(
          FirebaseAuthFailure('Unable to complete Facebook Sign-In.'),
        );
      }

      final socialUser = SocialAuthUserModel.fromFirebaseUser(
        user: firebaseUser,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );

      return Right(socialUser);
    } on FacebookSignInServiceException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapFacebookSignInException(e));
    } on FirebaseAuthException catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(_mapFirebaseAuthException(e));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (_isNetworkError(e)) {
        return const Left(
          NetworkFailure(
            'Network error during Facebook Sign-In. Please try again.',
          ),
        );
      }
      return const Left(
        FacebookSignInFailure('Facebook Sign-In failed. Please try again.'),
      );
    }
  }

  /// Maps flutter_facebook_auth tokens to the Firebase credential shape each type
  /// requires. Using [FacebookAuthProvider.credential] for a [LimitedToken] JWT
  /// causes Firebase `invalid-credential` / Facebook error 190 (bad signature).
  AuthCredential _buildFacebookCredential(FacebookSignInResult result) {
    final accessToken = result.accessToken;

    switch (accessToken.type) {
      case AccessTokenType.limited:
        // iOS Limited Login: OIDC id token + the raw nonce from sign-in.
        final token = accessToken as LimitedToken;
        return OAuthCredential(
          providerId: 'facebook.com',
          signInMethod: 'oauth',
          idToken: token.tokenString,
          rawNonce: result.rawNonce,
        );
      case AccessTokenType.classic:
        // Android / classic iOS: standard Facebook access token.
        final token = accessToken as ClassicToken;
        return FacebookAuthProvider.credential(token.tokenString);
    }
  }

  Future<UserCredential> _signInOrLinkFacebookCredential(
    AuthCredential credential,
  ) async {
    final currentUser = firebaseAuthDataSource.currentUser;

    if (currentUser != null) {
      try {
        return await firebaseAuthDataSource.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'provider-already-linked' &&
            e.code != 'credential-already-in-use') {
          rethrow;
        }
      }
    }

    try {
      return await firebaseAuthDataSource.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'account-exists-with-different-credential') {
        rethrow;
      }

      if (firebaseAuthDataSource.currentUser != null) {
        return firebaseAuthDataSource.linkWithCredential(credential);
      }

      throw FirebaseAuthException(
        code: e.code,
        message:
            'An account already exists with this email. Sign in with your original method first.',
      );
    }
  }

  Failure _mapFacebookSignInException(FacebookSignInServiceException exception) {
    switch (exception.type) {
      case FacebookSignInErrorType.cancelled:
        return const FacebookSignInFailure('Sign-in cancelled', isCancelled: true);
      case FacebookSignInErrorType.failed:
      case FacebookSignInErrorType.unknown:
        return FacebookSignInFailure(
          exception.message ?? 'Facebook Sign-In failed. Please try again.',
        );
    }
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
