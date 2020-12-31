package com.trimlighthacking;

public class RequestResponseFactory {
    public TrimlightInterpretable Create(byte[] buffer, boolean toServer) {
        if(buffer.length < 3) {
            throw new MalformedBufferException("Buffer should be more than three characters long", buffer);
        }
        if(buffer[0] != 0x5A || buffer[buffer.length - 1] != 0xA5) {
            throw new MalformedBufferException("Buffer is not bookended by 0x5A and 0xA5", buffer);
        }

        return null;
    }
}
