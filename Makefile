# OpenTxl Version 11 build process
# J.R. Cordy, July 2022

# Copyright 2022, James R. Cordy and others

# This process builds the fully checked Turing+ version of the Txl-11 compiler/interpreter and command line tools

TXLSRCS = src/globals.i src/ident.i src/locale.i src/limits.i src/options.i src/unparse.i src/rules.i \
	  src/symbols.i src/errors.i src/trees.i src/treeops.i src/tokens.i src/charset.i src/shared.i \
	  src/errormsg.i src/scan.i src/boot.i src/bootgrm.i

COMPILEOBJS = objs/comprul.o objs/compdef.o objs/loadstor.o 

GENERALOBJS = objs/locale.o 

OBJS = ${COMPILEOBJS} ${GENERALOBJS}

TPCFLAGS = -O -DCHECKED

CC = cc -c
COPTS = -w

# Main

all : bin lib bin/txl bin/txldb bin/txlc bin/txlp lib/txlpf.x lib/txlvm.o lib/txlmain.o lib/txlcvt.x lib/txlapr.x

bin/txl : objs objs/txl.o objs/xform.o objs/parse.o ${OBJS} 
	tpc ${TPCFLAGS} -o bin/txl objs/txl.o objs/xform.o objs/parse.o ${OBJS}
	
bin/txldb : objs objs/txl.o objs/xformdb.o objs/parse.o ${OBJS} 
	tpc ${TPCFLAGS} -o bin/txldb objs/txl.o objs/xformdb.o objs/parse.o ${OBJS} 
	
bin/txlc : src/scripts/t/txlc
	cp src/scripts/t/txlc bin/txlc

bin/txlp : src/scripts/t/txlp
	cp src/scripts/t/txlp bin/txlp

# Library

lib/txlpf.x : objs/txl.o objs/xformpf.o objs/parsepf.o ${OBJS} 
	tpc ${TPCFLAGS} -o lib/txlpf.x objs/txl.o objs/xformpf.o objs/parsepf.o ${OBJS} 
	    
lib/txlvm.o : objs/txlsa.o objs/xform.o objs/loadsa.o objs/parsa.o ${GENERALOBJS} 
	ld -r -o lib/txlvm.o objs/txlsa.o objs/xform.o objs/loadsa.o objs/parsa.o ${GENERALOBJS} 

lib/txlmain.o : objs/main.o
	ld -r -o lib/txlmain.o objs/main.o 

lib/txlcvt.x : objs/txlcvt.o
	tpc ${TPCFLAGS} -o lib/txlcvt.x objs/txlcvt.o

lib/txlapr.x : objs/txlapr.o
	tpc ${TPCFLAGS} -o lib/txlapr.x objs/txlapr.o

# Bootstrap

src/bootgrm.i : src/bootstrap/bootgrm.i
	pushd src/bootstrap; make; popd 
	cp src/bootstrap/bootgrm.i src/bootgrm.i

# Modules

objs/txl.o : src/txl.t ${TXLSRCS}
	/bin/rm -f objs/txl.o
	tpc ${TPCFLAGS} -c src/txl.t
	mv txl.o objs/txl.o
	
objs/txlsa.o : src/txl.t ${TXLSRCS}
	/bin/rm -f objs/txlsa.o
	tpc ${TPCFLAGS} -DNOCOMPILE -DSTANDALONE -c src/txl.t
	mv txl.o objs/txlsa.o
	
objs/compdef.o : src/compdef.ch src/limits.i src/trees.i src/treeops.i src/ident.i src/txltree.i \
	    src/compdef-analyze.i 
	/bin/rm -f objs/compdef.o
	tpc ${TPCFLAGS} -c src/compdef.ch 
	mv compdef.o objs/compdef.o

objs/comprul.o : src/comprul.ch src/limits.i src/tokens.i src/rules.i src/symbols.i src/trees.i src/treeops.i \
	    src/txltree.i src/ident.i
	/bin/rm -f objs/comprul.o
	tpc ${TPCFLAGS} -c src/comprul.ch 
	mv comprul.o objs/comprul.o

objs/xform.o : src/xform.ch src/limits.i src/rules.i src/charset.i src/trees.i src/treeops.i src/ident.i \
	    src/xform-predef.i src/xform-garbage.i 
	/bin/rm -f objs/xform.o
	tpc ${TPCFLAGS} -c src/xform.ch 
	mv xform.o objs/xform.o

objs/xformpf.o : src/xform.ch src/limits.i src/rules.i src/charset.i src/trees.i src/treeops.i src/ident.i \
	    src/xform-predef.i src/xform-garbage.i 
	/bin/rm -f objs/xformpf.o
	tpc ${TPCFLAGS} -w -DPROFILER -c src/xform.ch 
	mv xform.o objs/xformpf.o

objs/xformdb.o : src/xform.ch src/limits.i src/rules.i src/charset.i src/trees.i src/treeops.i src/ident.i \
	    src/xform-predef.i src/xform-garbage.i src/xform-debug.i
	/bin/rm -f objs/xformdb.o
	tpc ${TPCFLAGS} -w -DDEBUGGER -DTIMING -c src/xform.ch 
	mv xform.o objs/xformdb.o

objs/parse.o : src/parse.ch src/limits.i src/tokens.i src/trees.i src/treeops.i src/ident.i
	/bin/rm -f objs/parse.o
	tpc ${TPCFLAGS} -c src/parse.ch 
	mv parse.o objs/parse.o

objs/parsa.o : src/parse.ch src/limits.i src/tokens.i src/trees.i src/treeops.i src/ident.i
	/bin/rm -f objs/parsa.o
	tpc ${TPCFLAGS} -DNOCOMPILE -DSTANDALONE -c src/parse.ch 
	mv parse.o objs/parsa.o

objs/parsepf.o : src/parse.ch src/limits.i src/tokens.i src/trees.i src/treeops.i src/ident.i
	/bin/rm -f objs/parsepf.o
	tpc ${TPCFLAGS} -DPROFILER -c src/parse.ch 
	mv parse.o objs/parsepf.o
	
objs/loadstor.o : src/loadstor.ch src/limits.i src/trees.i src/treeops.i src/ident.i src/symbols.i src/rules.i src/options.i
	/bin/rm -f objs/loadstor.o
	tpc ${TPCFLAGS} -c src/loadstor.ch 
	mv loadstor.o objs/loadstor.o
	
objs/loadsa.o : src/loadstor.ch src/limits.i src/trees.i src/treeops.i src/ident.i src/symbols.i src/rules.i src/options.i
	/bin/rm -f objs/loadsa.o
	tpc ${TPCFLAGS} -DNOCOMPILE -DSTANDALONE -c src/loadstor.ch 
	mv loadstor.o objs/loadsa.o
	
objs/txlcvt.o : src/txlcvt.t 
	/bin/rm -f objs/txlcvt.o
	tpc ${TPCFLAGS} -c src/txlcvt.t 
	mv txlcvt.o objs/txlcvt.o

objs/txlapr.o : src/txlapr.t 
	/bin/rm -f objs/txlapr.o
	tpc ${TPCFLAGS} -c src/txlapr.t 
	mv txlapr.o objs/txlapr.o

objs/locale.o : src/locale.c
	/bin/rm -f objs/locale.o
	${CC} ${COPTS} src/locale.c  
	mv locale.o objs/locale.o

objs/main.o : src/tpluslib/TL.h src/main.c
	${CC} $(COPTS) -DBSD src/main.c; mv main.o objs/main.o

# Directories

bin :
	mkdir bin

lib :	
	mkdir lib

objs : 
	mkdir objs

clean :
	/bin/rm -f bin/* lib/* objs/* 
	/bin/rm -rf csrc 
	cd test; make clean; cd ..
	cd test/regression; make clean; cd ../..

# Production auto-generated C version

C :
	make -f Makefile-C

