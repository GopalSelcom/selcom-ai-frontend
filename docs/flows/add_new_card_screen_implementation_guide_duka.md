# Add New Card Flow - Implementation Guide & Source Code Reference

This document contains the exact Dart source code, validation logic, and step-by-step flow from `add_new_card_screen.dart`. You can share this document with developers working on other projects to implement the exact same card linking flow.

---

## 1. Complete Form Validation Logic

The following methods perform the validation of all UI inputs. You can copy these directly to your new project's card entry screen.

### Form Validation Entrypoint (`isValidate`)
This method checks every form field and returns `true` only if all fields meet their validation requirements.

```dart
bool isValidate() {
  showLoaderDialog(context); // Replace with your project's loader

  String firstName = fNameTextEditingController.text.trim();
  String lastName = lNameTextEditingController.text.trim();

  // 1. First Name Check
  if (firstName.isEmpty) {
    showErrorMessage("${translate(Labels.Enter_First_Name)}");
    return false;
  } else if (firstName.length < 3) {
    showErrorMessage(translate(Labels.firstNameValidation));
    return false;
  } 
  
  // 2. Last Name Check
  else if (lastName.isEmpty) {
    showErrorMessage("${translate(Labels.Enter_Last_Name)}");
    return false;
  } else if (lastName.length < 3) {
    showErrorMessage(translate(Labels.lastNameValidation));
    return false;
  } 
  
  // 3. Card Number Validation (Luhn Algorithm)
  else if (!validateCardNum(cardNumberTextEditingController.text)) {
    showErrorMessage(translate(Labels.error_enter_valid_card_number));
    return false;
  } 
  
  // 4. Expiry Date Check
  else if (validTextEditingController.text.isEmpty) {
    showErrorMessage("${translate(Labels.Enter_card_Expritation_Date)}");
    return false;
  } else if (!validateValidThru(validTextEditingController.text)) {
    return false;
  } 
  
  // 5. CVV Check
  else if (cvvTextEditingController.text.isEmpty) {
    showErrorMessage("${translate(Labels.Enter_CVV)}");
    return false;
  } 
  
  // 6. Country Selection Check
  else if (countriesResponse == null) {
    showErrorMessage("${translate(Labels.Select_Country_for_Billing_Address)}");
    return false;
  } 
  
  // 7. Phone Number length verification (minimum 9 digits after cleaning)
  else if (mobileTextEditingController.text.replaceAll("-", "").length < 9) {
    showErrorMessage("${translate(Labels.Please_Enter_valid_phone_number)}");
    return false;
  } 
  
  // 8. Email Format Verification
  else if (emailTextEditingController.text.trim().isEmpty &&
      !CommonLogics.isEmailValidated(emailTextEditingController.text.trim())) {
    showErrorMessage("${translate(Labels.Please_Enter_valid_Email_address)}");
    return false;
  } 
  
  // 9. Billing Address Check
  else if (addressTextEditingController.text.trim().isEmpty) {
    showErrorMessage("${translate(Labels.Please_Enter_Address)}");
    return false;
  } 
  
  // 10. City Check
  else if (cityTextEditingController.text.trim().isEmpty) {
    showErrorMessage("${translate(Labels.Please_Enter_City)}");
    return false;
  } 
  
  // 11. State & Zip Validation for specific country zones (US, CA, GB)
  else if (countriesResponse!.iso2Code == "US" ||
      countriesResponse!.iso2Code == "CA" ||
      countriesResponse!.iso2Code == "GB") {
    if (stateResponse == null) {
      showErrorMessage("${translate(Labels.Select_State_for_Billing_Address)}");
      return false;
    } else if (zipCodeTextEditingController.text.trim().isEmpty) {
      showErrorMessage("${translate(Labels.Select_Zipcode_for_Billing_Address)}");
      return false;
    }
  }
  return true;
}
```

### Luhn Algorithm Card Validator (`validateCardNum`)
Checks the mathematical validity of the credit/debit card number.

```dart
bool validateCardNum(String input) {
  if (input.isEmpty) {
    return false;
  }
  // Sanitize card number by stripping dots, dashes, and whitespace
  input = input.replaceAll(".", "");
  input = input.replaceAll("-", "");
  input = input.replaceAll(" ", "");
  
  // Card numbers must be at least 15 digits
  if (input.length < 15) {
    return false;
  }
  
  int sum = 0;
  int length = input.length;
  for (var i = 0; i < length; i++) {
    // Get digits in reverse order
    int digit = int.parse(input[length - i - 1]);
    
    // Multiply every second number (counting backwards) by 2
    if (i % 2 == 1) {
      digit *= 2;
    }
    // If double digit is greater than 9, sum its digits (e.g. 14 -> 1+4 = 5, or 14-9 = 5)
    sum += digit > 9 ? (digit - 9) : digit;
  }
  
  // Card is valid if the sum is divisible by 10
  return sum % 10 == 0;
}
```

### Expiry Date Validator (`validateValidThru`)
Validates that the card is not expired and the entry corresponds to a realistic calendar timeline (format `MM/YYYY`).

```dart
bool validateValidThru(String value) {
  if (validTextEditingController.text.isNotEmpty && value.length == 7) {
    String monthStr = value.substring(0, 2);
    String yearString = value.substring(3, value.length);
    int month = int.parse(monthStr);
    int year = int.parse(yearString);
    
    var thisInstant = DateTime.now();
    int currentMonth = thisInstant.month;
    int minYear = thisInstant.year;
    int maxYear = minYear + 20; // Allows up to 20 years in the future
    
    if (year > maxYear) {
      showErrorMessage(
          "Your card expiration can be between $currentMonth/$minYear and $currentMonth/$maxYear.");
      return false;
    }
    if (year < minYear) {
      showErrorMessage(
          "Your card expiration can be between $currentMonth/$minYear and $currentMonth/$maxYear.");
      return false;
    }
    
    if (year == minYear) {
      if (month < thisInstant.month || month > 12) {
        showErrorMessage(
            "Your card expiration can be between $currentMonth/$minYear and $currentMonth/$maxYear.");
        return false;
      }
    } else if (year == maxYear) {
      if (month > thisInstant.month || month > 12) {
        showErrorMessage(
            "Your card expiration can be between $currentMonth/$minYear and $currentMonth/$maxYear.");
        return false;
      }
    } else {
      if (month > 12) {
        showErrorMessage(
            "Your card expiration can be between $currentMonth/$minYear and $currentMonth/$maxYear.");
        return false;
      }
    }
    return true;
  }
  showErrorMessage("Please enter a valid expiration date in MM/YYYY format");
  return false;
}
```

---

## 2. API Submission & Card Initialization (`callAddCardAPI`)

This method initiates the card session setup by calling the backend API. It formats and maps the payload, sends it to `/init_card_session`, and processes the initial session data.

```dart
Future<void> callAddCardAPI() async {
  if (isValidate()) {
    String stateId = "";
    String billingAddressId = "";
    String countryName = "";
    String country = "";
    String addressId = "";

    if (widget.selectedAddress != null) {
      addressId = widget.selectedAddress!.sId!;
    }
    if (selectedBillingAddress != null) {
      billingAddressId = selectedBillingAddress!.sId!;
    }
    if (countriesResponse != null) {
      countryName = countriesResponse!.name!.trim();
      country = countriesResponse!.iso2Code!.trim();
    }
    if (stateResponse != null) {
      stateId = stateResponse!.name!;
    }

    int sendAmount = widget.sendAmount ?? 0;
    List<String> cartitemIds = [];
    int deliveryCharge = 0;
    String promoCode = "";
    String paymentMode = widget.paymentMode ?? "";
    String deliveryDate = widget.selectedDayName ?? "";
    String timeSlot = "";
    int starttime = 0;
    int endtime = 0;

    if (widget.groceryCartListResponse != null) {
      for (int i = 0; i < widget.groceryCartListResponse!.allProduct!.length; i++) {
        cartitemIds.add(widget.groceryCartListResponse!.allProduct![i].sId!);
      }
      deliveryCharge = widget.groceryCartListResponse!.deliveryCharge!;
      promoCode = widget.groceryCartListResponse!.promoCode!;
    }
    
    if (widget.timeslots != null) {
      timeSlot = widget.timeslots!.displayTxt!;
      if (widget.deliveryType != DeliveryType.PICK_UP) {
        starttime = widget.timeslots!.startTime!;
        endtime = widget.timeslots!.endTime!;
      }
    }

    String deliveryType = widget.deliveryType ?? "";
    int sqrAmount = widget.sqrAmount ?? 0;
    bool isCheckout = widget.groceryCartListResponse != null;

    // Execute the POST API Request to initiate the card session
    http.Response response = await HttpService.apiService(
      endpoint: URLS.INIT_CARD_SESSION,
      showLoaderOnRetry: true,
      headers: await getHeaders(
        accessTokenRequired: true,
        contentTypeEnabled: true,
        encryptionEnabled: true,
        passRequestId: true,
      ),
      method: METHOD.post,
      body: {
        "sendAmount": sendAmount,
        "allCart_id": cartitemIds,
        "type": "CARD",
        "deliveryCharge": deliveryCharge,
        "billing_address_id": billingAddressId,
        "newCard": 0, // Indicates linking a new card
        "transid": "",
        "isCheckout": isCheckout,
        "deliveryType": deliveryType,
        "address_id": addressId,
        "promo_code": promoCode,
        "payment_mode": paymentMode,
        "delivery_date": deliveryDate.toUpperCase(),
        "delivery_option": "Standard_Delivery",
        "time_slot": timeSlot,
        "order_id": "",
        "starttime": starttime,
        "endtime": endtime,
        "expresstime": 0,
        "payment_token": 0,
        "weight": 0,
        "sqr_amount": sqrAmount,
        "email": emailTextEditingController.text.trim(),
        "mobile_number": mobileTextEditingController.text.replaceAll("-", "").trim(),
        "country_code": countriesResponse!.phoneCode,
        "cardBin": cardNumberTextEditingController.text.replaceAll(" ", "").substring(0, 6),
        "fname": fNameTextEditingController.text.trim(),
        "lname": lNameTextEditingController.text.trim(),
        "address": addressTextEditingController.text.trim(),
        "city": cityTextEditingController.text.trim(),
        "state": stateId,
        "country": country,
        "postalcode": zipCodeTextEditingController.text.trim(),
        "country_name": countryName,
      },
    );

    hideLoaderDialog(); // Dismiss loading spinner

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Direct call to process the successful InitSession response
      onSuccess(InitSessionCardModel.fromJson(json.decode(response.body)));
    }
  }
}
```

---

## 3. Cybersource Silent Order Post (SOP) Integration & Webview Navigation

Once `callAddCardAPI` successfully completes, the app formats card data with the session payload into an HTML form that posts directly to the Cybersource gateway inside a WebView.

### 1. Card Type Recognition (`updateCardTypeImage`)
Determines the card type (Visa, Mastercard, Amex) to feed into the Cybersource parameter payload.

```dart
void updateCardTypeImage(String cardNumber) {
  if (cardNumber.isNotEmpty) {
    CreditCardType type = detectCCType(cardNumber); // standard credit card detector
    if (type == CreditCardType.visa) {
      cardType = "001"; // Visa Cybersource code
    } else if (type == CreditCardType.mastercard) {
      cardType = "002"; // Mastercard Cybersource code
    } else if (type == CreditCardType.amex) {
      cardType = "003"; // American Express Cybersource code
    } else {
      cardType = "";
    }
  } else {
    cardType = "";
  }
}
```

### 2. Auto-Submitting HTML Document Generation
Builds an self-submitting HTML string to load within the webview.

```dart
void createHtmlCodeForCuberSourceToAddCard(
    String cardNumber,
    String expiryMonth,
    String expiryYear,
    String cvv,
    String cardType,
    Map<String, dynamic> sessionResponse) {
  
  String htmlCode = r'''
        <html>
          <body onload="document.f.submit();">
      ''';
  
  // Action points to Cybersource SECURE_ADD_CARD_URL
  htmlCode += "<form id=\"f\" name=\"f\" method=\"post\" action=\"${URLS.SECURE_ADD_CARD_URL}\">\n";
  
  // Inject signed access keys, signature, and transaction details from the backend session response
  sessionResponse.forEach((key, value) {
    htmlCode += "<input type=\"hidden\" name=\"$key\" value=\"$value\" />\n";
  });
  
  // Inject card details collected in the native mobile form
  htmlCode += "<input type=\"hidden\" name=\"card_number\" value=\"$cardNumber\" />\n";
  
  htmlCode += "<input type=\"hidden\" name=\"card_type\" value=\"$cardType\" />\n";
  
  // Date format required: MM-YYYY
  htmlCode += "<input type=\"hidden\" name=\"card_expiry_date\" value=\"$expiryMonth-$expiryYear\"/>\n";
  
  htmlCode += "<input type=\"hidden\" name=\"card_cvn\" value=\"$cvv\" />\n";
  
  htmlCode += r'''
            </form>
          </body>
        </html>
      ''';

  // Navigate to WebView screen passing the generated HTML string
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CommonWebviewToLoadHTML(htmlCode),
    ),
  ).then((isSuccess) async {
    // 3. Handle callback when Webview screen pops
    if (isSuccess != null) {
      if (isSuccess is bool) {
        if (isSuccess) {
          // Trigger order verification dialog check on success
          openCheckOrderStatusAlert("${initSessionCardModel!.transid}");
        }
      } else if (isSuccess is String) {
        // Handle explicit string error messages
        showErrorAndSendCallback(isSuccess);
      }
    }
  });
}
```

---

## 4. Handling Webview Callbacks & Order Verification

When the Webview pops, the app executes order status query loops or sends failure callbacks to the backend.

### Order Status Verification Dialog (`openCheckOrderStatusAlert`)
Opens an alert view that polls the order completion status.

```dart
void openCheckOrderStatusAlert(String orderId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return CheckOrderStatusAlert(
        orderId: orderId,
        module: widget.module ?? Module.home,
        moduleName: widget.moduleName ?? "",
        onCheckPaymentStatus: (CheckPaymentStatusModel? checkStatusModel) async {
          if (checkStatusModel != null) {
            // Payment success - return card session details back to active flow
            initSessionCardModel!.message = checkStatusModel.message;
            initSessionCardModel!.transid = checkStatusModel.orderTransid;
            Navigator.pop(context, initSessionCardModel);
          } else {
            // Poll failed / payment failed - trigger failure callback
            sendAddCardFailureCallback();
          }
        },
      );
    },
  );
}
```

### Backend Failure Callback (`sendAddCardFailureCallback`)
Informs the server if the user aborted the flow or the Cybersource transaction returned a failure.

```dart
Future<void> sendAddCardFailureCallback() async {
  http.Response response = await HttpService.apiService(
    endpoint: URLS.GROCERY_ADD_CARD_CALLBACK,
    headers: await getHeaders(
      accessTokenRequired: true,
      contentTypeEnabled: true,
      encryptionEnabled: true,
    ),
    method: METHOD.post,
    body: {
      "transid": initSessionCardModel!.transid,
      "status": "FAIL",
    },
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    onSuccess(ModelCommonMsg.fromJson(jsonDecode(response.body)));
  }
}
```
