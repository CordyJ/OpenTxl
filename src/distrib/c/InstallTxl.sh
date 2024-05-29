#!/bin/sh
# OpenTxl Version 11 Installation script
# Copyright 2022, James R. Cordy and others

echo ""
echo "Installing OpenTxl 11 on your system."
sleep 1

# Default locations
DEFAULT=true
TXLBIN=/usr/local/bin
TXLLIB=/usr/local/lib/txl
TXLMAN=/usr/local/man/man1

# Localization
if [ -x /usr/bin/sed ] 
then
        SED=/usr/bin/sed
else
        SED=/bin/sed
fi
unset noclobber

# Check what kind of installation we have here
case `uname -s` in
    CYGWIN*|MSYS*|MINGW64*)
        ;;
    *)
        if [ "`whoami`" != "root" ]
        then
            echo ""
            echo "Warning - you are not running as root, so you can install TXL for yourself only."
            echo "If you intend to install TXL for all users on this machine,"
            echo "you will have to run this install script as root, for example using 'sudo ./InstallTxl'."
            echo ""
            echo "Do you want to continue to install TXL for yourself only? (y/n) :"
            read YESNO
            if [ "$YESNO" = "y" ] 
            then
                echo ""
                echo "Installing TXL for $USER only."
                DEFAULT=false
                TXLBIN=$HOME/bin
                TXLLIB=$HOME/txl/lib
                TXLMAN=$HOME/txl/man/man1
            else
                exit 99
            fi
        fi
esac
sleep 1

# Install TXL commands
echo ""
echo "Installing TXL commands into $TXLBIN"
/bin/mkdir -p $TXLBIN
/bin/cp ./bin/* $TXLBIN
if [ "$DEFAULT" != "true" ]
then
    for i in $TXLBIN/txlc $TXLBIN/txlp
    do
        $SED -e "s;/usr/local/lib/txl;$TXLLIB;" -e "s;/usr/local/bin;$TXLBIN;" < $i > $i.temp
        /bin/mv $i.temp $i
        chmod 0755 $i
    done
fi
sleep 1

# Install TXL library
echo ""
echo "Installing TXL library into $TXLLIB"
/bin/mkdir -p $TXLLIB
/bin/cp ./lib/* $TXLLIB
sleep 1

# Enable the TXL commands in MacOS
if [ `uname -s` = Darwin ]
then
    echo ""
    echo "Enabling TXL commands in MacOS"
    spctl --remove --label "TXL" >& /dev/null
    spctl --add --label "TXL" $TXLBIN/txl*
    spctl --add --label "TXL" $TXLLIB/txl*.x
    spctl --enable --label "TXL"
fi

# Test TXL
echo ""
echo "Testing TXL"
echo ""
sleep 1

cd ./test
$TXLBIN/txl ultimate.question

echo ""
echo "Done."
echo ""

# Rev 29.5.24
