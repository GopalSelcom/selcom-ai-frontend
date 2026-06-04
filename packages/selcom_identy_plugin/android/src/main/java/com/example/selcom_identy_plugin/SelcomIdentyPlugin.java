package com.example.selcom_identy_plugin;

import com.example.selcom_identy_plugin.R;

import androidx.annotation.NonNull;

import android.app.Activity;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.identy.Attempt;
import com.identy.ERRORS;
import com.identy.GuideNoGuideHelper;
import com.identy.IdentyError;
import com.identy.IdentyResponse;
import com.identy.IdentyResponseListener;
import com.identy.TemplateSize;
import com.identy.WSQCompression;
import com.identy.enums.Finger;
import com.identy.enums.Hand;
import com.identy.enums.Template;
import com.identy.exceptions.AttemptsExceededLimitException;
import com.identy.exceptions.NoDetectionModeException;
import com.identy.exceptions.TimeoutExceededLimitModeException;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.identy.enums.FingerDetectionMode;

import android.widget.Toast;

import java.util.Map;

import org.json.JSONObject;

import com.identy.WSQCompression;

import java.util.ArrayList;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;

import android.util.Log;

import io.flutter.plugin.common.MethodChannel;

import android.content.Intent;

import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;

import android.content.res.Configuration;

import java.util.Locale;

import android.content.Intent;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class SelcomIdentyPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Activity activity;
    private MethodChannel.Result pendingResult;  // To store the result temporarily
    private Boolean leftHandSelected;
    private Boolean rightHandSelected;
    private List<Integer> leftHandMissingArray;
    private List<Integer> rightHandMissingArray;
    private String licenseFile;
    private String languageCode;
    private boolean hasReplied = false;  // Flag to prevent double responses

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "selcom_identy_plugin");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("enrollFinger")) {
            if (activity != null) {
                // Reset the hasReplied flag
                hasReplied = false;
                // Extract arguments
                leftHandSelected = call.argument("leftHandSelected");
                rightHandSelected = call.argument("rightHandSelected");
                leftHandMissingArray = call.argument("leftHandMissingArray");
                rightHandMissingArray = call.argument("rightHandMissingArray");
                licenseFile = call.argument("licenseFile");
                languageCode = call.argument("languageCode");

                Log.d("DART/NATIVE", "Received leftHandSelected: " + leftHandSelected.toString() + ", rightHandSelected: " + rightHandSelected.toString());
                Log.d("DART/NATIVE", "leftHandMissingArray: " + (leftHandMissingArray != null ? leftHandMissingArray.toString() : "null"));
                Log.d("DART/NATIVE", "rightHandMissingArray: " + (rightHandMissingArray != null ? rightHandMissingArray.toString() : "null"));
                Log.d("DART/NATIVE", "licenseFile: " + licenseFile.toString());
                Log.d("DART/NATIVE", "languageCode: " + languageCode.toString());

                pendingResult = result;  // Store the result to be returned later

                initIdenty();
            } else {
                result.error("NO_ACTIVITY", "Plugin not attached to an activity.", null);
            }
        } else {
            result.notImplemented();
        }
    }

    private void initIdenty() {
        IdentyHelper identyHelper = new IdentyHelper();
        identyHelper.setListener(new IdentyResponseListener() {
            @Override
            public void onAttempt(Hand hand, int i, Map<Finger, Attempt> map) {
                Log.d("DART/NATIVE", "onAttempt");
            }

            @Override
            public void onResponse(IdentyResponse identyResponse, HashSet<String> hashSet) {
                Log.d("DART/NATIVE", "onResponse");
                if (!hasReplied) {
                    try {
                        JSONObject jo = identyResponse.toJson(activity);
                        String response = jo.toString();
                        Log.d("DART/NATIVE", "onResponse " + response);
                        pendingResult.success(response);
                        hasReplied = true;  // Mark as replied
                    } catch (Exception e) {
                        pendingResult.success("JSON_ERROR Failed to parse response");
                        hasReplied = true;  // Mark as replied
                    }
                }
            }

            @Override
            public void onErrorResponse(IdentyError identyError, HashSet<String> hashSet) {
                Log.d("DART/NATIVE", "onErrorResponse " + identyError.getError().toString());
                if (!hasReplied) {
                    String errorDescription = identyError.getError().toString();

                    if (identyError.getError() == ERRORS.LICENSE_ERROR
                            || identyError.getError() == ERRORS.LICENSE_EMPTY
                            || identyError.getError() == ERRORS.EXCEEDED_TRANSACTION_LIMIT
                            || identyError.getError() == ERRORS.LICENSE_NOT_EXIST
                            || identyError.getError() == ERRORS.LICENSE_SERVER_NOT_CONNECTED
                            || identyError.getError() == ERRORS.LICENSE_VALIDATION_FAILED
                    ) {
                        pendingResult.success("IDENTY_ERROR :" + errorDescription);
                    } else if( identyError.getError() == ERRORS.TIMED_OUT){
                        if(languageCode.toString().equals("en")){
                            pendingResult.success("IDENTY_ERROR : Scanning timed out. Please try again.");
                        } else{
                            pendingResult.success("IDENTY_ERROR : Uchakataji wa skani umeisha muda. Tafadhali jaribu tena.");
                        }
                    } else if (identyError.getError() == ERRORS.ACTIVITY_PAUSED_ON_BACK_PRESSED) {
                        pendingResult.success("500");
                    } else {
                        pendingResult.success("");
                        // pendingResult.success("IDENTY_ERROR :" + errorDescription);
                    }
                    hasReplied = true;  // Mark as replied
                }
            }

        });
        String languageToLoad = languageCode;
        Locale locale = new Locale(languageToLoad);
        Locale.setDefault(locale);
        Configuration config = new Configuration();
        config.locale = locale;
        activity.getBaseContext().getResources().updateConfiguration(config,
                activity.getBaseContext().getResources().getDisplayMetrics());
        identyHelper.initIdenty(activity, leftHandSelected, rightHandSelected, leftHandMissingArray, rightHandMissingArray, licenseFile);
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }


    @Override
    public void onDetachedFromActivity() {
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activity = null;
    }
}







