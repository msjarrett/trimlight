package com.trimlighthacking;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;

public class Main {

    public static void main(String[] args) {
        System.out.println("TrimLight Proxy v0.000001");

        Server s = new Server(System.out, 12); // log stream, max connections
        try {
            s.addService(new TrimlightProxyServer("192.168.254.50", 8189), 8189);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
