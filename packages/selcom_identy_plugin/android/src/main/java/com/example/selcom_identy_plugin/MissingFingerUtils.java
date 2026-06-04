package com.example.selcom_identy_plugin;


import com.identy.enums.FingerDetectionMode;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

public class MissingFingerUtils {

    public static List<FingerDetectionMode> getLeftMissingFingers() {
        Set<String> selections = IdentyUtils.getMissingFingers();
        List<FingerDetectionMode> modes = new ArrayList<>();
        if (selections.contains(FingerDetectionMode.LEFT_INDEX.toString())) {
            modes.add(FingerDetectionMode.LEFT_INDEX);
        }
        if (selections.contains(FingerDetectionMode.LEFT_MIDDLE.toString())) {
            modes.add(FingerDetectionMode.LEFT_MIDDLE);
        }
        if (selections.contains(FingerDetectionMode.LEFT_RING.toString())) {
            modes.add(FingerDetectionMode.LEFT_RING);
        }
        if (selections.contains(FingerDetectionMode.LEFT_LITTLE.toString())) {
            modes.add(FingerDetectionMode.LEFT_LITTLE);
        }
        return modes;

    }

    public static List<FingerDetectionMode> getRightMissingFingers() {
        Set<String> selections = IdentyUtils.getMissingFingers();
        List<FingerDetectionMode> modes = new ArrayList<>();

        if (selections.contains(FingerDetectionMode.RIGHT_INDEX.toString())) {
            modes.add(FingerDetectionMode.RIGHT_INDEX);

        }
        if (selections.contains(FingerDetectionMode.RIGHT_MIDDLE.toString())) {
            modes.add(FingerDetectionMode.RIGHT_MIDDLE);

        }
        if (selections.contains(FingerDetectionMode.RIGHT_RING.toString())) {
            modes.add(FingerDetectionMode.RIGHT_RING);

        }
        if (selections.contains(FingerDetectionMode.RIGHT_LITTLE.toString())) {
            modes.add(FingerDetectionMode.RIGHT_LITTLE);

        }
        return modes;
    }

    public static boolean checkNoFingers(int[] selected) {
        if (Arrays.stream(selected).noneMatch(n -> n == 1)) {
            return true;
        }
        return false;
    }

    public static boolean hasAllFingers(int[] selected) {
        if (Arrays.stream(selected).noneMatch(n -> n == 0)) {
            return true;
        }
        return false;
    }

    public static int getMissingCount(int[] selected) {
        return (int) Arrays.stream(selected).filter(n -> n == 0).count();
    }

}
