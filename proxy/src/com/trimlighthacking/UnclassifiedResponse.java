package com.trimlighthacking;

public class UnclassifiedResponse extends Response {
    public String toString() {
        String formattedByteArray = ByteArrayFormatter.format(this.rawBytes, this.rawBytes.length);
        return String.format("%s <Unclassified> %s", this.LogPrefix, formattedByteArray);
    }

    public UnclassifiedResponse(byte[] buffer) {
        this.rawBytes = buffer;
    }
}
