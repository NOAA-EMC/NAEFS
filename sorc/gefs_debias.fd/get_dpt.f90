subroutine get_dpt_g2(fort,maxgrd,ipdtn,ipdt,igdtn,igdt,gfld,iret)
!
!     calculate dew point temperature for given rh and tmp 
!
!     parameters

!         ipdtn,ipdt,igdtn,igdt: grid definition, and product definition
!
!     input
!              fort  ---> fort number to input ensemble forecast
!
!     output
!              gfld  ---> dew point temperature
!

use grib_mod
use params

implicit none

integer     j,iret,index,fort,maxgrd
real        rh(maxgrd),tmp(maxgrd),dpt(maxgrd)

integer,dimension(200) :: jids,jpdt,jgdt,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

type(gribfield) :: gfld
logical :: unpack=.true.
logical :: expand=.false.

! get relative humidity 

ipdt(1)=1
ipdt(2)=1

!ipdt(10)=103
!ipdt(11)=0
!ipdt(12)=2

call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(fort,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*, 'there is no relative humidity'; endif
if(iret.ne.0) goto 100

rh(1:maxgrd)=gfld%fld(1:maxgrd)

print *, '----- Variable Relative Humidity for Current Time ------'
call printinfr(gfld,0)
call gf_free(gfld)

! get temperature 

ipdt(1)=0
ipdt(2)=0

!ipdt(10)=103
!ipdt(11)=0
!ipdt(12)=2

call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(fort,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*, 'there is no temperature'; endif
if(iret.ne.0) goto 100

tmp(1:maxgrd)=gfld%fld(1:maxgrd)

print *, '----- Variable Temperature for Current Time ------'
call printinfr(gfld,0)

! calculate dew point temperature

call cal_dewpt(dpt,tmp,rh,maxgrd)

gfld%ipdtmpl(1)=0
gfld%ipdtmpl(2)=6
gfld%fld(1:maxgrd)=dpt(1:maxgrd)

print *, '----- Variable Dew Point Temperature for Current Time ------'
call printinfr(gfld,0)

!call gf_free(gfld)

!print *, '   '

100 continue

return
end

