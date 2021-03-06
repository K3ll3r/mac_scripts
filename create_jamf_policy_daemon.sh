#!/bin/bash

# If any previous instances of the  LaunchDaemon and script exist,
# unload the LaunchDaemon and remove the LaunchDaemon and script files

DaemonName=$4
PolicyTrigger=$5
StartIntervalDay1=$6
StartIntervalDay2=$7

# Uncomment for testing
# DaemonName="com.company.update"
# PolicyTrigger="install_mac_updates"
# StartIntervalDay1="1"
# StartIntervalDay2="15"

echo "checking for old daemon versions"
if [[ -f "/Library/LaunchDaemons/$DaemonName.plist" ]]; then
   echo "unloading old daemon"
   /bin/launchctl unload "/Library/LaunchDaemons/$DaemonName.plist"
   echo "deleting old daemon"
   /bin/rm "/Library/LaunchDaemons/$DaemonName.plist"
fi

# Create the LaunchDaemon by using cat input redirection
# to write the XML contained below to a new file.
#
# The LaunchDaemon will run at load and at an interval specified in the parameters

echo "creating plist"
/bin/cat > "/tmp/com.cruise.update.plist" << LOG_LAUNCHDAEMON
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$DaemonName</string>
	<key>ProgramArguments</key>
	<array>
			<string>/usr/local/bin/jamf</string>
			<string>policy</string>
			<string>-event</string>
			<string>$PolicyTrigger</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Day</key>
			<integer>$StartIntervalDay1</integer>
			<key>Hour</key>
			<integer>12</integer>
			<key>Minute</key>
			<integer>0</integer>
		</dict>
		<dict>
			<key>Day</key>
			<integer>$StartIntervalDay2</integer>
			<key>Hour</key>
			<integer>12</integer>
			<key>Minute</key>
			<integer>0</integer>
		</dict>
	</array>
	<key>StandardOutPath</key>
	<string>/tmp/$DaemonName.log</string>
	<key>StandardErrorPath</key>
	<string>/tmp/$DaemonName.err</string>
</dict>
</plist>
LOG_LAUNCHDAEMON


# After creation, fix permissions (owned by root:wheel and not executable)
# and move into /Library/LaunchDaemons.

echo "fixing plist permissions and ownership"
/usr/sbin/chown root:wheel "/tmp/$DaemonName.plist"
/bin/chmod 755 "/tmp/$DaemonName.plist"
/bin/chmod a-x "/tmp/$DaemonName.plist"
/bin/mv "/tmp/$DaemonName.plist" "/Library/LaunchDaemons/$DaemonName.plist"

# After the LaunchDaemon and script are in place with proper permissions,
# load the LaunchDaemon to begin the script's execution.

echo "loading daemon"
if [[ -f "/Library/LaunchDaemons/$DaemonName.plist" ]]; then
   /bin/launchctl load -w "/Library/LaunchDaemons/$DaemonName.plist"
fi

exit 0
