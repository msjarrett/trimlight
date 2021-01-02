package com.trimlighthacking;

import java.util.Arrays;

public class PatternLibraryQueryRequest extends Request {

    private final int fixedUnknown1;
    private final int fixedUnknown2;

    public PatternLibraryQueryRequest(byte[] buffer) {

        this.fixedUnknown1 = buffer[1] & 0xFF;
        this.fixedUnknown2 = buffer[2] & 0xFF;
        // Reduce to interesting slice
        this.rawBytes = Arrays.copyOfRange(buffer, 2, buffer.length - 1);
    }

    public String toString() {
        return String.format("%s <Pattern Library Query Request> Unknowns: (Fixed: %02X %02X)", this.LogPrefix, fixedUnknown1, fixedUnknown2);
    }
}
