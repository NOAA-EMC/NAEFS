program cmcens_post_prcp
!
! main program: cmcens_post            
!
! prgmmr: Bo Cui           org: np/wx20        date: 2016-10-01
!
! abstract: read in CMC ensemble forecast (one member at one forecast) and output
!           pgrb2a format, converts 6-hourly CMC total precipitation accumulations
!           to 6 hour accumulations
!
! modifications:
!          1. no need to calculate relative humidity rh
!          2  add 10m u and 10m v for enspost file
!          3. 79 variables for pgrba forecasts, 58 variables for analysis, 66 variables fro 00hr forecasts
!             add 15 new variables in pgrba: tmp, h, u, v and rh on 10, 50, 100mb
!             add 13 new variables in pgrba:
!             vvel,soilw,weasd,snod,lhtfl,shtfl,dswrf,dlwrf,uswrf,ulwrf(surface),ulwrf(olr),cin,tmp(0-10cm down)
!          4. read in 7 accumulated flux variables from previous 6hr and calculate 6hr averaged flux
!          5. variable tcdc: total cloud cover at atmospheric column [%], for NCEP GEFS, it is 6hr average
!             for CMC GEFS, it is intantaneous variable and no need to do 6hr average calculation
!
! attention:
!            there is no the following variables in CMC analysis
!            arain(223),asnow (224),afrzr(225),aicep(226)
!            cape(157 1 0), tmax(15 105 2),tmin(16 105 2),apcp(61 1 0),  vvel(39 100 850),soilw(144 112 10)
!            weasd(65 1 0), snod(66 1 0),  lhtfl(121 1 0),shtfl(122 1 0),dswrf(204 1 0),  dlwrf(205 1 0)
!            uswrf(211 1 0),ulwrf(212 1 0),ulwrf(212 8 0),cin(156 1 0),  tmp(11 112 10)
!            there is no the following variables in CMC 00hr forecast
!            arain(223),asnow (224),afrzr(225),aicep(226)
!            tmax(15 105 2),tmin(16 105 2),apcp(61 1 0)
!            lhtfl(121 1 0),shtfl(122 1 0),dswrf(204 1 0),dlwrf(205 1 0)
!            uswrf(211 1 0),ulwrf(212 1 0),ulwrf(212 8 0)
!
!            The set of pds(16) of CMC is different from NCEP GEFS

!            1. cmc analysis : pds(16)=1 for all variables
!               1: Initialized analysis product for reference time (P1=0, pds(14)=0)
!            2. cmc ensmeble forecast at 00hr: pds(16)=1 for all variables

!            3. cmc ensmeble forecasts except 00hr
!
!               for forecast hour <  258

!               (a) pds(13)=11, pds(16)=4
!                   for apcp,  Accumulation,
!                   reference time + P1 to reference time + P2, product considered valid at reference time + P2
!               (b) pds(13)=11, pds(16)=3
!                   for lhtfl,shtfl,dswrf,dlwrf,uswrf,ulwrf(surface),ulwrf(olr),crain,cfrzr,cicep,csnow
!               (c) pds(13)=11, pds(16)=2
!                   for tmax,tmin (Product with a valid time ranging between reference time + P1 and P2)
!               (d) pds(13)=1, pds(16)=0  for all the other variables
!                   pds(16)=0: Forecast product valid for reference time + P1 (P1>0,pds(14)>0)
!                   (NCEP GEFS forecas have pds(16)=10 for all forecast hours except variables in a and b)

!               for forecast hour >= 258

!               (a) pds(13)=11, pds(16)=4
!                   for apcp,  Accumulation,
!                   reference time + P1 to reference time + P2, product considered valid at reference time + P2
!               (b) pds(13)=11, pds(16)=3
!                   for lhtfl,shtfl,dswrf,dlwrf,uswrf,ulwrf(surface),ulwrf(olr),crain,cfrzr,cicep,csnow
!               (c) pds(13)=11, pds(16)=2
!                   for tmax,tmin (Product with a valid time ranging between reference time + P1 and P2)
!               (d) pds(13)=1, pds(16)=10  for all the other variables
!                   pds(16)=10: value of 10 allows the period of a forecast to be extended over two octets
!                   this accommodates extended range forecasts, product valid at reference time + P1
!
! some variable messages:
!                         arain:CNWAT, 223 Rain Precipitation Rate kg/m2/s RPRATE
!                         asnow,SOTYP, 224 Snow Precipitation Rate kg/m2/s SPRATE
!                         afrzr,VGTYP, 225 Freezing Rain Precipitation Rate kg/m2/s FPRATE
!                         aicep,BMIXL, 226 Ice Pellets Precipitation Rate kg/m2/s IPRATE
!
! 
! usage:
!
!   input file: CMC raw ensembel forecast                  

!   output file: Prcp estimation and averaged flux

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib reader
!   putgb2           grib writer
!   init_parm        define grid definition and product definition
!   printinfr        print grib2 data information

! exit states:
!   cond =   0 - successful run
!   cond =   1 - I/O abort
!
! attributes:
!   language: fortran 90
!
! notes:
!       1. there are 72 variables for 000hr files, 83 for 003hr and 85 for later
!$$$

use grib_mod
use params

implicit none

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: kids,kpdt,kgdt
integer kskp,kdisc,kpdtn,kgdtn

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer     n,inum,nvar,ivar,ifhr 
parameter   (inum=2,nvar=12)

real, allocatable :: fprcp(:,:),ftemp(:,:),fflux(:,:)
real, allocatable :: flux_avg(:),prcp_acc(:)
real, allocatable :: prcp(:),rain(:),frzr(:),icep(:),snow(:)
real, allocatable :: arain(:),afrzr(:),aicep(:),asnow(:)
real  weight(inum)

integer     maxgrd,iret,jret,i
integer     ipd1,ipd2,ipd3,ipd10,ipd11,ipd12,ipdn
integer     iunit,icfipg(inum)
integer     nfiles,iskip(inum),tfiles,ifile
integer     lfopg1,icfopg1,lenfile,interhr

character*150 cfipg(inum)
character*100 cfopg1

! variables: apcp snow icep frzr rain       
!            lhtfl,shtfl,dswrf,dlwrf,uswrf,ulwrf1 and ulwrf2


integer jpd1(nvar),jpd2(nvar),jpd10(nvar),jpd11(nvar),jpd12(nvar)

data jpd1 /  1,  1,  1,  1,  1,  0,  0,  4,  5,  4,  5,  5/
data jpd2 /  8, 66, 68, 67, 65, 10, 11,192,192,193,193,193/
data jpd10/  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  8/
data jpd11/  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0/
data jpd12/  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0/

namelist /namens/cfipg,nfiles,iskip,cfopg1,interhr
 
read (5,namens)
!write (6,namens)

print *, ' '; print *, 'Input files size ', nfiles                  

if(nfiles.le.1) goto 1020
if(iskip(1).eq.1.or.iskip(2).eq.1) goto 1020

! set the fort.* of intput file, open forecast files

print *, '   '
print *, 'Input files include '
print *, '   '

iunit=10

do ifile=1,inum
  iunit=iunit+1
  icfipg(ifile)=iunit
  lenfile=len_trim(cfipg(ifile))
  print *, '   '
  print *, 'fort.',iunit, cfipg(ifile)(1:lenfile)
  call baopenr(icfipg(ifile),cfipg(ifile)(1:lenfile),iret)
  if ( iret .ne. 0 ) then
    print *,'there is no CMC ensemble, ifile,iret = ',cfipg(ifile)(1:lenfile),iret
  endif
enddo

! set the fort.* of output file

print *, '   '
print *, 'Output files include '

iunit=iunit+1
icfopg1=iunit
lfopg1=len_trim(cfopg1)
call baopenwa(icfopg1,cfopg1(1:lfopg1),iret)
print *, 'fort.',icfopg1, cfopg1(1:lfopg1)
if(iret.ne.0) then
  print *,'there is no output Prcp/flux average =  ',cfopg1(1:lfopg1),iret
endif

! find grib message, maxgrd: number of grid points in the defined grid

do ifile=1,1  
  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(icfipg(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  if(iret.eq.0) maxgrd=gfld%ngrdpts
  call gf_free(gfld)
enddo

if(iret.ne.0) print *,'there is no maxgrd information'
if(iret.ne.0) goto 1020

allocate(fprcp(maxgrd,inum),ftemp(maxgrd,inum),fflux(maxgrd,inum))
allocate(flux_avg(maxgrd),prcp_acc(maxgrd))
allocate(prcp(maxgrd),rain(maxgrd),frzr(maxgrd),icep(maxgrd),snow(maxgrd),&
         arain(maxgrd),afrzr(maxgrd),aicep(maxgrd),asnow(maxgrd))

print *, '   '

! loop over for different variables

! Step 1: for variables prcp

do ivar = 1, 1

  kskp=0
  kids=-9999;kpdt=-9999; kgdt=-9999
  kdisc=-1;  kpdtn=-1;   kgdtn=-1

  kpdt(1)=jpd1(ivar)
  kpdt(2)=jpd2(ivar)
  kpdt(10)=jpd10(ivar)
  kpdt(12)=jpd12(ivar)
 
  fprcp=-9999.9999

  iret=99
  kpdtn=11
  call getgb2(icfipg(2),0,kskp,kdisc,kids,kpdtn,kpdt,kgdtn,kgdt,unpack,kskp,gfldo,iret)
 
  if(iret.eq.0) then
    print *, '----- Start Read Ensemble Prcp 6hr/3hr Later ------'
    print *, '   '
    call printinfr(gfldo,ivar)
    fprcp(1:maxgrd,2)=gfldo%fld(1:maxgrd)
  else
    print*, 'there is no Prcp for 6hr/3hr later'
    print *, '   '
  endif

  if(iret.ne.0) goto 100

  ! gfldo%ipdtmpl(8):Indicator of unit of time range (10: 3 hour)  
  ! gfldo%ipdtmpl(29):Indicator of unit of time range over which statistical processing is done
  !                   10: 3hours
  ! gfldo%ipdtmpl(30):Length of the time range over which statistical processing is done
 
  ifhr=0
  if(gfldo%ipdtmpl(8).eq.10) then
    if(gfldo%ipdtmpl(29).eq.10) then
      ifhr=gfldo%ipdtmpl(30)*3
    endif
  elseif(gfldo%ipdtmpl(8).eq.11) then
    if(gfldo%ipdtmpl(29).eq.11) then
      ifhr=gfldo%ipdtmpl(30)*6
    endif
  endif
 
  ! for 3hr/6hr lead time, no need to read in 00hr forecast

  if(ifhr.eq.3) then
     fprcp(1:maxgrd,1)=0.0
     print*, 'For 3hr forecast, skip the step to read in 00hr forecast'
  elseif(ifhr.eq.6) then
     fprcp(1:maxgrd,1)=0.0
     print*, 'For 6hr forecast, skip the step to read in 00hr forecast'
  endif

  if(ifhr.eq.3.or.ifhr.eq.6) go to 150

  ! save parameter message for other members 

  ipd1=gfldo%ipdtmpl(1)
  ipd2=gfldo%ipdtmpl(2)
  ipd3=gfldo%ipdtmpl(3)
  ipd10=gfldo%ipdtmpl(10)
  ipd11=gfldo%ipdtmpl(11)
  ipd12=gfldo%ipdtmpl(12)
  ipdn=gfldo%ipdtnum

  ! loop over for another Prcp file

  jret=99

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1; ipdt(2)=ipd2; ipdt(10)=ipd10; ipdt(11)=ipd11; ipdt(12)=ipd12
  igdtn=-1; ipdtn=ipdn
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(icfipg(1),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,jret)

! print Prcp data message

  if(jret.eq.0) then
    print *, '----- Ensemble Prcp for 6hr/3hr Ago ------'
    print *, '   '
    call printinfr(gfld,ivar)
    fprcp(1:maxgrd,1)=gfld%fld(1:maxgrd)
  else
    print*, 'there is no prcp for 6hr/3hr ago '
  endif

  ! clean gfld 

  call gf_free(gfld)

  if(jret.ne.0) goto 100

  150 continue

  do n=1,maxgrd
    prcp_acc(n)=fprcp(n,2)-fprcp(n,1)
    if(prcp_acc(n).lt.0.0) prcp_acc(n)=0.0
  enddo

  print *, '   ' 
  print *, 'Prcp Example at Point 8601 ' 
  print '(3f10.2)', (fprcp(8601,i),i=1,inum), prcp_acc(8601)
  print *, '   ' 

  ! modify the forecast lead time in grib2 message
  ! ipdtmpl(9): forecast time

  print *, '   '
  if(gfldo%ipdtmpl(8).eq.10) then
    if(gfldo%ipdtmpl(29).eq.10) then
      gfldo%ipdtmpl(8)=1
      if(interhr.eq.6) then
        gfldo%ipdtmpl(9)=3*gfldo%ipdtmpl(30)-6
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=6
      elseif(interhr.eq.3) then
        gfldo%ipdtmpl(9)=3*gfldo%ipdtmpl(30)-3
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=3
      endif
    endif
  elseif(gfldo%ipdtmpl(8).eq.11) then
    if(gfldo%ipdtmpl(29).eq.11) then
      gfldo%ipdtmpl(8)=1
      if(interhr.eq.6) then
        gfldo%ipdtmpl(9)=6*gfldo%ipdtmpl(30)-6
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=6
      elseif(interhr.eq.3) then
        gfldo%ipdtmpl(9)=6*gfldo%ipdtmpl(30)-3
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=3
      endif
    endif
  endif

  gfldo%fld(1:maxgrd)=prcp_acc(1:maxgrd)

  gfldo%idrtmpl(2)=0
  gfldo%idrtmpl(3)=2

  print *, '----- Output Prcp for Current Time ------'
  call putgb2(icfopg1,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! end of Prcp estimation calculation               

  100 continue

  call gf_free(gfldo)

enddo 

! end of Prcp calculation               

! Step 2: variable 2 to 5 

do ivar = 2, 5

  kskp=0
  kids=-9999;kpdt=-9999; kgdt=-9999
  kdisc=-1;  kpdtn=-1;   kgdtn=-1

  kpdt(1)=jpd1(ivar)
  kpdt(2)=jpd2(ivar)
  kpdt(10)=jpd10(ivar)
  kpdt(12)=jpd12(ivar)
 
  ftemp=-9999.9999

  iret=99
  kpdtn=11
  call getgb2(icfipg(2),0,kskp,kdisc,kids,kpdtn,kpdt,kgdtn,kgdt,unpack,kskp,gfldo,iret)
 
  if(iret.eq.0) then
    print *, '----- Start Read Ensemble Prcp 3hr/6hr Later ------'
    print *, '   '
    call printinfr(gfldo,ivar)
    ftemp(1:maxgrd,2)=gfldo%fld(1:maxgrd)
  else
    print*, 'there is no Prcp for 3hr/6hr later'
    print *, '   '
  endif

  if(iret.ne.0) goto 200 

  ! for 3hr/6hr lead time, no need to read in 00hr forecast

  ifhr=0
  if(gfldo%ipdtmpl(8).eq.10) then
    if(gfldo%ipdtmpl(29).eq.10) then
      ifhr=gfldo%ipdtmpl(30)*3
    endif
  elseif(gfldo%ipdtmpl(8).eq.11) then
    if(gfldo%ipdtmpl(29).eq.11) then
      ifhr=gfldo%ipdtmpl(30)*6
    endif
  endif

  if(ifhr.eq.3) then
     jret=0
     ftemp(1:maxgrd,1)=0.0
     print*, 'For 3hr forecast, skip the step to read in 00hr forecast'
  elseif(ifhr.eq.6) then
     jret=0
     ftemp(1:maxgrd,1)=0.0
     print*, 'For 6hr forecast, skip the step to read in 00hr forecast'
  endif

  if(ifhr.eq.3.or.ifhr.eq.6) go to 250

  ! save parameter message for other members 

  ipd1=gfldo%ipdtmpl(1)
  ipd2=gfldo%ipdtmpl(2)
  ipd3=gfldo%ipdtmpl(3)
  ipd10=gfldo%ipdtmpl(10)
  ipd11=gfldo%ipdtmpl(11)
  ipd12=gfldo%ipdtmpl(12)
  ipdn=gfldo%ipdtnum

  ! loop over for another Prcp file

  jret=99

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1; ipdt(2)=ipd2; ipdt(10)=ipd10; ipdt(11)=ipd11; ipdt(12)=ipd12
  igdtn=-1; ipdtn=ipdn
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(icfipg(1),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,jret)

! print Prcp data message

  if(jret.eq.0) then
    print *, '----- Ensemble Prcp for 3hr/6hr Ago ------'
    print *, '   '
    call printinfr(gfld,ivar)
    ftemp(1:maxgrd,1)=gfld%fld(1:maxgrd)
  else
    print*, 'there is no prcp for 3hr/6hr ago '
  endif

  ! clean gfld 

  call gf_free(gfld)

  if(jret.ne.0) goto 200 

  250 continue

  do n=1,maxgrd
    prcp_acc(n)=ftemp(n,2)-ftemp(n,1)
    if(prcp_acc(n).lt.0.0) prcp_acc(n)=0.0
  enddo

  if(jpd1(ivar).eq.1.and.jpd2(ivar).eq.66) then
    asnow(1:maxgrd)=prcp_acc(1:maxgrd)
  elseif(jpd1(ivar).eq.1.and.jpd2(ivar).eq.68) then
    aicep(1:maxgrd)=prcp_acc(1:maxgrd)
  elseif(jpd1(ivar).eq.1.and.jpd2(ivar).eq.67) then
    afrzr(1:maxgrd)=prcp_acc(1:maxgrd)
  elseif(jpd1(ivar).eq.1.and.jpd2(ivar).eq.65) then
    arain(1:maxgrd)=prcp_acc(1:maxgrd)
  endif

  print *, '   '
  print *, 'Snow Icep Frzr and Rain Example at Point 8601 ' 
  print '(3f8.2)', (ftemp(8601,i),i=1,inum), prcp_acc(8601)
  print *, '   '

  200 continue

  ! save grib2 message for next step output

  if(ivar.ne.5) call gf_free(gfldo)

  if(iret.ne.0.or.jret.ne.0) call gf_free(gfldo)
  if(iret.ne.0.or.jret.ne.0) exit       

enddo 

if(iret.ne.0.or.jret.ne.0) goto 350   

! Rcreates precip type masks

call mprcp_cmc(arain,afrzr,aicep,asnow,maxgrd,rain,frzr,icep,snow)

if(gfldo%ipdtmpl(8).eq.10) then
  if(gfldo%ipdtmpl(29).eq.10) then
    gfldo%ipdtmpl(8)=1
    if(interhr.eq.6) then
      gfldo%ipdtmpl(9)=3*gfldo%ipdtmpl(30)-6
      gfldo%ipdtmpl(29)=1
      gfldo%ipdtmpl(30)=6
    elseif(interhr.eq.3) then
      gfldo%ipdtmpl(9)=3*gfldo%ipdtmpl(30)-3
      gfldo%ipdtmpl(29)=1
      gfldo%ipdtmpl(30)=3
    endif
  else
    print *, '--- Wrong imdtmpl Nember, Check !!! ---'
  endif
elseif(gfldo%ipdtmpl(8).eq.11) then
  if(gfldo%ipdtmpl(29).eq.11) then
    gfldo%ipdtmpl(8)=1
    if(interhr.eq.6) then
      gfldo%ipdtmpl(9)=6*gfldo%ipdtmpl(30)-6
      gfldo%ipdtmpl(29)=1
      gfldo%ipdtmpl(30)=6
    elseif(interhr.eq.3) then
      gfldo%ipdtmpl(9)=6*gfldo%ipdtmpl(30)-3
      gfldo%ipdtmpl(29)=1
      gfldo%ipdtmpl(30)=3
    endif
  endif
endif

! gfldo%idsect(4) GRIB local table version number
! 0: CMC ensemble; 1: NCEP ensemble

gfldo%idsect(4)=1  

! gfldo%ipdtmpl(27): 0(average), 1(accumulate)

gfldo%idrtmpl(2)=0
gfldo%idrtmpl(3)=0

print *, '----- Output Precipitation Type Mask Snow ------'
print *, '   '
gfldo%fld(1:maxgrd)=snow(1:maxgrd)
gfldo%ipdtmpl(2)=195
gfldo%ipdtmpl(27)=0
call putgb2(icfopg1,gfldo,jret)
call printinfr(gfldo,1)

print *, '----- Output Precipitation Type Mask Icep ------'
print *, '   '
gfldo%fld(1:maxgrd)=icep(1:maxgrd)
gfldo%ipdtmpl(2)=194
gfldo%ipdtmpl(27)=0
call putgb2(icfopg1,gfldo,jret)
call printinfr(gfldo,2)

print *, '----- Output Precipitation Type Mask Frzr ------'
print *, '   '
gfldo%fld(1:maxgrd)=frzr(1:maxgrd)
gfldo%ipdtmpl(2)=193
gfldo%ipdtmpl(27)=0
call putgb2(icfopg1,gfldo,jret)
call printinfr(gfldo,3)

print *, '----- Output Precipitation Type Mask Rain ------'
print *, '   '
gfldo%fld(1:maxgrd)=rain(1:maxgrd)
gfldo%ipdtmpl(2)=192
gfldo%ipdtmpl(27)=0
call putgb2(icfopg1,gfldo,jret)
call printinfr(gfldo,4)

call gf_free(gfldo)

350 continue

! end of Prcp mask estimation calculation               

! Step 3: variable flux   

do ivar = 6, nvar

  kskp=0
  kids=-9999;kpdt=-9999; kgdt=-9999
  kdisc=-1;  kpdtn=-1;   kgdtn=-1

  kpdt(1)=jpd1(ivar)
  kpdt(2)=jpd2(ivar)
  kpdt(10)=jpd10(ivar)
  kpdt(12)=jpd12(ivar)
 
  fflux=-9999.9999

  iret=99
  kpdtn=11
  call getgb2(icfipg(2),0,kskp,kdisc,kids,kpdtn,kpdt,kgdtn,kgdt,unpack,kskp,gfldo,iret)
 
  if(iret.eq.0) then
    print *, '----- Start Read Ensemble Flux Later ------'
    print *, '   '
    call printinfr(gfldo,ivar)
    fflux(1:maxgrd,2)=gfldo%fld(1:maxgrd)
  else
    print*, 'there is no flux 3hr/6hr later',kpdt(1),kpdt(2),kpdt(10)
    print *, '   '
  endif

  if(iret.ne.0) goto 400

  ! for 3hr/6hr lead time, no need to read in 00hr forecast

  if(ifhr.eq.3) then
     fflux(1:maxgrd,1)=0.0
     print*, 'For 3hr forecast, skip the step to read in 00hr forecast'
  elseif(ifhr.eq.6) then
     fflux(1:maxgrd,1)=0.0
     print*, 'For 6hr forecast, skip the step to read in 00hr forecast'
  endif

  if(ifhr.eq.3.or.ifhr.eq.6) go to 450

  ! save parameter message for other members 

  ipd1=gfldo%ipdtmpl(1)
  ipd2=gfldo%ipdtmpl(2)
  ipd3=gfldo%ipdtmpl(3)
  ipd10=gfldo%ipdtmpl(10)
  ipd11=gfldo%ipdtmpl(11)
  ipd12=gfldo%ipdtmpl(12)
  ipdn=gfldo%ipdtnum

  ! loop over for another flux file

  jret=99

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1; ipdt(2)=ipd2; ipdt(10)=ipd10; ipdt(11)=ipd11; ipdt(12)=ipd12
  igdtn=-1; ipdtn=ipdn
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(icfipg(1),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,jret)

  ! print flux data message

  if(jret.eq.0) then
    print *, '----- Ensemble Flux for 3hr/6hr Ago ------'
    print *, '   '
    call printinfr(gfld,ivar)
    fflux(1:maxgrd,1)=gfld%fld(1:maxgrd)
  else
    print*, 'there is no flux for 3hr/6hr ago '
  endif

  ! clean gfld 

  call gf_free(gfld)

  if(jret.ne.0) goto 400

  ! read in accumulated flux and calculate 3hr/6hr averaged flux

  450 continue

  if(interhr.eq.6) then
    do n=1,maxgrd
      flux_avg(n)=(fflux(n,2)-fflux(n,1))/21600
    enddo
  elseif(interhr.eq.3) then
    do n=1,maxgrd
      flux_avg(n)=(fflux(n,2)-fflux(n,1))/10800
    enddo
  endif

  print *, '   ' 
  print *, 'flux Estimation Example at Point 8601 ' 
  print '(3f12.2)', (fflux(8601,i),i=1,inum), flux_avg(8601)
  print *, '   ' 

  ! gfldo%idsect(4) GRIB local table version number
  ! 0: CMC ensemble; 1: NCEP ensemble

  gfldo%idsect(4)=1  

  ! modify the forecast lead time in grib2 message
  ! ipdtmpl(9): forecast time

  print *, '----- Output Flux for Current Time ------'
  print *, '   '
  gfldo%ipdtmpl(27)=0
  if(gfldo%ipdtmpl(8).eq.10) then
    if(gfldo%ipdtmpl(29).eq.10) then
      gfldo%ipdtmpl(8)=1
      if(interhr.eq.6) then
        gfldo%ipdtmpl(9)=3*gfldo%ipdtmpl(30)-6
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=6
      elseif(interhr.eq.3) then
        gfldo%ipdtmpl(9)=3*gfldo%ipdtmpl(30)-3
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=3
      endif
    endif
  elseif(gfldo%ipdtmpl(8).eq.11) then
    if(gfldo%ipdtmpl(29).eq.11) then
      gfldo%ipdtmpl(8)=1
      if(interhr.eq.6) then
        gfldo%ipdtmpl(9)=6*gfldo%ipdtmpl(30)-6
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=6
      elseif(interhr.eq.3) then
        gfldo%ipdtmpl(9)=6*gfldo%ipdtmpl(30)-3
        gfldo%ipdtmpl(29)=1
        gfldo%ipdtmpl(30)=3
      endif
    endif
  endif

  gfldo%idrtmpl(2)=0
  gfldo%idrtmpl(3)=2
  gfldo%fld(1:maxgrd)=flux_avg(1:maxgrd)

  print *, '-----  Ensemble Flux for Current Time ------'
  call putgb2(icfopg1,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! end of flux estimation calculation               

  400 continue

  call gf_free(gfldo)

enddo 

! close files

do ifile=1,inum  
  if(iskip(ifile).eq.0) then 
    call baclose(icfipg(ifile),iret)
  endif
enddo

call baclose(icfopg1,iret)

deallocate(fprcp,ftemp,fflux,flux_avg,prcp_acc)
deallocate(prcp,rain,frzr,icep,snow,arain,afrzr,aicep,asnow)

print *,'Prcp Calculation Successfully Complete'

stop

1020  continue

print *, 'There is not Enough Files Input, Stop!'
!call errmsg('There is not Enough Files Input, Stop!')
!call errexit(1)

stop
end

subroutine mprcp_cmc(arain,afrzr,aicep,asnow,maxgrd,rain,frzr,icep,snow)
!
!$$$  documentation block
!
! subroutine mprcp_cmc:  creates precip type masks
!   prgmmr: Bo Cui          org: np/wx20        date: 2006_03_24
!
! abstract: converts precipitation type accumulation files
!      to precipitation type mask files
! 
! program history log and part code source:
!   2004-09-10   Wobus      New Program: global_mprcp_cmc.f90
!   2005-12-22   Bo Cui     New CMC Ensemble Data
!
! usage: 
!
! input data
!   arain   -  rain accumulation
!   afrzr   -  frzr accumulation
!   aicep   -  icep accumulation
!   asnow   -  snow accumulation
!
! output data: rain mask, frzr mask, icep mask, snow mask
!
! attributes:
!   language: fortran 90
!
!$$$

implicit none
integer     i,m,ij
integer     index
integer     iprint
integer     ijm,ijp
integer     ifi
integer     ifim
integer     j,jt,jd
integer     n,iret,jret,npt,kskp
real        rvarm
real        dmin,dmax

integer     maxgrd 
real        arain(maxgrd),afrzr(maxgrd),aicep(maxgrd),asnow(maxgrd)
real        rain(maxgrd),frzr(maxgrd),icep(maxgrd),snow(maxgrd)
real        rvari(maxgrd,4) 
real        rvaro(maxgrd,4)

!print*,' in subroutine mprcp_cmc '

rvari=0.0             
rvaro=0.0

rvari(1:maxgrd,1)=arain(1:maxgrd)
rvari(1:maxgrd,2)=afrzr(1:maxgrd)
rvari(1:maxgrd,3)=aicep(1:maxgrd)
rvari(1:maxgrd,4)=asnow(1:maxgrd)

do i=1,maxgrd
  do ifi=1,4
    if(rvari(i,ifi).lt.0.1) rvari(i,ifi)=0.0
  enddo
enddo

! calculate masks  

do i=1,maxgrd
  rvarm=0
  ifim=0
  do ifi=1,4
    if (rvarm.lt.rvari(i,ifi)) then
      rvarm=rvari(i,ifi)
      ifim=ifi
    endif
  enddo
  do ifi=1,4
    if (ifi.eq.ifim) then
      rvaro(i,ifi)=1.0
    else
      rvaro(i,ifi)=0.0
    endif
  enddo
enddo

rain(1:maxgrd)=rvaro(1:maxgrd,1)
frzr(1:maxgrd)=rvaro(1:maxgrd,2)
icep(1:maxgrd)=rvaro(1:maxgrd,3)
snow(1:maxgrd)=rvaro(1:maxgrd,4)

return
end

