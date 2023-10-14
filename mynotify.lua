-- based on https://github.com/rohieb/mpv-notify
-- https://unix.stackexchange.com/a/455198/119298
lastcommand = nil
function string.shellescape(str)
   return "'"..string.gsub(str, "'", "'\"'\"'").."'"
end
function do_notify(a,b)
   local command = ("notify-send -a mpv -- %s %s"):format(a:shellescape(),
                                                          b:shellescape())
   if command ~= lastcommand then
      os.execute(command)
      lastcommand = command
   end
end
function notify_current_track()
   local data = mp.get_property("media-title")
   if data then
      local artist, song_title = data:match("(.-)-(.*)")
      if artist and song_title then
         do_notify(artist, song_title)
      else
         mp.osd_message("Failed to extract artist and song title")
      end
   end
end

mp.observe_property("media-title", "string", notify_current_track)
mp.register_event("file-loaded", notify_current_track)
