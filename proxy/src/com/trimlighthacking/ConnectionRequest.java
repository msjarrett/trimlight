package com.trimlighthacking;

import java.util.Arrays;
import java.util.Calendar;
import java.util.GregorianCalendar;

public class ConnectionRequest extends Request {
    private final int fixedUnknown1;
    private final int fixedUnknown2;
    private final int varUnknown1;
    private final int varUnknown2;
    private final int varUnknown3;

    public ConnectionRequest(byte[] buffer) {
        // We don't know what indices 2-6 are used for yet.
        int year = buffer[7] & 0xff;
        int month = buffer[8] & 0xff;
        int day = buffer[9] & 0xff;
        int hour = buffer[11] & 0xff;
        int minute = buffer[12] & 0xff;
        int second = buffer[13] & 0xff;

        this.fixedUnknown1 = buffer[2] & 0xff;
        this.fixedUnknown2 = buffer[3] & 0xff;
        this.varUnknown1 = buffer[4] & 0xff;
        this.varUnknown2 = buffer[5] & 0xff;
        this.varUnknown3 = buffer[6] & 0xff;

        Calendar calendar = new GregorianCalendar();

        calendar.set(Calendar.YEAR, year);
        calendar.set(Calendar.MONTH, month - 1);
        calendar.set(Calendar.DAY_OF_MONTH, day);
        calendar.set(Calendar.HOUR, hour);
        calendar.set(Calendar.MINUTE, minute);
        calendar.set(Calendar.SECOND, second);
        this.ConnectionStartDate = calendar;

        // Reduce to interesting slice
        this.rawBytes = Arrays.copyOfRange(buffer, 2, buffer.length - 1);
    }

    public final Calendar ConnectionStartDate;

    @Override
    public String toString() {
        return String.format("%s <Connection Request> Connection Started: %s Unknowns: (Fixed: %02X %02X Var: %02X %02X %02X)", this.LogPrefix, this.ConnectionStartDate.getTime().toString(), fixedUnknown1, fixedUnknown2, varUnknown1, varUnknown2, varUnknown3);
    }
}
