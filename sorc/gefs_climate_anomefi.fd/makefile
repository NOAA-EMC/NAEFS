SHELL=	/bin/bash
#INC= /nwprod/lib/incmod/g2_4
#LIBS= -L/nwprod/lib -lg2_4 -lw3nco_4 -lbacio_4 \
	-ljasper -lpng -lz
SRCSf90= anomaly_mod.f90 gefs_climate_anomefi.f90 printinfr.f90 init_parm.f90 grib_cnvfnmoc.f90
SRCSf=   CDFNOR.f QUANOR.f QUASTN.f 
SRCS= $(SRCSf90) $(SRCSf)   
OBJS=    $(SRCSf:.f=.o) $(SRCSf90:.f90=.o)
CMD=     gefs_climate_anomefi
#OBJS=   $(SRCS:.f90=.o)
#FC=	ifort
#FFLAGS =        -O3 -g -convert big_endian -I $(INC)
#LDFLAGS=

#$(CMD):	$(SRCS)
#	$(FC) $(SRCS) $(FFLAGS) -o $(@) $(OBJS) $(LIBS)

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build a.out.
#

LDFLAGS=

all:    $(CMD)

$(CMD):        $(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(LIBS)
	rm -f $(OBJS)

$(OBJS):        $(SRCS)
	$(FC) $(FFLAGS) -c $(SRCS)

$(OBJS):        makefile

allclean:       clean all

clean:
	-rm -f $(OBJS)

install:
	mv $(CMD) ../../exec/$(CMD)



