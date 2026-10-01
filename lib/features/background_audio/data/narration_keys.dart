/// Every keyword the background-audio flow knows about.
///
/// Call sites use these constants rather than raw strings so a typo is a
/// compile error instead of a clip that silently never plays — the failure mode
/// that is hardest to notice, since a missing key looks exactly like a card
/// that simply had nothing to say.
class NarrationKeys {
  NarrationKeys._();

  // ─── Onboarding: language ───
  static const onbLang = 'onb_lang';
  static const onbLangSelected = 'onb_lang_selected';
  static const onbLangOther = 'onb_lang_other';
  static const onbVoiceLang = 'onb_voice_lang';

  // ─── Onboarding: mobile number ───
  static const onbMobile = 'onb_mobile';
  static const onbMobileInvalid = 'onb_mobile_invalid';
  static const onbMobileInternet = 'onb_mobile_internet';
  static const onbMobileGoogle = 'onb_mobile_google';

  // ─── Onboarding: OTP ───
  static const onbOtp = 'onb_otp';
  static const onbOtpMethod = 'onb_otp_method';
  static const onbOtpWhatsapp = 'onb_otp_whatsapp';
  static const onbOtpSms = 'onb_otp_sms';
  static const onbOtpResendWhatsapp = 'onb_otp_resend_whatsapp';
  static const onbOtpResendSms = 'onb_otp_resend_sms';
  static const onbOtpWhere = 'onb_otp_where';
  static const onbOtpWrong = 'onb_otp_wrong';
  static const onbOtpResend = 'onb_otp_resend';
  static const onbOtpSuccess = 'onb_otp_success';

  // ─── Onboarding: role ───
  static const onbRole = 'onb_role';
  static const onbRoleMom = 'onb_role_mom';
  static const onbRoleDad = 'onb_role_dad';

  // ─── Onboarding: name ───
  static const onbNamePromptMom = 'onb_name_prompt_mom';
  static const onbNamePromptDad = 'onb_name_prompt_dad';
  static const onbNameReaction = 'onb_name_reaction';
  static const onbNameEmpty = 'onb_name_empty';

  // ─── Onboarding: Dad family steps ───
  static const dadFamilyChoice = 'dad_family_choice';
  static const dadFamilySetup = 'dad_family_setup';
  static const dadJoinCode = 'dad_join_code';
  static const dadJoinWrong = 'dad_join_wrong';
  static const dadJoinSuccess = 'dad_join_success';
  static const onbDadFamilyChoice = dadFamilyChoice;
  static const onbDadFamilySetup = dadFamilySetup;
  static const onbDadJoinCode = dadJoinCode;
  static const onbDadJoinWrong = dadJoinWrong;
  static const onbDadJoinSuccess = dadJoinSuccess;

  // ─── Onboarding: status ───
  static const onbStatus = 'onb_status';
  static const onbStatusPregnant = 'onb_status_pregnant';
  static const onbStatusPrePregnancy = 'onb_status_prepregnancy';
  static const onbStatusNewMom = 'onb_status_newmom';

  // ─── Pregnant: LMP ───
  static const pregLmp = 'preg_lmp';
  static const pregLmpWhy = 'preg_lmp_why';
  static const pregLmpUnknown = 'preg_lmp_unknown';
  static const pregLmpFutureError = 'preg_lmp_future_error';
  static const pregLmpConfirm = 'preg_lmp_confirm';
  static const pregLmpStageT1 = 'preg_lmp_stage_t1';
  static const pregLmpStageT2 = 'preg_lmp_stage_t2';
  static const pregLmpStageT3 = 'preg_lmp_stage_t3';

  // ─── Pregnant: EDD ───
  static const pregEddBubble = 'preg_edd_bubble';
  static const pregEddDays = 'preg_edd_days';
  static const pregEddCountdownFar = 'preg_edd_countdown_far';
  static const pregEddCountdownHalf = 'preg_edd_countdown_half';
  static const pregEddCountdownNear = 'preg_edd_countdown_near';
  static const pregEddCountdownSoon = 'preg_edd_countdown_soon';
  static const pregEddDoctorDate = 'preg_edd_doctor_date';
  static const pregEddSaved = 'preg_edd_saved';

  // ─── Pregnant: family & siblings ───
  static const pregPartner = 'preg_partner';
  static const pregPartnerDad = 'preg_partner_dad';
  static const pregPartnerSkip = 'preg_partner_skip';
  static const pregPartnerSaved = 'preg_partner_saved';
  static const pregKids = 'preg_kids';
  static const pregKidsYes = 'preg_kids_yes';
  static const pregKidsNo = 'preg_kids_no';
  static const sibAdd = 'sib_add';
  static const sibGender = 'sib_gender';
  static const sibNameBrother = 'sib_name_brother';
  static const sibNameSister = 'sib_name_sister';
  static const sibDobBrother = 'sib_dob_brother';
  static const sibDobSister = 'sib_dob_sister';
  static const sibSavedBrother = 'sib_saved_brother';
  static const sibSavedSister = 'sib_saved_sister';

  // ─── Pregnant: done + home ───
  static const pregSetupDone = 'preg_setup_done';
  static const pregHomeWelcome = 'preg_home_welcome';
  static const pregHomeMicHint = 'preg_home_mic_hint';
  static const pregHomeFirstQuestion = 'preg_home_first_question';

  // ─── Pre-pregnancy ───
  static const preCycle = 'pre_cycle';
  static const preCycleLength = 'pre_cycle_length';
  static const preCycleIrregular = 'pre_cycle_irregular';
  static const preCycleSaved = 'pre_cycle_saved';
  static const preFolicAcid = 'pre_folic_acid';
  static const preHabits = 'pre_habits';
  static const prePartner = 'pre_partner';
  static const preKids = 'pre_kids';
  static const preSetupDone = 'pre_setup_done';
  static const preHomeWelcome = 'pre_home_welcome';
  static const preHomeWaiting = 'pre_home_waiting';
  static const preHomeFirstQuestion = 'pre_home_first_question';

  // ─── New mom ───
  static const newBabyName = 'new_baby_name';
  static const newBabyNameReaction = 'new_baby_name_reaction';
  static const newBabyDob = 'new_baby_dob';
  static const newBabyGender = 'new_baby_gender';
  static const newBabySaved = 'new_baby_saved';
  static const newBabyTwin = 'new_baby_twin';
  static const newFeedingIntro = 'new_feeding_intro';
  static const newAllocryIntro = 'new_allocry_intro';
  static const newVaccineIntro = 'new_vaccine_intro';
  static const newPartner = 'new_partner';
  static const newKids = 'new_kids';
  static const newChildrenList = 'new_children_list';
  static const newSetupDone = 'new_setup_done';
  static const newHomeWelcome = 'new_home_welcome';
  static const newHomeFirstQuestion = 'new_home_first_question';
  static const newHomeMotherCare = 'new_home_mother_care';

  // ─── Shared across the whole flow ───
  static const onbAlmostDone = 'onb_almost_done';
  static const onbBack = 'onb_back';
  static const onbPermMic = 'onb_perm_mic';
  static const onbPermNotification = 'onb_perm_notification';
  static const onbOfflineNote = 'onb_offline_note';

  // ══════════════════════════════════════════════════════════════════════
  // In-app screens
  //
  // Everything above is said once, on the way in. Everything below belongs to
  // the app she lives in afterwards: one line introducing each screen, and a
  // `pgConf*` line for each thing she saves.
  // ══════════════════════════════════════════════════════════════════════

  // ─── Home ───
  static const pgHomeOpen = 'pg_home_open';
  static const pgHomeCare = 'pg_home_care';
  static const pgHomeSummary = 'pg_home_summary';
  static const pgHomeVitals = 'pg_home_vitals';

  // ─── Pregnancy journey ───
  static const pgJourneyOpen = 'pg_journey_open';
  static const pgJourneyUpcoming = 'pg_journey_upcoming';
  static const pgJourneyBabies = 'pg_journey_babies';
  static const pgJourneyComplete = 'pg_journey_complete';
  static const pgJourneyDelete = 'pg_journey_delete';

  // ─── Welcome your baby (completing the pregnancy), one per step ───
  static const pgBirthDate = 'pg_birth_date';
  static const pgBirthDetails = 'pg_birth_details';
  static const pgBirthPhoto = 'pg_birth_photo';

  // ─── Care schedules ───
  static const pgAncOpen = 'pg_anc_open';
  static const pgAncEmpty = 'pg_anc_empty';
  static const pgLabOpen = 'pg_lab_open';
  static const pgLabEmpty = 'pg_lab_empty';
  static const pgVaccOpen = 'pg_vacc_open';
  static const pgVaccEmpty = 'pg_vacc_empty';

  // ─── Vitals ───
  static const pgVitalsOpen = 'pg_vitals_open';
  static const pgVitalsBp = 'pg_vitals_bp';
  static const pgVitalsGlucose = 'pg_vitals_glucose';
  static const pgVitalsHb = 'pg_vitals_hb';
  static const pgVitalsEmpty = 'pg_vitals_empty';

  // ─── Nutrition ───
  static const pgNutritionOpen = 'pg_nutrition_open';
  static const pgNutritionMeal = 'pg_nutrition_meal';
  static const pgNutritionWater = 'pg_nutrition_water';
  static const pgNutritionSnacks = 'pg_nutrition_snacks';
  static const pgNutritionReminder = 'pg_nutrition_reminder';

  // ─── Feeds ───
  static const pgFeedsOpen = 'pg_feeds_open';
  static const pgFeedsRecipe = 'pg_feeds_recipe';
  static const pgFeedsOffline = 'pg_feeds_offline';

  // ─── Family ───
  static const pgFamilyOpen = 'pg_family_open';
  static const pgFamilyEmpty = 'pg_family_empty';
  static const pgFamilyCreate = 'pg_family_create';
  static const pgFamilyCreated = 'pg_family_created';
  static const pgFamilyJoin = 'pg_family_join';
  static const pgFamilyJoined = 'pg_family_joined';
  static const pgFamilyCode = 'pg_family_code';

  // ─── Community ───
  static const pgCommunityOpen = 'pg_community_open';
  static const pgCommunityOffline = 'pg_community_offline';
  static const pgCommunityDisclaimer = 'pg_community_disclaimer';

  // ─── Settings ───
  static const pgSettingsOpen = 'pg_settings_open';
  static const pgSettingsProfile = 'pg_settings_profile';
  static const pgSettingsTimeline = 'pg_settings_timeline';
  static const pgSettingsBand = 'pg_settings_band';
  static const pgSettingsBandMac = 'pg_settings_band_mac';
  static const pgSettingsBandOk = 'pg_settings_band_ok';
  static const pgSettingsLanguage = 'pg_settings_language';
  static const pgSettingsVoice = 'pg_settings_voice';

  // ─── Reminders ───
  static const pgRemindersOpen = 'pg_reminders_open';
  static const pgRemindersWater = 'pg_reminders_water';
  static const pgRemindersMedicine = 'pg_reminders_medicine';
  static const pgRemindersAdd = 'pg_reminders_add';

  // ─── AlloBot ───
  static const pgAllobotOpen = 'pg_allobot_open';
  static const pgAllobotListening = 'pg_allobot_listening';
  static const pgAllobotTopics = 'pg_allobot_topics';
  static const pgAllobotOffline = 'pg_allobot_offline';
  static const pgAllobotDisclaimer = 'pg_allobot_disclaimer';

  // ─── Confirmations ───
  static const pgConfReminderSet = 'pg_conf_reminder_set';
  static const pgConfReminderWater = 'pg_conf_reminder_water';
  static const pgConfReminderMedicine = 'pg_conf_reminder_medicine';
  static const pgConfReminderMeal = 'pg_conf_reminder_meal';
  static const pgConfReminderSleep = 'pg_conf_reminder_sleep';
  static const pgConfReminderOff = 'pg_conf_reminder_off';
  static const pgConfReminderTime = 'pg_conf_reminder_time';
  static const pgConfReminderDeleted = 'pg_conf_reminder_deleted';
  static const pgConfAncSaved = 'pg_conf_anc_saved';
  static const pgConfLabSaved = 'pg_conf_lab_saved';
  static const pgConfVaccSaved = 'pg_conf_vacc_saved';
  static const pgConfVitalsSaved = 'pg_conf_vitals_saved';
  static const pgConfMealSaved = 'pg_conf_meal_saved';
  static const pgConfWaterAdded = 'pg_conf_water_added';
  static const pgConfBandSaved = 'pg_conf_band_saved';
  static const pgConfProfileSaved = 'pg_conf_profile_saved';
  static const pgConfLanguageSaved = 'pg_conf_language_saved';
  static const pgConfVoiceSaved = 'pg_conf_voice_saved';
  static const pgConfBabyAdded = 'pg_conf_baby_added';
  static const pgConfJourneyDone = 'pg_conf_journey_done';
  static const pgConfFamilySaved = 'pg_conf_family_saved';

  // ─── Screen Info Intent Keys ───
  static const screenAllocryInfo = 'screen_allocry_info';
  static const screenBabyMilestonesInfo = 'screen_baby_milestones_info';
  static const screenBabyVaccinesInfo = 'screen_baby_vaccines_info';
  static const screenBabyProfileInfo = 'screen_baby_profile_info';
  static const screenDailyActivityInfo = 'screen_daily_activity_info';
  static const screenAskAlloInfo = 'screen_ask_allo_info';
  static const screenAgentsInfo = 'screen_agents_info';
  static const screenAllobotChatInfo = 'screen_allobot_chat_info';
  static const screenAllobotSettingsInfo = 'screen_allobot_settings_info';
  static const screenFeedingTrackerInfo = 'screen_feeding_tracker_info';
  static const screenFeedsInfo = 'screen_feeds_info';
  static const screenHomeInfo = 'screen_home_info';
  static const screenHomeCareInfo = 'screen_home_care_info';
  static const screenHomeNutritionInfo = 'screen_home_nutrition_info';
  static const screenHomeVitalsInfo = 'screen_home_vitals_info';
  static const screenKickCounterInfo = 'screen_kick_counter_info';
  static const screenMyCyclePhaseInfo = 'screen_my_cycle_phase_info';
  static const screenMyCycleTrackerInfo = 'screen_my_cycle_tracker_info';
  static const screenMyHealthInfo = 'screen_my_health_info';
  static const screenMyPrescriptionsInfo = 'screen_my_prescriptions_info';
  static const screenMyProfileInfo = 'screen_my_profile_info';
  static const screenMyReportsInfo = 'screen_my_reports_info';
  static const screenMyVitalsInfo = 'screen_my_vitals_info';
  static const screenPeopleCommunityInfo = 'screen_people_community_info';
  static const screenPeopleFamilyInfo = 'screen_people_family_info';
  static const screenPregnancyJourneyInfo = 'screen_pregnancy_journey_info';
  static const screenRegisterPregnancyInfo = 'screen_register_pregnancy_info';
  static const screenSettingsInfo = 'screen_settings_info';
  static const screenPregnancyVaccinesInfo = 'screen_pregnancy_vaccines_info';
  static const screenAncCareInfo = 'screen_anc_care_info';
  static const screenReportsScansInfo = 'screen_reports_scans_info';
  static const screenStepsAnalysisInfo = 'screen_steps_analysis_info';
  static const screenSleepAnalysisInfo = 'screen_sleep_analysis_info';
  static const screenHeartRateAnalysisInfo = 'screen_heart_rate_analysis_info';
  static const screenBloodOxygenAnalysisInfo = 'screen_blood_oxygen_analysis_info';
  static const screenBloodPressureAnalysisInfo = 'screen_blood_pressure_analysis_info';
  static const screenStressAnalysisInfo = 'screen_stress_analysis_info';
  static const screenBloodGlucoseAnalysisInfo = 'screen_blood_glucose_analysis_info';
  static const screenWaterTrackingInfo = 'screen_water_tracking_info';
  static const screenBodyCompositionInfo = 'screen_body_composition_info';
  static const screenHemoglobinAnalysisInfo = 'screen_hemoglobin_analysis_info';
  static const screenHrvAnalysisInfo = 'screen_hrv_analysis_info';

  // ─── Screen Hint Intent Keys (Played on subsequent visits / sheets) ───
  static const screenAllocryHint = 'screen_allocry_hint';
  static const screenBodyCompositionHint = 'screen_body_composition_hint';
  static const screenHemoglobinAnalysisHint = 'screen_hemoglobin_analysis_hint';
  static const screenHrvAnalysisHint = 'screen_hrv_analysis_hint';
  static const screenBabyMilestonesHint = 'screen_baby_milestones_hint';
  static const screenBabyVaccinesHint = 'screen_baby_vaccines_hint';
  static const screenBabyProfileHint = 'screen_baby_profile_hint';
  static const screenDailyActivityHint = 'screen_daily_activity_hint';
  static const screenAskAlloHint = 'screen_ask_allo_hint';
  static const screenAgentsHint = 'screen_agents_hint';
  static const screenAllobotChatHint = 'screen_allobot_chat_hint';
  static const screenAllobotSettingsHint = 'screen_allobot_settings_hint';
  static const screenFeedingTrackerHint = 'screen_feeding_tracker_hint';
  static const screenFeedsHint = 'screen_feeds_hint';
  static const screenHomeCareHint = 'screen_home_care_hint';
  static const screenHomeNutritionHint = 'screen_home_nutrition_hint';
  static const screenHomeVitalsHint = 'screen_home_vitals_hint';
  static const screenKickCounterHint = 'screen_kick_counter_hint';
  static const screenMyCyclePhaseHint = 'screen_my_cycle_phase_hint';
  static const screenMyCycleTrackerHint = 'screen_my_cycle_tracker_hint';
  static const screenMyHealthHint = 'screen_my_health_hint';
  static const screenMyPrescriptionsHint = 'screen_my_prescriptions_hint';
  static const screenMyProfileHint = 'screen_my_profile_hint';
  static const screenMyReportsHint = 'screen_my_reports_hint';
  static const screenMyVitalsHint = 'screen_my_vitals_hint';
  static const screenPeopleCommunityHint = 'screen_people_community_hint';
  static const screenPeopleFamilyHint = 'screen_people_family_hint';
  static const screenPregnancyJourneyHint = 'screen_pregnancy_journey_hint';
  static const screenRegisterPregnancyHint = 'screen_register_pregnancy_hint';
  static const screenSettingsHint = 'screen_settings_hint';
  static const screenPregnancyVaccinesHint = 'screen_pregnancy_vaccines_hint';
  static const screenAncCareHint = 'screen_anc_care_hint';
  static const screenReportsScansHint = 'screen_reports_scans_hint';
  static const screenStepsAnalysisHint = 'screen_steps_analysis_hint';
  static const screenSleepAnalysisHint = 'screen_sleep_analysis_hint';
  static const screenHeartRateAnalysisHint = 'screen_heart_rate_analysis_hint';
  static const screenBloodOxygenAnalysisHint = 'screen_blood_oxygen_analysis_hint';
  static const screenBloodPressureAnalysisHint = 'screen_blood_pressure_analysis_hint';
  static const screenStressAnalysisHint = 'screen_stress_analysis_hint';
  static const screenBloodGlucoseAnalysisHint = 'screen_blood_glucose_analysis_hint';
  static const screenWaterTrackingHint = 'screen_water_tracking_hint';
  static const screenAddReportHint = 'screen_add_report_hint';
  static const screenLogBreakfastHint = 'screen_log_breakfast_hint';
  static const screenLogLunchHint = 'screen_log_lunch_hint';
  static const screenLogDinnerHint = 'screen_log_dinner_hint';
  static const screenLogSnacksHint = 'screen_log_snacks_hint';
  static const screenLogDrinkHint = 'screen_log_drink_hint';
  static const screenChildrenDetailsHint = 'screen_children_details_hint';
  static const screenAddBabyBirthDateHint = 'screen_add_baby_birth_date_hint';
  static const screenAddBabyDetailsHint = 'screen_add_baby_details_hint';
  static const screenAddBabyPhotoHint = 'screen_add_baby_photo_hint';
  static const screenAddPrescriptionUploadHint = 'screen_add_prescription_upload_hint';
  static const screenAddPrescriptionMedicinesHint = 'screen_add_prescription_medicines_hint';

  // ─── AlloCry Cry Results ───
  static const hungerCryMom = 'hunger_cry_mom';
  static const hungerCryDad = 'hunger_cry_dad';
  static const sleepCryMom = 'sleep_cry_mom';
  static const sleepCryDad = 'sleep_cry_dad';
  static const burpingCryMom = 'burping_cry_mom';
  static const burpingCryDad = 'burping_cry_dad';
  static const discomfortCryMom = 'discomfort_cry_mom';
  static const discomfortCryDad = 'discomfort_cry_dad';
  static const colicCryMom = 'colic_cry_mom';
  static const colicCryDad = 'colic_cry_dad';
  static const attentionCryMom = 'attention_cry_mom';
  static const attentionCryDad = 'attention_cry_dad';
}
