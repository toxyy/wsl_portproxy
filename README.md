# WSL Portproxy
Puts wsl on the public internet by running a netsh portproxy command through an admin powershell, all within wsl.

```sh
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
```
