package com.trimlighthacking;

public class MalformedBufferException extends RuntimeException {
    public MalformedBufferException(String message, byte[] buffer) {
        super(message);
        this.buffer = buffer;
    }

    public MalformedBufferException(String message, Throwable cause, byte[] buffer) {
        super(message, cause);
        this.buffer = buffer;
    }

    public MalformedBufferException(Throwable cause, byte[] buffer) {
        super(cause);
        this.buffer = buffer;
    }

    public final byte[] buffer;
}
