program gefs_climate_anfefi_acpr
!  Main program    gefs_climate_nfefi_acpr
!  Prgmmr: Hong Guan      Org: Hong.Guan                  Date: 2017-03-24
!
! This is main program to generate climate anomaly forecasts for ensemble mean and Extreme Forecast Index (EFI).             
!
!   subroutine                                                    
!              GETGB2  ---> to get GRIB format data                  
!              PUTGB2 --> to put GRIB format data 
!              GRANGE ---> to calculate max. and min value of array
!
!   parameters:
!      iv    -- 1 variable
!   note:
!
!
!--------+---------+---------+---------+---------+----------+---------+--

use grib_mod
use params
implicit none

double precision pdfval

integer   iv,iret,index,j,ndata,icnt,k,idate,jdate
integer   lfcst,lgamma1,lgamma2,lanom,lefi
integer   if_convert                                                    
integer   ij,i,ii,im,ijk,jnum,ilon,ilat,ipdtnum_out

real      dmin,dmax
real      PI

parameter (iv=1)
parameter (im=30)
parameter (PI=3.1415926)

double precision fstd(im)
double precision p,dp,fp,x,quagam,cdfgam,f50p

real,  allocatable :: fcst(:,:),gamma1(:),gamma2(:),efi(:),anom(:)
Logical*1,allocatable ::  bmap(:)


integer ibmap

type(gribfield) :: gfld,gfldo

integer,dimension(200) :: kids,kpdt,kgdt
integer kskp,kdisc,kpdtn,kgdtn
integer ijd,ipdt8

logical :: unpack=.true.

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer irefi,iranom,irfcst,irgamma1,irgamma2,imem,jm
integer ipd1,ipd2,ipd10,ipd11,ipd12
double precision fmon(2),opara(2),ffmon(2),fopara(2)
character*80 cfcst,cgamma2,cgamma1,cefi,canom

! VAIABLE: APCP

      data ipd1 /1/
      data ipd2 /8/
      data ipd10/1/
      data ipd11/0/
      data ipd12/0/

namelist /namin/cfcst,cgamma1,cgamma2,cefi,canom

read (5,namin,end=100)
write(6,namin)
100  continue

lfcst = len_trim(cfcst)
lgamma1 = len_trim(cgamma1)
lgamma2 = len_trim(cgamma2)
lanom = len_trim(canom)
lefi= len_trim(cefi)

print *, 'Forecast file is ',cfcst(1:lfcst)
print *, 'Climate  gamma1 file is ',cgamma1(1:lgamma1)
print *, 'Climate  gamma2 file is ',cgamma2(1:lgamma2)
print *, 'Anomaly outpu file is ',canom(1:lanom)
print *, 'EFI outpu file is ',cefi(1:lefi)
print *, '    '


call baopenw(81,cefi(1:lefi),irefi)
call baopenw(82,canom(1:lanom),iranom)

!nd grib message. 

  call baopenr(11,cfcst(1:lfcst),irfcst)
print *, irfcst,cfcst(1:lfcst)
iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

if (iret .ne. 0) then; print*,' getgbeh ,fort,index,iret =',11,index,iret; endif
if (iret .ne. 0) goto 882


if(iret.eq.0) then

  ijd=gfldo%ngrdpts

endif

allocate (efi(ijd),fcst(ijd,im),gamma1(ijd),gamma2(ijd),anom(ijd),bmap(ijd))

  call baopenr(12,cgamma1(1:lgamma1),irgamma1)
  call baopenr(13,cgamma2(1:lgamma2),irgamma2)

icnt = 0
do ii = 1, 1

  ! get forecast 

  icnt=0
  
  do imem = 2, im+1

     iids=-9999;ipdt=-9999; igdt=-9999
     idisc=-1;  ipdtn=-1;   igdtn=-1

     ! read and process input ensemble member

      ipdt(17)=imem-1           ! perturbation number

      ! read in control member

      if(imem.eq.1) then
        ipdt(16)=1           ! type of ensemble forecast
        ipdt(17)=0           ! perturbation number
      endif

      ipdtn=11; igdtn=-1
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

      if(iret.ne.0) print *, 'there is no varibale for member ',imem

      if(iret.eq.0) then
        icnt=icnt + 1
        print *, '----- Input Data for current member -----',imem
        print *, imem
        call printinfr(gfld,imem)

        do i=1,ijd
           fcst(i,icnt)=gfld%fld(i)
        enddo

        if_convert=0

        if(gfld%igdtmpl(12).eq.-90000.and.gfld%igdtmpl(15).eq.90000) then
           print *, 'attention, fcst are saved from south to north '
           print *, 'foreacst conversion is needed '
           print *, '   '
           if_convert=1
        elseif(gfld%igdtmpl(12).eq.-90000000.and.gfld%igdtmpl(15).eq.90000000) then
           print *, 'foreacst conversion is needed '
           print *, '   '
           if_convert=1
        endif

      else if (iret.eq.99) then
        print *, 'there is no variable',cfcst(1:lfcst)
           else
        print *, 'there is no variable',cfcst(1:lfcst)       
      endif  ! end of iret.eq.0

      call gf_free(gfld)

    enddo   !### for m = imems, imem

    if (icnt.eq.0) then
      write(*,886)
      icnt=1
    endif

  ! get climate gamma1

    iids=-9999; ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1

    ipdt(1)=ipd1
    ipdt(2)=ipd2
    ipdt(10)=ipd10
    ipdt(11)=ipd11
    ipdt(12)=ipd12
 
    ipdtn=8; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    bmap(1:ijd)=gfld%bmap(1:ijd)

    if(iret.eq.0) then
      print *, 'Climate  gamma1 file is ',cgamma1(1:lgamma1); print *, ' '
      call printinfr(gfld,ii)
    else if (iret.eq.99) then
      print *, ' There is no climate gamma1 variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      goto 150
    else
      print *, ' There is no climate gamma1 variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      goto 150
    endif
! judge if climate gamma1 have same data format as the GEFS 

!    if (iret.eq.0.and.if_convert.eq.1) then
!    if (iret.eq.0) then
!      call grib_cnvfnmoc_g2(gfld,ii)
!    endif
  
    gamma1(1:ijd)=gfld%fld(1:ijd)

    call gf_free(gfld)

  ! get climate standard deviation

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1

    ipdt(1)=ipd1
    ipdt(2)=ipd2
    ipdt(10)=ipd10
    ipdt(11)=ipd11
    ipdt(12)=ipd12

    ipdtn=8; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(13,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret .eq. 0) then
      print *, 'Climate gamma2 file is ',cgamma2(1:lgamma2); print *, ' '
      call printinfr(gfld,ii)
    else if (iret.eq.99) then
      print *, ' There is no climate gamma2 variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      goto 150
    else
      print *, ' There is no climate gamma2 variable ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      goto 150
    endif

 
   gamma2(1:ijd)=gfld%fld(1:ijd)

  ! to calculate anomaly forecast for ensemble mean and EFI

   print *, 'Anomaly outpu file is ',canom(1:lanom)
   print *, 'EFI outpu file is ',cefi(1:lefi)

   do ij = 1, ijd

     fmon(1) = gamma1(ij)
     fmon(2) = gamma2(ij)
     
     if(fmon(1).eq.0.D0.or.bmap(ij).eq..False.) then
        efi(ij)=-99.99
        anom(ij)=-99.99
      goto 200
     endif
     jnum=0
     do i=1,icnt
       if (fcst(ij,i).ne.-9999.99) then
          jnum=jnum+1
          fstd(jnum)=fcst(ij,i)
       endif
     enddo


     call probability(fstd,jnum,ffmon,pdfval)

!     if (fmon(2).eq.0.0) fmon(2) = 0.01D0
!     if (ffmon(2).eq.0.0) ffmon(2) = 0.01D0

      opara(1) = fmon(1)
      opara(2) = fmon(2)
      fopara(1) = ffmon(1)
      fopara(2) = ffmon(2)

      p=0.005D0
      dp=0.01D0
      efi(ij)=0.

     if(fopara(1).gt.-9999.99D0.and.opara(1).gt.0.0) then

          do i=1,100
            x=quagam(p,opara)
            fp=cdfgam(x,fopara)
            efi(ij)=efi(ij)+dp*(p-fp)/(sqrt(p*(1-p)))
            p=p+dp
          enddo

          efi(ij)=efi(ij)*2./PI
          anom(ij)=cdfgam(pdfval,opara)*100.0
          go to 200 
      endif

     if(fopara(1).gt.-9999.99D0.and.opara(1).eq.0.0) then
          efi(ij)=1.
          anom(ij)=100.
          go to 200 
     endif

     if(fopara(1).eq.-9999.99D0.and.opara(1).gt.0.0) then
          efi(ij)=-1
          anom(ij)=0.
          go to 200 
     endif

       efi(ij)=0.
       anom(ij)=50.

200  continue
   enddo

       ibmap=0

!  output EFI

  print *, '----- Output EFI -----'

  if(gfldo%ipdtnum.eq.1) ipdtnum_out=2
  if(gfldo%ipdtnum.eq.11) ipdtnum_out=12

  call change_template4(gfldo%ipdtnum,ipdtnum_out,gfldo)

  gfldo%fld(1:ijd)=efi(1:ijd)
  gfldo%ipdtmpl(16)=199
  gfldo%ipdtmpl(17)=20
  gfldo%idrtmpl(3)=3
  allocate(gfldo%bmap(ijd)) 
  gfldo%bmap(1:ijd)=bmap(1:ijd)
  gfldo%ibmap=ibmap

  call putgb2(81,gfldo,iret)
  call printinfr(gfldo,ii)

!  output anomaly forecasts

  print *, '----- Output Anomaly Forecast -----'

  gfldo%fld(1:ijd)=anom(1:ijd)
  gfldo%ipdtmpl(16)=197

  call putgb2(82,gfldo,iret)
  call printinfr(gfldo,ii)

  call gf_free(gfldo)

  150 continue  

  print *, '    '


 889 format (4(F9.3,2x))

enddo

call baclose(11,iret)
call baclose(12,iret)
call baclose(13,iret)
call baclose(81,iret)
call baclose(82,iret)

deallocate (efi,fcst,gamma1,gamma2,anom,bmap)

881 continue
991 continue
883 format('ij=',i5,'  m1='e11.4,'  m2=',e11.4, ' bs=',e11.4,'  fc=',e11.4,'  an=',e11.4)
886 format('  Irec  pds5 pds6 pds7 pds8 pds9 pd10 pd11 pd14','  ndata  Maximun  Minimum')
888 format (i4,2x,8i5,i8,2f9.2)

stop   

882 print *, 'Missing input file, please check! stop!!!'

stop
end

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

