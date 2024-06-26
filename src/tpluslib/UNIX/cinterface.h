/*
 * Adapted with permission from :
 *
 * Interface for Turing Plus to C translator
 * (c) 1987,1988,1989,1990 Holt Software Associates Inc.
 * All rights reserved.
 *
 * (These definitions may have to change from machine to machine.)
 *
 */
 
/* Named limits - JRC 9.4.24 */
/* Fixed memory leak in filenames - DAD 6.4.24 */

/* Updated library naming conventions to T+ 6.0 standard - JRC 11.7.18 */
/* Revised exception handling to be consistent with T+ 6.0 standard - JRC 11.7.18 */

/* Revised to be both 32- and 64-bit compatible - JRC 11.8.15 */
/* Removed obsolete SYS5 signal handling logic - JRC 11.8.15 */
/* Added missing implicit includes - JRC 11.8.15 */

/* TLIGSS repaired to handle unended and long input lines -- JRC 14.2.96 */
/* TL_TLA_TLAQ corrected to give 0 status for quit:0 -- JRC 6.3.97 */
/* TL_TLI_TLIFS added to allow flushing of buffered streams -- JRC 18.3.97 */
/* Added heap memory map to assist in converting to re-entrant subroutine -- JRC 16.5.97 */
/* Added TL_TLI_TLIPN (nat number output) -- JRC 12.3.98 */
/* Modified to use ANSI * substitution in printf widths -- JRC 20.7.98 */
/* Fixed TLIGSS to handle EOF correctly on Unix systems -- JRC 13.5.99 */
/* Unfixed TLIGSS and fixed TLIEOF to handle EOF correctly on Unix systems -- JRC 12.6.99 */
/* Added TLSVSI -- JRC 12.10.99 */
/* Updated TL_TLS_TLSVRS pattern to give more digits in integer results -- JRC 11.7.13 */
/* Added required includes for Windows 7/8 64 bit -- JRC 20.12.14 */
/* Added TL_TLA_TLA8FL -- JRC 2.2.15 */

/* Limits */
#define STRINGSIZE 4096
#define MAXALLOCS 100
#define MAXFILES 25

/* Predefined Types */
typedef char            TLboolean;
typedef unsigned char   TLchar;
typedef char            TLint1;
typedef short           TLint2;
typedef int             TLint4;
typedef unsigned char   TLnat1;
typedef unsigned short  TLnat2;
typedef unsigned int    TLnat4;
typedef float           TLreal4;
typedef double          TLreal8;
typedef char            TLstring[STRINGSIZE];
typedef char            *TLaddressint;

/* Old style, in case our T+ compiler is on Sun OS 4.x */
typedef char            TLSTRING[STRINGSIZE];
typedef char            *TLADDRESSINT;

/* Non-scalar assignment macros */
#define TLSTRCTASS(dest,src,type)       dest = src  /* struct assignment */
#define TLNONSCLASS(dest,src,type)      memcpy((char *)(dest), (char *)(src), (sizeof(type)))

/* Bind macros */
#define TLBIND(t,type)          type t
#define TLBINDREG(t,type)       register type t

/* TLE - Signal handling routines */
#include <setjmp.h>
extern struct TLHAREA {
        int             quitCode;
        jmp_buf         quit_env;
        struct TLHAREA *old_handlerArea;
} *TL_handlerArea;
extern struct TLHAREA *TL_currentHandlerArea;
extern struct TLHAREA defaultHandlerArea;

#define TLHANDENTER(handlerArea)  \
        ( \
            handlerArea.old_handlerArea = TL_handlerArea, \
            TL_handlerArea = &handlerArea, \
            TL_handlerArea->quitCode = 0, \
            setjmp (TL_handlerArea->quit_env) \
        )

#define TL_TLE_TLEHX()  \
        { \
            TL_handlerArea = TL_handlerArea->old_handlerArea; \
        }

#define TL_TLE_TLEQUIT(code, place, qtype)  \
        { \
            TL_currentHandlerArea = TL_handlerArea; \
            TL_currentHandlerArea->quitCode = code; \
            if (TL_currentHandlerArea != &defaultHandlerArea) \
                TL_handlerArea = TL_handlerArea->old_handlerArea; \
            longjmp (TL_currentHandlerArea->quit_env, code); \
        }

/* TLB - Storage management routines */
#include <stdlib.h>
#ifdef WIN
#include <malloc.h>
#endif

extern void *TL_mallocs[];
extern int TL_nextmalloc;

#define TLDYN(x)        (x)

#define TL_TLB_TLBALL(size, addr) \
        { \
            (*addr) = (void *) (malloc(size)); \
            if ((*addr) == (void *) 0) { \
                fprintf (stderr, "TXL ERROR : (Fatal) Available heap space too small for TXL heap at this size\n"); \
                exit (1); \
            } \
            TL_mallocs[TL_nextmalloc++] = (void *) (*addr); \
        }

/* TLI - I/O routines */
#include <stdio.h>
#define READ_MODE 0
#define WRITE_MODE 1
extern FILE *TL_files[];
extern char *TL_filenames[];
extern char TL_filemode[];
extern int TL_nextfile;
extern int TL_TLI_lookahead;
#define TL_TLI_TLISSI()
#define TL_TLI_TLISSO()
#define TL_TLI_TLIGS(length, target, stream)  /* TL_TLI_TLIGSS(length, target, stream) */ \
        fscanf (TL_files[stream+2], "%s", target)
#define TL_TLI_TLIEOF(streamNo) \
        ((((TL_TLI_lookahead = (getc (TL_files [streamNo+2]))) != EOF) \
                        ? (ungetc (TL_TLI_lookahead, TL_files [streamNo+2])) : 1), \
                 (feof (TL_files [streamNo+2])))
#define TL_TLI_TLICL(streamNo)  \
        fclose (TL_files [streamNo+2]), \
        TL_files [streamNo+2] = NULL, \
        free(TL_filenames [streamNo+2]), \
        TL_filenames [streamNo+2] = NULL
#define TL_TLI_TLIGC(getWidth, getItem, getItemSize, streamNo) \
        *getItem = fgetc (TL_files[streamNo+2]); \
        if (*getItem == (unsigned char) EOF) *getItem = '\0'
#define TL_TLI_TLIGN(getItem, getItemSize, streamNo) \
        fscanf (TL_files[streamNo+2], "%lu", getItem)
#define TL_TLI_TLIGSS(itemSize, getItem, streamNo) \
        if (fgets (getItem, itemSize+1, TL_files [streamNo+2]) == NULL) { \
            *getItem = '\0'; \
        } else { \
            int i = strlen(getItem)-1; \
            if (getItem[i] == '\n') \
                getItem[i] = '\0'; \
        }
#define TL_TLI_TLIPI(putWidth, putItem, streamNo) \
            fprintf (TL_files [streamNo+2], "%*i", putWidth, putItem)
#define TL_TLI_TLIPN(putWidth, putItem, streamNo) \
            fprintf (TL_files [streamNo+2], "%*u", putWidth, putItem)
#define TL_TLI_TLIPF(putPrec, putWidth, putItem, streamNo) \
            fprintf (TL_files [streamNo+2], "%*.*f", putWidth, putPrec, putItem)
#define TL_TLI_TLIPK(streamNo) \
        fputc ('\n', TL_files [streamNo+2]) 
#define TL_TLI_TLIPS( putWidth, putItem, streamNo) \
            fprintf (TL_files [streamNo+2], "%-*s", putWidth, putItem)
#define TL_TLI_TLIRE(readItem, itemSize, status, streamNo) \
         fread (readItem, itemSize, 1, TL_files [streamNo+2])
#define TL_TLI_TLIWR(writeItem, itemSize, status, streamNo) \
         fwrite (writeItem, itemSize, 1, TL_files [streamNo+2])
#define TL_TLI_TLISKE(streamNo) \
         fseek (TL_files [streamNo+2], 0, SEEK_END)
extern void TL_TLI_TLIOF();
extern void TL_TLI_TLISS();
extern void TL_TLI_TLIFS();
extern void TL_TLI_TLIGK();

/* TLM - numeric routines */
#include <math.h>
#define TL_TLM_TLMIMN(right, left)    (left < right ? left : right)
#define TL_TLM_TLMIMX(right, left)    (left > right ? left : right)
#define TL_TLM_TLM8RD(value)    ((int)(value))
#define TL_TLM_TLM8FL(value)    (floor(value))
#define TLSIMPLEMAX(a,b)        ((a) > (b) ? (a) : (b))
#define TLSIMPLEMIN(a,b)        ((a) < (b) ? (a) : (b))
#define TLSIMPLEABS(a)          ((a) < 0 ? -(a) : (a))
#define TLSUCC(x,y)             ((x)+1)

#define TL_TLA_TLA8RD(value) TL_TLM_TLM8RD(value)
#define TL_TLA_TLA8FL(value) TL_TLM_TLM8FL(value)
#define TL_TLA_TLAIMX(right, left) TL_TLM_TLMIMX(right, left)
#define TL_TLA_TLAIMN(right, left) TL_TLM_TLMIMN(right, left)

/* TLS - string routines */
#include <string.h>
#define TLCHRTOSTR(c, t)        (t[0] = c, t[1] = '\0')
#define TLCVTTOCHR(c)           c[0]
#define TLSTRASS(size,dest,src)         strcpy((char *)(dest), (char *)(src))
#define TLSTRCATASS(dest,src,size)      strcat(dest, src)
#define TLSTRCMP(left,right)            strcmp((char *)(left), (char *)(right))
#define TLCHRSTRCMP(left,right,size)    memcmp(left, right, size)
#define TL_TLS_TLSBS(target, offset, source) \
        (target[0] = source[strlen(source)+offset-1], target[1] = '\0')
#define TL_TLS_TLSBX(target, charIndex, source) \
        (target[0] = source[charIndex-1], target[1] = '\0')
#define TL_TLS_TLSCAT(left, right, target) \
        strcpy (target, left), strcat (target, right)
#define TL_TLS_TLSCTA(target, targetSize, right) \
        strcat (target, right)
#define TL_TLS_TLSLEN(source) \
        strlen (source)
#define TL_TLS_TLSVRS(value, width, target) \
        sprintf (target, "%.15g", value)
extern void TL_TLS_TLSBXS();
extern void TL_TLS_TLSBXX();
extern int  TL_TLS_TLSIND();
extern void TL_TLS_TLSRPT();
extern void TL_TLS_TLSVIS();
extern void TL_TLS_TLSVNS();
extern double TL_TLS_TLSVS8();
extern int  TL_TLS_TLSVSI();

/* Program parameters */
extern int  TL_TLI_TLIARC;
extern char **TL_TLI_TLIARV;
extern void TL_TLI_TLIFA();
