package com.trimlighthacking;

public class UnclassifiedRequest extends Request {
        public String toString() {
            String formattedByteArray = ByteArrayFormatter.format(this.rawBytes, this.rawBytes.length);
            return String.format("%s <Unclassified> %s", this.LogPrefix, formattedByteArray);
    }

    public UnclassifiedRequest(byte[] buffer) {
        this.rawBytes = buffer;
    }
}
