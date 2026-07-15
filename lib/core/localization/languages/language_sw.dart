import 'languages.dart';

class LanguageSw extends Languages {
  @override
  final Map<String, String> values = {
    'code_not_exist': 'Msimbo uliotafuta haupo.',
    'account_unlinked_successfully': 'Akaunti imetenganishwa kwa mafanikio',
    'account_verified': 'Akaunti Imethibitishwa',
    'add': 'Ongeza',
    'add_asaved_place': 'Ongeza mahali palipohifadhiwa',
    'add_debit_credit_card': 'Ongeza kadi ya deni/mikopo',
    'add_new_card': 'Ongeza Kadi Mpya',
    'add_card': 'Ongeza Kadi',
    'address_missing': 'Anwani inakosekana',
    'an_unexpected_error_occurred': 'Itilafu isiyotarajiwa imetokea',
    'app_title': 'Selcom Rides',
    'apply': 'TUMIA',
    'are_you_sure_want_to_add_ndelete_this_card': 'Je, una uhakika unataka kuongeza/kufuta kadi hii?',
    'are_you_sure_you_want_to_cancel': 'Je, una uhakika unataka kughairi?',
    'blink_your_eyes': 'Kopesa Macho Yako',
    'book_ride': 'Agiza Safari',
    'book_any': 'Yoyote',
    'book_ride_wallet_deduction_notice': 'Kiasi hiki kitakatwa kutoka kwenye mkoba wako.',
    'insufficient_balance_title': 'Salio Halitoshi',
    'insufficient_balance_message': 'Salio la mkoba wako ni dogo sana kuagiza safari hii. Tafadhali ongeza salio ili kuendelea.',
    'current_balance_label': 'Salio la Sasa',
    'required_amount_label': 'Kiasi Kinachohitajika',
    'amount_needed_label': 'Kiasi Kinachohitajika',
    'top_up_wallet': 'Ongeza Salio la Mkoba',
    'add_money_to_wallet': 'Ongeza Pesa kwenye mkoba',
    'add_money': 'Ongeza Pesa',
    'amount': 'Kiasi',
    'back': 'Nyuma',
    'add_money_selcom_pesa_subtitle': 'Omba pesa kutoka SelcomPesa',
    'add_money_mobile_money_subtitle': 'Ongeza Pesa ukitumia Pesa ya Mtandao',
    'add_money_local_banks_subtitle': 'Ongeza Pesa ukitumia benki za ndani',
    'wallet_funds_received_title': 'Mkoba wako umepokea fedha',
    'wallet_funds_received_subtitle':
        'Sasa unaweza kutumia mkoba wako kuweka nafasi ya safari.',
    'top_up_request_sent_title': 'Ombi la kuongeza salio limetumwa',
    'mobile_money_request_sent_title': 'Ombi limetumwa',
    'mobile_money_request_sent_message':
        'Ombi lako la malipo limetumwa kwa @number. Kiasi kitaonyeshwa kwenye mkoba wako wa Selcom Go.',
    'selcom_pesa_to_go_wallet': 'SelcomPesa kwenda kwenye mkoba wa Go',
    'use_another_number': '+ Tumia namba nyingine',
    'enter_selcom_pesa_customer_phone_hint':
        'Ingiza namba ya simu ya mteja wa SelcomPesa, na tutatuma ombi',
    'request_sent_complete_selcom_topup':
        'Ombi limetumwa. Tafadhali kamilisha malipo kwenye SelcomPesa ili kuongeza salio la mkoba wako wa Go',
    'expires_in_with_time': 'Inaisha baada ya @time',
    'wallet_topup_amount_required': 'Tafadhali ingiza kiasi',
    'wallet_topup_amount_must_be_greater_than_zero':
        'Kiasi lazima kiwe zaidi ya 0',
    'wallet_topup_amount_exceeds_max': 'Kiasi hakiwezi kuzidi TZS @max',
    'wallet_topup_request_failed':
        'Imeshindikana kuanzisha malipo. Tafadhali jaribu tena.',
    'wallet_topup_timer_expired_title': 'Muda wa malipo umeisha',
    'wallet_topup_timer_expired_message':
        'Ombi la malipo limeisha muda wake. Je, ungependa kujaribu tena?',
    'wallet_topup_cancel_request': 'Futa ombi',
    'selcom_pesa_app_not_installed': 'Programu ya SelcomPesa haijasakinishwa',
    'selcom_pesa_install_prompt':
        'Sakinisha SelcomPesa ili kukamilisha malipo kwenye kifaa chako.',
    'selcom_pesa_handoff_failed':
        'Imeshindikana kufungua SelcomPesa. Hakikisha programu imesakinishwa na ujaribu tena.',
    'selcom_pesa_status_not_found':
        'Hatukuweza kupata malipo haya. Tafadhali jaribu tena.',
    'selcom_pesa_payment_rejected':
        'Malipo yamekataliwa au yamefeli. Tafadhali jaribu tena.',
    'selcom_pesa_payment_processing':
        'Malipo yamepokelewa, tunashughulikia kuongeza salio lako. Wasiliana na huduma kwa wateja ikiwa salio halitasasishwa.',
    'wallet_account_unavailable':
        'Mkoba wako wa Go haupatikani. Tafadhali jaribu tena baadaye.',
    'download_app': 'Pakua programu',
    'mobile_money_phone_value': '+255 711 410 410',
    'mobile_money_amount_value': 'TZS 43,000',
    'select_a_vehicle': 'Tafadhali chagua chombo.',
    'book_ride_with_fare': 'Weka safari @currency @amount',
    'booking_fees_and_convenience_charges':
        'Ada za Uhifadhi na Malipo ya Urahisi',
    'booking_for_name': 'Kumwekea @name',
    'booking_for_someone_else_prompt': 'Je, unamwekea mtu mwingine safari?',
    'booking_for_someone_else_subtitle': 'Unaweza kuingiza maelezo yao ili tuweze kuwatumia taarifa za safari moja kwa moja.',
    'booking_ride_option_for_me': 'Hapana, ni kwa ajili yangu',
    'booking_ride_option_for_someone_else': 'Ndiyo, kwa ajili ya mtu mwingine',
    'notification_phone_required':
        'Tafadhali ingiza namba ya simu kwa ajili ya arifa.',
    'notification_phone_subtitle':
        'Wasilisha taarifa za safari na arifa kwenye namba hii.',
    'notification_phone_title': 'Namba ya simu ya arifa',
    'enter_passenger_full_name': 'Ingiza majina kamili',
    'passenger_details_title': 'Maelezo ya Abiria',
    'passenger_name_label': 'Jina la Abiria',
    'passenger_phone_label': 'Simu ya Abiria',
    'by_continuing_you_agree_that_you_have_read_and_accept_our_tand_cs_and_privacy_policy':
        'Kwa kuendelea, unakubali kwamba umesoma na kukubaliana na Vigezo na Masharti yetu na Sera ya Faragha',
    'call': 'Piga simu',
    'call_driver': 'Piga simu kwa dereva',
    'call_driver_sheet_subtitle': 'Chagua jinsi unavyotaka kuwasiliana na dereva wako wakati wa safari hii.',
    'coming_soon': 'Inakuja hivi karibuni',
    'calling_driver': 'Anapigiwa Dereva',
    'camera_permission': 'Ruhusa ya Kamera',
    'contacts_permission': 'Ruhusa ya Anwani',
    'contacts_access_needed':
        'Selcom Go inahitaji ufikiaji wa anwani zako ili kukuruhusu kuchagua abiria kutoka kwenye kitabu chako cha simu. Tafadhali wezesha kwenye Mipangilio.',
    'cancel_update': 'Ghairi Kusasisha',
    'cancel_and_pay': 'Ghairi & Lipa',
    'cancel_dialogs_gallery': 'Matunzio ya Mazungumzo ya Kughairi',
    'cancel_failed': 'Kughairi kumeshindikana',
    'cancel_ride': 'Ghairi Safari',
    'cancel': 'Futa',
    'cancelled': 'Imeghairiwa',
    'card_detail': 'Maelezo ya Kadi',
    'card_number': 'Namba ya Kadi',
    'card_ending_in_placeholder': 'Kadi inayoishia na XX1234',
    'change_drop_location': 'Badilisha eneo la kushukia',
    'add_stops': 'Ongeza vituo',
    'change_location': 'Badilisha Eneo',
    'change_phone_number': 'Badilisha namba ya simu',
    'chat': 'Mazungumzo',
    'chat_is_only_available_during_an_active_ride': 'Mazungumzo yanapatikana tu wakati wa safari inayoendelea',
    'ride_chat_quick_passenger_coming_to_road': 'Coming to the road',
    'ride_chat_quick_passenger_there_in_5_mins': "I'll be there in 5 mins",
    'ride_chat_quick_passenger_big_bag': 'I have a big bag with me',
    'check_your_pickup_point': 'Angalia eneo lako la kuchukuliwa',
    'choose_ride': 'Chagua safari',
    'comment_required': 'Maoni yanahitajika',
    'confirm_pickup': 'Thibitisha kuchukuliwa',
    'connection_error': 'Itilafu ya Muunganisho',
    'contact_us': 'Wasiliana Nasi',
    'contact_support': 'Wasiliana na Huduma kwa Wateja',
    'continue': 'Endelea',
    'sign_in_with_google': 'Ingia na Google',
    'didnt_receive_the_code': 'Hukupokea msimbo?',
    'could_not_cancel_try_again': 'Imeshindikana kughairi. Jaribu tena.',
    'could_not_resolve_vehicle_type_id_please_try_again': 'Imeshindikana kupata kitambulisho cha chombo. Tafadhali jaribu tena.',
    'could_not_validate_payment_please_try_again':
        'Imeshindikana kuthibitisha malipo. Tafadhali jaribu tena.',
    'default': 'Chaguomsingi',
    'default_currency_tzs': 'TZS',
    'delete_card': 'Futa kadi',
    'do_not_share_your_personal_details_with_rider_be_safe_and_always_check_your_luggage':
        'Usishiriki maelezo yako binafsi na msafiri. Kuwa salama na uangalie mizigo yako kila wakati.',
    'done': 'Tayari',
    'download_slip': 'Pakua Stakabadhi',
    'download_slip_gallery_subtitle': 'Hifadhi nakala kwenye matunzio yako',
    'choose_how_to_receive_receipt': 'Chagua jinsi ungependa kupokea stakabadhi yako',
    'receipt_options': 'Chaguo za Stakabadhi',
    'share_slip': 'Shiriki Stakabadhi',
    'share_slip_subtitle': 'Tuma kiungo cha stakabadhi kwa wengine',
    'driver_arrived_map_badge': 'Dereva amewasili',
    'driver_arrived_pickup_primary': 'Dereva amewasili kwenye eneo la kuchukulia',
    'your_driver_has_arrived': 'Dereva wako amewasili!',
    'driver_is_heading_to_your_location': 'Dereva anaelekea eneo lako',
    'driver_heading_towards_you': 'Dereva wako anaelekea kwako',
    'driver_assigned_description': 'Dereva amekubali safari yako na yuko njiani.',
    'driver_has_accepted_your_ride': 'Dereva amekubali safari yako',
    'driver_arrived_description': 'Dereva wako amewasili kwenye eneo la kuchukuliwa.',
    'ride_started_description': 'Uko njiani kuelekea unakokwenda.',
    'finding_your_driver': 'Kumtafuta Dereva Wako',
    'finding_driver_default_description': 'Dereva atakuchukua haraka iwezekanavyo baada ya kuthibitisha agizo lako',
    'finding_driver_minutes_remain': 'Zimebaki dakika @minutes na sekunde @seconds',
    'driver_will_arriving_in_minutes': 'Dereva atawasili baada ya dakika @minutes...',
    'driver_finishing_nearby_trip':
        'Dereva wako anakamilisha safari iliyo karibu na atakuchukua hivi karibuni.',
    'driver_assigned': 'Dereva Amepangwa',
    'driver_arriving': 'Dereva Anakuja',
    'driver_en_route': 'Dereva yuko Njiani',
    'driver_arrived': 'Dereva Amewasili',
    'e_g123': 'mfano. 123',
    'e_g7_xx_xxx_xxx': 'mfano. 7XX XXX XXX',
    'e_gjohn_doe': 'mfano. John Doe',
    'e_gname_email_com_optional': 'mfano. jina@email.com (hiari)',
    'edit_your_phone_number': 'Hariri namba yako ya simu?',
    'enter_otp': 'Ingiza OTP',
    'enter_phone_number': 'Ingiza namba ya simu',
    'enter_phone_number_for_verification':
        'Ingiza namba ya simu kwa uthibitisho',
    'enter_promo_code': 'Ingiza msimbo wa promosi',
    'enter_promocode': 'Ingiza Msimbo wa Promosi',
    'enter_your_selcom_pesa_number': 'Ingiza namba yako ya SelcomPesa',
    'error': 'Itilafu',
    'error_opening_phone_dialer': 'Itilafu wakati wa kufungua kipiga simu',
    'error_sending_message': 'Itilafu wakati wa kutuma ujumbe',
    'estimate_failed': 'Ukadiriaji umeshindikana',
    'eta_minutes_away_drop_time': 'Dakika @minutes zilizobaki • Kufika @time',
    'eta_minutes_away_only': 'Umbali wa dakika @minutes',
    'drop_at_time': 'Kufika @time',
    'explore_vehicle': 'Chunguza Chombo',
    'minutes_ago': 'Dakika @count zilizopita',
    'hours_ago': 'Saa @count zilizopita',
    'days_ago': 'Siku @count zilizopita',
    'days_left_count': 'Siku @count zimebaki',
    'expires_in_timer': 'Inaisha baada ya @timer',
    'request_sent_please_complete_payment_on_selcom_pesa_to_book_your_ride':
        'Ombi limetumwa. Tafadhali kamilisha malipo kwenye SelcomPesa ili kuongeza salio la mkoba wako.',
    'payment_completed_successfully': 'Malipo yamekamilika kwa mafanikio',
    'thank_you_for_riding_with_us_see_you_on_the_next_trip': 'Asante kwa kusafiri nasi, tutakuona kwenye safari ijayo.',
    'fare': 'Nauli',
    'failed_to_send_message': 'Imeshindikana kutuma ujumbe',
    'failed_to_load_settings': 'Imeshindikana kupakia mipangilio',
    'failed_to_load_ride_pin_preference': 'Imeshindikana kupakia upendeleo wa PIN ya safari',
    'failed_to_update_ride_pin_preference': 'Imeshindikana kusasisha upendeleo wa PIN ya safari',
    'failed_to_resend_otp': 'Imeshindikana kutuma tena OTP',
    'failed_to_send_otp': 'Imeshindikana kutuma OTP',
    'failed_to_update_favorite_status': 'Imeshindikana kusasisha hali ya unayopendelea',
    'fallback_ride_name': 'Safari',
    'favourite_locations': 'Maeneo Yanayopendwa',
    'saved_locations': 'Maeneo Yaliyohifadhiwa',
    'get_started': 'Anza',
    'home_label': 'Nyumbani',
    'get_verification_code': 'Pata Msimbo wa Uthibitishaji',
    'havent_got_the_confirmation_code_yet': 'Bado hujapata msimbo wa uthibitisho? ',
    'got_it': 'Nimeelewa',
    'google_sign_in_cancelled': 'Uingiaji umeghairiwa',
    'google_sign_in_config_error': 'Uingiaji wa Google haujasanidiwa vizuri',
    'google_sign_in_failed': 'Uingiaji wa Google umefeli. Tafadhali jaribu tena.',
    'google_sign_in_success': 'Umeingia kama @email',
    'google_sign_in_unsupported': 'Uingiaji wa Google hautumiki kwenye kifaa hiki',
    'sign_in_with_apple': 'Ingia na Apple',
    'apple_sign_in_success': 'Umeingia kama @email',
    'apple_sign_in_cancelled': 'Uingiaji umeghairiwa',
    'apple_sign_in_failed': 'Uingiaji wa Apple umefeli. Tafadhali jaribu tena.',
    'apple_sign_in_account_exists': 'Akaunti iliyo na barua pepe hii tayari ipo. Ingia kwa njia yako ya kwanza kwanza.',
    'apple_sign_in_not_available': 'Uingiaji wa Apple unapatikana tu kwenye vifaa vya iOS',
    'sign_in_with_facebook': 'Ingia na Facebook',
    'facebook_sign_in_success': 'Umeingia kama @email',
    'facebook_sign_in_cancelled': 'Uingiaji umeghairiwa',
    'facebook_sign_in_failed': 'Uingiaji wa Facebook umefeli. Tafadhali jaribu tena.',
    'help': 'Msaada',
    'having_trouble_logging_in': 'Unapata Shida Kuingia?',
    'help_selcom_go_do_better_by_rating_this_trip': 'Saidia Selcom Go kufanya vizuri zaidi kwa kukadiria safari hii',
    'how_can_we_help_you': 'Je, tunawezaje kukusaidia?',
    'how_do_you_rate_the_driver': 'Je, unamkadiria vipi dereva?',
    'how_was_your_ride': 'Safari yako ilikuwaje?',
    'includes_stops': 'Ina vituo',
    'includes_stop_fee': 'Inajumuisha ada ya kituo',
    'initiating_call_to_driverphone':
        'Inapiga simu kwenda kwa \$driverPhone...',
    'keep_ride': 'Weka Safari',
    'link_account': 'Unganisha Akaunti',
    'location': 'Eneo',
    'locating': 'Kutafuta eneo...',
    'locating_driver': 'Kumtafuta dereva...',
    'current_location': 'Eneo la sasa',
    'saved': 'Imehifadhiwa',
    'saved_place': 'Mahali Palipohifadhiwa',
    'saved_places': 'Maeneo Yaliyohifadhiwa',
    'recent_locations': 'Maeneo ya Hivi Karibuni',
    'search_tag': 'TAFUTA',
    'recent_tag': 'HIVI KARIBUNI',
    'saved_tag': 'IMEHIFADHIWA',
    'loading_your_profile': 'Inapakia wasifu wako...',
    'location_selection': 'Uteuzi wa Eneo',
    'location_unavailable': 'Eneo halipatikani',
    'login': 'Ingia',
    'logout': 'Ondoka',
    'lorem_ipsum_dolor_sit_amet_consectetur': 'Lorem ipsum dolor sit amet, consectetur',
    'making_your_drive_best_is_our_responsibility': 'Kufanya safari yako kuwa bora ni jukumu letu',
    'maybe_later': 'Labda Baadaye',
    'mark_all_read_count': 'Weka zote zimesomwa (@count)',
    'message': 'Ujumbe',
    'missing_info': 'Maelezo yanayokosekana',
    'missing_ride_information': 'Maelezo ya safari yanakosekana.',
    'mm_yy': 'MM/YY',
    'my_rides': 'Safari Zangu',
    'name_cannot_be_empty': 'Jina haliwezi kuwa tupu',
    'name_contains_invalid_characters': 'Jina lina herufi zisizo sahihi',
    'name_is_required': 'Jina linahitajika',
    'need_help': 'Unahitaji Msaada?',
    'new_message': 'Ujumbe Mpya',
    'no': 'Hapana',
    'no_configurable_settings_are_available_right_now': 'Hakuna mipangilio inayoweza kusanidiwa kwa sasa.',
    'no_driver_found_for_your_request_please_try_again': 'Hakuna dereva aliyepatikana kwa ombi lako. Tafadhali jaribu tena.',
    'no_drivers_found_within9_minutes_cancelling_ride': 'Hakuna madereva waliopatikana ndani ya dakika 9. Inaghairi safari...',
    'no_drivers_nearby_please_try_again_later': 'Hakuna madereva karibu. Tafadhali jaribu tena baadaye.',
    'no_fare_estimate_returned_for_the_updated_pickup_location':
        'Hakuna makadirio ya nauli yaliyopatikana kwa eneo jipya la kuchukuliwa.',
    'no_favorite_locations_yet': 'Hakuna maeneo yanayopendwa bado',
    'no_locations_found': 'Hakuna maeneo yaliyopatikana',
    'no_notifications_yet': 'Hakuna arifa bado',
    'no_past_rides_found': 'Hakuna safari zilizopita zilizopatikana',
    'no_recent_locations_found': 'Hakuna maeneo ya hivi karibuni yaliyopatikana',
    'no_recent_locations': 'Hakuna maeneo ya hivi karibuni',
    'note_by_proceeding_you_consent_to_get_calls_whatsapp_or_sms_messages_including_by_au':
        'Kumbuka: Kwa kuendelea, unakubali kupokea simu, ujumbe wa WhatsApp au SMS, ikiwa ni pamoja na njia za kiotomatiki, kutoka Selcom Go na washirika wake kwenye namba iliyotolewa.',
    'notification': 'Arifa',
    'notifications': 'Arifa',
    'ok': 'Sawa',
    'order_label_with_id': 'Agizo: @orderId',
    'open_settings': 'Fungua Mipangilio',
    'call_notification_permission_msg':
        'Ruhusa ya arifa inahitajika kupokea simu za dereva. Tafadhali iwashe katika mipangilio ya programu.',
    'call_full_screen_permission_msg':
        'Arifa za skrini kamili zinahitajika kujibu simu simu yako ikiwa imefungwa. Tafadhali iwashe katika mipangilio ya programu.',
    'please_enter_label': 'Tafadhali ingiza lebo',
    'or_divider': 'au',
    'otp_resent_successfully': 'OTP imetumiwa tena kwa mafanikio',
    'past': 'Zilizopita',
    'pay_using': 'Lipa Ukitumia',
    'payment': 'Malipo',
    'processing': 'Inchakata...',
    'updating_payment': 'Inasasisha Malipo',
    'recalculating_route': 'Inakokotoa upya Njia',
    'drop_off_updated': 'Eneo la kushukia limesasishwa!',
    'route_updated': 'Njia Imesasishwa!',
    'adjusting_payment_hold_for_new_route':
        'Tunarekebisha zuio la malipo yako kwa ajili ya njia mpya.',
    'syncing_new_route_with_driver': 'Inalandanisha njia mpya na dereva wako.',
    'driver_received_new_drop_off_location': 'Dereva wako amepokea eneo jipya la kushukia.',
    'driver_received_new_stops': 'Dereva wako amepokea vituo vipya.',
    'please_wait_while_we_process_your_request': 'Tafadhali subiri wakati tunachakata ombi lako.',
    'payment_mode': 'Njia ya malipo',
    'payment_not_confirmed': 'Malipo hayajathibitishwa',
    'book_ride_payment_not_applied_title': 'Malipo hayajakatwa',
    'book_ride_payment_not_applied_message':
        'Hatukuweza kuthibitisha kwamba malipo yako yalichukuliwa kwa safari hii. Gusa Jaribu tena ili kutuma ombi upya, au Futa ili kubaki hapa.',
    'payment_validation_failed': 'Uthibitisho wa malipo umefeli',
    'phone_number_unavailable': 'Namba ya simu haipatikani',
    'phone_with_number': 'Simu: @phone',
    'pick_any_tags_that_match_this_trip': 'Chagua lebo zozote zinazolingana na safari hii.',
    'pickup': 'Kuchukuliwa',
    'pickup_point': 'Eneo la kuchukulia',
    'pickup_confirmation_note_label': 'Maelezo ya ziada',
    'pickup_confirmation_note_hint': 'Hiari — jengo, geti, alama ya eneo…',
    'pin': 'PIN',
    'pin_locked': 'PIN Imefungwa',
    'please_confirm_pickup_point_to_continue': 'Tafadhali thibitisha eneo la kuchukuliwa ili kuendelea.',
    'please_enter_apromo_code': 'Tafadhali ingiza msimbo wa promosi',
    'please_enter_a_valid_email': 'Tafadhali ingiza barua pepe sahihi',
    'please_enter_a_valid_name': 'Tafadhali ingiza jina sahihi',
    'please_enter_the4_digit_code_sent_to_phone_through_sms':
        'Tafadhali ingiza tarakimu 4 zilizotumwa kwa \n@countryCode @phoneNumber kupitia SMS',
    'please_enter_your_details_to_continue': 'Tafadhali ingiza maelezo yako ili kuendelea.',
    'please_enter_at_least_one_destination': 'Tafadhali ingiza angalau eneo moja unalokwenda.',
    'please_enter_your_comment_first': 'Tafadhali ingiza maoni yako kwanza.',
    'please_rate_your_ride_before_submitting': 'Tafadhali kadiria safari yako kabla ya kuwasilisha.',
    'please_select_at_least_one_destination': 'Tafadhali chagua angalau eneo moja unalokwenda.',
    'please_select_at_least_one_tag_before_submitting': 'Tafadhali chagua angalau lebo moja kabla ya kuwasilisha.',
    'please_tell_us_what_went_wrong_or_how_we_can_improve': 'Tafadhali tuambie nini kimeenda vibaya au jinsi tunavyoweza kuboresha.',
    'please_try_again': 'Tafadhali jaribu tena.',
    'privacy_policy': 'Sera ya Faragha',
    'terms_and_conditions': 'Vigezo na Masharti',
    'payment_method_with_name': 'Njia ya malipo @name',
    'calculating_best_route': 'Inatafuta njia bora zaidi...',
    'ride_receipt': 'Stakabadhi ya Safari',
    'ref_with_id': 'Rejea: @id',
    'transaction_id_with_value': 'Kitambulisho cha Muamala: @id',
    'route': 'Njia',
    'dropoff': 'Kushukia',
    'em_dash': '—',
    'driver_and_vehicle': 'Dereva & Chombo',
    'driver': 'Dereva',
    'model': 'Mfano',
    'colour': 'Rangi',
    'plate': 'Namba ya Gari',
    'fare_breakdown': 'Mchanganuo wa Nauli',
    'base_fare': 'Nauli ya Msingi',
    'distance_charge': 'Gharama ya Umbali',
    'time_charge': 'Gharama ya Muda',
    'discount': 'Punguzo',
    'tax': 'Kodi',
    'total': 'Jumla',
    'thank_you_for_riding_with_selcom_go': 'Asante kwa kusafiri na Selcom Go!',
    'mobile_money': 'Pesa ya Mtandao',
    'card': 'Kadi',
    'promocode_list': 'Orodha ya misimbo ya promosi',
    'promotions': 'Promosheni',
    'have_promo_code': 'Una msimbo wa promosi?',
    'promo_apply_success_message': 'Msimbo wa promosi umetumika kwa mafanikio.',
    'promo_removed_title': 'Promosi imeondolewa',
    'promo_removed_destination_changed': 'Njia imebadilika — promosi imefutwa.',
    'promo_error_invalid': 'Msimbo si sahihi',
    'promo_error_expired': 'Msimbo huu umeisha muda',
    'promo_error_not_applicable': 'Msimbo huu hautumiki kwa safari hii',
    'promo_error_network': 'Imeshindikana kuthibitisha. Jaribu tena.',
    'promo_not_applied_title': 'Promosi haijatumiwa',
    'promo_code_not_valid_for_vehicle': 'Si sahihi kwa chombo hiki',
    'ride_free_label': 'BURE',
    'receipt_promo_line': 'Promosi (@code)',
    'promo_min_ride_amount': 'Kiasi cha chini @amount',
    'promo_expires_today': 'Inaisha leo',
    'no_available_promo_codes': 'Hakuna misimbo ya promosheni kwa sasa',
    'failed_to_load_promo_codes': 'Imeshindwa kupakia misimbo ya promosheni',
    'rating': 'Ukadiriaji',
    'rating_given': 'ukadiriaji uliotolewa',
    'rating_required': 'Ukadiriaji unahitajika',
    'reason_to_contact': 'Sababu ya Kuwasiliana',
    'recent_location': 'Eneo la Hivi Karibuni',
    'remove_account': 'Futa Akaunti',
    'remove': 'Ondoa',
    'remove_saved_address': 'Ondoa anwani iliyohifadhiwa',
    'are_you_sure_you_want_to_remove_this_saved_address': 'Je, una uhakika unataka kuondoa anwani hii iliyohifadhiwa?',
    'resend_code': 'Tuma Msimbo Tena',
    'resend_otp': 'Tuma tena OTP',
    'retry': 'Jaribu tena',
    'ride_cancelled': 'Safari Imeghairiwa',
    'trip_ended_by_driver': 'Safari imeishia na dereva',
    'mid_ride_sorry_subtitle': 'Samahani, safari yako haikuweza kukamilika.',
    'mid_ride_reason_lead': 'Sababu: ',
    'mid_ride_dispute_charge': 'Pinga malipo',
    'mid_ride_dispute_success':
        'Zuio limetolewa. Timu yetu itakagua — hautalipishwa tunapokagua.',
    'mid_ride_dispute_failed': 'Imeshindikana kuwasilisha pingamizi',
    'mid_ride_dispute_unavailable': 'Pingamizi halipatikani',
    'mid_ride_dispute_window_closed':
        'Muda wa kupinga umekwisha. Wasiliana na msaada ikiwa bado unahitaji usaidizi.',
    'mid_ride_cancelled_by_driver_partial_charge':
        'Imeghairiwa na dereva',
    'mid_ride_reason_vehicle_breakdown': 'Gari limevunjika',
    'mid_ride_reason_accident': 'Ajali',
    'mid_ride_reason_unsafe': 'Hali si salama',
    'mid_ride_reason_other': 'Nyingine',
    'driver_started_your_ride': '@driverName ameanzisha safari yako',
    'ride_completed': 'Safari Imekamilika',
    'the_ride_has_been_cancelled': 'Safari imeghairiwa.',
    'you_have_reached_your_destination': 'Umeshafika unakokwenda.',
    'you_have_arrived': 'Umeshawasili!',
    'you_are_almost_there': 'Uko karibu kufika',
    'on_your_way_with_driver': 'Uko njiani na @driverName',
    'arrived_in_minutes': 'Imewasili kwa dakika @minutes',
    'approaching_your_destination': 'Inakaribia unakokwenda',
    'heading_to_your_destination': 'Inaelekea unakokwenda',
    'trip_has_started': 'Safari imeanza',
    'nearby': 'Karibu',
    'arriving': 'Inawasili',
    'driver_is_arriving': 'Dereva anawasili...',
    'we_couldnt_find_a_driver_nearby': 'Hatukuweza kupata dereva karibu.',
    'ride_charge': 'Gharama ya Safari',
    'ride_data_is_unavailable': 'Maelezo ya safari hayapatikani.',
    'ride_id_is_missing': 'Kitambulisho cha safari kinakosekana.',
    'destination': 'Unakokwenda',
    'arrived_in': 'Imewasili baada ya',
    'minutes_short_count': 'dakika @count',
    'someone': 'Mtu mwingine',
    'could_not_fetch_receipt_details': 'Imeshindikana kupata maelezo ya stakabadhi.',
    'ride_details_are_missing': 'Maelezo ya safari yanakosekana.',
    'failed_to_load_ride_details': 'Imeshindikana kupakia maelezo ya safari. Tafadhali jaribu tena.',
    'could_not_open_pdf_with_message': 'Imeshindikana kufungua PDF: @message',
    'could_not_download_slip_please_try_again_later': 'Imeshindikana kupakua stakabadhi. Tafadhali jaribu tena baadaye.',
    'check_out_my_ride_receipt_share_url': 'Angalia stakabadhi ya safari my: @url',
    'selcom_go_ride_receipt_subject': 'Stakabadhi ya Safari ya Selcom Go',
    'could_not_share_slip_please_try_again_later': 'Imeshindikana kushiriki stakabadhi. Tafadhali jaribu tena baadaye.',
    'ride_pin_protection': 'Ulinzi wa PIN ya Safari',
    'safety_and_privacy': 'Safety & Faragha',
    'save_this_address_first_then_you_can_book_from_here': 'Hifadhi anwani hii kwanza, kisha unaweza kuagiza kutoka hapa.',
    'saving_changes': 'Inahifadhi mabadiliko...',
    'search_destination': 'Tafuta unakokwenda',
    'search_location': 'Tafuta eneo...',
    'search_pickup': 'Tafuta eneo la kuchukulia',
    'search_stop': 'Tafuta eneo la kituo',
    'search_stop_location': 'Tafuta eneo la kituo',
    'in_app_calling': 'Piga simu kupitia App',
    'in_app_calling_subtitle': 'Piga simu ya sauti kupitia programu kwa kutumia muunganisho wa safari yako.',
    'normal_call': 'Simu ya Kawaida',
    'normal_call_subtitle': 'Tumia kipiga simu cha kifaa chako kumpigia dereva moja kwa moja.',
    'in_app_calling_will_be_available_soon': 'Simu kupitia programu itapatikana hivi karibuni',
    'update_failed': 'Kusasisha Kumefeli',
    'update_in_progress': 'Kusasisha kunaendelea',
    'a_previous_update_is_still_being_processed': 'Mabadiliko ya awali bado yanashughulikiwa.',
    'taking_longer_than_expected': 'Inachukua muda mrefu kuliko ilivyotarajiwa',
    'the_update_is_taking_some_time_please_check_back_shortly': 'Mabadiliko yanachukua muda kidogo. Tafadhali angalia tena hivi karibuni.',
    'payment_hold_update_failed_no_charges_applied':
        'Uboreshaji wa zuio la malipo umefeli. Hakuna gharama zilizotozwa.',
    'drivers_app_couldnt_be_updated_billing_adjusted_back': 'Programu ya dereva haikuweza kusasishwa. Gharama zimerudishwa.',
    'search_timeout': 'Muda wa kutafuta umeisha',
    'security_and_preference_controls_more_settings_will_appear_here_as_they_are_enable':
        'Udhibiti wa usalama na upendeleo. Mipangilio zaidi itaonekana hapa itakapowezeshwa.',
    'selcom_pesa': 'SelcomPesa',
    'select_anearby_point_for_easier_pickup': 'Chagua eneo la karibu kwa ajili ya kuchukuliwa kwa urahisi',
    'select_apayment_method': 'Chagua njia ya malipo',
    'select_country': 'Chagua nchi',
    'select_country_subtitle':
        'Tafuta na uchague msimbo wa nchi kwa ajili ya namba yako ya simu.',
    'search_country': 'Tafuta nchi',
    'no_countries_found': 'Hakuna nchi zilizopatikana',
    'select_areason': 'Chagua sababu',
    'select_a_reason_subtitle': 'Chagua mada inayoelezea vizuri zaidi kile unachohitaji msaada nacho.',
    'select_avehicle_and_payment_method': 'Chagua chombo na njia ya malipo.',
    'select_payment': 'Chagua malipo',
    'selfie_capture_failed': 'Upigaji picha wa selfie umefeli',
    'session_expired': 'Muda wa Kipindi Umeisha',
    'settings': 'Mipangilio',
    'skip': 'Ruka',
    'skip_failed': 'Kuruka kumefeli',
    'smile': 'Tabasamu',
    'stop': 'Kituo',
    'socket_off': 'Inaangalia upatikanaji wa madereva...',
    'socket_off_error': 'Imeshindikana kuonyesha madereva wa karibu',
    'socket_on_drivers': 'Madereva @count wako karibu',
    'start_typing_pickup': 'Anza kuandika eneo la kuchukulia',
    'start_typing_destination': 'Anza kuandika eneo unalokwenda',
    'stay_notified': 'Pata Taarifa!',
    'enable_notifications_for_ride_updates': 'Wezesha arifa ili kupokea taarifa za wakati halisi kuhusu kuwasili kwa dereva na hali ya safari.',
    'steps_to_connect_selcom_pesa': 'Hatua za kuunganisha SelcomPesa',
    'submit_failed': 'Uwasilishaji umefeli',
    'submit': 'Wasilisha',
    'success': 'Mafanikio',
    'selected_address': 'Anwani iliyochaguliwa',
    'searching_for_driver': 'Inamtafuta dereva...',
    'enable_location_service': 'Wezesha huduma ya eneo',
    'enable_location_service_message':
        'Tafadhali wezesha huduma ya eneo ili kupata eneo lako la sasa.',
    'enable_location_service_message_ios':
        'Huduma za Eneo zimezimwa kwenye kifaa chako.\n\nNenda Mipangilio → Faragha na Usalama → Huduma za Eneo na uzivute. Kisha rudi kwenye programu na uguse kitufe cha GPS ili kuruhusu eneo kwa Selcom Go.',
    'location_permission_denied': 'Ruhusa ya eneo imekataliwa',
    'location_access_required': 'Ufikiaji wa eneo unahitajika',
    'location_permission_denied_open_settings': 'Ruhusa ya eneo imekataliwa kabisa. Fungua Mipangilio ili kuruhusu eneo kwa ajili ya kuchukuliwa na kuona madereva wa karibu.',
    'unable_to_estimate_fare_for_this_route':
        'Imeshindikana kukadiria nauli ya njia hii.',
    'distance_min_km': 'KM 0.1',
    'distance_max_km': '>KM 999',
    'distance_km_format': '@value KM',
    'distance': 'Umbali',
    'duration': 'Muda',
    'could_not_remove_address': 'Imeshindikana kuondoa anwani',
    'view_more': 'Angalia zaidi',
    'ride_in_progress': 'Safari Inaendelea',
    'ongoing': 'Inaendelea',
    'completed': 'Imekamilika',
    'no_driver_found': 'Hakuna Dereva Aliyepatikana',
    'boda': 'Boda boda',
    'unknown_location': 'Eneo lisilojulikana',
    'near_destination': 'Karibu na unakokwenda',
    'active_ride': 'Safari Inayoendelea',
    'your_ride': 'Safari yako',
    'booked_for_passenger': 'Imewekewa abiria @name',
    'booked_for_someone_else': 'Imewekewa mtu mwingine',
    'booked_for_other_limit_reached': 'Umefikia kikomo cha safari unazoweza kuwawekea wengine.',
    'booked_for_other_no_multi_stop': 'Safari za vituo vingi haziruhusiwi unapoagiza safari kwa ajili ya mtu mwingine.',
    'book_any_fare_settled_title': 'Malipo yamesasishwa',
    'book_any_fare_settled_blocked_lead': 'Tulizuia kwa muda ',
    'book_any_fare_settled_middle_with_vehicle':
        ' kwa ajili ya safari yako ya Yoyote. @vehicle ilipangwa kwa nauli ya chini, kwa hivyo ',
    'book_any_fare_settled_middle_no_vehicle':
        ' kwa ajili ya safari yako ya Yoyote. Chombo cha nauli ya chini kilipangwa, kwa hivyo ',
    'book_any_fare_settled_released_trail': ' imerejeshwa kwenye mkoba wako.',
    'book_any_fare_settled_final_charge_label': 'Gharama ya mwisho: ',
    'unable_to_get_location_coordinates': 'Imeshindikana kupata viwianishi vya eneo',
    'please_select_valid_pickup_and_destination_locations': 'Tafadhali chagua maeneo sahihi ya kuchukuliwa na unakokwenda.',
    'are_you_sure_you_want_to_add_this_address_as':
        'Are you sure you want to add this address as @phrase?',
    'tag_required': 'Lebo inahitajika',
    'tap_each_button_to_preview_the_popup_ui': 'Gusa kila kitufe ili kuona muonekano wa UI',
    'tell_us_more_about_your_experience': 'Tuambie zaidi kuhusu uzoefu wako...',
    'thank_you': 'Asante',
    'this_is_second_slide': 'Hii ni Slaidi ya Pili',
    'this_is_third_slide': 'Hii ni Slaidi ya Tatu',
    'this_saved_place_has_no_address': 'Mahali hapa palipohifadhiwa hapana anwani.',
    'this_saved_place_is_missing_coordinates': 'Mahali hapa palipohifadhiwa hapana viwianishi.',
    'this_saved_place_is_missing_coordinates_try_saving_it_again': 'Mahali hapa palipohifadhiwa hapana viwianishi. Jaribu kukihifadhi tena.',
    'timeout': 'Muda umeisha',
    'total_amount': 'Jumla ya Kiasi',
    'total_fare': 'Jumla ya Nauli',
    'unable_to_initiate_booking_right_now': 'Imeshindikana kuanzisha uagizaji kwa sasa.',
    'unable_to_open_phone_dialer': 'Imeshindikana kufungua kipiga simu',
    'unable_to_open_ride_details': 'Imeshindikana kufungua maelezo ya safari',
    'unable_to_skip_rating_now': 'Imeshindikana kuruka ukadiriaji kwa sasa.',
    'unable_to_submit_rating_now': 'Imeshindikana kuwasilisha ukadiriaji kwa sasa.',
    'stop_location': 'Eneo la Kituo',
    'updating_address': 'Inasasisha anwani...',
    'user_profile_updated_successfully': 'Wasifu wa mtumiaji umesasishwa kwa mafanikio',
    'validation': 'Uthibitishaji',
    'validation_id_missing_from_server_response': 'Kitambulisho cha uthibitisho hakipo kwenye jibu la seva.',
    'value0000000000000000': '0000 0000 0000 0000',
    'value1_standard_confirmation': '1. Uthibitisho wa Kawaida',
    'value20_percent_off_on_your_first_ride_booking': 'Punguzo la 20% kwenye uagizaji wa safari yako ya kwanza',
    'value255': '+255',
    'value2_assignment_warning_fee': '2. Onyo la upangaji (Ada)',
    'value3_reason_selection': '3. Uteuzi wa Sababu',
    'share': 'Shiriki',
    'safety': 'Usalama',
    'safety_options': 'Chaguo za Usalama',
    'safety_options_subtitle': 'Shiriki eneo lako la moja kwa moja au wasiliana na namba za dharura ikiwa unahitaji msaada.',
    'share_live_location': 'Shiriki eneo la moja kwa moja',
    'selcom_go_sos_helpline': 'Namba ya dharura ya Selcom Go',
    'call_police': 'Piga polisi',
    'share_ride_status': 'Shiriki taarifa ya safari',
    'choose_app_to_share': 'Chagua app ya kushiriki',
    'whatsapp': 'WhatsApp',
    'text_message': 'Ujumbe wa maandishi',
    'copy_link': 'Nakili kiungo',
    'share_feature_coming_soon':
        'Huduma ya kushiriki itaunganishwa hivi karibuni.',
    'vehicle_type': 'Aina ya chombo',
    'verification_successful': 'Uthibitishaji Umekamilika kwa Mafanikio!',
    'otp_label': 'OTP',
    'otp_verification_failed': 'Uthibitishaji wa OTP umefeli',
    'verify_phone_number': 'Thibitisha Namba ya Simu',
    'verify_your_selfie': 'Thibitisha Selfie Yako',
    'view_trip': 'Angalia safari',
    'view_ride': 'Angalia Safari',
    'active_ride_min_remains': 'Dakika @minutes zimebaki',
    'active_ride_more_count': 'na wengine +@count',
    'visa': 'VISA',
    'wallet': 'Mkoba',
    'wallet_number_copied': 'Namba ya mkoba imenakiliwa',
    'copied_to_clipboard': 'Imenakiliwa kwenye ubao wa kunakili',
    'wallet_number_label': 'Namba ya Mkoba',
    'wallet_reserved_balance': 'Imehifadhiwa: @amount',
    'recent_transactions': 'Miamala ya Hivi Karibuni',
    'recent_transaction_title': 'Muamala wa Hivi Karibuni',
    'view_all': 'Angalia Zote',
    'e_statement': 'Taarifa ya Kielektroniki',
    'wallet_statement_emailed_success':
        'Taarifa yako ya mkoba imetumwa kwa barua pepe yako.',
    'wallet_statement_email_failed':
        'Imeshindikana kutuma taarifa yako ya mkoba kwa barua pepe. Tafadhali jaribu tena.',
    'wallet_statement_range_capped_hint':
        'Taarifa inajumuisha siku 30 zilizopita zinazoishia kwenye tarehe ya mwisho iliyochaguliwa.',
    'show_vcn': 'Onyesha VCN',
    'no_transactions_yet': 'Hakuna miamala bado',
    'filter_all': 'Zote',
    'filter_received': 'Zilizopokelewa',
    'filter_sent': 'Zilizotumwa',
    'we_could_not_confirm_your_payment_block_please_try_again':
        'Hatukuweza kuthibitisha zuio la malipo yako. Tafadhali jaribu tena.',
    'we_ll_text_acode_to_verify_your_phone_number':
        'Tutatuma msimbo kwa ujumbe ili kuthibitisha namba yako ya simu',
    'we_will_notify_you_when_something_important_happens': 'Tutaarifu wakati kitu muhimu kinapotokea.',
    'what_stood_out': 'Nini kilionekana kuwa bora?',
    'where_are_you_going': 'Unakwenda wapi?',
    'why_do_you_want_to_cancel': 'Kwa nini unataka kughairi?',
    'cancellation_fee_of': 'Ada ya kufuta ya ',
    'will_be_charged_since_driver_on_way':
        ' itatozwa kwa sababu dereva wako yuko njiani.',
    'net_amount_refunded': 'Kiasi kilichorejeshwa: ',
    'yes': 'Ndiyo',
    'yes_cancel': 'NDIYO, GHAIRI',
    'you_can_still_able_to_request_money_on_selcom_pesa_using_another_number':
        'Bado unaweza kuomba fedha kwenye SelcomPesa kwa kutumia namba nyingine.',
    'your_card_has_been_nadded_successfully':
        'Kadi yako imeongezwa kwa mafanikio.',
    'your_driver_is_already_on_the_way': 'Dereva wako tayari yuko njiani.',
    'your_identity_has_been_successfully_verified_you_can_now_use_selcom_pesa':
        'Uthibitisho wa utambulisho wako umekamilika kwa mafanikio. Sasa unaweza kutumia SelcomPesa.',
    'your_linked_account': 'Akaunti Yako Iliyounganishwa',
    'your_rating_has_been_submitted': 'Ukadiriaji wako umewasilishwa.',
    'your_ride_was_cancelled': 'Safari yako imeghairiwa.',
    'thanks_for_using_go': 'Asante kwa kutumia Go!',
    'your_rides': 'Safari Zangu',
    'welcome_to_selcom_go': 'Karibu Selcom GO',
    'full_name': 'Majina kamili',
    'enter_your_full_name': 'Ingiza majina yako kamili',
    'email': 'Barua pepe',
    'enter_your_email_optional': 'Ingiza barua pepe yako (hiari)',
    'enter_your_email': 'Ingiza barua pepe yako',
    'email_is_required': 'Barua pepe inahitajika',
    'i_agree_to_the_terms_and_conditions': 'Ninakubaliana na Vigezo na Masharti',
    'please_accept_terms_and_conditions': 'Tafadhali kubali Vigezo na Masharti',
    'your_selfie_will_be_captured_to_help_us_validate_you_against_your_id_please_hold_your':
        'Picha yako ya selfie itapigwa ili kutusaidia kukuthibiti dhidi ya kitambulisho chako. Tafadhali shika simu yako vizuri, hakikisha uso wako uko ndani ya fremu ya duara, na ufuate maelekezo.',
    'your_session_has_expired_please_login_again_to_continue': 'Muda wa kipindi chako umeisha. Tafadhali ingia tena ili kuendelea.',
    'language': 'Lugha',
    'english': 'Kiingereza',
    'swahili': 'Kiswahili',
    'switched_to_english': 'Imebadilishwa kwenda Kiingereza',
    'switched_to_swahili': 'Imebadilishwa kwenda Kiswahili',
    'exit_app': 'Ondoka kwenye App',
    'exit_app_title': 'Ondoka kwenye App',
    'exit_app_message': 'Je, una uhakika unataka kuondoka kwenye app?',
    'card_delete_warning_description':
        'Kitendo hiki kitaondoa kadi kwenye akaunti yako, na utahitaji kuiongeza tena ikiwa unataka kuitumia baadaye.',
    'no_cancel': 'Hapana, Ghairi',
    'expiry': 'Muda wa Mwisho',
    'cvv': 'CVV',
    'set_a_nick_name': 'Weka Jina la Utani',
    'please_enter_your_phone_number': 'Tafadhali ingiza namba yako ya simu',
    'please_provide_email_or_phone':
        'Tafadhali weka barua pepe au namba ya simu ili tuweze kuwasiliana nawe',
    'enter_phone_number_optional': 'Ingiza namba ya simu (hiari)',
    'please_enter_a_valid_phone_number':
        'Tafadhali ingiza namba ya simu iliyo sahihi',
    'invalid_otp_please_try_again': 'OTP si sahihi. Tafadhali jaribu tena.',
    'camera_access_needed_for_selfie_verification': 'Tunahitaji ufikiaji wa kamera ili kupiga selfie kwa ajili ya uthibitisho wa utambulisho. Tafadhali wezesha kwenye mipangilio ya kifaa chako.',
    'card_ready_to_use_you_can_manage_or_remove_anytime':
        'Sasa iko tayari kwa malipo. Unaweza kudhibiti au kuondoa kadi hii wakati wowote kutoka kwenye mipangilio ya malipo.',
    'selcom_pesa_connect_step_1':
        'Ingiza namba yako ya simu iliyosajiliwa ya SelcomPesa',
    'selcom_pesa_connect_step_2':
        'Thibitisha picha ya selfie inayohusiana na akaunti yako ya SelcomPesa.',
    'selcom_pesa_connect_step_3':
        'Angalia programu yako ya SelcomPesa na uidhinishe ombi la uthibitisho.',
    'selcom_pesa_link_request_sent_message':
        'Ombi la kuunganisha limetumwa kwa @phoneNumber. Tafadhali fungua SelcomPesa na uidhinishe ili kuunganisha akaunti yako.',
    'selcom_pesa_already_linked_message':
        '@phoneNumber tayari imeunganishwa na akaunti yako ya Selcom Go.',
    'link_another_account': 'Unganisha akaunti nyingine',
    'selcom_pesa_pending_approval': 'Inasubiri idhini',
    'selcom_pesa_max_linked_accounts':
        'Unaweza kuunganisha akaunti @max za SelcomPesa.',
    'selcom_pesa_multiple_linked': 'Akaunti @count za SelcomPesa zimeunganishwa',
    'selcom_pesa_connect_step_4':
        'Umekamilisha kila kitu! Akaunti yako ya SelcomPesa imeunganishwa.',
    'otp_sent_to_your_phone_number':
        'OTP imetumwa kwa namba yako ya simu ya @phoneNumber',
    'require_verification_pin_before_starting_ride': 'Inahitaji PIN ya uthibitisho kabla ya kuanza safari.',
    'ride_pin_required_by_admin_cannot_be_turned_off': 'PIN ya safari inahitajika na msimamizi na haiwezi kuzimwa.',
    'current_status_required': 'Hali ya sasa: inahitajika',
    'current_status_optional': 'Hali ya sasa: hiari',
    'take_selfie': 'Piga Selfie',
    'error_picking_image': 'Itilafu wakati wa kuchagua picha: @error',
    'are_you_sure_you_want_to_logout_from_the_app': 'Je, una uhakika unataka kuondoka kwenye programu?',
    'please_select_a_reason': 'Tafadhali chagua sababu',
    'please_enter_a_message': 'Tafadhali ingiza ujumbe',
    'user': 'Mtumiaji',
    'user_name': 'Jina la mtumiaji',
    'phone_number': 'Namba ya simu',
    'add_new': 'Ongeza Mpya',
    'add_to_favourites': 'Ongeza kwenye Maeneo unayopenda',
    'add_to_favourites_subtitle': 'Chagua lebo ya anwani hii au ongeza yako binafsi.',
    'confirm': 'Thibitisha',
    'confirmation': 'Uthibitisho',
    'home': 'Nyumbani',
    'loading': 'Inapakia...',
    'minutes_count': 'dakika @count',
    'pin_locked_message_retry_in_time': '@message. Tafadhali jaribu tena baada ya @time.',
    'save_address': 'Hifadhi Anuani',
    'save_location_as': 'Hifadhi Eneo Kama',
    'work': 'Kazi',
    'office': 'Ofisi',
    'other': 'Nyingine',
    'info': 'Taarifa',
    'enter_custom_label': 'Ingiza lebo yako',
    'connection_timed_out_please_check_internet': 'Muda wa muunganisho umeisha. Tafadhali angalia mtandao wako.',
    'no_internet_connection': 'Hakuna muunganisho wa mtandao',
    'session_expired_please_login_again': 'Kipindi kimeisha. Tafadhali ingia tena.',
    'session_expired_refreshing': 'Kipindi kimeisha. Inafanya upya...',
    'social_login_subtitle': 'Fungua akaunti au ingia ili kuchunguza programu yetu',
    'request_queue_full_please_try_again_later': 'Foleni ya maombi imejaa. Tafadhali jaribu tena baadaye.',
    'duplicate_request_already_queued': 'Ombi linalofanana tayari liko kwenye foleni',
    'request_queue_cleared': 'Foleni ya maombi imefutwa',
    'search_ended': 'Utafutaji Umeisha',
    'search_timeout_no_driver_found': 'Utafutaji umeisha: hakuna dereva aliyepatikana',
    'send_timeout': 'Muda wa kutuma umeisha',
    'receive_timeout': 'Muda wa kupokea umeisha',
    'bad_response_from_server': 'Jibu lisilo sahihi kutoka kwa seva',
    'bad_request': 'Ombi baya',
    'unauthorized': 'Hauruhusiwi',
    'connection_timeout': 'Muda wa muunganisho umeisha',
    'server_error_with_status': 'Itilafu ya Seva (@statusCode)',
    'request_cancelled': 'Ombi limeghairiwa',
    'network_is_unreachable': 'Mtandao haufikiki',
    'no_internet_or_unexpected_error': 'Hakuna mtandao au itilafu isiyotarajiwa',
    'unexpected_network_error': 'Itilafu ya mtandao isiyotarajiwa',
    'server_taking_too_long_please_try_again': 'Seva inachukua muda mrefu kujibu. Tafadhali jaribu tena.',
    'server_timeout': 'Muda wa seva umeisha',
    'you_already_have_an_active_ride': 'Tayari una safari inayoendelea.',
    'insufficient_funds_in_wallet': 'Salio la mkoba halitoshi.',
    'something_went_wrong_please_try_again': 'Kuna kitu kimeenda vibaya. Tafadhali jaribu tena.',
    'unexpected_error_occurred_with_error': 'Itilafu isiyotarajiwa imetokea: @error',
    'invalid_otp': 'OTP si sahihi.',
    'add_stop': 'Ongeza Kituo',
    'back_to_home': 'Rudi Nyumbani',
    'booking': 'Inaagiza',
    'booking_failed': 'Uagizaji umefeli',
    'card_expired': 'Imeisha muda',
    'cards': 'Kadi',
    'chat_unavailable': 'Mazungumzo hayapatikani',
    'confirm_and_update': 'Thibitisha & Sasisha',
    'confirm_stop': 'Thibitisha Kituo',
    'connect_selcom_pesa_ride_charges_subtitle':
        'Unganisha akaunti yako ya SelcomPesa kuwezesha ukataji wa nauli otomatiki na rahisi.',
    'connecting_drivers': 'Inatafuta madereva wa karibu...',
    'connecting_socket': 'Inatafuta madereva wa karibu...',
    'could_not_refresh_fare_after_pickup':
        'Imeshindikana kusasisha nauli baada ya uthibitisho wa kuchukuliwa.',
    'current_destination': 'Eneo la sasa la kwenda',
    'display_name_ride': 'Safari',
    'drivers_online_count': 'madereva @count wako karibu',
    'no_drivers_nearby_badge': 'Hakuna madereva karibu',
    'eta_badge': 'ETA',
    'fare_difference': 'Tofauti ya Nauli:',
    'fare_increase_payment_authorization':
        'Kuongezeka kwa nauli kutahitaji idhini ya malipo.',
    'mastercard_visa': 'Mastercard / Visa',
    'max_stops_only': 'Unaweza kuongeza hadi vituo @count tu.',
    'microphone_permission_denied_open_settings': 'Ruhusa ya maikrofoni imekataliwa kabisa. Fungua Mipangilio ili kuiruhusu.',
    'microphone_permission_required': 'Ruhusa ya maikrofoni inahitajika ili kupiga simu.',
    'new_destination': 'Eneo jipya la kwenda',
    'new_estimated_fare': 'Nauli Mpya ya Kukadiriwa:',
    'payment_methods_title': 'Njia za malipo',
    'receipt_saved_to_gallery': 'Stakabadhi imehifadhiwa kwenye matunzio yako ya picha.',
    'ride_created_missing_id': 'Safari imeundwa lakini kitambulisho cha safari hakipo kwenye jibu.',
    'search_again': 'Tafuta Tena',
    'selected_location': 'Eneo lililochaguliwa',
    'selected_pickup_point': 'Eneo lililochaguliwa la kuchukulia',
    'selcom_pesa_linked_number': 'Namba iliyounganishwa: @number',
    'socket_disconnected': 'Muunganisho wa soketi umekatika',
    'stop_number': 'Kituo @number',
    'update_destination': 'Sasisha Eneo la Kwenda',
    'update_ride': 'Sasisha Safari',
    'write_a_message': 'Andika ujumbe...',
    'your_driver': 'Dereva Wako',
    'incorrect_pin': 'PIN si sahihi.',
    'selcom_pesa_link_number': '+ Unganisha namba',
    'selcom_pesa_self_title': 'Binafsi',
    'selcom_pesa_self_subtitle': 'Ingiza kiasi na uelekezwe kwenye SelcomPesa',
    'selcom_pesa_other_title': 'Nyingine',
    'selcom_pesa_other_subtitle': 'Ingiza namba ya simu na kiasi',
    'remove_account_title': 'Ondoa Akaunti',
    'remove_account_message': 'Je, una uhakika unataka kuondoa akaunti hii ya SelcomPesa?',
    'remove_label': 'Ondoa',
    'saved_card_label': 'Kadi iliyohifadhiwa',
    'saved_card_subtitle': 'Ongeza salio ukitumia kadi zilizohifadhiwa',
    'no_saved_cards_found': 'Hakuna kadi zilizohifadhiwa',
    'add_new_card_text': '+ Ongeza kadi mpya',
    'amount_is_required': 'Kiasi kinahitajika',
    'enter_valid_amount': 'Tafadhali ingiza kiasi sahihi',
    'set_as_default': 'Weka kama Chaguomsingi',
    'set_as_default_confirm': 'Weka hii kama akaunti yako ya chaguomsingi',
    'default_account_set_successfully': 'Akaunti ya chaguomsingi imesasishwa kwa mafanikio',
    'card_information': 'Taarifa za Kadi',
    'first_name': 'Jina la Kwanza',
    'last_name': 'Jina la Mwisho',
    'billing_details': 'Maelezo ya Malipo',
    'billing_details_subtitle':
        'Tafadhali toa anwani yako ya malipo kulingana na rekodi za benki yako',
    'country': 'Nchi',
    'state': 'Jimbo',
    'select_state': 'Chagua Jimbo',
    'address': 'Anwani',
    'city': 'Jiji',
    'postal_code': 'Msimbo wa Posta',
    'eg_user_email': 'mfano. user@example.com',
    'street_name_house_number': 'Jina la mtaa / Namba ya nyumba',
    'eg_dar_es_salaam': 'mfano. Dar es Salaam',
    'eg_postal_code': 'mfano. 14110',
    'first_name_is_required': 'Jina la kwanza linahitajika',
    'last_name_is_required': 'Jina la mwisho linahitajika',
    'card_number_is_required': 'Namba ya kadi inahitajika',
    'enter_valid_card_number': 'Ingiza namba sahihi ya kadi',
    'expiry_is_required': 'Tarehe ya kuisha inahitajika',
    'enter_valid_expiry_date': 'Ingiza tarehe sahihi ya kuisha',
    'cvv_is_required': 'CVV inahitajika',
    'cvv_must_be_3_digits': 'CVV lazima iwe tarakimu 3',
    'country_is_required': 'Nchi inahitajika',
    'state_is_required': 'Jimbo linahitajika',
    'phone_number_is_required': 'Namba ya simu inahitajika',
    'invalid_phone_number_for_country': 'Namba ya simu si sahihi kwa @country',
    'address_is_required': 'Anwani inahitajika',
    'city_is_required': 'Jiji linahitajika',
    'postal_code_is_required': 'Msimbo wa posta unahitajika',
    'invalid_session_response_from_server':
        'Jibu batili la kikao kutoka kwa seva.',
  };

  @override
  String get codeNotExist => values['code_not_exist'] ?? '';

  @override
  String get accountUnlinkedSuccessfully =>
      values['account_unlinked_successfully'] ?? '';

  @override
  String get accountVerified => values['account_verified'] ?? '';

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
  String get appTitle => values['app_title'] ?? '';

  @override
  String get apply => values['apply'] ?? '';

  @override
  String get areYouSureWantToAddNdeleteThisCard =>
      values['are_you_sure_want_to_add_ndelete_this_card'] ?? '';

  @override
  String get areYouSureYouWantToCancel =>
      values['are_you_sure_you_want_to_cancel'] ?? '';

  @override
  String get blinkYourEyes => values['blink_your_eyes'] ?? '';

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
  String get addMoneySelcomPesaSubtitle =>
      values['add_money_selcom_pesa_subtitle'] ?? '';

  @override
  String get addMoneyMobileMoneySubtitle =>
      values['add_money_mobile_money_subtitle'] ?? '';

  @override
  String get addMoneyLocalBanksSubtitle =>
      values['add_money_local_banks_subtitle'] ?? '';

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
  String get useAnotherNumber => values['use_another_number'] ?? '';

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
  String get mobileMoneyPhoneValue => values['mobile_money_phone_value'] ?? '';

  @override
  String get mobileMoneyAmountValue =>
      values['mobile_money_amount_value'] ?? '';

  @override
  String get selectAVehicle => values['select_a_vehicle'] ?? '';

  @override
  String get bookRideWithFare => values['book_ride_with_fare'] ?? '';

  @override
  String get bookingFeesAndConvenienceCharges =>
      values['booking_fees_and_convenience_charges'] ?? '';

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
  String
  get byContinuingYouAgreeThatYouHaveReadAndAcceptOurTAndCsAndPrivacyPolicy =>
      values['by_continuing_you_agree_that_you_have_read_and_accept_our_tand_cs_and_privacy_policy'] ??
      '';

  @override
  String get call => values['call'] ?? '';

  @override
  String get callDriver => values['call_driver'] ?? '';

  @override
  String get callDriverSheetSubtitle =>
      values['call_driver_sheet_subtitle'] ?? '';

  @override
  String get comingSoon => values['coming_soon'] ?? '';

  @override
  String get callingDriver => values['calling_driver'] ?? '';

  @override
  String get cameraPermission => values['camera_permission'] ?? '';

  @override
  String get contactsPermission => values['contacts_permission'] ?? '';

  @override
  String get contactsAccessNeeded => values['contacts_access_needed'] ?? '';

  @override
  String get cancelUpdate => values['cancel_update'] ?? '';

  @override
  String get cancelAndPay => values['cancel_and_pay'] ?? '';

  @override
  String get cancelDialogsGallery => values['cancel_dialogs_gallery'] ?? '';

  @override
  String get cancelFailed => values['cancel_failed'] ?? '';

  @override
  String get cancelRide => values['cancel_ride'] ?? '';

  @override
  String get cancel => values['cancel'] ?? '';

  @override
  String get cancelled => values['cancelled'] ?? '';

  @override
  String get cardDetail => values['card_detail'] ?? '';

  @override
  String get cardNumber => values['card_number'] ?? '';

  @override
  String get cardEndingInPlaceholder =>
      values['card_ending_in_placeholder'] ?? '';

  @override
  String get changeDropLocation => values['change_drop_location'] ?? '';

  @override
  String get addStops => values['add_stops'] ?? '';

  @override
  String get changeLocation => values['change_location'] ?? '';

  @override
  String get changePhoneNumber => values['change_phone_number'] ?? '';

  @override
  String get chat => values['chat'] ?? '';

  @override
  String get chatIsOnlyAvailableDuringAnActiveRide =>
      values['chat_is_only_available_during_an_active_ride'] ?? '';

  @override
  String get rideChatQuickPassengerComingToRoad =>
      values['ride_chat_quick_passenger_coming_to_road'] ?? '';

  @override
  String get rideChatQuickPassengerThereIn5Mins =>
      values['ride_chat_quick_passenger_there_in_5_mins'] ?? '';

  @override
  String get rideChatQuickPassengerBigBag =>
      values['ride_chat_quick_passenger_big_bag'] ?? '';

  @override
  String get checkYourPickupPoint => values['check_your_pickup_point'] ?? '';

  @override
  String get chooseRide => values['choose_ride'] ?? '';

  @override
  String get commentRequired => values['comment_required'] ?? '';

  @override
  String get confirmPickup => values['confirm_pickup'] ?? '';

  @override
  String get connectionError => values['connection_error'] ?? '';

  @override
  String get contactUs => values['contact_us'] ?? '';

  @override
  String get contactSupport => values['contact_support'] ?? '';

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
  String get defaultLabel => values['default'] ?? '';

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
  String get driverAssigned => values['driver_assigned'] ?? '';

  @override
  String get driverArriving => values['driver_arriving'] ?? '';

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
  String get eGNameEmailComOptional =>
      values['e_gname_email_com_optional'] ?? '';

  @override
  String get editYourPhoneNumber => values['edit_your_phone_number'] ?? '';

  @override
  String get enterOtp => values['enter_otp'] ?? '';

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
  String get expiresInTimer => values['expires_in_timer'] ?? '';

  @override
  String get requestSentPleaseCompletePaymentOnSelcomPesaToBookYourRide =>
      values['request_sent_please_complete_payment_on_selcom_pesa_to_book_your_ride'] ??
      '';

  @override
  String get paymentCompletedSuccessfully =>
      values['payment_completed_successfully'] ?? '';

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
  String get failedToUpdateFavoriteStatus =>
      values['failed_to_update_favorite_status'] ?? '';

  @override
  String get fallbackRideName => values['fallback_ride_name'] ?? '';

  @override
  String get favouriteLocations => values['favourite_locations'] ?? '';

  @override
  String get getStarted => values['get_started'] ?? '';

  @override
  String get homeLabel => values['home_label'] ?? '';

  @override
  String get getVerificationCode => values['get_verification_code'] ?? '';

  @override
  String get haventGotTheConfirmationCodeYet =>
      values['havent_got_the_confirmation_code_yet'] ?? '';

  @override
  String get gotIt => values['got_it'] ?? '';

  @override
  String get googleSignInCancelled => values['google_sign_in_cancelled'] ?? '';

  @override
  String get googleSignInConfigError =>
      values['google_sign_in_config_error'] ?? '';

  @override
  String get googleSignInFailed => values['google_sign_in_failed'] ?? '';

  @override
  String get googleSignInSuccess => values['google_sign_in_success'] ?? '';

  @override
  String get googleSignInUnsupported =>
      values['google_sign_in_unsupported'] ?? '';

  @override
  String get signInWithApple => values['sign_in_with_apple'] ?? '';

  @override
  String get appleSignInSuccess => values['apple_sign_in_success'] ?? '';

  @override
  String get appleSignInCancelled => values['apple_sign_in_cancelled'] ?? '';

  @override
  String get appleSignInFailed => values['apple_sign_in_failed'] ?? '';

  @override
  String get appleSignInAccountExists =>
      values['apple_sign_in_account_exists'] ?? '';

  @override
  String get appleSignInNotAvailable =>
      values['apple_sign_in_not_available'] ?? '';

  @override
  String get signInWithFacebook => values['sign_in_with_facebook'] ?? '';

  @override
  String get facebookSignInSuccess => values['facebook_sign_in_success'] ?? '';

  @override
  String get facebookSignInCancelled =>
      values['facebook_sign_in_cancelled'] ?? '';

  @override
  String get facebookSignInFailed => values['facebook_sign_in_failed'] ?? '';

  @override
  String get help => values['help'] ?? '';

  @override
  String get havingTroubleLoggingIn =>
      values['having_trouble_logging_in'] ?? '';

  @override
  String get helpSelcomGoDoBetterByRatingThisTrip =>
      values['help_selcom_go_do_better_by_rating_this_trip'] ?? '';

  @override
  String get howCanWeHelpYou => values['how_can_we_help_you'] ?? '';

  @override
  String get howDoYouRateTheDriver =>
      values['how_do_you_rate_the_driver'] ?? '';

  @override
  String get howWasYourRide => values['how_was_your_ride'] ?? '';

  @override
  String get includesStops => values['includes_stops'] ?? '';

  @override
  String get includesStopFee => values['includes_stop_fee'] ?? '';

  @override
  String get initiatingCallToDriverphone =>
      values['initiating_call_to_driverphone'] ?? '';

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
  String get nameContainsInvalidCharacters =>
      values['name_contains_invalid_characters'] ?? '';

  @override
  String get nameIsRequired => values['name_is_required'] ?? '';

  @override
  String get needHelp => values['need_help'] ?? '';

  @override
  String get newMessage => values['new_message'] ?? '';

  @override
  String get no => values['no'] ?? '';

  @override
  String get noConfigurableSettingsAreAvailableRightNow =>
      values['no_configurable_settings_are_available_right_now'] ?? '';

  @override
  String get noDriverFoundForYourRequestPleaseTryAgain =>
      values['no_driver_found_for_your_request_please_try_again'] ?? '';

  @override
  String get noDriversFoundWithin9MinutesCancellingRide =>
      values['no_drivers_found_within9_minutes_cancelling_ride'] ?? '';

  @override
  String get noDriversNearbyPleaseTryAgainLater =>
      values['no_drivers_nearby_please_try_again_later'] ?? '';

  @override
  String get noFareEstimateReturnedForTheUpdatedPickupLocation =>
      values['no_fare_estimate_returned_for_the_updated_pickup_location'] ?? '';

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
  String get notificationPhoneTitle => values['notification_phone_title'] ?? '';

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
  String get orDivider => values['or_divider'] ?? '';

  @override
  String get otpResentSuccessfully => values['otp_resent_successfully'] ?? '';

  @override
  String get past => values['past'] ?? '';

  @override
  String get payUsing => values['pay_using'] ?? '';

  @override
  String get payment => values['payment'] ?? '';

  @override
  String get processing => values['processing'] ?? '';

  @override
  String get updatingPayment => values['updating_payment'] ?? '';

  @override
  String get recalculatingRoute => values['recalculating_route'] ?? '';

  @override
  String get dropOffUpdated => values['drop_off_updated'] ?? '';

  @override
  String get routeUpdated => values['route_updated'] ?? '';

  @override
  String get adjustingPaymentHoldForNewRoute =>
      values['adjusting_payment_hold_for_new_route'] ?? '';

  @override
  String get syncingNewRouteWithDriver =>
      values['syncing_new_route_with_driver'] ?? '';

  @override
  String get driverReceivedNewDropOffLocation =>
      values['driver_received_new_drop_off_location'] ?? '';

  @override
  String get driverReceivedNewStops =>
      values['driver_received_new_stops'] ?? '';

  @override
  String get pleaseWaitWhileWeProcessYourRequest =>
      values['please_wait_while_we_process_your_request'] ?? '';

  @override
  String get paymentMode => values['payment_mode'] ?? '';

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
  String get pleaseEnterThe4DigitCodeSentToPhoneThroughSms =>
      values['please_enter_the4_digit_code_sent_to_phone_through_sms'] ?? '';

  @override
  String get pleaseEnterYourDetailsToContinue =>
      values['please_enter_your_details_to_continue'] ?? '';

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
  String get pleaseSelectAtLeastOneTagBeforeSubmitting =>
      values['please_select_at_least_one_tag_before_submitting'] ?? '';

  @override
  String get pleaseTellUsWhatWentWrongOrHowWeCanImprove =>
      values['please_tell_us_what_went_wrong_or_how_we_can_improve'] ?? '';

  @override
  String get pleaseTryAgain => values['please_try_again'] ?? '';

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
  String get refWithId => values['ref_with_id'] ?? '';

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
  String get baseFare => values['base_fare'] ?? '';

  @override
  String get distanceCharge => values['distance_charge'] ?? '';

  @override
  String get timeCharge => values['time_charge'] ?? '';

  @override
  String get discount => values['discount'] ?? '';

  @override
  String get tax => values['tax'] ?? '';

  @override
  String get total => values['total'] ?? '';

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
  String get rideFreeLabel => values['ride_free_label'] ?? '';

  @override
  String get receiptPromoLine => values['receipt_promo_line'] ?? '';

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
  String get rating => values['rating'] ?? '';

  @override
  String get ratingGiven => values['rating_given'] ?? '';

  @override
  String get ratingRequired => values['rating_required'] ?? '';

  @override
  String get reasonToContact => values['reason_to_contact'] ?? '';

  @override
  String get recentLocation => values['recent_location'] ?? '';

  @override
  String get removeAccount => values['remove_account'] ?? '';

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
  String get resendOtp => values['resend_otp'] ?? '';

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
  String get midRideDisputeCharge => values['mid_ride_dispute_charge'] ?? '';

  @override
  String get midRideDisputeSuccess => values['mid_ride_dispute_success'] ?? '';

  @override
  String get midRideDisputeFailed => values['mid_ride_dispute_failed'] ?? '';

  @override
  String get midRideDisputeUnavailable =>
      values['mid_ride_dispute_unavailable'] ?? '';

  @override
  String get midRideDisputeWindowClosed =>
      values['mid_ride_dispute_window_closed'] ?? '';

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
  String get rideCharge => values['ride_charge'] ?? '';

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
  String get couldNotOpenPdfWithMessage =>
      values['could_not_open_pdf_with_message'] ?? '';

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
  String get safetyAndPrivacy => values['safety_and_privacy'] ?? '';

  @override
  String get safetyOptions => values['safety_options'] ?? '';

  @override
  String get safetyOptionsSubtitle => values['safety_options_subtitle'] ?? '';

  @override
  String get saveThisAddressFirstThenYouCanBookFromHere =>
      values['save_this_address_first_then_you_can_book_from_here'] ?? '';

  @override
  String get savingChanges => values['saving_changes'] ?? '';

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
  String get inAppCallingWillBeAvailableSoon =>
      values['in_app_calling_will_be_available_soon'] ?? '';

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
  String get searchTimeout => values['search_timeout'] ?? '';

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
  String get selectAPaymentMethod => values['select_apayment_method'] ?? '';

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
  String get selectAVehicleAndPaymentMethod =>
      values['select_avehicle_and_payment_method'] ?? '';

  @override
  String get selectPayment => values['select_payment'] ?? '';

  @override
  String get selfieCaptureFailed => values['selfie_capture_failed'] ?? '';

  @override
  String get sessionExpired => values['session_expired'] ?? '';

  @override
  String get settings => values['settings'] ?? '';

  @override
  String get skip => values['skip'] ?? '';

  @override
  String get skipFailed => values['skip_failed'] ?? '';

  @override
  String get smile => values['smile'] ?? '';

  @override
  String get stop => values['stop'] ?? '';

  @override
  String get socketOff => values['socket_off'] ?? '';

  @override
  String get socketOffError => values['socket_off_error'] ?? '';

  @override
  String get socketOnDrivers => values['socket_on_drivers'] ?? '';

  @override
  String get startTypingPickup => values['start_typing_pickup'] ?? '';

  @override
  String get startTypingDestination => values['start_typing_destination'] ?? '';

  @override
  String get stayNotified => values['stay_notified'] ?? '';

  @override
  String get enableNotificationsForRideUpdates =>
      values['enable_notifications_for_ride_updates'] ?? '';

  @override
  String get stepsToConnectSelcomPesa =>
      values['steps_to_connect_selcom_pesa'] ?? '';

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
  String get rideInProgress => values['ride_in_progress'] ?? '';

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
  String get nearDestination => values['near_destination'] ?? '';

  @override
  String get activeRide => values['active_ride'] ?? '';

  @override
  String get yourRide => values['your_ride'] ?? '';

  @override
  String get bookedForPassenger => values['booked_for_passenger'] ?? '';

  @override
  String get bookedForSomeoneElse => values['booked_for_someone_else'] ?? '';

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
  String get tagRequired => values['tag_required'] ?? '';

  @override
  String get tapEachButtonToPreviewThePopupUi =>
      values['tap_each_button_to_preview_the_popup_ui'] ?? '';

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
  String get totalAmount => values['total_amount'] ?? '';

  @override
  String get totalFare => values['total_fare'] ?? '';

  @override
  String get unableToInitiateBookingRightNow =>
      values['unable_to_initiate_booking_right_now'] ?? '';

  @override
  String get unableToOpenPhoneDialer =>
      values['unable_to_open_phone_dialer'] ?? '';

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
  String get value1StandardConfirmation =>
      values['value1_standard_confirmation'] ?? '';

  @override
  String get value20PercentOffOnYourFirstRideBooking =>
      values['value20_percent_off_on_your_first_ride_booking'] ?? '';

  @override
  String get value255 => values['value255'] ?? '';

  @override
  String get value2AssignmentWarningFee =>
      values['value2_assignment_warning_fee'] ?? '';

  @override
  String get value3ReasonSelection => values['value3_reason_selection'] ?? '';

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
  String get verifyYourSelfie => values['verify_your_selfie'] ?? '';

  @override
  String get viewTrip => values['view_trip'] ?? '';

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
  String get recentTransactionTitle => values['recent_transaction_title'] ?? '';

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
  String get showVcn => values['show_vcn'] ?? '';

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
  String get yourLinkedAccount => values['your_linked_account'] ?? '';

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
  String get enterYourEmailOptional =>
      values['enter_your_email_optional'] ?? '';

  @override
  String get enterYourEmail => values['enter_your_email'] ?? '';

  @override
  String get emailIsRequired => values['email_is_required'] ?? '';

  @override
  String get iAgreeToTheTermsAndConditions =>
      values['i_agree_to_the_terms_and_conditions'] ?? '';

  @override
  String get pleaseAcceptTermsAndConditions =>
      values['please_accept_terms_and_conditions'] ?? '';

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
  String get exitAppTitle => values['exit_app_title'] ?? '';

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
  String get setANickName => values['set_a_nick_name'] ?? '';

  @override
  String get pleaseEnterYourPhoneNumber =>
      values['please_enter_your_phone_number'] ?? '';

  @override
  String get pleaseProvideEmailOrPhone =>
      values['please_provide_email_or_phone'] ?? '';

  @override
  String get enterPhoneNumberOptional =>
      values['enter_phone_number_optional'] ?? '';

  @override
  String get pleaseEnterAValidPhoneNumber =>
      values['please_enter_a_valid_phone_number'] ?? '';

  @override
  String get invalidOtpPleaseTryAgain =>
      values['invalid_otp_please_try_again'] ?? '';

  @override
  String get cameraAccessNeededForSelfieVerification =>
      values['camera_access_needed_for_selfie_verification'] ?? '';

  @override
  String get cardReadyToUseYouCanManageOrRemoveAnytime =>
      values['card_ready_to_use_you_can_manage_or_remove_anytime'] ?? '';

  @override
  String get selcomPesaConnectStep1 =>
      values['selcom_pesa_connect_step_1'] ?? '';

  @override
  String get selcomPesaConnectStep2 =>
      values['selcom_pesa_connect_step_2'] ?? '';

  @override
  String get selcomPesaConnectStep3 =>
      values['selcom_pesa_connect_step_3'] ?? '';

  @override
  String get selcomPesaLinkRequestSentMessage =>
      values['selcom_pesa_link_request_sent_message'] ?? '';

  @override
  String get selcomPesaAlreadyLinkedMessage =>
      values['selcom_pesa_already_linked_message'] ?? '';

  @override
  String get linkAnotherAccount => values['link_another_account'] ?? '';

  @override
  String get selcomPesaPendingApproval =>
      values['selcom_pesa_pending_approval'] ?? '';

  @override
  String get selcomPesaMaxLinkedAccounts =>
      values['selcom_pesa_max_linked_accounts'] ?? '';

  @override
  String get selcomPesaMultipleLinked =>
      values['selcom_pesa_multiple_linked'] ?? '';

  @override
  String get selcomPesaConnectStep4 =>
      values['selcom_pesa_connect_step_4'] ?? '';

  @override
  String get otpSentToYourPhoneNumber =>
      values['otp_sent_to_your_phone_number'] ?? '';

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
  String get takeSelfie => values['take_selfie'] ?? '';

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
  String get loading => values['loading'] ?? '';

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
  String get duplicateRequestAlreadyQueued =>
      values['duplicate_request_already_queued'] ?? '';

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
  String get connectingDrivers => values['connecting_drivers'] ?? '';

  @override
  String get connectingSocket => values['connecting_socket'] ?? '';

  @override
  String get couldNotRefreshFareAfterPickup =>
      values['could_not_refresh_fare_after_pickup'] ?? '';

  @override
  String get currentDestination => values['current_destination'] ?? '';

  @override
  String get displayNameRide => values['display_name_ride'] ?? '';

  @override
  String get driversOnlineCount => values['drivers_online_count'] ?? '';

  @override
  String get noDriversNearbyBadge => values['no_drivers_nearby_badge'] ?? '';

  @override
  String get etaBadge => values['eta_badge'] ?? '';

  @override
  String get fareDifference => values['fare_difference'] ?? '';

  @override
  String get fareIncreasePaymentAuthorization =>
      values['fare_increase_payment_authorization'] ?? '';

  @override
  String get mastercardVisa => values['mastercard_visa'] ?? '';

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
  String get socketDisconnected => values['socket_disconnected'] ?? '';

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
  String get savedCardSubtitle => values['saved_card_subtitle'] ?? '';

  @override
  String get noSavedCardsFound => values['no_saved_cards_found'] ?? '';

  @override
  String get addNewCardText => values['add_new_card_text'] ?? '';

  @override
  String get amountIsRequired => values['amount_is_required'] ?? '';

  @override
  String get enterValidAmount => values['enter_valid_amount'] ?? '';

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
}
