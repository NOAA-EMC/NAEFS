program cmce_adjust_tmaxmin_g2 
!
! main program: cmce_adjust_tmaxmin 
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-10-01
!
! Program history log:
!  Date | Programmer | Comments
!  -----|------------|---------
!  2013-10-01 | Bo Cui       | Initial
!  2023-01-13 | Bo Cui       | Update CMC GRIB2 message with 10 more NCEP/GEFS ensemble members
!
! abstract: adjust CMC ensemble T2m, Tmax and Tmin for future downscaling process
!
! usage:
!
!   input file: cmc ensemble forecast                                          
!             : cmc accumulated analysis difference
!             : cmc accumulated analysis difference 6 hour ago
!             : cmc ensemble forecast t2m
!             : cmc ensemble forecast t2m 6 hour ago
!
!   output file: cmc adjusted tmax and tmin
!
!   parameters
!     nvar  -      : number of variables
!
! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgbe2          grib reader
!   putgbe2          grib writer
!   grid_cnvncep_g2  invert CMC data from north to south
!   init_parm        define grid definition and product definition
!   printinfr        print grib2 data information
!
! exit states:
!   cond =   0 - successful run
!   cond =   1 - I/O abort
!
! attributes:
!   language: fortran 90
!
!$$$

use grib_mod
use params

implicit none

integer     nmemd,nvar,ivar,i,k,im,imem,n
parameter   (nmemd=21,nvar=3)

real,       allocatable :: fgrid_im(:),fgrid_t2m(:)
real,       allocatable :: anl_bias(:),t2m_bias(:),t2m_biasm06(:)
real,       allocatable :: t2m_cmc(:),t2m_cmcm06(:)
integer     maxgrd,ndata,ifhr
integer     index,j,iret,jret             

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer ipd1(nvar),ipd2(nvar),ipd10(nvar),ipd11(nvar),ipd12(nvar)
integer kens(5)

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

! variables: t2m,tmax,tmin

data ipd1 /  0,  0,  0/
data ipd2 /  0,  4,  5/
data ipd10/103,103,103/
data ipd11/  0,  0,  0/
data ipd12/  2,  2,  2/

integer     iret_bias,iret_biasm06,iret_t2m,iret_t2mm06,ifdebias,iall_cmc
integer     iunit,lfipg(nmemd),lfipg1,lfipg2,lfipg3,icfipg(nmemd),icfipg1,icfipg2,icfipg3
integer     nfiles,iskip(nmemd),tfiles,ifile
integer     lfopg1,icfopg1

character*150 cfipg(nmemd),cfipg1,cfipg2,cfipg3,cfopg1

namelist /namens/nfiles,ifdebias,iskip,cfipg,cfipg1,cfipg2,cfipg3,ifhr,cfopg1
 
read (5,namens)
!write (6,namens)

! set the fort.* of intput file, open forecast files

if(nfiles.eq.0) goto 1010

print *, '   '
print *, 'Input files include '

iunit=9

tfiles=nfiles

do ifile=1,nfiles
  iunit=iunit+1
  icfipg(ifile)=iunit
  lfipg(ifile)=len_trim(cfipg(ifile))
  print *, 'fort.',icfipg(ifile), cfipg(ifile)(1:lfipg(ifile))
  call baopenr(icfipg(ifile),cfipg(ifile)(1:lfipg(ifile)),iret)
  if ( iret .ne. 0 ) then
    print *,'there is no NAEFS forecast, ifile ',cfipg(ifile)(1:lfipg(ifile))
    tfiles=nfiles-1
    iskip(ifile)=0
  endif
enddo

if(ifdebias.eq.1) then 

  ! set the fort.* of intput CMC t2m forecast 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg1=iunit
    lfipg1=len_trim(cfipg1)
    call baopenr(icfipg1,cfipg1(1:lfipg1),iret)
    print *, 'fort.',icfipg1, cfipg1(1:lfipg1)
    if(iret.ne.0) then
      print *,'there is no previous 6hr CMC forecast input ',cfipg1(1:lfipg1)
    endif
  endif

  ! set the fort.* of intput NCEP & CMC analysis difference   

  iunit=iunit+1
  icfipg2=iunit
  lfipg2=len_trim(cfipg2)
  call baopenr(icfipg2,cfipg2(1:lfipg2),iret)
  print *, 'fort.',icfipg2, cfipg2(1:lfipg2)
  if(iret.ne.0) then
    print *,'there is no NCEP & CMC analysis difference input ',cfipg2(1:lfipg2)
  endif

  ! set the fort.* of intput NCEP & CMC analysis difference 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg3=iunit
    lfipg3=len_trim(cfipg3)
    call baopenr(icfipg3,cfipg3(1:lfipg3),iret)
    print *, 'fort.',icfipg3, cfipg3(1:lfipg3)
    if(iret.ne.0) then
      print *,'there is no NCEP & CMC analysis difference (6h ago) input ',cfipg3(1:lfipg3)
    endif
  endif

endif

! set the fort.* of output file

print *, '   '
print *, 'Output files include '

iunit=iunit+1
icfopg1=iunit
lfopg1=len_trim(cfopg1)
call baopenwa(icfopg1,cfopg1(1:lfopg1),iret)
print *, 'fort.',icfopg1, cfopg1(1:lfopg1)
if(iret.ne.0) then
  print *,'there is no output ',cfopg1(1:lfopg1),iret
endif

! judge if all member are from CMC data, 1=all member are from CMC data
! iskip =  1 : ensemble member is from NCEP/GEFS
! iskip = -1 : ensemble member is from CMC/GEFS

iall_cmc=1

do imem=1,nfiles 
  if (iskip(imem).eq.1) then 
    iall_cmc=0
  endif
enddo

! find grib message

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(icfipg(2),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1010

maxgrd=gfld%ngrdpts
call gf_free(gfld)

allocate (fgrid_im(maxgrd))
allocate (anl_bias(maxgrd),t2m_bias(maxgrd),t2m_cmc(maxgrd))
allocate (t2m_biasm06(maxgrd),t2m_cmcm06(maxgrd))

print *, '   '

! loop over variables

t2m_bias=0.0
t2m_biasm06=0.0

do ivar = 1, nvar  

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ! read and process variable of input data

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  iret_bias=0
  iret_biasm06=0

  ! get NCEP & CMC analysis difference for t2m, there is no variables of tmax and tmin

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then

    ipdtn=1; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg2,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if(iret.eq.0) anl_bias(1:maxgrd)=gfld%fld(1:maxgrd)
    if(iret.ne.0) anl_bias=0.0

    t2m_bias=anl_bias

    print *, '   '
    print *, '----- NCEP & CMC T2m Analysis Bias for Current Cycle ------'
    if(iret.eq.0) call printinfr(gfld,ivar)
    if(iret.ne.0) print*, 'there is no bias for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

  endif

  call gf_free(gfld)

  ! loop over NAEFS members, get operational ensemble forecast

  do imem=1,nfiles 

    print *, '   '
    print *, '----- CMC Ensemble Forecast for Member ',imem-1,' ----'
    print *, '   '

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1

  ! read and process variable of input data

    ipdt(1)=ipd1(ivar)
    ipdt(2)=ipd2(ivar)
    ipdt(10)=ipd10(ivar)
    ipdt(11)=ipd11(ivar)
    ipdt(12)=ipd12(ivar)

    fgrid_im=-9999.9999

    if (iskip(imem).eq.0) goto 200

    if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      ipdtn=1; igdtn=-1
    elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      ipdtn=11; igdtn=-1
    elseif(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
      ipdtn=11; igdtn=-1
    endif
 
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg(imem),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

    if(iret.eq.0) call printinfr(gfldo,ivar)
    if(iret.ne.0) print*, 'there is no var for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

    ! start CMC data processing, invert & remove initial analyis difference between NCEP and CMC

    if(iret.eq.0) then

      call grid_cnvncep_g2(gfldo,ivar) 

      fgrid_im(1:maxgrd)=gfldo%fld(1:maxgrd)

      ! save ensemble identification number for future use 

      kens(3)=gfldo%ipdtmpl(17)

      ! adjust CMC ensemble forecast, first adjust variable t2m temperature 

      if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
        call debias(anl_bias,fgrid_im,maxgrd)
      endif

      ! adjust CMC ensemble forecast tmax & tmin

      if(ipd2(ivar).eq.5.or.ipd2(ivar).eq.4) then
      if(ipd1(ivar).eq.0.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then

        ! read in CMC one member t2m forecast 6 hour ago using the same kens message from above 

        iret_t2mm06=0

        iids=-9999;ipdt=-9999; igdt=-9999
        idisc=-1;  ipdtn=-1;   igdtn=-1

        ipdt(1)=0;ipdt(2)=0;ipdt(10)=103;ipdt(11)=0;ipdt(12)=2
        ipdt(17)=kens(3)

        print *, '----- CMC Ensemble Forecast T2m 6 hour ago ------'

        ipdtn=1; igdtn=-1
        call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
        call getgb2(icfipg1,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_t2mm06)

        if(iret_t2mm06.eq.0) then
          call printinfr(gfld,ivar)
          call grid_cnvncep_g2(gfld,ivar) 
          t2m_cmcm06(1:maxgrd)=gfld%fld(1:maxgrd)
        endif

        if(iret_t2mm06.ne.0) print*, 'there is no t2m for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

        call gf_free(gfld)

        ! read in CMC one member t2m fcst at current time using the same kens message from above 

        iret_t2m=0

        print *, '----- CMC Ensemble Forecast T2m Current Time ------'
        ipdtn=1; igdtn=-1
        ipdt(17)=kens(3)
        call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
        call getgb2(icfipg(imem),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_t2m)

        if(iret_t2m.eq.0) call grid_cnvncep_g2(gfld,ivar) 
        if(iret_t2m.eq.0) t2m_cmc(1:maxgrd)=gfld%fld(1:maxgrd)

        if(iret_t2m.eq.0) call printinfr(gfld,ivar)
        if(iret_t2m.ne.0) print*, 'there is no t2m for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

        call gf_free(gfld)

        ! get NCEP & CMC T2m analysis difference 6 hour ago

        iret_biasm06=0

        ipdtn=1; igdtn=-1
        ipdt(17)=-9999   

        call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
        call getgb2(icfipg3,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_biasm06)

        if(iret_biasm06.eq.0) call grid_cnvncep_g2(gfld,ivar) 
        if(iret_biasm06.eq.0) t2m_biasm06(1:maxgrd)=gfld%fld(1:maxgrd)

        print *, '----- NCEP & CMC T2m Analysis Bias 6 Hour Ago ------'
        if(iret_biasm06.eq.0) call printinfr(gfld,ivar)
        if(iret_biasm06.ne.0) print*, 'there is no t2m bias for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

        call gf_free(gfld)

        ! get NCEP & CMC T2m analysis difference for current time 

        iret_bias=0

        print *, '----- NCEP & CMC T2m Analysis Bias for Current Cycle ------'

        ipdtn=1; igdtn=-1
        call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
        call getgb2(icfipg2,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_bias)

        if(iret_bias.eq.0) t2m_bias(1:maxgrd)=gfld%fld(1:maxgrd)

        if(iret_bias.eq.0) call printinfr(gfld,ivar)
        if(iret_bias.ne.0) print*, 'there is no t2m bias for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

        call gf_free(gfld)

        if(iret_t2m.eq.0.and.iret_t2mm06.eq.0.and.iret_bias.eq.0.and.iret_biasm06.eq.0) then
          call biastmaxtmin(fgrid_im,t2m_cmcm06,t2m_cmc,t2m_biasm06,t2m_bias,anl_bias,maxgrd)
          gfldo%fld(1:maxgrd)=anl_bias(1:maxgrd)
          print *, '----- NCEP & CMC Analysis Bias for Tmax or Tmin ------'
          call printinfr(gfldo,ivar)
        else
          anl_bias=0.0
          print *, ' '
          print *, '----- NCEP & CMC Analysis Bias for Tmax or Tmin Are Zero ------'
          print *, ' '
        endif

!       gfldo%fld(1:maxgrd)=anl_bias(1:maxgrd)
!       print *, '----- NCEP & CMC Analysis Bias for Tmax or Tmin ------'
!       call printinfr(gfld,ivar)

        call debias(anl_bias,fgrid_im,maxgrd)

      endif
      endif

      print *, '----- After Debias CMC Forecast for Current Time ------'

      !  adjust the cmc ensmeble message for future combination
      
      gfldo%fld(1:maxgrd)=fgrid_im(1:maxgrd)
      gfldo%ipdtmpl(17)=30+gfldo%ipdtmpl(17)

      ! check GRID TEMPLATE
     
      ! if(gfldo%igdtmpl(1).eq.0) gfldo%igdtmpl(1)=6

      call putgb2(icfopg1,gfldo,iret)
      call printinfr(gfldo,ivar)
      call gf_free(gfldo)

    endif      ! end of iret equal to 0

    200 continue

  enddo          ! end of imem loop

enddo

! end of ivar loop                                      

! close files

do ifile=1,nfiles
  call baclose(icfipg(ifile),iret)
enddo

call baclose(icfipg1,iret)
call baclose(icfipg2,iret)
call baclose(icfipg3,iret)

call baclose(icfopg1,iret)

print *,'   '
print *,'CMC Tmax & Tmin Adjustment Process Successfully Complete'
stop

1010 print *, ' There is no CMC pgb file !!! '
stop

end

subroutine debias(bias,fgrid,maxgrd)

!   adjust cmc forecast
!
!   input
!         fgrid   ---> ensemble forecast
!         bias    ---> bias estimation
!         maxgrid ---> number of grid points in the defined grid
!
!   output
!         fgrid  ---> adjusted ensemble forecast

implicit none

integer maxgrd,ij
real bias(maxgrd),fgrid(maxgrd)

do ij=1,maxgrd
  if(fgrid(ij).gt.-9999.0.and.fgrid(ij).lt.999999.0.and.bias(ij).gt.-9999.0.and.bias(ij).lt.999999.0) then
    fgrid(ij)=fgrid(ij)-bias(ij)
  else
    fgrid(ij)=fgrid(ij)
  endif
enddo

return
end


subroutine biastmaxtmin(fgrid,t2m_cmcm06,t2m_cmc,t2m_biasm06,t2m_bias,anl_bias,maxgrd)

! calculate Tmax and Tmin bias 
!
!         bias=a*t2m_biasm06+b*t2m_bias
!
! input       
!        fgrid       ---> tmax or tmin forecast
!        t2m_cmcm06  ---> t2m ensemble forecas 6hr ago
!        t2m_cmc     ---> t2m ensemble forecast 
!        t2m_biasm06 ---> t2m analysis difference 6hr ago
!        t2m_bias    ---> t2m analysis difference
!        maxgrid ---> number of grid points in the defined grid
!
!   output
!        anl_bias ---> Tmax and Tmin bias estimation
!

implicit none

integer maxgrd,ij
real t2m_biasm06(maxgrd),t2m_bias(maxgrd),t2m_cmc(maxgrd),t2m_cmcm06(maxgrd)
real fgrid(maxgrd),anl_bias(maxgrd)
real lmta,ym,y0,y1,a,b

do ij=1,maxgrd
  ym=fgrid(ij)
  y0=t2m_cmcm06(ij)
  y1=t2m_cmc(ij)
  if(ym.gt.-9999.0.and.ym.lt.999999.0.and.y0.gt.-9999.0.and.y0.lt.999999.0.and.y1.gt.-9999.0.and.y1.lt.999999.0) then
    if(ym.ne.y1.and.ym.ne.y0) then
      lmta=sqrt(abs((ym-y0)/(ym-y1)))
      a=lmta/(1+lmta)
      b=1/(1+lmta)
    else
      if(ym.eq.y1.and.ym.ne.y0) then
        a=0.0
        b=1.0
      endif
      if(ym.eq.y1.and.ym.eq.y0) then
        a=0.5
        b=0.5
      endif
      if(ym.ne.y1.and.ym.eq.y0) then
        a=1.0
        b=0.0
      endif
    endif
  endif
  anl_bias(ij)=a*t2m_biasm06(ij)+b*t2m_bias(ij)
!if(ij.eq.8601) then 
! print *, 'a=',a,' b=', b, ' bias=', anl_bias(ij)
! print *, 't2m_biasm06=',t2m_biasm06(ij),' t2m_bias(ij)=',t2m_bias(ij) 
!endif
enddo

!print *, 'in tmaxtmin'

return
end









