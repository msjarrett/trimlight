# Trimlight protocol
Analysis of wire protocol between a [Trimlight](https://trimlight.com)
Select Plus controller and the [com.spled.trimlight 1.2.0](https://play.google.com/store/apps/details?id=com.spled.trimlight)
Android app.


## Discovery
When the app is looking for controllers, it attempts to connect to every IP
on the current subnet and send a connect message. Once it receives a response,
presumably to determine the device name, the connection is closed until the user
taps on the device in the discovery list.


## Connection
When the user taps on a listed device the app connects to the controller on
**TCP port 8189**. This connection persists while working with the controller.

All communication is initiated by the app, and the controller only responds to
commands that are querying information.


## Wifi Network Setup

### Auto Mode
App sends out a bunch of UDP broadcast messages with a payload consisting
entirely of 0x31 bytes, but the length of the payload varies. It starts out
with length 515, 514, 513, and 512 bytes and repeats that many times. After a
while, it sends seemingly random lengths, but always with the entire payload
having each byte set to 0x31.

### Manual Mode
During Manual Network setup, the app sends a "AP Network Config," and later a
"AP Network Config OK" message. Not much is known about these messages yet.

## Message Packet Structure
> :memo: **Note:** These tables are best viewed as rendered Markdown. If viewing
raw, it is best to disable wordwrap to keep each row on a single line.

The protocol is message-based: all messages start with `5a` and end with `a5`,
with each message capturing a single request or response. The protocol uses
standard network byte order (big-endian).

All commands (requests from app to controller) use an envelope (frame) as
follows:

| Byte      | Field                         | Example | Notes                                          |
|-----------|-------------------------------|---------|------------------------------------------------|
| 1         | Start Flag                    | 0x5a    | Every message starts with this value           |
| 2         | [Request Type](#request-type) | 0x0d    | Indicates what request (command) is being made |
| 3 - 4     | Command Length                | 0x00 01 | Length of the command payload, in bytes        |
| 5 - (n-1) | Command Payload               | ...     | Different for every command                    |
| n         | End Flag                      | 0xa5    | Every message ends with this value             |

Responses (from the controller) use the start and end flags only. You have to
know what the request was in order to interpret the response.


### Sync Detail
Requests the list of libary pattern ID's, calendar schedule ID's, and daily
 schedule parameters the controller has saved. Occurs when tapping "Enter" in
 app (e.g. after selecting a controller and setting to manual mode).

**Request**

| Byte  | Field          | Example | Notes                                   |
|-------|----------------|---------|-----------------------------------------|
| 1     | Start Flag     | 0x5a    |                                         |
| 2     | Request Type   | 0x02    | Request Saved Pattern and schedule ID's |
| 3 - 4 | Command Length | 0x00 00 | This command has no payload             |
| 5     | End Flag       | 0xa5    |                                         |

**Response**

The length of the response depends on how many patterns and calendar schedules
are saved. The minimum length (if there are no patterns and no schedules) is 18
bytes. The maximum length would have 30 patterns and 30 schedules, bringing the
message to 78 bytes.

There is a fixed size of 2 daily schedules and the last part of the message
contains the parameters for these.

| Byte            | Field                             | Example        | Notes                                                           |
|-----------------|-----------------------------------|----------------|-----------------------------------------------------------------|
| 1               | Start Flag                        | 0x5a           |                                                                 |
| 2               | Num Patterns                      | 0x16           | Number of patterns in library (p)                               |
| 3 - (2+p)       | Library ID's                      | 0x01 02 03 ... | The ID of each custom pattern saved in library, one byte per ID |
| (3+p)           | Num schedules                     | 0x16           | Number of schedules (s)                                         |
| (4+p) - (3+p+s) | Schedule ID's                     | 0x01 02 ...    | The ID of each schedule saved on the system, one byte per ID    |
| 4+p+s           | Daily 1 [State](#state)           | 0x01           | Enable/Disable                                                  |
| 5+p+s           | Daily 1 Pattern ID                | 0x0b           | The pattern to display                                          |
| 6+p+s           | Daily 1 [Repetition](#repetition) | 0x01           | What days should the pattern repeat                             |
| 7+p+s           | Daily 1 Start Hour                | 0x12           | The hour to start (activate) the schedule (24-hour format)      |
| 8+p+s           | Daily 1 Start Minute              | 0x1e           | The minute to start (activate) the schedule                     |
| 9+p+s           | Daily 1 Off Hour                  | 0x17           | The hour to stop (deactivate) the schedule (24-hour format)     |
| 10+p+s          | Daily 1 Off Minute                | 0x00           | The minute to stop (deactivate) the schedule                    |
| 11+p+s          | Daily 2 [State](#state)           | 0x01           | Enable/Disable                                                  |
| 12+p+s          | Daily 2 Pattern ID                | 0x0b           | The pattern to display                                          |
| 13+p+s          | Daily 2 [Repetition](#repetition) | 0x01           | What days should the pattern repeat                             |
| 14+p+s          | Daily 2 Start Hour                | 0x12           | The hour to start (activate) the schedule (24-hour format)      |
| 15+p+s          | Daily 2 Start Minute              | 0x1e           | The minute to start (activate) the schedule                     |
| 16+p+s          | Daily 2 Off Hour                  | 0x17           | The hour to stop (deactivate) the schedule (24-hour format)     |
| 17+p+s          | Daily 2 Off Minute                | 0x00           | The minute to stop (deactivate) the schedule                    |
| 18+p+s          | End Flag                          | 0xa5           |                                                                 |


### Check Pattern
Sets the lights to display a saved pattern.

**Request**

| Byte  | Field              | Example | Notes                             |
|-------|--------------------|---------|-----------------------------------|
| 1     | Start Flag         | 0x5a    |                                   |
| 2     | Request Type       | 0x03    | Load Saved Library Pattern        |
| 3 - 4 | Command Length     | 0x00 01 | 1 byte                            |
| 5     | Library Pattern ID | 0x05    | The library pattern ID to set     |
| 6     | End Flag           | 0xa5    |                                   |

**Response**

none


### Delete pattern

**Request**

| Byte  | Field              | Example | Notes                             |
|-------|--------------------|---------|-----------------------------------|
| 1     | Start Flag         | 0x5a    |                                   |
| 2     | Request Type       | 0x04    | Delete Pattern.                   |
| 3 - 4 | Command Length     | 0x00 01 | 1 byte                            |
| 5     | Library Pattern ID | 0x0b    | The library pattern ID to delete. |
| 6     | End Flag           | 0xa5    |                                   |

**Response**

none


### Update Pattern
Saves the custom pattern as an existing pattern in the libary. Sent when the
"Cover" button is used in the app (instead of the "Save as..." button).

**Request**

| Byte    | Field                                         | Example                 | Notes                                                |
|---------|-----------------------------------------------|-------------------------|------------------------------------------------------|
| 1       | Start Flag                                    | 0x5a                    |                                                      |
| 2       | Request Type                                  | 0x05                    | Update existing pattern                              |
| 3 - 4   | Command Length                                | 0x00 3a                 | 58 bytes                                             |
| 5       | Library Pattern ID                            | 0x0e                    | The ID of the pattern being updated/overwritten      |
| 6 - 30  | [Library Pattern Name](#library-pattern-name) | see link                | Each byte is an ASCII character, 25 characters total |
| 31      | [Category](#category)                         | 0x02                    | What category the pattern belongs to                 |
| 32      | [Effect Mode](#effect-mode)                   | 0x00                    | The animation effect                                 |
| 33      | Speed                                         | 0x7f                    | How fast the effect changes (0 - 255)                |
| 34      | Brightness                                    | 0xff                    | How bright the lights are (0 - 255)                  |
| 35 - 41 | [Dot (pixel) Count](#dot-pixel-count)         | 0x01 00 00 00 00 00 00  | How many lights of each of the seven colors          |
| 42 - 62 | [Dot (pixel) Color](#dot-pixel-color)         | 0xdd 64 14 00 00 00 ... | The RGB color of each of the seven colors            |
| 63      | End Flag                                      | 0xa5                    |                                                      |

**Response**

none


### Create Pattern
Saves the custom pattern as a new pattern in the library. Sent when the "Save
as..." button is used in the app (instead of the "Cover..." button).

**Request**

| Byte    | Field                                         | Example                 | Notes                                                |
|---------|-----------------------------------------------|-------------------------|------------------------------------------------------|
| 1       | Start Flag                                    | 0x5a                    |                                                      |
| 2       | Request Type                                  | 0x06                    | Create (save) pattern                                |
| 3 - 4   | Command Length                                | 0x00 3a                 | 58 bytes                                             |
| 5       | Library Pattern ID                            | 0x0e                    | It seems the app chooses the lowest available ID     |
| 6 - 30  | [Library Pattern Name](#library-pattern-name) | see link                | Each byte is an ASCII character, 25 characters total |
| 31      | [Category](#category)                         | 0x02                    | What category the pattern belongs to                 |
| 32      | [Effect Mode](#effect-mode)                   | 0x00                    | The animation effect                                 |
| 33      | Speed                                         | 0x7f                    | How fast the effect changes (0 - 255)                |
| 34      | Brightness                                    | 0xff                    | How bright the lights are (0 - 255)                  |
| 35 - 41 | [Dot (pixel) Count](#dot-pixel-count)         | 0x01 00 00 00 00 00 00  | How many lights of each of the seven colors          |
| 42 - 62 | [Dot (pixel) Color](#dot-pixel-color)         | 0xdd 64 14 00 00 00 ... | The RGB color of each of the seven colors            |
| 63      | End Flag                                      | 0xa5                    |                                                      |

**Response**

none


### Create Schedule

**Request**

| Byte  | Field          | Example | Notes                                                  |
|-------|----------------|---------|--------------------------------------------------------|
| 1     | Start Flag     | 0x5a    |                                                        |
| 2     | Request Type   | 0x07    | Create/save a new schedule                             |
| 3 - 4 | Command Length | 0x00 0a | 10 bytes                                               |
| 5     | Schedule ID    | 0x01    | It seems the app chooses the lowest available ID       |
| 6     | Pattern ID     | 0x08    | Pattern ID to display                                  |
| 7     | Start Month    | 0x03    | Month when schedule starts (activates)                 |
| 8     | Start Day      | 0x02    | Day of month when schedule starts (activates)          |
| 9     | Off Month      | 0x04    | Month when schedule ends (deactivates)                 |
| 10    | Off Day        | 0x09    | Day of month when schedule ends (deactivates)          |
| 11    | Start Hour     | 0x03    | Hour when schedule starts (activates) - 24 hour format |
| 12    | Start Minute   | 0x02    | Minute of hour when schedule starts (activates)        |
| 13    | Off Hour       | 0x04    | Hour when schedule ends (deactivates) - 24 hour format |
| 14    | Off Minute     | 0x09    | Minute of hour when schedule ends (deactivates)        |
| 15    | End Flag       | 0xa5    |                                                        |

**Response**

none


### Delete Schedule

**Request**

| Byte  | Field          | Example | Notes                            |
|-------|----------------|---------|----------------------------------|
| 1     | Start Flag     | 0x5a    |                                  |
| 2     | Request Type   | 0x08    | Delete Schedule                  |
| 3 - 4 | Command Length | 0x00 01 | 1 byte                           |
| 5     | Schedule ID    | 0x0b    | The ID of the schedule to delete |
| 6     | End Flag       | 0xa5    |                                  |

**Response**

none


### Update Daily Schedule

**Request**

| Byte  | Field                     | Example | Notes                                                       |
|-------|---------------------------|---------|-------------------------------------------------------------|
| 1     | Start Flag                | 0x5a    |                                                             |
| 2     | Request Type              | 0x09    | Update Daily Schedule                                       |
| 3 - 4 | Command Length            | 0x00 08 | 8 bytes                                                     |
| 5     | Schedule ID               | 0x01    | The daily schedule ID (1 or 2)                              |
| 6     | [State](#state)           | 0x01    | Enable/Disable                                              |
| 7     | Pattern ID                | 0x0b    | The pattern to display                                      |
| 8     | [Repetition](#repetition) | 0x01    | What days should the pattern repeat                         |
| 9     | Start Hour                | 0x12    | The hour to start (activate) the schedule (24-hour format)  |
| 10    | Start Minute              | 0x1e    | The minute to start (activate) the schedule                 |
| 11    | Off Hour                  | 0x17    | The hour to stop (deactivate) the schedule (24-hour format) |
| 12    | Off Minute                | 0x00    | The minute to stop (deactivate) the schedule                |
| 13    | End Flag                  | 0xa5    |                                                             |

**Response**

none


### Check Preset Mode
Display one of 180 preset patterns (the ones available from the colorwheel on
the first page in the app).

**Request**

| Byte  | Field             | Example | Notes                                                                    |
|-------|-------------------|---------|--------------------------------------------------------------------------|
| 1     | Start Flag        | 0x5a    |                                                                          |
| 2     | Request Type      | 0x0a    | Check preset mode, set to one of 180 preset patterns                     |
| 3 - 4 | Command Length    | 0x00 03 | 3 bytes                                                                  |
| 5     | Preset Pattern ID | 0x01    | The preset pattern ID corresponds to the number shown in the color wheel |
| 6     | Speed             | 0x7f    | How fast the effect changes (0 - 255)                                    |
| 7     | Brightness        | 0xff    | How bright the lights are (0 - 255)                                      |
| 36    | End Flag          | 0xa5    |                                                                          |

**Response**

none


### Check Device (Discover/Connect)

When the app is first opened, it sends this request to discover controllers on
the network. It also sends this request when a controller is selected from the
list of discovered controllers (only sent to the one specific controller in this
case).

To determine what addresses to send to, it takes the first three octets of the
gateway address (I think) (e.g. 192.168.0.1 is a default for many home
routers). Using that as the base, 1 - 254 is appended as the last octet
(skipping the device's own IP address) and this command is sent to each of the
resulting addresses. This is done with several threads to speed up discovery.
Any valid responses get added to the list of controllers that is displayed in
the app.

It also sends this command to 192.168.4.1, which is the address of the
controller when it is in AP (Access Point) mode.

Two common culprits for the app not finding a controller on the network are:
1. Timeouts - the app has a one-second timeout for responses to this command.
2. Subnet size - if your network has a subnet larger than 255.255.255.0, then
many of the IP addresses on your subnet will not even be attempted.

The command payload contains 3 verification bytes that the controller uses in a
formula and must return the result in the response. It also contains the
date/time that the controller uses to sync with the current time.

**Request**

| Byte  | Field                       | Example    | Notes                                |
|-------|-----------------------------|------------|--------------------------------------|
| 1     | Start Flag                  | 0x5a       |                                      |
| 2     | Request Type                | 0x0c       | Check Device (Connect) Command       |
| 3 - 4 | Command Length              | 0x00 0a    | 10 bytes                             |
| 5 - 7 | Verification Bytes          | 0xeb 2b 76 | 3 random bytes used for verification |
| 8     | Year                        | 0x15       | The 2-digit year                     |
| 9     | Month                       | 0x0c       | The 2-digit month                    |
| 10    | Day                         | 0x1b       | The 2-digit day of the month         |
| 11    | [Day of Week](#day-of-week) | 0x03       | The day of the week                  |
| 12    | Hour                        | 0x15       | The 2-digit hour (24-hour format)    |
| 13    | Minute                      | 0x35       | The 2-digit minute                   |
| 14    | Second                      | 0x04       | The 2-digit second                   |
| 15    | End Flag                    | 0xa5       |                                      |

The verification bytes are guaranteed not to be 0x5a or 0xa5 (the start and end
flags). The datetime given in this command is Wed October 27, 2021 08:53:04 PM

**Response**

| Byte          | Field                  | Example   | Notes                                                     |
|---------------|------------------------|-----------|-----------------------------------------------------------|
| 1             | Start Flag             | 0x5a      |                                                           |
| 2             | Verification           | 0xc9      | Calculated from the verification bytes in the request     |
| 3             | [Mode](#mode)          | 0x00      | Timer/Manual mode                                         |
| 4             | Controller Name Length | 0x09      | The number of bytes used for the controller name, max: 15 |
| 5 - (n-7)     | Controller Name        | See below | Each byte is an ASCII character                           |
| (n-6)         | [IC](#ic)              | 0x02      | The type of IC (Integrated Circuit) used in the lights    |
| (n-5)         | [RGB](#rgb)            | 0x00      | The RGB order                                             |
| (n-4) - (n-3) | Pixel Count            | 0x02 58   | The number of pixels (lights) on the string               |
| (n-2)         | Unknown                | 0x03      | ? (Perhaps firmware version? May be fixed value)          |
| (n-1)         | Unknown                | 0x00      | ? (ignored by app)                                        |
| n             | End Flag               | 0xa5      |                                                           |

The Verification byte is calculated by taking the three random verification
bytes from the check device request (connect command) and performing the
following operation: `((byte3 << 5) | ((byte1 >> 3) & 0x1f & byte2)) & 0xff`

Controller Name Example: 0x54 72 69 6d 6c 69 67 68 74 = "Trimlight"


### Set Mode
Used to put the controller in Timer mode or Manual mode.

**Request**

| Byte  | Field          | Example | Notes            |
|-------|----------------|---------|------------------|
| 1     | Start Flag     | 0x5a    |                  |
| 2     | Request Type   | 0x0d    | Set Mode Command |
| 3 - 4 | Command Length | 0x00 01 | 1 byte           |
| 5     | [Mode](#mode)  | 0x01    | The mode to set  |
| 6     | End Flag       | 0xa5    |                  |

**Response**

none


### Set Device Name

**Request**

| Byte      | Field          | Example | Notes                            |
|-----------|----------------|---------|----------------------------------|
| 1         | Start Flag     | 0x5a    |                                  |
| 2         | Request Type   | 0x0e    | Set Device Name Command          |
| 3 - 4     | Command Length | 0x00 02 | n bytes (name length)            |
| 5 - (n-1) | Name           | 0x54 4c | The new controlller name (ASCII) |
| n         | End Flag       | 0xa5    |                                  |

**Response**

none


### Set RGB Sequence

**Request**

| Byte  | Field                   | Example | Notes                    |
|-------|-------------------------|---------|--------------------------|
| 1     | Start Flag              | 0x5a    |                          |
| 2     | Request Type            | 0x10    | Set RGB Sequence Command |
| 3 - 4 | Command Length          | 0x00 01 | 1 byte                   |
| 5     | [RGB Order](#rgb-order) | 0x01    |                          |
| n     | End Flag                | 0xa5    |                          |

**Response**

none


### Set IC Model

**Request**

| Byte  | Field                 | Example | Notes                    |
|-------|-----------------------|---------|--------------------------|
| 1     | Start Flag            | 0x5a    |                          |
| 2     | Request Type          | 0x11    | Set RGB Sequence Command |
| 3 - 4 | Command Length        | 0x00 01 | 1 byte                   |
| 5     | [IC Model](#ic-model) | 0x01    |                          |
| 6     | End Flag              | 0xa5    |                          |

**Response**

none


### Set Dot (Pixel) Count
Sets the number of pixels (LED lights) on the string.

**Request**

| Byte  | Field                 | Example | Notes                                  |
|-------|-----------------------|---------|----------------------------------------|
| 1     | Start Flag            | 0x5a    |                                        |
| 2     | Request Type          | 0x12    | Set RGB Sequence Command               |
| 3 - 4 | Command Length        | 0x00 01 | 2 bytes                                |
| 5 - 6 | Pixel Count           | 0x01 0a | The number of LED lights on the string |
| 7     | End Flag              | 0xa5    |                                        |

**Response**

none


### Check Custom Pattern
Preview custom pattern (used to preview changes while in the app). Custom
patterns are those on the pattern creation page that aren't saved yet.

**Request**

| Byte    | Field                                 | Example                 | Notes                                       |
|---------|---------------------------------------|-------------------------|---------------------------------------------|
| 1       | Start Flag                            | 0x5a                    |                                             |
| 2       | Request Type                          | 0x13                    | Check (Preview) custom pattern.             |
| 3 - 4   | Command Length                        | 0x00 1f                 | 31 bytes                                    |
| 5       | [Effect Mode](#effect-mode)           | 0x00                    | Effect mode                                 |
| 6       | Speed                                 | 0x7f                    | How fast the effect changes (0 - 255)       |
| 7       | Brightness                            | 0xff                    | How bright the lights are (0 - 255)         |
| 8 - 14  | [Dot (pixel) Count](#dot-pixel-count) | 0x01 00 00 00 00 00 00  | How many lights of each of the seven colors |
| 15 - 35 | [Dot (pixel) Color](#dot-pixel-color) | 0xdd 64 14 00 00 00 ... | The RGB color of each of the seven colors   |
| 36      | End Flag                              | 0xa5                    |                                             |

**Response**

none


### Set Solid Color
Sets all pixels (dots) to a single solid color. This is used when setting a
custom color - all the lights show the color so the user can see.

The app shows custom colors in specific positions. This is stored only in the
app - the controller has no need for this information. So, only the RGB values
are sent to the controller.

**Request**

| Byte  | Field          | Example    | Notes            |
|-------|----------------|------------|------------------|
| 1     | Start Flag     | 0x5a       |                  |
| 2     | Request Type   | 0x14       | Save Cusom Color |
| 3 - 4 | Command Length | 0x00 03    | 3 bytes          |
| 5 - 7 | RGB Color      | 0xa7 0a af | (167, 10, 175)   |
| 8     | End Flag       | 0xa5       |                  |

**Response**

none


### Set Auto Mode
I could not get the controller to emit this event. It is likely related to
the Auto network mode when pairing a new device.

**Request**

Unknown

**Response**

Unknown


### Sync Pattern Detail
Requests details for a pattern. Automatically sent for each pattern ID received
in response to the Sync Detail command.

**Request**

| Byte  | Field          | Example | Notes                                    |
|-------|----------------|---------|------------------------------------------|
| 1     | Start Flag     | 0x5a    |                                          |
| 2     | Request Type   | 0x16    | Request details for the given pattern ID |
| 3 - 4 | Command Length | 0x00 01 | 1 byte                                   |
| 5     | Pattern ID     | 0x01    |                                          |
| 6     | End Flag       | 0xa5    |                                          |


**Response (success)**

| Byte    | Field                                         | Example                   | Notes                                                |
|---------|-----------------------------------------------|---------------------------|------------------------------------------------------|
| 1       | Start Flag                                    | 0x5a                      |                                                      |
| 2       | Library Pattern ID                            | 0x01                      |                                                      |
| 3 - 27  | [Library Pattern Name](#library-pattern-name) | See link                  | Each byte is an ASCII character, 25 characters total |
| 31      | [Category](#category)                         | 0x02                      | What category the pattern belongs to                 |
| 32      | [Effect Mode](#effect-mode)                   | 0x00                      | The animation effect                                 |
| 30      | Speed                                         | 0x7f                      | How fast the effect changes (0 - 255)                |
| 31      | Brightness                                    | 0xff                      | How bright the lights are (0 - 255)                  |
| 32 - 38 | [Dot (pixel) Count](#dot-pixel-count)         | 0x01 00 00 00 00 00 00    | How many lights of each of the seven colors          |
| 39 - 59 | [Dot (pixel) Color](#dot-pixel-color)         | 0xdd 64 14 00 00 00 <...> | The RGB color of each of the seven colors            |
| 60      | End Flag                                      | 0xa5                      |                                                      |

Patterns saved from the preset (colorwheel) page have category 1 (Preset) and do
not show up in the drop down list on the pattern customization page. Patterns
saved from the pattern customization page have category 2 (Custom).

**Response (error)**

If the library pattern ID is not valid, 58 `ff` bytes are returned (with the
start and end flags bringing the total TCP payload to 60 bytes).


### Sync Schedule Detail

**Request**

| Byte  | Field          | Example | Notes                                     |
|-------|----------------|---------|-------------------------------------------|
| 1     | Start Flag     | 0x5a    |                                           |
| 2     | Request Type   | 0x17    | Request details for the given schedule ID |
| 3 - 4 | Command Length | 0x00 01 | 1 byte                                    |
| 5     | Schedule ID    | 0x01    |                                           |
| 6     | End Flag       | 0xa5    |                                           |

**Response (success)**

| Byte  | Field          | Example | Notes                                                  |
|-------|----------------|---------|--------------------------------------------------------|
| 1     | Start Flag     | 0x5a    |                                                        |
| 2     | Schedule ID    | 0x01    | ID slot assigned to this schedule                      |
| 3     | Pattern ID     | 0x08    | Pattern ID to display                                  |
| 4     | Start Month    | 0x03    | Month when schedule starts (activates)                 |
| 5     | Start Day      | 0x02    | Day of month when schedule starts (activates)          |
| 6     | Off Month      | 0x04    | Month when schedule ends (deactivates)                 |
| 7     | Off Day        | 0x09    | Day of month when schedule ends (deactivates)          |
| 8     | Start Hour     | 0x03    | Hour when schedule starts (activates) - 24 hour format |
| 9     | Start Minute   | 0x02    | Minute of hour when schedule starts (activates)        |
| 10    | Off Hour       | 0x04    | Hour when schedule ends (deactivates) - 24 hour format |
| 11    | Off Minute     | 0x09    | Minute of hour when schedule ends (deactivates)        |
| 12    | End Flag       | 0xa5    |                                                        |

**Response (error)**

If the schedule pattern ID is not valid, 58 `ff` bytes are returned (with the
start and end flags bringing the total TCP payload to 60 bytes).


### Update Schedule

**Request**

| Byte  | Field          | Example | Notes                                                  |
|-------|----------------|---------|--------------------------------------------------------|
| 1     | Start Flag     | 0x5a    |                                                        |
| 2     | Request Type   | 0x18    | Update and existing schedule                           |
| 3 - 4 | Command Length | 0x00 0a | 10 bytes                                               |
| 5     | Schedule ID    | 0x01    | ID of schedule to update                               |
| 6     | Pattern ID     | 0x08    | Pattern ID to display                                  |
| 7     | Start Month    | 0x03    | Month when schedule starts (activates)                 |
| 8     | Start Day      | 0x02    | Day of month when schedule starts (activates)          |
| 9     | Off Month      | 0x04    | Month when schedule ends (deactivates)                 |
| 10    | Off Day        | 0x09    | Day of month when schedule ends (deactivates)          |
| 11    | Start Hour     | 0x03    | Hour when schedule starts (activates) - 24 hour format |
| 12    | Start Minute   | 0x02    | Minute of hour when schedule starts (activates)        |
| 13    | Off Hour       | 0x04    | Hour when schedule ends (deactivates) - 24 hour format |
| 14    | Off Minute     | 0x09    | Minute of hour when schedule ends (deactivates)        |
| 15    | End Flag       | 0xa5    |                                                        |

**Response**

none


### AP Network Config
Set network config while controller is in AP (Access Point) mode. The payload is
undeciphered as of yet, but it is assumed to contain SSID and password of the
wifi network to connect to. If so, these are encrypted (thankfully). The
controller must be in AP mode, emitting its own WiFi hotspot. The controller's
IP address in this mode is always 192.168.4.1 and the app's device must be
connected to this network (SSID/network name is always the controller's name).

**Request**

| Byte  | Field          | Example | Notes                                    |
|-------|----------------|---------|------------------------------------------|
| 1     | Start Flag     | 0x5a    |                                          |
| 2     | Request Type   | 0x1a    | AP Network Config                        |
| 3 - 4 | Command Length | 0x00 3b | 59 bytes (varies based on network setup) |
| 5     | Payload        | ...     | Payload                                  |
| 15    | End Flag       | 0xa5    |                                          |

**Response**

none


### AP Network Config OK
This is sent after the AP Network Config command has been issued and both the
controller and the app's device have connected to the WiFi network that was
configured as part of the AP Network Config command. I'm unsure of the meaning
of the payload, but it seems to be fixed.

**Request**

| Byte  | Field          | Example    | Notes                |
|-------|----------------|------------|----------------------|
| 1     | Start Flag     | 0x5a       |                      |
| 2     | Request Type   | 0x1b       | AP Network Config OK |
| 3 - 4 | Command Length | 0x00 03    | 3 bytes              |
| 5     | Payload        | 0x01 02 03 | Paylod (fixed?)      |
| 15    | End Flag       | 0xa5       |                      |

**Response**

none


### Common Field Definitions

#### Library Pattern Name
If the name is less than 25 characters, remaining bytes are padded with either
all `0x00` or all `0xff`. Example: 0x77 69 72 65 73 68 61 72 6b 69 6e 67 <13
bytes of 0x00> = "wiresharking"

#### Dot (pixel) count
Each pattern has up to 7 different colors with 0 - 30 lights (pixels) in a row
for each color. This field has one byte per color to indicate the count for each
color. Example: 0x01 00 00 00 00 00 00 means the first color will have 1 light
(pixel) in a row. No other colors are set. Then the pattern repeats (so the
result is to have all lights the same color). On the other hand, for values
0x03 01 03 07 01 03 00 means the first 3 lights will be the first color, the
next 1 is the second color, the next 3 are the third color, the next 7 are
the fourth color, the next 1 is the fifth color, the next 3 are the sixth color
and the seventh color has no lights. Then the pattern repeats until the end of
your lights.

#### Dot (pixel) Color
Indicates the color for each of the 7 options. There are three bytes per color -
one byte each for red, blue, and green. Example: 0xdd 64 14 00 00 00 ... =
orange for first position, black for the second, and so on ...


### Enumerations

#### Request Type
* 1 = Sync  // I could not get the app to emit Sync (0x01). This value is
defined in the app code, but I couldn't find any references to it. It may be
obsolete now.
* 2 = [Sync Detail](#sync-detail)
* 3 = [Check Pattern](#check-pattern)
* 4 = [Delete Pattern](#delete-pattern)
* 5 = [Update Pattern](#update-pattern)
* 6 = [Create Pattern](#create-pattern)
* 7 = [Create Schedule](#create-schedule)
* 8 = [Delete Schedule](#delete-schedule)
* 9 = [Update Daily Schedule](#update-daily-schedule)
* 10 = [Check Preset Mode](#check-preset-mode)
* _11 = unused_
* 12 = [Check Device](#check-device-discoverconnect)
* 13 = [Set Mode](#set-mode)
* 14 = [Set Device Name](#set-device-name)
* _15 = unused_
* 16 = [Set RGB Sequence](#set-rgb-sequence)
* 17 = [Set IC Model](#set-ic-model)
* 18 = [Set Dot Count](#set-dot-pixel-count)
* 19 = [Check Custom Pattern](#check-custom-pattern)
* 20 = [Set Solid Color](#set-solid-color)
* 21 = [Auto Mode](#set-auto-mode)
* 22 = [Sync Pattern Detail](#sync-pattern-detail)
* 23 = [Sync Schedule Detail](#sync-schedule-detail)
* 24 = [Update Schedule](#update-schedule)
* _25 = unused_
* 26 = [AP Network Config](#ap-network-config)
* 27 = [AP Network Config OK](#ap-network-config-ok)

#### Mode
* 0 = Timer
* 1 = Manual

#### IC Model
* 0 = SM16703
* 1 = TM1804
* 2 = UCS1903
* 3 = WS2811
* 4 = WS2801
* 5 = SK6812
* 6 = LPD6803
* 7 = LPD8806
* 8 = APA102
* 9 = APA105
* 10 = DMX512
* 11 = TM1914
* 12 = TM1913
* 13 = P9813
* 14 = INK1003
* 15 = P943S
* 16 = P9411
* 17 = P9413
* 18 = TX1812
* 19 = TX1813
* 20 = GS8206
* 21 = GS8208
* 22 = SK9822
* 23 = TM1814
* 24 = SK6812_RGBW
* 25 = P9414
* 26 = P9412

#### RGB Order
* 0 = RGB (Red Green Blue)
* 1 = RBG (Red Blue Green)
* 2 = GRB (Green Red Blue)
* 3 = GBR (Green Blue Red)
* 4 = BRG (Blue Red Green)
* 5 = BGR (Blue Green Red)

#### Day Of Week
* 1 = Monday
* 2 = Tuesday
* 3 = Wednesday
* 4 = Thursday
* 5 = Friday
* 6 = Saturday
* 7 = Sunday

#### Effect Mode
* 0 = Static
* 1 = Chase Forward
* 2 = Chase Backward
* 3 = Chase Middle to Out
* 4 = Chase Out to Middle
* 5 = Strobe
* 6 = Fade
* 7 = Comet Forward
* 8 = Come Backward
* 9 = Wave Forward
* 10 = Wave Backward
* 11 = Solid Fade

#### State
* 0 = Off
* 1 = On

#### Repetition
* 0 = Today Only
* 1 = Everyday
* 2 = Week Days
* 3 = Weekend

#### Category
* 1 = Preset
* 2 = Custom
