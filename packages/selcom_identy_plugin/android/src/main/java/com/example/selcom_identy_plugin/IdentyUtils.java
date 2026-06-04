package com.example.selcom_identy_plugin;

import android.app.Activity;
import com.identy.TemplateSize;
import com.identy.enums.Finger;
import com.identy.enums.FingerDetectionMode;
import com.identy.enums.Template;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class IdentyUtils {
    public static final String LICENSE_FILE = "3723-com.selcombank.dev-30-10-2024.lic";
    public static boolean LEFT_FOUR = true;
    public static boolean RIGHT_FOUR = false;
    public static Set<String> SELECTIONS = new HashSet<>();
    private static FingerDetectionMode[] detectionModes;
    private static HashMap<Finger, ArrayList<TemplateSize>> fingerSizeHP = new HashMap<>();

    public static final String BOXES = "BOXES";
    public static final String SCANNING_BAR = "SCANNING BAR";
    public static final String IMAGE = "IMAGE";
    public static final String IMAGE_WITH_OUTERBOX = "IMAGE WITH OUTERBOX";

    public static void updateIntent(Activity activity) {
        HashMap<Finger, ArrayList<TemplateSize>> fingerSize = new HashMap<>();
        ArrayList<FingerDetectionMode> modes = new ArrayList<>();
        ArrayList<TemplateSize> sizes = new ArrayList<>();
        sizes.add(TemplateSize.DEFAULT);

        if (IdentyUtils.isLeft4FSelected()) {

            List<FingerDetectionMode> fingers = MissingFingerUtils.getLeftMissingFingers();
            if (fingers.isEmpty() || fingers.size() == 4) {
                modes.add(FingerDetectionMode.L4F);
                fingerSize.put(Finger.INDEX, sizes);
                fingerSize.put(Finger.MIDDLE, sizes);
                fingerSize.put(Finger.RING, sizes);
                fingerSize.put(Finger.LITTLE, sizes);
            } else {
                modes.addAll(fingers);
                for (FingerDetectionMode fingerMode : fingers) {
                    String finger = fingerMode.toString().replace("LEFT_", "");
                    fingerSize.put(Finger.valueOf(finger), sizes);
                }
            }
        }

        if (IdentyUtils.isRight4FSelected()) {
            List<FingerDetectionMode> fingers = MissingFingerUtils.getRightMissingFingers();
            if (fingers.isEmpty() || fingers.size() == 4) {
                modes.add(FingerDetectionMode.R4F);
                fingerSize.put(Finger.INDEX, sizes);
                fingerSize.put(Finger.MIDDLE, sizes);
                fingerSize.put(Finger.RING, sizes);
                fingerSize.put(Finger.LITTLE, sizes);
            } else {
                modes.addAll(fingers);
                for (FingerDetectionMode fingerMode : fingers) {
                    String finger = fingerMode.toString().replace("RIGHT_", "");
                    fingerSize.put(Finger.valueOf(finger), sizes);
                }
            }
        }

        setFingerSizeHP(fingerSize);
        setDetectionModes(modes.toArray(new FingerDetectionMode[modes.size()]));
    }

    public static FingerDetectionMode[] getDetectionModes() {
        return detectionModes;
    }

    public static void setDetectionModes(FingerDetectionMode[] detectionModes) {
        IdentyUtils.detectionModes = detectionModes;
    }

    public static HashMap<Finger, ArrayList<TemplateSize>> getFingerSizeHP() {
        return fingerSizeHP;
    }

    public static void setFingerSizeHP(HashMap<Finger, ArrayList<TemplateSize>> fingerSizeHP) {
        IdentyUtils.fingerSizeHP = fingerSizeHP;
    }

    public static boolean isRight4FSelected() {
        return RIGHT_FOUR;
    }

    public static boolean isLeft4FSelected() {
        return LEFT_FOUR;
    }

    public static void setIsRight4FSelected(boolean isSel) {
        RIGHT_FOUR = isSel;
        LEFT_FOUR = !RIGHT_FOUR;
    }

    public static void setIsLeft4FSelected(boolean isSel) {
        LEFT_FOUR = isSel;
        RIGHT_FOUR = !LEFT_FOUR;
    }

    public static Set<String> getMissingFingers() {
        return SELECTIONS;
    }

    public static void setMissingFingers(Set<String> fingers) {
        SELECTIONS = fingers;
    }

    public static HashMap<Template, HashMap<Finger, ArrayList<TemplateSize>>> getTemplatesConfig() {
        // Configuration of desired templates. Adding most of them for illustration purposes
        HashMap<Template, HashMap<Finger, ArrayList<TemplateSize>>> templatesConfig = new HashMap<>();

        HashSet<String> requiredTemplates = new HashSet<>();
        requiredTemplates.add("WSQ");
        requiredTemplates.add("SLAP_WSQ");

        Set<String> templates = requiredTemplates;
        for (String template : templates) {
            templatesConfig.put(Template.valueOf(template), getFingerSizeHP());
        }

        return templatesConfig;
    }

    public static void saveSelectionForFingers(int[] missing) {
        Set<String> selections = new HashSet<>();
        addSelection(selections, missing[0], FingerDetectionMode.LEFT_INDEX);
        addSelection(selections, missing[1], FingerDetectionMode.LEFT_MIDDLE);
        addSelection(selections, missing[2], FingerDetectionMode.LEFT_RING);
        addSelection(selections, missing[3], FingerDetectionMode.LEFT_LITTLE);
        addSelection(selections, missing[0], FingerDetectionMode.RIGHT_INDEX);
        addSelection(selections, missing[1], FingerDetectionMode.RIGHT_MIDDLE);
        addSelection(selections, missing[2], FingerDetectionMode.RIGHT_RING);
        addSelection(selections, missing[3], FingerDetectionMode.RIGHT_LITTLE);
        IdentyUtils.setMissingFingers(selections);
    }

    private static void addSelection(Set<String> selections, int selected, FingerDetectionMode mode) {
        if (selected == 1) {
            selections.add(mode.toString());
        }
    }

    public static ArrayList<WSQModel> getWsqBytesList(JSONObject jsonObject) {
        ArrayList<WSQModel> bytesList = new ArrayList<>();
        try {
            JSONObject jsonFingers = jsonObject.getJSONObject("data");
            String hand = "left";
            if (IdentyUtils.isLeft4FSelected()) {
                hand = "left";
                if (jsonFingers.has("leftindex")){
                    String wsqbyte =
                            getWSQString(jsonFingers, "leftindex");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("L2", wsqbyte));
                    }
                }
                if (jsonFingers.has("leftmiddle")) {
                    String wsqbyte = getWSQString(jsonFingers, "leftmiddle");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("L3", wsqbyte));
                    }
                }
                if (jsonFingers.has("leftring")) {
                    String wsqbyte = getWSQString(jsonFingers, "leftring");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("L4", wsqbyte));
                    }
                }
                if (jsonFingers.has("leftlittle")) {
                    String wsqbyte = getWSQString(jsonFingers, "leftlittle");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("L5", wsqbyte));
                    }
                }
            } else {
                hand = "right";
                if (jsonFingers.has("rightindex")) {
                    String wsqbyte = getWSQString(jsonFingers, "rightindex");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("R2", wsqbyte));
                    }
                }
                if (jsonFingers.has("rightmiddle")) {
                    String wsqbyte = getWSQString(jsonFingers, "rightmiddle");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("R3", wsqbyte));
                    }
                }
                if (jsonFingers.has("rightring")) {
                    String wsqbyte = getWSQString(jsonFingers, "rightring");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("R4", wsqbyte));
                    }
                }
                if (jsonFingers.has("rightlittle")) {
                    String wsqbyte = getWSQString(jsonFingers, "rightlittle");
                    if (wsqbyte != null){
                        bytesList.add(new WSQModel("R5", wsqbyte));
                    }
                }
            }
            return bytesList;
        } catch (JSONException e) {
            return bytesList;
        }
    }

    private static String getWSQString(JSONObject jsonFingers, String index) {
        try {
            String wsq = jsonFingers.getJSONObject(index)
                    .getJSONObject("templates")
                    .getJSONObject("WSQ")
                    .getString("DEFAULT");
            return wsq;
//            return wsq.getBytes(StandardCharsets.UTF_8);
        } catch (JSONException e) {
            return null;
        }
    }

    public static byte[] getBytes(String index) {
        return index.getBytes(StandardCharsets.UTF_8);
    }
}
