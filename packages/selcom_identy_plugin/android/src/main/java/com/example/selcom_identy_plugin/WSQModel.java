package com.example.selcom_identy_plugin;

import android.os.Parcel;
import android.os.Parcelable;

import androidx.annotation.NonNull;


public class WSQModel implements Parcelable {
    String fingerIndex;
    String fingerWsq;

    public WSQModel(String fingerIndex, String fingerWsq) {
        this.fingerIndex = fingerIndex;
        this.fingerWsq = fingerWsq;
    }

    protected WSQModel(Parcel in) {
        fingerIndex = in.readString();
        fingerWsq = in.readString();
    }

    public static final Creator<WSQModel> CREATOR = new Creator<WSQModel>() {
        @Override
        public WSQModel createFromParcel(Parcel in) {
            return new WSQModel(in);
        }

        @Override
        public WSQModel[] newArray(int size) {
            return new WSQModel[size];
        }
    };

    public String getFingerWsq() {
        return fingerWsq;
    }

    public void setFingerWsq(String fingerWsq) {
        this.fingerWsq = fingerWsq;
    }

    public String getFingerIndex() {
        return fingerIndex;
    }

    public void setFingerIndex(String fingerIndex) {
        this.fingerIndex = fingerIndex;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(@NonNull Parcel parcel, int i) {
        parcel.writeString(fingerIndex);
        parcel.writeString(fingerWsq);
    }
}
