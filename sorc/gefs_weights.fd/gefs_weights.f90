program gefs_weights_g2

!  Main program    gefs_weights_g2
!
!  Prgmmr: Yuejian Zhu           Org: np23          Date: 2006-04-04
!                                mod: Bo.Cui        Date: 2013-12-01
!
! This is main program to generate ensemble weights.             
!
! program hostory log 
!                      2013-12-01  Bo Cui    encode and decode grib2

! call subroutine                                                    
!              getgb2  ---> to get GRIB format data                  
!
!   parameters:
!      ix    -- x-dimensional
!      iy    -- y-dimensional
!      ixy   -- ix*iy
!
!   Notes:
!      members is the total ensemble members include ensemble control
!
!   Fortran 90 on IBMSP 
!
!--------+---------+---------+---------+---------+----------+---------+--

use naefs_mod

implicit none

integer   iv,ixy,irwght,irfcst,iret,index,j,ndata,jj,k
integer   ij,i,ii,members,lfcst,lwght,id_center

real,     allocatable :: fcst(:),wght(:)

character*80 cfcst,cwght
namelist /namin/ cfcst,cwght,members

read (5,namin,end=100)
write(6,namin)

100  continue

lfcst = len_trim(cfcst)
lwght = len_trim(cwght)

print *, 'Forecast      file is ',cfcst(1:lfcst)
print *, 'Weights otput file is ',cwght(1:lwght)
print *, ' '

call baopen (81,cwght(1:lwght),irwght)

! find grib message, ixy: number of grid points in the defined grid

call baopenr(11,cfcst(1:lfcst),irfcst)

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if (iret .ne. 0) then; print*,' getgbeh ,fort,index,iret =',11,index,iret; endif
if (iret .ne. 0) goto 882

ixy=gfld%ngrdpts
id_center=gfld%idsect(1)
call gf_free(gfld)

allocate (fcst(ixy),wght(ixy))

do ii = 1, 1  
  call baopenr(11,cfcst(1:lfcst),irfcst)
  if (irfcst.ne.0) goto 882

  ! get forecast

  ipdt=-9999
  igdt=-9999
  iids=-9999

  ipdt(1)=ipd1(ii)
  ipdt(2)=ipd2(ii)
  ipdt(10)=ipd10(ii)
  ipdt(11)=ipd11(ii)
  ipdt(12)=ipd12(ii)

  igdtn=-1
  ipdtn=ipdn(ii)

  ! CMC fcsts come from /dcom, with different ipd11 and ipd12 from the NCEP

  if(id_center.eq.54) then
    ipdt(11)=ipd11_cmc(ii)
    ipdt(12)=ipd12_cmc(ii)
  endif

  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if (iret .eq. 0) then
    print *, 'Forecast      file is ',cfcst(1:lfcst)
    fcst(1:ixy)=gfldo%fld(1:ixy)
    call printinfr(gfldo,ii)
  else if (iret.eq.99) then
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
    goto 991
  else
    print *, ' There is no forecast ',jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    call gf_free(gfldo)
    goto 991
  endif

!
! calculate weights for ensemble forecasts
!
  do ij = 1, ixy
    wght(ij)=1.0/float(members)
  enddo

! iens(4)  = 5
! ipds(5)  = 184  ! Octet 9 = 184 (ensemble weights)
! ipds(6)  = 200  ! Octet 10 : need define
! ipds(7)  = 0    ! Octet 11-12: need define
! ipds(19) = 129  ! Octet 4 = 129 (using 129 parameter table)
! ipds(22) = 4

  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

  gfldo%idrtmpl(3)=3

  print *, '----- Output Member Weight -----'

  gfldo%fld(1:ixy)=wght(1:ixy)

  call putgb2(81,gfldo,iret)
  call printinfr(gfldo,ii)
  call gf_free(gfldo)

  call baclose(11,iret)

enddo

call baclose(81,iret)
deallocate(fcst,wght)

991 continue

stop   

882 print *, 'Missing input file, please check! stop!!!'

stop
end

