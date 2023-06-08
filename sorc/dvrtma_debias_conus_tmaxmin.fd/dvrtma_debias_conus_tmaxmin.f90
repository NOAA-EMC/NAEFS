program dvrtma_debias_conus_tmaxmin
!
! main program: dvrtma_debias_conus_tmaxmin
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-10-01
!
! Program history log:
!  Date | Programmer | Comments
!  -----|------------|---------
!  2013-10-01 | Bo Cui       | Initial
!  2023-01-13 | Bo Cui       | Update GRIB2 message to add 10 NCEP/GEFS ensemble members
!
! abstract: get downscaled tmax and tmin forecast for conus region
!
! usage:
!
!   downscale Tmax & Tmin process
!
!     Definition of Tmax and Tmin for conus region :
!
!       Tmax period: 11/12UTC (7am-local) - 23/00UTC (7pm-local) - EAST
!	Tmin period: 23/00UTC (7pm-local) - 12/13UTC (8am-local) - EAST

!
!     setp 1: read in t2m downscaling vectors valid at 00z, 06, 12z and 18z
!     setp 2: get downscaled mean temperature for each 6hr period by taking weighted waverage of instantaneous vectors 
!             DV(t0-6hr)  = ( DV(t0) + DV(t6) ] /2
!             DV(t6-12hr) = ( DV(t6) + DV(t12) ] /2
!             DV(t12-18hr)= ( DV(t12) + DV(t18) ] /2
!             DV(t18-00hr)= ( DV(t18) + DV(t00) ] /2
!     setp 3: read in interpolating bias corrected 6-hourly Tmax, Tmin from 1x1 degree to 6km NDGD grid for conus region
!     setp 4: appling mean down-scaling vectors to each grid point, each ensemble member, and each 6-hour lead-time period
!             to produce down-scaled Tmax and Tmin for each 6-hour lead-time period, then  find out highest Tmax and 
!             lowest Tmin for approximated period for Tmax and Tmin ( see defination) at 6km resolution.  There is only
!             one down-scaled Tmax and Tmin for every 24-hour forecast, up to 384 hours. 
!     step 5: calculate the mean, spread, mode, 10%, 50% and 90% based on step 4 

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

implicit none

integer     ivar,i,nmemd,imem,inum
parameter   (nmemd=5)

real,       allocatable :: tmax(:),tmin(:),t2m_m06(:),t2m(:),fst(:)
real,       allocatable :: fgrid_im(:),fgrid(:,:),dv01(:),dv02(:),dv03(:),dv04(:)
real,       allocatable :: t2m_dv(:),t2m_dvm06(:),weight(:)
real,       allocatable :: ens_avg(:),ens_spr(:),anl_bias(:)
real,       allocatable :: prob_10(:),prob_90(:),prob_mode(:),prob_50(:)
real        avg,spr,epdf

double precision,allocatable :: fstd(:)
double precision prob10,prob90,prob50,mode

integer     ifile,cfile,ofile,ii,idxjug,ipdtnum_out,refhr
integer     maxgrd,ndata,iunit                                
integer     index,j,n,iret,jret             
integer     nfiles,iskip(nmemd),tmems,oskip,nunit(nmemd),nunitdv(4)
integer     lfopg1,lfopg2,lfopg3,lfopg4,lfopg5,lfopg6,fhrst,fhrend
integer     icfopg1,icfopg2,icfopg3,icfopg4,icfopg5,icfopg6
character*40 cfipg(nmemd)
character*80 cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6,variable
character*80 cfipgdv1,cfipgdv2,cfipgdv3,cfipgdv4

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer ipd1,ipd2,ipd10,ipd11,ipd12

integer ifallcmc,ifallfnmoc

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

! variables: t2m,tmax,tmin

!data ipd1 /  0,  0,  0/
!data ipd2 /  0,  4,  5/
!data ipd10/103,103,103/
!data ipd11/  0,  0,  0/
!data ipd12/  2,  2,  2/

namelist /namens/cfipg,iskip,nfiles,cfipgdv1,cfipgdv2,cfipgdv3,cfipgdv4,cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6,oskip,variable,tmems,fhrst,fhrend

read(5,namens,end=1020)
write(6,namens)

ifallcmc=0

inum=0
do ifile=1,nfiles
  if(iskip(ifile).eq.1) inum=inum+1
enddo

if(inum.lt.3) goto 1040

if(variable.eq.'tmax') then
  ipd1=0
  ipd2=4
  ipd10=103
  ipd11=0
  ipd12=2
endif

if(variable.eq.'tmin') then
  ipd1=0
  ipd2=5
  ipd10=103
  ipd11=0
  ipd12=2
endif

print *, ' variable = ',variable
print *, 'Input files include '

iunit=10

! input GEFS & CMCE ensemble forecasat that are saved in a file for different lead time  

do ifile=1,nfiles
  iunit=iunit+1
  nunit(ifile)=iunit
  print *, 'fort.',iunit, trim(cfipg(ifile))
  if(iskip(ifile).eq.1) then
    call baopenr(iunit,trim(cfipg(ifile)),iret)
    if(iret.ne.0) then
      print *,'there is no NAEFS forecast, ifile,iret = ',cfipg(ifile),iret
      iskip(ifile)=0
    endif
  endif
enddo

! input 4 cycle downscaling vector files    

iunit=iunit+1
nunitdv(1)=iunit
call baopenr(iunit,trim(cfipgdv1),iret)
print *, 'fort.',iunit, trim(cfipgdv1)

iunit=iunit+1
nunitdv(2)=iunit
call baopenr(iunit,trim(cfipgdv2),iret)
print *, 'fort.',iunit, trim(cfipgdv2)

iunit=iunit+1
nunitdv(3)=iunit
call baopenr(iunit,trim(cfipgdv3),iret)
print *, 'fort.',iunit, trim(cfipgdv3)

iunit=iunit+1
nunitdv(4)=iunit
call baopenr(iunit,trim(cfipgdv4),iret)
print *, 'fort.',iunit, trim(cfipgdv4)

! set output file

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
call getgb2(14,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1020

if(iret.eq.0) maxgrd=gfld%ngrdpts
if(gfld%ipdtmpl(17).ge.21) ifallcmc=1
call gf_free(gfld)

allocate (fgrid(maxgrd,tmems),fgrid_im(maxgrd),fstd(tmems),fst(tmems),weight(tmems))
allocate (dv01(maxgrd),dv02(maxgrd),dv03(maxgrd),dv04(maxgrd),anl_bias(maxgrd))
allocate (t2m_dv(maxgrd),t2m_dvm06(maxgrd),t2m_m06(maxgrd),t2m(maxgrd))
allocate (ens_avg(maxgrd),ens_spr(maxgrd),tmax(maxgrd),tmin(maxgrd))
allocate (prob_10(maxgrd),prob_50(maxgrd),prob_90(maxgrd),prob_mode(maxgrd))

! get initialized downscaling vector

print *, '   '
print *, '----- Downscaling Vector for t2m -----'

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
ipdt(1)=0;ipdt(2)=0;ipdt(10)=103;ipdt(11)=0;ipdt(12)=2
ipdtn=1; igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(nunitdv(1),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) dv01=0.0
if(iret.ne.0) print *, 'there is no downscaling vector for 01 '
if(iret.eq.0) dv01(1:maxgrd)=gfld%fld(1:maxgrd)
if(iret.eq.0) call printinfr(gfld,1)
call gf_free(gfld)

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(nunitdv(2),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) dv02=0.0
if(iret.ne.0) print *, 'there is no downscaling vector for 02 '
if(iret.eq.0) dv02(1:maxgrd)=gfld%fld(1:maxgrd)
if(iret.eq.0) call printinfr(gfld,2)
call gf_free(gfld)

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(nunitdv(3),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) dv03=0.0
if(iret.ne.0) print *, 'there is no downscaling vector for 03 '
if(iret.eq.0) dv03(1:maxgrd)=gfld%fld(1:maxgrd)
if(iret.eq.0) call printinfr(gfld,3)
call gf_free(gfld)

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(nunitdv(4),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) dv04=0.0
if(iret.ne.0) print *, 'there is no downscaling vector for 04 '
if(iret.eq.0) dv04(1:maxgrd)=gfld%fld(1:maxgrd)
if(iret.eq.0) call printinfr(gfld,4)
call gf_free(gfld)

inum=0

! outmost loop for 2 varlables: tmax & tmin 

do imem=1,tmems 

  print *, '   '
  print '(a48,i3,a8)', '----- Downscling Tmax or Tmin Start for Member ',imem,'  ------'
  print *, '   '

  tmax=0
  tmin=999

  idxjug=1

  do ifile=2,nfiles

    print '(a48,i3,a10,i3)', '----- Downscling Tmax or Tmin Start for Member ',imem,' and file ',ifile
    print *, '   '

    ! read and process variable of input data

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1

    ipdt(1)=ipd1;ipdt(2)=ipd2;ipdt(10)=ipd10;ipdt(11)=ipd11;ipdt(12)=ipd12

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

    ! NCEP adds 10 members withwipdt(17) from 1 to 30, CMC has ipdt(17) from 21 to 40  
    ! after reading NCEP 30 members, adjust ipdt(17) starting with 21 for CMC ensemble

    if(imem.gt.30) then
       ipdt(17)=imem
       iids(1)=54    
    endif

    ! get operational forecast tmax or tmin

    if(iskip(ifile).eq.0) goto 100
    if(iskip(ifile-1).eq.0) goto 100

    ipdtn=11; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(nunit(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if(iret.ne.0) print *, 'there is no Tmax or Tmin for member ',imem
    if(iret.ne.0) goto 100 

    print *, '----- Operational Tmax or Tmin Forecast for Current Time ------'

    call printinfr(gfld,imem)

    fgrid_im(1:maxgrd)=gfld%fld(1:maxgrd)

    ! get operational forecast t2m 6h ago

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1
    ipdt(1)=0;ipdt(2)=0;ipdt(10)=103;ipdt(11)=0;ipdt(12)=2
    ipdtn=1; igdtn=-1

    ! read and process input member for NCEP 30 members               

    if(imem.le.30) then
      ipdt(17)=imem   
      iids(1)=7    
    endif

    ! check if all member are from cmc ensmeble 

    if(imem.le.20.and.ifallcmc.eq.1) ipdt(17)=20+imem

    if(imem.gt.30) then
       ipdt(17)=imem
       iids(1)=54    
    endif

    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(nunit(ifile-1),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    print *, '----- Ensemble Forecast T2m 6 hour ago ------'

    if(iret.ne.0) print *, ' there is no Ensemble Forecast T2m 6 hour ago '
    if(iret.ne.0) goto 100 

    call printinfr(gfld,imem)
    t2m_m06(1:maxgrd)=gfld%fld(1:maxgrd)

    ! get operational forecast t2m current time

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1
    ipdt(1)=0;ipdt(2)=0;ipdt(10)=103;ipdt(11)=0;ipdt(12)=2
    ipdtn=1; igdtn=-1

    ! read and process input member for NCEP 30 members               

    if(imem.le.30) then
      ipdt(17)=imem   
      iids(1)=7    
    endif

    ! check if all member are from cmc ensmeble 

    if(imem.le.20.and.ifallcmc.eq.1) ipdt(17)=20+imem

    if(imem.gt.30) then
       ipdt(17)=imem   
       iids(1)=54     
    endif

    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(nunit(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    print *, '----- Ensemble Forecast T2m Current Time ------'
    if(iret.ne.0) goto 100 

    call printinfr(gfld,imem)
    t2m(1:maxgrd)=gfld%fld(1:maxgrd)

    ! get NCEP & CMC t2m downscaling vector 6 hour ago 

    if(ifile.eq.2) then
      t2m_dvm06=dv01
      t2m_dv=dv02
    endif

    if(ifile.eq.3) then
      t2m_dvm06=dv02
      t2m_dv=dv03
    endif

    if(ifile.eq.4) then
      t2m_dvm06=dv03
      t2m_dv=dv04
    endif

    if(ifile.eq.5) then
      t2m_dvm06=dv04
      t2m_dv=dv01
    endif

    print *, '----- NCEP & CMC T2m Downscaling Vector 6 Hour Ago ------'
    call message(t2m_dvm06,maxgrd,imem)

    ! get NCEP & CMC T2m downscaling vector

    print *, '----- NCEP & CMC T2m Downscaling Vector for Current Cycle ------'
    call message(t2m_dv,maxgrd,imem)

    ! calculate donwnscaling vector of tmax tmin 

    print *, '----- NCEP & CMC Downscaling Vector for Tmax or Tmin ------'
    call biastmaxtmin(fgrid_im,t2m_m06,t2m,t2m_dvm06,t2m_dv,anl_bias,maxgrd)
    call message(anl_bias,maxgrd,imem)

    goto 300

    200 continue
    anl_bias=0.0

    300 continue

    ! apply downscaling approach

    call debias(anl_bias,fgrid_im,maxgrd)

    gfld%fld(1:maxgrd)=fgrid_im(1:maxgrd)

    print *, '----- Downscaled Tmax or Tmin for Current Cycle ------'

    call printinfr(gfld,imem)

    ! compare the downscled forecast ( 3 files compararison) to get the maximum tmax 

    if(variable.eq."tmax") then
      do ii=1,maxgrd 
        if(fgrid_im(ii).gt.tmax(ii)) tmax(ii)=fgrid_im(ii)
      enddo
      gfld%fld(1:maxgrd)=tmax(1:maxgrd)
      print *, '----- Compared & Downscaled Tmax for Current Cycle ------'
      call printinfr(gfld,imem)
    endif

    if(variable.eq."tmin") then
      do ii=1,maxgrd 
        if(fgrid_im(ii).lt.tmin(ii)) tmin(ii)=fgrid_im(ii)
      enddo
      gfld%fld(1:maxgrd)=tmin(1:maxgrd)
      print *, '----- Compared & Downscaled Tmin for Current Cycle ------'
      call printinfr(gfld,imem)
    endif

    idxjug=0

    100 continue
    
    call gf_free(gfld)

  enddo        ! end of ifile

  ! set data for probability

  ! idxjug is to judge if the process to downscale each member tmax/tmin work sucessfully.

  if(idxjug.eq.0) then
    inum=inum+1
    if(variable.eq.'tmax') then
      fgrid(1:maxgrd,inum)=tmax(1:maxgrd)
    endif
    if(variable.eq.'tmin') then
      fgrid(1:maxgrd,inum)=tmin(1:maxgrd)
    endif
  endif

enddo          ! end of imem loop

! end of imem loop, calculate 10%, 50% and 90% probability

if(inum.eq.0) goto 1040

print *, 'inum= ',inum

print *, '   '
print *,  ' Combined Ensemble Data Example at Point 8601 '
write (*,'(10f8.1)') (fgrid(8601,i),i=1,inum)

do n=1,maxgrd

  fst(1:inum)=fgrid(n,1:inum)
  fstd(1:inum)=fgrid(n,1:inum)

  do i=1,inum
    weight(i)=1/float(inum)
  enddo

  ens_avg(n)=epdf(fst,weight,inum,1.0,0)
  ens_spr(n)=epdf(fst,weight,inum,2.0,0)

  call probability(fstd,inum,prob10,prob90,prob50)
  prob_10(n)=prob10
  prob_90(n)=prob90
  prob_50(n)=prob50

  if(prob_50(n).gt.-999.0.and.prob_50(n).lt.999999.0.and.ens_avg(n).gt.-999.0.and.ens_avg(n).lt.999999.0) then
    prob_mode(n)=3*prob_50(n)-2*ens_avg(n)
  else
    prob_mode(n)=-9999.99
  endif

! if(prob10.eq.0.0.or.prob90.eq.0.0.or.prob50.eq.0.0) then
!   print *, '   '
!   print *,  ' Sorted Ensemble Data Example at Point',n
!   write (*,'(10f8.2)') (fst(i),i=1,inum)
!   print *,  ' 10%, 90%, 50% Probability at Point',n
!   write (*,'(10f8.1)') prob_10(n),prob_90(n), prob_50(n)
! endif

enddo

print *, '   '

! get grib2 message from input file, the second input file, the time is the
! beginning time of tmax/tmin

!iret=-1
!do ifile=2,2
!  if(iskip(ifile).ne.0) then
!    iids=-9999;ipdt=-9999; igdt=-9999
!    idisc=-1;  ipdtn=-1;   igdtn=-1
!    ipdt(1)=ipd1
!    ipdt(2)=ipd2
!    ipdt(10)=ipd10
!    ipdt(12)=ipd12
!    ipdtn=11
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
!    call getgb2(nunit(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
!    refhr=gfldo%ipdtmpl(9)
!write(6,*) '0 nunit(ifile)=',nunit(2),iret
!    if(iret.ne.0) then
!      iids=-9999;ipdt=-9999; igdt=-9999
!      idisc=-1;  ipdtn=-1;   igdtn=-1
!      ipdt(1)=0
!      ipdt(2)=0
!      ipdt(10)=ipd10
!      ipdt(12)=ipd12
!      ipdtn=1
!      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
!      call getgb2(nunit(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
!      refhr=gfldo%ipdtmpl(9)
!    endif
!  endif
!enddo

iret=-1
do ifile=5,5
  if(iskip(ifile).ne.0) then
    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1
    ipdt(1)=ipd1
    ipdt(2)=ipd2
    ipdt(10)=ipd10
    ipdt(12)=ipd12
    ipdtn=11
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(nunit(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif
enddo

if(iret.ne.0) goto 1020

!400 continue

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

call change_template4(gfldo%ipdtnum,ipdtnum_out,gfldo%ipdtmpl,gfldo%ipdtlen)

! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

gfldo%idrtmpl(3)=2
gfldo%ipdtmpl(17)=inum   !PDT 4.12 number of forecasts in the ensemble

! gfldo%ipdtmpl(8): indicator of unit of time range
! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours

if(gfldo%ipdtmpl(8).eq.1) gfldo%ipdtmpl(9)=int(fhrst) 
if(gfldo%ipdtmpl(8).eq.10) gfldo%ipdtmpl(9)=int(fhrst/3) 
if(gfldo%ipdtmpl(8).eq.11) gfldo%ipdtmpl(9)=int(fhrst/6) 
if(gfldo%ipdtmpl(8).eq.12) gfldo%ipdtmpl(9)=int(fhrst/12) 

! gfldo%ipdtmpl(28): indicator of unit of time ranga for process
! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours
! gfldo%ipdtmpl(29): PDT 4.12 length of the time range for process

if(gfldo%ipdtmpl(8).eq.1) gfldo%ipdtmpl(29)=int((fhrend-fhrst)) 
if(gfldo%ipdtmpl(8).eq.10) gfldo%ipdtmpl(29)=int((fhrend-fhrst)/3) 
if(gfldo%ipdtmpl(8).eq.11) gfldo%ipdtmpl(29)=int((fhrend-fhrst)/6) 
if(gfldo%ipdtmpl(8).eq.12) gfldo%ipdtmpl(29)=int((fhrend-fhrst)/12) 

! extensions for 10% probability forecast
  
gfldo%ipdtnum=12         ! derived forecast
gfldo%ipdtmpl(16)=193    ! code table 4.7, Percentile value (10%) of All Members
gfldo%fld(1:maxgrd)=prob_10(1:maxgrd)

print *, '----- Probility 10% for Current Time ------'

call putgb2(icfopg1,gfldo,iret)
call printinfr(gfldo,0)

! extensions for 90% probability forecast

gfldo%ipdtnum=12         ! derived forecast
gfldo%ipdtmpl(16)=195    ! code table 4.7, Percentile value (90%) of All Members
gfldo%fld(1:maxgrd)=prob_90(1:maxgrd)

print *, '----- Probility 90% for Current Time ------'

call putgb2(icfopg2,gfldo,jret)
call printinfr(gfldo,0)

! extensions for 50% forecast

gfldo%ipdtnum=12         ! derived forecast
gfldo%ipdtmpl(16)=194    ! code table 4.7, Percentile value (50%) of All Members
gfldo%fld(1:maxgrd)=prob_50(1:maxgrd)

print *, '----- Probility 50% for Current Time ------'
call putgb2(icfopg3,gfldo,jret)
call printinfr(gfldo,0)

! extensions for mode forecast

gfldo%ipdtnum=12         ! derived forecast
gfldo%ipdtmpl(16)=192    ! code table 4.7, unweighted mode of all Members
gfldo%fld(1:maxgrd)=prob_mode(1:maxgrd)

print *, '-----  Probility Mode for Current Time ------'
call putgb2(icfopg6,gfldo,jret)
call printinfr(gfldo,0)

print *, '----- Output ensemble average and spread for Current Time ------'
print *, '   '

! extensions for ensemble mean

gfldo%ipdtnum=12         ! derived forecast
gfldo%ipdtmpl(16)=0      ! code table 4.7, unweighted mean of all Members
gfldo%fld(1:maxgrd)=ens_avg(1:maxgrd)

print *, '-----  Ensemble Average for Current Time ------'
call putgb2(icfopg4,gfldo,jret)
call printinfr(gfldo,0)

! extensions for ensemble spread

gfldo%ipdtnum=12         ! derived forecast
gfldo%ipdtmpl(16)=4      ! code table 4.7, spread of all Members
gfldo%fld(1:maxgrd)=ens_spr(1:maxgrd)

print *, '-----  Ensemble Spread for Current Time ------'
call putgb2(icfopg5,gfldo,jret)
call printinfr(gfldo,0)

call gf_free(gfldo)

! end of probability forecast calculation               

call baclose(ifile,iret)
call baclose(cfile,iret)
call baclose(ofile,iret)

print *,'Downscaling Process Successfully Complete'

stop

1020  continue
print *,'Wrong Data Input, Output or Wrong Message Input'
stop

1040  continue
print *,'There is no Enough members Input, Stop!'
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

subroutine biastmaxtmin(fgrid,t2m_cmcm06,t2m_cmc,t2m_biasm06,t2m_bias,anl_bias,maxgrd)

! calculate Tmax and Tmin bias
!
!         bias=a*t2m_biasm06+b*t2m_bias
!
! input
!        fgrid       ---> tmax or tmin forecast
!        t2m_cmcm06  ---> t2m ensemble forecas 6hr ago
!        t2m_cmc     ---> t2m ensemble forecast
!        t2m_biasm06 ---> t2m analysis difference 6hr ago
!        t2m_bias    ---> t2m analysis difference
!        maxgrid ---> number of grid points in the defined grid
!
!   output
!        anl_bias ---> Tmax and Tmin bias estimation
!

implicit none

integer maxgrd,ij
real t2m_biasm06(maxgrd),t2m_bias(maxgrd),t2m_cmc(maxgrd),t2m_cmcm06(maxgrd)
real fgrid(maxgrd),anl_bias(maxgrd)
real lmta,ym,y0,y1,a,b

!print *, 'in tmaxtmin'
! print *, 't2m_biasm06=',t2m_biasm06(8601),' t2m_bias(ij)=',t2m_bias(8601) 
! print *, 't2m_cmc=',t2m_cmc(8601),' t2m(ij)=',t2m_cmcm06(8601) 

do ij=1,maxgrd
  ym=fgrid(ij)
  y0=t2m_cmcm06(ij)
  y1=t2m_cmc(ij)
  if(ym.gt.-9999.0.and.ym.lt.999999.0.and.y0.gt.-9999.0.and.y0.lt.999999.0.and.y1.gt.-9999.0.and.y1.lt.999999.0) then
    if(ym.ne.y1.and.ym.ne.y0) then
      lmta=sqrt(abs((ym-y0)/(ym-y1)))
      a=lmta/(1+lmta)
      b=1/(1+lmta)
    else
      if(ym.eq.y1.and.ym.ne.y0) then
        a=0.0
        b=1.0
      endif
      if(ym.eq.y1.and.ym.eq.y0) then
        a=0.5
        b=0.5
      endif
      if(ym.ne.y1.and.ym.eq.y0) then
        a=1.0
        b=0.0
      endif
    endif
  endif
  anl_bias(ij)=b*t2m_biasm06(ij)+a*t2m_bias(ij)
! if(ij.eq.8601) then 
!  print *, 'a=',a,' b=', b, ' bias=', anl_bias(ij)
!  print *, 't2m_biasm06=',t2m_biasm06(ij),' t2m_bias(ij)=',t2m_bias(ij) 
! endif
enddo

!print *, 'in tmaxtmin'

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









