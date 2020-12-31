package com.trimlighthacking;

import java.util.Arrays;

public class BuiltInPatternSetRequest extends Request {
    private final int fixedUnknown1;
    private final int fixedUnknown2;

    public BuiltInPatternSetRequest(byte[] buffer) {


        this.fixedUnknown1 = buffer[2] & 0xFF;
        this.fixedUnknown2 = buffer[3] & 0xFF;

        this.PatternIndex = buffer[4] & 0xFF;
        this.Speed = buffer[5] & 0xFF;
        this.Brightness = buffer[6] & 0xFF;
        // Reduce to interesting slice
        this.rawBytes = Arrays.copyOfRange(buffer, 2, buffer.length - 1);
    }

    int PatternIndex; // TODO: Enumerate names
    int Speed;
    int Brightness;

    public String toString() {
        return String.format("%s <Built-In Pattern Set Request> Index: %s Speed: %d Brightness: %d Unknowns: (Fixed: %02X %02X)", this.LogPrefix, PatternIndex, Speed, Brightness, fixedUnknown1, fixedUnknown2);
    }
}
