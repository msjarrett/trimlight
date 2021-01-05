package com.knottysoftware.trimlight;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.net.ProtocolException;

public class ServerMessageParser {
  public static Command parseCommand(byte[] data) throws ProtocolException {
    if (data.length < 3 || data[0] != (byte)Protocol.MAGIC_START ||
        data[data.length - 1] != (byte)Protocol.MAGIC_END) {
      throw new ProtocolException("Invalid message: " + Protocol.getHexDump(data));
    }

    Command command = null;
    Command.Type type = getCommandTypeForByte(data[1]);
    if (type == Command.Type.UNKNOWN) {
      throw new ProtocolException(String.format("Unknown command: %02x", data[1]));
    }

    command = new Command(type);
    return command;
  }

  public ServerMessageParser(InputStream is) {
    this.is = is;
  }

  public Command readNextCommand() throws ProtocolException, IOException {
    int b = is.read();
    if (b == -1) {
      // Not a real byte. This is end-of-stream.
      return null;
    }
    if (b != Protocol.MAGIC_START) {
      throw new ProtocolException(String.format("Stream not starting a command: %02x", b));
    }
    ByteArrayOutputStream bs = new ByteArrayOutputStream();
    bs.write(b);
    do {
      b = is.read();
      bs.write(b);
    } while (b != Protocol.MAGIC_END);

    // Even if this throws ProtocolException, we will have read an entire command's worth from
    // the stream, and should be able to read the next command.
    return parseCommand(bs.toByteArray());
  }

  private static Command.Type getCommandTypeForByte(int b) {
    switch (b) {
      case 0x0c:
        return Command.Type.CONNECT;
      case 0x0d:
        return Command.Type.SET_MODE;
      case 0x02:
        return Command.Type.PATTERN_LIB_QUERY;
      case 0x16:
        return Command.Type.PATTERN_LIB_ENTRY_QUERY;
      case 0x06:
        return Command.Type.PATTERN_LIB_SAVE;
      case 0x13:
        return Command.Type.PATTERN_LIB_UPDATE;
      case 0x0a:
        return Command.Type.SET_MANUAL_DISPLAY;
      default:
        return Command.Type.UNKNOWN;
    }
  }

  private InputStream is;
}
