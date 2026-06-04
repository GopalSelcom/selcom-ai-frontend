package com.example.selcom_identy_plugin;

import android.app.Activity;
import android.util.Base64;

import com.identy.GuideNoGuideHelper;
import com.identy.IdentyResponseListener;
import com.identy.IdentySdk;
import com.identy.InitializationListener;
import com.identy.InlineGuideOption;
import com.identy.QualityMode;
import com.identy.enums.FingerMatchSecLevel;
import com.identy.exceptions.AttemptsExceededLimitException;
import com.identy.exceptions.TimeoutExceededLimitModeException;
import com.identy.WSQCompression;
import com.identy.enums.Template;

import java.lang.Exception;
import java.util.ArrayList;
import java.util.List;

import com.identy.enums.Finger;
import com.identy.TemplateSize;

import java.util.HashMap;

import com.identy.exceptions.AttemptsExceededLimitException;
import com.identy.exceptions.NoDetectionModeException;
import com.identy.exceptions.TimeoutExceededLimitModeException;

import android.util.Log;

import com.example.selcom_identy_plugin.IdentyUtils;

/**
 * 1. Init IdentyHelper class in Activity where finger scanning will be performed.
 * IdentyHelper identyHelper = new IdentyHelper();
 * identyHelper.setListener(new IdentyResponseListener() {
 *
 * @Override public void onAttempt(Hand hand, int i, Map<Finger, Attempt> map) {
 * }
 * @Override public void onResponse(IdentyResponse identyResponse, HashSet<String> hashSet) {
 * try {
 * JSONObject jo = identyResponse.toJson(FingerPrintActivity.this);
 * setUpFingerPrintResultIdenty(jo);
 * } catch (Exception e) {
 * }
 * }
 * @Override public void onErrorResponse(IdentyError identyError, HashSet<String> hashSet) {
 * if (hashSet != null) {
 * if (identyError.getError() == ERRORS.LICENSE_ERROR
 * || identyError.getError() == ERRORS.LICENSE_EMPTY
 * || identyError.getError() == ERRORS.EXCEEDED_TRANSACTION_LIMIT
 * || identyError.getError() == ERRORS.LICENSE_NOT_EXIST
 * || identyError.getError() == ERRORS.LICENSE_SERVER_NOT_CONNECTED
 * || identyError.getError() == ERRORS.LICENSE_VALIDATION_FAILED) {
 * if (BuildConfig.DEBUG) {
 * Toast.makeText(FingerPrintActivity.this, identyError.getMessage(), Toast.LENGTH_SHORT).show();
 * } else {
 * Toast.makeText(FingerPrintActivity.this, "Something went wrong. Please try again.", Toast.LENGTH_SHORT).show();
 * }
 * } else if (identyError.getError() == ERRORS.TIMED_OUT) {
 * Toast.makeText(Activity, "Timeout", Toast.LENGTH_SHORT).show();
 * }
 * }
 * }
 * }); -> Listener for callbacks
 * identyHelper.initIdenty(this); -> Pass activity
 * <p>
 * <p>
 * 2. For Missing Fingers
 * Pass int array of size 4. where 1 -> finger present, 0 -> missing finger
 * [1,1,1,1] ->  IdentyUtils.saveSelectionForFingers(missingArray);
 * <p>
 * <p>
 * 3. To select hand
 * For Left Hand -> IdentyUtils.setIsLeft4FSelected(true);
 * For Right Hand -> IdentyUtils.setIsRight4FSelected(true);
 * <p>
 * <p>
 * 4. Launch scanner
 * IdentyHelper.getInstance().capture();
 */

public class IdentyHelper {

    private static IdentySdk mIdentySdk;

    public static IdentySdk getInstance() {
        return mIdentySdk;
    }

    public IdentyHelper() {
    }

    private IdentyResponseListener mResponseListener;

    public void setListener(IdentyResponseListener identyResponseListener) {
        this.mResponseListener = identyResponseListener;
    }

    // public void initIdenty(Activity activity) {
    public void initIdenty(Activity activity, Boolean leftHandSelected, Boolean rightHandSelected, List<Integer> leftHandMissingArray, List<Integer> rightHandMissingArray, String licenseFile) {
        // Use leftHandSelected and rightHandSelected here as needed
        Log.d("DART/NATIVE", "Initializing identy with leftHandSelected: " + leftHandSelected + ", rightHandSelected: " + rightHandSelected);
        Log.d("DART/NATIVE", "initIdenty before try block");
        Log.d("DART/NATIVE", "activity" + activity.toString());
        Log.d("DART/NATIVE", "LICENSE_FILE 1" + licenseFile);
        Log.d("DART/NATIVE", "IdentyUtils.LISTENER" + this.mResponseListener.toString());
        try {
            Log.d("DART/NATIVE", "LICENSE_FILE 2" + licenseFile);

            IdentySdk.newInstance(activity, licenseFile, new InitializationListener<IdentySdk>() {
                        @Override
                        public void onInit(IdentySdk identySdk) {
                            Log.d("DART/NATIVE", "initIdenty helper oninit called");
                            mIdentySdk = identySdk;

                            mIdentySdk.setBase64EncodingFlag(Base64.DEFAULT);
                            String uiMode = IdentyUtils.BOXES;

                            switch (uiMode) {
                                case IdentyUtils.BOXES:
                                    mIdentySdk.setDisplayBoxes(true, false);
                                    break;
                                case IdentyUtils.SCANNING_BAR:
                                    mIdentySdk.setDisplayBoxes(false, false);
                                    break;
                                case IdentyUtils.IMAGE:
                                    // mIdentySdk.setFingerPrintDrawable(R.drawable.splash_logo, true);
                                    break;
                                case IdentyUtils.IMAGE_WITH_OUTERBOX:
                                    // mIdentySdk.setFingerPrintDrawable(R.drawable.splash_logo, false);
                                    break;
                            }

                            mIdentySdk.setAllowTabletLandscape(false);
                            mIdentySdk.setAllowVerificationAfterSpoof(false);
                            try {
                                 mIdentySdk.setMode("demo");
                                Log.d("DART/NATIVE", "Mode => Demo" );

//                                mIdentySdk.setMode("commercial");
                            } catch (Exception e) {
                            }
                            mIdentySdk.setQualityMode(QualityMode.VERIFICATION);
                            mIdentySdk.displayResult(false);
                            mIdentySdk.setMatchSecLevel(FingerMatchSecLevel.MEDIUM);
//                            mIdentySdk.disableQC();
                            mIdentySdk.disableDisplayTransactionAlerts(); // disable transactions alerts if you want to customize the UI
                            try {
                                mIdentySdk.setAttemptsTimeout(5, 30);
                            } catch (AttemptsExceededLimitException | TimeoutExceededLimitModeException e) {
                                throw new RuntimeException(e);
                            }

                            GuideNoGuideHelper.markIntroSetting(activity, false);
                            mIdentySdk.disableMoveNextDetectionDialog(); // disable nextHand and backbutton popups

                            InlineGuideOption inlineGuideOption = new InlineGuideOption(300, 10);
                            mIdentySdk.setInlineGuide(true, inlineGuideOption);

                            // IdentyUtils.saveSelectionForFingers(missingArray);
                            // IdentyUtils.setIsLeft4FSelected(true);
                            IdentyUtils.setIsLeft4FSelected(leftHandSelected);
                            IdentyUtils.setIsRight4FSelected(rightHandSelected);

                            // IdentyUtils.saveSelectionForFingers(new int[]{1, 1, 1, 1});
                            if (leftHandMissingArray == null && rightHandMissingArray == null) {
                                IdentyUtils.saveSelectionForFingers(new int[]{1, 1, 1, 1});
                            } else if (leftHandMissingArray != null && !leftHandMissingArray.isEmpty()) {
                                Log.d("DART/NATIVE", "leftHandMissingArray" + (leftHandMissingArray != null ? leftHandMissingArray.toString() : "null"));
                                IdentyUtils.saveSelectionForFingers(convertToIntArray(leftHandMissingArray));
                            } else if (rightHandMissingArray != null && !rightHandMissingArray.isEmpty()) {
                                Log.d("DART/NATIVE", "rightHandMissingArray" + (rightHandMissingArray != null ? rightHandMissingArray.toString() : "null"));
                                IdentyUtils.saveSelectionForFingers(convertToIntArray(rightHandMissingArray));
                            } else {
                                IdentyUtils.saveSelectionForFingers(new int[]{1, 1, 1, 1});
                                Log.d("DART/NATIVE", "Both arrays are null");
                            }
                            IdentyUtils.updateIntent(activity);
                            GuideNoGuideHelper.markIntroSetting(activity, true);
                            WSQCompression compression = WSQCompression.valueOf("WSQ_10_1");
                            HashMap<Template, HashMap<Finger, ArrayList<TemplateSize>>> templatesConfig = IdentyUtils.getTemplatesConfig();
                            mIdentySdk.displayImages(false).setRequiredTemplates(templatesConfig).setWSQCompression(compression).setDetectionMode(IdentyUtils.getDetectionModes());

                            Log.d("DART/NATIVE", "before try");
                            try {
                                mIdentySdk.capture();
                            } catch (NoDetectionModeException e) {
                                throw new RuntimeException(e);
                            } catch (AttemptsExceededLimitException e) {
                                throw new RuntimeException(e);
                            } catch (TimeoutExceededLimitModeException e) {
                                throw new RuntimeException(e);
                            }


                        }
                    },
                    this.mResponseListener
                    , true, true);
        } catch (Exception e) {
            Log.d("DART/NATIVE", "catch");

        }
        Log.d("DART/NATIVE", "after catch");
    }

    private int[] convertToIntArray(List<Integer> list) {
        if (list == null) return null;
        int[] array = new int[list.size()];
        for (int i = 0; i < list.size(); i++) {
            array[i] = list.get(i);
        }
        return array;
    }

}
