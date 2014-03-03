.SUFFIXES :

.SUFFIXES : .c .ftn .f .o .a .f90

SHELL = /bin/sh

CPP = /lib/cpp

RMNLIB_BASE_PATH=$(ARMNLIB)

RMNLIB = $(RMNLIB_BASE_PATH)/lib/$(EC_ARCH)$(ABI)/librmn.a

FFLAGS = =-C -g

CFLAGS = -g
SUPP_OPT = -openmp

OPTIMIZ = 2

CPPFLAGS = -I$(ARMNLIB)/include

.PRECIOUS: $(RMNLIB) $(MALIB)

default: obj

include $(ARMNLIB)/include/makefile_suffix_rules.inc

CDECKS= fstd98.c

FDECKS=

FTNDECKS= 

COMDECKS = 

OBJECTS= fstd98.o


FICHIERS = $(FDECKS) $(CDECKS) $(FTNDECKS) $(COMDECKS)

fstd98.o:	fstd98.c if_fstd98.c qstdir.h proto.h

obj: $(OBJECTS) 
#Produire les fichiers objets (.o) pour tous les fichiers

clean:
#Faire le grand menage. On enleve tous les fichiers sources\ninutiles et les .o 
	-if [ "*.ftn" != "`echo *.ftn`" ] ; \
	then \
	for i in *.ftn ; \
	do \
	fn=`r.basename $$i '.ftn'`; \
	rm -f $$fn.f; \
	done \
	fi
	rm -f *.o *.mod
