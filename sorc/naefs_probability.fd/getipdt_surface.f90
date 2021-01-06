subroutine getipdt_g2_surface(fort,nvar,ipd1,ipd2,ipd10,ipd11,ipd12,ipd11_new,ipd12_new)

! program: getipdt_g2_surface
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-10-01
!
! abstract:    get product definitation template gfld%ipdtmpl(11) and gfld%ipdtmpl(12)

! parameters
!           gfld%ipdtmpl(10): type of first fixed surface
!           gfld%ipdtmpl(11): scale factor of first fixed surface
!           gfld%ipdtmpl(12): scaled value of first fixed surface
!
!        input
!                  fort  ---> fort number to input record
!
!        output
!                  ipd11_new ---> scale factor of first fixed surface
!                  ipd12_new ---> scaled value of first fixed surface
!

use grib_mod
use params

implicit none

type(gribfield) :: gfld

integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: jids,iids,ipdt,igdt
integer idisc,ipdtn,igdtn
integer nvar                      

integer ipd1(nvar),ipd2(nvar),ipd10(nvar),ipd11(nvar),ipd12(nvar)

integer j,iret,fort

integer pl_tmp,pl_ncep,icount,ivar,iskp
integer ipd11_tmp(nvar),ipd12_tmp(nvar)
integer ipd11_new(nvar),ipd12_new(nvar)

ipd11_tmp=-9999
ipd12_tmp=-9999

idisc=-1; ipdtn=-1; igdtn=-1
iids=-9999; ipdt=-9999; igdt=-9999

icount=0
iskp=0
do
  call getgb2(fort,0,iskp,idisc,iids,ipdtn,ipdt,igdtn,igdt,unpack,iskp,gfld,iret)

  if(iret.eq.0) then

    icount=icount+1

!   call printinfr(gfld,icount)

    pl_tmp=int(gfld%ipdtmpl(12)*(10**abs(gfld%ipdtmpl(11))))

    do ivar = 1, nvar
      pl_ncep=ipd12(ivar)/(10**ipd11(ivar))

      if(gfld%ipdtmpl(1).eq.ipd1(ivar).and.  &
        gfld%ipdtmpl(2).eq.ipd2(ivar).and.  &
        gfld%ipdtmpl(10).eq.ipd10(ivar).and.pl_tmp.eq.pl_ncep) then
        ipd11_tmp(ivar)=gfld%ipdtmpl(11)
        ipd12_tmp(ivar)=gfld%ipdtmpl(12)
        go to 100
      endif
    enddo

    100 continue

  endif

  if(iret.ne.0) then
    if(iret.eq.99 ) exit
    print *,' getgb2 error = ',iret
    cycle
  endif

  call gf_free(gfld)

enddo

ipd11_new=ipd11
ipd12_new=ipd12

do ivar = 1, nvar
  if(ipd11_tmp(ivar).ne.-9999) then
    if(ipd11_tmp(ivar).ne.ipd11(ivar)) then
!     print *,' Warning, ipd11 Changed ', ipd11_tmp(ivar),ipd11(ivar)
      ipd11_new(ivar)=ipd11_tmp(ivar)
    endif
  endif
  if(ipd12_tmp(ivar).ne.-9999) then
    if(ipd12_tmp(ivar).ne.ipd12(ivar)) then
!     print *,' Warning, ipd12 Changed ', ipd12_tmp(ivar),ipd12(ivar)
      ipd12_new(ivar)=ipd12_tmp(ivar)
    endif
  endif
enddo

return
end

