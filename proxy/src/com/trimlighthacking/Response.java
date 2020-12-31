package com.trimlighthacking;

public abstract class Response implements TrimlightInterpretable {
    protected String name = null;
    protected byte[] rawBytes;
    protected static final String LogPrefix = "server->client";
}
