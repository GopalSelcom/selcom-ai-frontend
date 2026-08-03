import 'languages.dart';

class LanguageEn extends Languages {
  @override
  final Map<String, String> values = {
    'code_not_exist': 'The code you searched for does not exist.',
    'account_unlinked_successfully': 'Account unlinked successfully',
    'add': 'Add',
    'add_asaved_place': 'Add a saved place',
    'add_debit_credit_card': 'Add debit/credit card',
    'add_new_card': 'Add new card',
    'add_card': 'Add card',
    'address_missing': 'Address missing',
    'an_unexpected_error_occurred': 'An unexpected error occurred',
    'apply': 'APPLY',
    'are_you_sure_want_to_add_ndelete_this_card': 'Are you sure want to add Delete this card?',
    'are_you_sure_you_want_to_cancel': 'Are you sure you want to cancel?',
    'book_ride': 'Book ride',
    'book_any': 'Any',
    'book_ride_wallet_deduction_notice': 'The amount will be deducted from your wallet.',
    'insufficient_balance_title': 'Insufficient balance',
    'insufficient_balance_message': 'Your wallet balance is too low to book this ride. Please top up to continue.',
    'current_balance_label': 'Current balance',
    'required_amount_label': 'Required amount',
    'amount_needed_label': 'Amount needed',
    'top_up_wallet': 'Top up wallet',
    'add_money_to_wallet': 'Add money to wallet',
    'add_money': 'Add money',
    'amount': 'Amount',
    'back': 'Back',
    'wallet_funds_received_title': 'Your wallet has received funds',
    'wallet_funds_received_subtitle': 'You can now use your wallet to book rides.',
    'top_up_request_sent_title': 'Top up request sent',
    'mobile_money_request_sent_title': 'Request sent',
    'mobile_money_request_sent_message':
        'Your payment request has been sent to @number. The amount will be reflected in your Selcom Go wallet.',
    'selcom_pesa_to_go_wallet': 'SelcomPesa to Go wallet',
    'enter_selcom_pesa_customer_phone_hint': 'Enter SelcomPesa customer phone number, and we\'ll send a request',
    'request_sent_complete_selcom_topup':
        'Request sent. Please complete payment on SelcomPesa to top up your Go wallet',
    'expires_in_with_time': 'Expires in @time',
    'wallet_topup_amount_required': 'Please enter an amount',
    'wallet_topup_amount_must_be_greater_than_zero': 'Amount must be greater than 0',
    'wallet_topup_amount_exceeds_max': 'Amount cannot exceed TZS @max',
    'wallet_topup_request_failed': 'Could not start the payment. Please try again.',
    'wallet_topup_timer_expired_title': 'Payment time expired',
    'wallet_topup_timer_expired_message': 'The payment request has expired. Would you like to try again?',
    'wallet_topup_cancel_request': 'Cancel request',
    'selcom_pesa_app_not_installed': 'SelcomPesa app not installed',
    'selcom_pesa_install_prompt': 'Install SelcomPesa to complete this payment on your device.',
    'selcom_pesa_handoff_failed': 'Unable to open SelcomPesa. Please make sure the app is installed and try again.',
    'selcom_pesa_status_not_found': 'We could not find this payment. Please try again.',
    'selcom_pesa_payment_rejected': 'Payment was declined or failed. Please try again.',
    'selcom_pesa_payment_processing':
        'Payment received, processing your top-up. Contact support if your balance does not update.',
    'wallet_account_unavailable': 'Your Go wallet is not available. Please try again later.',
    'download_app': 'Download',
    'select_a_vehicle': 'Please select a vehicle.',
    'booking_for_name': 'Booking for @name',
    'booking_for_someone_else_prompt': 'Are you booking for someone else?',
    'booking_for_someone_else_subtitle': 'You can enter their details so that we can directly send them ride information.',
    'booking_ride_option_for_me': 'No, booking for me',
    'booking_ride_option_for_someone_else': 'Yes, for someone else',
    'notification_phone_required': 'Please enter a phone number for notifications.',
    'notification_phone_subtitle': 'We will send ride updates and notifications to this number.',
    'enter_passenger_full_name': 'Enter full name',
    'passenger_details_title': 'Passenger details',
    'passenger_name_label': 'Passenger name',
    'passenger_phone_label': 'Passenger phone',
    'onboarding_footer_lead': 'By continuing, you agree that you have read and accept our ',
    'onboarding_footer_terms_link': 'T&Cs',
    'onboarding_footer_joiner': ' and ',
    'call': 'Call',
    'call_driver': 'Call driver',
    'call_driver_sheet_subtitle': 'Choose how you want to reach your driver during this ride.',
    'contacts_permission': 'Contacts permission',
    'contacts_access_needed':
        'We need contacts access to let you select a passenger from your contact list. Please enable it in Settings.',
    'cancel_and_pay': 'Cancel & Pay',
    'cancel_failed': 'Cancel failed',
    'cancel_ride': 'Cancel ride',
    'cancel': 'Cancel',
    'cancelled': 'Cancelled',
    'cancellation_reason': 'Cancellation reason',
    'cancellation_reason_by_rider': 'Cancelled by you',
    'cancelling_your_ride': 'Cancelling your ride…',
    'card_number': 'Card number',
    'change_drop_location': 'Change drop location',
    'add_stops': 'Add stops',
    'change_location': 'Change location',
    'chat': 'Chat',
    'chat_is_only_available_during_an_active_ride': 'Chat is only available during an active ride',
    'check_your_pickup_point': 'Check your pickup point',
    'choose_ride': 'Choose a ride',
    'confirm_pickup': 'Confirm pickup',
    'connection_error': 'Connection error',
    'contact_us': 'Contact us',
    'contact_support': 'Contact support',
    'request_to_cancel': 'Request to cancel',
    'request_cancellation_subtitle': 'Tell us why you want support to review cancelling this ride.',
    'submit_request': 'Submit request',
    'optional_details': 'Optional details',
    'describe_what_happened_hint': 'Describe what happened (optional)',
    'withdraw_request': 'Withdraw request',
    'cancellation_request_sent_with_ticket': 'Request sent. Support will review and call you shortly. Ticket @ticket',
    'support_declined_cancellation': 'Support declined — your ride continues',
    'could_not_submit_cancellation_request': 'Could not submit cancellation request. Please try again.',
    'could_not_withdraw_cancellation_request': 'Could not withdraw the request. Please try again.',
    'could_not_load_cancellation_reasons': 'Could not load cancellation reasons. Please try again.',
    'ride_not_active_refresh': 'This ride is no longer active. Please refresh.',
    'cancellation_request_already_decided': 'Support already decided this request.',
    'cancellation_request_already_pending': 'Your cancellation request is already under review. Ticket @ticket',
    'back_on_route': 'Back on route',
    'continue_to_trip': 'Continue to trip',
    'continue': 'Continue',
    'sign_in_with_google': 'Sign in with Google',
    'could_not_cancel_try_again': 'Could not cancel. Try again.',
    'could_not_resolve_vehicle_type_id_please_try_again': 'Could not resolve vehicle type id. Please try again.',
    'could_not_validate_payment_please_try_again': 'Could not validate payment. Please try again.',
    'default_currency_tzs': 'TZS',
    'delete_card': 'Delete card',
    'do_not_share_your_personal_details_with_rider_be_safe_and_always_check_your_luggage': 'Do not share your personal Details with rider Be safe and always check your luggage',
    'done': 'Done',
    'download_slip': 'Download slip',
    'download_slip_gallery_subtitle': 'Save a copy to your gallery',
    'choose_how_to_receive_receipt': 'Choose how you would like to receive your receipt',
    'receipt_options': 'Receipt options',
    'share_slip': 'Share slip',
    'share_slip_subtitle': 'Send receipt link to others',
    'driver_arrived_map_badge': 'Driver arrived',
    'map_satellite_view': 'Satellite view',
    'map_standard_view': 'Standard map',
    'driver_arrived_pickup_primary': 'Driver arrived at pickup',
    'your_driver_has_arrived': 'Your driver has arrived!',
    'driver_is_heading_to_your_location': 'Driver is heading to your location',
    'driver_heading_towards_you': 'Your driver is heading towards you',
    'driver_assigned_description': 'A driver has accepted your ride and is on the way.',
    'driver_has_accepted_your_ride': 'Driver has accepted your ride',
    'driver_arrived_description': 'Your driver has arrived at the pickup location.',
    'ride_started_description': 'You are on your way to the destination.',
    'finding_your_driver': 'Finding your driver',
    'finding_driver_default_description': 'The driver will pick you up as soon as possible after they confirm your order',
    'finding_driver_minutes_remain': '@minutes min @seconds sec remaining',
    'driver_will_arriving_in_minutes': 'Driver will arrive in @minutes min...',
    'driver_finishing_nearby_trip': 'Your driver is finishing a nearby trip and will pick you up soon.',
    'driver_en_route': 'Driver en route',
    'driver_arrived': 'Driver arrived',
    'e_g123': 'e.g. 123',
    'e_g7_xx_xxx_xxx': 'e.g. 7XX XXX XXX',
    'e_gjohn_doe': 'e.g. John Doe',
    'edit_your_phone_number': 'Edit your phone number?',
    'enter_phone_number': 'Enter phone number',
    'enter_phone_number_for_verification': 'Enter phone number for verification',
    'enter_promo_code': 'Enter promo code',
    'enter_promocode': 'Enter promocode',
    'enter_your_selcom_pesa_number': 'Enter your SelcomPesa number',
    'error': 'Error',
    'error_opening_phone_dialer': 'Error opening phone dialer',
    'error_sending_message': 'Error sending message',
    'estimate_failed': 'Estimate failed',
    'eta_minutes_away_drop_time': '@minutes min away • Drop @time',
    'eta_minutes_away_only': '@minutes min away',
    'drop_at_time': 'Drop @time',
    'explore_vehicle': 'Explore vehicle',
    'minutes_ago': '@count m ago',
    'hours_ago': '@count h ago',
    'days_ago': '@count d ago',
    'days_left_count': '@count days left',
    'request_sent_please_complete_payment_on_selcom_pesa_to_book_your_ride': 'Request sent. Please complete payment on SelcomPesa to top-up your wallet.',
    'thank_you_for_riding_with_us_see_you_on_the_next_trip': 'Thank you for riding with us, see you on the next trip.',
    'fare': 'Fare',
    'failed_to_send_message': 'Failed to send message',
    'failed_to_load_settings': 'Failed to load settings',
    'failed_to_load_ride_pin_preference': 'Failed to load ride PIN preference',
    'failed_to_update_ride_pin_preference': 'Failed to update ride PIN preference',
    'failed_to_resend_otp': 'Failed to resend OTP',
    'failed_to_send_otp': 'Failed to send OTP',
    'fallback_ride_name': 'Ride',
    'saved_locations': 'Saved locations',
    'home_label': 'Home',
    'got_it': 'Got it',
    'google_sign_in_cancelled': 'Sign-in cancelled',
    'google_sign_in_failed': 'Google Sign-In failed. Please try again.',
    'sign_in_with_apple': 'Sign in with Apple',
    'apple_sign_in_cancelled': 'Sign-in cancelled',
    'apple_sign_in_failed': 'Apple Sign-In failed. Please try again.',
    'apple_sign_in_account_exists': 'An account already exists with this email. Sign in with your original method first.',
    'sign_in_with_facebook': 'Sign in with Facebook',
    'facebook_sign_in_cancelled': 'Sign-in cancelled',
    'facebook_sign_in_failed': 'Facebook Sign-In failed. Please try again.',
    'help': 'Help',
    'having_trouble_logging_in': 'Having trouble logging in?',
    'how_can_we_help_you': 'How can we help you?',
    'how_do_you_rate_the_driver': 'How do you rate the driver?',
    'how_was_your_ride': 'How was your ride?',
    'includes_stop_fee': 'Includes stop fee',
    'keep_ride': 'Keep ride',
    'link_account': 'Link account',
    'location': 'Location',
    'locating': 'Locating...',
    'locating_driver': 'Locating driver...',
    'current_location': 'Current location',
    'saved': 'Saved',
    'saved_place': 'Saved place',
    'saved_places': 'Saved places',
    'recent_locations': 'Recent locations',
    'search_tag': 'SEARCH',
    'recent_tag': 'RECENT',
    'saved_tag': 'SAVED',
    'loading_your_profile': 'Loading your profile...',
    'location_selection': 'Location selection',
    'location_unavailable': 'Location unavailable',
    'login': 'Login',
    'logout': 'Logout',
    'lorem_ipsum_dolor_sit_amet_consectetur': 'Lorem ipsum dolor sit amet, consectetur',
    'making_your_drive_best_is_our_responsibility': 'Making your drive best is our responsibility',
    'maybe_later': 'Maybe later',
    'mark_all_read_count': 'Mark all read (@count)',
    'message': 'Message',
    'missing_info': 'Missing info',
    'missing_ride_information': 'Missing ride information.',
    'mm_yy': 'MM/YY',
    'my_rides': 'My rides',
    'name_cannot_be_empty': 'Name cannot be empty',
    'name_is_required': 'Name is required',
    'need_help': 'Need help?',
    'new_message': 'New message',
    'no': 'NO',
    'no_driver_found_for_your_request_please_try_again': 'No driver found for your request. Please try again.',
    'no_drivers_nearby_please_try_again_later': 'No drivers nearby. Please try again later.',
    'no_favorite_locations_yet': 'No favorite locations yet',
    'no_locations_found': 'No locations found',
    'no_notifications_yet': 'No notifications yet',
    'no_past_rides_found': 'No past rides found',
    'no_recent_locations_found': 'No recent locations found',
    'no_recent_locations': 'No recent locations',
    'note_by_proceeding_you_consent_to_get_calls_whatsapp_or_sms_messages_including_by_au':
        'Note: By proceeding, you consent to get calls, WhatsApp or SMS messages, including by automated means, from Selcom Go and its affiliates to the number provided.',
    'notification': 'Notification',
    'notifications': 'Notifications',
    'ok': 'OK',
    'order_label_with_id': 'Order: @orderId',
    'open_settings': 'Open settings',
    'call_notification_permission_msg':
        'Notification permission is required to receive incoming driver calls. Please enable it in the app settings.',
    'call_full_screen_permission_msg':
        'Full screen notifications are required to answer calls when your phone is locked. Please enable it in the app settings.',
    'please_enter_label': 'Please enter label',
    'past': 'Past',
    'payment': 'Payment',
    'payment_not_confirmed': 'Payment not confirmed',
    'book_ride_payment_not_applied_title': 'Payment not deducted',
    'book_ride_payment_not_applied_message':
        'We could not confirm that your payment was taken for this ride. Tap Retry to submit the booking again, or Cancel to stay here.',
    'payment_validation_failed': 'Payment validation failed',
    'phone_number_unavailable': 'Phone number unavailable',
    'phone_with_number': 'Phone: @phone',
    'pick_any_tags_that_match_this_trip': 'Pick any tags that match this trip.',
    'pickup': 'Pickup',
    'pickup_point': 'Pickup point',
    'pickup_confirmation_note_label': 'Additional note',
    'pickup_confirmation_note_hint': 'Optional — building, gate, landmark…',
    'pin': 'PIN',
    'pin_locked': 'PIN locked',
    'please_confirm_pickup_point_to_continue': 'Please confirm pickup point to continue.',
    'please_enter_apromo_code': 'Please enter a promo code',
    'please_enter_a_valid_email': 'Please enter a valid email',
    'please_enter_a_valid_name': 'Please enter a valid name',
    'please_enter_at_least_one_destination': 'Please enter at least one destination.',
    'please_enter_your_comment_first': 'Please enter your comment first.',
    'please_rate_your_ride_before_submitting': 'Please rate your ride before submitting.',
    'please_select_at_least_one_destination': 'Please select at least one destination.',
    'please_tell_us_what_went_wrong_or_how_we_can_improve': 'Please tell us what went wrong or how we can improve.',
    'privacy_policy': 'Privacy policy',
    'terms_and_conditions': 'Terms and conditions',
    'payment_method_with_name': 'Payment method @name',
    'calculating_best_route': 'Calculating best route...',
    'ride_receipt': 'Ride receipt',
    'transaction_id_with_value': 'Transaction ID: @id',
    'route': 'Route',
    'dropoff': 'Dropoff',
    'em_dash': '—',
    'driver_and_vehicle': 'Driver & vehicle',
    'driver': 'Driver',
    'model': 'Model',
    'colour': 'Colour',
    'plate': 'Plate',
    'fare_breakdown': 'Fare breakdown',
    'thank_you_for_riding_with_selcom_go': 'Thank you for riding with Selcom Go!',
    'mobile_money': 'Mobile money',
    'card': 'Card',
    'promocode_list': 'Promocode list',
    'promotions': 'Promotions',
    'have_promo_code': 'Have a promo code?',
    'promo_apply_success_message': 'Promo code applied successfully.',
    'promo_removed_title': 'Promo removed',
    'promo_removed_destination_changed': 'Your route changed — the promo was cleared.',
    'promo_error_invalid': 'Invalid promo code',
    'promo_error_expired': 'This code has expired',
    'promo_not_applied_title': 'Promo not applied',
    'promo_code_not_valid_for_vehicle': 'Code not valid for this vehicle',
    'promo_auto_applied_badge': 'Auto-applied',
    'promo_cashback_amount': 'Cashback @amount',
    'ride_free_label': 'FREE',
    'promo_min_ride_amount': 'Min. ride @amount',
    'promo_expires_today': 'Expires today',
    'no_available_promo_codes': 'No promo codes available right now',
    'failed_to_load_promo_codes': 'Could not load promo codes',
    'promo_auto_apply_list_badge': 'Auto-applied',
    'rating': 'Rating',
    'rating_required': 'Rating required',
    'reason_to_contact': 'Reason to contact',
    'recent_location': 'Recent location',
    'remove': 'Remove',
    'remove_saved_address': 'Remove saved address',
    'are_you_sure_you_want_to_remove_this_saved_address': 'Are you sure you want to remove this saved address?',
    'resend_code': 'Resend code',
    'retry': 'Retry',
    'ride_cancelled': 'Ride cancelled',
    'trip_ended_by_driver': 'Trip ended by driver',
    'mid_ride_sorry_subtitle': 'We\'re sorry your trip couldn\'t be completed.',
    'mid_ride_reason_lead': 'Reason: ',
    'mid_ride_cancelled_by_driver_partial_charge': 'Cancelled by driver',
    'mid_ride_reason_vehicle_breakdown': 'Vehicle breakdown',
    'mid_ride_reason_accident': 'Accident',
    'mid_ride_reason_unsafe': 'Unsafe situation',
    'mid_ride_reason_other': 'Other',
    'driver_started_your_ride': '@driverName has started your ride',
    'ride_completed': 'Ride completed',
    'the_ride_has_been_cancelled': 'The ride has been cancelled.',
    'you_have_reached_your_destination': 'You have reached your destination.',
    'you_have_arrived': 'You have arrived!',
    'arrived_in_minutes': 'Arrived in @minutes mins',
    'approaching_your_destination': 'Approaching your destination',
    'heading_to_your_destination': 'Heading to your destination',
    'trip_has_started': 'Trip has started',
    'nearby': 'Nearby',
    'arriving': 'Arriving',
    'driver_is_arriving': 'Driver is arriving...',
    'we_couldnt_find_a_driver_nearby': 'We couldn\'t find a driver nearby.',
    'ride_data_is_unavailable': 'Ride data is unavailable.',
    'ride_id_is_missing': 'Ride id is missing.',
    'destination': 'Destination',
    'arrived_in': 'Arrived in',
    'minutes_short_count': '@count mins',
    'someone': 'Someone',
    'could_not_fetch_receipt_details': 'Could not fetch receipt details.',
    'ride_details_are_missing': 'Ride details are missing.',
    'failed_to_load_ride_details': 'Could not load ride details. Please try again.',
    'could_not_download_slip_please_try_again_later': 'Could not download slip. Please try again later.',
    'check_out_my_ride_receipt_share_url': 'Check out my ride receipt: @url',
    'selcom_go_ride_receipt_subject': 'Selcom Go ride receipt',
    'could_not_share_slip_please_try_again_later': 'Could not share slip. Please try again later.',
    'ride_pin_protection': 'Ride PIN protection',
    'save_this_address_first_then_you_can_book_from_here': 'Save this address first, then you can book from here.',
    'search_destination': 'Search destination',
    'search_location': 'Search location...',
    'search_pickup': 'Search pickup',
    'search_stop_location': 'Search stop location',
    'in_app_calling': 'In-app call',
    'in_app_calling_subtitle': 'Voice call through the app using your active ride connection.',
    'normal_call': 'Phone call',
    'normal_call_subtitle': 'Use your device dialer to call the driver directly.',
    'update_failed': 'Update failed',
    'update_in_progress': 'Update in progress',
    'a_previous_update_is_still_being_processed': 'A previous update is still being processed.',
    'taking_longer_than_expected': 'Taking longer than expected',
    'the_update_is_taking_some_time_please_check_back_shortly': 'The update is taking some time. Please check back shortly.',
    'payment_hold_update_failed_no_charges_applied': 'Payment hold update failed. No charges applied.',
    'drivers_app_couldnt_be_updated_billing_adjusted_back': 'Driver\'s app couldn\'t be updated. Your billing has been adjusted back.',
    'security_and_preference_controls_more_settings_will_appear_here_as_they_are_enable': 'Security and preference controls. More settings will appear here as they are enabled.',
    'selcom_pesa': 'SelcomPesa',
    'select_anearby_point_for_easier_pickup': 'Select a nearby point for easier pickup',
    'select_country': 'Select country',
    'select_country_subtitle': 'Search and choose your country dialling code for your phone number.',
    'search_country': 'Search country',
    'no_countries_found': 'No countries found',
    'select_areason': 'Select a reason',
    'select_a_reason_subtitle': 'Choose the topic that best describes what you need help with.',
    'session_expired': 'Session expired',
    'settings': 'Settings',
    'skip': 'Skip',
    'skip_failed': 'Skip failed',
    'stop': 'Stop',
    'start_typing_pickup': 'Start typing pickup',
    'start_typing_destination': 'Start typing destination',
    'submit_failed': 'Submit failed',
    'submit': 'Submit',
    'success': 'Success',
    'selected_address': 'Selected address',
    'searching_for_driver': 'Searching for driver...',
    'enable_location_service': 'Enable location service',
    'enable_location_service_message': 'Please enable your location service to get your current location.',
    'enable_location_service_message_ios':
        'Location Services are turned off on your device.\\n\\nGo to Settings → Privacy & Security → Location Services and turn it on. Then return to the app and tap the GPS button again to allow location for Selcom Go.',
    'location_permission_denied': 'Location permission denied',
    'location_access_required': 'Location access required',
    'location_permission_denied_open_settings':
        'Location permission is permanently denied. Open Settings to allow location for pickup and nearby drivers.',
    'unable_to_estimate_fare_for_this_route': 'Unable to estimate fare for this route.',
    'distance_min_km': '0.1 KM',
    'distance_max_km': '>999 KM',
    'distance_km_format': '@value KM',
    'distance': 'Distance',
    'duration': 'Duration',
    'could_not_remove_address': 'Could not remove address',
    'view_more': 'View more',
    'ongoing': 'Ongoing',
    'completed': 'Completed',
    'no_driver_found': 'No driver found',
    'boda': 'Boda',
    'unknown_location': 'Unknown location',
    'active_ride': 'Active ride',
    'booked_for_other_limit_reached': 'You have reached the limit for rides booked for others.',
    'booked_for_other_no_multi_stop': 'Multi-stop rides are not allowed when booking for another person.',
    'book_any_fare_settled_title': 'Payment updated',
    'book_any_fare_settled_blocked_lead': 'We temporarily blocked ',
    'book_any_fare_settled_middle_with_vehicle': ' for your Book Any ride. A @vehicle was assigned at a lower fare, so ',
    'book_any_fare_settled_middle_no_vehicle': ' for your Book Any ride. A lower fare vehicle was assigned, so ',
    'book_any_fare_settled_released_trail': ' has been released back to your wallet.',
    'book_any_fare_settled_final_charge_label': 'Final charge: ',
    'unable_to_get_location_coordinates': 'Unable to get location coordinates',
    'please_select_valid_pickup_and_destination_locations': 'Please select valid pickup and destination locations.',
    'are_you_sure_you_want_to_add_this_address_as': 'Are you sure you want to add this address as @phrase?',
    'tell_us_more_about_your_experience': 'Tell us more about your experience...',
    'thank_you': 'Thank you',
    'this_is_second_slide': 'This is second slide',
    'this_is_third_slide': 'This is third slide',
    'this_saved_place_has_no_address': 'This saved place has no address.',
    'this_saved_place_is_missing_coordinates': 'This saved place is missing coordinates.',
    'this_saved_place_is_missing_coordinates_try_saving_it_again': 'This saved place is missing coordinates. Try saving it again.',
    'timeout': 'Timeout',
    'total_fare': 'Total fare',
    'unable_to_initiate_booking_right_now': 'Unable to initiate booking right now.',
    'unable_to_open_ride_details': 'Unable to open ride details',
    'unable_to_skip_rating_now': 'Unable to skip rating now.',
    'unable_to_submit_rating_now': 'Unable to submit rating now.',
    'stop_location': 'Stop location',
    'updating_address': 'Updating address...',
    'user_profile_updated_successfully': 'User profile updated successfully',
    'validation': 'Validation',
    'validation_id_missing_from_server_response': 'Validation id missing from server response.',
    'value0000000000000000': '0000 0000 0000 0000',
    'value255': '+255',
    'share': 'Share',
    'safety': 'Safety',
    'safety_options': 'Safety options',
    'safety_options_subtitle': 'Share your live location or reach emergency contacts if you need help.',
    'share_live_location': 'Share live location',
    'share_ride_status': 'Share ride status',
    'vehicle_type': 'Vehicle type',
    'verification_successful': 'Verification successful!',
    'otp_label': 'OTP',
    'otp_verification_failed': 'OTP verification failed',
    'verify_phone_number': 'Verify phone number',
    'view_ride': 'View ride',
    'active_ride_min_remains': '@minutes Min remains',
    'active_ride_more_count': '+@count more',
    'visa': 'VISA',
    'wallet': 'Wallet',
    'wallet_number_copied': 'Wallet number copied',
    'copied_to_clipboard': 'Copied to clipboard',
    'wallet_number_label': 'Wallet number',
    'wallet_reserved_balance': 'Reserved: @amount',
    'recent_transactions': 'Recent transactions',
    'recent_transaction_title': 'Recent transaction',
    'view_all': 'View all',
    'e_statement': 'E-Statement',
    'wallet_statement_emailed_success': 'Your wallet statement has been emailed to you.',
    'wallet_statement_email_failed': 'Could not email your wallet statement. Please try again.',
    'wallet_statement_range_capped_hint': 'The statement covers the last 30 days ending on the selected end date.',
    'no_transactions_yet': 'No transactions yet',
    'filter_all': 'All',
    'filter_received': 'Received',
    'filter_sent': 'Sent',
    'we_could_not_confirm_your_payment_block_please_try_again': 'We could not confirm your payment block. Please try again.',
    'we_ll_text_acode_to_verify_your_phone_number': 'We’ll text a code to verify your phone number',
    'we_will_notify_you_when_something_important_happens': 'We will notify you when something important happens.',
    'what_stood_out': 'What stood out?',
    'where_are_you_going': 'Where are you going?',
    'why_do_you_want_to_cancel': 'Why do you want to cancel?',
    'cancellation_fee_of': 'A cancellation fee of ',
    'will_be_charged_since_driver_on_way': ' will be charged since your driver is on the way.',
    'has_been_charged_period': ' has been charged.',
    'net_amount_refunded': 'Net amount refunded: ',
    'net_refund_of': 'A net amount of ',
    'has_been_refunded_period': ' has been refunded.',
    'yes': 'Yes',
    'yes_cancel': 'YES, CANCEL',
    'you_can_still_able_to_request_money_on_selcom_pesa_using_another_number': 'You can still able to request money on SelcomPesa using another number.',
    'your_card_has_been_nadded_successfully': 'Your card has been added successfully.',
    'your_driver_is_already_on_the_way': 'Your driver is already on the way.',
    'your_identity_has_been_successfully_verified_you_can_now_use_selcom_pesa': 'Your identity has been successfully verified. You can now use SelcomPesa.',
    'your_rating_has_been_submitted': 'Your rating has been submitted.',
    'your_ride_was_cancelled': 'Your ride was cancelled.',
    'thanks_for_using_go': 'Thanks for using Go!',
    'your_rides': 'Your rides',
    'welcome_to_selcom_go': 'Welcome to Selcom Go',
    'full_name': 'Full name',
    'enter_your_full_name': 'Enter your full name',
    'email': 'Email',
    'enter_your_email': 'Enter your email',
    'email_is_required': 'Email is required',
    'your_selfie_will_be_captured_to_help_us_validate_you_against_your_id_please_hold_your':
        'Your selfie will be captured to help us validate you against your ID. Please hold your phone steady, ensure your face is within the circular frame, and follow the prompts.',
    'your_session_has_expired_please_login_again_to_continue': 'Your session has expired. Please login again to continue.',
    'language': 'Language',
    'english': 'English',
    'swahili': 'Swahili',
    'switched_to_english': 'Switched to English',
    'switched_to_swahili': 'Switched to Swahili',
    'exit_app': 'Exit app',
    'exit_app_message': 'Are you sure, you want to exit the app?',
    'card_delete_warning_description':
        'This action will remove the card from your account, and you will need to add it again if you want to use it in the future.',
    'no_cancel': 'No, cancel',
    'expiry': 'Expiry',
    'cvv': 'CVV',
    'please_enter_your_phone_number': 'Please enter your phone number',
    'please_provide_email_or_phone': 'Please provide an email or phone number so we can reach you',
    'please_enter_a_valid_phone_number': 'Please enter a valid phone number',
    'selcom_pesa_link_request_sent_message':
        'A link request was sent to @phoneNumber. Please open SelcomPesa and approve it to connect your account.',
    'selcom_pesa_already_linked_message': '@phoneNumber is already linked to your Selcom Go account.',
    'selcom_pesa_max_linked_accounts': 'You can link up to @max SelcomPesa accounts.',
    'selcom_pesa_multiple_linked': '@count linked SelcomPesa accounts',
    'require_verification_pin_before_starting_ride': 'Require a verification PIN before starting a ride.',
    'ride_pin_required_by_admin_cannot_be_turned_off': 'Ride PIN is required by admin and cannot be turned off.',
    'current_status_required': 'Current status: required',
    'current_status_optional': 'Current status: optional',
    'error_picking_image': 'Error picking image: @error',
    'are_you_sure_you_want_to_logout_from_the_app': 'Are you sure, you want to logout from the app?',
    'please_select_a_reason': 'Please select a reason',
    'please_enter_a_message': 'Please enter a message',
    'user': 'User',
    'user_name': 'User name',
    'phone_number': 'Phone number',
    'add_new': 'Add new',
    'add_to_favourites': 'Add to favourites',
    'add_to_favourites_subtitle': 'Choose a label for this address or add your own.',
    'confirm': 'Confirm',
    'confirmation': 'Confirmation',
    'home': 'Home',
    'minutes_count': '@count minutes',
    'pin_locked_message_retry_in_time': '@message. Please try again in @time.',
    'save_address': 'Save address',
    'save_location_as': 'Save location as',
    'work': 'Work',
    'office': 'Office',
    'other': 'Other',
    'info': 'Info',
    'enter_custom_label': 'Enter custom label',
    'connection_timed_out_please_check_internet': 'Connection timed out. Please check your internet.',
    'no_internet_connection': 'No internet connection',
    'session_expired_please_login_again': 'Session expired. Please login again.',
    'session_expired_refreshing': 'Session expired. Refreshing...',
    'social_login_subtitle': 'Create an account or log in to explore our app',
    'request_queue_full_please_try_again_later': 'Request queue is full. Please try again later.',
    'request_queue_cleared': 'Request queue cleared',
    'search_ended': 'Search ended',
    'search_timeout_no_driver_found': 'Search timeout: no driver found',
    'send_timeout': 'Send timeout',
    'receive_timeout': 'Receive timeout',
    'bad_response_from_server': 'Bad response from server',
    'bad_request': 'Bad request',
    'unauthorized': 'Unauthorized',
    'connection_timeout': 'Connection timeout',
    'server_error_with_status': 'Server Error (@statusCode)',
    'request_cancelled': 'Request cancelled',
    'network_is_unreachable': 'Network is unreachable',
    'no_internet_or_unexpected_error': 'No internet or unexpected error',
    'unexpected_network_error': 'Unexpected network error',
    'server_taking_too_long_please_try_again': 'Server is taking too long to respond. Please try again.',
    'server_timeout': 'Server timeout',
    'you_already_have_an_active_ride': 'You already have an active ride.',
    'insufficient_funds_in_wallet': 'Insufficient funds in wallet.',
    'something_went_wrong_please_try_again': 'Something went wrong. Please try again.',
    'unexpected_error_occurred_with_error': 'Unexpected error occurred: @error',
    'invalid_otp': 'Invalid OTP.',
    'add_stop': 'Add stop',
    'back_to_home': 'Back to home',
    'booking': 'Booking',
    'booking_failed': 'Booking failed',
    'card_expired': 'Expired',
    'cards': 'Cards',
    'chat_unavailable': 'Chat unavailable',
    'confirm_and_update': 'Confirm & update',
    'confirm_stop': 'Confirm stop',
    'connect_selcom_pesa_ride_charges_subtitle': 'Connect your SelcomPesa account to enable automatic, seamless ride charge deductions.',
    'could_not_refresh_fare_after_pickup': 'Could not refresh fare after pickup confirmation.',
    'current_destination': 'Current destination',
    'display_name_ride': 'Ride',
    'eta_badge': 'ETA',
    'fare_difference': 'Fare difference:',
    'fare_increase_payment_authorization': 'Fare increase will require a payment authorization.',
    'max_stops_only': 'You can add up to @count stops only.',
    'microphone_permission_denied_open_settings': 'Microphone permission is permanently denied. Open Settings to allow it.',
    'microphone_permission_required': 'Microphone permission is required to place a call.',
    'new_destination': 'New destination',
    'new_estimated_fare': 'New estimated fare:',
    'payment_methods_title': 'Payment methods',
    'receipt_saved_to_gallery': 'Receipt saved to your photos gallery.',
    'ride_created_missing_id': 'Ride was created but ride id is missing from the response.',
    'search_again': 'Search again',
    'selected_location': 'Selected location',
    'selected_pickup_point': 'Selected pickup point',
    'selcom_pesa_linked_number': 'Linked number @number',
    'stop_number': 'Stop @number',
    'update_destination': 'Update destination',
    'update_ride': 'Update ride',
    'write_a_message': 'Write a message...',
    'your_driver': 'Your driver',
    'incorrect_pin': 'Incorrect PIN.',
    'selcom_pesa_link_number': '+ Link number',
    'selcom_pesa_self_title': 'Self',
    'selcom_pesa_self_subtitle': 'Enter amount and redirect to SelcomPesa',
    'selcom_pesa_other_title': 'Other',
    'selcom_pesa_other_subtitle': 'Enter mobile number and amount',
    'remove_account_title': 'Remove account',
    'remove_account_message': 'Are you sure you want to remove this SelcomPesa account?',
    'remove_label': 'Remove',
    'saved_card_label': 'Saved card',
    'no_saved_cards_found': 'No saved cards found',
    'amount_is_required': 'Amount is required',
    'enter_valid_amount': 'Please enter a valid amount',
    'add_card_minimum_amount': 'Minimum amount is TZS @amount',
    'set_as_default': 'Set as default',
    'set_as_default_confirm': 'Make this your default account for transactions',
    'default_account_set_successfully': 'Default account updated successfully',
    'card_information': 'Card information',
    'first_name': 'First name',
    'last_name': 'Last name',
    'billing_details': 'Billing details',
    'billing_details_subtitle': 'Please provide your billing address as per your bank records',
    'country': 'Country',
    'state': 'State',
    'select_state': 'Select state',
    'address': 'Address',
    'city': 'City',
    'postal_code': 'Postal code',
    'eg_user_email': 'e.g. user@example.com',
    'street_name_house_number': 'Street name / house number',
    'eg_dar_es_salaam': 'e.g. Dar es Salaam',
    'eg_postal_code': 'e.g. 14110',
    'first_name_is_required': 'First name is required',
    'last_name_is_required': 'Last name is required',
    'card_number_is_required': 'Card number is required',
    'enter_valid_card_number': 'Enter a valid card number',
    'expiry_is_required': 'Expiry is required',
    'enter_valid_expiry_date': 'Enter a valid expiry date',
    'cvv_is_required': 'CVV is required',
    'cvv_must_be_3_digits': 'CVV must be 3 digits',
    'country_is_required': 'Country is required',
    'state_is_required': 'State is required',
    'phone_number_is_required': 'Phone number is required',
    'invalid_phone_number_for_country': 'Invalid phone number for @country',
    'address_is_required': 'Address is required',
    'city_is_required': 'City is required',
    'postal_code_is_required': 'Postal code is required',
    'invalid_session_response_from_server': 'Invalid session response from server.',
    'help_selcom_go_do_better_by_rating_this_trip':
        'Help Selcom Go do better by rating this trip',
    'no_fare_estimate_returned_for_the_updated_pickup_location':
        'No fare estimate returned for the updated pickup location.',
    'please_enter_the4_digit_code_sent_to_phone_through_sms':
        'Please enter the 4-digit code sent to \n@countryCode @phoneNumber through SMS',
  };

  @override
  String get codeNotExist => values['code_not_exist'] ?? '';

  @override
  String get accountUnlinkedSuccessfully =>
      values['account_unlinked_successfully'] ?? '';

  @override
  String get add => values['add'] ?? '';

  @override
  String get addASavedPlace => values['add_asaved_place'] ?? '';

  @override
  String get addDebitCreditCard => values['add_debit_credit_card'] ?? '';

  @override
  String get addNewCard => values['add_new_card'] ?? '';

  @override
  String get addCard => values['add_card'] ?? '';

  @override
  String get addressMissing => values['address_missing'] ?? '';

  @override
  String get anUnexpectedErrorOccurred =>
      values['an_unexpected_error_occurred'] ?? '';

  @override
  String get apply => values['apply'] ?? '';

  @override
  String get areYouSureWantToAddNdeleteThisCard =>
      values['are_you_sure_want_to_add_ndelete_this_card'] ?? '';

  @override
  String get areYouSureYouWantToCancel =>
      values['are_you_sure_you_want_to_cancel'] ?? '';

  @override
  String get bookRide => values['book_ride'] ?? '';

  @override
  String get bookAny => values['book_any'] ?? '';

  @override
  String get bookRideWalletDeductionNotice =>
      values['book_ride_wallet_deduction_notice'] ?? '';

  @override
  String get insufficientBalanceTitle =>
      values['insufficient_balance_title'] ?? '';

  @override
  String get insufficientBalanceMessage =>
      values['insufficient_balance_message'] ?? '';

  @override
  String get currentBalanceLabel => values['current_balance_label'] ?? '';

  @override
  String get requiredAmountLabel => values['required_amount_label'] ?? '';

  @override
  String get amountNeededLabel => values['amount_needed_label'] ?? '';

  @override
  String get topUpWallet => values['top_up_wallet'] ?? '';

  @override
  String get addMoneyToWallet => values['add_money_to_wallet'] ?? '';

  @override
  String get addMoney => values['add_money'] ?? '';

  @override
  String get amount => values['amount'] ?? '';

  @override
  String get back => values['back'] ?? '';

  @override
  String get walletFundsReceivedTitle =>
      values['wallet_funds_received_title'] ?? '';

  @override
  String get walletFundsReceivedSubtitle =>
      values['wallet_funds_received_subtitle'] ?? '';

  @override
  String get topUpRequestSentTitle => values['top_up_request_sent_title'] ?? '';

  @override
  String get mobileMoneyRequestSentTitle =>
      values['mobile_money_request_sent_title'] ?? '';

  @override
  String get mobileMoneyRequestSentMessage =>
      values['mobile_money_request_sent_message'] ?? '';

  @override
  String get selcomPesaToGoWallet => values['selcom_pesa_to_go_wallet'] ?? '';

  @override
  String get enterSelcomPesaCustomerPhoneHint =>
      values['enter_selcom_pesa_customer_phone_hint'] ?? '';

  @override
  String get requestSentCompleteSelcomTopup =>
      values['request_sent_complete_selcom_topup'] ?? '';

  @override
  String get expiresInWithTime => values['expires_in_with_time'] ?? '';

  @override
  String get walletTopUpAmountRequired =>
      values['wallet_topup_amount_required'] ?? '';

  @override
  String get walletTopUpAmountMustBeGreaterThanZero =>
      values['wallet_topup_amount_must_be_greater_than_zero'] ?? '';

  @override
  String get walletTopUpAmountExceedsMax =>
      values['wallet_topup_amount_exceeds_max'] ?? '';

  @override
  String get walletTopUpRequestFailed =>
      values['wallet_topup_request_failed'] ?? '';

  @override
  String get walletTopUpTimerExpiredTitle =>
      values['wallet_topup_timer_expired_title'] ?? '';

  @override
  String get walletTopUpTimerExpiredMessage =>
      values['wallet_topup_timer_expired_message'] ?? '';

  @override
  String get walletTopUpCancelRequest =>
      values['wallet_topup_cancel_request'] ?? '';

  @override
  String get selcomPesaAppNotInstalled =>
      values['selcom_pesa_app_not_installed'] ?? '';

  @override
  String get selcomPesaInstallPrompt =>
      values['selcom_pesa_install_prompt'] ?? '';

  @override
  String get selcomPesaHandoffFailed =>
      values['selcom_pesa_handoff_failed'] ?? '';

  @override
  String get selcomPesaStatusNotFound =>
      values['selcom_pesa_status_not_found'] ?? '';

  @override
  String get selcomPesaPaymentRejected =>
      values['selcom_pesa_payment_rejected'] ?? '';

  @override
  String get selcomPesaPaymentProcessing =>
      values['selcom_pesa_payment_processing'] ?? '';

  @override
  String get walletAccountUnavailable =>
      values['wallet_account_unavailable'] ?? '';

  @override
  String get downloadApp => values['download_app'] ?? '';

  @override
  String get selectAVehicle => values['select_a_vehicle'] ?? '';

  @override
  String get bookingForName => values['booking_for_name'] ?? '';

  @override
  String get bookingForSomeoneElsePrompt =>
      values['booking_for_someone_else_prompt'] ?? '';

  @override
  String get bookingForSomeoneElseSubtitle =>
      values['booking_for_someone_else_subtitle'] ?? '';

  @override
  String get bookingRideOptionForMe =>
      values['booking_ride_option_for_me'] ?? '';

  @override
  String get bookingRideOptionForSomeoneElse =>
      values['booking_ride_option_for_someone_else'] ?? '';

  @override
  String get onboardingFooterLead =>
      values['onboarding_footer_lead'] ?? '';

  @override
  String get onboardingFooterTermsLink =>
      values['onboarding_footer_terms_link'] ?? '';

  @override
  String get onboardingFooterJoiner => values['onboarding_footer_joiner'] ?? '';

  @override
  String get call => values['call'] ?? '';

  @override
  String get callDriver => values['call_driver'] ?? '';

  @override
  String get callDriverSheetSubtitle =>
      values['call_driver_sheet_subtitle'] ?? '';

  @override
  String get contactsPermission => values['contacts_permission'] ?? '';

  @override
  String get contactsAccessNeeded => values['contacts_access_needed'] ?? '';

  @override
  String get cancelAndPay => values['cancel_and_pay'] ?? '';

  @override
  String get cancelFailed => values['cancel_failed'] ?? '';

  @override
  String get cancelRide => values['cancel_ride'] ?? '';

  @override
  String get cancel => values['cancel'] ?? '';

  @override
  String get cancelled => values['cancelled'] ?? '';

  @override
  String get cardNumber => values['card_number'] ?? '';

  @override
  String get changeDropLocation => values['change_drop_location'] ?? '';

  @override
  String get addStops => values['add_stops'] ?? '';

  @override
  String get changeLocation => values['change_location'] ?? '';

  @override
  String get chat => values['chat'] ?? '';

  @override
  String get chatIsOnlyAvailableDuringAnActiveRide =>
      values['chat_is_only_available_during_an_active_ride'] ?? '';

  @override
  String get checkYourPickupPoint => values['check_your_pickup_point'] ?? '';

  @override
  String get chooseRide => values['choose_ride'] ?? '';

  @override
  String get confirmPickup => values['confirm_pickup'] ?? '';

  @override
  String get connectionError => values['connection_error'] ?? '';

  @override
  String get contactUs => values['contact_us'] ?? '';

  @override
  String get contactSupport => values['contact_support'] ?? '';

  @override
  String get requestToCancel => values['request_to_cancel'] ?? '';

  @override
  String get requestCancellationSubtitle =>
      values['request_cancellation_subtitle'] ?? '';

  @override
  String get submitRequest => values['submit_request'] ?? '';

  @override
  String get optionalDetails => values['optional_details'] ?? '';

  @override
  String get describeWhatHappenedHint =>
      values['describe_what_happened_hint'] ?? '';

  @override
  String get withdrawRequest => values['withdraw_request'] ?? '';

  @override
  String get cancellationRequestSentWithTicket =>
      values['cancellation_request_sent_with_ticket'] ?? '';

  @override
  String get supportDeclinedCancellation =>
      values['support_declined_cancellation'] ?? '';

  @override
  String get couldNotSubmitCancellationRequest =>
      values['could_not_submit_cancellation_request'] ?? '';

  @override
  String get couldNotWithdrawCancellationRequest =>
      values['could_not_withdraw_cancellation_request'] ?? '';

  @override
  String get couldNotLoadCancellationReasons =>
      values['could_not_load_cancellation_reasons'] ?? '';

  @override
  String get rideNotActiveRefresh => values['ride_not_active_refresh'] ?? '';

  @override
  String get cancellationRequestAlreadyDecided =>
      values['cancellation_request_already_decided'] ?? '';

  @override
  String get cancellationRequestAlreadyPending =>
      values['cancellation_request_already_pending'] ?? '';

  @override
  String get backOnRoute => values['back_on_route'] ?? '';

  @override
  String get continueToTrip => values['continue_to_trip'] ?? '';

  @override
  String get continueLabel => values['continue'] ?? '';

  @override
  String get signInWithGoogle => values['sign_in_with_google'] ?? '';

  @override
  String get didntReceiveTheCode => values['didnt_receive_the_code'] ?? '';

  @override
  String get couldNotCancelTryAgain =>
      values['could_not_cancel_try_again'] ?? '';

  @override
  String get couldNotResolveVehicleTypeIdPleaseTryAgain =>
      values['could_not_resolve_vehicle_type_id_please_try_again'] ?? '';

  @override
  String get couldNotValidatePaymentPleaseTryAgain =>
      values['could_not_validate_payment_please_try_again'] ?? '';

  @override
  String get defaultCurrencyTzs => values['default_currency_tzs'] ?? '';

  @override
  String get deleteCard => values['delete_card'] ?? '';

  @override
  String
  get doNotShareYourPersonalDetailsWithRiderBeSafeAndAlwaysCheckYourLuggage =>
      values['do_not_share_your_personal_details_with_rider_be_safe_and_always_check_your_luggage'] ??
      '';

  @override
  String get done => values['done'] ?? '';

  @override
  String get downloadSlip => values['download_slip'] ?? '';

  @override
  String get downloadSlipGallerySubtitle =>
      values['download_slip_gallery_subtitle'] ?? '';

  @override
  String get chooseHowToReceiveReceipt =>
      values['choose_how_to_receive_receipt'] ?? '';

  @override
  String get receiptOptions => values['receipt_options'] ?? '';

  @override
  String get shareSlip => values['share_slip'] ?? '';

  @override
  String get shareSlipSubtitle => values['share_slip_subtitle'] ?? '';

  @override
  String get driverArrivedMapBadge => values['driver_arrived_map_badge'] ?? '';

  @override
  String get mapSatelliteView => values['map_satellite_view'] ?? '';

  @override
  String get mapStandardView => values['map_standard_view'] ?? '';

  @override
  String get driverArrivedPickupPrimary =>
      values['driver_arrived_pickup_primary'] ?? '';

  @override
  String get yourDriverHasArrived => values['your_driver_has_arrived'] ?? '';

  @override
  String get driverIsHeadingToYourLocation =>
      values['driver_is_heading_to_your_location'] ?? '';

  @override
  String get driverHeadingTowardsYou =>
      values['driver_heading_towards_you'] ?? '';

  @override
  String get driverAssignedDescription =>
      values['driver_assigned_description'] ?? '';

  @override
  String get driverHasAcceptedYourRide =>
      values['driver_has_accepted_your_ride'] ?? '';

  @override
  String get driverArrivedDescription =>
      values['driver_arrived_description'] ?? '';

  @override
  String get rideStartedDescription => values['ride_started_description'] ?? '';

  @override
  String get findingYourDriver => values['finding_your_driver'] ?? '';

  @override
  String get findingDriverDefaultDescription =>
      values['finding_driver_default_description'] ?? '';

  @override
  String get findingDriverMinutesRemain =>
      values['finding_driver_minutes_remain'] ?? '';

  @override
  String get driverWillArrivingInMinutes =>
      values['driver_will_arriving_in_minutes'] ?? '';

  @override
  String get driverFinishingNearbyTrip =>
      values['driver_finishing_nearby_trip'] ?? '';

  @override
  String get driverEnRoute => values['driver_en_route'] ?? '';

  @override
  String get driverArrived => values['driver_arrived'] ?? '';

  @override
  String get eG123 => values['e_g123'] ?? '';

  @override
  String get eG7XxXxxXxx => values['e_g7_xx_xxx_xxx'] ?? '';

  @override
  String get eGJohnDoe => values['e_gjohn_doe'] ?? '';

  @override
  String get editYourPhoneNumber => values['edit_your_phone_number'] ?? '';

  @override
  String get enterPhoneNumber => values['enter_phone_number'] ?? '';

  @override
  String get enterPhoneNumberForVerification =>
      values['enter_phone_number_for_verification'] ?? '';

  @override
  String get enterPromoCode => values['enter_promo_code'] ?? '';

  @override
  String get enterPromocode => values['enter_promocode'] ?? '';

  @override
  String get enterYourSelcomPesaNumber =>
      values['enter_your_selcom_pesa_number'] ?? '';

  @override
  String get error => values['error'] ?? '';

  @override
  String get errorOpeningPhoneDialer =>
      values['error_opening_phone_dialer'] ?? '';

  @override
  String get errorSendingMessage => values['error_sending_message'] ?? '';

  @override
  String get estimateFailed => values['estimate_failed'] ?? '';

  @override
  String get etaMinutesAwayDropTime =>
      values['eta_minutes_away_drop_time'] ?? '';

  @override
  String get etaMinutesAwayOnly => values['eta_minutes_away_only'] ?? '';

  @override
  String get dropAtTime => values['drop_at_time'] ?? '';

  @override
  String get exploreVehicle => values['explore_vehicle'] ?? '';

  @override
  String get minutesAgo => values['minutes_ago'] ?? '';

  @override
  String get hoursAgo => values['hours_ago'] ?? '';

  @override
  String get daysAgo => values['days_ago'] ?? '';

  @override
  String get daysLeftCount => values['days_left_count'] ?? '';

  @override
  String get requestSentPleaseCompletePaymentOnSelcomPesaToBookYourRide =>
      values['request_sent_please_complete_payment_on_selcom_pesa_to_book_your_ride'] ??
      '';

  @override
  String get thankYouForRidingWithUsSeeYouOnTheNextTrip =>
      values['thank_you_for_riding_with_us_see_you_on_the_next_trip'] ?? '';

  @override
  String get fare => values['fare'] ?? '';

  @override
  String get failedToSendMessage => values['failed_to_send_message'] ?? '';

  @override
  String get failedToLoadSettings => values['failed_to_load_settings'] ?? '';

  @override
  String get failedToLoadRidePinPreference =>
      values['failed_to_load_ride_pin_preference'] ?? '';

  @override
  String get failedToUpdateRidePinPreference =>
      values['failed_to_update_ride_pin_preference'] ?? '';

  @override
  String get failedToResendOtp => values['failed_to_resend_otp'] ?? '';

  @override
  String get failedToSendOtp => values['failed_to_send_otp'] ?? '';

  @override
  String get fallbackRideName => values['fallback_ride_name'] ?? '';

  @override
  String get getStarted => values['get_started'] ?? '';

  @override
  String get homeLabel => values['home_label'] ?? '';

  @override
  String get haventGotTheConfirmationCodeYet =>
      values['havent_got_the_confirmation_code_yet'] ?? '';

  @override
  String get gotIt => values['got_it'] ?? '';

  @override
  String get googleSignInCancelled => values['google_sign_in_cancelled'] ?? '';

  @override
  String get googleSignInFailed => values['google_sign_in_failed'] ?? '';

  @override
  String get signInWithApple => values['sign_in_with_apple'] ?? '';

  @override
  String get appleSignInCancelled => values['apple_sign_in_cancelled'] ?? '';

  @override
  String get appleSignInFailed => values['apple_sign_in_failed'] ?? '';

  @override
  String get appleSignInAccountExists =>
      values['apple_sign_in_account_exists'] ?? '';

  @override
  String get signInWithFacebook => values['sign_in_with_facebook'] ?? '';

  @override
  String get facebookSignInCancelled => values['facebook_sign_in_cancelled'] ?? '';

  @override
  String get facebookSignInFailed => values['facebook_sign_in_failed'] ?? '';

  @override
  String get help => values['help'] ?? '';

  @override
  String get havingTroubleLoggingIn =>
      values['having_trouble_logging_in'] ?? '';

  @override
  String get howCanWeHelpYou => values['how_can_we_help_you'] ?? '';

  @override
  String get howDoYouRateTheDriver =>
      values['how_do_you_rate_the_driver'] ?? '';

  @override
  String get howWasYourRide => values['how_was_your_ride'] ?? '';

  @override
  String get includesStopFee => values['includes_stop_fee'] ?? '';

  @override
  String get keepRide => values['keep_ride'] ?? '';

  @override
  String get linkAccount => values['link_account'] ?? '';

  @override
  String get location => values['location'] ?? '';

  @override
  String get locating => values['locating'] ?? '';

  @override
  String get locatingDriver => values['locating_driver'] ?? '';

  @override
  String get currentLocation => values['current_location'] ?? '';

  @override
  String get saved => values['saved'] ?? '';

  @override
  String get savedPlace => values['saved_place'] ?? '';

  @override
  String get savedPlaces => values['saved_places'] ?? '';

  @override
  String get recentLocations => values['recent_locations'] ?? '';

  @override
  String get searchTag => values['search_tag'] ?? '';

  @override
  String get recentTag => values['recent_tag'] ?? '';

  @override
  String get savedTag => values['saved_tag'] ?? '';

  @override
  String get loadingYourProfile => values['loading_your_profile'] ?? '';

  @override
  String get locationSelection => values['location_selection'] ?? '';

  @override
  String get locationUnavailable => values['location_unavailable'] ?? '';

  @override
  String get login => values['login'] ?? '';

  @override
  String get logout => values['logout'] ?? '';

  @override
  String get loremIpsumDolorSitAmetConsectetur =>
      values['lorem_ipsum_dolor_sit_amet_consectetur'] ?? '';

  @override
  String get makingYourDriveBestIsOurResponsibility =>
      values['making_your_drive_best_is_our_responsibility'] ?? '';

  @override
  String get maybeLater => values['maybe_later'] ?? '';

  @override
  String get markAllReadCount => values['mark_all_read_count'] ?? '';

  @override
  String get message => values['message'] ?? '';

  @override
  String get missingInfo => values['missing_info'] ?? '';

  @override
  String get missingRideInformation => values['missing_ride_information'] ?? '';

  @override
  String get mmYy => values['mm_yy'] ?? '';

  @override
  String get myRides => values['my_rides'] ?? '';

  @override
  String get nameCannotBeEmpty => values['name_cannot_be_empty'] ?? '';

  @override
  String get nameIsRequired => values['name_is_required'] ?? '';

  @override
  String get needHelp => values['need_help'] ?? '';

  @override
  String get newMessage => values['new_message'] ?? '';

  @override
  String get no => values['no'] ?? '';

  @override
  String get noDriverFoundForYourRequestPleaseTryAgain =>
      values['no_driver_found_for_your_request_please_try_again'] ?? '';

  @override
  String get noDriversNearbyPleaseTryAgainLater =>
      values['no_drivers_nearby_please_try_again_later'] ?? '';

  @override
  String get noFavoriteLocationsYet =>
      values['no_favorite_locations_yet'] ?? '';

  @override
  String get noLocationsFound => values['no_locations_found'] ?? '';

  @override
  String get noNotificationsYet => values['no_notifications_yet'] ?? '';

  @override
  String get noPastRidesFound => values['no_past_rides_found'] ?? '';

  @override
  String get noRecentLocationsFound =>
      values['no_recent_locations_found'] ?? '';

  @override
  String get noRecentLocations => values['no_recent_locations'] ?? '';

  @override
  String
  get noteByProceedingYouConsentToGetCallsWhatsappOrSmsMessagesIncludingByAu =>
      values['note_by_proceeding_you_consent_to_get_calls_whatsapp_or_sms_messages_including_by_au'] ??
      '';

  @override
  String get notificationPhoneRequired =>
      values['notification_phone_required'] ?? '';

  @override
  String get notificationPhoneSubtitle =>
      values['notification_phone_subtitle'] ?? '';

  @override
  String get enterPassengerFullName =>
      values['enter_passenger_full_name'] ?? '';

  @override
  String get passengerDetailsTitle => values['passenger_details_title'] ?? '';

  @override
  String get passengerNameLabel => values['passenger_name_label'] ?? '';

  @override
  String get passengerPhoneLabel => values['passenger_phone_label'] ?? '';

  @override
  String get notification => values['notification'] ?? '';

  @override
  String get notifications => values['notifications'] ?? '';

  @override
  String get ok => values['ok'] ?? '';

  @override
  String get orderLabelWithId => values['order_label_with_id'] ?? '';

  @override
  String get openSettings => values['open_settings'] ?? '';

  @override
  String get callNotificationPermissionMsg =>
      values['call_notification_permission_msg'] ?? '';

  @override
  String get callFullScreenPermissionMsg =>
      values['call_full_screen_permission_msg'] ?? '';

  @override
  String get pleaseEnterLabel => values['please_enter_label'] ?? '';

  @override
  String get past => values['past'] ?? '';

  @override
  String get payment => values['payment'] ?? '';

  @override
  String get paymentNotConfirmed => values['payment_not_confirmed'] ?? '';

  @override
  String get bookRidePaymentNotAppliedTitle =>
      values['book_ride_payment_not_applied_title'] ?? '';

  @override
  String get bookRidePaymentNotAppliedMessage =>
      values['book_ride_payment_not_applied_message'] ?? '';

  @override
  String get paymentValidationFailed =>
      values['payment_validation_failed'] ?? '';

  @override
  String get phoneNumberUnavailable => values['phone_number_unavailable'] ?? '';

  @override
  String get phoneWithNumber => values['phone_with_number'] ?? '';

  @override
  String get pickAnyTagsThatMatchThisTrip =>
      values['pick_any_tags_that_match_this_trip'] ?? '';

  @override
  String get pickup => values['pickup'] ?? '';

  @override
  String get pickupPoint => values['pickup_point'] ?? '';

  @override
  String get pickupConfirmationNoteLabel =>
      values['pickup_confirmation_note_label'] ?? '';

  @override
  String get pickupConfirmationNoteHint =>
      values['pickup_confirmation_note_hint'] ?? '';

  @override
  String get pin => values['pin'] ?? '';

  @override
  String get pinLocked => values['pin_locked'] ?? '';

  @override
  String get pleaseConfirmPickupPointToContinue =>
      values['please_confirm_pickup_point_to_continue'] ?? '';

  @override
  String get pleaseEnterAPromoCode => values['please_enter_apromo_code'] ?? '';

  @override
  String get pleaseEnterAValidEmail =>
      values['please_enter_a_valid_email'] ?? '';

  @override
  String get pleaseEnterAValidName => values['please_enter_a_valid_name'] ?? '';

  @override
  String get pleaseEnterAtLeastOneDestination =>
      values['please_enter_at_least_one_destination'] ?? '';

  @override
  String get pleaseEnterYourCommentFirst =>
      values['please_enter_your_comment_first'] ?? '';

  @override
  String get pleaseRateYourRideBeforeSubmitting =>
      values['please_rate_your_ride_before_submitting'] ?? '';

  @override
  String get pleaseSelectAtLeastOneDestination =>
      values['please_select_at_least_one_destination'] ?? '';

  @override
  String get pleaseTellUsWhatWentWrongOrHowWeCanImprove =>
      values['please_tell_us_what_went_wrong_or_how_we_can_improve'] ?? '';

  @override
  String get privacyPolicy => values['privacy_policy'] ?? '';

  @override
  String get termsAndConditions => values['terms_and_conditions'] ?? '';

  @override
  String get paymentMethodWithName => values['payment_method_with_name'] ?? '';

  @override
  String get calculatingBestRoute => values['calculating_best_route'] ?? '';

  @override
  String get rideReceipt => values['ride_receipt'] ?? '';

  @override
  String get transactionIdWithValue =>
      values['transaction_id_with_value'] ?? '';

  @override
  String get route => values['route'] ?? '';

  @override
  String get dropoff => values['dropoff'] ?? '';

  @override
  String get emDash => values['em_dash'] ?? '';

  @override
  String get driverAndVehicle => values['driver_and_vehicle'] ?? '';

  @override
  String get driver => values['driver'] ?? '';

  @override
  String get model => values['model'] ?? '';

  @override
  String get colour => values['colour'] ?? '';

  @override
  String get plate => values['plate'] ?? '';

  @override
  String get fareBreakdown => values['fare_breakdown'] ?? '';

  @override
  String get thankYouForRidingWithSelcomGo =>
      values['thank_you_for_riding_with_selcom_go'] ?? '';

  @override
  String get mobileMoney => values['mobile_money'] ?? '';

  @override
  String get card => values['card'] ?? '';

  @override
  String get promocodeList => values['promocode_list'] ?? '';

  @override
  String get promotions => values['promotions'] ?? '';

  @override
  String get havePromoCode => values['have_promo_code'] ?? '';

  @override
  String get promoApplySuccessMessage =>
      values['promo_apply_success_message'] ?? '';

  @override
  String get promoRemovedTitle => values['promo_removed_title'] ?? '';

  @override
  String get promoRemovedDestinationChanged =>
      values['promo_removed_destination_changed'] ?? '';

  @override
  String get promoErrorInvalid => values['promo_error_invalid'] ?? '';

  @override
  String get promoErrorExpired => values['promo_error_expired'] ?? '';

  @override
  String get promoErrorNotApplicable =>
      values['promo_error_not_applicable'] ?? '';

  @override
  String get promoErrorNetwork => values['promo_error_network'] ?? '';

  @override
  String get promoNotAppliedTitle => values['promo_not_applied_title'] ?? '';

  @override
  String get promoCodeNotValidForVehicle =>
      values['promo_code_not_valid_for_vehicle'] ?? '';

  @override
  String get promoAutoAppliedBadge => values['promo_auto_applied_badge'] ?? '';

  @override
  String get promoCashbackAmount => values['promo_cashback_amount'] ?? '';

  @override
  String get rideFreeLabel => values['ride_free_label'] ?? '';

  @override
  String get promoMinRideAmount => values['promo_min_ride_amount'] ?? '';

  @override
  String get promoExpiresToday => values['promo_expires_today'] ?? '';

  @override
  String get noAvailablePromoCodes => values['no_available_promo_codes'] ?? '';

  @override
  String get failedToLoadPromoCodes =>
      values['failed_to_load_promo_codes'] ?? '';

  @override
  String get promoAutoApplyListBadge =>
      values['promo_auto_apply_list_badge'] ?? '';

  @override
  String get rating => values['rating'] ?? '';

  @override
  String get ratingRequired => values['rating_required'] ?? '';

  @override
  String get reasonToContact => values['reason_to_contact'] ?? '';

  @override
  String get recentLocation => values['recent_location'] ?? '';

  @override
  String get remove => values['remove'] ?? '';

  @override
  String get removeSavedAddress => values['remove_saved_address'] ?? '';

  @override
  String get areYouSureYouWantToRemoveThisSavedAddress =>
      values['are_you_sure_you_want_to_remove_this_saved_address'] ?? '';

  @override
  String get resendCode => values['resend_code'] ?? '';

  @override
  String get retry => values['retry'] ?? '';

  @override
  String get rideCancelled => values['ride_cancelled'] ?? '';

  @override
  String get tripEndedByDriver => values['trip_ended_by_driver'] ?? '';

  @override
  String get midRideSorrySubtitle => values['mid_ride_sorry_subtitle'] ?? '';

  @override
  String get midRideReasonLead => values['mid_ride_reason_lead'] ?? '';

  @override
  String get midRideCancelledByDriverPartialCharge =>
      values['mid_ride_cancelled_by_driver_partial_charge'] ?? '';

  @override
  String get midRideReasonVehicleBreakdown =>
      values['mid_ride_reason_vehicle_breakdown'] ?? '';

  @override
  String get midRideReasonAccident => values['mid_ride_reason_accident'] ?? '';

  @override
  String get midRideReasonUnsafe => values['mid_ride_reason_unsafe'] ?? '';

  @override
  String get midRideReasonOther => values['mid_ride_reason_other'] ?? '';

  @override
  String get driverStartedYourRide => values['driver_started_your_ride'] ?? '';

  @override
  String get rideCompleted => values['ride_completed'] ?? '';

  @override
  String get theRideHasBeenCancelled =>
      values['the_ride_has_been_cancelled'] ?? '';

  @override
  String get youHaveReachedYourDestination =>
      values['you_have_reached_your_destination'] ?? '';

  @override
  String get youHaveArrived => values['you_have_arrived'] ?? '';

  @override
  String get youAreAlmostThere => values['you_are_almost_there'] ?? '';

  @override
  String get onYourWayWithDriver => values['on_your_way_with_driver'] ?? '';

  @override
  String get arrivedInMinutes => values['arrived_in_minutes'] ?? '';

  @override
  String get approachingYourDestination =>
      values['approaching_your_destination'] ?? '';

  @override
  String get headingToYourDestination =>
      values['heading_to_your_destination'] ?? '';

  @override
  String get tripHasStarted => values['trip_has_started'] ?? '';

  @override
  String get nearby => values['nearby'] ?? '';

  @override
  String get arriving => values['arriving'] ?? '';

  @override
  String get driverIsArriving => values['driver_is_arriving'] ?? '';

  @override
  String get weCouldntFindADriverNearby =>
      values['we_couldnt_find_a_driver_nearby'] ?? '';

  @override
  String get rideDataIsUnavailable => values['ride_data_is_unavailable'] ?? '';

  @override
  String get rideIdIsMissing => values['ride_id_is_missing'] ?? '';

  @override
  String get destination => values['destination'] ?? '';

  @override
  String get arrivedIn => values['arrived_in'] ?? '';

  @override
  String get minutesShortCount => values['minutes_short_count'] ?? '';

  @override
  String get someone => values['someone'] ?? '';

  @override
  String get couldNotFetchReceiptDetails =>
      values['could_not_fetch_receipt_details'] ?? '';

  @override
  String get rideDetailsAreMissing => values['ride_details_are_missing'] ?? '';

  @override
  String get failedToLoadRideDetails =>
      values['failed_to_load_ride_details'] ?? '';

  @override
  String get couldNotDownloadSlipPleaseTryAgainLater =>
      values['could_not_download_slip_please_try_again_later'] ?? '';

  @override
  String get checkOutMyRideReceiptShareUrl =>
      values['check_out_my_ride_receipt_share_url'] ?? '';

  @override
  String get selcomGoRideReceiptSubject =>
      values['selcom_go_ride_receipt_subject'] ?? '';

  @override
  String get couldNotShareSlipPleaseTryAgainLater =>
      values['could_not_share_slip_please_try_again_later'] ?? '';

  @override
  String get ridePinProtection => values['ride_pin_protection'] ?? '';

  @override
  String get safetyOptions => values['safety_options'] ?? '';

  @override
  String get safetyOptionsSubtitle => values['safety_options_subtitle'] ?? '';

  @override
  String get saveThisAddressFirstThenYouCanBookFromHere =>
      values['save_this_address_first_then_you_can_book_from_here'] ?? '';

  @override
  String get searchDestination => values['search_destination'] ?? '';

  @override
  String get searchLocation => values['search_location'] ?? '';

  @override
  String get searchPickup => values['search_pickup'] ?? '';

  @override
  String get searchStopLocation => values['search_stop_location'] ?? '';

  @override
  String get inAppCalling => values['in_app_calling'] ?? '';

  @override
  String get inAppCallingSubtitle => values['in_app_calling_subtitle'] ?? '';

  @override
  String get normalCall => values['normal_call'] ?? '';

  @override
  String get normalCallSubtitle => values['normal_call_subtitle'] ?? '';

  @override
  String get updateFailed => values['update_failed'] ?? '';

  @override
  String get updateInProgress => values['update_in_progress'] ?? '';

  @override
  String get aPreviousUpdateIsStillBeingProcessed =>
      values['a_previous_update_is_still_being_processed'] ?? '';

  @override
  String get takingLongerThanExpected =>
      values['taking_longer_than_expected'] ?? '';

  @override
  String get theUpdateIsTakingSomeTimePleaseCheckBackShortly =>
      values['the_update_is_taking_some_time_please_check_back_shortly'] ?? '';

  @override
  String get paymentHoldUpdateFailedNoChargesApplied =>
      values['payment_hold_update_failed_no_charges_applied'] ?? '';

  @override
  String get driversAppCouldntBeUpdatedBillingAdjustedBack =>
      values['drivers_app_couldnt_be_updated_billing_adjusted_back'] ?? '';

  @override
  String
  get securityAndPreferenceControlsMoreSettingsWillAppearHereAsTheyAreEnable =>
      values['security_and_preference_controls_more_settings_will_appear_here_as_they_are_enable'] ??
      '';

  @override
  String get selcomPesa => values['selcom_pesa'] ?? '';

  @override
  String get selectANearbyPointForEasierPickup =>
      values['select_anearby_point_for_easier_pickup'] ?? '';

  @override
  String get selectCountry => values['select_country'] ?? '';

  @override
  String get selectCountrySubtitle => values['select_country_subtitle'] ?? '';

  @override
  String get searchCountry => values['search_country'] ?? '';

  @override
  String get noCountriesFound => values['no_countries_found'] ?? '';

  @override
  String get selectAReason => values['select_areason'] ?? '';

  @override
  String get selectAReasonSubtitle => values['select_a_reason_subtitle'] ?? '';

  @override
  String get sessionExpired => values['session_expired'] ?? '';

  @override
  String get settings => values['settings'] ?? '';

  @override
  String get skip => values['skip'] ?? '';

  @override
  String get skipFailed => values['skip_failed'] ?? '';

  @override
  String get stop => values['stop'] ?? '';

  @override
  String get startTypingPickup => values['start_typing_pickup'] ?? '';

  @override
  String get startTypingDestination => values['start_typing_destination'] ?? '';

  @override
  String get submitFailed => values['submit_failed'] ?? '';

  @override
  String get submit => values['submit'] ?? '';

  @override
  String get success => values['success'] ?? '';

  @override
  String get selectedAddress => values['selected_address'] ?? '';

  @override
  String get searchingForDriver => values['searching_for_driver'] ?? '';

  @override
  String get enableLocationService => values['enable_location_service'] ?? '';

  @override
  String get enableLocationServiceMessage =>
      values['enable_location_service_message'] ?? '';

  @override
  String get enableLocationServiceMessageIos =>
      values['enable_location_service_message_ios'] ?? '';

  @override
  String get locationPermissionDenied =>
      values['location_permission_denied'] ?? '';

  @override
  String get locationAccessRequired => values['location_access_required'] ?? '';

  @override
  String get locationPermissionDeniedOpenSettings =>
      values['location_permission_denied_open_settings'] ?? '';

  @override
  String get unableToEstimateFareForThisRoute =>
      values['unable_to_estimate_fare_for_this_route'] ?? '';

  @override
  String get distanceMinKm => values['distance_min_km'] ?? '';

  @override
  String get distanceMaxKm => values['distance_max_km'] ?? '';

  @override
  String get distanceKmFormat => values['distance_km_format'] ?? '';

  @override
  String get distance => values['distance'] ?? '';

  @override
  String get duration => values['duration'] ?? '';

  @override
  String get couldNotRemoveAddress => values['could_not_remove_address'] ?? '';

  @override
  String get viewMore => values['view_more'] ?? '';

  @override
  String get ongoing => values['ongoing'] ?? '';

  @override
  String get completed => values['completed'] ?? '';

  @override
  String get noDriverFound => values['no_driver_found'] ?? '';

  @override
  String get boda => values['boda'] ?? '';

  @override
  String get unknownLocation => values['unknown_location'] ?? '';

  @override
  String get activeRide => values['active_ride'] ?? '';

  @override
  String get bookedForOtherLimitReached =>
      values['booked_for_other_limit_reached'] ?? '';

  @override
  String get bookedForOtherNoMultiStop =>
      values['booked_for_other_no_multi_stop'] ?? '';

  @override
  String get bookAnyFareSettledTitle =>
      values['book_any_fare_settled_title'] ?? '';

  @override
  String get bookAnyFareSettledBlockedLead =>
      values['book_any_fare_settled_blocked_lead'] ?? '';

  @override
  String get bookAnyFareSettledMiddleWithVehicle =>
      values['book_any_fare_settled_middle_with_vehicle'] ?? '';

  @override
  String get bookAnyFareSettledMiddleNoVehicle =>
      values['book_any_fare_settled_middle_no_vehicle'] ?? '';

  @override
  String get bookAnyFareSettledReleasedTrail =>
      values['book_any_fare_settled_released_trail'] ?? '';

  @override
  String get bookAnyFareSettledFinalChargeLabel =>
      values['book_any_fare_settled_final_charge_label'] ?? '';

  @override
  String get unableToGetLocationCoordinates =>
      values['unable_to_get_location_coordinates'] ?? '';

  @override
  String get pleaseSelectValidPickupAndDestinationLocations =>
      values['please_select_valid_pickup_and_destination_locations'] ?? '';

  @override
  String get areYouSureYouWantToAddThisAddressAs =>
      values['are_you_sure_you_want_to_add_this_address_as'] ?? '';

  @override
  String get tellUsMoreAboutYourExperience =>
      values['tell_us_more_about_your_experience'] ?? '';

  @override
  String get thankYou => values['thank_you'] ?? '';

  @override
  String get thisIsSecondSlide => values['this_is_second_slide'] ?? '';

  @override
  String get thisIsThirdSlide => values['this_is_third_slide'] ?? '';

  @override
  String get thisSavedPlaceHasNoAddress =>
      values['this_saved_place_has_no_address'] ?? '';

  @override
  String get thisSavedPlaceIsMissingCoordinates =>
      values['this_saved_place_is_missing_coordinates'] ?? '';

  @override
  String get thisSavedPlaceIsMissingCoordinatesTrySavingItAgain =>
      values['this_saved_place_is_missing_coordinates_try_saving_it_again'] ??
      '';

  @override
  String get timeout => values['timeout'] ?? '';

  @override
  String get totalFare => values['total_fare'] ?? '';

  @override
  String get unableToInitiateBookingRightNow =>
      values['unable_to_initiate_booking_right_now'] ?? '';

  @override
  String get unableToOpenRideDetails =>
      values['unable_to_open_ride_details'] ?? '';

  @override
  String get unableToSkipRatingNow => values['unable_to_skip_rating_now'] ?? '';

  @override
  String get unableToSubmitRatingNow =>
      values['unable_to_submit_rating_now'] ?? '';

  @override
  String get updatingAddress => values['updating_address'] ?? '';

  @override
  String get userProfileUpdatedSuccessfully =>
      values['user_profile_updated_successfully'] ?? '';

  @override
  String get validation => values['validation'] ?? '';

  @override
  String get validationIdMissingFromServerResponse =>
      values['validation_id_missing_from_server_response'] ?? '';

  @override
  String get value0000000000000000 => values['value0000000000000000'] ?? '';

  @override
  String get value255 => values['value255'] ?? '';

  @override
  String get vehicleType => values['vehicle_type'] ?? '';

  @override
  String get verificationSuccessful => values['verification_successful'] ?? '';

  @override
  String get otpLabel => values['otp_label'] ?? '';

  @override
  String get otpVerificationFailed => values['otp_verification_failed'] ?? '';

  @override
  String get verifyPhoneNumber => values['verify_phone_number'] ?? '';

  @override
  String get viewRide => values['view_ride'] ?? '';

  @override
  String get activeRideMinRemains => values['active_ride_min_remains'] ?? '';

  @override
  String get activeRideMoreCount => values['active_ride_more_count'] ?? '';

  @override
  String get visa => values['visa'] ?? '';

  @override
  String get wallet => values['wallet'] ?? '';

  @override
  String get walletNumberCopied => values['wallet_number_copied'] ?? '';

  @override
  String get copiedToClipboard => values['copied_to_clipboard'] ?? '';

  @override
  String get walletNumberLabel => values['wallet_number_label'] ?? '';

  @override
  String get walletReservedBalance =>
      values['wallet_reserved_balance'] ?? '';

  @override
  String get recentTransactions => values['recent_transactions'] ?? '';

  @override
  String get recentTransactionTitle =>
      values['recent_transaction_title'] ?? '';

  @override
  String get viewAll => values['view_all'] ?? '';

  @override
  String get eStatement => values['e_statement'] ?? '';

  @override
  String get walletStatementEmailedSuccess =>
      values['wallet_statement_emailed_success'] ?? '';

  @override
  String get walletStatementEmailFailed =>
      values['wallet_statement_email_failed'] ?? '';

  @override
  String get walletStatementRangeCappedHint =>
      values['wallet_statement_range_capped_hint'] ?? '';

  @override
  String get noTransactionsYet => values['no_transactions_yet'] ?? '';

  @override
  String get filterAll => values['filter_all'] ?? '';

  @override
  String get filterReceived => values['filter_received'] ?? '';

  @override
  String get filterSent => values['filter_sent'] ?? '';

  @override
  String get weCouldNotConfirmYourPaymentBlockPleaseTryAgain =>
      values['we_could_not_confirm_your_payment_block_please_try_again'] ?? '';

  @override
  String get weLlTextACodeToVerifyYourPhoneNumber =>
      values['we_ll_text_acode_to_verify_your_phone_number'] ?? '';

  @override
  String get weWillNotifyYouWhenSomethingImportantHappens =>
      values['we_will_notify_you_when_something_important_happens'] ?? '';

  @override
  String get whatStoodOut => values['what_stood_out'] ?? '';

  @override
  String get whereAreYouGoing => values['where_are_you_going'] ?? '';

  @override
  String get whyDoYouWantToCancel => values['why_do_you_want_to_cancel'] ?? '';

  @override
  String get cancellationFeeOf => values['cancellation_fee_of'] ?? '';

  @override
  String get willBeChargedSinceDriverOnWay =>
      values['will_be_charged_since_driver_on_way'] ?? '';

  @override
  String get netAmountRefunded => values['net_amount_refunded'] ?? '';

  @override
  String get yes => values['yes'] ?? '';

  @override
  String get yesCancel => values['yes_cancel'] ?? '';

  @override
  String get youCanStillAbleToRequestMoneyOnSelcomPesaUsingAnotherNumber =>
      values['you_can_still_able_to_request_money_on_selcom_pesa_using_another_number'] ??
      '';

  @override
  String get yourCardHasBeenNaddedSuccessfully =>
      values['your_card_has_been_nadded_successfully'] ?? '';

  @override
  String get yourDriverIsAlreadyOnTheWay =>
      values['your_driver_is_already_on_the_way'] ?? '';

  @override
  String get yourIdentityHasBeenSuccessfullyVerifiedYouCanNowUseSelcomPesa =>
      values['your_identity_has_been_successfully_verified_you_can_now_use_selcom_pesa'] ??
      '';

  @override
  String get yourRatingHasBeenSubmitted =>
      values['your_rating_has_been_submitted'] ?? '';

  @override
  String get yourRideWasCancelled => values['your_ride_was_cancelled'] ?? '';

  @override
  String get thanksForUsingGo => values['thanks_for_using_go'] ?? '';

  @override
  String get yourRides => values['your_rides'] ?? '';

  @override
  String get welcomeToSelcomGo => values['welcome_to_selcom_go'] ?? '';

  @override
  String get fullName => values['full_name'] ?? '';

  @override
  String get enterYourFullName => values['enter_your_full_name'] ?? '';

  @override
  String get email => values['email'] ?? '';

  @override
  String get enterYourEmail => values['enter_your_email'] ?? '';

  @override
  String get emailIsRequired => values['email_is_required'] ?? '';

  @override
  String
  get yourSelfieWillBeCapturedToHelpUsValidateYouAgainstYourIdPleaseHoldYour =>
      values['your_selfie_will_be_captured_to_help_us_validate_you_against_your_id_please_hold_your'] ??
      '';

  @override
  String get yourSessionHasExpiredPleaseLoginAgainToContinue =>
      values['your_session_has_expired_please_login_again_to_continue'] ?? '';

  @override
  String get language => values['language'] ?? '';

  @override
  String get english => values['english'] ?? '';

  @override
  String get swahili => values['swahili'] ?? '';

  @override
  String get switchedToEnglish => values['switched_to_english'] ?? '';

  @override
  String get switchedToSwahili => values['switched_to_swahili'] ?? '';

  @override
  String get exitApp => values['exit_app'] ?? '';

  @override
  String get exitAppMessage => values['exit_app_message'] ?? '';

  @override
  String get cardDeleteWarningDescription =>
      values['card_delete_warning_description'] ?? '';

  @override
  String get noCancel => values['no_cancel'] ?? '';

  @override
  String get expiry => values['expiry'] ?? '';

  @override
  String get cvv => values['cvv'] ?? '';

  @override
  String get pleaseEnterYourPhoneNumber =>
      values['please_enter_your_phone_number'] ?? '';

  @override
  String get pleaseProvideEmailOrPhone =>
      values['please_provide_email_or_phone'] ?? '';

  @override
  String get pleaseEnterAValidPhoneNumber =>
      values['please_enter_a_valid_phone_number'] ?? '';

  @override
  String get selcomPesaLinkRequestSentMessage =>
      values['selcom_pesa_link_request_sent_message'] ?? '';

  @override
  String get selcomPesaAlreadyLinkedMessage =>
      values['selcom_pesa_already_linked_message'] ?? '';

  @override
  String get selcomPesaMaxLinkedAccounts =>
      values['selcom_pesa_max_linked_accounts'] ?? '';

  @override
  String get selcomPesaMultipleLinked =>
      values['selcom_pesa_multiple_linked'] ?? '';

  @override
  String get requireVerificationPinBeforeStartingRide =>
      values['require_verification_pin_before_starting_ride'] ?? '';

  @override
  String get ridePinRequiredByAdminCannotBeTurnedOff =>
      values['ride_pin_required_by_admin_cannot_be_turned_off'] ?? '';

  @override
  String get currentStatusRequired => values['current_status_required'] ?? '';

  @override
  String get currentStatusOptional => values['current_status_optional'] ?? '';

  @override
  String get errorPickingImage => values['error_picking_image'] ?? '';

  @override
  String get areYouSureYouWantToLogoutFromTheApp =>
      values['are_you_sure_you_want_to_logout_from_the_app'] ?? '';

  @override
  String get pleaseSelectAReason => values['please_select_a_reason'] ?? '';

  @override
  String get pleaseEnterAMessage => values['please_enter_a_message'] ?? '';

  @override
  String get user => values['user'] ?? '';

  @override
  String get userName => values['user_name'] ?? '';

  @override
  String get phoneNumber => values['phone_number'] ?? '';

  @override
  String get addNew => values['add_new'] ?? '';

  @override
  String get addToFavourites => values['add_to_favourites'] ?? '';

  @override
  String get addToFavouritesSubtitle =>
      values['add_to_favourites_subtitle'] ?? '';

  @override
  String get confirm => values['confirm'] ?? '';

  @override
  String get confirmation => values['confirmation'] ?? '';

  @override
  String get home => values['home'] ?? '';

  @override
  String get minutesCount => values['minutes_count'] ?? '';

  @override
  String get pinLockedMessageRetryInTime =>
      values['pin_locked_message_retry_in_time'] ?? '';

  @override
  String get saveAddress => values['save_address'] ?? '';

  @override
  String get saveLocationAs => values['save_location_as'] ?? '';

  @override
  String get work => values['work'] ?? '';

  @override
  String get office => values['office'] ?? '';

  @override
  String get other => values['other'] ?? '';

  @override
  String get info => values['info'] ?? '';

  @override
  String get enterCustomLabel => values['enter_custom_label'] ?? '';

  @override
  String get connectionTimedOutPleaseCheckInternet =>
      values['connection_timed_out_please_check_internet'] ?? '';

  @override
  String get noInternetConnection => values['no_internet_connection'] ?? '';

  @override
  String get sessionExpiredPleaseLoginAgain =>
      values['session_expired_please_login_again'] ?? '';

  @override
  String get sessionExpiredRefreshing =>
      values['session_expired_refreshing'] ?? '';

  @override
  String get socialLoginSubtitle => values['social_login_subtitle'] ?? '';

  @override
  String get requestQueueFullPleaseTryAgainLater =>
      values['request_queue_full_please_try_again_later'] ?? '';

  @override
  String get requestQueueCleared => values['request_queue_cleared'] ?? '';

  @override
  String get searchEnded => values['search_ended'] ?? '';

  @override
  String get searchTimeoutNoDriverFound =>
      values['search_timeout_no_driver_found'] ?? '';

  @override
  String get sendTimeout => values['send_timeout'] ?? '';

  @override
  String get receiveTimeout => values['receive_timeout'] ?? '';

  @override
  String get badResponseFromServer => values['bad_response_from_server'] ?? '';

  @override
  String get badRequest => values['bad_request'] ?? '';

  @override
  String get unauthorized => values['unauthorized'] ?? '';

  @override
  String get connectionTimeout => values['connection_timeout'] ?? '';

  @override
  String get serverErrorWithStatus => values['server_error_with_status'] ?? '';

  @override
  String get requestCancelled => values['request_cancelled'] ?? '';

  @override
  String get networkIsUnreachable => values['network_is_unreachable'] ?? '';

  @override
  String get noInternetOrUnexpectedError =>
      values['no_internet_or_unexpected_error'] ?? '';

  @override
  String get unexpectedNetworkError => values['unexpected_network_error'] ?? '';

  @override
  String get serverTakingTooLongPleaseTryAgain =>
      values['server_taking_too_long_please_try_again'] ?? '';

  @override
  String get serverTimeout => values['server_timeout'] ?? '';

  @override
  String get youAlreadyHaveAnActiveRide =>
      values['you_already_have_an_active_ride'] ?? '';

  @override
  String get insufficientFundsInWallet =>
      values['insufficient_funds_in_wallet'] ?? '';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      values['something_went_wrong_please_try_again'] ?? '';

  @override
  String get unexpectedErrorOccurredWithError =>
      values['unexpected_error_occurred_with_error'] ?? '';

  @override
  String get invalidOtp => values['invalid_otp'] ?? '';

  @override
  String get incorrectPin => values['incorrect_pin'] ?? '';

  @override
  String get addStop => values['add_stop'] ?? '';

  @override
  String get backToHome => values['back_to_home'] ?? '';

  @override
  String get booking => values['booking'] ?? '';

  @override
  String get bookingFailed => values['booking_failed'] ?? '';

  @override
  String get cardExpired => values['card_expired'] ?? '';

  @override
  String get cards => values['cards'] ?? '';

  @override
  String get chatUnavailable => values['chat_unavailable'] ?? '';

  @override
  String get confirmAndUpdate => values['confirm_and_update'] ?? '';

  @override
  String get confirmStop => values['confirm_stop'] ?? '';

  @override
  String get connectSelcomPesaRideChargesSubtitle =>
      values['connect_selcom_pesa_ride_charges_subtitle'] ?? '';

  @override
  String get couldNotRefreshFareAfterPickup =>
      values['could_not_refresh_fare_after_pickup'] ?? '';

  @override
  String get currentDestination => values['current_destination'] ?? '';

  @override
  String get displayNameRide => values['display_name_ride'] ?? '';

  @override
  String get etaBadge => values['eta_badge'] ?? '';

  @override
  String get fareDifference => values['fare_difference'] ?? '';

  @override
  String get fareIncreasePaymentAuthorization =>
      values['fare_increase_payment_authorization'] ?? '';

  @override
  String get maxStopsOnly => values['max_stops_only'] ?? '';

  @override
  String get microphonePermissionDeniedOpenSettings =>
      values['microphone_permission_denied_open_settings'] ?? '';

  @override
  String get microphonePermissionRequired =>
      values['microphone_permission_required'] ?? '';

  @override
  String get newDestination => values['new_destination'] ?? '';

  @override
  String get newEstimatedFare => values['new_estimated_fare'] ?? '';

  @override
  String get paymentMethodsTitle => values['payment_methods_title'] ?? '';

  @override
  String get receiptSavedToGallery => values['receipt_saved_to_gallery'] ?? '';

  @override
  String get rideCreatedMissingId => values['ride_created_missing_id'] ?? '';

  @override
  String get searchAgain => values['search_again'] ?? '';

  @override
  String get selectedLocation => values['selected_location'] ?? '';

  @override
  String get selectedPickupPoint => values['selected_pickup_point'] ?? '';

  @override
  String get selcomPesaLinkedNumber =>
      values['selcom_pesa_linked_number'] ?? '';

  @override
  String get stopNumber => values['stop_number'] ?? '';

  @override
  String get updateDestination => values['update_destination'] ?? '';

  @override
  String get updateRide => values['update_ride'] ?? '';

  @override
  String get writeAMessage => values['write_a_message'] ?? '';

  @override
  String get yourDriver => values['your_driver'] ?? '';

  @override
  // TODO: implement savedLocations
  String get savedLocations => values['saved_locations'] ?? '';

  @override
  String get selcomPesaLinkNumber => values['selcom_pesa_link_number'] ?? '';

  @override
  String get selcomPesaSelfTitle => values['selcom_pesa_self_title'] ?? '';

  @override
  String get selcomPesaSelfSubtitle => values['selcom_pesa_self_subtitle'] ?? '';

  @override
  String get selcomPesaOtherTitle => values['selcom_pesa_other_title'] ?? '';

  @override
  String get selcomPesaOtherSubtitle => values['selcom_pesa_other_subtitle'] ?? '';

  @override
  String get removeAccountTitle => values['remove_account_title'] ?? '';

  @override
  String get removeAccountMessage => values['remove_account_message'] ?? '';

  @override
  String get removeLabel => values['remove_label'] ?? '';

  @override
  String get savedCardLabel => values['saved_card_label'] ?? '';

  @override
  String get noSavedCardsFound => values['no_saved_cards_found'] ?? '';

  @override
  String get amountIsRequired => values['amount_is_required'] ?? '';

  @override
  String get enterValidAmount => values['enter_valid_amount'] ?? '';

  @override
  String get addCardMinimumAmount => values['add_card_minimum_amount'] ?? '';

  @override
  String get cardInformation => values['card_information'] ?? '';

  @override
  String get firstName => values['first_name'] ?? '';

  @override
  String get lastName => values['last_name'] ?? '';

  @override
  String get billingDetails => values['billing_details'] ?? '';

  @override
  String get billingDetailsSubtitle => values['billing_details_subtitle'] ?? '';

  @override
  String get country => values['country'] ?? '';

  @override
  String get state => values['state'] ?? '';

  @override
  String get selectState => values['select_state'] ?? '';

  @override
  String get address => values['address'] ?? '';

  @override
  String get city => values['city'] ?? '';

  @override
  String get postalCode => values['postal_code'] ?? '';

  @override
  String get egUserEmail => values['eg_user_email'] ?? '';

  @override
  String get streetNameHouseNumber => values['street_name_house_number'] ?? '';

  @override
  String get egDarEsSalaam => values['eg_dar_es_salaam'] ?? '';

  @override
  String get egPostalCode => values['eg_postal_code'] ?? '';

  @override
  String get firstNameIsRequired => values['first_name_is_required'] ?? '';

  @override
  String get lastNameIsRequired => values['last_name_is_required'] ?? '';

  @override
  String get cardNumberIsRequired => values['card_number_is_required'] ?? '';

  @override
  String get enterValidCardNumber => values['enter_valid_card_number'] ?? '';

  @override
  String get expiryIsRequired => values['expiry_is_required'] ?? '';

  @override
  String get enterValidExpiryDate => values['enter_valid_expiry_date'] ?? '';

  @override
  String get cvvIsRequired => values['cvv_is_required'] ?? '';

  @override
  String get cvvMustBe3Digits => values['cvv_must_be_3_digits'] ?? '';

  @override
  String get countryIsRequired => values['country_is_required'] ?? '';

  @override
  String get stateIsRequired => values['state_is_required'] ?? '';

  @override
  String get phoneNumberIsRequired => values['phone_number_is_required'] ?? '';

  @override
  String get invalidPhoneNumberForCountry =>
      values['invalid_phone_number_for_country'] ?? '';

  @override
  String get addressIsRequired => values['address_is_required'] ?? '';

  @override
  String get cityIsRequired => values['city_is_required'] ?? '';

  @override
  String get postalCodeIsRequired => values['postal_code_is_required'] ?? '';

  @override
  String get invalidSessionResponseFromServer =>
      values['invalid_session_response_from_server'] ?? '';

  @override
  String get helpSelcomGoDoBetterByRatingThisTrip =>
      values['help_selcom_go_do_better_by_rating_this_trip'] ?? '';

  @override
  String get noFareEstimateReturnedForTheUpdatedPickupLocation =>
      values['no_fare_estimate_returned_for_the_updated_pickup_location'] ?? '';

  @override
  String get pleaseEnterThe4DigitCodeSentToPhoneThroughSms =>
      values['please_enter_the4_digit_code_sent_to_phone_through_sms'] ?? '';
}
