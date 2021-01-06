!
!  Main program    naefs_climate_anv

!  Prgmmr: Yuejian Zhu           Org: np23                       Date: 2005-10-10
!          Bo Cui                mod: converted from f77 to f90        2006-12-10
!          Bo Cui                mod: encod/decode grib2               2013-12-01
!          Bo Cui                mod: add new variable wind10m         2017-09-01
!                                this code is for ensemble mean only     
!
! This is main program to generate climate anomaly forecasts
!
!   calculate the difference between ens average and climate mean  
!
!   subroutine                                                    
!              IADDATE---> to add forecast hours to initial data    
!              GETGB  ---> to get GRIB format data                  
!              GRANGE ---> to calculate max. and min value of array
!
!   parameters:
!      ix    -- x-dimensional
!      iy    -- y-dimensional
!      ixy   -- ix*iy
!      iv    -- 19 variables
!   note:
!      if ibias = 1, no bias information available
!
!   Fortran 90 on IBMSP 
!
!--------+---------+---------+---------+---------+----------+---------+--

program ANOMALY

use anomaly_mod

implicit none

!real cdfnor

integer   ixy,irwght,iret,index,j,ndata,jj,kf,k,idate,jdate
integer   ij,i,ii,kpds9,kpds10,kpds11,members,lwght,kdate,jpds9,jpds10,jpds11
integer   ibias,lfcst,lmean,lstdv,lbias,lanom,iranom,irfcst,irmean,irstdv,irbias 
integer   if_convert                                                    
real      dmin,dmax

!parameter (iv=19)

real,      allocatable :: fcst(:),cavg(:),stdv(:),bias(:),anom(:)
logical(1),allocatable :: lb(:)

integer ifld(iv),ityp(iv),ilev(iv)

real    fmon(2),opara(2)

character*80 cfcst,cmean,cstdv,cbias,canom
namelist /namin/ cfcst,cmean,cstdv,cbias,canom,ibias

read (5,namin,end=100)
write(6,namin)

100  continue

lfcst = len_trim(cfcst)
lmean = len_trim(cmean)
lstdv = len_trim(cstdv)
lbias = len_trim(cbias)
lanom = len_trim(canom)

print *, 'Forecast      file is ',cfcst(1:lfcst)
print *, 'Climate  mean file is ',cmean(1:lmean)
print *, 'Climate  stdv file is ',cstdv(1:lstdv)
print *, 'Analysis bias file is ',cbias(1:lbias)
print *, 'Anomaly outpu file is ',canom(1:lanom)
print *, '    '

call baopen (51,canom(1:lanom),iranom)

! find grib message, ixy: number of grid points in the defined grid

call baopenr(11,cfcst(1:lfcst),irfcst)

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
ixy=gfld%ngrdpts
call gf_free(gfld)
if (iret .ne. 0) then; print*,' getgbeh ,fort,index,iret =',11,index,iret; endif
if (iret .ne. 0) goto 882

allocate (fcst(ixy),cavg(ixy),stdv(ixy),bias(ixy),anom(ixy),lb(ixy))

call baopenr(11,cfcst(1:lfcst),irfcst)
call baopenr(12,cmean(1:lmean),irmean)
call baopenr(13,cstdv(1:lstdv),irstdv)
call baopenr(14,cbias(1:lbias),irbias)
if (irfcst.ne.0) goto 882
if (irmean.ne.0) goto 882
if (irstdv.ne.0) goto 882
if (ibias.ne.1) then
  if (irbias.ne.0) goto 882
endif

do ii = 1, iv

  ! get forecast

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ii)
  ipdt(2)=ipd2(ii)
  ipdt(10)=ipd10(ii)
  ipdt(11)=ipd11(ii)
  ipdt(12)=ipd12(ii)

  igdtn=-1
  ipdtn=ipdnm(ii)
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if (iret .eq. 0) then
    print *, 'Forecast      file is ',cfcst(1:lfcst); print *, ' '
    fcst(1:ixy)=gfldo%fld(1:ixy)
    call printinfr(gfldo,ii)
  else if (iret.eq.99) then
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
    goto 150
  else
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
    goto 991
  endif

  idate=gfldo%idsect(6)*1000000 + gfldo%idsect(7)*10000 + &
        gfldo%idsect(8)*100 + gfldo%idsect(9)

  ! climate mean and standard deviation have grib2 message differnt with gefs forecast

  if(ipd1(ii).eq.0.and.ipd2(ii).eq.4.and.ipd10(ii).eq.103.and.ipd12(ii).eq.2) then 
    call iaddate(idate,gfldo%ipdtmpl(9)+06,jdate)
  elseif(ipd1(ii).eq.0.and.ipd2(ii).eq.5.and.ipd10(ii).eq.103.and.ipd12(ii).eq.2) then     
    call iaddate(idate,gfldo%ipdtmpl(9)+06,jdate)
  else
    call iaddate(idate,gfldo%ipdtmpl(9),jdate)
  endif

  iids(7)= mod(jdate/10000,  100)
  iids(8)= mod(jdate/100,    100)
  iids(9)= mod(jdate,        100)

  ! check read in forecast. If the input ensmeble are CMC/FNMOC, the climate mean
  ! and standard deviation need to be inverted
  ! CMC and FNMOC default gfld%igdtmpl(12)=-90000 and gfld%igdtmpl(15)=90000

  if_convert=0

  if(gfldo%igdtmpl(12).eq.-90000.and.gfldo%igdtmpl(15).eq.90000) then
    print *, 'attention, fcst are saved from south to north '
    print *, 'climate mean/standard deviation conversion is needed '
    print *, '   '
    if_convert=1
  elseif(gfldo%igdtmpl(12).eq.-90000000.and.gfldo%igdtmpl(15).eq.90000000) then
    print *, 'climate mean/standard deviation conversion is needed '
    print *, '   '
    if_convert=1
  endif

  ! get climate mean

  igdtn=-1
  ipdtn=ipdnc(ii)

  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if (iret .eq. 0) then
    print *, 'Climate  mean file is ',cmean(1:lmean); print *, ' '
    call printinfr(gfld,ii)
  else if (iret.eq.99) then
    print *, ' There is no climate mean variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    goto 150
  else
    print *, ' There is no climate mean variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    goto 150
  endif

  ! check read in forecast
  ! for CMC and FNMOC ensmeble, data are saved from south to north
  ! CMC and FNMOC have gfld%igdtmpl(12)=-90000000 and gfld%igdtmpl(15)=90000000

  ! judge if climate mean have the same data format as the GEFS fcst

  if (iret.eq.0.and.if_convert.eq.1) then
    call grib_cnvfnmoc_g2(gfld,ii)
  endif

  cavg(1:ixy)=gfld%fld(1:ixy)

  call gf_free(gfld)

  ! get climate standard deviation

  igdtn=-1
  ipdtn=ipdnc(ii)

  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(13,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if (iret .eq. 0) then
    print *, 'Climate stdv file is ',cstdv(1:lstdv); print *, ' '
    call printinfr(gfld,ii)
  else if (iret.eq.99) then
    print *, ' There is no climate stdv variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    goto 150
  else
    print *, ' There is no climate stdv variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    goto 150
  endif

  ! check read in forecast
  ! for CMC and FNMOC ensmeble, data are saved from south to north
  ! CMC and FNMOC have gfld%igdtmpl(12)=-90000000 and gfld%igdtmpl(15)=90000000

  if (iret.eq.0.and.if_convert.eq.1) then
    call grib_cnvfnmoc_g2(gfld,ii)
  endif

  stdv(1:ixy)=gfld%fld(1:ixy)

  call gf_free(gfld)

  ! get bias (diff. between analysis and cdas)

  if (ibias.ne.1) then

    igdtn=-1
    idisc=-1
    iids=-9999
    ipdtn=ipdnr(ii)

    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(14,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret .eq. 0) then
      print *, 'Analysis bias file is ',cbias(1:lbias); print *, ' '
      call printinfr(gfld,ii)
    else if (iret.eq.99) then
      print *, ' There is no bias variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
!     goto 150
    else
      print *, ' There is no bias variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      bias=0.0
!     goto 150
    endif

    ! judge if bias have same data format as the GEFS analysis

    if (iret.eq.0.and.if_convert.eq.1) then
      call grib_cnvfnmoc_g2(gfld,ii)
    endif

    if (iret.eq.0) then
      bias(1:ixy)=gfld%fld(1:ixy)
    endif

    call gf_free(gfld)

  else
    bias=0.0
  endif

  ! to calculate difference between ensemble mean and climate mean

  ! notes to use climate bias
  ! if bias = gdas - cdas, then fmon = cavg + bias
  ! if bias = cdas - gdas, then fmon = cavg - bias

  print *, 'Anomaly outpu file is ',canom(1:lanom)

  do ij = 1, ixy
    anom(ij)=fcst(ij)-cavg(ij)-bias(ij)   
  enddo

  print *, ' '

! output anomaly forecasts 

  gfldo%fld(1:ixy)=anom(1:ixy)
 
! ipdtmpl(16): derived forecast
! ipdtmpl(16)=18: Deviation of Ensemble Mean from Daily Climatology

  gfldo%ipdtmpl(16)=198       

  print *, '----- Output Anomaly Forecast -----'; print *, ' '

  call putgb2(51,gfldo,iret)
  call printinfr(gfldo,ii)
  call gf_free(gfldo)

  150 continue

  print *, '    '

enddo

call baclose(11,iret)
call baclose(12,iret)
call baclose(13,iret)
call baclose(14,iret)

call baclose(51,iret)

print *,'Anomaly Forecast Calculation Successfully Complete'

881 continue
991 continue
883 format('ij=',i5,'  m1=',f10.4,'  m2=',f10.4, ' bs=',f10.4,'  fc=',f10.4,'  an=',f10.4)
886 format('  Irec  pds5 pds6 pds7 pds8 pds9 pd10 pd11 pd14','  ndata  Maximun  Minimum')
888 format (i4,2x,8i5,i8,2f9.2)

stop   

882 print *, 'Missing input file, please check! stop!!!'

stop
end

SUBROUTINE IADDATE(IDATE,IHOUR,JDATE)

IMPLICIT NONE

INTEGER   MON(12),IC,IY,IM,ID,IHR,IDATE,JDATE,IHOUR
DATA MON/31,28,31,30,31,30,31,31,30,31,30,31/

IC = MOD(IDATE/100000000,100 )
IY = MOD(IDATE/1000000,100 )
IM = MOD(IDATE/10000  ,100 )
ID = MOD(IDATE/100    ,100 )
IHR= MOD(IDATE        ,100 ) + IHOUR

IF(MOD(IY,4).EQ.0) MON(2) = 29
1 IF(IHR.LT.0) THEN
    IHR = IHR+24
    ID = ID-1
    IF(ID.EQ.0) THEN
      IM = IM-1
      IF(IM.EQ.0) THEN
        IM = 12
        IY = IY-1
        IF(IY.LT.0) IY = 99
      ENDIF
      ID = MON(IM)
    ENDIF
    GOTO 1
  ELSEIF(IHR.GE.24) THEN
    IHR = IHR-24
    ID = ID+1
    IF(ID.GT.MON(IM)) THEN
      ID = 1
      IM = IM+1
        IF(IM.GT.12) THEN
          IM = 1
        IY = MOD(IY+1,100)
        ENDIF
     ENDIF
     GOTO 1
  ENDIF

JDATE = IC*100000000 + IY*1000000 + IM*10000 + ID*100 + IHR
RETURN
END


