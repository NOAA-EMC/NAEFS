program gefs_debias_g2   
!
! main program: gefs_debias_g2
!
! prgmmr: Bo Cui           org: np/wx20        date: 2006-12-10
!                          mod: np/wx20        date: 2007-07-27
!                          mod: np/wx20        date: 2008-09-11
!                          mod:                date: 2013-12-01
!                          mod: Bo Cui         date: 2014-11-01
!
! abstract: bias correct global ensemble forecast
!
! modification: 1. add hybrid method, combing bias corrected high resolution forecast GFS and NAEFS bias
!                  corrected forecast information for best guidance products
!               2. add more variables for bias estimation (+14)
!               3. add variable 2m dew point temperature and 2m relative humidity
!               4. add variable total cloud cover                                     
!
!
! Process to get bias corrected 2m dew point temperature and 2m relative humidity
!
!      1. read in 2m temperature and relative humidity from one ensemble member, GFS and control forecast,
!         calculate their 2m dew point temperature, respectively
!      2. read in bias estimation of 2m dew point temperature for one ensemble mean and GFS forecast
!      3. bias correct 2m dew point temperature by applying bias correction and dual resolution technique
!      4. adjust bias corrected 2m dew point temperature by comparing it with the bias corrected 2m dew point
!         temperature and choosing the smaller value
!
! usage:
!
!   input file: grib
!     unit 11 -    : GEFS ensmeble mean bias estimation                                               
!     unit 12 -    : GEFS one member forecast
!     unit 13 -    : GFS bias estimation
!     unit 14 -    : GFS high resolution forecast         
!     unit 15 -    : GEFS control forecast         
!
!   output file: grib
!     unit 51 -    : bias-corrected forecast  
!
!   parameters
!     fgrid_ens -      : one ensemble member's forecast
!     fgrid_ctl -      : ensemble control forecast
!     fgrid_gfs -      : GFS forecast
!     bias_ens  -      : GEFS ensemble mean bias estimation
!     bias_gfs  -      : GFS bias estimation
!     nvar      -      : number of variables

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib reader
!   putgb2           grib writer

!
! attributes:
!   language: fortran 90
!
!$$$

use naefs_mod

implicit none

integer     ivar,i,ij,icstart_ens,icstart_gfs
!parameter  (nvar=52)

real,       allocatable :: fgrid_ens(:),bias_ens(:)
real,       allocatable :: fgrid_gfs(:),bias_gfs(:)
real,       allocatable :: fgrid_ctl(:)
real,       allocatable :: t2m(:),td2m(:)
real        dmin,dmax,pi,weight

integer     ifile_ens,ibias_ens,ifile_gfs,ibias_gfs,ifile_ctl,ofile

! variables: u,v,t,h at 1000,925,850,700,500,250,200,100,50,10 mb,tmax,tmin,   &
!            slp,pres u10m v10m t2m,ULWRF(Surface),ULWRF(OLR),VVEL(850w), dpt2 rh2m
 
integer     maxgrd,ndata,nfhr,if_gfs                                
integer     index,j,n,iret,jret             
character*7 cfortnn

namelist/message/icstart_ens,icstart_gfs,nfhr,if_gfs

read(5,message,end=1020)
write(6,message)

ibias_ens=11
ifile_ens=12
ibias_gfs=13
ifile_gfs=14
ifile_ctl=15
ofile=51

! set the fort.* of intput files

if(icstart_ens.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ibias_ens
  call baopenr(ibias_ens,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no GEFS bias estimation'; endif
endif

write(cfortnn,'(a5,i2)') 'fort.',ifile_ens
call baopenr(ifile_ens,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no GEFS forecast'; endif
if (iret .ne. 0) goto 1020

if(nfhr.le.180) then

  if(icstart_gfs.eq.0) then
    write(cfortnn,'(a5,i2)') 'fort.',ibias_gfs
    call baopenr(ibias_gfs,cfortnn,iret)
    if (iret .ne. 0) then; print*,'there is no GFS bias estimation'; endif
  endif

  write(cfortnn,'(a5,i2)') 'fort.',ifile_gfs
  call baopenr(ifile_gfs,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no GFS forecast'; endif

endif

write(cfortnn,'(a5,i2)') 'fort.',ifile_ctl
call baopenr(ifile_ctl,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no GEFS control forecast'; endif
if (iret .ne. 0) goto 1020

! set the fort.* of output file

write(cfortnn,'(a5,i2)') 'fort.',ofile
call baopenw(ofile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no bias-corrected output, stop!'; endif
if (iret .ne. 0) goto 1020

! find grib message, maxgrd: number of grid points in the defined grid

ipdt=-9999; igdt=-9999
ipdtn=-1; igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(ifile_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
maxgrd=gfld%ngrdpts
call gf_free(gfld)

if (iret .ne. 0) then; print*,' getgbeh ,ifile_ens,index,iret =',ifile_ens,index,iret; endif
if (iret .ne. 0) goto 1020

allocate (fgrid_ens(maxgrd),bias_ens(maxgrd))
allocate (fgrid_gfs(maxgrd),bias_gfs(maxgrd),fgrid_ctl(maxgrd))
allocate (t2m(maxgrd),td2m(maxgrd))

do ivar = 1, nvar  

  ! apply bias corection & hybrid method, define the weight first   

  pi=3.1415926
  if(nfhr.le.180) then
    weight=(cos(2*pi*float(nfhr)/360.)+1.0)/2
  else
    weight=0.0
  endif

  ! for GFS forecast, weight =0.0

  if(if_gfs.eq.1) then
    weight=0.0                                      
  endif

  bias_ens=0.0             
  bias_gfs=0.0             
  fgrid_ens=-9999.99
  fgrid_ctl=-9999.99
  fgrid_gfs=-9999.99

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized GEFS bias estimation

  if(icstart_ens.eq.1) then
    print *, '----- Cold Start for GEFS Bias Correction -----'
    bias_ens=0.0
    print *, '    '
  else

    ! if_gfs=1, read in gfs bias

    igdtn=-1
    ipdtn=ipdnm(ivar)
    if(if_gfs.eq.1) ipdtn=ipdn(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ibias_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) print*, 'There is no Bias for', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    if (iret.ne.0) bias_ens=0.0
    print*, '     '

    if(iret.eq.0) then
      print *, '----- Initialized GEFS Bias for Current Time -----'
      bias_ens(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
    endif

    call gf_free(gfld)

  endif

  ! get operational GEFS forecast 

  ! set ipdn for GFS forecast

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)
  igdtn=-1
  ipdtn=ipdn(ivar)

  call init_parm(ipdtn,ipdt,igdtn,igdt)
  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte GEFS Dew Point Temperature Forecast '; print *, ' '
    call get_dpt_g2(ifile_ens,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
  elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
    print*, 'Start to Calcualte GEFS 10m Wind Speed Forecast '; print *, ' '
    call get_wspd10m(ifile_ens,maxgrd,ipdtn,ipdt,igdtn,igdt,gfldo,iret)
!   call get_wspd10m(ifile_ens,maxgrd,gfldo,iret)
  else
    call getgb2(ifile_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif

  if (iret.ne.0) then
    print*, 'There is no GEFS', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    print *, ' '
!   call gf_free(gfldo)
  endif

  if (iret.ne.0) goto 100

  print *, '----- GEFS operational forecast for current Time ------'
  call printinfr(gfldo,ivar)
  fgrid_ens(1:maxgrd)=gfldo%fld(1:maxgrd)

  ! get initialized GFS bias estimation

  if(nfhr.le.180) then

    if(icstart_gfs.eq.1) then
      print *, '----- Cold Start for GFS Bias Correction -----'
      bias_gfs=0.0
      print *, '    '
    else
      ipdt(1)=ipd1(ivar)
      ipdt(2)=ipd2(ivar)
      ipdt(10)=ipd10(ivar)
      ipdt(11)=ipd11(ivar)
      ipdt(12)=ipd12(ivar)
      igdtn=-1
      ipdtn=ipdn(ivar)
      call init_parm(ipdtn,ipdt,igdtn,igdt)
      call getgb2(ibias_gfs,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
      if (iret.ne.0) print*, 'There is no GFS Bias', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      if (iret.eq.0) then
        print *, '----- Initialized GFS Bias for Current Time -----'
        bias_gfs(1:maxgrd)=gfld%fld(1:maxgrd)
        call printinfr(gfld,ivar)
      else
        bias_gfs=0.0
      endif

      call gf_free(gfld)

    endif

    ! get operational GFS forecast 

    igdtn=-1
    ipdtn=ipdn(ivar)

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      print *, ' '
      print*, 'Start to Calcualte GFS Dew Point Temperature Forecast '; print *, ' '
      call get_dpt_g2(ifile_gfs,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
    elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
      print*, 'Start to Calcualte GFS 10m Wind Speed Forecast '; print *, ' '
      call get_wspd10m(ifile_gfs,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
    else
      call getgb2(ifile_gfs,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    endif

    if (iret.ne.0) then
      print*, 'There is no GFS forecast for variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      weight=0.0
      print *, ' '
    endif

    if(iret.eq.0) then
      print *, '----- Operational GFS forecast for current Time ------'
      call printinfr(gfld,ivar)
      fgrid_gfs(1:maxgrd)=gfld%fld(1:maxgrd)
    endif

    call gf_free(gfld)

    ! get operational GEFS control forecast 

    ipdt(1)=ipd1(ivar)
    ipdt(2)=ipd2(ivar)
    ipdt(10)=ipd10(ivar)
    ipdt(11)=ipd11(ivar)
    ipdt(12)=ipd12(ivar)
    igdtn=-1
    ipdtn=ipdn(ivar)

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      print *, ' '
      print*, 'Start to Calcualte Control Dew Point Temperature Forecast '; print *, ' '
      call get_dpt_g2(ifile_ctl,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
    elseif(ipd1(ivar).eq.2.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.10) then
      print*, 'Start to Calcualte Control 10m Wind Speed Forecast '; print *, ' '
      call get_wspd10m(ifile_ctl,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
    else
      call getgb2(ifile_ctl,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    endif

    if (iret.ne.0) then
      print*, 'There is no control forecast', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      print *, ' '
      weight=0.0
    endif

    if(iret.eq.0) then
      print *, '----- GEFS control forecast for current Time ------'
      call printinfr(gfld,ivar)
      fgrid_ctl(1:maxgrd)=gfld%fld(1:maxgrd)
    endif

  endif

  ! end of GFS and ensemble control forecast read in

  ! skip the bias correction step for 3hrly variables
  ! skep tmax tmin TCDC and 2 flux variable 

  if(gfldo%ipdtlen.ge.29) then
    if(gfldo%ipdtmpl(29).eq.1.and.gfldo%ipdtmpl(30).eq.3) goto 100
  endif

  call debias_hrbrid(bias_ens,bias_gfs,fgrid_ens,fgrid_gfs,fgrid_ctl,maxgrd,weight)

  ! grib2 in sectiob 4, Octet 12
  ! gfldo%ipdtmpl(3)=11 GRIB2 Code Table 4.3 for bias correced ens. fcst 

  gfldo%fld(1:maxgrd)=fgrid_ens(1:maxgrd)
  gfldo%ipdtmpl(3)=11               

  ! save t2m and 2m Td to get bias corrected 2m rh 

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) t2m=fgrid_ens

  ! adjust the bias corrected dew point temperature by comparing with the bias corrected temperature

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print*, 'Before Adjusted Bias Corrected DPT Forecast '; print *, ' '
    call printinfr(gfldo,ivar)
    do ij=1,maxgrd
      td2m(ij)=min(fgrid_ens(ij),t2m(ij))
    enddo
    gfldo%fld(1:maxgrd)=td2m(1:maxgrd)
    print*, 'After Adjusted Bias Corrected DPT Forecast '; print *, ' '
    call printinfr(gfldo,ivar)
  endif

  ! adjust relative humility, two ends are bounded (0,100)

  if(ipd1(ivar).eq.1.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print*, 'Before Adjusted Bias Corrected RH Forecast '; print *, ' '
    call printinfr(gfldo,ivar)
    do ij=1,maxgrd
      if(fgrid_ens(ij).lt.0.0) fgrid_ens(ij)=0.0
      if(fgrid_ens(ij).gt.100.0) fgrid_ens(ij)=100.0
    enddo
    gfldo%fld(1:maxgrd)=fgrid_ens(1:maxgrd)
    print*, 'After Adjusted Bias Corrected RH Forecast '; print *, ' '
    call printinfr(gfldo,ivar)
  endif

  ! adjust TCDC total cloud cover, two ends are bounded (0,100)

  if(ipd1(ivar).eq.6.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.10.and.ipd12(ivar).eq.0) then
    print*, 'Before Adjusted Bias Corrected TCDC Forecast '; print *, ' '
    call printinfr(gfldo,ivar)
    do ij=1,maxgrd
      if(fgrid_ens(ij).lt.0.0) fgrid_ens(ij)=0.0
      if(fgrid_ens(ij).gt.100.0) fgrid_ens(ij)=100.0
    enddo
    gfldo%fld(1:maxgrd)=fgrid_ens(1:maxgrd)
    print*, 'After Adjusted Bias Corrected TCDC Forecast '; print *, ' '
    call printinfr(gfldo,ivar)
  endif

  ! output bias corrected forecast

  print *, '----- Output Bias Corrected Forecast -----'

! gfldo%ipdtmpl(3)=3               ! code table 4.3, Bias corrected forecast
  gfldo%ipdtmpl(3)=11              ! code table 4.3, Bias corrected ensemble forecast

  call putgb2(ofile,gfldo,iret)
  call printinfr(gfldo,ivar)

100 continue

  call gf_free(gfldo)

! end of bias estimation for one forecast lead time

enddo

call baclose(ifile_ens,iret)
call baclose(ibias_ens,iret)
call baclose(ifile_gfs,iret)
call baclose(ibias_gfs,iret)
call baclose(ifile_ctl,iret)
call baclose(ofile,iret)

deallocate(fgrid_ens,bias_ens,t2m,td2m)
deallocate(fgrid_gfs,bias_gfs,fgrid_ctl)

print *,'Bias Correction Successfully Complete'

stop

1020  continue

print *,'Wrong Data Input or Wrong Message Input'

stop
end

subroutine debias_hrbrid(bias_ens,bias_gfs,fgrid_ens,fgrid_gfs,fgrid_ctl,maxgrd,weight)

!  apply the bias correction & hybrid method        
!
!  input                
!         bias_ens  : GEFS ensmeble mean bias estimation                                               
!         bias_gfs  : GFS bias estimation
!         fgrid_ens : GEFS one member forecast
!         fgrid_gfs : GFS high resolution forecast         
!         fgrid_ctl : GEFS control forecast         
!         maxgrid   : number of grid points in the defined grid
!         weight    : factor to control the influence of gfs forecast

!   output
!         fgrid_ens : GEFS adjusted forecast     

implicit none

integer maxgrd,ij
real    bias_ens(maxgrd),fgrid_ens(maxgrd),bias_gfs(maxgrd),fgrid_gfs(maxgrd),fgrid_ctl(maxgrd)
real    weight

do ij=1,maxgrd
  if(fgrid_ens(ij).gt.-9999.0.and.fgrid_ens(ij).lt.999999.0.and.   &
      bias_ens(ij).gt.-9999.0.and.bias_ens(ij).lt.999999.0) then
    if(fgrid_gfs(ij).gt.-9999.0.and.fgrid_gfs(ij).lt.999999.0.and. &
       fgrid_ctl(ij).gt.-9999.0.and.fgrid_ctl(ij).lt.999999.0) then
       fgrid_ens(ij)=fgrid_ens(ij)-bias_ens(ij)+weight*            &
             (fgrid_gfs(ij)-bias_gfs(ij)-fgrid_ctl(ij)+bias_ens(ij))
    else
      fgrid_ens(ij)=fgrid_ens(ij)-bias_ens(ij)
    endif
  else
    fgrid_ens(ij)=fgrid_ens(ij)
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


subroutine cal_rhp(dpt,tmp,rhp,maxgrd)

! calculate relative humidity in percent
!
!    Compute Relative Humidity (Bolton 1980):
!    es = 6.112*exp((17.67*T)/(T + 243.5));
!    e = 6.112*exp((17.67*Td)/(Td + 243.5));
!    RH = 100.0 * (e/es);
!
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
!                  dpt  ---> dew point temperature
!
!        output
!                  rhp  ---> relative humidity percent 

implicit none

integer maxgrd,ij
real dpt(maxgrd),tmp(maxgrd),rhp(maxgrd)
real T,Td,es,e,RH

do ij=1,maxgrd
  T=tmp(ij)-273.15
  Td=dpt(ij)-273.15
  es=6.112*exp((17.67*T)/(T+243.5))
  e=6.112*exp((17.67*Td)/(Td+243.5)) 
  RH=100.0*(e/es) 
! if(RH.gt.100) then
!   print*, 'ij,T, Td, es,e=',ij,T, Td, es,e                     
! endif
  rhp(ij)=min(100.,RH)                 
enddo
 
return 
end

