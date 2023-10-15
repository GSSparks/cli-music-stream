#!/bin/bash

# Check if mpv is installed
if ! command -v mpv &> /dev/null; then
  echo "Error: mpv is not installed. Please install mpv to use this script."
  exit 1
fi

# JSON file path in the user's home directory
JSON_FILE="$HOME/.config/streams.json"

# Function to check and initialize the JSON file if it doesn't exist
initialize_json_file() {
  if [ ! -f "$JSON_FILE" ]; then
    echo "JSON file does not exist. Creating one in $JSON_FILE..."
    jsonfile='{
      "streams": {
        "WAJI": "https://ice64.securenetsystems.net/WAJI",
        "Wayne": "https://prod-54-90-118-66.amperwave.net/adamsradio-wwfwfmaac-ibc1?",
        "80s80s": "http://streams.80s80s.de/web/mp3-192/streams.80s80s.de/",
        "90s90s": "http://streams.90s90s.de/grunge/mp3-192/streams.90s90s.de/",
        "Bluegrass": "https://ice24.securenetsystems.net/WAMU",
        "Country": "http://185.33.21.112/ccountry_mobile_mp3",
        "Numetal": "http://stream.revma.ihrhls.com/zc9483",
        "Oldies": "http://46.105.122.141:9676/;",
        "Vinyl": "https://icecast.walmradio.com:8443/classic"
      },
      "lastplayed": "WAJI"
    }'
    # Create a sample JSON file with an empty object {}
    echo $jsonfile > "$JSON_FILE"
  fi
}

# Call the function to initialize the JSON file
initialize_json_file

# Function to read the stream URLs from the JSON file and populate the 'streams' associative array

declare -A streams

# Use jq to extract the "streams" object from the JSON file and format it as a JSON string
streams_json=$(jq '.streams | to_entries[] | "\(.key) \(.value)"' "$JSON_FILE")

# Iterate over the key-value pairs and populate the streams array
while IFS=' ' read -r key value; do
  key=$(echo "$key" | tr -d '"')
  value=$(echo "$value" | tr -d '"')
  streams["$key"]="$value"
done <<< "$streams_json"

# Function to add a new stream
add_stream() {
  local key="$1"
  local url="$2"

  if [ -z "$key" ] || [ -z "$url" ]; then
    echo "Usage: $0 add <key> <url>"
    exit 1
  fi

  if [ -n "${streams["$key"]}" ]; then
    echo "Stream with key '$key' already exists. Use 'update' to change it."
    exit 1
  fi

  tmpJson=$(cat $JSON_FILE)
  jq --arg key "$key" --arg url "$url" '.streams[$key] = $url' <<< "$tmpJson" > /tmp/music_stream_tmp.json
  mv /tmp/music_stream_tmp.json "$JSON_FILE"
  echo "Stream added: $key -> $url"

  restart_stream
}

# Function to remove an existing stream
remove_stream() {
  local key="$1"

  if [ -z "$key" ]; then
    echo "Usage: $0 remove <key> "
    exit 1
  fi

  if [ -z "${streams["$key"]}" ]; then
    echo "Stream with key '$key' does not exist."
    exit 1
  fi

  tmpJson=$(cat $JSON_FILE)
  jq --arg key "$key" 'del(.streams[$key])' <<< "$tmpJson" > /tmp/music_stream_tmp.json
  mv /tmp/music_stream_tmp.json "$JSON_FILE"
  echo "Stream $key has been removed"

  restart_stream
}

# Function to update an existing stream
update_stream() {
  local key="$1"
  local url="$2"

  if [ -z "$key" ] || [ -z "$url" ]; then
    echo "Usage: $0 update <key> <url>"
    exit 1
  fi

  if [ -z "${streams["$key"]}" ]; then
    echo "Stream with key '$key' does not exist. Use 'add' to create it."
    exit 1
  fi

  tmpJson=$(cat $JSON_FILE)
  jq --arg key "$key" --arg url "$url" '.streams[$key] = $url' <<< "$tmpJson" > /tmp/music_stream_tmp.json
  mv /tmp/music_stream_tmp.json "$JSON_FILE"
  echo "Stream updated: $key -> $url"

  restart_stream
}

# Define variables
caller="$0"
last_selected_stream="$(jq -r '.lastplayed' $JSON_FILE)"

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

  # This section will stop any running streams in the event we're "changing" stations
  playing=$(pgrep -a "mpv" | grep "$urls" | awk '{print $3}')
  if [ -n "$playing" ]; then
    stop_stream
  fi

  local selected_stream="${streams[$1]}"
  if [ -n "$selected_stream" ]; then
    mpv "$selected_stream" > /dev/null 2>&1 &

    # This section updates the lastplayed value
    tmpJson=$(cat $JSON_FILE)
    streaming=$1
    jq '.lastplayed = $streaming' --arg streaming $streaming <<<"$tmpJson" > /tmp/music_stream_tmp.json
    mv /tmp/music_stream_tmp.json "$JSON_FILE"

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

restart_stream() {
  local caller=""
  stop_stream
  start_stream $last_selected_stream
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
  echo "CLI Music Streamer: This script plays music streams in the background"
  echo "from the command line using mpv music player."
  echo ""
  echo "Usage: $(basename $0) [play <stream>] [stop] [next] [prev]"
  echo ""
  echo "       Add a stream:    [add <stream> <url>]"
  echo "       Update a stream: [update <stream> <url>]"
  echo "       Remove a stream: [remove <stream>]"
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
elif [ "$1" == "add" ]; then
  add_stream "$2" "$3"
elif [ "$1" == "update" ]; then
  update_stream "$2" "$3"
elif [ "$1" == "remove" ]; then
  remove_stream "$2"
else
  usage
fi
