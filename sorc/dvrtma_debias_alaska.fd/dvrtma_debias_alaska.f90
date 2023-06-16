program dvrtma_debias_conus_g2   
!
! main program: dvrtma_debias_conus_g2    
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-03-01
!
! abstract: downscale forecast by removing downscaling vector from it 
!           add 2m dew point temperature and 2m relative humidity
!
! usage:
!
!   input file: grib
!     unit 11 -    : downscaling vector                                                 
!     unit 12 -    : ensemble forecast
!
!   output file: grib
!     unit 51 -    : downscaled forecast  
!
!   parameters
!     gfld  -      : forecast
!     bias  -      : downscaling vector
!     nvar  -      : number of variables

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib2 reader
!   putgb2           grib2 writer
!   init_parm        define grid definition and product definition
!   printinfr        print grib2 data information
!   getbits          comput number of bits and round field

! exit states:
!   cond =   0 - successful run
!   cond =   1 - I/O abort
!
! attributes:
!   language: fortran 90
!
!$$$

use grib_mod
use params

implicit none

integer     nvar,ivar,i,icstart,ij
parameter   (nvar=4)

real,       allocatable :: fgrid(:),bias(:),t2m(:)

integer     ifile,cfile,ofile

integer     ipd1(nvar),ipd2(nvar),ipd10(nvar),ipd11(nvar),ipd12(nvar)

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

! variables: pres  t2m dpt2m rh2m

data ipd1 /  3,  0,  1,  0/
data ipd2 /  0,  0,  1,  6/
data ipd10/  1,103,103,103/
data ipd11/  0,  0,  0,  0/
data ipd12/  0,  2,  2,  2/

integer     maxgrd,length
integer     index,j,n,iret,jret             
character*7 cfortnn
character*120 cbias,cfcst,oprod

real    gmax, gmin
integer nbit

namelist/message/icstart,cbias,cfcst,oprod

read(5,message,end=1020)
write(6,message)

ifile=11
cfile=12
ofile=51

! set the fort.* of intput files

if(icstart.eq.0) then
  length=len_trim(cbias)
  call baopenr(ifile,cbias(1:length),iret)
  if (iret.ne.0) then; print*,'there is no rtma downscaling vector'; endif
endif

length=len_trim(cfcst)
call baopenr(cfile,cfcst(1:length),iret)
if (iret.ne.0) then; print*,'there is no forecast, stop!'; endif
if (iret.ne.0) goto 1020 

! set the fort.* of output file

length=len_trim(oprod)
call baopenw(ofile,oprod(1:length),iret)
if (iret.ne.0) then; print*,'there is no downscaled output, stop!'; endif
if (iret.ne.0) goto 1020

! find grib message

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1020

call gf_free(gfld)
maxgrd=gfld%ngrdpts

allocate (fgrid(maxgrd),bias(maxgrd),t2m(maxgrd))

do ivar = 1, nvar

  ! read and process variable of input data

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized downscaling vector
  ! downscaling vector has product template 4.1
  ! ipdt(3)=7 (analysis error from code table 4.3)

  if(icstart.eq.1) then
    print *, '----- Cold Start for Bias Correction -----'
    bias=0.0
  else
    print *, '----- Initialized Bias for Current Time -----'

    ipdtn=1; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) bias=0.0 
    if (iret.eq.0) bias(1:maxgrd)=gfld%fld(1:maxgrd)
    if (iret.eq.0) call printinfr(gfld,ivar)

  endif
 
  call gf_free(gfld)

  ! get operational forecast 
  ! NCEP GEFS/NAEFS probability forecast has product template 4.2/4.12
  ! ipdt(3)=4 (ensemble forecast from code table 4.3)

  print *, '----- Operational Forecast for Current Time ------'

  ipdtn=2; igdtn=-1
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if (iret.ne.0) print*, 'there is no fcst', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
  if (iret.ne.0) goto 100

  if (iret.eq.0) call printinfr(gfldo,ivar)
  if (iret.eq.0) fgrid(1:maxgrd)=gfldo%fld(1:maxgrd)

  ! apply downscaling approach

  call debias(bias,fgrid,maxgrd)

  ! save the downscaled output

  gfldo%fld(1:maxgrd)=fgrid(1:maxgrd)

! save t2m to adjust the downscaled dpt2m

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) t2m=fgrid

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then

    print*, 'Before Adjusted DPT2m Forecast '; print *, ' '
    call printinfr(gfldo,ivar)

    do ij=1,maxgrd
      fgrid(ij)=min(fgrid(ij),t2m(ij))
    enddo

    gfldo%fld(1:maxgrd)=fgrid(1:maxgrd)

    print*, 'After Adjusted DPT2m Forecast '; print *, ' '
    call printinfr(gfldo,ivar)

  endif

  ! adjust relative humility, two ends are bounded (0,100)

  if(ipd1(ivar).eq.1.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then

    print*, 'Before Adjusted RH Forecast '; print *, ' '
    call printinfr(gfldo,ivar)

    do ij=1,maxgrd
      if(fgrid(ij).lt.0.0) fgrid(ij)=0.0
      if(fgrid(ij).gt.100.0) fgrid(ij)=100.0
    enddo

    gfldo%fld(1:maxgrd)=fgrid(1:maxgrd)

    print*, 'After Adjusted RH Forecast '; print *, ' '
    call printinfr(gfldo,ivar)

  endif

  ! get the number of bits
  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

! write(6,*) 'gfldo%idrtmpl(3)=',gfldo%idrtmpl(3)

  call gtbits(0,gfldo%idrtmpl(3),maxgrd,0,fgrid,gmin,gmax,nbit)
  gfldo%fld(1:maxgrd)=fgrid(1:maxgrd)

! gfldo%idrtmpl(4) : GRIB2 DRT 5.40 number of bits

  gfldo%idrtmpl(4)=nbit

  print *, '----- Output Downscaled Forecast -----'

  call putgb2(ofile,gfldo,iret)
  call printinfr(gfldo,ivar)

! end of downscaling process for one forecast lead time

100 continue

  call gf_free(gfld)
  call gf_free(gfldo)

enddo

call baclose(ifile,iret)
call baclose(cfile,iret)
call baclose(ofile,iret)

print *,'Downscaling Process Successfully Complete'

stop

1020  continue

print *,'Wrong Data Input, Output or Wrong Message Input'

stop
end

subroutine debias(bias,fgrid,maxgrd)

!   apply the downscaling process    
!
!   input
!         fgrid   ---> ensemble forecast
!         bias    ---> downscaling vector
!         maxgrid ---> number of grid points in the defined grid
!
!   output
!         fgrid  ---> downscaled ensemble forecast

implicit none

integer maxgrd,ij
real bias(maxgrd),fgrid(maxgrd)

do ij=1,maxgrd
  if(fgrid(ij).gt.-999.0.and.fgrid(ij).lt.999999.0.and.bias(ij).gt.-999.0.and.bias(ij).lt.999999.0) then
    fgrid(ij)=fgrid(ij)-bias(ij)
  else
    fgrid(ij)=fgrid(ij)
  endif
enddo

return
end

