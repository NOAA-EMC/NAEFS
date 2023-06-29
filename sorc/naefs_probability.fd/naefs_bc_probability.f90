        program naefs_bc_probability_g2
!
! main program: naefs_bc_probability_g2
!
! prgmmr: Bo Cui           org: Bo.Cui      date: 2013-10-01
!
! abstract: calculate 10%,50% & 90% probability forecast, ensemble mean, & spread of
!           ensemble NCEP, CMC or NAEFS
! 
!            modification: use accumulated analysis difference to adjust CMC ensemble
!            modification: set NAEFS product ID as 114 
!                          set GEFS product ID as 107 that pass from bias-corrected product directly
!           add 13 new variables for bias estimation (H, T, U, V at 100mb 50mb 10mb and VVEL)
!           calculate and output 2m dew point temperature and 2m relative humidity (+2 variables)
!
! usage:
!
!   input file: ncep/cmc/fnmoc ensemble forecast                                          
!             : ncep/cmc accumulated analysis difference
!             : ncep/cmc accumulated analysis difference 6 hour ago
!             : cmc ensemble forecast t2m
!             : cmc ensemble forecast t2m 6 hour ago
!             : ncep/fnmoc accumulated analysis difference
!             : ncep/fnmoc accumulated analysis difference 6 hour ago
!             : fnmoc ensemble forecast t2m
!             : fnmoc ensemble forecast t2m 6 hour ago
!
!   output file: 10%, 50%, 90% and mode probability forecast
!              : ensemble mean and spread
!
!   parameters
!     nvar  -      : number of variables
!

!   2m dew point temperature and 2m relative humidity process
!
!      step 1. read in 2m dew point temperature of NCEP/GEFS and CMC/GEFS ensembles, adjust 
!              CMC/FNMOC each member's dpt2m,combine NCEP and adjusted CMC 2m dew point temperature
!              to generate the mean, spread, mode, 10%, and etc.
!           2. compare the mean, mode, 10%, 50% and 90% of 2m temperature and 2m dew point
!              temperature, make sure the values of 2m temperature are smaller than 2m dew
!              point temperature
!           3. use adjusted CMC 2m temperature and 2m dew point temperature to get new CMC 2m
!              relative humidity, combine NCEP and CMC new 2m relative humidity to generate the
!              mean, spread, mode, 10%, 50% and 90% forecast.
!           4. adjust the mean, spread, mode, 10%, 50% and 90% values of rh to make sure these values
!              are not larger than 100%
!              or smaller than 0%

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgbeh          grib reader
!   getgbe           grib reader
!   putgbe           grib writer

! exit states:
!   cond =   0 - successful run
!   cond =   1 - I/O abort
!
! attributes:
!   language: fortran 90
!
!$$$

!use naefs_mod

use grib_mod
use params

!implicit none

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer     nmemd,nmvar,nvar,ivar,i,k,im,imem,n,inum,ignum,ii
parameter   (nmemd=62,nmvar=52)

real,       allocatable :: fgrid_im(:),fgrid(:,:),fst(:),fgrid_t2m(:)
real,       allocatable :: ens_avg(:),ens_spr(:)
real,       allocatable :: anl_bias_cmc(:),t2m_bias_cmc(:),t2m_biasm06_cmc(:)
real,       allocatable :: t2m_cmc(:),t2m_cmcm06(:)
real,       allocatable :: anl_bias_fnmoc(:),t2m_bias_fnmoc(:),t2m_biasm06_fnmoc(:)
real,       allocatable :: t2m_fnmoc(:),t2m_fnmocm06(:)
real,       allocatable :: prob_10(:),prob_90(:),prob_mode(:),prob_50(:)
real,       allocatable :: prob_10_t2m(:),prob_90_t2m(:),prob_mode_t2m(:),prob_50_t2m(:),prob_avg_t2m(:)
logical(1), allocatable :: lbms(:),lbmsout(:)
real        dmin,dmax,avg,spr,weight(nmemd)
integer     maxgrd,ndata,ifhr
integer     index,j,iret,jret             

double precision,allocatable :: fstd(:)
double precision prob10,prob90,prob50,mode

integer     kens(5)
integer     ipdn(nmvar),ipdtnum_out
integer     ipd1(nmvar),ipd2(nmvar),ipd10(nmvar),ipd11(nmvar),ipd12(nmvar),mmod(nmvar)
integer     ipd11_cmc(nmvar), ipd12_cmc(nmvar)
integer     ipd11_new(nmvar), ipd12_new(nmvar)

character*10  ffd(nmvar)

! variables: u,v,t,h at 1000,925,850,700,500,250,200,100,50,10 mb,  &
!            slp pres t2m u10m v10m tmax tmin ULWRF(Surface) ULWRF(OLR) VVEL(850w)

integer     iret_ncep,iret_bias_cmc,iret_biasm06_cmc,ifdebias,iall_cmc,iall_fnmoc
integer     iret_bias_fnmoc,iret_biasm06_fnmoc
integer     iunit,lfipg(nmemd),lfipg1,lfipg2,lfipg3,lfipg4,lfipg5,lfipg6,icfipg(nmemd)
integer     icfipg1,icfipg2,icfipg3,icfipg4,icfipg5,icfipg6
integer     pidswitch,nfiles,iskip(nmemd),tfiles,ifile
integer     lfopg1,lfopg2,lfopg3,lfopg4,lfopg5,lfopg6
integer     icfopg1,icfopg2,icfopg3,icfopg4,icfopg5,icfopg6

character*150 cfipg(nmemd),cfipg1,cfipg2,cfipg3,cfipg4,cfipg5,cfipg6
character*150 cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6

namelist /namens/pidswitch,nfiles,ifdebias,iall_cmc,iall_fnmoc,iskip,cfipg,cfipg1,cfipg2,cfipg3, &
                 cfipg4,cfipg5,cfipg6,ifhr,cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6
namelist /varlist/ffd,ipdn,ipd1,ipd2,ipd10,ipd11,ipd12,mmod,nvar
 
read (5,namens)
!write (6,namens)

read (5,varlist)
!write(6,varlist)

print *, 'Input variables include '
print *, (ffd(i),i=1,nvar)

! stop this program if there is no enough files put in 

print *, ' '; print *, 'Input files size ', nfiles                  

if(iall_cmc.eq.1) print *, 'There is No NCEP GEFS Files'

if(iall_cmc.eq.1.and.iall_fnmoc.eq.1) print *, 'There is No NCEP and CMC GEFS Files'

if(nfiles.le.10) goto 1020 

! set the fort.* of intput file, open forecast files

print *, '   '
print *, 'Input files include '

iunit=9

tfiles=nfiles

do ifile=1,nfiles
  iunit=iunit+1
  icfipg(ifile)=iunit
  lfipg(ifile)=len_trim(cfipg(ifile))
  print '(a4,i3,a75)', 'fort.',icfipg(ifile), cfipg(ifile)(1:lfipg(ifile))
  call baopenr(icfipg(ifile),cfipg(ifile)(1:lfipg(ifile)),iret)
  if ( iret .ne. 0 ) then
    print *,'there is no NAEFS forecast, ifile,iret = ',cfipg(ifile)(1:lfipg(ifile)),iret
!   tfiles=nfiles-1
    iskip(ifile)=0
  endif
enddo

if(ifdebias.eq.1) then 

  ! set the fort.* of intput CMC t2m forecast 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg1=iunit
    lfipg1=len_trim(cfipg1)
    call baopenr(icfipg1,cfipg1(1:lfipg1),iret)
    print *, 'fort.',icfipg1, cfipg1(1:lfipg1)
    if(iret.ne.0) then
      print *,'there is no previous 6hr CMC forecast input',cfipg1(1:lfipg1)
    endif
  endif

  ! set the fort.* of intput NCEP & CMC analysis difference   

  iunit=iunit+1
  icfipg2=iunit
  lfipg2=len_trim(cfipg2)
  call baopenr(icfipg2,cfipg2(1:lfipg2),iret)
  print *, 'fort.',icfipg2, cfipg2(1:lfipg2)
  if(iret.ne.0) then
    print *,'there is no NCEP & CMC analysis bias input',cfipg2(1:lfipg2)
  endif

  ! set the fort.* of intput NCEP & CMC analysis difference 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg3=iunit
    lfipg3=len_trim(cfipg3)
    call baopenr(icfipg3,cfipg3(1:lfipg3),iret)
    print *, 'fort.',icfipg3, cfipg3(1:lfipg3)
    if(iret.ne.0) then
      print *,'there is no NCEP & CMC analysis bias (6h ago) input',cfipg3(1:lfipg3)
    endif
  endif

  ! set the fort.* of intput FNMOC t2m forecast 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg4=iunit
    lfipg4=len_trim(cfipg4)
    call baopenr(icfipg4,cfipg4(1:lfipg4),iret)
    print *, 'fort.',icfipg4, cfipg4(1:lfipg4)
    if(iret.ne.0) then
      print *,'there is no previous 6hr FNMOC forecast input',cfipg4(1:lfipg4)
    endif
  endif

  ! set the fort.* of intput NCEP & FNMOC analysis difference   

  iunit=iunit+1
  icfipg5=iunit
  lfipg5=len_trim(cfipg5)
  call baopenr(icfipg5,cfipg5(1:lfipg5),iret)
  print *, 'fort.',icfipg5, cfipg5(1:lfipg5)
  if(iret.ne.0) then
    print *,'there is no NCEP & FNMOC analysis bias: ',cfipg5(1:lfipg5)
  endif

  ! set the fort.* of intput NCEP & FNMOC analysis difference 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg6=iunit
    lfipg6=len_trim(cfipg6)
    call baopenr(icfipg6,cfipg6(1:lfipg6),iret)
    print *, 'fort.',icfipg6, cfipg6(1:lfipg6)
    if(iret.ne.0) then
      print *,'there is no NCEP & FNMOC analysis bias (6h ago): ',cfipg6(1:lfipg6)
    endif
  endif

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

! find grib message, maxgrd: number of grid points in the defined grid

do ifile=1,tfiles
  if(iskip(ifile).ne.0) then 
    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    maxgrd=gfld%ngrdpts
    call gf_free(gfld)
    if(iret.eq.0) goto 100
  endif       
enddo

100 continue

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1020

! get NCEP ensemble ipdt message: fixed surface and its scaled value

do ifile=1,tfiles
  if(iskip(ifile).eq.1) then 
    call getipdt_g2_surface(icfipg(ifile),nmvar,ipd1,ipd2,ipd10,ipd11,ipd12,ipd11_new,ipd12_new)
    ipd11=ipd11_new
    ipd12=ipd12_new
    go to 120
  endif
enddo

120 continue

! get CMC ensemble ipdt message: fixed surface and its scaled value

do ifile=1,tfiles
  if(iskip(ifile).eq.2) then 
    call getipdt_g2_surface(icfipg(ifile),nmvar,ipd1,ipd2,ipd10,ipd11,ipd12,ipd11_new,ipd12_new)
    ipd11_cmc=ipd11_new
    ipd12_cmc=ipd12_new
    go to 140
  endif
enddo

140 continue

allocate (fgrid(maxgrd,tfiles),fgrid_im(maxgrd),fstd(tfiles),fst(tfiles),                   &
          prob_10(maxgrd),prob_50(maxgrd),prob_90(maxgrd),prob_mode(maxgrd),ens_avg(maxgrd),&
          prob_10_t2m(maxgrd),prob_50_t2m(maxgrd),prob_90_t2m(maxgrd),prob_mode_t2m(maxgrd),&
          prob_avg_t2m(maxgrd),t2m_bias_fnmoc(maxgrd),                                      &
          ens_spr(maxgrd),anl_bias_cmc(maxgrd),t2m_bias_cmc(maxgrd),t2m_cmc(maxgrd),        &
          t2m_biasm06_cmc(maxgrd),t2m_cmcm06(maxgrd),anl_bias_fnmoc(maxgrd),                &
          t2m_fnmoc(maxgrd),t2m_biasm06_fnmoc(maxgrd),t2m_fnmocm06(maxgrd))

print *, '   '

! loop over variables

t2m_bias_cmc=0.0
t2m_biasm06_cmc=0.0
t2m_bias_fnmoc=0.0
t2m_biasm06_fnmoc=0.0

do ivar = 1, nvar  

  print *, '----- Start NCEP/CMC/FNMOC Ensemble Combination For Variable ',ffd(ivar),'------'
  print *, '   '

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(12)=ipd12(ivar)

  fgrid=-9999.9999

  inum=0
  iret_ncep=0
  iret_bias_cmc=0
  iret_bias_fnmoc=0
  iret_biasm06_cmc=0
  iret_biasm06_fnmoc=0

  ! judge if need to adjust CMC and FNMOC ensembles

  if(ifdebias.eq.1) then 

    ! get NCEP & CMC analysis bias data
    ! there is no Tmax and Tmin from CMC/NCEP analysis difference, don't read them

    iret_bias_cmc=0

    if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      print *, ' '; print *, '----- No NCEP & CMC Analysis Bias for Tmax ------'
      anl_bias_cmc=0.0
    elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      print *, ' '; print *, '----- No NCEP & CMC Analysis Bias for Tmin ------'
      anl_bias_cmc=0.0
    else
      igdtn=-1; ipdtn=ipdn(ivar)
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(icfipg2,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_bias_cmc)
      if(iret_bias_cmc.ne.0) then
        print '(a36,4i7)', 'there is no CMC analysis bias for ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
        anl_bias_cmc=0.0
      else
        print *, '   '; print *, '----- NCEP & CMC Analysis Bias for Current Cycle ------'
        call printinfr(gfld,ivar)
        anl_bias_cmc(1:maxgrd)=gfld%fld(1:maxgrd)
      endif
    endif

    call gf_free(gfld)

    ! get NCEP & FNMOC analysis bias data
    ! there is no Tmax and Tmin from FNMOC/NCEP analysis difference, don't read them

    iret_bias_fnmoc=0

    if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      print *, ' '; print *, '----- No NCEP & FNMOC Analysis Bias for Tmax ------'; print *, ' '
      anl_bias_fnmoc=0.0
    elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      print *, ' '; print *, '----- No NCEP & FNMOC Analysis Bias for Tmin ------'; print *, ' '
      anl_bias_fnmoc=0.0
    else
      igdtn=-1; ipdtn=ipdn(ivar)
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(icfipg5,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_bias_fnmoc)
      if(iret_bias_fnmoc.ne.0) then
        print '(a36,4i7)', 'No FNMOC Analysis Bias for ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
        print *, ' '
        anl_bias_fnmoc=0.0
      else
        print *, '   '; print *, '----- NCEP & FNMOC Analysis Bias for Current Cycle ------'
        anl_bias_fnmoc(1:maxgrd)=gfld%fld(1:maxgrd)
        call printinfr(gfld,ivar)
      endif
    endif

    call gf_free(gfld)

  endif

  ! loop over NAEFS members, get operational ensemble forecast

  print *, '----- NCEP/CMC/FNMOC Ensemble Forecast for Current Time ------'; print *, '   '

  do imem=1,nfiles 

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1

    ipdt(1)=ipd1(ivar)
    ipdt(2)=ipd2(ivar)
    ipdt(10)=ipd10(ivar)
    ipdt(12)=ipd12(ivar)

    fgrid_im=-9999.9999

    ! check how many cneter ensmebles are read
    ! mmod(ivar)=0, no this variable
    ! mmod(ivar)=1, only NCEP/GEFS
    ! mmod(ivar)=2, NCEP/GEFS + CMC/GEFS
    ! mmod(ivar)=3, NCEP/GEFS + CMC/GEFS + FNMOC/GEFS
    ! iskip(imem)=1,ensemble from NCEP
    ! iskip(imem)=2,ensemble from CMC 
    ! iskip(imem)=3,ensemble from FNMOC

    if(mmod(ivar).eq.0)  goto 200
    if(iskip(imem).eq.0) goto 200
    if(mmod(ivar).eq.1.and.iskip(imem).eq.2) goto 200
    if(mmod(ivar).eq.1.and.iskip(imem).eq.3) goto 200
    if(mmod(ivar).eq.2.and.iskip(imem).eq.3) goto 200

    if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      if(iskip(imem).eq.2) then
        print *, ' '
        print*, 'Start to Calcualte CMC Dew Point Temperature Forecast '; print *, ' '
!       call getipdt_cmc(ipd11(ivar),ipd12(ivar),ipd11_cmc,ipd12_cmc)
        ipdt(11)=ipd11_cmc(ivar)
        ipdt(12)=ipd12_cmc(ivar)
        igdtn=-1; ipdtn=ipdn(ivar)
        call get_dpt_g2(icfipg(imem),maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
      elseif(iskip(imem).eq.3) then
        print *, ' '
        print*, 'Start to Calcualte FNMOC Dew Point Temperature Forecast '; print *, ' '
        igdtn=-1; ipdtn=ipdn(ivar)
        call get_dpt_g2(icfipg(imem),maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
      elseif(iskip(imem).eq.1) then
        igdtn=-1; ipdtn=ipdn(ivar)
        call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
        call getgb2(icfipg(imem),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
      endif
    elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
      if(iskip(imem).eq.2) then
!       ipdt(11)=ipd11_cmc(ivar)
!       ipdt(12)=ipd12_cmc(ivar)
        igdtn=-1; ipdtn=ipdn(ivar)
        print *, ' '
        print*, 'Start to Calcualte CMC 10m Wind Speed '; print *, ' '
        call get_wspd10m(icfipg(imem),maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
      elseif(iskip(imem).eq.1) then
        igdtn=-1; ipdtn=ipdn(ivar)
        call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
        call getgb2(icfipg(imem),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
      endif
    else
      if(iskip(imem).eq.2) then
!       call getipdt_cmc(ipd11(ivar),ipd12(ivar),ipd11_cmc,ipd12_cmc)
        ipdt(11)=ipd11_cmc(ivar)
        ipdt(12)=ipd12_cmc(ivar)
      endif
      igdtn=-1; ipdtn=ipdn(ivar)
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(icfipg(imem),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    endif

    if(iret.ne.0) print '(a12,4i7,a12,i4)', 'there is no ',jpdt(1),jpdt(2),jpdt(10),jpdt(12), &
                        ' for member ',imem

    ! judge if data come from right source

    ! %idsect(1)=  7: US National Weather Service - NCEP (WMC)
    ! %idsect(1) =54: Canadian Meteorological Service - Montreal (RSMC)s
    ! %idsect(1) =58: FNMOC
    ! %ipdtmpl(5)=114: NAEFS Products from joined NCEP,CMC global ensembles
    ! %ipdtmpl(5)=107: Global Ensemble Forecast System (GEFS)

    if(iret.eq.0) then
      if(iskip(imem).eq.2.and.gfld%idsect(1).ne.54) iret=99                           
      if(iskip(imem).eq.3.and.gfld%idsect(1).ne.58) iret=99                           
    endif

    if(iret.ne.0) call gf_free(gfld)
    if(iret.ne.0) goto 200

    ! print NCEP data message

    if (iskip(imem).eq.1) call printinfr(gfld,ivar)

    ! start CMC/FNMOC data processing
    ! invert & remove initial analyis difference between NCEP and CMC/FNMOC

    if (iskip(imem).eq.2.or.iskip(imem).eq.3) then
      call grid_cnvncep_g2(gfld,ivar)
    endif

    fgrid_im(1:maxgrd)=gfld%fld(1:maxgrd)

    ! adjust CMC ensemble forecast 

    if(ifdebias.eq.1.and.iskip(imem).eq.2) then 

      ! for cmc bias creected fcst, gfld%ipdtmpl(16)=4

      if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
        kens(1)=gfld%ipdtmpl(16)
        kens(2)=gfld%ipdtmpl(17)
        call debias_tmaxmin(fgrid_im,maxgrd,kens,icfipg1,icfipg(imem),icfipg3,icfipg2)
      elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
        kens(1)=gfld%ipdtmpl(16)
        kens(2)=gfld%ipdtmpl(17)
        call debias_tmaxmin(fgrid_im,maxgrd,kens,icfipg1,icfipg(imem),icfipg3,icfipg2)
      else
        call debias(anl_bias_cmc,fgrid_im,maxgrd)
      endif

      print *, '----- After Debias CMC Forecast for Current Time ------'

      gfld%fld(1:maxgrd)=fgrid_im(1:maxgrd)
      call printinfr(gfld,ivar)

    endif  !  end for ifdebias.eq.1 and iskip(imem).eq.2

    ! adjust FNMOC ensemble forecast 

    if(ifdebias.eq.1.and.iskip(imem).eq.3) then 

      if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
        kens(1)=gfld%ipdtmpl(16)
        kens(2)=gfld%ipdtmpl(17)
        call debias_tmaxmin(fgrid_im,maxgrd,kens,icfipg4,icfipg(imem),icfipg6,icfipg5)
      elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
        kens(1)=gfld%ipdtmpl(16)
        kens(2)=gfld%ipdtmpl(17)
        call debias_tmaxmin(fgrid_im,maxgrd,kens,icfipg4,icfipg(imem),icfipg6,icfipg5)
      else
        call debias(anl_bias_fnmoc,fgrid_im,maxgrd)
      endif

      print *, '----- After Debias FNMOC Forecast for Current Time ------'

      gfld%fld(1:maxgrd)=fgrid_im(1:maxgrd)
      call printinfr(gfld,ivar)

    endif    !  end for ifdebias.eq.1 and iskip(imem).eq.3

    call gf_free(gfld)

    inum=inum+1
    fgrid(1:maxgrd,inum)=fgrid_im(1:maxgrd)

    200 continue

  enddo          ! end of imem loop

  ! end of imem loop, calculate 10%, 50% and 90% probability

  print *, '   '; print *,ffd(ivar),' has member',inum; print *, '   '
  if(inum.le.10) goto 300

  print *, '   '; print *,  ' Combined Ensemble Data Example at Point 8601 '
  write (*,'(10f8.1)') (fgrid(8601,i),i=1,inum)
  print *, '   '

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

    if(prob_50(n).gt.-999.0.and.prob_50(n).lt.999999.0.and.  &
       ens_avg(n).gt.-999.0.and.ens_avg(n).lt.999999.0) then
      prob_mode(n)=3*prob_50(n)-2*ens_avg(n)
    else
      prob_mode(n)=-9999.99
    endif

    if(prob10.eq.0.0.or.prob90.eq.0.0.or.prob50.eq.0.0) then
      print *, '   '
      print *,  ' Sorted Ensemble Data Example at Point',n
      write (*,'(10f8.2)') (fstd(i),i=1,inum)
      print *,  ' 10%, 90%, 50% Probability at Point',n
      write (*,'(5f12.1)') prob_10(n),prob_90(n), prob_50(n),ens_avg(n),ens_spr(n)
      print *, '   '
    endif

  enddo

  print *, '   '


  ! save t2m and dpt2m and compare them to get reasonable dpt2m

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    prob_10_t2m=prob_10
    prob_90_t2m=prob_90
    prob_50_t2m=prob_50
    prob_mode_t2m=prob_mode
    prob_avg_t2m=ens_avg
  endif

  ! compare adjusted dpt2m and tmp2m to make sure the dpt2m the smaller values

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then

    print*, 'Before Adjusted DPT2m Forecast '; print *, ' '
    print*, ' ivar=',ivar
    call message(prob_10,maxgrd,ivar)                 
    call message(prob_50,maxgrd,ivar)                 
    call message(prob_90,maxgrd,ivar)                 
    call message(prob_mode,maxgrd,ivar)                 
    call message(ens_avg,maxgrd,ivar)                 
    call message(ens_spr,maxgrd,ivar)                 

    do ii=1,maxgrd
      prob_10(ii)=min(prob_10(ii),prob_10_t2m(ii))
      prob_90(ii)=min(prob_90(ii),prob_90_t2m(ii))
      prob_50(ii)=min(prob_50(ii),prob_50_t2m(ii))
      prob_mode(ii)=min(prob_mode(ii),prob_mode_t2m(ii))
      ens_avg(ii)=min(ens_avg(ii),prob_avg_t2m(ii))
    enddo

    print*, 'After Adjusted DPT2m Forecast '; print *, ' '
    call message(prob_10,maxgrd,ivar)                 
    call message(prob_50,maxgrd,ivar)                 
    call message(prob_90,maxgrd,ivar)                 
    call message(prob_mode,maxgrd,ivar)                 
    call message(ens_avg,maxgrd,ivar)                 
    call message(ens_spr,maxgrd,ivar)                 

  endif

  ! adjust relative humility, two ends are bounded (0,100)

  if(ipd1(ivar).eq.1.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print*, 'Before Adjusted RH Forecast '; print *, ' '
    call message(prob_10,maxgrd,ivar)
    call message(prob_50,maxgrd,ivar)
    call message(prob_90,maxgrd,ivar)
    call message(prob_mode,maxgrd,ivar)
    call message(ens_avg,maxgrd,ivar)
    call message(ens_spr,maxgrd,ivar)
    do ij=1,maxgrd
      if(prob_10(ij).lt.0.0) prob_10(ij)=0.0
      if(prob_10(ij).gt.100.0) prob_10(ij)=100.0
      if(prob_90(ij).lt.0.0) prob_90(ij)=0.0
      if(prob_90(ij).gt.100.0) prob_90(ij)=100.0
      if(prob_50(ij).lt.0.0) prob_50(ij)=0.0
      if(prob_50(ij).gt.100.0) prob_50(ij)=100.0
      if(prob_mode(ij).lt.0.0) prob_mode(ij)=0.0
      if(prob_mode(ij).gt.100.0) prob_mode(ij)=100.0
      if(ens_avg(ij).lt.0.0) ens_avg(ij)=0.0
      if(ens_avg(ij).gt.100.0) ens_avg(ij)=100.0
      if(ens_spr(ij).lt.0.0) ens_spr(ij)=0.0
      if(ens_spr(ij).gt.100.0) ens_spr(ij)=100.0
    enddo
    print*, 'After Adjusted RH Forecast '; print *, ' '
    call message(prob_10,maxgrd,ivar)
    call message(prob_50,maxgrd,ivar)
    call message(prob_90,maxgrd,ivar)
    call message(prob_mode,maxgrd,ivar)
    call message(ens_avg,maxgrd,ivar)
    call message(ens_spr,maxgrd,ivar)
  endif

  ! get grib2 message from input file 

  do ifile=1,tfiles
    if(iskip(ifile).ne.0) then
      iids=-9999;ipdt=-9999; igdt=-9999
      idisc=-1;  ipdtn=-1;   igdtn=-1
      ipdt(1)=ipd1(ivar)
      ipdt(2)=ipd2(ivar)
      ipdt(10)=ipd10(ivar)
      ipdt(12)=ipd12(ivar)
      ipdtn=ipdn(ivar)
      if(iskip(ifile).eq.2) then
        ipdt(11)=ipd11_cmc(ivar)
        ipdt(12)=ipd12_cmc(ivar)
        igdtn=-1; ipdtn=ipdn(ivar)
        ! there is no dpt2m from cmc bias corrected forecast
        if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
          ipdt(1)=0            
          ipdt(2)=0               
        endif
        ! there is no wspd10m from cmc bias corrected forecast
        if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
          ipdt(1)=2
          ipdt(2)=2
        endif
      endif
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(icfipg(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
      if(iret.ne.0) goto 500
      if(iret.eq.0) then       
        if(iskip(ifile).eq.2.or.iskip(ifile).eq.3) then
          call grid_cnvncep_g2(gfldo,ivar)
        endif
      endif
      if(iskip(ifile).eq.2) then
        gfldo%ipdtmpl(11)=ipd11(ivar)
        gfldo%ipdtmpl(12)=ipd12(ivar)
        ! there is no dpt2m from cmc bias corrected forecast, change ipdt from t2m to dpt
        if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
          gfldo%ipdtmpl(1)=0
          gfldo%ipdtmpl(2)=6
        endif
        ! there is no wspd10m from cmc bias corrected forecast, change ipdt from t2m to dpt
        if(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
          gfldo%ipdtmpl(1)=2
          gfldo%ipdtmpl(2)=1
        endif
      endif
      if(iret.eq.0) goto 400
    endif
    500 continue
  enddo

  400 continue

  ! save NCEP message for output. If no NCEP data, save CMC data message later
  ! idsect(1) is for product generation center
  ! ipdtmpl(5) is for generation process identifier

  ! %idsect(1)=  7: US National Weather Service - NCEP (WMC)
  ! %idsect(1) =54: Canadian Meteorological Service - Montreal (RSMC)s
  ! %ipdtmpl(5)=114: NAEFS Products from joined NCEP,CMC global ensembles
  ! %ipdtmpl(5)=107: Global Ensemble Forecast System (GEFS)

  if(pidswitch.eq.1) then
    gfldo%idsect(1)=7
    gfldo%ipdtmpl(5)=114
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

  ! extensions for 10% probability forecast
  
  gfldo%ipdtnum=ipdtnum_out          ! derived forecast

  gfldo%ipdtmpl(17)=inum   !PDT 4.2 Number of forecasts in the ensemble             

  gfldo%ipdtmpl(16)=193    ! code table 4.7, Percentile value (10%) of All Members

  gfldo%fld(1:maxgrd)=prob_10(1:maxgrd)

  print *, '----- Probility 10% for Current Time ------'

  call putgb2(icfopg1,gfldo,iret)
  call printinfr(gfldo,ivar)

  ! extensions for 90% probability forecast

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=23          !: OCT 44, Product identifier, ensemble forecast value for X% probability
! kensout(5)=90          !: OCT 45, Spatial Smoothing of Product or Probability (if byte 44 = 23), 90=90% probability 

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=195    ! code table 4.7, Percentile value (90%) of All Members

  gfldo%fld(1:maxgrd)=prob_90(1:maxgrd)

  print *, '----- Probility 90% for Current Time ------'

  call putgb2(icfopg2,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! extensions for 50% forecast

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=23          !: OCT 44, Product identifier, ensemble forecast value for X% probability
! kensout(5)=50          !: OCT 45, Spatial Smoothing of Product or Probability (if byte 44 = 23), 50=50% probability 

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=194    ! code table 4.7, Percentile value (50%) of All Members

  gfldo%fld(1:maxgrd)=prob_50(1:maxgrd)

  print *, '----- Probility 50% for Current Time ------'
  call putgb2(icfopg3,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! extensions for mode forecast

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=24          !: OCT 44, Product identifier, the ensemble mode forecast (mode = 3*medium - 2*mean)
! kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=192    ! code table 4.7, unweighted mode of all Members

  gfldo%fld(1:maxgrd)=prob_mode(1:maxgrd)

  print *, '-----  Probility Mode for Current Time ------'
  call putgb2(icfopg6,gfldo,jret)
  call printinfr(gfldo,ivar)

  print *, '----- Output ensemble average and spread for Current Time ------'
  print *, '   '

  ! extensions for ensemble mean

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=4           !: OCT 44, Product identifier, 4 = Weighted mean ( of bias corrected forecasts)
! kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=0      ! code table 4.7, unweighted mean of all Members

  gfldo%fld(1:maxgrd)=ens_avg(1:maxgrd)

  print *, '-----  Ensemble Average for Current Time ------'
  call putgb2(icfopg4,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! extensions for ensemble spread

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=11          !: OCT 44, Product identifier, 11 = Standard deviation with respect to ensemble mean 
! kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=4      ! code table 4.7, spread of all Members

  gfldo%fld(1:maxgrd)=ens_spr(1:maxgrd)

  print *, '-----  Ensemble Spread for Current Time ------'
  call putgb2(icfopg5,gfldo,jret)
  call printinfr(gfldo,ivar)

  call gf_free(gfldo)

  ! end of probability forecast calculation               

  300 continue

enddo 

! end of ivar loop                                      

! close files

do ifile=1,nfiles
  call baclose(icfipg(ifile),iret)
enddo

if(ifdebias.eq.1) then 
  call baclose(icfipg2,iret)
  call baclose(icfipg5,iret)
  if(ifhr.ge.6) then
    call baclose(icfipg1,iret)
    call baclose(icfipg3,iret)
    call baclose(icfipg4,iret)
    call baclose(icfipg6,iret)
  endif
endif

call baclose(icfopg1,iret)
call baclose(icfopg2,iret)
call baclose(icfopg3,iret)
call baclose(icfopg4,iret)
call baclose(icfopg5,iret)
call baclose(icfopg6,iret)

print *,'Probability Calculation Successfully Complete'

stop

1020  continue

print *, 'There is not Enough Files Input, Stop!'
!call errmsg('There is not Enough Files Input, Stop!')
!call errexit(1)

stop
end


subroutine debias(bias,fgrid,maxgrd)

!     apply the bias correction
!
!     parameters
!                  fgrid  ---> ensemble forecast
!                  bias   ---> bias estimation

implicit none

integer maxgrd,ij
real bias(maxgrd),fgrid(maxgrd)

do ij=1,maxgrd
  if(fgrid(ij).gt.-99999.0.and.fgrid(ij).lt.999999.0.and.bias(ij).gt.-99999.0.and.bias(ij).lt.999999.0) then
    fgrid(ij)=fgrid(ij)-bias(ij)
  else
    fgrid(ij)=fgrid(ij)
  endif
enddo

return
end


subroutine biastmaxtmin(fgrid,t2m_cmcm06,t2m_cmc,t2m_biasm06,t2m_bias,anl_bias,maxgrd)

!     get Tmax and Tmin bias 
!
!         bias=a*t2m_biasm06+b*t2m_bias
!
!     parameters
!                  fgrid        ---> tmax or tmin forecast
!                  t2m_cmcm06   ---> t2m ensemble forecas 6hr ago
!                  t2m_cmc    ---> t2m ensemble forecast 
!                  t2m_biasm06 ---> t2m analysis bias 6hr ago
!                  t2m_bias    ---> t2m analysis bias
!

implicit none

integer maxgrd,ij
real t2m_biasm06(maxgrd),t2m_bias(maxgrd),t2m_cmc(maxgrd),t2m_cmcm06(maxgrd)
real fgrid(maxgrd),anl_bias(maxgrd)
real lmta,ym,y0,y1,a,b

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
  anl_bias(ij)=a*t2m_biasm06(ij)+b*t2m_bias(ij)
!if(ij.eq.8601) then 
! print *, 'a=',a,' b=', b, ' bias=', anl_bias(ij)
! print *, 't2m_biasm06=',t2m_biasm06(ij),' t2m_bias(ij)=',t2m_bias(ij) 
!endif
enddo

!print *, 'in tmaxtmin'

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


subroutine message(grid,maxgrd,ivar)

! print data information

implicit none

integer    ivar,maxgrd,j
real       grid(maxgrd),dmin,dmax

dmin=grid(1)
dmax=grid(1)

do j=2,maxgrd
  if(grid(j).gt.dmax) dmax=grid(j)               
  if(grid(j).lt.dmin) dmin=grid(j)               
enddo

print*, 'Irec ndata   Maximun    Minimum   Example'
print '(i3,i8,3f10.2)',ivar,maxgrd,dmax,dmin,grid(8601)

print *, '   '

return
end
