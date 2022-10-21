This directory contains the TXL regression test suite, a set of TXL programs
and applications that must continue to work correctly in new versions of TXL.
To do that, the tests are run and their output compared with the installed
production version of TXL in /usr/local/bin/txl.

To run the regression test suite on a new version of TXL (../../bin/txl), 
first make the new version from source as described in the README.txt file in ../..,
then run the command "make" in this directory to create the differences file "diffs.txt",
and the time and space performance differences file "diffs-performance.txt".

A successful regression test reports "SUCCEEDED" and finds no differences in output,
and reports "SUCCEEDED" and finds only insignificant differences in time and space.

NOTE: 
The T+ checked version of TXL can not handle Unicode characters, and will fail on some Unicode and numeric tests.
The C production version of TXL should handle all tests.
