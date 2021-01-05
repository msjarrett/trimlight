package com.knottysoftware.trimlight;

public class Command {
  public enum Type {
    UNKNOWN,
    CONNECT,                  // 0x0c
    SET_MODE,                 // 0x0d
    PATTERN_LIB_QUERY,        // 0x02
    PATTERN_LIB_ENTRY_QUERY,  // 0x16
    PATTERN_LIB_SAVE,         // 0x06
    PATTERN_LIB_UPDATE,       // 0x13
    SET_MANUAL_DISPLAY,	      // 0x0a
  }

  public Command(Type type) {
    this.type = type;
  }

  public Type getType() {
    return type;
  }

  @Override
  public String toString() {
    return String.format("Command %s", getType().toString());
  }

  private Type type;
}
