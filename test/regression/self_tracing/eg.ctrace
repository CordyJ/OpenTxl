#include <stdio.h>

#define maxDepth 6
#define elementType int

elementType stack [maxDepth];
int stackTop;

Push (elementType value)
{
    if (stackTop < maxDepth) {
	stackTop += 1;
	stack [stackTop] = value;
    } else {
	puts ("ERROR: Push\n");
    }
}

Pop ()
{
    if (stackTop > 0) 
	stackTop -= 1;
    else
	printf ("ERROR: Pop\n");
}

elementType Top ()
{
    return (stack [stackTop]);
}

Pause ()
{
    char x;
    puts ("Hit return to continue\n");
    x = getchar ();
}

main ()
{
    stackTop = 0;
    Push (10);
    Push (5);
    Push (-6);
    Push (14); Pause;
    Pop ();
    Pop ();
    Push (99); Pause;
}
