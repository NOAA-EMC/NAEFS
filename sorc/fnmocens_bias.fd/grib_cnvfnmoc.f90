subroutine grib_cnvfnmoc_g2(gfld,ivar)

! invert NCEP data and let it start from south to north
!
!  parameters
!
!        gfld     ---> ensemble forecast

!        lpds     ---> grid descraption sction from NCEP GEFS data
!
!                      FNMOC/CMC global ensemble data (gfld%igdtmpl(j),j=1,gfld%igdtlen)
!                      6 0 0 0 0 0 0 360 181 0 0 -90000000 0 48 90000000 359000000 1000000 1000000 64
!                      start point (-90.0 0), end point ( 90.0, 359) 
!
!                      NCEP global ensemble data (gfld%igdtmpl(j),j=1,gfld%igdtlen)
!                      6 0 0 0 0 0 0 360 181 0 0 90000000 0 48 -90000000 359000000 1000000 1000000 0
!                      start point ( 90.0 0), end point (-90.0, 359) 
!
!         input:  
!                 gfld --->  before invert
!                 ivar ---> nember of variable
!
!         output:
!                 gfld --->  after invert
!

use grib_mod
use params

implicit none

type(gribfield) :: gfld
integer :: currlen=0
logical :: unpack=.true.

integer    maxgrd,i,j,ij,ijcv,ilon,ilat,ivar
integer    kgds(200),lgds(19)
data       lgds/6,0,0,0,0,0,0,360,181,0,0,-90000000,0,48,90000000,359000000,1000000,1000000,64/
real,      allocatable :: fgrid(:),temp(:)

! judge if all read in data have the same format as FNMOC GEFS

kgds(1:gfld%igdtlen)=gfld%igdtmpl(1:gfld%igdtlen)

if(kgds(12).eq.lgds(12).and.kgds(15).eq.lgds(15)) return

maxgrd=gfld%ngrdpts
allocate (fgrid(maxgrd),temp(maxgrd))

! invert forecast data 

print *, '   '
print *, '----- Reading In Data Before Invert, North to South ------'
call printinfr(gfld,ivar)

fgrid(1:maxgrd)=gfld%fld(1:maxgrd)

ilon=kgds(8)
ilat=kgds(9)

do i = 1, ilon
  do j = 1, ilat
   ij=(j-1)*ilon + i
   ijcv=(ilat-j)*ilon + i
   temp(ijcv)=fgrid(ij)
 enddo
enddo

!do i=1,11
!  kgds(i)=lgds(i)
!enddo

gfld%fld(1:maxgrd)=temp(1:maxgrd)

gfld%igdtmpl(12)=lgds(12)
gfld%igdtmpl(15)=lgds(15)

print *, '----- Reading In Data After Invert, South to North ------'
call printinfr(gfld,ivar)

return
end
