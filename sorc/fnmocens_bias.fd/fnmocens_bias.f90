program cmcens_bias_g2
!
! main program: cmcens_bias_g2   
!
! prgmmr: Bo Cui           org: np/wx20        date: 2006-12-10
!                          mod: np/wx20        date: 2008-01-25
!                          mod: np/wx20        date: 2010-04_01
!                          mod:                date: 2013-12_01
!
!
! abstract: calculate and update bias estimation between FNMOC/CMC analysis and FNMOC/CMC ensemble forecast 
!           calculate and update bias estimation between CDAS reanalysis and FNMOC/CMC analysis 
!           calculate and update bias estimation between NCEP analysis and FNMOC/CMC analysis 
!           this code can be used for both FNMOC and CMC ensmeble
! 
!
! Attention      
!              add variable 2m dew point temperature and relative humility, calculate & output bias
!              calculate dew point temperature forecast from relative humidity and 2m temperature
!              then calculate the bias of 2m dew point temperature, 52 variables in total for bias estimation
!              51 variables for reanalysis difference (no 2m dpt)
!              49 variables for NCEP CMC analysis difference (no tmax,tmin and vvel)

! 
! for FNMOC ensemble:
!
!            1. FNMOC data Y dimension values go from south to north, the bias estimation output follow this way
!
!            2. Reanalysis difference between CDAS and FNMOC analysis is from south to north and saved in
!               /com/fnmoc/fens.PDYm2/CYC/pgrba. It is used to calculate anomaly forecast for each FNMOC member 
!
!            3. Analysis difference between NCEP and FNMOC analysis varies from north to south and is save in
!               /com/gens/prod/gefs.PDYm1/CYC/pgrba. It is used to adjust FNMOC when do multi-ensmeble combination 
!
!            4. Bias estimation: Variables ULWRF in FNMOC ensemble are instantaneous values ( different from NCEP/CMC ) 
!               For FNMOC, only 2 cycles (00z and 12z) are available, use the forecast of previous cycle as analysis. 
!
!               tmax & tmin are calculated by taking the mean of 6hr previous t2m bias and currrent t2m bias
!
!            5. Reanalysis difference: 48 variables, no ULWRF (top and sfc) because no ULWRF in anormaly forecasts 
!
!            6. Analysis difference between FNMOC and NCEP: output 46 variables, no tmax, tmin, ULWRFtop and ULWRFsfc
!
! modification ( Dec. 1, 2013)
!
!            1. bias estimation output: 46 varibales for 00hr and 48 variables for > 06hr
!               there is no rh and dpt for nogaps data, therefore, no rh2m and dpt2m for bias estimation  
!
!            2. there are no ULWRFtop and ULWRFsfc in FNMOC forecast, no bias estimation for the 2 variables
!
!            3. grib2 encode/decode
!
! for CMC ensemble:
!
!            1. CMC data Y dimension values go from south to north, the bias estimation output follow this way
!
!            2. Reanalysis difference between CDAS and CMC analysis is from south to north and saved in
!               /com/gens/cmce.PDYm2/CYC/pgrba. It is used to calculate anomaly forecast for each member 
!
!            3. Analysis difference between NCEP and CMC analysis varies from north to south and is save in
!               /com/gens/prod/gefs.PDY/CYC/pgrba. It is used to adjust FNMOC when do multi-ensmeble combination. 
!               calculated in job /nwprod/jobs/JGEFS_BIAS.sms.prod,  not job /nwprod/jobs/JCMC_ENS_BIAS.sms.prod
!
!            4. Bias estimation: ULWRF is 6hr average value and ULWRF at control f00hr is almost instantaneous value.
!               Therefore, choose 6hr forecast of previous cycle as the ULWRF analysis. For CMC, only 2 cycle
!               (00z and 12z) forecasts are available, use the cycle forecast of 12hr ago.
!
!               tmax & tmin are calculated by taking the mean of 6hr previous t2m bias and currrent t2m bias
!
!            5. Reanalysis difference: no ULWRF because there is no ULWRF in anormaly forecasts 
!
!            6. Analysis difference between NCEP and CMC analysis: 
!               calculated in job /nwprod/jobs/JGEFS_BIAS.sms.prod,  not job /nwprod/jobs/JCMC_ENS_BIAS.sms.prod
!

!              
! usage:
!
!   input file: grib
!     unit 11 -    : prior bias estimation                                               
!     unit 12 -    : analysis
!     unit 13 -    : analysis for Tmax, Tmin and ULWRF
!     unit 14 -    : operational forecast or CDAS reanalysis
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
!   grib_cnvfnmoc_g2 invert NCEP data and let it start from south to north
!   grib_cnvncep_g2  invert FNMOC/CMC data and let it start from north to south
!   get_dpt          calculate dew point temperature for given rh and tmp
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

integer      ivar,i,k,icstart,odate,id_center
!parameter   (nvar=52)

real,       allocatable :: agrid(:),fgrid(:),bias(:),rgrid(:)
real,       allocatable :: rh2m(:),tmp2m(:)
real,       allocatable :: t2m_bias(:),t2m_bias_m06(:)
real,       allocatable :: anl_ncep(:),anl_fnmoc(:)

real        dec_w

integer     ifile,afile,afile_m12,cfile,rfile,rfile_m06,ofile,bias_m06

integer     maxgrd,ndata,ifhr                                
integer     index,j,n,iret,iret_t2m,jret             
character*7 cfortnn
character*4 nens

namelist/message/icstart,nens,ifhr,dec_w,odate

read(5,message,end=1020)
write(6,message)

if(nens.ne.'mdf'.and.nens.ne.'anl') then

ifile=11
afile=12
afile_m12=13
cfile=14
bias_m06=15
ofile=51

! set the fort.* of intput files

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data, stop!'; endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',afile_m12
call baopenr(afile_m12,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data for ulwrf, stop!'; endif
!if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',cfile
call baopenr(cfile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no GEFS forecast data, stop!'; endif
if (iret .ne. 0) goto 1020

if(ifhr.ge.06) then
  write(cfortnn,'(a5,i2)') 'fort.',bias_m06
  call baopenr(bias_m06,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no GEFS forecast bias data 6 hour ago!'; endif
  !if (iret .ne. 0) goto 1020
endif

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

allocate (agrid(maxgrd),fgrid(maxgrd),bias(maxgrd))
allocate (rh2m(maxgrd),tmp2m(maxgrd))
allocate (t2m_bias(maxgrd),t2m_bias_m06(maxgrd))

do ivar = 1, nvar  

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 100
  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 100

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
    if(nens.eq.'avg') ipdtn=ipdnm(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12);print*, ' '
    if (iret.eq.0) then    
      bias(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      bias=0.0
    endif
  endif

  ! get ensemble forecast

  print *, '----- GEFS ensemble forecast for current Time ------'

  ! GEFS forecast; ipdnm for ensemble average forecast

  igdtn=-1
  if(nens.eq.'avg') ipdtn=ipdnm(ivar)

  call init_parm(ipdtn,ipdt,igdtn,igdt)
  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte GEFS Dew Point Temperature Forecast '; print *, ' '
    call get_dpt(cfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  else
    call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif

  if (iret.ne.0) then
     print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12);print *, ' '
     call gf_free(gfld)
  endif

  if (iret.ne.0) goto 100

  if (iret.eq.0) then
    call printinfr(gfldo,ivar)
    fgrid(1:maxgrd)=gfldo%fld(1:maxgrd)
  endif

  ! get analysis data

  print *, '----- Analysis for Current Time ------'

  igdtn=-1; ipdtn=ipdna(ivar)

  call init_parm(ipdtn,ipdt,igdtn,igdt)

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte Analysis Dew Point Temperature Forecast '; print *, ' '
    call get_dpt(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.1.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  elseif(ipd1(ivar).eq.5.and.ipd2(ivar).eq.193.and.ipd10(ivar).eq.8.and.ipd12(ivar).eq.0) then
    call getgb2(afile_m12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  else
    call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  endif

  if (iret.ne.0) then
     print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12);print *, ' '
     call gf_free(gfld)
  endif

  if (iret.ne.0) goto 100

  if (iret.eq.0) then
    call printinfr(gfld,ivar)
    agrid(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  call gf_free(gfld)

  ! apply the decay average

  call decay(bias,fgrid,agrid,maxgrd,dec_w)

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    t2m_bias(1:maxgrd)=bias(1:maxgrd)
    iret_t2m=0
  endif

  ! output bias estimation

  print *, '----- Output Bias Estimation for Current Time ------'

  gfldo%ipdtmpl(3)=6                !  gfldo%ipdtmpl(3)=6 GRIB2 Code Table 4.3 forecast error

  call putgb2(ofile,gfldo,jret)
  call printinfr(gfldo,ivar)

  100 continue

  call gf_free(gfldo)

! end of bias estimation 

enddo

! calculate the bias of Tmax and Tmin using 6h averaged t2m bias

if(ifhr.ge.06) then

  ipdt=-9999; igdt=-9999
  ipdt(1)=0; ipdt(2)=0; ipdt(10)=103; ipdt(11)=0; ipdt(12)=2
  igdtn=-1

  print *, '----- GEFS Ensemble Forecast T2m Bias 6 Hour Ago -----'
  print *, '   '

  ipdtn=2
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(bias_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if(iret.ne.0.and.iret_t2m.ne.0) then
    print *, 'There is No t2m Bias Estimation for Tmax or Tmin'
  elseif(iret.ne.0.and.iret_t2m.eq.0) then
    print *, 'There is No t2m Bias Estimation Input 6hr Ago, No Tmax or Tmin Bias'
  elseif(iret.eq.0.and.iret_t2m.ne.0) then
    print *, 'There is No t2m Bias Estimation Current Time No Tmax or Tmin Bias'
  elseif(iret.eq.0.and.iret_t2m.eq.0) then

    t2m_bias_m06(1:maxgrd)=gfld%fld(1:maxgrd)

    print *, '----- T2m Bias Estimation 6hr Ago -----'
    call printinfr(gfld,0)

!   print *, '----- T2m Bias Estimation Current Time -----'
!   call printinfr(gfld,0)

    bias(1:maxgrd)=0.5*(t2m_bias(1:maxgrd)+t2m_bias_m06(1:maxgrd))

  endif

  call gf_free(gfld)

  if(iret.ne.0.or.iret_t2m.ne.0) goto 350

  ! get tmax grib2 message from fnmoc ensemble mean (ipdtn=12)

  ipdt=-9999; igdt=-9999
  ipdt(1)=0; ipdt(2)=4; ipdt(10)=103; ipdt(11)=0; ipdt(12)=2
  igdtn=-1; ipdtn=12
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if(iret.ne.0) goto 350

  print *, '------ Output Tmax Message Reference  ------'
  call printinfr(gfldo,0)

  print *, '------ Output Bias Estimation for Tmax  ------'

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)
  gfldo%ipdtmpl(3)=6                !  gfldo%ipdtmpl(3)=6 GRIB2 Code Table 4.3 forecast error
  gfldo%ipdtmpl(1)=0      
  gfldo%ipdtmpl(2)=4     

  call putgb2(ofile,gfldo,jret)
  call printinfr(gfldo,46)

  call gf_free(gfldo) 

  ! get tmin grib2 message from fnmoc ensemble mean (ipdtn=12)

  ipdt=-9999; igdt=-9999
  ipdt(1)=0; ipdt(2)=5; ipdt(10)=103; ipdt(11)=0; ipdt(12)=2
  igdtn=-1; ipdtn=12
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if(iret.ne.0) goto 350

  print *, '------ Output Tmin Message Reference  ------'
  call printinfr(gfldo,0)

  print *, '------ Output Bias Estimation for Tmin  ------'

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)
  gfldo%ipdtmpl(3)=6                !  gfldo%ipdtmpl(3)=6 GRIB2 Code Table 4.3 forecast error
  gfldo%ipdtmpl(1)=0      
  gfldo%ipdtmpl(2)=5     

  call putgb2(ofile,gfldo,jret)
  call printinfr(gfldo,47)

  350 continue

  call gf_free(gfldo) 

endif

call baclose(ifile,iret)
call baclose(afile,iret)
call baclose(afile_m12,iret)
call baclose(cfile,iret)
call baclose(bias_m06,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Successfully Complete'

endif

if(nens.eq.'mdf') then

ifile=11
afile=12
rfile=13
rfile_m06=14
ofile=51

! set the fort.* of intput files

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data, stop!';  endif
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
id_center=gfld%idsect(1)
call gf_free(gfld)

if (iret .ne. 0) then; print*,' getgbeh ,afile,index,iret =',afile,index,iret; endif
if (iret .ne. 0) goto 1020

allocate (agrid(maxgrd),rgrid(maxgrd),bias(maxgrd))

do ivar = 1, nvar  

  ! tmax and tmin difference come from t2m 

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 300
  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 300

  ! skip rh2m and dpt2m

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 300
  if(ipd1(ivar).eq.1.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 300

  bias=0.0             
  agrid=-9999.9999
  rgrid=-9999.9999

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized bias estimation between CFS/CDAS and GDAS

  if(icstart.eq.1) then
    print *, '----- Cold Start for Bias Estimation between CDAS and GDAS -----'
    print*, '  '
    bias=0.0
  else
    print *, '----- Initialized Bias for Current Time -----'

    igdtn=-1
    ipdtn=ipdnr(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12);print*, ' '
    if (iret.eq.0) then
      bias(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      bias=0.0
      call gf_free(gfld)
    endif

  endif

  ! get FNMOC/CMC analysis data 

  print *, '----- FNMOC/CMC Analysis for Current Time ------'

  igdtn=-1; ipdtn=ipdna(ivar)

  ! CMC analysis has ipdn=1, the analysis come from pgrb2a after grib1 conversion 
  ! it has the same ipd11 and ipd12 as the NCEP

  if(id_center.eq.54) then
    ipdtn=ipdn(ivar)
!   ipdt(11)=ipd11_cmc(ivar)
!   ipdt(12)=ipd12_cmc(ivar)
  endif

  call init_parm(ipdtn,ipdt,igdtn,igdt)

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte GEFS Analysis Dew Point Temperature Forecast '; print *, ' '
    call get_dpt(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  else
    call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12);print *, ' '
    call gf_free(gfld)
  endif

  if (iret.ne.0) goto 300

  if (iret.eq.0) then
    call printinfr(gfld,ivar)
    agrid(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  call gf_free(gfld)

  ! get reanalysis data CFS/CDAS 

  igdtn=-1; ipdtn=ipdnr(ivar) 
  call init_parm(ipdtn,ipdt,igdtn,igdt)

  ! get tmax, tmin, ULWRF(sfc) and ULWRF(top) for 6hr forecast of previous cycle 
  ! ipdnr=8 for the 4 variables; ipdnr=0 for all the other variables

  print *, '----- CFS CDAS reanalysis for current Time ------'

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte CFS Dew Point Temperature Forecast '; print *, ' '
    call get_dpt(rfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
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

! judge if CFS analysis have same data format as the GEFS analysis

  if (iret.eq.0) then
    call grib_cnvfnmoc_g2(gfldo,ivar)
  endif

  rgrid(1:maxgrd)=gfldo%fld(1:maxgrd)

  ! apply the decay average

  call decay(bias,rgrid,agrid,maxgrd,dec_w)

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)

  print *, '----- Output Bias Estimation between CFS/CDAS and FNMOC/CMC Analysis ------'

  gfldo%ipdtmpl(3)=7                !  gfldo%ipdtmpl(3)=7 GRIB2 Code Table 4.3 analysis error

  call putgb2(ofile,gfldo,iret)
  call printinfr(gfldo,ivar)

! save the difference of t2m as tmin and tmax difference

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then

    ! get tmax grib2 message from cfs 6h forecast (ipdtn=8)

    ipdt=-9999; igdt=-9999
    ipdt(1)=0; ipdt(2)=4; ipdt(10)=103; ipdt(11)=0; ipdt(12)=2
    igdtn=-1; ipdtn=8
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(rfile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if(iret.ne.0) then
      print *, 'There is No Tmax Message Reference'
      call gf_free(gfld)
    endif

    if(iret.ne.0) goto 250
   
    ! judge if CFS analysis have same data format as the FNMOC/CMC analysis

    print *, '------ Output Tmax Message Reference  ------'
    call grib_cnvfnmoc_g2(gfld,0)

    print *, '------ Output Tmax Bias Estimation for Current Time  ------'

    gfld%fld(1:maxgrd)=bias(1:maxgrd)

    gfld%ipdtmpl(3)=7                !  gfld%ipdtmpl(3)=7 GRIB2 Code Table 4.3 analysis error

    call putgb2(ofile,gfld,jret)
    call printinfr(gfld,46)
    call gf_free(gfld)

    ! get tmin grib2 message from cfs 6h forecast (ipdtn=8)

    ipdt=-9999; igdt=-9999
    ipdt(1)=0; ipdt(2)=5; ipdt(10)=103; ipdt(11)=0; ipdt(12)=2
    igdtn=-1; ipdtn=8
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(rfile_m06,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if(iret.ne.0) then
      print *, 'There is No Tmin Message Reference'
      call gf_free(gfld)
    endif

    if(iret.ne.0) goto 250

    ! judge if CFS analysis have same data format as the FNMOC/CMC analysis

    print *, '------ Output Tmin Message Reference  ------'
    call grib_cnvfnmoc_g2(gfld,0)

    print *, '------ Output Tmin Bias Estimation for Current Time  ------'

    gfld%fld(1:maxgrd)=bias(1:maxgrd)

    gfld%ipdtmpl(3)=7                !  gfld%ipdtmpl(3)=7 GRIB2 Code Table 4.3 analysis error

    call putgb2(ofile,gfld,jret)
    call printinfr(gfld,47)
    call gf_free(gfld)

    250 continue

  endif

  call gf_free(gfldo)

  300 continue

! end of bias estimation between CDAS and GDAS 

enddo

call baclose(ifile,iret)
call baclose(afile,iret)
call baclose(rfile,iret)
call baclose(rfile_m06,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Between CDAS and GDAS Successfully Complete'

endif

if(nens.eq.'anl') then

ifile=11
afile=12
rfile=13
ofile=51

! set the fort.* of intput files

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data, stop!';  endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',rfile
call baopenr(rfile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no CMC analysis data, stop!'; endif
if (iret .ne. 0) goto 1020

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

allocate (anl_ncep(maxgrd),anl_fnmoc(maxgrd),bias(maxgrd),t2m_bias(maxgrd))
allocate (tmp2m(maxgrd),rh2m(maxgrd))

! output 46 variables for fnmoc, there are no tmax, tmin, ulwrf(sfc, top)

do ivar = 1, nvar  

  ! there are no Tmax and Tmin

! if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 500
! if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 500

  bias=0.0             
  anl_fnmoc=-9999.9999
  anl_ncep=-9999.9999

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized bias estimation between NCEP and FNMOC analysis

  if(icstart.eq.1) then
    print *, '----- Cold Start for Bias Estimation between NCEP and CMC analysis -----'
    print*, '  '
    bias=0.0
  else

    print *, '----- Initialized Bias for Current Time -----'

    igdtn=-1; ipdtn=ipdn(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) then
      print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if (iret.eq.0) then
      bias(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      bias=0.0
    endif

  endif

  ! get NCEP GDAS analysis data 

  igdtn=-1; ipdtn=ipdn(ivar)
  call init_parm(ipdtn,ipdt,igdtn,igdt)

  print *, '----- NCEP Analysis for Current Cycle ------'

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte NCEP Dew Point Temperature Analysis '; print *, ' '
    call get_dpt(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  else
    call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12);print *, ' '
    call gf_free(gfldo)
  endif

  if (iret.ne.0) goto 500

  if (iret.eq.0) then
    call printinfr(gfldo,ivar)
    anl_ncep(1:maxgrd)=gfldo%fld(1:maxgrd)
  endif

  ! get FNMOC analysis 

  igdtn=-1; ipdtn=ipdna(ivar)
  call init_parm(ipdtn,ipdt,igdtn,igdt)

  print *, '----- FNMOC Analysis for Current Cycle ------'

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte GEFS Dew Point Temperature Analysis '; print *, ' '
    call get_dpt(rfile,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
  else
    call getgb2(rfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12); print *, ' '
    call gf_free(gfldo)
  endif

  if (iret.ne.0) goto 500

  if (iret.eq.0) then
    call grib_cnvncep_g2(gfld,ivar)
    anl_fnmoc(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

   call gf_free(gfld)

  ! apply the decay average

  call decay(bias,anl_fnmoc,anl_ncep,maxgrd,dec_w)

  print *, '----- Output Bias Estimation between CMC and NCEP analysis ------'

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
call baclose(rfile,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Between CMC and NCEP Analysis Successfully Complete'

endif
stop

1020  continue

stop
end

subroutine decay(aveeror,fgrid,agrid,maxgrd,dec_w)

!   apply the decaying average scheme
!
!   input      
!            fgrid  ---> ensemble forecast
!            agrid  ---> analysis data
!            aveeror---> bias estimation
!            dec_w  ---> decay weight
!            maxgrid ---> number of grid points in the defined grid
!
!   output
!            fgrid  ---> adjusted ensemble forecast

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
  es=6.112 * exp((17.67 * T)/(T + 243.5))
  e=es*(RH/100.0)
  Td=log(e/6.112)*243.5/(17.67-log(e/6.112))+273.15
  dpt(ij)=min(T+273.15,Td)                 
enddo
 
return 
end
