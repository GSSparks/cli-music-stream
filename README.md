# cli-music-stream
This script takes a list of streaming urls and allows you to play them in the background from the cli.
Included in this repo is a simple lua script that can be added to the `mpv` config directory to allow
a notification with the stream and song info.

## Usage

`./music_stream.sh play <stream>`

Other agruments are `stop`, `next`, and `prev`.

`next` and `prev` cycle through the stations.

### How to add/change available streams
There are many ways to find stream URLs. An easy way is to simply
visit the [radio-browser.info](https://www.radio-browser.info/) website.
Here you can find a community supported database of different online music streams.

As of right now, the streams are hard coded in list in the script.
To change them, edit this part of the script:
```
declare -A streams
streams["WAJI"]="https://ice64.securenetsystems.net/WAJI?playSessionID=8882F088-FBC7-F008-2C64ACB2C771047E"
streams["Wayne"]="https://prod-54-90-118-66.amperwave.net/adamsradio-wwfwfmaac-ibc1?"
streams["80s80s"]="http://streams.80s80s.de/web/mp3-192/streams.80s80s.de/"
streams["90s90s"]="http://streams.90s90s.de/grunge/mp3-192/streams.90s90s.de/"
streams["Bluegrass"]="https://ice24.securenetsystems.net/WAMU"
streams["Country"]="http://185.33.21.112/ccountry_mobile_mp3"
streams["Numetal"]="http://stream.revma.ihrhls.com/zc9483"
streams["Oldies"]="http://46.105.122.141:9676/;"
streams["Vinyl"]="https://icecast.walmradio.com:8443/classic"
```

### Example:
Let's say you find a radio stream called WALM - Old Time Radio at https://icecast.walmradio.com:8443/otr.
You will add it to the list like such:
`streams["OTR"]="https://icecast.walmradio.com:8443/otr"`.
And now you can play the stream by typing `./music_stream.sh play OTR` into the command line.

### Other ways to use this script
I'm calling this script with hotkeys.  By pressing a keycombo I can play and stop the stream
and hop to the next or previous stream in the list. Then, I added these keycombos to a cheap mini keypad,
and I use this to control my music at a push of a button.

## Requirements

[mpv](https://mpv.io/) - music player

