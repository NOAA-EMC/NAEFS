subroutine change_template4(ipdtnum_in,ipdtnum_out,ipdtmpl,ipdtlen)

! SUBPROGRAM:    init_parm
!
!   PRGMMR: Bo Cui         DATE: 2013-12-01
!
! ABSTRACT: This subroutine returns the changed ipdtlen once product 
!           difinition template 4.1/4.11 chenge to 4.2/4.12 
!
! PROGRAM HISTORY LOG:
! 2013-12-01  Bo Cui
!
!   INPUT:  
!          ipdtnum_in   --->  input Product Definition Template Number (see Code Table 4.0)
!          ipdtnum_out  --->  derived Product Definition Template Number 
!          ipdtmpl      --->  contains the data values for the specified Product
!                             Definition Template (N=ipdtnum)
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


implicit none

integer ipdtnum_in,ipdtnum_out,ipdtlen
integer ipdtmpl(ipdtlen),temp(ipdtlen)

! gfld%ipdtnum 1/11: ens. fcst or control/high reslution
! gfld%ipdtnum 2/12: ens. average fcst

temp(1:ipdtlen)=ipdtmpl(1:ipdtlen)
ipdtmpl=-9999

! ipdtmpl(16) will be defined in main program (type of ens fcst, code table 4.6)

if(ipdtnum_in.eq.1.and.ipdtnum_out.eq.2) then
  ipdtmpl(1:15)=temp(1:15)
  ipdtmpl(17)=temp(18)
  ipdtlen=ipdtlen-1
endif
  
if(ipdtnum_in.eq.11.and.ipdtnum_out.eq.12) then
  ipdtmpl(1:15)=temp(1:15)
  ipdtmpl(17:ipdtlen-1)=temp(18:ipdtlen)
  ipdtlen=ipdtlen-1
endif

ipdtnum_in=ipdtnum_out

return
end


