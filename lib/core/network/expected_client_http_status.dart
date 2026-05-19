/// HTTP statuses treated as expected business outcomes (not transport faults).
///
/// Call sites should avoid throwing or global error reporting for these codes;
/// return null, empty collections, or domain-safe fallbacks instead.
bool isExpectedClientBusinessHttpStatus(int? statusCode) =>
    statusCode == 400 ||
    statusCode == 401 ||
    statusCode == 403 ||
    statusCode == 405;
