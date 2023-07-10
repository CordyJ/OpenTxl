#!/bin/sh
# OpenTxl Version 11 Uninstallation script
# Copyright 2022, James R. Cordy and others

echo ""
echo "Removing OpenTxl from your system."
sleep 1

# Default locations
DEFAULT=true
TXLBIN=/usr/local/bin
TXLLIB=/usr/local/lib/txl

# Localization
if [ -x /usr/bin/sed ] 
then
        SED=/usr/bin/sed
else
        SED=/bin/sed
fi
unset noclobber

# Check what kind of installation we have here
if [ "`whoami`" != "root" ] 
then
        echo ""
        echo "Warning - you are not running as root, so you can uninstall TXL for yourself only."
        echo "If you intend to uninstall a copy TXL installed for all users on this machine,"
        echo "you will have to run this install script as root, for example using 'sudo ./UninstallTxl'."
        echo ""
        echo "Do you want to continue to uninstall TXL for yourself only? (y/n) :"
        read YESNO
        if [ "$YESNO" = "y" ] 
        then
                echo ""
                echo "Uninstalling TXL for $USER only."
                DEFAULT=false
                TXLBIN=$HOME/bin
                TXLLIB=$HOME/txl/lib
        else
                exit 99
        fi
fi

sleep 1

# Uninstall TXL commands
echo ""
echo "Uninstalling TXL commands from $TXLBIN"
/bin/rm -f $TXLBIN/txl $TXLBIN/txldb $TXLBIN/txlp $TXLBIN/txlc 
sleep 1

# Uninstall TXL library
echo ""
echo "Uninstalling the TXL library $TXLLIB"
/bin/rm -rf $TXLLIB
sleep 1

echo ""
echo "Done."
echo ""

# Rev 17.10.22
