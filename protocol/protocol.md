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
        * `00 0a` - ?? fixed. [Confirmed same across two devices -- App version?]
        * `eb 2b 76` ?? varying.
        * `14 0c 1b 07 15 35 04` - Current time: Year Month Day Day-of-week? Hour Minute Second
          
    * Response
        * `c9` - ?? varying.
        * `01` - ?? varying 00 or 01.
        * `09` - String length
        * `54 72 69 6d 6c 69 67 68 74` - "Trimlight" 
          Controller name.
        * `00 00` - ?? fixed. [RGB order?]
        * `02 58` - Pixel count 
        * `03 00` - ?? fixed. [IC?]
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
        `* 00 01 0a 01 10 1e 17 01 00 01 00 01 00 01 01` - ?? fixed.
* Query pattern library entry
    * Request
        * `16` - Command.
        * `00 01` - ?? fixed.
        * `01` - Pattern library ID.
    * Response
        * `01` - Pattern library ID.
        * `4e 45 57 20 59 45 41 52 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00` -
          "NEW YEAR". Pattern library name. The app limits this to "< 25 characters",
          so this may be a fixed legnth string. Existing patterns are padded with `00`,
          while user-added patterns are padded with `ff`.
         * `02 00` - ??
        * `7f` - Speed.
        * `ff` - Brightness.
        * `01 00 00 00 00 00 00 dd 64 14 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`
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
