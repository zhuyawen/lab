# DM Lab Observations

Shapes are tensor shapes (row-major) and images' origins are top left.

## Built-in (Player only)

There several built-in observations:

Some observations depend on setting `width` (Default 320) and `height` (Default
180).

| Observation Name       | Type/Shape               | Description             |
| :--------------------- | :----------------------- | :---------------------- |
| `RGB_INTERLACED`       | Bytes (height, width, 3) | Player view interlaced. |
| `RGBD_INTERLACED`      | Bytes (height, width, 4) | Player view with depth  |
:                        :                          : interlaced.             :
| `RGB`                  | Bytes (3, height, width) | Player view planar.     |
| `RGBD`                 | Bytes (4, height, width) | Player view with depth  |
:                        :                          : planar.                 :
| FRAMES_REMAINING_AT_60 | Doubles (1)              | Frames remaining in     |
:                        :                          : episode, unless ended   :
:                        :                          : early. (Assumed frame   :
:                        :                          : rate of 60 fps.)        :

Note:

1.  Planar - Each channel is on the major rank. (Bytes are arranged RRR...
    GGG... BBB...)
2.  Interlaced - Each color is on the minor rank. (Bytes are arranged
    RGBRGB....)

Prefer RGB_INTERLACED as this is a little faster as it requires less processing.

## Custom observations (Player only)

There are also optional custom observations that can be added via
custom_observations.decorate(api).

Observation Name | Type/Shape | Description
:--------------- | :--------- | :-----------------------------------
`VEL.TRANS`      | Doubles(3) | Player relative velocity.
`VEL.ROT`        | Doubles(3) | Player relative angular velocity.
`INSTR`          | String     | Textual message from level to agent.
`TEAM.SCORE`     | Doubles(2) | Team score (your team, their team.)

## Debug observations (Player only)

Debug camera observations default to using the width and height of the screen.
To render larger output to these screens use the setting `maxAltCameraWidth` and
`maxAltCameraHeight`.

By default, only entities close to the current player are rendered. The setting
`hasAltCameras` overrides this behavior and makes sure all entities are always
visible.

1.  `altWidth` will be the max of settings `width` and `maxAltCameraWidth`
2.  `altHeight` will be the max of settings `height` and `maxAltCameraHeight`.

| Observation Name                      | Type/Shape | Description             |
| :------------------------------------ | :--------- | :---------------------- |
| `DEBUG.CAMERA.TOP_DOWN`               | Bytes (3   | topDownCamera           |
:                                       : altHeight, :                         :
:                                       : altWidth)  :                         :
| `DEBUG.CAMERA.PLAYER_VIEW`            | Bytes (3   | Player's view - no      |
:                                       : altHeight, : heads up display. (with :
:                                       : altWidth)  : reticle.)               :
| `DEBUG.CAMERA.PLAYER_VIEW_NO_RETICLE` | Bytes (3   | Player's view - no      |
:                                       : altHeight, : heads up display.       :
:                                       : altWidth)  :                         :
| `DEBUG.POS.TRANS`                     | Doubles(3) | Player's world position |
:                                       :            : in game units.          :
| `DEBUG.POS.ROT`                       | Doubles(3) | Player's world          |
:                                       :            : orientation in degrees. :
| `DEBUG.PLAYER_ID`                     | Doubles(1) | Current player's id.    |

## Debug observations (Server only)

This gets data about each players' state.

Dimensions containing 0 will be expand to the number of active players in the
map including any bots.

| Observation Name              | Type/Shape    | Description                 |
| :---------------------------- | :------------ | :-------------------------- |
| `DEBUG.PLAYERS.ARMOR`         | Doubles(0)    | Armor level.                |
| `DEBUG.PLAYERS.GADGET`        | Doubles(0)    | Current gadget held.        |
| `DEBUG.PLAYERS.GADGET_AMOUNT` | Doubles(0)    | Current amount for gadget.  |
| `DEBUG.PLAYERS.HEALTH`        | Doubles(0)    | Health of each player.      |
| `DEBUG.PLAYERS.HOLDING_FLAG`  | Doubles(0)    | Whether holding a flag.     |
| `DEBUG.PLAYERS.ID`            | Doubles(0)    | Players' Id                 |
| `DEBUG.PLAYERS.EYE.POS`       | Doubles(0, 3) | Players' eye position       |
:                               :               : Unsmoothed.                 :
| `DEBUG.PLAYERS.EYE.ROT`       | Doubles(0, 3) | Players' look direction     |
:                               :               : (degrees).                  :
| `DEBUG.PLAYERS.NAME`          | String        | New-line separated list of  |
:                               :               : player names.               :
| `DEBUG.PLAYERS.TEAM`          | Doubles(0)    | Players' team. 0=None 1=Red |
:                               :               : 2=Blue                      :

These observations are for flag data.

The observations are `{posX, posY, posZ, playerId, state}`

Where `state` maps {0 = NONE, 1 = HOME, 2 = CARRIED, 3 = DROPPED}.

Observation Name   | Type/Shape | Description
:----------------- | :--------- | :------------------------------------
`DEBUG.FLAGS.RED`  | Doubles(5) | Red flag's position, playerId, state
`DEBUG.FLAGS.BLUE` | Doubles(5) | Blue flag's position, playerId, state

These observations are for the flags' home locations.

The observations are `{posX, posY, posZ, state}`

Where `state` maps {0 = NONE, 1 = HOME, 2 = AWAY}.

Observation Name        | Type/Shape | Description
:---------------------- | :--------- | :----------------------------------
`DEBUG.FLAGS.RED_HOME`  | Doubles(4) | Red flag's home location and state
`DEBUG.FLAGS.BLUE_HOME` | Doubles(4) | Blue flag's home location and state
