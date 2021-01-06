subroutine change_template4(ipdtnum_in,ipdtnum_out,gfldo)

! SUBPROGRAM:    change_template4
!
!   PRGMMR: Bo Cui         DATE: 2013-12-01
!
! ABSTRACT: This subroutine returns ipdtlen and ipdtmpl once product 
!           difinition template are chenged 
!
! PROGRAM HISTORY LOG:
! 2013-12-01  Bo Cui
! 2016-11-12  Bo Cui 
!                add new pdt information in ipdtmpl for new products
!
!   INPUT:  
!          ipdtnum_in    --->  input Product Definition Template Number (see Code Table 4.0)
!          ipdtnum_out   --->  derived Product Definition Template Number 
!          gfldo(ipdtmpl)--->  contains the data values for the specified Product
!                              Definition Template (N=ipdtnum)
!
!   OUTPUT: 
!          ipdtmpl      --->  contains the data values for the specified Product
!                             Definition Template (N=ipdtnum)
!          ipdtlen     --->   number of elements in ipdtmpl(). i.e. number of entries in
!                             Product Defintion Template 4.N(N=ipdtnum).
!
! REMARKS: None
!
! ATTRIBUTES:
!   LANGUAGE: Fortran 90
!   MACHINE:  IBM SP
!
!$$$
! note for pdt number: 
!
!      gfld%ipdtnum 1/11: ens. fcst or control/high reslution
!      gfld%ipdtnum 2/12: ens. average fcst
!      gfld%ipdtnum 5   : probability forecasts at a horizontal level

use grib_mod

implicit none

type(gribfield) :: gfldo

integer ipdtnum_in,ipdtnum_out,ipdtlen
integer temp(200)

ipdtlen=gfldo%ipdtlen
temp=-9999
temp(1:ipdtlen)=gfldo%ipdtmpl(1:ipdtlen)
deallocate (gfldo%ipdtmpl)

! when product difinition template 4.1 change to 4.2
! ipdtlen aslo change, need do modification for output
! ipdtlen change from ipdtlen=18 (4.1) to ipdtlen=17 (4.2)

! ipdtmpl(16) will be defined in main program (type of ens fcst, code table 4.6)

if(ipdtnum_in.eq.1.and.ipdtnum_out.eq.2) then
  ipdtlen=ipdtlen-1
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:15)=temp(1:15)
  gfldo%ipdtmpl(17)=temp(18)
endif

! when product difinition template 4.11 change to 4.12
! ipdtlen change from ipdtlen=34 (4.11) to ipdtlen=33 (4.2)

if(ipdtnum_in.eq.11.and.ipdtnum_out.eq.12) then
  ipdtlen=ipdtlen-1
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:15)=temp(1:15)
  gfldo%ipdtmpl(17:ipdtlen-1)=temp(18:ipdtlen)
endif

! when product difinition template 4.1 change to 4.5
! ipdtlen change from ipdtlen=18(4.11) to ipdtlen=22(4.5)

!print *, 'ipdtnum_in,ipdtnum_out=',ipdtnum_in,ipdtnum_out,ipdtlen
!print *, 'gfldo%ipdtle=',gfldo%ipdtlen                             

if(ipdtnum_in.eq.1.and.ipdtnum_out.eq.5) then
  ipdtlen=22          
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:15)=temp(1:15)
  gfldo%ipdtmpl(17)=0     
  gfldo%ipdtmpl(18)=10              ! Reserved
  gfldo%ipdtmpl(19:ipdtlen)=0                      
endif

! when product difinition template 4.2 change to 4.5
! ipdtlen change from ipdtlen=17(4.2) to ipdtlen=22(4.5)

if(ipdtnum_in.eq.2.and.ipdtnum_out.eq.5) then
  ipdtlen=22          
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:15)=temp(1:15)
  gfldo%ipdtmpl(17)=0     
  gfldo%ipdtmpl(18)=10              ! Reserved
  gfldo%ipdtmpl(19:ipdtlen)=0                      
endif

! when product difinition template 4.1 chenge to 4.15
! no need change ipdtlen 

if(ipdtnum_in.eq.1.and.ipdtnum_out.eq.15) then
  ipdtlen=18          
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:18)=temp(1:18)
endif

! when product difinition template 4.11 chenge to 4.15
! need change ipdtlen from ipdtlen=34 to ipdtlen=18

if(ipdtnum_in.eq.11.and.ipdtnum_out.eq.15) then
  ipdtlen=18          
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:18)=temp(1:18)
endif

! when product difinition template 4.2 chenge to 4.15
! need change ipdtlen from ipdtlen=17 to ipdtlen=18

if(ipdtnum_in.eq.2.and.ipdtnum_out.eq.15) then
  ipdtlen=18          
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:15)=temp(1:15)
  gfldo%ipdtmpl(18)=temp(17)
endif

! when product difinition template 4.12 chenge to 4.15
! need change ipdtlen from ipdtlen=33 to ipdtlen=18

if(ipdtnum_in.eq.12.and.ipdtnum_out.eq.15) then
  ipdtlen=18          
  allocate (gfldo%ipdtmpl(ipdtlen))
  gfldo%ipdtmpl(1:15)=temp(1:15)
  gfldo%ipdtmpl(18)=temp(17)
endif

gfldo%ipdtlen=ipdtlen
ipdtnum_in=ipdtnum_out

return
end


