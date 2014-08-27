This is a script I discovered on GitHub which creates VMs on a VMWare ESX server. Special thanks goes to Tamas Piros who created the inital script.

I have just updated it to work with the latest ESXi servers (ESXi version 5.5). I have also changed to defaults to suit my preference.

Automatic Virtual Machine creation on an ESXi server

Usage: /bin/sh create.sh options: n <|c|i|r|s>


Where n: Name of VM (required), c: Number of virtual CPUs, i: location of an ISO image, r: RAM size in MB, s: Disk size in GB

Default values are: CPU: 1, RAM: 2048MB, HDD-SIZE: 16GB
