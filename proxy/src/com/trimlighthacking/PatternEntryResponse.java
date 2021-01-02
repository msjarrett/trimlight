package com.trimlighthacking;

import sun.plugin2.util.ColorUtil;

import java.awt.*;
import java.util.Arrays;

public class PatternEntryResponse extends Response {
    public PatternEntryResponse(byte[] buffer) {
        this.PatternIndex = buffer[1] & 0xFF;
        byte[] patternNameBytes = Arrays.copyOfRange(buffer, 2, 27);
        this.PatternName = new String(patternNameBytes);
        for(int i = 0; i < 7; i++) {
            Lengths[i] = buffer[31 + i] & 0xFF;
        }

        for(int i = 0; i < 7; i++) {
            int tripletStart = i * 3 + 38;
            int r = buffer[tripletStart + 0] & 0xFF;
            int g = buffer[tripletStart + 1] & 0xFF;
            int b = buffer[tripletStart + 2] & 0xFF;
            Colors[i] = new Color(r,g,b);
        }
        // Reduce to interesting slice
        this.rawBytes = Arrays.copyOfRange(buffer, 2, buffer.length - 1);
    }

    public int PatternIndex;
    public String PatternName;
    public int[] Lengths = new int[7];
    public Color[] Colors = new Color[7];

    public String toString() {
        String formattedByteArray = ByteArrayFormatter.format(this.rawBytes, this.rawBytes.length);
        StringBuilder sb = new StringBuilder();
        for(int i = 0; i < 7; i++) {
            sb.append(Colors[i].toString().replace("java.awt.Color", ""));
            sb.append(" x ");
            sb.append(Lengths[i]);
            sb.append(" ");
        }
        return String.format("%s <Pattern Entry Response> #%d \"%s\" %s", this.LogPrefix, this.PatternIndex, this.PatternName, sb.toString());
    }
}
