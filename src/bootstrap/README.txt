The TXL Bootstrap grammar

TXL uses the same parser to parse TXL programs, grammars and rule sets as it does to parse user languages.
In order to do so, it must build a grammar tree for the TXL language without using the TXL grammar compiler.
It does so using a minimal basic grammar processor (../boot.i).

In order to speed the bootstrap process and avoid re-scanning the TXL language grammar on every TXL run, 
the TXL language grammar (Txl-11-bootstrap.grm) is pre-scanned into an initialized array of tokens 
to be processed by the bootstrap grammar processor. 

The process in this directory transforms the TXL grammar into this token array form (bootgrm.i)
to be included in the TXL processor source.

