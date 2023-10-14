#!/bin/bash

# Check if mpv is installed
if ! command -v mpv &> /dev/null; then
  echo "Error: mpv is not installed. Please install mpv to use this script."
  exit 1
fi

# Define a list of stream identifiers and their corresponding URLs
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

# Define variables
caller="$0"
last_selected_stream="$(cat ~/.music_stream)"

is_playing() {  # function to keep next and prev from starting a stream
  playing=$(pgrep -a "mpv" | grep "$urls" | awk '{print $3}')
  if [ ! "$playing" ]; then
    exit
  fi
}

list_streams() {
  for key in "${!streams[@]}"; do
    echo "  $key"
  done
}

# Function to start streaming in the background
start_stream() {
  local caller=""  # Set to nil to keep from reporting that we're stopping streams while changing stations

  # This section makes play toggle start and stop like a play/pause button
  playing=$(pgrep -a "mpv" | grep "$urls" | awk '{print $3}')
  if [ "${streams[$1]}" == "$playing" ]; then
    caller="$0"
    stop_stream
    exit
  fi

  # This section will stop any running streams in the event we're "chang" stations
  playing=$(pgrep -a "mpv" | grep "$urls" | awk '{print $3}')
  if [ -n "$playing" ]; then
    stop_stream
  fi

  local selected_stream="${streams[$1]}"
  if [ -n "$selected_stream" ]; then
    mpv "$selected_stream" > /dev/null 2>&1 &
    echo "$1" > ~/.music_stream
    echo "Streaming $1..."
    notify-send -a "Music Streaming" "$1"
  else
    usage
  fi
}

# Function to stop the streaming
stop_stream() {
  for urls in "${streams[@]}"; do
    proc=$(pgrep -a "mpv" | grep "$urls" | awk '{print $3}')
  done
  pkill -f "mpv $proc"
  if [ "$caller" == $0 ]; then
    echo "Music stopped."
  fi
}

# Function to get the next stream
next_stream() {
  is_playing

  current_stream="$1"
  next_stream_found=0
  for key in "${!streams[@]}"; do
    if [ "$next_stream_found" == 1 ]; then
      start_stream "$key"
      return
    fi
    if [ "$key" == "$current_stream" ]; then
      next_stream_found=1
    fi
  done
  # If there is no next stream, start the first one
  start_stream $(echo "${!streams[@]}" | awk '{print $1}')
}


# Function to get the previous stream
prev_stream() {
  is_playing

  current_stream="$1"
  prev_stream=""
  for key in "${!streams[@]}"; do
    if [ "$key" == "$current_stream" ]; then
      break
    fi
    prev_stream="$key"
  done
  # If a previous stream is found, start it
  if [ -n "$prev_stream" ]; then
    start_stream "$prev_stream"
  else
    # If no previous stream is found, start the last stream
    start_stream $(echo "${!streams[@]}" | awk '{print $NF}')
  fi
}

usage() {
  echo ""
  echo "Usage: $(basename $0) [play <stream>] [stop]"
  echo "----------------------------------------------------------"
  echo "The available streams are:"
  echo ""
  list_streams
  exit 1
}

# Check for command-line arguments
if [ "$1" == "play" ]; then
  start_stream "${2:-$last_selected_stream}"
elif [ "$1" == "stop" ]; then
  stop_stream
elif [ "$1" == "next" ]; then
  next_stream "$last_selected_stream"
elif [ "$1" == "prev" ]; then
  prev_stream "$last_selected_stream"
else
  usage
fi
