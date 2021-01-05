package com.knottysoftware.trimlight;

import java.io.IOException;
import java.io.OutputStream;

public class ServerResponseGenerator {
  public ServerResponseGenerator(OutputStream os) {
    this.os = os;
  }

  public void sendConnectResponse(String deviceName) throws IOException {
    os.write(Protocol.MAGIC_START);
    os.write(Protocol.MAGIC_END);
  }

  public void sendPatteryLibraryResponse() throws IOException {
    os.write(Protocol.MAGIC_START);
    os.write(Protocol.MAGIC_END);
  }

  public void sendPatternLibraryEntry() throws IOException {
    os.write(Protocol.MAGIC_START);
    os.write(Protocol.MAGIC_END);
  }

  private OutputStream os;
}
