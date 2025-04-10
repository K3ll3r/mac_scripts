#!/bin/bash

# Custom Variables
# Set process to "daemon" or "agent"
process="daemon"
projectName="test_project"
companyName="company"

# Other Variables
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
loggedInUID=$(id -u "$loggedInUser")
logFolder="/Users/${loggedInUser}/Library/Logs/${companyName}"
scriptPath="/Library/Scripts/${companyName}"
[[ ! -d "$scriptPath" ]] && mkdir -p "$scriptPath"
[[ ! -d "$logFolder" ]] && mkdir -p "$logFolder"

if [[ "$process" == "daemon" ]]; then
processPath="/Library/LaunchDaemons"
elif [[ "$process" == "agent" ]]; then
processPath="/Users/$loggedInUser/Library/LaunchAgents"
else
echo "process type malformed. Please fix."
exit 1
fi

processName="com.$companyName.$projectName"
processFullPath="$processPath/$processName.plist"
scriptPath="/Library/Scripts/${companyName}"
mkdir -p "$scriptPath"

# If any previous instances of the  LaunchAgent and script exist,
# unload the LaunchAgent and remove the LaunchAgent and script files

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

# Create the LaunchAgent/Daemon by using cat input redirection
# to write the XML contained below to a new file.
#
# The LaunchAgent/Daemon will run at load and at an interval specified in the parameters

echo "creating plist"
/bin/cat > "/tmp/$processName.plist" << LOG_PROCESS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$processName</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>$scriptPath/$projectName.sh</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
  <key>StartCalendarInterval</key>
  <dict>
  <key>Hour</key>
  <integer>2</integer>
  <key>Minute</key>
  <integer>0</integer>
  <key>Weekday</key>
  <integer>4</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>/tmp/$projectName.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/$projectName.log</string>
</dict>
</plist>
LOG_PROCESS

# Create the autopkg_cache_cleaner script by using cat input redirection
# to write the shell script contained below to a new file.
#
# The script will write the repos to a log file
echo "creating script"
/bin/cat > "/tmp/$projectName.sh" << LOG_SCRIPT

### INSERT SCRIPT HERE

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
