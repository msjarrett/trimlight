Place relevant wire captures here, preferably as pcapng format (which allows comments).

Please add comments in the capture explaining what you were doing at the time.

If using an emulator, I used the following command from a shell:

```
adb shell tcpdump -i eth1 -w /data/trimlight.pcap port 8189
adb pull /data/trimlight.pcap
```
