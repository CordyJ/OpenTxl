TXL Grammar for PHP 3,4,5 (BETA)
J.R. Cordy, Queen's University, June 2007
Version 0.3, February 2009

After the SDF PHP grammar by Eric Bouwers and Martin Bravenboer in PhpFront
http://www.program-transformation.org/PHP/PhpFront

Example:
        txl Examples/ApiBase.php

This is an analysis grammar for PHP versions 3,4 and 5 derived from the source
above.  It has been tested on over 500 examples from open source PHP applications, 
but is still known to fail on certain strangely formed examples. 

This is still a work in progress.

Known limitations and bugs:

1. This grammar is known to fail on examples where HTML is interspersed in
   the middle of a PHP statements.  This would be difficult to fix.
   Recommended workaround: edit to move split to statement boundary.

2. This grammar purposely uses a simple ambiguous non-precedence expression grammar. 
   For this reason several nonterminals are defined in pieces so that precedence 
   can be added later.  For most transformations precedence shouldn't matter.

3. This grammar is intended primarily for analysis tasks and has not yet been tuned 
   for high fidelity transformations.  In particular it does not yet offer the 
   option of preserving comments and formatting.

---
Rev 22.2.09
