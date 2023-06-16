program dvrtma_debias_alaska_wind10m
!
! main program: dvrtma_debias_alaska_wind10m
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-10-01
!
! Program history log:
!  Date | Programmer | Comments
!  -----|------------|---------
!  2013-10-01 | Bo Cui       | Initial
!  2023-01-13 | Bo Cui       | Update GRIB2 message to add 10 NCEP/GEFS ensemble members
!
! abstract: get downscaled wind speed and wind direction
!            products include 10%,50% & 90% probability forecast, ensemble mean, & spread
!
!
! usage:
!
!   input file: ncep/cmc ensemble forecast                                          
!
!   output file: 10%, 50%, 90% and mode probability forecast
!              : ensemble mean and spread
!
!   parameters
!     nvar  -      : number of variables
!
!   wind direction calculation
!
!     step 1: divide [0,360) into many small units, choose the 2 units where wind direction data fall most
!          2: rearrange dir date locations, let the 2 units with most data in the middle of all data
!          3: calculate the average direction using the 2 units data
!          4: calculate the direction spread
!          5: adjust wind direction phase in [0,360)
!
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
!$$$

use grib_mod
use params

!implicit none

integer     nmemd,nvar,ivar,i,k,im,imem,n,inum,ignum,nunit,jjm1
parameter   (nmemd=42,nvar=4,nunit=6)

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer     ipd1(nvar),ipd2(nvar),ipd10(nvar),ipd11(nvar),ipd12(nvar),ipdn(nvar)

real,       allocatable :: fgrid_im(:),fgrid(:,:),fst(:)
real,       allocatable :: ens_avg(:),ens_spr(:),bias(:)
real,       allocatable :: prob_10(:),prob_90(:),prob_mode(:),prob_50(:)
real,       allocatable :: wind_u(:,:),wind_v(:,:),wind_speed(:,:),wind_dir(:,:)
real,       allocatable :: temp_u(:,:),temp_v(:,:)
real,       allocatable :: wdir_avg(:),wdir_spr(:),wdir_mode(:)
integer,    allocatable :: iret_u(:),iret_v(:)
logical(1), allocatable :: lbms(:),lbmsout(:)
real        xmin,xmax,avg,spr,weight(nmemd)
integer     maxgrd,ndata
integer     index,j,iret,jret             

integer     ifweightwdir,ipdtnum_out

double precision,allocatable :: fstd(:)
double precision prob10,prob90,prob50,mode

integer     kpds1,kpds2,kpds12

! variables: u10m v10m wspd wdir

data ipd1 /  2,  2,  2,  2/
data ipd2 /  2,  3,  1,  0/
data ipd10/103,103,103,103/
data ipd11/  0,  0,  0,  0/
data ipd12/ 10, 10, 10, 10/

integer     icstart
integer     iunit,lfipg1,lfipg2,icfipg1,icfipg2
integer     tfiles
integer     lfopg1,lfopg2,lfopg3,lfopg4,lfopg5,lfopg6
integer     icfopg1,icfopg2,icfopg3,icfopg4,icfopg5,icfopg6
character*120 cfipg1,cfipg2,cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6

namelist /namens/tfiles,icstart,cfipg1,cfipg2,cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6
 
read (5,namens)

! stop this program if there is no enough files put in

if(tfiles.le.10) goto 1020

! set the fort.* of intput file, open forecast files

print *, 'Input files include '

iunit=10

! set the fort.* of intput GEFS or NAEFS forecast

iunit=iunit+1
icfipg1=iunit
lfipg1=len_trim(cfipg1)
call baopenr(icfipg1,cfipg1(1:lfipg1),iret)
print *, 'fort.',icfipg1, cfipg1(1:lfipg1)
if(iret.ne.0) then
  print *,'there is no GEFS or NAEFS forecast, ifile,iret = ',cfipg1(1:lfipg1),iret
endif

! set the fort.* of intput Downscaling vector

iunit=iunit+1
icfipg2=iunit
lfipg2=len_trim(cfipg2)
call baopenr(icfipg2,cfipg2(1:lfipg2),iret)
print *, 'fort.',icfipg2, cfipg2(1:lfipg2)
if(iret.ne.0) then
  print *,'there is no Downscaling Vector, ifile,iret = ',cfipg2(1:lfipg2),iret
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
  print *,'there is no output probability, 10% = ',cfopg1(1:lfopg1),iret
endif

iunit=iunit+1
icfopg2=iunit
lfopg2=len_trim(cfopg2)
call baopenwa(icfopg2,cfopg2(1:lfopg2),iret)
print *, 'fort.',icfopg2, cfopg2(1:lfopg2)
if(iret.ne.0) then
  print *,'there is no output probability, 90% = ',cfopg2(1:lfopg2),iret
endif

iunit=iunit+1
icfopg3=iunit
lfopg3=len_trim(cfopg3)
call baopenwa(icfopg3,cfopg3(1:lfopg3),iret)
print *, 'fort.',icfopg3, cfopg3(1:lfopg3)
if(iret.ne.0) then
  print *,'there is no output probability, 50% =  ',cfopg3(1:lfopg3),iret
endif

iunit=iunit+1
icfopg4=iunit
lfopg4=len_trim(cfopg4)
call baopenwa(icfopg4,cfopg4(1:lfopg4),iret)
print *, 'fort.',icfopg4, cfopg4(1:lfopg4)
if(iret.ne.0) then
  print *,'there is no output ensemble average =  ',cfopg4(1:lfopg4),iret
endif

iunit=iunit+1
icfopg5=iunit
lfopg5=len_trim(cfopg5)
call baopenwa(icfopg5,cfopg5(1:lfopg5),iret)
print *, 'fort.',icfopg5, cfopg5(1:lfopg5)
if(iret.ne.0) then
  print *,'there is no output ensemble spread  =  ',cfopg5(1:lfopg5),iret
endif

iunit=iunit+1
icfopg6=iunit
lfopg6=len_trim(cfopg6)
call baopenwa(icfopg6,cfopg6(1:lfopg6),iret)
print *, 'fort.',icfopg6, cfopg6(1:lfopg6)
if(iret.ne.0) then
  print *,'there is no output probability, mode =  ',cfopg6(1:lfopg6),iret
endif

! find grib message

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(icfipg1,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1020

maxgrd=gfld%ngrdpts
if(gfld%ipdtmpl(17).ge.21) ifallcmc=1

call gf_free(gfld)

allocate (fgrid(maxgrd,tfiles),fgrid_im(maxgrd),fstd(tfiles),fst(tfiles))
allocate (wind_u(maxgrd,tfiles),wind_v(maxgrd,tfiles),wind_speed(maxgrd,tfiles),wind_dir(maxgrd,tfiles))
allocate (temp_u(maxgrd,tfiles),temp_v(maxgrd,tfiles))
allocate (iret_u(tfiles),iret_v(tfiles))
allocate (prob_10(maxgrd),prob_50(maxgrd),prob_90(maxgrd),prob_mode(maxgrd))
allocate (wdir_mode(maxgrd),wdir_avg(maxgrd),wdir_spr(maxgrd))
allocate (bias(maxgrd),ens_avg(maxgrd),ens_spr(maxgrd))

print *, '   '

! loop over variables

xmin=-999.
xmax=999999.

do ivar = 1, 2  

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1; ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get input downscling vector

  if(icstart.eq.1) then
    print *, '----- Cold Start for Downscaling Vector Input -----'
    print*, '  '
    bias=0.0
  else
    print *, '----- Downscaling Vector for Current Time -----'

    ipdtn=1; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg2,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if(iret.ne.0) then; print*, 'there is no bias ',jpdt(1),jpdt(2),jpdt(10),jpdt(12);endif
    if(iret.ne.0) bias=0.0
    if(iret.eq.0) call printinfr(gfld,ivar)
    if(iret.eq.0) bias(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  call gf_free(gfld)

  fgrid=-9999.9999
  if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.2) wind_u=-9999.99
  if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.3) wind_v=-9999.99

  if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.2) temp_u=-9999.99
  if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.3) temp_v=-9999.99

  inum=0

  ! iret_u and iret_v are used to judge if U and V component are from the same member

  if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.2) iret_u=1
  if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.3) iret_v=1

  ! loop over NAEFS members, get operational ensemble forecast

  print *, '----- NCEP/CMC Ensemble Forecast for Current Time ------'
  print *, '   '

  do imem=1,tfiles 

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1; ipdtn=-1;   igdtn=-1

    ! read and process variable of input data

    ipdt(1)=ipd1(ivar)
    ipdt(2)=ipd2(ivar)
    ipdt(10)=ipd10(ivar)
    ipdt(11)=ipd11(ivar)
    ipdt(12)=ipd12(ivar)

    ! iids(1) is for product generation center
    ! ipdtmpl(5) is for generation process identifier
    ! %iids(1)=  7: US National Weather Service - NCEP (WMC)
    ! %iids(1) =54: Canadian Meteorological Service - Montreal (RSMC)s
    ! %ipdtmpl(5)=114: NAEFS Products from joined NCEP,CMC global ensembles
    ! %ipdtmpl(5)=107: Global Ensemble Forecast System (GEFS)

    ! read and process input member for NCEP 30 members

    if(imem.le.30) then
      ipdt(17)=imem
      iids(1)=7
    endif

    ! check if all member are from cmc ensmeble

    if(imem.le.20.and.ifallcmc.eq.1) ipdt(17)=20+imem

    ! NCEP adds 10 members with ipdt(17) from 1 to 30, CMC has ipdt(17) from 21 to 40
    ! after reading NCEP 30 members, adjust ipdt(17) starting with 21 for CMC ensemble

    if(imem.gt.30) then
       ipdt(17)=imem
       iids(1)=54
    endif

    fgrid_im=-9999.9999

    ipdtn=1; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg1,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    print *, '----- Ensemble Forecast Member ',imem, ' Before Downscaling ------'
    print *, '   '

    if(iret.ne.0) then; print*, 'there is no fcst ',jpdt(1),jpdt(2),jpdt(10),jpdt(12);endif

    if(iret.eq.0) then

      fgrid_im(1:maxgrd)=gfld%fld(1:maxgrd)

      ! print data message

      call printinfr(gfld,ivar)

      ! save NCEP message for output. If there is no NCEP data, save CMC data message later

      if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.2.and.iret.eq.0) iret_u(imem)=0
      if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.3.and.iret.eq.0) iret_v(imem)=0

      ! downscaling process

      call debias(bias,fgrid_im,maxgrd)

      gfld%fld(1:maxgrd)=fgrid_im(1:maxgrd)

      print *, '----- Ensemble Forecast Member ',imem, ' After Downscaling ------'
      print *, '   '
      call printinfr(gfld,ivar)
      print *, '   '

      inum=inum+1
      fgrid(1:maxgrd,inum)=fgrid_im(1:maxgrd)

      ! no matter iret =0 or not, save data to wind_u or wind_v

      if(gfld%ipdtmpl(1).eq.2.and.gfld%ipdtmpl(2).eq.2.and.gfld%ipdtmpl(12).eq.10) then
        temp_u(1:maxgrd,imem)=fgrid_im(1:maxgrd)
        kpds1=gfld%ipdtmpl(1)
        kpds2=gfld%ipdtmpl(2)
        kpds12=gfld%ipdtmpl(12)
      endif

      if(gfld%ipdtmpl(1).eq.2.and.gfld%ipdtmpl(2).eq.3.and.gfld%ipdtmpl(12).eq.10) then
        temp_v(1:maxgrd,imem)=fgrid_im(1:maxgrd)
        kpds1=gfld%ipdtmpl(1)
        kpds2=gfld%ipdtmpl(2)
        kpds12=gfld%ipdtmpl(12)
      endif

    endif      ! end of iret equal to 0

    call gf_free(gfld)

  enddo          ! end of imem loop

  ! end of imem loop, calculate 10%, 50% and 90% probability

  ! goto 300 to calculate probability of 10m u ans 10m v 

  go to 300

  500 continue                                      

  ! judge if U and V component are from the same member

  inum=0
  do imem=1,tfiles
    if(iret_u(imem).eq.0.and.iret_v(imem).eq.0) then
      inum=inum+1
      wind_u(1:maxgrd,inum)=temp_u(1:maxgrd,imem)
      wind_v(1:maxgrd,inum)=temp_v(1:maxgrd,imem)
    endif
  enddo

  print *, '   '
  print *, '----- Start Wind Speed and Direction Calculation for Each Member ------'

  !print *, ' wind_u, wind_v, inum ',inum
  !print '(10f10.2)',(wind_u(8601,n),n=1,inum)
  !print '(10f10.2)',(wind_v(8601,n),n=1,inum)

  ! if there are enough members, don't calculate the probability of this variables

  if(inum.le.10) go to 200                                         

  ! calculate wind and direction in phase [0,360) for each member

  call wind2parts(wind_speed,wind_dir,maxgrd,inum,wind_u,wind_v)

  print *, ' wind_speed, wind_dir '
  print '(10f10.2)',(wind_u(8601,n),n=1,inum)
  print '(10f10.2)',(wind_v(8601,n),n=1,inum)
  print '(10f10.2)',(wind_speed(8601,n),n=1,inum)
  print '(10f10.2)',(wind_dir(8601,n),n=1,inum)

  print *, '----- Wind Speed for Each Ensemble Member  ------'; print *, ' '

  do n=1,inum
    call message(wind_speed(1,n),maxgrd,n)
  enddo

  ! rearrange wdir date locations, let the 2 units with most data in the middle of all data
  ! calculate wind direction average and spread and mode (no wind speed )

  call wdirprob(wind_dir,maxgrd,inum,nunit,wdir_avg,wdir_spr,wdir_mode)

  ! goto 300 to calculate wind speed probability 
  ! returen to 400 to calculate wind direction probability 

  ! wspd: gfld%ipdtmpl(1)=2; gfld%ipdtmpl(2)=1; gfld%ipdtmpl(12)=10
  ! wdir: gfld%ipdtmpl(1)=2; gfld%ipdtmpl(2)=0; gfld%ipdtmpl(12)=10

  kpds1=2; kpds2=1; kpds12=10
  fgrid=wind_speed

  goto 300

  400 continue

  kpds1=2; kpds2=0; kpds12=10
  fgrid=wind_dir  

  print *, '----- Wind Direction for Each Ensemble Member  ------'; print *, ' '

  do n=1,inum
    call message(wind_dir(1,n),maxgrd,n)
  enddo

  print *, '----- Wind Direction After Rearrange  ------'; print *, ' '

  do n=1,inum
    call message(wind_dir(1,n),maxgrd,n)
  enddo

  300 continue

  print *, '   '
  print *,  ' Combined Ensemble Data Example at Point 8601 '
  write (*,'(10f8.1)') (fgrid(8601,i),i=1,inum)

  do n=1,maxgrd

    fst(1:inum)=fgrid(n,1:inum)
    fstd(1:inum)=fgrid(n,1:inum)

    do i=1,inum
      weight(i)=1/float(inum)
    enddo

    ! for wind direction

    if(kpds1.eq.2.and.kpds2.eq.0.and.kpds12.eq.10) then
      ens_avg(n)=wdir_avg(n)
      ens_spr(n)=wdir_spr(n)
    else
      ens_avg(n)=epdf(fst,weight,inum,1.0,0)
      ens_spr(n)=epdf(fst,weight,inum,2.0,0)
    endif

    call probability(fstd,inum,prob10,prob90,prob50)
    prob_10(n)=prob10
    prob_90(n)=prob90
    prob_50(n)=prob50

    if(prob_50(n).gt.xmin.and.prob_50(n).lt.xmax.and.ens_avg(n).gt.xmin  &
      .and.ens_avg(n).lt.xmax) then
      prob_mode(n)=3*prob_50(n)-2*ens_avg(n)
    else
      prob_mode(n)=-9999.99
    endif

    ! for wind speed                

    if(kpds1.eq.2.and.kpds2.eq.1.and.kpds12.eq.10) then
      prob_mode(n)=prob_50(n)
    endif

    ! for wind direction only

    if(kpds1.eq.2.and.kpds2.eq.0.and.kpds12.eq.10) then
      prob_mode(n)=wdir_mode(n)
    endif

    if(prob10.eq.0.0.or.prob90.eq.0.0.or.prob50.eq.0.0) then
      print *, '   '
      print *,  ' Sorted Ensemble Data Example at Point',n
      write (*,'(10f8.2)') (fst(i),i=1,inum)
      print *,  ' 10%, 90%, 50% Probability at Point',n
      write (*,'(10f8.1)') prob_10(n),prob_90(n), prob_50(n)
    endif

  enddo

  print *, '   '

  ! adjust wind direction to [0,360)

  if(kpds1.eq.2.and.kpds2.eq.0.and.kpds12.eq.10) then

    print *, ' before adjust phase in [0,360) '
    call message(prob_10,maxgrd,ivar)
    call message(prob_50,maxgrd,ivar)
    call message(prob_90,maxgrd,ivar)
    call message(prob_mode,maxgrd,ivar)
    call message(ens_avg,maxgrd,ivar)
    call message(ens_spr,maxgrd,ivar)

    ! adjust wind direction to [0,360)

    call phasechange(prob_10,maxgrd,3)
    call phasechange(prob_50,maxgrd,3)
    call phasechange(prob_90,maxgrd,3)
    call phasechange(prob_mode,maxgrd,3)
    call phasechange(ens_avg,maxgrd,3)
    call phasechange(ens_spr,maxgrd,3)

    !do n=1,maxgrd
    ! if(ens_avg(n).ge.359.99) then
    !   print *, ' n=',n,ens_avg(n)                                 
    ! endif
    !enddo

    print *, ' after adjust phase in [0,360) '
    print '(10f10.2)',prob_10(8601),prob_50(8601),prob_90(8601),prob_mode(8601),ens_avg(8601),ens_spr(8601)

  endif

  ! save probability forecast

  ! get grib2 message from input file

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(icfipg1,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  ! save probability forecast

  ! save NCEP message for output. If no NCEP data, save CMC data message later
  ! idsect(1) is for product generation center
  ! ipdtmpl(5) is for generation process identifier
  
  ! %idsect(1)=  7: US National Weather Service - NCEP (WMC)
  ! %idsect(1) =54: Canadian Meteorological Service - Montreal (RSMC)s
  ! %ipdtmpl(5)=114: NAEFS Products from joined NCEP,CMC global ensembles
  ! %ipdtmpl(5)=107: Global Ensemble Forecast System (GEFS)

  if(cfopg1(1:5).eq.'naefs') then
    gfldo%idsect(1)=7
    gfldo%ipdtmpl(5)=114
  elseif(cfopg1(1:2).eq.'ge') then
    gfldo%idsect(1)=7
    gfldo%ipdtmpl(5)=107
  else
    gfldo%idsect(1)=7
    gfldo%ipdtmpl(5)=107
  endif

  ! save probability forecast

  print*, '  '
  print *, '----- Output Probability for Current Time ------'
  print *, '   '

  ! when product difinition template 4.1/4.11 chenge to 4.2/4.12
  ! ipdtlen aslo change, need do modification for output
  ! code table 4.0, 2=derived forecast

  if(gfldo%ipdtnum.eq.1) ipdtnum_out=2
  if(gfldo%ipdtnum.eq.11) ipdtnum_out=12

  print *, 'gfldo%ipdtnum,gfldo%ipdtnum,ipdtnum_out,gfldo%ipdtlen'
  print *, gfldo%ipdtnum,gfldo%ipdtnum,ipdtnum_out,gfldo%ipdtlen

  call change_template4(gfldo%ipdtnum,ipdtnum_out,gfldo%ipdtmpl,gfldo%ipdtlen)

  print *, gfldo%ipdtnum,gfldo%ipdtnum,ipdtnum_out,gfldo%ipdtlen

  ! save PDT parameter category, parameter number

  gfldo%ipdtmpl(1)=kpds1; gfldo%ipdtmpl(2)=kpds2; gfldo%ipdtmpl(12)=kpds12

  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

  gfldo%idrtmpl(3)=2

  ! extensions for 10% probability forecast
  
! gfldo%ipdtnum=2          ! derived forecast
  gfldo%ipdtmpl(16)=193    ! code table 4.7, Percentile value (10%) of All Members
  gfldo%fld(1:maxgrd)=prob_10(1:maxgrd)

  print *, '----- Probility 10% for Current Time ------'

  call putgb2(icfopg1,gfldo,iret)
  call printinfr(gfldo,ivar)

  ! extensions for 90% probability forecast

! gfldo%ipdtnum=2          ! derived forecast
  gfldo%ipdtmpl(16)=195    ! code table 4.7, Percentile value (90%) of All Members
  gfldo%fld(1:maxgrd)=prob_90(1:maxgrd)

  print *, '----- Probility 90% for Current Time ------'

  call putgb2(icfopg2,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! extensions for 50% forecast

! gfldo%ipdtnum=2          ! derived forecast
  gfldo%ipdtmpl(16)=194    ! code table 4.7, Percentile value (50%) of All Members
  gfldo%fld(1:maxgrd)=prob_50(1:maxgrd)

  print *, '----- Probility 50% for Current Time ------'
  call putgb2(icfopg3,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! extensions for mode forecast

! gfldo%ipdtnum=2          ! derived forecast
  gfldo%ipdtmpl(16)=192    ! code table 4.7, unweighted mode of all Members
  gfldo%fld(1:maxgrd)=prob_mode(1:maxgrd)

  print *, '-----  Probility Mode for Current Time ------'
  call putgb2(icfopg6,gfldo,jret)
  call printinfr(gfldo,ivar)

  print *, '----- Output ensemble average and spread for Current Time ------'
  print *, '   '

  ! extensions for ensemble mean

! gfldo%ipdtnum=2          ! derived forecast
  gfldo%ipdtmpl(16)=0      ! code table 4.7, unweighted mean of all Members
  gfldo%fld(1:maxgrd)=ens_avg(1:maxgrd)

  print *, '-----  Ensemble Average for Current Time ------'
  call putgb2(icfopg4,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! extensions for ensemble spread

! gfldo%ipdtnum=2          ! derived forecast
  gfldo%ipdtmpl(16)=4      ! code table 4.7, spread of all Members
  gfldo%fld(1:maxgrd)=ens_spr(1:maxgrd)

  print *, '-----  Ensemble Spread for Current Time ------'
  call putgb2(icfopg5,gfldo,jret)
  call printinfr(gfldo,ivar)

  call gf_free(gfldo)

  ! end of probability forecast calculation               

  ! wdir: gfld%ipdtmpl(1)=2; gfld%ipdtmpl(2)=0; gfld%ipdtmpl(12)=10
  ! wspd: gfld%ipdtmpl(1)=2; gfld%ipdtmpl(2)=1; gfld%ipdtmpl(12)=10

  ! when variable is 10m v, both u and v are avaiable, go to caculate wind speed

  if(kpds1.eq.2.and.kpds2.eq.3.and.kpds12.eq.10) go to 500

  ! when variable is 10m wind speed, go to caculate wind direction

  if(kpds1.eq.2.and.kpds2.eq.1.and.kpds12.eq.10) go to 400

  200 continue

enddo

! end of ivar loop                                      

! close files

call baclose(icfipg1,iret)
call baclose(icfipg2,iret)

call baclose(icfopg1,iret)
call baclose(icfopg2,iret)
call baclose(icfopg3,iret)
call baclose(icfopg4,iret)
call baclose(icfopg5,iret)
call baclose(icfopg6,iret)

print *,'Probability Calculation Successfully Complete'

stop

1020  continue

print *,'There is not Enough Files Input, Stop!'

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
  if(fgrid(ij).gt.-9999.0.and.fgrid(ij).lt.999999.0.and.bias(ij).gt.-9999.0.and.bias(ij).lt.999999.0) then
    fgrid(ij)=fgrid(ij)-bias(ij)
  else
    fgrid(ij)=fgrid(ij)
  endif
enddo

return
end


subroutine wind2parts(wspd,wdir,maxgrd,inum,wind_u,wind_v)    

!     calculate wind speed and direction
!
!     parameters
!
!        input
!                  wind_u  ---> u ccomponent
!                  wind_v  ---> v component
!                  maxgrid ---> number of grid points in the defined grid

!        output
!                  wind_speed ---> wind speed    
!                  wind_dir   ---> wind direction

! wind direction: 45.0/atan(1.0)*atan(u/v)) + phase adjust
!
! general cases
!
! theta= 45.0/atan(1.0)*atan(u/v))
!
! wind direction = theta    ,    u<0, v<0 
!                = 180 + theta , u<0, v>0 
!                = 180 + theta , u>0, v>0 
!                = 360 + theta , u>0, v<0 
!
! special cases
!
! wind direction =  0 ,  u=0, v<0 
!                =  90,  u<0, v=0 
!                = 180,  u=0, v>0 
!                = 270,  u>0, v=0 
!                = 0  ,  u=0, v=0 

implicit none

integer maxgrd,ij,inum,num
real const,ue,ve,aearth
real wspd(maxgrd,inum),wdir(maxgrd,inum),wind_u(maxgrd,inum),wind_v(maxgrd,inum)

const=45./atan(1.)

do 100 num=1,inum 

  do 200 ij=1,maxgrd

    ue=wind_u(ij,num)
    ve=wind_v(ij,num)

    if(ue.gt.-999.0.and.ue.lt.999999.0) then
      if(ve.gt.-999.0.and.ve.lt.999999.0) then

        wspd(ij,num)=sqrt(ue*ue+ve*ve)

        if (wspd(ij,num).eq.0.0) then
            wdir(ij,num)=0.
            goto 200
        endif

        if (ve.eq.0.0) then
          if (ue.gt.0.0) wdir(ij,num) = 270.
          if (ue.lt.0.0) wdir(ij,num) =  90.
        else if (ue.eq.0.0) then
          if (ve.gt.0.0) wdir(ij,num) = 180.
          if (ve.lt.0.0) wdir(ij,num) =   0.
        else
          aearth = atan(ue/ve)*const 
          if (ue.lt.0.0 .and. ve.lt.0.0 ) wdir(ij,num) = aearth
          if (ue.lt.0.0 .and. ve.gt.0.0 ) wdir(ij,num) = aearth + 180.0
          if (ue.gt.0.0 .and. ve.gt.0.0 ) wdir(ij,num) = aearth + 180.0
          if (ue.gt.0.0 .and. ve.lt.0.0 ) wdir(ij,num) = aearth + 360.0
        endif

      endif
    endif

  200 continue
100 continue

return
end

subroutine phasechange(angle,maxgrd,chndex)

! change wind direction phase from [0,360) to [-180,180]
!
!     parameters
!
!        input
!                  angle   ---> wind direction
!                  chndex  ---> index number  
!
!        output
!                  angle   ---> adjusted wind direction
!
!    chndex = 1 : change wind direction phase from [0,360) to (-180,180]
!           = 2 : change wind direction phase from (-180,180], [0,360)
!           = 3 : adjust wind direction to locate in phase [0,360) if it is negative or biger than 360 
!           = 4 : adjust wind direction in phase (-180,180] if it is less than -180 or biger than 180
!
implicit none

integer chndex,ij,maxgrd                
real    angle(maxgrd)

if(chndex.eq.1) then
  do ij=1,maxgrd
    if(angle(ij).gt.180.) angle(ij)=angle(ij)-360.
  enddo
endif

if(chndex.eq.2) then
  do ij=1,maxgrd
    if(angle(ij).lt.0.) angle(ij)=360.0+angle(ij)
  enddo
endif

if(chndex.eq.3) then

  do ij=1,maxgrd
    if(angle(ij).lt.0.) angle(ij)=360.0+angle(ij)
    if(angle(ij).ge.360.) angle(ij)=angle(ij)-360.0
  enddo

  ! to avoid extram case 

  do ij=1,maxgrd
    if(angle(ij).lt.0.) angle(ij)=360.0+angle(ij)
    if(angle(ij).ge.360.) angle(ij)=angle(ij)-360.0
  enddo

endif

if(chndex.eq.4) then
  do ij=1,maxgrd
    if(angle(ij).gt.180.) angle(ij)=angle(ij)-360.0
    if(angle(ij).lt.-180.) angle(ij)=angle(ij)+360.0
  enddo
  ! to avoid extram case
  do ij=1,maxgrd
    if(angle(ij).gt.180.) angle(ij)=angle(ij)-360.0
    if(angle(ij).lt.-180.) angle(ij)=angle(ij)+360.0
  enddo
endif


return
end

subroutine wdirprob(wdir,maxgrd,inum,nunit,wdir_avg,wdir_spr,wdir_mode)

! this subroutine calculate wind direction average and spread
!
!     parameters
!
!        input
!                  wdir     ---> wind direction
!                  maxgrd   ---> grid number
!                  inum     ---> ensemble size 
!                  nunit    ---> number of units to divide [0,360) into small units
!
!        output
!                  wdir_avg ---> wind direction average
!                  wdir_spr ---> wind direction spreed
!                  wdir_mode---> wind direction mode    
!                  wdir     ---> wind direction distributed in a stream
!
! step 1: divide [0,360) into many small units, choose the 2 units where wind direction data fall most 
!      2: rearrange wdir date locations, let the 2 units with most data in the middle of all data
!      3: calculate the average direction using whole data                                    
!      4: calculate the wind direction spread using whole data

implicit none

integer inum,nunit,ii,jj,maxgrd
real    wdir(maxgrd,inum),wdir_avg(maxgrd),wdir_spr(maxgrd),wdir_mode(maxgrd),wind(inum)
real    ensavg,ensspr,ensmode,ens50pt,ens90pt,ens10pt

do ii=1,maxgrd
!do ii=8601,8602
  wind(1:inum)=wdir(ii,1:inum)
  call wdircount(wind,inum,nunit,ensavg,ensspr,ensmode)
  wdir(ii,1:inum)=wind(1:inum)
  wdir_avg(ii)=ensavg
  wdir_spr(ii)=ensspr
  wdir_mode(ii)=ensmode
enddo

!print *, 'in subrountine first'
!print '(10f10.2)',wdir_avg(8601),wdir_spr(8601)

return
end

subroutine wdircount(wdir,inum,nunit,ensavg,ensspr,ensmode)

! this subroutine calculate wind direction average and spread at one grid point
!
!     parameters
!
!        input
!                  wdir    ---> wind direction
!                  inum    ---> ensemble size 
!                  nunit   ---> number of units to divide [0,360) into small units
!
!        output
!                  enssvg  ---> wind direction average
!                  ensspr  ---> wind direction spreed
!                  ensmode ---> wind direction mode   
!                  wdir    ---> wind direction distributed in a stream
!
! step 1: divide [0,360) into many small units, choose the 2 units where wind direction data fall most 
!      2: rearrange dir date locations, let the 2 units with most data in the middle of all data
!      3: calculate the average direction using whole data                                    
!      4: calculate the wind direction spread using whole data

implicit none

integer ii,jj,num,inum,nunit,maxn,idxmax,cnum,count(nunit),jjm1
real    wdir(inum),unit,angst,anged,ensavg,ensspr,ensmode,ens50pt,diff,ens10pt,ens90pt

count=0               

! count the number that the wind direction fall in this range

unit=360./nunit

! first give the start and end values of each unit, then judge if wind direction fall into this unit

do jj=1,nunit
  angst=(jj-1)*unit
  anged=jj*unit
  do ii=1,inum
    if(wdir(ii).ge.angst.and.wdir(ii).lt.anged) count(jj)=count(jj)+1
  enddo
enddo

! judge which 2 units have the most members ( idxmax-1 & idxmax )

maxn=0
idxmax=0
cnum=0

do jj=1,nunit
  jjm1=jj-1
  if(jj.eq.1) jjm1=6
  cnum=count(jjm1)+count(jj)
  if(cnum.ge.maxn) then
     maxn=cnum
     idxmax=jj
  endif
enddo

! adjust wind direction distribution, let the 2 units having most data locate in the middle of whole data
! distribution. The adjusted wind direction values may be negative or bigger than 360 

call wdirline(wdir,inum,idxmax,maxn,nunit)

! calculate wind direction average use all unit data

ensavg=0.0
cnum=0

do ii=1,inum
  ensavg=ensavg+wdir(ii)
  cnum=cnum+1
enddo

if(cnum.ge.1) ensavg=ensavg/cnum

! calculate wind direction mode use 2 unit data

ensmode=0.0

call wdirmode(wdir,inum,idxmax,maxn,nunit,ensmode)
 
! calculate wind direction spread use all data
! choose the difference between two wind direction less than 180

ensspr=0.0

do ii=1,inum
  diff=abs(wdir(ii)-ensavg)
  if(diff.gt.180.0) diff=360.-diff
  ensspr=ensspr+diff**2                                  
enddo

ensspr=sqrt(ensspr/float(inum-1))

!print *, 'inum,cnum,ensavg,ensspr=',inum,cnum,ensavg,ensspr    
!print '(10f10.2)', (wdir(ii),ii=1,inum)

return
end

subroutine wdirline(dir,inum,idxmax,maxn,nunit)

! adjust wind direction values and let the 2 units having most data locate in the middle of whole data distribution
!
!     parameters
!
!        input
!                  dir    ---> wind direction values
!                  inum   ---> ensemble size 
!                  nunit  ---> number of units to divide [0,360) 
!                  idxmax ---> the unit number that idxmax and idxmax-1 have the most ensemble forecast
!                  maxn   ---> maximum number of ensmeble forecast falling into 2 units
!
!        output
!                  dir    ---> wind direction
! 
!  step 1: judge if the 2 units having most data are located in the middle of whole data distribution
!          if yes, no need to do adjustment, if no, goto step 2
!       2: if the 2 units having most data are located in the left side of whole data distribution,
!          adjust the most right side values to negative values by minusing 360
!       3: if the 2 units having most data are located in the right side of whole data distribution,
!          adjust the most left side values to postive value by adding 360
!       4: if idxmax is 1 (2 units are located at the first and last unit), adjust the first 3 units to the right of last unit
!
! note:
!      the adjusted wind direction values may become negative or bigger than 360. Therefore, wind direction are
!      needed to be adjusted back to [0,360) after finishing average and spreed calculation
!

implicit none

integer idxmax,nunit,mvnum,mvst,mved,nle,nrg,ii,jj,inum,maxn
real    dir(inum),unit,dirst,dired

! nunit is chosen as 6n (n=1)

unit=360./nunit

! judge if idxmax equle 1, then adjust the first 3 units (nunit=6) to the right of the last unit 

if(idxmax.eq.1) then
  do jj=1,inum
     dirst=0.
     dired=unit*nunit/2
     if(dir(jj).ge.dirst.and.dir(jj).le.dired) dir(jj)=dir(jj)+360
  enddo
endif

if(idxmax.eq.1) goto 100

! if all ensemble forecast fall into the 2 units, there is no need to do any adjustment 

if(maxn.eq.inum) goto 100

! nle: number of units at the left side of unit with maximum data
! nrg: number of units at the right side of unit with maximum data

nle=idxmax-2
nrg=nunit-idxmax

! mvnum : total number of units that their value need to be adjusted
! mvst  : start number of unit that their value need to be adjusted
! mved  : end number of unit that their value need to be adjusted

mvnum=0
mvst=0
mved=0

! get the start and end unit number where wind direction are needed to be adjusted

if(nle.eq.nrg) goto 100

if (nrg.gt.nle) then
  mvnum=(nrg-nle)/2
  mvst=nunit-mvnum+1
  mved=nunit              
  do ii=mvst,mved
    dirst=unit*(mvst-1)
    dired=unit*mved 
    do jj=1,inum
      if(dir(jj).ge.dirst.and.dir(jj).le.dired) dir(jj)=dir(jj)-360
    enddo
  enddo
else
  mvnum=(nle-nrg)/2
  mvst=1                    
  mved=1+mvnum            
  do ii=mvst,mved
    do jj=1,inum
      dirst=unit*(mvst-1)
      dired=unit*mved 
      if(dir(jj).ge.dirst.and.dir(jj).le.dired) dir(jj)=dir(jj)+360
    enddo
  enddo
endif

100 continue

return 
end

subroutine wdirmode(dir,inum,idxmax,maxn,nunit,ensmode)

! calculate wind direction mode
!    first get the start and end values of 2 unit with most members, then set a 60 degree window         
!    move the window and see which window has the most members in the 2 units

!     parameters
!
!        input
!                  dir    ---> wind direction values
!                  inum   ---> ensemble size 
!                  idxmax ---> the unit number that idxmax and idxmax-1 have the most ensemble forecast
!                  maxn   ---> maximum number of ensmeble forecast falling into 2 units
!                  nunit  ---> number of units to divide [0,360) 
!
!        output
!                  ensmode---> wind direction mode
! 

implicit none

integer ii,jj,num,inum,nunit,maxn,idxmax,cnum
integer refnum,refst,refed,modenum,modeid(10),modeadd
real    dir(inum),unit,angst,anged,ensmode
real,   allocatable :: refcount(:)      

unit=360./nunit

! sorts the dir into ascending order

call sortr(dir,inum)

! all the wdir have been relocated, the middle 2 units have the most members.
! get the start and end values of 2 unit 

angst=unit*(idxmax-2)
anged=unit*idxmax
if(idxmax.eq.1) then
  angst=unit*(nunit-1)
  anged=unit*(nunit+1)
endif

!print *, 'angst, anged=', angst, anged 

! get how many windows are set up

refnum=int(unit/10+1)

allocate (refcount(0:refnum+1))

refcount=0

! get how many members fall in each window

do jj=0,refnum+1
  refst=angst+(jj-1)*10.    
  refed=angst+60+(jj-1)*10.    
  do ii=1,inum
    if(dir(ii).ge.refst.and.dir(ii).lt.refed) refcount(jj)=refcount(jj)+1
  enddo
enddo

!print *, 'refcount=', refcount              

maxn=0
idxmax=0

! get the window location (jj) with the most members

do jj=1,refnum
  if(refcount(jj).ge.maxn) then
     maxn=refcount(jj)
     idxmax=jj
  endif
enddo

! judge if there are identical maxn values       

modenum=0
modeid=0

do jj=1,refnum
  if(refcount(jj).eq.maxn) then
     modenum=modenum+1
     modeid(modenum)=jj
  endif
enddo

!print *, 'modenum, modeid=', modenum, modeid       

! if there are more than one mode,
 
if(modenum.ge.2) then
  maxn=0
  idxmax=0
  do ii=1,modenum
    jj=modeid(ii)
    modeadd=refcount(jj)+refcount(jj+1)+refcount(jj-1)
    if(modeadd.ge.maxn) then
      maxn=modeadd      
      idxmax=jj
    endif
  enddo
endif  

!print *, 'modeadd,idxmax=', modeadd,idxmax

!if(modenum.ge.3) then
!  cnum=0
!  idxmax=0
!  do ii=1,modenum
!    idxmax=modeid(ii)+idxmax
!    cnum=cnum+1
!  enddo
!  if(cnum.ge.1) idxmax=int(idxmax/cnum)
!  print *, 'cnum=', cnum  
!endif

!print *, 'angst+(idxmax-1)*10= ', angst+(idxmax-1)*10.
!print *, 'angst+60+(idxmax-1)*10= ', angst+60+(idxmax-1)*10

!print *, 'dir=',dir                                        

! calculate wind direction mode use the window  

ensmode=0.0
cnum=0

ensmode=(angst+(idxmax-1)*10.+angst+60+(idxmax-1)*10.)*0.5

!do ii=1,inum
!  refst=angst+(idxmax-1)*10.
!  refed=angst+60+(idxmax-1)*10.
!  if(dir(ii).ge.refst.and.dir(ii).lt.refed) then
!    ensmode=ensmode+dir(ii)
!    cnum=cnum+1
!  endif
!enddo

!if(cnum.ge.1) ensmode=ensmode/cnum
!print *, 'refst, refed,cnum, ensmode=',angst+(idxmax-1)*10., angst+60+(idxmax-1)*10., ensmode                                    
return 
end

subroutine message(grid,maxgrd,ivar)

! print data information

! input:
!         grid    ---> ensemble forecast
!         maxgrid ---> number of grid points in the defined grid
!         ivar    ---> number of variable

implicit none

integer    ivar,maxgrd,j
real       grid(maxgrd),dmin,dmax

dmin=grid(1)
dmax=grid(1)

do j=2,maxgrd
  if(grid(j).gt.dmax) dmax=grid(j)
  if(grid(j).lt.dmin) dmin=grid(j)
enddo

print*, 'Irec   ndata   Maximun    Minimum   Example'
print '(i5,i8,3f10.2)',ivar,maxgrd,dmax,dmin,grid(8601)

print *, '   '

return
end

