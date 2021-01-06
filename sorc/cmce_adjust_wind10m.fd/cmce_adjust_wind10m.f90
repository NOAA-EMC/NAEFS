program cmce_adjust_wind10m_g2
!
! main program: cmce_adjust_wind10m_g2 
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-12-01
!
! abstract: adjust CMC ensemble u10m and v10m for future downscaling process
! 
! usage:
!
!   input file: cmc ensemble forecast                                          
!             : cmc accumulated analysis difference
!
!   output file: cmc adjusted u10m and v10m
!
!   parameters
!     nvar  -      : number of variables
!
! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib reader
!   putgb2           grib writer
!   grid_cnvncep_g2  invert CMC data from north to south
!   init_parm        define grid definition and product definition
!   printinfr        print grib2 data information

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

integer     nmemd,nvar,ivar,i,k,im,imem,n
parameter   (nmemd=21,nvar=2)

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer     ipd1(nvar),ipd2(nvar),ipd10(nvar),ipd11(nvar),ipd12(nvar),ipdn(nvar)

real,       allocatable :: fgrid_im(:)
real,       allocatable :: anl_bias(:)
integer     maxgrd,ndata
integer     index,j,iret,jret             

! variables: u10m v10m

data ipd1 /  2,  2/
data ipd2 /  2,  3/
data ipd10/103,103/
data ipd11/  0,  0/
data ipd12/ 10, 10/

integer     ifdebias
integer     iunit,lfipg(nmemd),lfipg1,icfipg(nmemd),icfipg1
integer     nfiles,iskip(nmemd),tfiles,ifile
integer     lfopg1,icfopg1

character*150 cfipg(nmemd),cfipg1,cfopg1

real    gmax, gmin
integer nbit

namelist /namens/nfiles,ifdebias,iskip,cfipg,cfipg1,cfopg1
 
read (5,namens)
!write (6,namens)

! set the fort.* of intput file, open forecast files

print *, '   '
print *, 'Input files include '

iunit=9

tfiles=nfiles

do ifile=1,nfiles
  iunit=iunit+1
  icfipg(ifile)=iunit
  lfipg(ifile)=len_trim(cfipg(ifile))
  print *, 'fort.',icfipg(ifile), cfipg(ifile)(1:lfipg(ifile))
  call baopenr(icfipg(ifile),cfipg(ifile)(1:lfipg(ifile)),iret)
  if ( iret .ne. 0 ) then
    print *,'there is no CMC forecast, ifile,iret = ',cfipg(ifile)(1:lfipg(ifile)),iret
    tfiles=nfiles-1
    iskip(ifile)=0
  endif
enddo

if(tfiles.eq.0) goto 1020

! set the fort.* of intput NCEP & CMC analysis difference   

iunit=iunit+1
icfipg1=iunit
lfipg1=len_trim(cfipg1)
call baopenr(icfipg1,cfipg1(1:lfipg1),iret)
print *, 'fort.',icfipg1, cfipg1(1:lfipg1)
if(iret.ne.0) then
  print *,'there is no NCEP & CMC analysis difference input, iret=  ',cfipg1(1:lfipg1),iret
endif

! set the fort.* of output file

print *, '   '
print *, 'Output files include '

iunit=iunit+1
icfopg1=iunit
lfopg1=len_trim(cfopg1)
call baopenwa(icfopg1,cfopg1(1:lfopg1),iret)
print *, 'fort.',icfopg1, cfopg1(1:lfopg1)
if(iret.ne.0) then
  print *,'there is no output ',cfopg1(1:lfopg1),iret
endif

! iskip =  1 : ensemble member is from NCEP/GEFS
! iskip = -1 : ensemble member is from CMC/GEFS

! find grib message

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1

do ifile=1,tfiles
  if(iskip(ifile).ne.0) then 
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    if(iret.eq.0) goto 100
  endif       
enddo

100 continue

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1020

maxgrd=gfld%ngrdpts
call gf_free(gfld)

allocate (fgrid_im(maxgrd),anl_bias(maxgrd))

print *, '   '

! loop over variables

anl_bias=0.0

do ivar = 1, nvar  

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1; ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get NCEP & CMC analysis difference 

  ipdtn=1; igdtn=-1
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(icfipg1,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if(iret.eq.0) anl_bias(1:maxgrd)=gfld%fld(1:maxgrd) 
  if(iret.ne.0) anl_bias=0.0

  print *, '   '
  print *, '----- NCEP & CMC Analysis Bias for Current Cycle ------'

  if(iret.eq.0) call printinfr(gfld,ivar)
  if(iret.ne.0) then; print*, 'there is no bias ',jpdt(1),jpdt(2),jpdt(10),jpdt(12);endif

  call gf_free(gfld)

  ! loop over NAEFS members, get operational ensemble forecast

  do imem=1,nfiles 

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1; ipdtn=-1;   igdtn=-1

    ipdt(1)=ipd1(ivar)
    ipdt(2)=ipd2(ivar)
    ipdt(10)=ipd10(ivar)
    ipdt(11)=ipd11(ivar)
    ipdt(12)=ipd12(ivar)

    print *, '   '
    print *, '----- CMC Ensemble Forecast for Member ',imem-1,' ----'
    print *, '   '

    fgrid_im=-9999.9999

    if (iskip(imem).eq.0) goto 200

    ipdtn=1; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg(imem),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

    if(iret.eq.0) call printinfr(gfldo,ivar)
    if(iret.ne.0) then; print*, 'there is no fcst ',jpdt(1),jpdt(2),jpdt(10),jpdt(12);endif

    ! start CMC data processing, invert & remove initial analyis difference between NCEP and CMC

    if (iret.eq.0) then

      call grid_cnvncep_g2(gfldo,ivar)

      fgrid_im(1:maxgrd)=gfldo%fld(1:maxgrd)

      ! adjust CMC ensemble forecast

      call debias(anl_bias,fgrid_im,maxgrd)

      print *, '----- After Debias CMC Forecast for Current Time ------'

      !  adjust the cmc ensmeble message for future combination

      gfldo%ipdtmpl(17)=20+gfldo%ipdtmpl(17)

      ! get the number of bits
      ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

      call gtbits(0,gfldo%idrtmpl(3),maxgrd,0,fgrid_im,gmin,gmax,nbit)
      gfldo%fld(1:maxgrd)=fgrid_im(1:maxgrd)

      ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

      ! gfldo%idrtmpl(3)=1

      call putgb2(icfopg1,gfldo,iret)
      call printinfr(gfldo,ivar)
      call gf_free(gfldo)

    endif      ! end of iret equal to 0

    200 continue

  enddo          ! end of imem loop

enddo

! end of ivar loop                                      

! close files

do ifile=1,nfiles
  call baclose(icfipg(ifile),iret)
enddo

call baclose(icfipg1,iret)

call baclose(icfopg1,iret)

print *,'   '
print *,'CMC U10m & V10m Adjustment Process Successfully Complete'

stop

1020  continue
print *, ' There is no CMC pgb file !!! '
stop

end


subroutine debias(bias,fgrid,maxgrd)

!   adjust cmc forecast            
!
!   input
!         fgrid   ---> ensemble forecast
!         bias    ---> bias estimation
!         maxgrid ---> number of grid points in the defined grid
!
!   output 
!         fgrid  ---> adjusted ensemble forecast

implicit none

integer maxgrd,ij
real bias(maxgrd),fgrid(maxgrd)

do ij=1,maxgrd
  if(fgrid(ij).gt.-9999.0.and.fgrid(ij).lt.999999.0.and.bias(ij).gt.-9999.0.and.bias(ij).lt.999999.0) then
    fgrid(ij)=fgrid(ij)-bias(ij)
  else
    fgrid(ij)=fgrid(ij)
  endif
enddo

return
end

