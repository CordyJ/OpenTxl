The OpenTxl Turing+ source code and build process

OpenTxl requires the Turing+ compiler, tpc, to build.

To build the fully checked debugging version of TXL in pure Turing+, 
use the command "make" in this directory.

Tests can be run in the test/ subdirectory. Run "make" in that directory
for a basic functionality test, and run "make" in the test/regression/
subdirectory for a full regression test. See the README.txt files 
in those directories for further information.

To build the fast production version of TXL using auto-generated C code, 
first use the command "make C" in this directory to make the auto-generated 
C directory "csrc", then see the README.txt file in that directory 
for production build instructions.

