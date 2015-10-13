#!/bin/sh

#paratmers: machine name (required), CPU (number of cores), RAM (memory size in MB), HDD Disk size (in GB), ISO (Location of ISO image, optional), NETWORKNAME (Network to join)
#default params: CPU: 1, RAM: 2048, DISKSIZE: 16GB, ISO: 'blank', NETWORK: 'VM Network'

phelp() {
	echo "Script for automatic Virtual Machine creation for ESXi"
	echo "Usage: ./create.sh options: n <|c|i|r|s|w>"
	echo "Where n: Name of VM (required), c: Number of virtual CPUs, i: location of an ISO image, r: RAM size in MB, s: Disk size in GB, w: Network Name"
	echo "Default values are: CPU: 1, RAM: 2048MB, HDD-SIZE: 16GB"
}

#Setting up some of the default variables
CPU=1
RAM=2048
SIZE=16
ISO=""
FLAG=true
ERR=false
DATASTORE="datastore1/"
VMPATH="/vmfs/volumes/${DATASTORE}"
ISOPATH="${VMPATH}isos/"
GUESTOS="centos-64"
ETHVIRTDEV="vmxnet3"
NETWORKNAME="VM Network"

#Error checking will take place as well
#the NAME has to be filled out (i.e. the $NAME variable needs to exist)
#The CPU has to be an integer and it has to be between 1 and 32. Modify the if statement if you want to give more than 32 cores to your Virtual Machine, and also email me pls :)
#You need to assign more than 1 MB of ram, and of course RAM has to be an integer as well
#The HDD-size has to be an integer and has to be greater than 0.
#If the ISO parameter is added, we are checking for an actual .iso extension
while getopts n:c:i:r:s:w: option
do
        case $option in
                n)
					NAME=${OPTARG};
					FLAG=false;
					if [ -z $NAME ]; then
						ERR=true
						MSG="$MSG | Please make sure to enter a VM name."
					fi
					;;
                c)
					CPU=${OPTARG}
					if [ `echo "$CPU" | egrep "^-?[0-9]+$"` ]; then
						if [ "$CPU" -le "0" ] || [ "$CPU" -ge "32" ]; then
							ERR=true
							MSG="$MSG | The number of cores has to be between 1 and 32."
						fi
					else
						ERR=true
						MSG="$MSG | The CPU core number has to be an integer."
					fi
					;;
		i)
					ISO=${OPTARG}
					if [ ! `echo "$ISO" | egrep "^.*\.(iso)$"` ]; then
						ERR=true
						MSG="$MSG | The extension should be .iso"
					else
						ISO=${ISOPATH}${ISO}
					fi
					;;
		w)
					NETWORKNAME="${OPTARG}"
					if [ -z "$NETWORKNAME" ]; then
						ERR=true
						MSG="$MSG | Please make sure to enter a network name."
					fi
					;;
					
                r)
					RAM=${OPTARG}
					if [ `echo "$RAM" | egrep "^-?[0-9]+$"` ]; then
						if [ "$RAM" -le "0" ]; then
							ERR=true
							MSG="$MSG | Please assign more than 1MB memory to the VM."
						fi
					else
						ERR=true
						MSG="$MSG | The RAM size has to be an integer."
					fi
					;;
                s)
					SIZE=${OPTARG}
					if [ `echo "$SIZE" | egrep "^-?[0-9]+$"` ]; then
						if [ "$SIZE" -le "0" ]; then
							ERR=true
							MSG="$MSG | Please assign more than 1GB for the HDD size."
						fi
					else
						ERR=true
						MSG="$MSG | The HDD size has to be an integer."
					fi
					;;
				\?) echo "Unknown option: -$OPTARG" >&2; phelp; exit 1;;
        		:) echo "Missing option argument for -$OPTARG" >&2; phelp; exit 1;;
        		*) echo "Unimplimented option: -$OPTARG" >&2; phelp; exit 1;;
        esac
done

if $FLAG; then
	echo "You need to at least specify the name of the machine with the -n parameter."
	exit 1
fi

if $ERR; then
	echo $MSG
	exit 1
fi

if [ -d "$NAME" ]; then
	echo "Directory - ${NAME} already exists, can't recreate it."
	exit
fi

#Creating the folder for the Virtual Machine
mkdir ${NAME}

#Creating the actual Virtual Disk file (the HDD) with vmkfstools
vmkfstools -c "${SIZE}"G -a lsilogic $NAME/$NAME.vmdk

#Creating the config file
touch $NAME/$NAME.vmx

#writing information into the configuration file
cat << EOF > $NAME/$NAME.vmx
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "8"
nvram = "${NAME}.nvram"
pciBridge0.present = "TRUE"
svga.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
vmci0.present = "TRUE"
displayName = "${NAME}"
memSize = "${RAM}"
scsi0.virtualDev = "lsilogic"
scsi0.present = "TRUE"
ide1:0.deviceType = "cdrom-image"
ide1:0.fileName = "${ISO}"
ide1:0.present = "TRUE"
ethernet0.virtualDev = "${ETHVIRTDEV}"
ethernet0.networkName = "${NETWORKNAME}"
ethernet0.addressType = "generated"
ethernet0.present = "TRUE"
scsi0:0.deviceType = "scsi-hardDisk"
scsi0:0.fileName = "${NAME}.vmdk"
scsi0:0.present = "TRUE"
guestOS = "${GUESTOS}"
numvcpus = "${CPU}"
toolScripts.afterPowerOn = "TRUE"
toolScripts.afterResume = "TRUE"
toolScripts.beforeSuspend = "TRUE"
toolScripts.beforePowerOff = "TRUE"
floppy0.present = "FALSE"
EOF

#Adding Virtual Machine to VM register - modify your path accordingly!!
MYVM=`vim-cmd solo/registervm ${VMPATH}${NAME}/${NAME}.vmx`

PADDED=`printf %02d $MYVM`

cat << EOF >> $NAME/$NAME.vmx
RemoteDisplay.vnc.enabled = "TRUE"
RemoteDisplay.vnc.port = "59$PADDED"
EOF

#Powering up virtual machine:
vim-cmd vmsvc/power.on $MYVM

echo "The Virtual Machine is now setup & the VM has been started up. Your have the following configuration:"
echo "Name: ${NAME}"
echo "CPU: ${CPU}"
echo "RAM: ${RAM}"
echo "HDD-size: ${SIZE}"
if [ -n "$ISO" ]; then
	echo "ISO: ${ISO}"
else
	echo "No ISO added."
fi
echo "Thank you."
exit
