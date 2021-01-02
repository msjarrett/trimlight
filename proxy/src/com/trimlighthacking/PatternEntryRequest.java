package com.trimlighthacking;

import java.util.Arrays;

public class PatternEntryRequest extends Request {
    private final int fixedUnknown1;
    private final int fixedUnknown2;

    public PatternEntryRequest(byte[] buffer) {
        this.fixedUnknown1 = buffer[2] & 0xFF;
        this.fixedUnknown2 = buffer[3] & 0xFF;

        this.PatternIndex = buffer[4] & 0xFF;
        // Reduce to interesting slice
        this.rawBytes = Arrays.copyOfRange(buffer, 2, buffer.length - 1);
    }

    public int PatternIndex;

    public String toString() {
        return String.format("%s <Pattern Entry Request> Index: %d Unknowns: (Fixed: %02X %02X)", this.LogPrefix, this.PatternIndex, fixedUnknown1, fixedUnknown2);
    }
}
