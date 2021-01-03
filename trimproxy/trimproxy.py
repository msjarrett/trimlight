#!/usr/bin/python3

import os
import selectors
import socket
import socketserver
import sys
import time


IO_SIZE = 4096
TRIMLIGHT_PORT = 8189


class TrimlightHandler(socketserver.BaseRequestHandler):

    ControllerAddress = None
    OutputDir = None

    def handle(self):
        print('Got TrimLight connection')
        outpath = os.path.join(TrimlightHandler.OutputDir, time.strftime('%Y-%m-%d-%H-%M-%S'))

        # Probably need to do something more clever than just reading 4k chunks.
        # Is there a framing mechanism in the protocol? Or does each command have a known length?
        # Or... *do* we just read from '5a' to 'af' ?

        data = None
        with open(outpath + '.cli', 'wb') as f:
            data = self.request.recv(IO_SIZE)
            f.write(data)

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
            client.connect((TrimlightHandler.ControllerAddress, TRIMLIGHT_PORT))
            client.sendall(data)
            received = client.recv(IO_SIZE)
            with open(outpath + '.srv', 'wb') as f:
                f.write(received)
            self.request.sendall(received)
        print('Finished TrimLight connection')


def annotate(fileobj, output_dir):
    with open(os.path.join(output_dir, time.strftime('%Y-%m-%d-%H-%M-%S') + '.txt'), 'w') as f:
        f.write(fileobj.readline())


def main(args):
    if len(args) != 3:
        raise ValueError('Usage: trimproxy trimlight-controller-ip-address output-dir')

    controller_address = args[1]
    output_dir = args[2]
    TrimlightHandler.ControllerAddress = controller_address
    TrimlightHandler.OutputDir = output_dir
    
    selector = selectors.DefaultSelector()
    with socketserver.TCPServer((bytes(socket.INADDR_ANY), TRIMLIGHT_PORT), TrimlightHandler) as server:
        print('TrimLight server listening. Type notes on standard input and hit enter.')

        selector.register(server.fileno(), selectors.EVENT_READ, lambda fileobj, mask: server.handle_request())
        selector.register(sys.stdin, selectors.EVENT_READ, lambda fileobj, mask: annotate(fileobj, output_dir))
        
        while True:
            events = selector.select()
            for key, mask in events:
                callback = key.data
                callback(key.fileobj, mask)


if __name__ == '__main__':
    main(sys.argv)
