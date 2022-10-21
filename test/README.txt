OpenTxl basic functionality test

This directory contains a basic first functionality test for any new version of TXL
that should be run after compiling any new set of changes.

To run the test, use the command "make" in this directory and check that all answers are 42.

This test simply insures that the commands txl, txldb, txlp and txlc are runnable.
The more thorough regression tests in ./regression must be run before distributing any new version.
