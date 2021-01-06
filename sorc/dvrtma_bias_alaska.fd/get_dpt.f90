subroutine get_dpt_g2(fort,maxgrd,ipdtn,ipdt,igdtn,igdt,idisc,iids,gfld,iret)
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

! get relative humidity 

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)

jpdt(1)=1
jpdt(2)=1

!jpdt(10)=103
!jpdt(11)=0
!jpdt(12)=2

call getgb2(fort,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*, 'there is no relative humidity'; endif
if(iret.ne.0) goto 100

rh(1:maxgrd)=gfld%fld(1:maxgrd)

print *, '----- Variable Relative Humidity for Current Time ------'
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

subroutine cal_dewpt(dpt,tmp,rhp,maxgrd)

! calculate dew point temperature
!
!    Compute Dew Point Temperature (Bolton 1980)
!    es = 6.112 * exp((17.67 * T)/(T + 243.5));
!    e = es * (RH/100.0);
!    Td = log(e/6.112)*243.5/(17.67-log(e/6.112));

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
!                  rhp  ---> relative humidity
!
!        output
!                  dpt  ---> dew point temperature

implicit none

integer maxgrd,ij
real dpt(maxgrd),tmp(maxgrd),rhp(maxgrd)
real T,Td,es,e,RH

do ij=1,maxgrd
  T=tmp(ij)-273.15
  RH=rhp(ij)
  es=6.112 * exp((17.67 * T)/(T + 243.5))
  e=es*(RH/100.0)
  Td=log(e/6.112)*243.5/(17.67-log(e/6.112))+273.15
  dpt(ij)=min(T+273.15,Td)
enddo

return
end

