The production OpenTxl auto-generated C code and build process

This auto-generated C source version of OpenTXL can be ported and 
compiled on platforms that do not support Turing+.

To build the fast production version of TXL for this platform 
from the auto-generated C code in this directory, use the command "make".  
The distributable binary version of TXL for this platform will be output 
as "opentxl-$(OSTYPE).tar.gz".

Tests can be run in the test/ subdirectory. Run "make" in that directory
for a basic functionality test, and run "make" in the test/regression/
subdirectory for a full regression test. See the README.txt files 
in those directories for further information.

DO NOT DISTRIBUTE A NEW VERSION OF TXL UNTIL IT PASSES ALL OF THE REGRESSION TESTS.

