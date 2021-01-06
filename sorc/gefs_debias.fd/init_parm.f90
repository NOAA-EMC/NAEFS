subroutine init_parm(ipdtn,ipdt,igdtn,igdt)

! SUBPROGRAM:    init_parm         
!
!   PRGMMR: Bo Cui         DATE: 2013-06-11
!
! ABSTRACT: This subroutine returns the Grid Definition, and
!   Product Definition for a given data field.
!
! PROGRAM HISTORY LOG:
! 2013-02-27  Bo Cui   
!
! USAGE:    call init_parm(ipdtn,ipdt,igdtn,igdt)
!
!   INPUT:  ipdtn,ipdt,igdtn,igdt
!   OUTPUT: jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt
!
! REMARKS: None
!
! ATTRIBUTES:
!   LANGUAGE: Fortran 90
!   MACHINE:  IBM SP
!
!$$$

implicit none

integer,dimension(200) :: jids,jpdt,jgdt,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,ipdtn,igdtn  
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

jskp=0
jdisc=-1
jids=-9999

jpdtn=ipdtn
jgdtn=igdtn

jpdt=-9999
jgdt=-9999

! input product defining values

jpdt=ipdt
jgdt=igdt

!jpdt(1)=ipdt(1)   
!jpdt(2)=ipdt(2)   
!jpdt(10)=ipdt(10)  
!jpdt(11)=ipdt(11) 
!jpdt(12)=ipdt(12)

return
end


