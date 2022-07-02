SHELL=	/bin/bash
#INC= /nwprod/lib/incmod/g2_4
#LIBS= -L/nwprod/lib -lg2_4 -lw3nco_4 -lbacio_4 \
	#-ljasper -lpng -lz
SRCS=	anomaly_mod.f90 gefs_climate_anomaly.f90 CDFNOR.f90 printinfr.f90 \
        init_parm.f90 grib_cnvfnmoc.f90 change_template4.f90    
OBJS=   $(SRCS:.f90=.o)
CMD=	gefs_climate_anomaly
#FC=	ifort
#FFLAGS =        -O3 -g -convert big_endian -I $(INC)
LDFLAGS=

#$(CMD):	$(SRCS)
#	$(FC) $(SRCS) $(FFLAGS) -o $(@) $(OBJS) $(LIBS)

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build a.out.
#
all:    $(CMD)

$(CMD):		$(OBJS)
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



