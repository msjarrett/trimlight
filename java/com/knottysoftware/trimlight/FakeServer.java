package com.knottysoftware.trimlight;

import java.io.IOException;
import java.net.ProtocolException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.logging.Logger;

public class FakeServer {
  public static void main(String[] args) {
    try {
      listenForConnections();
    } catch(Exception e) {
      System.out.println(e);
    }
  }

  private static void listenForConnections() throws IOException {
    Logger l = Logger.getLogger("trimlight.FakeServer");
    ServerSocket ss = new ServerSocket(Protocol.PORT);
    // ss.bind(new java.net.InetSocketAddress("192.168.1.38", Protocol.PORT));
    l.info("Waiting for connections on " + ss.getLocalPort());
    while (true) {
      Socket s = ss.accept();
      Thread t = new Thread(new ServerRunnable(s, l));
      t.start();
         
    }
  }

  private static class ServerRunnable implements Runnable {
    public ServerRunnable(Socket s, Logger l) {
      this.s = s;
      this.l = l;
    }

    @Override
    public void run() {
      l.info("Connected to " + s.getInetAddress());
      try {
        ServerMessageParser messageParser = new ServerMessageParser(s.getInputStream());
        while (!s.isClosed()) {
          try {
            Command cmd = messageParser.readNextCommand();
            if (cmd == null) {
              // Socket should report closed, but it doesn't.
              break;
            }
            l.info(cmd.toString());
          } catch (ProtocolException e) {
            l.warning(e.toString());
            break;
          }
        }
        // Probably already closed, but we should be sure.
        s.close();
      } catch (IOException e) {
        l.severe(e.toString());
      }
      l.info("Finished connection on " + s.getInetAddress());
    }

    private Socket s;
    private Logger l;
  }
}

