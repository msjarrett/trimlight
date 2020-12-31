package com.trimlighthacking;

import java.util.Arrays;

public class PatternLibraryQueryResponse extends Response {

    public PatternLibraryQueryResponse(byte[] buffer) {

        /*this.PatternIndex = buffer[1] & 0xFF;
        byte[] patternNameBytes = Arrays.copyOfRange(buffer, 2, 27);
        this.PatternName = new String(patternNameBytes);*/
        // Reduce to interesting slice
        this.rawBytes = Arrays.copyOfRange(buffer, 2, buffer.length - 1);
    }

    public int PatternIndex;
    public String PatternName;

    public String toString() {
        String formattedByteArray = ByteArrayFormatter.format(this.rawBytes, this.rawBytes.length);
        return String.format("%s <Pattern Library Query Response> %s", this.LogPrefix, formattedByteArray);
    }
}
