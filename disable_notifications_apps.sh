#!/bin/zsh
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
notification_plist="/Users/$loggedInUser/Library/Preferences/com.apple.ncprefs.plist"
disableNotificationLockFlag="41955342" # 41955342 is the flag number to disable notification on lock screen

#Count the number of bundles in the plist file
bundleCount=$(/usr/libexec/PlistBuddy -c "Print :apps" "${notification_plist}" | grep -c "bundle-id")

index=1
while [ $index -lt "${bundleCount}" ]; do
    bundle_id=$(/usr/libexec/PlistBuddy -c "Print apps:${index}:bundle-id" "${notification_plist}");
            if [ "${bundle_id}" = "com.tinyspeck.slackmacgap" ] || [ "${bundle_id}" = "com.google.Chrome" ]; then
                    flags_value=$(/usr/libexec/PlistBuddy -c "Print apps:${index}:flags" "${notification_plist}");
                    echo "bundleid: $bundle_id; index number: $index; current flag number: $flags_value"
                    if [ $flags_value != $disableNotificationLockFlag ]; then
                        echo "updating flag number to disable notification on lock screen"
                        /usr/libexec/PlistBuddy -c "Set :apps:${index}:flags $disableNotificationLockFlag" "${notification_plist}"
                    fi
            fi
    index=$((index + 1))
done

# Restart notification center to make changes take effect.
killall usernoted