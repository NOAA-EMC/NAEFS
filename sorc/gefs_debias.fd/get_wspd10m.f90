subroutine get_wspd10m(fort,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
!
!     calculate 10m wind speed 
!
!     parameters

!         ipdtn,ipdt,igdtn,igdt: grid definition, and product definition
!
!     input
!              fort  ---> fort number to input ensemble forecast
!
!     output
!              gfld  ---> 10m wind speed             
!

use grib_mod
use params

implicit none

integer     j,iret,index,fort,maxgrd,ij
real        u10m(maxgrd),v10m(maxgrd),wspd10m(maxgrd)

integer,dimension(200) :: jids,jpdt,jgdt,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

type(gribfield) :: gfld
logical :: unpack=.true.
logical :: expand=.false.

! get 10m u 

ipdt(1)=2
ipdt(2)=2
ipdt(10)=103
ipdt(11)=0
ipdt(12)=10

call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(fort,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*, 'there is no 10m U'; endif
if(iret.ne.0) goto 100

u10m(1:maxgrd)=gfld%fld(1:maxgrd)

print *, '----- Variable 10m U for Current Time ------'
call printinfr(gfld,0)
call gf_free(gfld)

! get 10m v             

ipdt(1)=2
ipdt(2)=3
ipdt(10)=103
ipdt(11)=0
ipdt(12)=10

call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(fort,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*, 'there is no 10m V'; endif
if(iret.ne.0) goto 100

v10m(1:maxgrd)=gfld%fld(1:maxgrd)

print *, '----- Variable 10m V for Current Time ------'
call printinfr(gfld,0)

! calculate 10m wind speed             

do ij=1,maxgrd
  wspd10m(ij)=sqrt(u10m(ij)**2+v10m(ij)**2)
enddo

gfld%ipdtmpl(1)=2
gfld%ipdtmpl(2)=1
gfld%fld(1:maxgrd)=wspd10m(1:maxgrd)

print *, '----- Variable 10m Wind Speed for Current Time ------'
call printinfr(gfld,0)

!print *, '   '

100 continue

return
end

