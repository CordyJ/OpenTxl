#!/bin/bash

# OpenTxl Regression Test script
# J.R. Cordy, October 2022

# The TXLs to compare
OLDTXL=/usr/local/bin/txl
NEWTXL=../../bin/txl

if [ ! -x $OLDTXL ]; then
    echo "ERROR: No installed TXL to compare to ($OLDTXL)"
    exit 1
fi

if [ ! -x $NEWTXL ]; then
    echo "ERROR: No new TXL to compare to ($NEWTXL - did you remember to build it?)"
    exit 1
fi

# Unlimit stack, set up fake input
ulimit -s hard
echo "42" > /tmp/42

# Clean up old results
/bin/rm -f */*-oldoutput */*-newoutput

# Keep track of success
echo "==== TESTING ===="
success=true

# For all of the tests in the regression set
dirs=`/bin/ls`

for dir in $dirs; do
    if [ -d $dir ]; then
        cd $dir

        # For each example input
        egs=`/bin/ls eg*.*`

        for eg in $egs; do
            # Run old TXL
            : > /tmp/tta-old$$
            (/usr/bin/time $OLDTXL -v -s 400 -w 200 $eg -o /tmp/tta-old$$ < /tmp/42 2>&1 ) >> $eg-oldoutput
            cat /tmp/tta-old$$ >> $eg-oldoutput
            grep "TXL0" $eg-oldoutput >> /tmp/tta-old$$

            # Run new TXL
            : > /tmp/tta-new$$
            (/usr/bin/time ../$NEWTXL -v -s 400 -w 200 $eg -o /tmp/tta-new$$ < /tmp/42 2>&1 ) >> $eg-newoutput
            cat /tmp/tta-new$$ >> $eg-newoutput
            grep "TXL0" $eg-newoutput >> /tmp/tta-new$$

            # Diff them
            if [ "`diff -q /tmp/tta-old$$ /tmp/tta-new$$`" != "" ]; then
                echo "** Output for $dir/$eg differs"
                success=false
            fi

            # Diff detailed performance if requested
            if [ "$1" == "performance" ]; then
                echo "==== $dir/$eg ===="
                diff $eg-oldoutput $eg-newoutput
            fi
        done
        cd ..
    fi
done

# Report results
if [ "$success" == "true" ]; then
    echo "==== SUCCEEDED ===="
else
    echo "==== FAILED ===="
fi
