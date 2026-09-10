tell application "System Events" to tell process "NotificationCenter"
  repeat 12 times
    set a to missing value
    try
      set els to entire contents of window "Notification Center"
      repeat with g in els
        try
          if (subrole of g as text) is "AXNotificationCenterAlert" then
            set a to contents of g
            exit repeat
          end if
        end try
      end repeat
    end try
    if a is missing value then exit repeat
    set done to false
    try
      repeat with ac in (actions of a)
        set d to description of ac as text
        if d contains "Close" or d contains "Clear" then
          perform ac
          set done to true
          exit repeat
        end if
      end repeat
    end try
    if not done then exit repeat
    delay 0.7
  end repeat
end tell
