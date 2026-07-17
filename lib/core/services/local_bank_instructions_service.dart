import 'dart:async';
import '../network/api_service.dart';
import '../network/urls.dart';
import '../utils/app_logger.dart';

class LocalBankInstructionsService {
  dynamic _instructionsData;
  bool _fetchInFlight = false;

  /// Holds the response data from the local-bank-instructions wallet API.
  dynamic get instructionsData => _instructionsData;

  /// Fetches local bank instructions once per session while a wallet is linked.
  ///
  /// Subsequent calls are no-ops until [clear] (logout). Triggered after a
  /// successful wallet-balance load that includes a wallet number — not from
  /// Home startup.
  Future<void> fetchInstructions() async {
    if (_instructionsData != null || _fetchInFlight) return;
    _fetchInFlight = true;
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.getLocalBankInstructions,
          method: ApiMethod.post,
          showLoader: false,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        _instructionsData = response.data;
        AppLogger.d(
          'fetchInstructions success: $_instructionsData',
          tag: 'LocalBankInstructionsService',
        );
      } else {
        AppLogger.e(
          'fetchInstructions failed with status: ${response.statusCode}',
          tag: 'LocalBankInstructionsService',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'fetchInstructions exception: $e',
        tag: 'LocalBankInstructionsService',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _fetchInFlight = false;
    }
  }

  /// Clears the session cache so the next login can fetch again.
  void clear() {
    _instructionsData = null;
    _fetchInFlight = false;
  }
}

class LocalBankInstructions {
  final String accountNo;
  final List<BankInstructionItem> items;

  LocalBankInstructions({required this.accountNo, required this.items});

  factory LocalBankInstructions.fromJson(Map<String, dynamic> json) {
    final list = json['response'] as List? ?? [];
    return LocalBankInstructions(
      accountNo: json['account_no']?.toString() ?? '',
      items: list
          .map(
            (e) => BankInstructionItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class BankInstructionItem {
  final String id;
  final String uid;
  final Map<String, String> title;
  final Map<String, String> description;
  final Map<String, List<InstructionStep>> instructions;

  BankInstructionItem({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.instructions,
  });

  factory BankInstructionItem.fromJson(Map<String, dynamic> json) {
    final titleMap = Map<String, String>.from(json['title'] ?? {});
    final descMap = Map<String, String>.from(json['description'] ?? {});
    final instrMap = <String, List<InstructionStep>>{};

    final instructionsJson = json['instructions'] as Map? ?? {};
    instructionsJson.forEach((key, value) {
      if (value is List) {
        instrMap[key.toString()] = value
            .map((e) => InstructionStep.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    });

    return BankInstructionItem(
      id: json['_id']?.toString() ?? '',
      uid: json['UID']?.toString() ?? '',
      title: titleMap,
      description: descMap,
      instructions: instrMap,
    );
  }

  String getDisplayTitle(String locale) {
    return title[locale] ?? title['en'] ?? '';
  }

  String getDisplayDescription(String locale) {
    return description[locale] ?? description['en'] ?? '';
  }

  List<InstructionStep> getDisplaySteps(String locale) {
    return instructions[locale] ?? instructions['en'] ?? [];
  }
}

class InstructionStep {
  final String step;
  final String instruction;

  InstructionStep({required this.step, required this.instruction});

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      step: json['step']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? '',
    );
  }
}
