#!/bin/bash

# Edit these variables for your environment
DaemonName="jamf_policy_test"
CompanyName="company"
AppList=(
    "install_Google Chrome"
    "install_Slack"
    "install_Zoom"
    )
SlackWebhookURL=""

# If any previous instances of the  LaunchDaemon and script exist,
# unload the LaunchDaemon and remove the LaunchDaemon and script files

echo "checking for old daemon versions"
if [[ -f "/Library/LaunchDaemons/com.$CompanyName.$DaemonName.plist" ]]; then
   echo "unloading old daemon"
   /bin/launchctl unload "/Library/LaunchDaemons/com.$CompanyName.$DaemonName.plist"
   echo "deleting old daemon"
   /bin/rm "/Library/LaunchDaemons/com.$CompanyName.$DaemonName.plist"
fi

echo "checking for old script versions"
if [[ -f "/Library/Application Support/JAMF/bin/$DaemonName.sh" ]]; then
   echo "removing old script"
   /bin/rm "/Library/Application Support/JAMF/bin/$DaemonName.sh"
fi

# Create the LaunchDaemon by using cat input redirection
# to write the XML contained below to a new file.
#
# The LaunchDaemon will run at load and at an interval specified in the parameters

echo "creating plist"
/bin/cat > "/tmp/com.$CompanyName.$DaemonName.plist" << LOG_LAUNCHDAEMON
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.$CompanyName.$DaemonName</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>/Library/Application Support/JAMF/bin/$DaemonName.sh</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
  <key>StartCalendarInterval</key>
  <dict>
  <key>Hour</key>
  <integer>2</integer>
  <key>Minute</key>
  <integer>0</integer>
  </dict>
</dict>
</plist>
LOG_LAUNCHDAEMON

# Create the $DaemonName script by using cat input redirection
# to write the shell script contained below to a new file.
#
# The script will write the repos to a log file
echo "creating script"
/bin/cat > "/tmp/$DaemonName.sh" << LOG_SCRIPT
#!/bin/bash


# Kill any Jamf processes
runningProc=\$(ps axc | grep -i "jamf" | awk '{print \$1}')
if [[ \$runningProc ]]; then
    echo "Found running process jamf with PID: \${runningProc}. Killing it..."
    kill \$runningProc
else
    echo "\$proc not found running..."
fi

apps=@AppList

# Running the policy
for i in "\${apps[@]}"
do
    echo "Calling the jamf policy for \$i"

    caffeinate -disu bash -c "/usr/local/bin/jamf policy -event '\$i'"
    returnCode=\$?

    if [[ "\${returnCode}" == "0" ]]; then
        echo "Policy call successful"
        curl -X POST -H 'Content-type: application/json' --data '{"text":"'"\$i"' installation policy verified! :white_check_mark:"}' "$SlackWebhookURL"
    else
        echo "FAILED policy call"
        curl -X POST -H 'Content-type: application/json' --data '{"text":"'"\$i"' installation policy failed! :x:"}' "$SlackWebhookURL"

    fi
done

LOG_SCRIPT

# After creation, fix permissions (owned by root:wheel and not executable)
# and move into /Library/LaunchDaemons.

echo "fixing plist permissions and ownership"
/usr/sbin/chown root:wheel "/tmp/com.$CompanyName.$DaemonName.plist"
/bin/chmod 755 "/tmp/com.$CompanyName.$DaemonName.plist"
/bin/chmod a-x "/tmp/com.$CompanyName.$DaemonName.plist"
/bin/mv "/tmp/com.$CompanyName.$DaemonName.plist" "/Library/LaunchDaemons/com.$CompanyName.$DaemonName.plist"

# After creation, fix permissions (owned by root:wheel and executable)
# and move into /Library/LaunchDaemons.

echo "fixing script permissions and ownership"
/usr/sbin/chown root:wheel "/tmp/$DaemonName.sh"
/bin/chmod 755 "/tmp/$DaemonName.sh"
/bin/chmod a+x "/tmp/$DaemonName.sh"
/bin/mv "/tmp/$DaemonName.sh" "/Library/Application Support/JAMF/bin/$DaemonName.sh"

# After the LaunchDaemon and script are in place with proper permissions,
# load the LaunchDaemon to begin the script's execution.

echo "loading daemon"
if [[ -f "/Library/LaunchDaemons/com.$CompanyName.$DaemonName.plist" ]]; then
   /bin/launchctl load -w "/Library/LaunchDaemons/com.$CompanyName.$DaemonName.plist"
fi

exit 0
