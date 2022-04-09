# WSL Portproxy
Puts wsl on the public internet by running a netsh portproxy through an admin powershell, all within wsl.
## Why
If you run an apache server on port 80 and connect to your public ip, you will time out, as
WSL2 runs within its own virtual network that only the local computer can connect to.
In order to get around this, you need to run this within an elevated powershell:
```powershell
netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=wsl_ip
netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=443 connectaddress=wsl_ip
```
And in order to get the wsl_ip, you need to run this within wsl:
```sh
ip -4 -j route | grep -o '"prefsrc":"[^"]*' | grep -o '[^"]*$'
```
Originally, the quick solution was to do `ip a | grep eth0`, find and copy the ip,
make two commands, and call it a day. But the WSL ip changes sometimes, and that
annoyance spawned this script.

It runs an elevated powershell within a process to run the netsh.

## Usage
```console
$ ./wsl_portproxy.sh -h
Usage: wsl_portproxy [-a <addr>] [-p <port1,port2...>]
   eg: wsl_portproxy -p 80,8080,443
   eg: wsl_portproxy -a 172.12.34.56 -p 80
   eg: wsl_portproxy -a 172.12.34.56
   eg: wsl_portproxy

   -a  IP to portproxy windows to.
       The default ip used is the local WSL2 ip outputted by:
       $ ip -4 -j route | grep -o '"prefsrc":"[^"]*' | grep -o '[^"]*$'

   -p  Port(s) to portproxy with
       Default ports: 80, 443
```
_** with no opts, default usage will automatically open the local wsl_ip on ports 80 and 443_
```console
$ ./wsl_portproxy.sh
Windows portproxy started on 0.0.0.0:80 to 172.12.34.56:80
Windows portproxy started on 0.0.0.0:443 to 172.12.34.56:443
```
