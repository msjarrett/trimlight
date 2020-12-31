package com.trimlighthacking;

import java.util.Arrays;

public class ConnectionResponse extends Response {

    private final int varUnknown1;
    private final int fixedUnknown1;
    private final int fixedUnknown2;
    private final int fixedUnknown3;
    private final int fixedUnknown4;
    private final int fixedUnknown5;

    public ConnectionResponse(byte[] buffer) {

        this.varUnknown1 = buffer[1] & 0xff;
        this.fixedUnknown1 = buffer[2] & 0xff;
        int hostnameLength = buffer[3] & 0xff;
        int hostnameEnd = 4 + hostnameLength;
        byte[] hostname = Arrays.copyOfRange(buffer, 4, hostnameEnd);
        this.HostName = new String(hostname);
        this.fixedUnknown2 = buffer[hostnameEnd] & 0xff;
        this.fixedUnknown3 = buffer[hostnameEnd + 1] & 0xff;
        this.PixelCount = (((buffer[hostnameEnd + 2] & 0xff) << 8) + (buffer[hostnameEnd + 3] & 0xff));
        this.fixedUnknown4 = buffer[hostnameEnd + 4] & 0xff;
        this.fixedUnknown5 = buffer[hostnameEnd + 5] & 0xff;
        // Reduce to interesting slice
        this.rawBytes = Arrays.copyOfRange(buffer, 2, buffer.length - 1);
    }

    public String HostName;
    public int PixelCount;
    @Override
    public String toString() {
        return String.format("%s <Connection Response> HostName: %s PixelCount: %d Unknowns: (Fixed: %02X %02X %02X %02X %02X Var: %02X)", this.LogPrefix, this.HostName, this.PixelCount, fixedUnknown1, fixedUnknown2, fixedUnknown3, fixedUnknown4, fixedUnknown5, varUnknown1);
    }
}
