SHELL=	/bin/bash
#LIBS    = -L/nwprod/lib -lip_4 -lsp_4 -lbacio_4 -lw3nco_4
#LIBS= -L/nwprod/lib -lg2_4 -lw3nco_4 -lbacio_4 \
        -ljasper -lpng -lz

#LIBS    = -L/gpfs/hps/nco/ops/nwprod/lib 
SRCSf90= gefs_climate_anfefi_acpr.f90 INIT_PARM.f90 PRINTINFR.f90 grib_cnvfnmoc.f90 change_template4.f90
SRCSf=   probability.f quastn.f quagam.f pelgam.f sort.f samlmr.f dlgama.f gamind.f cdfgam.f
SRCS=    $(SRCSf90) $(SRCSf)
OBJS=    $(SRCSf:.f=.o) $(SRCSf90:.f90=.o)
CMD=     gefs_climate_anfefi_acpr
#ftn=iford

#FFLAGS=	-O3 -qsuffix=f=f90 -qlist -qsource -qlanglvl=90PURE -bnoquiet 
#FFLAGS=	-O3 -qsuffix=f=f90 -qlist -qsource -bnoquiet 
#LDFLAGS=

#all:    $(CMD)

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
