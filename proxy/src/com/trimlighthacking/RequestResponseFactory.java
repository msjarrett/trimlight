package com.trimlighthacking;

import java.util.Arrays;

public class RequestResponseFactory {
    private static byte previousRequestCode;
    private static final Object LOCK = new Object() {
    };

    private static void setPreviousRequestCode(byte currentRequestCode) {
        synchronized (LOCK) {
            RequestResponseFactory.previousRequestCode = currentRequestCode;
        }
    }

    public static TrimlightInterpretable Create(byte[] buffer, int bytes_read, boolean toServer) {
        if (buffer.length < 3) {
            throw new MalformedBufferException("Buffer should be more than three characters long", buffer);
        }

        byte[] bufferSlice = Arrays.copyOfRange(buffer, 0, bytes_read);

        if ((bufferSlice[0] & 0xFF) != 0x5A || (bufferSlice[bufferSlice.length - 1] & 0xFF) != 0xA5) {
            throw new MalformedBufferException(String.format("Buffer is not bookended by 0x5A and 0xA5. Instead, it has %02X and %02X", bufferSlice[0], bufferSlice[bufferSlice.length - 1]), bufferSlice);
        }

        byte code = buffer[1];
        if (toServer) {
            setPreviousRequestCode(code);
            switch (code & 0xFF) {
                case 0x02:
                    return new PatternLibraryQueryRequest(bufferSlice);
                case 0x0A:
                    return new BuiltInPatternSetRequest(bufferSlice);
                case 0x0C:
                    return new ConnectionRequest(bufferSlice);
                default:
                    return new UnclassifiedRequest(bufferSlice);
            }
        } else {
            switch (previousRequestCode & 0xFF) {
                case 0x02:
                    return new PatternLibraryQueryResponse(bufferSlice);
                case 0x0C:
                    return new ConnectionResponse(bufferSlice);
            }
            switch (code) {
                default:
                    return new UnclassifiedResponse(bufferSlice);
            }
        }
    }
}
