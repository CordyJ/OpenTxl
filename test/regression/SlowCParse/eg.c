/* 
From postmaster@ns-1.csn.net Thu Mar  9 22:31 EST 1995
From: melges@advancedsw.com (Mike Elges)
Subject: Problem with TXL
To: cordy@qucis.queensu.ca

Hello Prof Cordy,

  I think I have found a bug in txl.  If you take this file:

--------------Start of File-----------------------------------------------
*/

static char text_bits[] = {
 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
 0x00,0x00,0x00,0x08,0x00,0x00,0x00,0x0c,0x00,0x00,0x00,0x1c,0x00,0x00,0x00,
 0x1c,0x00,0x00,0x00,0x3a,0x00,0x00,0x00,0x32,0xe0,0x01,0x00,0x33,0x10,0x03,
 0x00,0x61,0x30,0x03,0x00,0x7f,0xc0,0x03,0x80,0xc0,0x30,0x03,0x80,0xc0,0x18,
 0x03,0xc0,0xc0,0x99,0x0b,0xf0,0xe3,0x73,0x0e,0x00,0x00,0x00,0x00,0x00,0x00,
 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
 
/*
-------------End of File--------------------------------------------------

try to parse it using your C grammer it just goes off into space never
to return.  Now if you delete any line (except the first or last) it will
take a long time but it will finally parse.  If you delete Two Lines it
parses even faster.  My guess is there is something exponetial going
on here.  I have traced the tree and it is following the correct path it
just seems to get lost.  This is true on both 7.4 and 7.7a5.

Any Thoughts!!  This is preventing us from Betaing our product and my VP
is ready to junk the TXL in favor of YACC (YUK).  This seems to be
my last problem.  By the way I have found about 8-10 problems with
the original grammer which I have fixed.  Would you like a copy?  There
is one problem that does not seem fixable by the grammer.  Because 
the C grammer has typedefs TXL grammer has to treat them as Identifiers.
This leads to confusion where a Functions get parsed as declarators.

for example
{
	foo(a);
}

foo will be parsed as a declaration.  I have followed the grammer and it
is correct.  It things foo is a type specifier and (a) is a parened 
variable declaration.  I have work arounds in my rules to catch this
but it is very ugly.  This begs the question of the potential of TXL.
Because it has no way of collecting valid Type specifiers as it parses
and I see no work around in the grammer itself what is the answer.
Is the problem in the C language that seems to need semantic information
when it parses????  Or is this a limitation of TXL.


Any Help Would Be APPRECIATED!!!!!!

Thanks in advance

Mike Elges

*/
