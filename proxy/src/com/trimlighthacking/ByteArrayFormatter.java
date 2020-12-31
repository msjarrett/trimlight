package com.trimlighthacking;

public class ByteArrayFormatter {
    public static String format(byte[] bytes, int count) {
        StringBuilder out = new StringBuilder(bytes.length * 3);
        if(count > bytes.length) {
            throw new IllegalArgumentException(String.format("Count %d is greater than buffer length %d", count, bytes.length));
        }
        for(int i = 0; i < count; i++) {
            byte b = bytes[i];
            if((b & 0xFF) < 32) {
                out.append(String.format("^%s ", (char)((b & 0xFF) + 64)));
            } else if((b & 0xFF) < 128) {
                out.append(String.format(" %s ", (char)(b)));
            }
            else {
                out.append("   ");
            }

        }
        out.append("\n                                                            ");
        for(int i = 0; i < count; i++) {
            out.append(String.format("%02X ", bytes[i]));
        }
        return out.toString();
    }
}
