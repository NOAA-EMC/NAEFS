subroutine get_rh_g2(fort,maxgrd,ipdtn,ipdt,igdtn,igdt,idisc,iids,gfld,iret)

!     calculate relative humility for given dpt and tmp 
!
!     parameters

!         ipdtn,ipdt,igdtn,igdt: grid definition, and product definition

!     parameters
!
!        input
!                  fort  ---> fort number to input dpt and tmp 
!
!        output
!                  gfld ---> relative humility    

use grib_mod
use params

implicit none

integer     j,iret,index,fort,maxgrd
real        rh(maxgrd),tmp(maxgrd),dpt(maxgrd)

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

type(gribfield) :: gfld
logical :: unpack=.true.
logical :: expand=.false.

! get dew point temperature

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)

jpdt(1)=0
jpdt(2)=6

!jpdt(10)=103
!jpdt(11)=0
!jpdt(12)=2

call getgb2(fort,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*, 'there is no dew point temperature'; endif
if(iret.ne.0) goto 100

dpt(1:maxgrd)=gfld%fld(1:maxgrd)

print *, '----- Variable Dew Point Temperature for Current Time ------'
call printinfr(gfld,0)
call gf_free(gfld)

! get temperature 

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)

jpdt(1)=0
jpdt(2)=0

!jpdt(10)=103
!jpdt(11)=0
!jpdt(12)=2

call getgb2(fort,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*, 'there is no  temperature'; endif
if(iret.ne.0) goto 100

print *, '----- Variable Temperature for Current Time ------'
tmp(1:maxgrd)=gfld%fld(1:maxgrd)
call printinfr(gfld,0)

! calculate relative humility    

call cal_rhp(dpt,tmp,rh,maxgrd)

gfld%ipdtmpl(1)=1
gfld%ipdtmpl(2)=1
gfld%fld(1:maxgrd)=rh(1:maxgrd)

print *, '----- Variable Relative Humility for Current Time ------'
call printinfr(gfld,0)

100 continue

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
!
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

