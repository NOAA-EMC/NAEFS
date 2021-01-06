subroutine debias_tmaxmin(fgrid,maxgrd,kens,fort1,fort2,fort3,fort4)

! adjust the CMC/FNMOC Tmax and Tmin

!   input
!         fort1   ---> CMC ensemble t2m forecast 6 hours ago
!         fort2   ---> CMC t2m forecast for current time   
!         fort3   ---> NCEP & CMC t2m analysis bias 6 hours ago
!         fort4   ---> NCEP & CMC t2m analysis bias for current Cycle
!         maxgrid ---> number of grid points in the defined grid
!
!   output
!         fgrid  ---> adjusted ensemble forecast tmax or tmin
!
!   parameters
!         kens(1) ---> ensemble perturbation number       
!         kens(2) ---> number of forecasts in ensemble    

use grib_mod
use params

implicit none

real        fgrid(maxgrd),anl_bias(maxgrd)
real        t2m(maxgrd),t2m_m06(maxgrd),t2m_bias(maxgrd),t2m_biasm06(maxgrd)

integer     kens(5)
integer     fort1,fort2,fort3,fort4,index,j
integer     iret,jret,iret_bias,iret_biasm06,ndata,maxgrd

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

type(gribfield) :: gfld,gfldo
logical :: unpack=.true.
logical :: expand=.false.

! get CMC T2m forecast 6 hour ago

iret=0

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1

ipdt(1)=0
ipdt(2)=0
ipdt(10)=103
ipdt(11)=0
ipdt(12)=2

ipdt(16)=kens(1)
ipdt(17)=kens(2)

ipdtn=1

print *, '----- CMC Ensemble Forecast T2m 6 hour ago ------'

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(fort1,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) print*, 'there is no t2m 6 hour ago'

if (iret.eq.0) then
  call grid_cnvncep_g2(gfld,0)
  t2m_m06(1:maxgrd)=gfld%fld(1:maxgrd)
endif

call gf_free(gfld)

! get CMC T2m forecast for current time

jret=0
iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1

ipdt(1)=0
ipdt(2)=0
ipdt(10)=103
ipdt(11)=0
ipdt(12)=2

ipdt(16)=kens(1)
ipdt(17)=kens(2)

ipdtn=1

print *, '----- CMC Ensemble Forecast T2m for Current Time ------'

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(fort2,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,jret)

if(jret.ne.0) print*, 'there is no t2m for current time'

if (jret.eq.0) then
  call grid_cnvncep_g2(gfldo,0)
  t2m(1:maxgrd)=gfldo%fld(1:maxgrd)
endif

! get NCEP & CMC T2m analysis bias 6 hour ago

iret_biasm06=0

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1

ipdt(1)=0
ipdt(2)=0
ipdt(10)=103
ipdt(11)=0
ipdt(12)=2

ipdtn=1

print *, '   '; print *, '----- NCEP & CMC T2m Analysis Bias 6 Hour Ago ------'

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(fort3,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_biasm06)

if(iret_biasm06.eq.0) call printinfr(gfld,0)
if(iret_biasm06.ne.0) print*, 'there is no t2m bias 6 hours ago'

if(iret_biasm06.eq.0) then
  call grid_cnvncep_g2(gfld,0)
  t2m_biasm06(1:maxgrd)=gfld%fld(1:maxgrd)
else
  t2m_biasm06(1:maxgrd)=0.0
endif

call gf_free(gfld)

! get NCEP & CMC T2m analysis bias 

iret_bias=0

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1

ipdt(1)=0
ipdt(2)=0
ipdt(10)=103
ipdt(11)=0
ipdt(12)=2

ipdtn=1
print *, '   '; print *, '----- NCEP & CMC T2m Analysis Bias for Current Cycle ------'

call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(fort4,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_bias)

if(iret_bias.ne.0) print*, 'there is no t2m bias for current time '

if(iret_bias.eq.0) then
  call grid_cnvncep_g2(gfld,0)
  t2m_bias(1:maxgrd)=gfld%fld(1:maxgrd)
else
  t2m_bias(1:maxgrd)=0.0
endif

if(iret.eq.0.and.jret.eq.0.and.iret_bias.eq.0.and.iret_biasm06.eq.0) then 
  call biastmaxtmin(fgrid,t2m_m06,t2m,t2m_biasm06,t2m_bias,anl_bias,maxgrd)
  gfld%fld(1:maxgrd)=anl_bias(1:maxgrd)
  print *, '   '; print *, '----- NCEP & CMC Analysis Bias for Tmax or Tmin ------'
  call printinfr(gfld,0)
else
  anl_bias(1:maxgrd)=0.0
  print *, '   '; print *, '----- NCEP & CMC Analysis Bias for Tmax or Tmin are 0 ------'
  print *, '   '
endif

call debias(anl_bias,fgrid,maxgrd)

call gf_free(gfld)
call gf_free(gfldo)

return
end

