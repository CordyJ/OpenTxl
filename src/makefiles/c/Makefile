# OpenTXL Version 11 production build process
# J.R. Cordy, July 2022

# Copyright 2022, James R. Cordy and others

# Rev v11.1, Jan 2023

# This process builds the production unchecked auto-translated C version 
# of the Txl-11 compiler/interpreter and command line tools

# WARNING: DO NOT RAISE THE C COMPILER OPTIMIZATION LEVEL ABOVE THE DEFAULT (-O) 
# when compiling TXL. TXL is a sufficiently strange program as to cause 
# most optimizing C compilers to generate incorrect code for it, or at 
# the very least to slow it down severely, at higher levels of optimization.

CC = gcc -w -Wno-error=int-conversion 
CFLAGS = -m64 -c -O -fno-inline -I .
LD = gcc
LDFLAGS = -m64 
LDLIBS = -lm
RLFLAGS = -r 
EXE =

# Kind of signals (interrupt handlers) supported by your operating system.
# SIGTYPE=BSD  means Berkeley (BSD) signals, e.g. Linux, MacOS, Cygwin, MinGW, etc.
# SIGTYPE=SYS5 means System V (POSIX) signals, e.g. Solaris, IRIX, etc.
# SIGTYPE=NONE means no signal handling available at all.

SIGTYPE = NONE

# Localization

OS := $(shell (uname -s | sed 's/_.*//'))

MESSAGE = "Unrecognized platform - making TXL using gcc and no signal handling"

ifeq ($(OS), Darwin)
    MESSAGE = "Making TXL on MacOS using gcc and BSD signal handling"
    CFLAGS := $(CFLAGS) -ansi -mmacosx-version-min=10.12
    LDFLAGS := $(LDFLAGS) -mmacosx-version-min=10.12
    SIGTYPE = BSD

else ifeq ($(OS), Linux)
    MESSAGE = "Making TXL on Linux using gcc and BSD signal handling"
    SIGTYPE = BSD

else ifeq ($(OS), CYGWIN)
    MESSAGE = "Making TXL on Cygwin using gcc and BSD signal handling"
    LDFLAGS := $(LDFLAGS) -Wl,--stack,0x2000000
    EXE = .exe
    SIGTYPE = BSD

else ifeq ($(OS), MSYS)
    MESSAGE = "Making TXL on Msys / MinGW using gcc and BSD signal handling"
    LDFLAGS := $(LDFLAGS) -Wl,--stack,0x2000000
    EXE = .exe
    SIGTYPE = BSD

else ifeq ($(OS), MINGW64)
    MESSAGE = "Making TXL on Msys / MinGW using gcc and BSD signal handling"
    LDFLAGS := $(LDFLAGS) -Wl,--stack,0x2000000
    EXE = .exe
    SIGTYPE = BSD
endif

# Object groups

COMPILEOBJS = objs/comprul.o objs/compdef.o 

COMMONOBJS = objs/locale.o

OBJS = ${COMPILEOBJS} ${COMMONOBJS} 

TLOBJS = objs/TLS.o objs/TLI.o

# Main 

all : message alltxls distrib

message:
	@echo ""
	@echo $(MESSAGE)
	@echo ""

alltxls : thetxl thetxldb thetxlpf thetxlvm thetxlcvt thetxlapr 

# Regular versions

thetxl : bin objs objs/main.o objs/txl.o objs/xform.o objs/parse.o objs/loadstor.o ${OBJS} ${TLOBJS} 
	${CC} ${LDFLAGS} -o bin/txl objs/main.o objs/txl.o objs/xform.o objs/parse.o objs/loadstor.o \
	    ${OBJS} ${TLOBJS} ${LDLIBS}
	strip bin/txl${EXE}
	cp scripts/unix/* bin/

thetxldb : bin objs objs/main.o objs/txl.o objs/xformdb.o objs/parse.o objs/loadstor.o ${OBJS} ${TLOBJS} 
	${CC} ${LDFLAGS} -o bin/txldb objs/main.o objs/txl.o objs/xformdb.o objs/parse.o objs/loadstor.o \
	    ${OBJS} ${TLOBJS} ${LDLIBS}
	strip bin/txldb${EXE}

thetxlpf : lib objs objs/main.o objs/txl.o objs/xformpf.o objs/parsepf.o objs/loadstor.o ${OBJS} ${TLOBJS}
	${CC} ${LDFLAGS} -o lib/txlpf.x objs/main.o objs/txl.o objs/xformpf.o objs/parsepf.o objs/loadstor.o \
	    ${OBJS} ${TLOBJS} ${LDLIBS}
	strip lib/txlpf.x

thetxlvm : lib objs objs/main.o objs/txlsa.o objs/xform.o objs/loadsa.o objs/parsa.o ${COMMONOBJS} ${TLOBJS} 
	${LD} ${RLFLAGS} -o lib/txlvm.o objs/txlsa.o objs/xform.o objs/loadsa.o objs/parsa.o \
	    ${COMMONOBJS} ${TLOBJS}
	cp objs/main.o lib/txlmain.o

thetxlcvt : lib objs objs/main.o objs/txlcvt.o
	${CC} ${LDFLAGS} -o lib/txlcvt.x objs/main.o objs/txlcvt.o ${TLOBJS} ${LDLIBS}
	strip lib/txlcvt.x

thetxlapr : lib objs objs/main.o objs/txlapr.o
	${CC} ${LDFLAGS} -o lib/txlapr.x objs/main.o objs/txlapr.o ${TLOBJS} ${LDLIBS}
	strip lib/txlapr.x

objs/main.o : tpluslib/TL.h UNIX main.c 
	${CC} $(CFLAGS) -D${SIGTYPE} main.c; mv main.o objs/main.o

objs/comprul.o : UNIX comprul.c 
	${CC} ${CFLAGS} comprul.c; mv comprul.o objs/comprul.o

objs/compdef.o : UNIX compdef.c 
	${CC} ${CFLAGS} compdef.c; mv compdef.o objs/compdef.o

objs/loadstor.o : UNIX loadstor.c 
	${CC} ${CFLAGS} loadstor.c; mv loadstor.o objs/loadstor.o

objs/ident.o : UNIX ident.c 
	${CC} ${CFLAGS} ident.c; mv ident.o objs/ident.o

objs/scan.o : UNIX scan.c 
	${CC} ${CFLAGS} scan.c; mv scan.o objs/scan.o

objs/parse.o : UNIX parse.c 
	${CC} ${CFLAGS} parse.c; mv parse.o objs/parse.o

objs/parsepf.o : UNIX parsepf.c 
	${CC} ${CFLAGS} parsepf.c; mv parsepf.o objs/parsepf.o

objs/txl.o : UNIX txl.c 
	${CC} ${CFLAGS} txl.c; mv txl.o objs/txl.o

objs/xform.o : UNIX xform.c 
	${CC} ${CFLAGS} xform.c; mv xform.o objs/xform.o

objs/xformpf.o : UNIX xformpf.c 
	${CC} ${CFLAGS} xformpf.c; mv xformpf.o objs/xformpf.o

objs/xformdb.o : UNIX xformdb.c 
	${CC} ${CFLAGS} xformdb.c; mv xformdb.o objs/xformdb.o

objs/TLS.o : UNIX tpluslib/TLS.c
	${CC} ${CFLAGS} tpluslib/TLS.c; mv TLS.o objs/TLS.o

objs/TLI.o : UNIX tpluslib/TLI.c 
	${CC} ${CFLAGS} tpluslib/TLI.c; mv TLI.o objs/TLI.o

objs/locale.o : UNIX locale.c
	${CC} ${CFLAGS} locale.c; mv locale.o objs/locale.o

objs/txlsa.o : UNIX txlsa.c
	${CC} ${CFLAGS} txlsa.c; mv txlsa.o objs/txlsa.o
	
objs/loadsa.o : UNIX loadsa.c
	${CC} ${CFLAGS} loadsa.c; mv loadsa.o objs/loadsa.o

objs/parsa.o : UNIX parsa.c 
	${CC} ${CFLAGS} parsa.c; mv parsa.o objs/parsa.o

objs/txlcvt.o : UNIX txlcvt.c
	${CC} ${CFLAGS} txlcvt.c; mv txlcvt.o objs/txlcvt.o

objs/txlapr.o : UNIX txlapr.c
	${CC} ${CFLAGS} txlapr.c; mv txlapr.o objs/txlapr.o

UNIX : 
	ln -s tpluslib/UNIX
	ln -s tpluslib/UNIX UNIX32
	ln -s tpluslib/UNIX UNIX64

# Configure for distribution

distrib : bin lib opentxl
	@echo ""
	@echo "Configuring for distribution"
	@echo ""
	cp bin/* opentxl/bin/
	cp lib/* opentxl/lib/
	cp scripts/unix/* opentxl/bin/
	cp -r installers/unix/* opentxl/
	cp LICENSE.txt opentxl/
	mv opentxl opentxl-$(OS)
	tar cfz opentxl-$(OS).tar.gz opentxl-$(OS)
	@echo ""
	@echo "Distributable binary in opentxl-$(OS).tar.gz"
	@echo ""

# Directories

objs :
	mkdir objs

bin :
	mkdir bin

lib :
	mkdir lib

opentxl :
	mkdir opentxl opentxl/bin opentxl/lib

clean :
	rm -f UNIX*
	rm -f bin/txl* objs/*.o 
	rm -rf opentxl opentxl-* opentxl*.tar.gz 
	cd test; make clean; cd ..

