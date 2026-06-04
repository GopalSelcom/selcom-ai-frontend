package com.example.selcom_identy_plugin;


import android.os.Bundle;
import android.widget.Toast;


import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.identy.Attempt;
import com.identy.ERRORS;
import com.identy.IdentyError;
import com.identy.IdentyResponse;
import com.identy.IdentyResponseListener;
import com.identy.enums.Finger;
import com.identy.enums.Hand;

import android.app.Activity;

import java.util.List;

import org.json.JSONObject;

import android.util.Log;

import java.util.HashSet;
import java.util.Map;

import android.content.Intent;

import java.util.ArrayList;

public class TempActivity extends AppCompatActivity {

    private Boolean leftHandSelected;
    private Boolean rightHandSelected;
    private List<Integer> leftHandMissingArray;
    private List<Integer> rightHandMissingArray;
    private String licenseFile;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_temp);
        Log.d("DART/NATIVE", "method call is here 22");
        Intent intent = getIntent();
        leftHandSelected = intent.getBooleanExtra("leftHandSelected", false);
        rightHandSelected = intent.getBooleanExtra("rightHandSelected", false);
        leftHandMissingArray = intent.getIntegerArrayListExtra("leftHandMissingArray");
        rightHandMissingArray = intent.getIntegerArrayListExtra("rightHandMissingArray");
        licenseFile = intent.getStringExtra("licenseFile");

        Log.d("DART/NATIVE", "Received in TempActivity - leftHandSelected: " + leftHandSelected + ", rightHandSelected: " + rightHandSelected);
        initIdenty();
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
                try {
                    JSONObject jo = identyResponse.toJson(TempActivity.this);
                    String response = jo.toString();
                    Log.d("DART/NATIVE", "onResponse " + response);
                    Intent intent = new Intent();
                    intent.putExtra("fingerResponse", response);
                    setResult(Activity.RESULT_OK, intent);
                    finish();
                } catch (Exception e) {
                }

            }

            @Override
            public void onErrorResponse(IdentyError identyError, HashSet<String> hashSet) {
                Log.d("DART/NATIVE", "onErrorResponse" + identyError.getError().toString());
                if (hashSet != null) {
                    if (identyError.getError() == ERRORS.LICENSE_ERROR
                            || identyError.getError() == ERRORS.LICENSE_EMPTY
                            || identyError.getError() == ERRORS.EXCEEDED_TRANSACTION_LIMIT
                            || identyError.getError() == ERRORS.LICENSE_NOT_EXIST
                            || identyError.getError() == ERRORS.LICENSE_SERVER_NOT_CONNECTED
                            || identyError.getError() == ERRORS.LICENSE_VALIDATION_FAILED) {
                        // if (BuildConfig.DEBUG) {
                        // } else {
                        // }
                    } else if (identyError.getError() == ERRORS.TIMED_OUT) {
                    }
                }
            }
        });
        identyHelper.initIdenty(this, leftHandSelected, rightHandSelected, leftHandMissingArray, rightHandMissingArray, licenseFile);
    }
}