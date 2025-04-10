#!/bin/bash

# Custom Variables
# Set process to "daemon" or "agent"
process="daemon"
projectName="jamf_policy_test"
companyName="company"
AppList=(
    "install_Google Chrome"
    "install_Slack"
    "install_Zoom"
    )
SlackWebhookURL=""

# Other Variables
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
loggedInUID=$(id -u "$loggedInUser")
logFolder="/Users/${loggedInUser}/Library/Logs/${companyName}"
scriptPath="/Library/Scripts/${companyName}"
[[ ! -d "$scriptPath" ]] && mkdir -p "$scriptPath"
[[ ! -d "$logFolder" ]] && mkdir -p "$logFolder"

processName="com.$companyName.$projectName"
processFullPath="$processPath/$processName.plist"
scriptPath="/Library/Scripts/${companyName}"
mkdir -p "$scriptPath"

# If any previous instances of the  LaunchDaemon and script exist,
# unload the LaunchDaemon and remove the LaunchDaemon and script files
echo "checking for old $process versions"
if [[ -f "$processFullPath" ]]; then
  if [[ $process == "daemon" ]]; then
  echo "Unloading $process"
  /bin/launchctl bootout system "$processFullPath"
  elif [[ $process == "agent" ]]; then
  echo "Unloading $process"
  /bin/launchctl bootout gui/$loggedInUID "$processFullPath"
  fi
  echo "deleting old $process"
  /bin/rm "$processFullPath"
fi

echo "checking for old script versions"
if [[ -f "$scriptPath/$projectName.sh" ]]; then
   echo "removing old script"
   /bin/rm "$scriptPath/$projectName.sh"
fi

# Create the LaunchDaemon by using cat input redirection
# to write the XML contained below to a new file.
#
# The LaunchDaemon will run at load and at an interval specified in the parameters

echo "creating plist"
/bin/cat > "/tmp/com.$companyName.$projectName.plist" << LOG_LAUNCHDAEMON
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.$companyName.$projectName</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>/Library/Application Support/JAMF/bin/$projectName.sh</string>
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

# Create the $projectName script by using cat input redirection
# to write the shell script contained below to a new file.
#
# The script will write the repos to a log file
echo "creating script"
/bin/cat > "/tmp/$projectName.sh" << LOG_SCRIPT
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
# and move into $AgentPath.

echo "fixing plist permissions and ownership"
/usr/sbin/chown root:wheel "/tmp/$processName.plist"
/bin/chmod 755 "/tmp/$processName.plist"
/bin/chmod a-x "/tmp/$processName.plist"
/bin/mv "/tmp/$processName.plist" "$processFullPath"

# After creation, fix permissions (owned by root:wheel and executable)
# and move into $AgentPath.

echo "fixing script permissions and ownership"
/usr/sbin/chown root:wheel "/tmp/$projectName.sh"
/bin/chmod 755 "/tmp/$projectName.sh"
/bin/chmod a+x "/tmp/$projectName.sh"
/bin/mv "/tmp/$projectName.sh" "$scriptPath/$projectName.sh"

# After the LaunchAgent and script are in place with proper permissions,
# load the LaunchAgent to begin the script's execution.

echo "loading $process"
if [[ -f "$processFullPath" ]]; then
  if [[ $process == "daemon" ]]; then
  /bin/launchctl bootstrap system "$processFullPath"
  elif [[ $process == "agent" ]]; then
  /bin/launchctl bootstrap gui/$loggedInUID "$processFullPath"
  fi
else
echo "$process not found"
fi

exit 0
