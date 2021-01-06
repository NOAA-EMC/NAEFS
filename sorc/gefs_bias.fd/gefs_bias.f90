program gefs_bias_g2     
!
! main program: gefs_bias_g2       
!
! prgmmr: Bo Cui           org: np/wx20        date: 2006-12-10
!                          mod np/wx20         date: 2008-01-25
!                          mod np/wx20         date: 2009-04_01
!                          mod np/wx20         date: 2011-04_01
!                          mod: Bo.Cui         date: 2015-06-01
!
! abstract: 1. update bias estimation between GDAS analysis and NCEP ensemble forecast 
!              add bias estimation calculation between NCEP and CMC analysis (CMC - NCEP)
!           2. add more variables for bias estimation (+14)
!           3. add variable ULWRF(OLR). ULWRF(OLR) is 6hr average value and ULWRF(OLR) at GEFS control
!              f00hr is almost instantaneous value. Therefore, choose 6hr forecast of previous cycle as
!              the ULWRF(OLR) analysis
!           4. add variable 2m dew point temperature and relative humility, calculate & output bias
!              calculate dew point temperature forecast from relative humidity and 2m temperature
!              then calculate the bias of 2m dew point temperature, 52 variables in total for bias estimation
!              51 variables for reanalysis difference (no 2m dpt)
!              49 variables for NCEP CMC analysis difference (no tmax,tmin and vvel)

! modification: add new variable TCDC (total cloud cover), 6 hour average
!              
! usage:
!
!   input file: grib
!     unit 11 -    : prior bias estimation                                               
!     unit 12 -    : analysis
!     unit 13 -    : analysis for Tmax, Tmin and ULWRF
!     unit 14 -    : ncep operational forecast or CDAS reanalysis
!     unit 15 -    : CFS reanalysis for variable tmax, tmin, ulwrf(surface) and ulwrf(top)
!
!   output file: grib
!     unit 51 -    : updated bias estimation pgrba file
!
!   parameters
!     fgrid -      : ensemble forecast
!     agrid -      : analysis data (GDAS)
!     rgrid -      : reanalysis data (CDAS)
!     bias  -      : bias estimation
!     dec_w -      : decay averaging weight 
!     nvar  -      : number of variables

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib2 reader
!   putgb2           grib2 writer
!   init_parm        define grid definition and product definition
!   printinfr        print grib2 data information
!
! attributes:
!   language: fortran 90
!
!$$$

use grib_mod
use params
use naefs_mod

implicit none

integer      ivar,i,k,icstart,odate,ij
!parameter   (nvar=52)

real,       allocatable :: agrid(:),fgrid(:),bias(:),rgrid(:)
real,       allocatable :: rh2m(:),tmp2m(:)
real,       allocatable :: anl_ncep(:),anl_cmc(:)

real        dec_w

integer     ifile,afile,afile_m06,cfile,rfile,rfile_m06,rfile_m12,ofile

integer     maxgrd,ndata,index,j,n,iret,jret             
integer     ipd11_new(nvar),ipd12_new(nvar)              
integer     ipd11_cfs(nvar),ipd12_cfs(nvar)              

character*7 cfortnn
character*4 nens

namelist/message/icstart,nens,dec_w,odate

read(5,message,end=1020)
write(6,message)

if(nens.ne.'mdf'.and.nens.ne.'anl') then

ifile=11
afile=12
afile_m06=13
cfile=14
ofile=51

! set the fort.* of intput files

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data, stop!'; endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',afile_m06
call baopenr(afile_m06,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data for Tmax and Tmin, stop!'; endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',cfile
call baopenr(cfile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no NCEP forecast data, stop!'; endif
if (iret .ne. 0) goto 1020

if(icstart.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ifile
  call baopenr(ifile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no bias estimation data, please check!'; endif
endif

! set the fort.* of output file

write(cfortnn,'(a5,i2)') 'fort.',ofile
call baopenw(ofile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no output bias data, stop!'; endif
if (iret .ne. 0) goto 1020

! find grib message, maxgrd: number of grid points in the defined grid

ipdt=-9999; igdt=-9999
ipdtn=-1; igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
maxgrd=gfld%ngrdpts
call gf_free(gfld)

if (iret .ne. 0) then; print*,' getgbeh ,afile,index,iret =',afile,index,iret; endif
if (iret .ne. 0) goto 1020

! get NCEP ensemble ipdt message: fixed surface and its scaled value

call getipdt_g2_surface(cfile,ipd11_new,ipd12_new)

ipd11=ipd11_new
ipd12=ipd12_new

allocate (agrid(maxgrd),fgrid(maxgrd),bias(maxgrd))
allocate (rh2m(maxgrd),tmp2m(maxgrd))

do ivar = 1, nvar  

  bias=0.0            
  agrid=-9999.9999
  fgrid=-9999.9999

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized bias estimation

  if(icstart.eq.1) then
    print *, '----- Cold Start for Bias Estimation -----'
    print*, '  '
    bias=0.0
  else
    print *, '----- Initialized Bias for Current Time -----'

    igdtn=-1
    if(nens.eq.'gfs') ipdtn=ipdn(ivar)
    if(nens.eq.'avg') ipdtn=ipdnm(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if(iret.ne.0) then
      print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if(iret .eq. 0) then    
      bias(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      bias=0.0
    endif
  endif

  ! get ensemble forecast

  print *, '----- NCEP ensemble forecast for current Time ------'

  ! ipdn for GFS forecast; ipdnm for ensemble average forecast

  igdtn=-1
  if(nens.eq.'gfs') ipdtn=ipdn(ivar)
  if(nens.eq.'avg') ipdtn=ipdnm(ivar)

  call init_parm(ipdtn,ipdt,igdtn,igdt)
  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte GEFS Dew Point Temperature Forecast '; print *, ' '
    call get_dpt_g2(cfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
    print *, ' '
  elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
    print *, ' '
    print*, 'Start to Calcualte GEFS 10m Wind Speed '; print *, ' '
    call get_wspd10m(cfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  else
    call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif

  if(iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    print *, ' '
    call gf_free(gfld)
  endif
     
  if(iret.ne.0) goto 100

  if(iret.eq.0) then
    call printinfr(gfldo,ivar)
    fgrid(1:maxgrd)=gfldo%fld(1:maxgrd)
  endif

  ! get analysis data

  print *, '----- Analysis for Current Time ------'

  igdtn=-1; ipdtn=ipdn(ivar)

  call init_parm(ipdtn,ipdt,igdtn,igdt)

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte GEFS Dew Point Temperature Analysis '; print *, ' '
    call get_dpt_g2(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
    print *, ' '
    print*, 'Start to Calcualte GEFS 10m Wind Speed Analysis '; print *, ' '
    call get_wspd10m(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.1.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.8.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.6.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.10.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  else
    call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  endif

  if(iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    print *, ' '
    call gf_free(gfld)
    bias(1:maxgrd)=0.0                           
  endif

! if(iret.ne.0) goto 200
  if(iret.ne.0) goto 100

  if(iret.eq.0) then
    call printinfr(gfld,ivar)
    agrid(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  call gf_free(gfld)

  ! apply the decay average

  call decay(bias,fgrid,agrid,maxgrd,dec_w)

  ! save the first moment bias, give the bias a time one day before

  200 continue

  ! output bias estimation

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)

  print *, '----- Output Bias Estimation for Current Time ------'

  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

  if(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.5) then
    continue
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.1) then
    gfldo%idrtmpl(3)=2
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.0) then
    gfldo%idrtmpl(3)=2
  else
    gfldo%idrtmpl(3)=2
  endif

  gfldo%ipdtmpl(3)=6                !  gfldo%ipdtmpl(3)=6 GRIB2 Code Table 4.3 forecast error

  call putgb2(ofile,gfldo,jret)
  call printinfr(gfldo,ivar)

  call gf_free(gfldo)

  100 continue

! end of bias estimation 

enddo

call baclose(ifile,iret)
call baclose(afile,iret)
call baclose(afile_m06,iret)
call baclose(cfile,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Successfully Complete'

endif

if(nens.eq.'mdf') then

ifile=11
afile=12
afile_m06=13
rfile=14
rfile_m06=15
ofile=51

! set the fort.* of intput files

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data, stop!';  endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',afile_m06
call baopenr(afile_m06,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data for Tmax and Tmin, stop!'; endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',rfile
call baopenr(rfile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no reanalysis data, stop!'; endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',rfile_m06
call baopenr(rfile_m06,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no reanalysis data for surface variables, stop!'; endif
if (iret .ne. 0) goto 1020

if(icstart.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ifile
  call baopenr(ifile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no bias between CDAS and GDAS, please check!'; endif
endif

! set the fort.* of output file

write(cfortnn,'(a5,i2)') 'fort.',ofile
call baopenw(ofile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no output bias data, stop!'; endif
if (iret .ne. 0) goto 1020

! find grib message, maxgrd: number of grid points in the defined grid

ipdt=-9999; igdt=-9999
ipdtn=-1; igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
maxgrd=gfld%ngrdpts
call gf_free(gfld)

if (iret .ne. 0) then; print*,' getgbeh ,afile,index,iret =',afile,index,iret; endif
if (iret .ne. 0) goto 1020

! get NCEP analysis ipdt message: fixed surface and its scaled value

call getipdt_g2_surface(afile,ipd11_new,ipd12_new)

print*,' ipd11_new,ipd12_new=',ipd11_new,ipd12_new

ipd11=ipd11_new
ipd12=ipd12_new

! get CFS analysis ipdt message: fixed surface and its scaled value

call getipdt_g2_surface(rfile,ipd11_new,ipd12_new)

ipd11_cfs=ipd11_new
ipd12_cfs=ipd12_new

print*,' ipd11_new,ipd12_new=',ipd11_new,ipd12_new

allocate (agrid(maxgrd),rgrid(maxgrd),bias(maxgrd))

do ivar = 1, nvar  

  bias=0.0             
  agrid=-9999.9999
  rgrid=-9999.9999

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdtn=ipdn(ivar)
  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized bias estimation between CDAS and GDAS

  if(icstart.eq.1) then
    print *, '----- Cold Start for Bias Estimation between CDAS and GDAS -----'
    print*, '  '
    bias=0.0
  else
    print *, '----- Initialized Bias for Current Time -----'

    igdtn=-1
    ipdtn=ipdnr(ivar)
!   ipdtn=ipdn(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    if (iret .eq. 0) then
      bias(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      bias=0.0
    endif

  endif

  ! get analysis data GDAS

  print *, '----- Analysis for Current Time ------'

  igdtn=-1
  ipdtn=ipdn(ivar) 
  call init_parm(ipdtn,ipdt,igdtn,igdt)

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte GEFS Dew Point Temperature Analysis '; print *, ' '
    call get_dpt_g2(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
    print *, ' '
    print*, 'Start to Calcualte GEFS 10m Wind Speed Analysis '; print *, ' '
    call get_wspd10m(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.1.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.8.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  else
    call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfld)
  endif

  if (iret.ne.0) goto 300
  if (iret.eq.0) then
    call printinfr(gfld,ivar)
    agrid(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  call gf_free(gfld)

  ! get CFS reanalysis data CDAS  

  igdtn=-1
  ipdtn=ipdnr(ivar) 
  ipdt(11)=ipd11_cfs(ivar)
  ipdt(12)=ipd12_cfs(ivar)
  call init_parm(ipdtn,ipdt,igdtn,igdt)

  print *, '----- CDAS reanalysis for current Time ------'

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte CDAS Dew Point Temperature Forecast '; print *, ' '
    call get_dpt_g2(rfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
    print *, ' '
    print*, 'Start to Calcualte CFS 10m Wind Speed Analysis '; print *, ' '
    call get_wspd10m(rfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    call getgb2(rfile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    call getgb2(rfile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.1.and.ipd12(ivar).eq.0) then
    call getgb2(rfile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.8.and.ipd12(ivar).eq.0) then
    call getgb2(rfile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  else
    call getgb2(rfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
  endif

  if (iret.ne.0) goto 300
  if (iret.eq.0) then
    call printinfr(gfldo,ivar)
    rgrid(1:maxgrd)=gfldo%fld(1:maxgrd)
  endif

  ! apply the decay average

  call decay(bias,rgrid,agrid,maxgrd,dec_w)

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)

  print *, '----- Output Bias Estimation between CDAS and GDAS ------'

  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

  if(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.5) then
    continue
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.1) then
    gfldo%idrtmpl(3)=2
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.0) then
    gfldo%idrtmpl(3)=2
  else
    gfldo%idrtmpl(3)=2
  endif

  gfldo%ipdtmpl(3)=7                !  gfldo%ipdtmpl(3)=7 GRIB2 Code Table 4.3 analysis error

  call putgb2(ofile,gfldo,iret)
  call printinfr(gfldo,ivar)

  call gf_free(gfldo)

  300 continue

! end of bias estimation between CDAS and GDAS 

enddo

call baclose(ifile,iret)
call baclose(afile,iret)
call baclose(afile_m06,iret)
call baclose(rfile,iret)
call baclose(rfile_m06,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Between CDAS and GDAS Successfully Complete'

endif

if(nens.eq.'anl') then

ifile=11
afile=12
afile_m06=13
rfile=14
rfile_m12=15
ofile=51

! set the fort.* of intput files

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no NCEP analysis data, stop!';  endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',afile_m06
call baopenr(afile_m06,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no NCEP analysis for  ULWRF!';  endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',rfile
call baopenr(rfile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no CMC analysis data, stop!'; endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',rfile_m12
call baopenr(rfile_m12,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no CMC analysis for ULWRF, stop!'; endif
!if (iret .ne. 0) goto 1020

if(icstart.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ifile
  call baopenr(ifile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no bias between CMC and NCEP analysis, please check!'; endif
endif

! set the fort.* of output file

write(cfortnn,'(a5,i2)') 'fort.',ofile
call baopenw(ofile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no output bias data, stop!'; endif
if (iret .ne. 0) goto 1020

! find grib message, maxgrd: number of grid points in the defined grid

ipdt=-9999; igdt=-9999
ipdtn=-1; igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
maxgrd=gfld%ngrdpts
call gf_free(gfld)

if (iret .ne. 0) then; print*,' getgbeh ,afile,index,iret =',afile,index,iret; endif
if (iret .ne. 0) goto 1020

! get NCEP analysis ipdt message: fixed surface and its scaled value

call getipdt_g2_surface(afile,ipd11_new,ipd12_new)

ipd11=ipd11_new
ipd12=ipd12_new

! get CMC analysis ipdt message: fixed surface and its scaled value

call getipdt_g2_surface(rfile,ipd11_new,ipd12_new)

ipd11_cmc=ipd11_new
ipd12_cmc=ipd12_new

allocate (anl_ncep(maxgrd),anl_cmc(maxgrd),bias(maxgrd))
allocate (tmp2m(maxgrd),rh2m(maxgrd))

do ivar = 1, nvar  

  bias=0.0             
  anl_cmc=-9999.9999
  anl_ncep=-9999.9999

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized bias estimation between NCEP and CMC analysis

  if(icstart.eq.1) then
    print *, '----- Cold Start for Bias Estimation between NCEP and CMC analysis -----'
    print*, '  '
    bias=0.0
  else

    print *, '----- Initialized Bias for Current Time -----'

    igdtn=-1
    ipdtn=ipdn(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) then
      print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if (iret .eq. 0) then
      bias(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      bias=0.0
    endif

  endif

  ! get NCEP analysis data GDAS

  igdtn=-1; ipdtn=ipdn(ivar)
  call init_parm(ipdtn,ipdt,igdtn,igdt)

  ! there are no Tmax and Tmin

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 500
  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 500

  print *, '----- NCEP Analysis for Current Cycle ------'

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte NCEP Dew Point Temperature Analysis '; print *, ' '
    call get_dpt_g2(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
    print *, ' '
    print*, 'Start to Calcualte GEFS 10m Wind Speed '; print *, ' '
    call get_wspd10m(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.1.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.8.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  else
    call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
  endif

  if (iret.ne.0) goto 500

  if (iret.eq.0) then
    call printinfr(gfldo,ivar)
    anl_ncep(1:maxgrd)=gfldo%fld(1:maxgrd)
  endif

  ! get CMC analysis data
  ! there is no two ULWRF(surface/top) and VVEL(850mb) for analysis, get from ens average
  ! ULWRF(surface): PRODUCT TEMPLATE 4. 12 :  5 193 4 0 70 0 0 11 1 1 0 0 
  ! ULWRF(top):     PRODUCT TEMPLATE 4. 12 :  5 193 4 0 70 0 0 11 1 8 0 0

  ipdt(11)=ipd11_cmc(ivar)
  ipdt(12)=ipd12_cmc(ivar)

  igdtn=-1; ipdtn=ipdn(ivar)
  call init_parm(ipdtn,ipdt,igdtn,igdt)

  print *, '----- CMC Analysis for Current Cycle ------'

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte CMC Dew Point Temperature Analysis '; print *, ' '
    call get_dpt_g2(rfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
    print *, ' '
    print*, 'Start to Calcualte CMC 10m Wind Speed '; print *, ' '
    call get_wspd10m(rfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.1.and.ipd12(ivar).eq.0) then
    ipdtn=12
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(rfile_m12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.8.and.ipd12(ivar).eq.0) then
    ipdtn=12
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(rfile_m12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.6.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.10.and.ipd12(ivar).eq.0) then
    print *, ' '
    print*, 'Start to get CMC TCDC Analysis '; print *, ' '
    ipdtn=1 
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(rfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  else
    call getgb2(rfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfld)
  endif

  if (iret.ne.0) goto 500

  if (iret.eq.0) then
    call grid_cnvncep_g2(gfld,ivar)
    anl_cmc(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  call gf_free(gfld)

  ! apply the decay average

  call decay(bias,anl_cmc,anl_ncep,maxgrd,dec_w)

  print *, '----- Output Bias Estimation between CMC and NCEP analysis ------'

  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

  if(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.5) then
    continue
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.1) then
    gfldo%idrtmpl(3)=2
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.0) then
    gfldo%idrtmpl(3)=2
  else
    gfldo%idrtmpl(3)=2
  endif

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)

  gfldo%ipdtmpl(3)=7                !  gfldo%ipdtmpl(3)=7 GRIB2 Code Table 4.3 analysis error

  call putgb2(ofile,gfldo,jret)

  call printinfr(gfldo,ivar)

  call gf_free(gfldo)

  500 continue

! end of bias estimation between CMC and NCEP analysis

enddo

call baclose(ifile,iret)
call baclose(afile,iret)
call baclose(afile_m06,iret)
call baclose(rfile,iret)
call baclose(rfile_m06,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Between CMC and NCEP Analysis Successfully Complete'

endif
stop

1020  continue

stop
end

subroutine decay(aveeror,fgrid,agrid,maxgrd,dec_w)

! apply the decaying average scheme
!
!     input      
!            fgrid  ---> ensemble forecast
!            agrid  ---> analysis data
!            aveeror---> bias estimation
!            dec_w  ---> decay weight
!
!     output
!            aveeror---> updated bias estimation

implicit none

integer maxgrd,ij
real aveeror(maxgrd),fgrid(maxgrd),agrid(maxgrd)
real dec_w           

do ij=1,maxgrd
  if(fgrid(ij).gt.-99999.0.and.fgrid(ij).lt.999999.0.and.agrid(ij).gt.-99999.0.and.agrid(ij).lt.999999.0) then
      if(aveeror(ij).gt.-99999.0.and.aveeror(ij).lt.999999.0) then
        aveeror(ij)= (1-dec_w)*aveeror(ij)+dec_w*(fgrid(ij)-agrid(ij))
      else
        aveeror(ij)= dec_w*(fgrid(ij)-agrid(ij))
      endif
  else
    if(aveeror(ij).gt.-99999.0 .and.aveeror(ij).lt.999999.0) then
      aveeror(ij)= aveeror(ij)                   
    else
      aveeror(ij)= 0.0                                
    endif
  endif
enddo

return
end


subroutine cal_dewpt(dpt,tmp,rhp,maxgrd)

! calculate dew point temperature 
!
!    Compute Dew Point Temperature (Bolton 1980)
!    es = 6.112 * exp((17.67 * T)/(T + 243.5));
!    e = es * (RH/100.0);
!    Td = log(e/6.112)*243.5/(17.67-log(e/6.112));

!         where:
!           T = temperature in deg C;
!           es = saturation vapor pressure in mb;
!           e = vapor pressure in mb;
!           RH = Relative Humidity in percent;
!           Td = dew point in deg C 
!
!     parameters
!
!        input
!                  tmp  ---> temperature                   
!                  rhp  ---> relative humidity 
!
!        output
!                  dpt  ---> dew point temperature                   

implicit none

integer maxgrd,ij
real dpt(maxgrd),tmp(maxgrd),rhp(maxgrd)
real T,Td,es,e,RH

do ij=1,maxgrd
  T=tmp(ij)-273.15
  RH=rhp(ij)  
  if(RH.eq.0) then
    print *,'RH 0 value',ij,RH,e,Td,dpt(ij)
    if(ij.eq.1) then
      if(rhp(ij+1).ne.0.0) then
        RH=rhp(ij+1)
      else
        RH=0.5
      endif
    elseif(ij.eq.maxgrd) then
      if(rhp(ij-1).ne.0.0) then
        RH=rhp(ij-1)
      else
        RH=0.5
      endif
    else
      if(rhp(ij-1).ne.0.0.and.rhp(ij+1).ne.0.0) then
        RH=(rhp(ij+1)+rhp(ij-1))/2.0
      else
        RH=0.5
      endif
    endif
  endif
  es=6.112 * exp((17.67 * T)/(T + 243.5))
  e=es*(RH/100.0)
  Td=log(e/6.112)*243.5/(17.67-log(e/6.112))+273.15
  dpt(ij)=min(T+273.15,Td)                 
enddo
 
return 
end
