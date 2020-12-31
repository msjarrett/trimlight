package com.trimlighthacking;

public abstract class Request implements TrimlightInterpretable {
    protected String name = null;
    protected byte[] rawBytes;
    protected static final String LogPrefix = "client->server";
}
