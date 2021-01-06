!
!  Main program    gefs_climate_anomqefi_g2
!  Prgmmr: Hong Guan             Org:                       Date: 2017-01-10
!
! This is main program to generate climate anomaly forecasts and extreme
!              forecast index.             

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
!
!   Fortran 90 on IBMSP 
!
!
!--------+---------+---------+---------+---------+----------+---------+--

program ANOMALY

use anomaly_mod

implicit none

double precision quanor,cdfnor
double precision p,dp,fp,value

integer   ivar,ixy,iret,index,j,ndata,icnt,kf,k,idate,jdate
integer   ij,i,ii,id_center
integer   ibias,lfcsts,lfcstm,lanom,lefi,lanlm,lanls,lbias
integer   irfcsts,irfcstm,iranom,irefi,iranlm,iranls,irbias
integer   if_convert
real      dmin,dmax
real      PI

parameter (ivar=20)
parameter (PI=3.1415926)

real,      allocatable :: fcstm(:),fcsts(:),efi(:),anom(:),bias(:)
real,      allocatable :: anlm(:),anls(:)

double precision apara(2),fpara(2)

character*80 cfcstm,cfcsts,canlm,canls,cefi,canom,cbias
namelist /namin/cfcstm,cfcsts,canlm,canls,cefi,canom,cbias,ibias

read (5,namin,end=100)
write(6,namin)

100  continue

lfcstm = len_trim(cfcstm)
lfcsts = len_trim(cfcsts)
lanlm = len_trim(canlm)
lanls= len_trim(canls)
lefi= len_trim(cefi)
lanom = len_trim(canom)
lbias= len_trim(cbias)

print *, 'Forecast mean file is ',cfcstm(1:lfcstm)
print *, 'Forecast stdv file is ',cfcsts(1:lfcsts)
print *, 'Analysis mean inpu file is ',canlm(1:lanlm)
print *, 'Analysis stdv inpu file is ',canls(1:lanls)
print *, 'Analysis bias file is ',cbias(1:lbias)
print *, 'EFI outpu file is ',cefi(1:lefi)
print *, 'Anomaly outpu file is ',canom(1:lanom)
print *, '    '

call baopenr(11,cfcstm(1:lfcstm),irfcstm)
call baopenr(12,cfcsts(1:lfcsts),irfcsts)
call baopenr(13,canlm(1:lanlm),iranlm)
call baopenr(14,canls(1:lanls),iranls)
call baopenr(15,cbias(1:lbias),irbias)

if (irfcstm.ne.0) goto 882
if (irfcsts.ne.0) goto 882
if (iranlm.ne.0) goto 882
if (iranls.ne.0) goto 882
!if (irbias.ne.0) goto 882

call baopenw(51,canom(1:lanom),iranom)
call baopenw(52,cefi(1:lefi),irefi)

! find grib message, ixy: number of grid points in the defined grid

call baopenr(11,cfcstm(1:lfcstm),irfcstm)
iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

ixy=gfld%ngrdpts
id_center=gfld%idsect(1)
call gf_free(gfld)
if (iret .ne. 0) then; print*,' getgbeh ,fort,index,iret =',11,index,iret; endif
if (iret .ne. 0) goto 882

allocate(efi(ixy),fcstm(ixy),fcsts(ixy),anom(ixy))
allocate(anlm(ixy),anls(ixy),bias(ixy))

icnt = 0

do ii = 16, 18

! get forecast mean

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ii)
  ipdt(2)=ipd2(ii)
  ipdt(10)=ipd10(ii)
  ipdt(11)=ipd11(ii)
  ipdt(12)=ipd12(ii)

  igdtn=-1
  ipdtn=ipdnm(ii)

! CMC fcsts come from /dcom, with different ipd11 and ipd12 from the NCEP

  if(id_center.eq.54) then
    ipdt(11)=ipd11_cmc(ii)
    ipdt(12)=ipd12_cmc(ii)
  endif

  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if(iret.eq.0) then
    print *, 'Forecast file is ',cfcstm(1:lfcstm); print *, ' '
    fcstm(1:ixy)=gfldo%fld(1:ixy)
    call printinfr(gfldo,ii)
  else if (iret.eq.99) then
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
    goto 150
  else
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
    goto 150
  endif

  idate=gfldo%idsect(6)*1000000 + gfldo%idsect(7)*10000 + &
        gfldo%idsect(8)*100 + gfldo%idsect(9)

  call iaddate(idate,gfldo%ipdtmpl(9),jdate)

  iids(7)= mod(jdate/10000,  100)
  iids(8)= mod(jdate/100,    100)
  iids(9)= mod(jdate,        100)

  ! check read in forecast
  ! for CMC and FNMOC ensmeble, data are saved from south to north
  ! CMC and FNMOC have gfld%igdtmpl(12)=-90000000 and gfld%igdtmpl(15)=90000000
  ! judge if climate mean have the same data format as the GEFS fcst

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

  ! get forecast std

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
  call getgb2(12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  if(iret.eq.0) then
    print *, 'Forecast file is ',cfcsts(1:lfcsts); print *, ' '
    fcsts(1:ixy)=gfld%fld(1:ixy)
    call  printinfr(gfld,ii)
    else if (iret.eq.99) then
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfld)
    goto 150
  else
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfld)
    goto 150
  endif

  idate=gfld%idsect(6)*1000000 + gfld%idsect(7)*10000 + &
        gfld%idsect(8)*100 + gfld%idsect(9)

  call iaddate(idate,gfld%ipdtmpl(9),jdate)

  iids(7)= mod(jdate/10000,  100)
  iids(8)= mod(jdate/100,    100)
  iids(9)= mod(jdate,        100)

  ! check read in forecast
  ! for CMC and FNMOC ensmeble, data are saved from south to north
  ! CMC and FNMOC have gfld%igdtmpl(12)=-90000000 and gfld%igdtmpl(15)=90000000
  ! judge if climate mean have the same data format as the GEFS fcst
  if_convert=0

  if(gfld%igdtmpl(12).eq.-90000.and.gfld%igdtmpl(15).eq.90000) then
    print *, 'attention, fcst are saved from south to north '
    print *, 'climate mean/standard deviation conversion is needed '
    print *, '   '
    if_convert=1
  elseif(gfld%igdtmpl(12).eq.-90000000.and.gfld%igdtmpl(15).eq.90000000) then
    print *, 'climate mean/standard deviation conversion is needed '
    print *, '   '
    if_convert=1
  endif
  call gf_free(gfld)

  ! get climate mean

  ipdt(11)=ipd11(ii)
  ipdt(12)=ipd12(ii)

  igdtn=-1
  ipdtn=ipdnc(ii)

  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(13,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if (iret .eq. 0) then
    print *, 'Climate  mean file is ',canlm(1:lanlm); print *, ' '
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

  anlm(1:ixy)=gfld%fld(1:ixy)

  call gf_free(gfld)

  ! get analysis stdv
  igdtn=-1
  ipdtn=ipdnc(ii)

  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(14,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if (iret .eq. 0) then
    print *, 'Climate stdv file is ',canls(1:lanls); print *, ' '
    call printinfr(gfld,ii)
  else if (iret.eq.99) then
 print *, ' There is no climate stdv variable',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    goto 150
  else
 print *, ' There is no climate stdv variable',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    goto 150
  endif

  ! judge if climate standard deviation have same data format as the GEFS fcst

  if (iret.eq.0.and.if_convert.eq.1) then
    call grib_cnvfnmoc_g2(gfld,ii)
  endif

  anls(1:ixy)=gfld%fld(1:ixy)

  call gf_free(gfld)

  !get bias (diff. between analysis and cdas)

  if (ibias.ne.1) then

    igdtn=-1
    idisc=-1
    iids=-9999
    ipdtn=ipdnr(ii)

    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(15,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret .eq. 0) then
      print *, 'Analysis bias file is ',cbias(1:lbias); print *, ' '
      call printinfr(gfld,ii)
    else if (iret.eq.99) then
      print *, ' There is no bias variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
!     goto 150
    else
      print *, ' There is no bias variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
!     goto 150
    endif

    ! judge if bias have same data format as the GEFS fcst

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

  ! to calculate anomaly forecast

  do ij = 1, ixy

    apara(1) = anlm(ij) - bias(ij)
    apara(2) = anls(ij)
    fpara(1) = fcstm(ij)
    fpara(2) = fcsts(ij)
    
    ! cdfnor accept two parameters directly (mean and std deviation)

    if (apara(2).eq.0.0) apara(2) = 0.01
    if (fpara(2).eq.0.0) fpara(2) = 0.01

       p=0.005d0
       dp=0.01d0
       efi(ij)=0.

      do i=1,100
       value=quanor(p,apara)
       fp=cdfnor(value,fpara)
       efi(ij)=efi(ij)+dp*(p-fp)/(sqrt(p*(1-p)))
       p=p+dp
      enddo

      efi(ij)=efi(ij)*2./PI

      value=fcstm(ij)
      anom(ij)=cdfnor(value,apara)*100.

  enddo

! output anomaly forecasts

  gfldo%fld(1:ixy)=anom(1:ixy)

  gfldo%ipdtnum=2

  gfldo%idrtmpl(3)=3
  gfldo%ipdtmpl(16)=197

  print *, '----- Output Anomaly Forecast -----'

  call putgb2(51,gfldo,iret)
  call printinfr(gfldo,ii)

! output EFI

  gfldo%fld(1:ixy)=efi(1:ixy)

  gfldo%ipdtnum=2

  gfldo%ipdtmpl(16)=199

  call putgb2(52,gfldo,iret)
  call printinfr(gfldo,ii)
  call gf_free(gfldo)

  150 continue

  print *, '    '


enddo

call baclose(11,iret)
call baclose(12,iret)
call baclose(13,iret)
call baclose(14,iret)
call baclose(15,iret)

call baclose(51,iret)
call baclose(52,iret)

deallocate(fcstm,fcsts,anlm,anls,anom,efi,bias)

print *,'EFI Calculation Successfully Complete'

881 continue
991 continue

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

subroutine grange(n,ld,d,dmin,dmax)

!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM: GRANGE(N,LD,D,DMIN,DMAX)
!   PRGMMR: YUEJIAN ZHU       ORG:NP23          DATE: 97-03-17
!
! ABSTRACT: THIS SUBROUTINE WILL ALCULATE THE MAXIMUM AND
!           MINIMUM OF A ARRAY
!
! PROGRAM HISTORY LOG:
!   97-03-17   YUEJIAN ZHU (WD20YZ)
!
! USAGE:
!
!   INPUT ARGUMENTS:
!     N        -- INTEGER
!     LD(N)    -- LOGICAL OF DIMENSION N
!     D(N)     -- REAL ARRAY OF DIMENSION N
!
!   OUTPUT ARGUMENTS:
!     DMIN     -- REAL NUMBER ( MINIMUM )
!     DMAX     -- REAL NUMBER ( MAXIMUM )
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN
!
!$$$

implicit none

logical(1) ld(n)
real d(n)
real dmin,dmax
integer i,n
dmin=1.e38
dmax=-1.e38
do i=1,n
  if(ld(i)) then
    dmin=min(dmin,d(i))
    dmax=max(dmax,d(i))
  endif
enddo
return
end

