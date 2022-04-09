#!/bin/sh
#
# Copyright (C) 2022 toxyy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

help() { cat <<HELP
Usage: wsl_portproxy [-a <addr>] [-p <port1,port2...>]
   eg: wsl_portproxy -p 80,8080,443
   eg: wsl_portproxy -a 127.0.0.1 -p 80
   eg: wsl_portproxy -a 127.0.0.1
   eg: wsl_portproxy

   -a  IP to portproxy windows to.
       The default ip used is the local WSL2 ip outputted by:
       $ ip -4 -j route | grep -o '"prefsrc":"[^"]*' | grep -o '[^"]*$'

   -p  Port(s) to portproxy with
       Default ports: 80, 443
HELP
}

# default ip: the wsl local ip
ip=$(ip -4 -j route | grep -o '"prefsrc":"[^"]*' | grep -o '[^"]*$')
# default ports: 80, 443
ports=80,443

# validate port input
# strips commas from a delimited string, checks to see if leftovers are ints
is_integer() {
  int_arr=$(echo "$1" | tr -d ',')
  case "$int_arr" in
    (*[!0123456789]*) return 1 ;;
    ('')              return 1 ;;
    (*)               return 0 ;;
  esac
}

# opts get parameter priority
while getopts "a:p:h" opt; do
  case $opt in
    a) ip="$OPTARG";;
    p)
      if ! is_integer "$OPTARG" || [ -z "$OPTARG" ]; then
        echo "Ports must be a number"
        exit 0
      else
        ports="$OPTARG"
      fi;;
    h)
      help
      exit 0;;
    *) exit 0;;
  esac
done
shift $((OPTIND -1))

# returns a ps command to create a portproxy on 0.0.0.0:port to input_ip:port
# usage: get_netsh [ip] [port]
get_netsh() {
  ps_portproxy="netsh interface portproxy add v4tov4
    listenport=$2 listenaddress=0.0.0.0 connectport=$2 connectaddress=$1;"
  echo $ps_portproxy
}

# returns all portproxy commands from corresponding $ports
# if any args are passed at all, it returns the success message instead
# usage: get_ps_portproxy [bool]
get_ps_portproxy() {
  out=''
  # no arrays in posix, so iterate a string with a delimiter instead
  for port in $(echo "$ports" | sed "s/,/ /g"); do
    if [ -z "$1" ]; then
      out="$out$(get_netsh "$ip" "$port")"
    else
      out="$out$(printf "$1" "$port" "$ip" "$port")\n"
    fi
  done
  # remove final comma artifact due to pseudo array
  echo "${out:-1}"
}

# runs a powershell command from wsl as admin
# returns corresponding error code
# usage: ps [script]
ps() {
  # ps script that runs a command as admin, returns error code
  # "1 -eq 1" used instead of True due to error from running inline:
  # "'True' is not recognized as the name of a cmdlet..."
  ps_runas_admin='
    $startInfo = new-object System.Diagnostics.ProcessStartInfo;
    $startInfo.FileName = '\''powershell'\'';
    $startInfo.Arguments = '\'$1\'';
    $startInfo.Verb = '\''RunAs'\'';
    $startInfo.RedirectStandardOutput = 1 -eq 1;
    $startInfo.UseShellExecute = 0 -eq 1;

    $process = [System.Diagnostics.Process]::Start($startInfo);

    $output = $process.StandardOutput.ReadToEnd();

    $process.WaitForExit();
    echo $process.ExitCode'

  # how to run an inline ps script in wsl
  echo "$(powershell.exe Invoke-Command -ScriptBlock \{ "$ps_runas_admin" \})"
}

# main()
errors=$(ps "$(get_ps_portproxy)")

if [ $errors -eq 1 ]; then
  echo "Error starting portproxy to $ip:$ports\n"
else
  echo "$(get_ps_portproxy 'Windows portproxy started on 0.0.0.0:%d to %s:%d')"
fi
