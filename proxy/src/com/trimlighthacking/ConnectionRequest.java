package com.trimlighthacking;

import java.util.Arrays;
import java.util.Calendar;
import java.util.GregorianCalendar;

public class ConnectionRequest extends Request {
    private final int fixed_unknown1;
    private final int fixed_unknown2;
    private final int var_unknown3;
    private final int var_unknown4;
    private final int var_unknown5;

    public ConnectionRequest(byte[] buffer) {
        // We don't know what indices 2-6 are used for yet.
        int year = buffer[7] & 0xff;
        int month = buffer[8] & 0xff;
        int day = buffer[9] & 0xff;
        int hour = buffer[11] & 0xff;
        int minute = buffer[12] & 0xff;
        int second = buffer[13] & 0xff;

        this.fixed_unknown1 = buffer[2] & 0xff;
        this.fixed_unknown2 = buffer[3] & 0xff;
        this.var_unknown3 = buffer[4] & 0xff;
        this.var_unknown4 = buffer[5] & 0xff;
        this.var_unknown5 = buffer[6] & 0xff;

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
        return String.format("%s <Connection Request> Connection Started: %s Unknowns: (Fixed: %02X %02X Var: %02X %02X %02X)", this.LogPrefix, this.ConnectionStartDate.getTime().toString(), fixed_unknown1, fixed_unknown2, var_unknown3, var_unknown4, var_unknown5);
    }
}
