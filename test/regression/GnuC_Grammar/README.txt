Validated TXL Basis Grammar for C with Macros and Gnu Extensions
Version 4.2, June 2010

Copyright 1994-2010 James R. Cordy, Andrew J. Malton and Christopher Dahn
Licensed under the MIT open source license, see source for details.

Description:
    Consolidated grammar for K+R and ANSI C with Gnu extensions
    designed for large scale C analysis tasks.  Validated on a large range 
    of open source C software including Bison, Cook, Gzip, Postgresql, SNNS, 
    Weltab, WGet, Apache HTTPD and the entire Linux 2.6 kernel.

    Handles both preprocessed and unpreprocessed C code with with expanded or
    unexpanded C macro calls.  

    Handles but does not interpret C preprocesor directives, except #ifdefs 
    that violate syntactic boundaries.  #ifdefs can be handled using the 
    Antoniol et al. transformation that comments out the #else part.

    Ignores and does not preserve comments.

Authors:
    J.R. Cordy, Queen's University
    A.J. Malton, University of Waterloo
    C. Dahn, Drexel University

Example:
    txl program.c c.txl
    txl porogram.c ifdef.txl > program_ifdef.c;  txl program_ifdef.c c.txl
