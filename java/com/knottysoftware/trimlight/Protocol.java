package com.knottysoftware.trimlight;

/**
 * Common protocol elements shared between client and server.
 */
public class Protocol {
  public static final int PORT = 8189;

  public static final int MAGIC_START = 0x5a;
  public static final int MAGIC_END = 0xa5;

  public static String getHexDump(byte[] blob) {
    StringBuilder sb = new StringBuilder();
    for (byte b : blob) {
      sb.append(String.format("%02x ", b));
    }
    return sb.toString();
  }
}
