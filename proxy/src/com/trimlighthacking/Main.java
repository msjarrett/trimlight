package com.trimlighthacking;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;

public class Main {

    public static void main(String[] args) {
	// write your code here
        System.out.println("Hello world");

        Server s = new Server(System.out, 12); // log stream, max connections
        try {
            s.addService(new TrimlightProxyServer("192.168.254.51", 22), 20022);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
