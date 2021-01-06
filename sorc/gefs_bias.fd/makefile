SHELL=	/bin/bash
#INC= /nwprod/lib/incmod/g2_4
#LIBS= -L/nwprod/lib -lg2_4 -lw3nco_4 -lbacio_4 \
	#-ljasper -lpng -lz
SRCS=	naefs_mod.f90 gefs_bias.f90 get_dpt.f90 printinfr.f90 \
        init_parm.f90 grid_cnvncep.f90 getipdt_surface.f90 get_wspd10m.f90
OBJS=   $(SRCS:.f90=.o)
CMD=	gefs_bias
#FC=	ifort
#FFLAGS =        -O3 -g -convert big_endian -I $(INC)
LDFLAGS=

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


