# Trimlight protocol

Analysis of wire protocol between a [Trimlight](https://trimlight.com)
controller and the
[com.spled.trimlight 1.1.1](https://play.google.com/store/apps/details?id=com.spled.trimlight) Android app.

## Discovery

When the app is looking for controllers, it attempts to connect to every IP
on the current subnet and send a connect message. Once it receives a response,
presumably to determine the device name, the connection is closed until the user
taps on the device in the discovery list.

## Connection
When the user taps on a listed device the app connects to the controller on
**TCP port 8189**. This connection persists while working with the controller.

The protocol is message-based: all messages start with `5a` and end with `a5`,
with each message capturing a single request or response. So far, all
communication is initiated by the app, and the controller only responds to
commands that are querying information.

## Commands

* Connect
    * Request
        * `0c` - Command.
        * `00 0a` - ?? fixed.
        * `eb 2b 76 14 0c 1b 07 15 35 04` - ?? varying with each connection.
          Is `0a` an array length for this?
    * Response
        * `c9` - ?? varying.
        * `01` - ?? varying 00 or 01.
        * `09 54 72 69 6d 6c 69 67 68 74` - "Trimlight" (assuming 09 is a string length).
          Controller name.
        * `00 00` - ?? fixed.
        * `02 58` - Pixel count? **TODO: Confirm this with a different system.*
        * `03 00` - ?? fixed.
* Controller mode change
    * Request
        * `0d` - Command.
        * `00 01` - ?? fixed.
        * `01` - mode. `00` for timer, `01` for manual.
* Pattern library query root?
    * Occurs when tapping "Enter" in app.
    * Request
        * `02` - Command.
        * `00 00` - ?? fixed.
    * Response
        * `0c 01 02 03 04 05 06 07 08 09 0a 0b 0c` - ?? fixed. Potentially pattern library IDs.
        * `00 01 0a 01 10 1e 17 01 00 01 00 01 00 01 01` - ?? fixed.
* Query pattern library entry
    * Request
        * `16` - Command.
        * `00 01` - ?? fixed.
        * `01` - Pattern library ID.
    * Response (success)
        * `01` - Pattern library ID.
        * `4e 45 57 20 59 45 41 52 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00` -
          "NEW YEAR". Pattern library name. The app limits this to "< 25 characters",
          so this may be a fixed length string. Patterns are padded with either `00`
          or `ff`.
        * `02` - ?? fixed.
        * `00` - Animation: `00` = Static, `01` = Chase forward, `02` = Chase
          backward, `03` = Middle to out, `04` = Out to middle, `05` = Strobe, `06` =
          Fade, `07` = Comet forward, `08` = Comet backward, `09` = Wave forward,
          `0a` = Wave backward, `0b` = Solid fade.
        * `7f` - Speed (0-255).
        * `ff` - Brightness (0-255).
        * `01 00 00 00 00 00 00` - Seven color repetition counts (0-30).
        * `dd 64 14  00 00 00  00 00 00  00 00 00  00 00 00  00 00 00  00 00 00` - Seven
          3-byte RGB settings (red, green, blue, each 0-255).
    * Response (error)
        * 58 `ff` bytes are returned if Pattern library ID is not valid.
* Save to pattern library??
    * Request
        * `06` - Command.
        * `00 3a` - ??.
        * `0e` - Pattern library ID?
        * `77 69 72 65 73 68 61 72 6b 69 6e 67 ff ff ff ff ff ff ff ff ff ff ff ff ff` -
          "wiresharking". Pattern library name.
        * `02 02 7c ff 01 01 01 00 00 00 00 ff 00 00 00 ff 00 00 00 ff 00 00 00 00 00 00 00 00 00 00 00 00` - ??.
    * Response: none.
* Edit pattern?
    * Request
        * `13` - Command.
        * `00 1f` - ??.
        * `01` - potentially pattern?
            * `00` Static.
            * `01` Chase Forward.
            * `02` Chase Backward.
        * `7f 7f 01 01 01 00 00 00 00 ff 00 00 00 ff 00 00 00 ff 00 00 00 00 00 00 00 00 00 00 00 00` - ??.
    * Response: none.        
* Set manual pattern.
    * Request
        * `0a` - Command.
        * `00 03` - ?? fixed.
        * `01` - Manual pattern ID - correspond to the numbers shown on the
          first tab of the app. If adjusting speed or brightness, set to `fa`.
        * `7f` - Speed.
        * `ff` - Brightness.
    * Response: none.
