       program gefs_r2_grb2
!
! main program: gefs_r2_grb2
!
! prgmmr: Hong Guan        org:Hong.Guan         date: 2016-08-16
!
! abstract: update r combination coefficient between analysis and NCEP ensemble mean forecast 
!
! usage:
!
!   input file: grib
!     unit 12 -    : analysis
!     unit 13 -    : analysis for Tmax, Tmin and ULWRF
!     unit 14 -    : ncep operational forecast
!
!     unit 20 -    : input abar pgrba file
!     unit 21 -    : input fbar pgrba file
!     unit 22 -    : input saabar pgrba file
!     unit 23 -    : input sffbar pgrba file
!     unit 24 -    : input sfabar pgrba file
!
!   output file: grib
!
!     unit 40 -    : updated abar pgrba file
!     unit 41 -    : updated fbar pgrba file
!     unit 42 -    : updated saabar pgrba file
!     unit 43 -    : updated sffbar pgrba file
!     unit 44 -    : updated sfabar pgrba file
!     unit 45 -    : updated r2 pgrba file

!   parameters
!     fgrid -      : ensemble forecast
!     agrid -      : analysis data (GDAS)
!     dec_w -      : decay averaging weight 
!     nvar  -      : number of variables

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgbe2           grib2 reader
!   putgbe2           grib2 writer
!   init_parm        define grid definition and product definition
!
! attributes:
!   language: fortran 90
!
! notes:
!
!      fbar (decaying average forecast)
!      abar (decaying average analysis)
!      saabar (decaying average analysis variance)
!      sffbar (decaying average forecast variance)
!      sfabar (decaying average analysis-forecast co-variance)

!$$$

use grib_mod
use params
use naefs_mod

implicit none

integer     ivar,i,k,icstart,odate

real,       allocatable :: agrid(:),fgrid(:)
real,       allocatable :: abar(:),fbar(:)
real,       allocatable :: saabar(:),sffbar(:),sfabar(:),r2(:)
real        dec_w

integer     afile,afile_m06,cfile
integer     abarfile,fbarfile,saabarfile,sffbarfile,sfabarfile,orfile
integer     oabar,ofbar,osaabar,osffbar,osfabar,or2
integer     iii

integer     maxgrd,ndata,FHR
integer     ipd11_new(nvar),ipd12_new(nvar)
integer     index,j,n,iret,jret             
integer     iret_abar,iret_fbar,iret_saabar,iret_sffbar,iret_sfabar 

character*7 cfortnn,cfortnn1,cfortnn2,cfortnn3,cfortnn4,cfortnn5,cfortnn6
character*4 nens

character*10  ffd(nvar)
integer     jpd1(nvar),jpd2(nvar),jpd10(nvar),jpd11(nvar),jpd12(nvar)
integer     ifvar(nvar),jnvar,jvar
integer     ipdtnum_out                               
real        bar0(nvar),bar(nvar)

namelist/message/icstart,nens,dec_w,odate,FHR
namelist/varlist/ffd,bar,jpd1,jpd2,jpd10,jpd11,jpd12,jnvar

read(5,message,end=1020)
write(6,message)

read (5,varlist,end=1020)
!write(6,varlist)

! set the fort.* of intput files

afile=12
cfile=14

abarfile=20
fbarfile=21
saabarfile=22
sffbarfile=23
sfabarfile=24

oabar=40
ofbar=41
osaabar=42
osffbar=43
osfabar=44
or2=45

write(cfortnn,'(a5,i2)') 'fort.',cfile
call baopenr(cfile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no NCEP forecast data, stop!'; endif
if (iret .ne. 0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no analysis data, stop!'; endif
if (iret .ne. 0) goto 1020

if(icstart.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',abarfile
  call baopenr(abarfile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no abar data, stop!'; endif
  if (iret .ne. 0) goto 1020

  write(cfortnn,'(a5,i2)') 'fort.',fbarfile
  call baopenr(fbarfile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no fbar data, stop!'; endif
  if (iret .ne. 0) goto 1020

  write(cfortnn,'(a5,i2)') 'fort.',saabarfile
  call baopenr(saabarfile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no saabar data, stop!'; endif
  if (iret .ne. 0) goto 1020

  write(cfortnn,'(a5,i2)') 'fort.',sffbarfile
  call baopenr(sffbarfile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no sffbar data, stop!'; endif
  if (iret .ne. 0) goto 1020

  write(cfortnn,'(a5,i2)') 'fort.',sfabarfile
  call baopenr(sfabarfile,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no sfabar data, stop!'; endif
  if (iret .ne. 0) goto 1020
endif

! set the fort.* of output files

! output abar, fbar, saabar, sffbar, sfabar, r estimation

write(cfortnn1,'(a5,i2)') 'fort.',oabar
call baopenw(oabar,cfortnn1,iret)

write(cfortnn2,'(a5,i2)') 'fort.',ofbar
call baopenw(ofbar,cfortnn2,iret)

write(cfortnn3,'(a5,i2)') 'fort.',osaabar
call baopenw(osaabar,cfortnn3,iret)

write(cfortnn4,'(a5,i2)') 'fort.',osffbar
call baopenw(osffbar,cfortnn4,iret)

write(cfortnn5,'(a5,i2)') 'fort.',osfabar
call baopenw(osfabar,cfortnn5,iret)

write(cfortnn6,'(a5,i2)') 'fort.',or2
call baopenw(or2,cfortnn6,iret)

! find grib message, maxgrd: number of grid points in the defined grid

iret=0
ipdt=-9999; igdt=-9999
ipdtn=-1; igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt)
call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
maxgrd=gfld%ngrdpts
call gf_free(gfld)

if (iret .ne. 0) then; print*,' getgb2 ,cfile, iret =',cfile, iret; endif
if (iret .ne. 0) goto 1020

! get NCEP ensemble ipdt message: fixed surface and its scaled value

call getipdt_g2_surface(cfile,ipd11_new,ipd12_new)
ipd11=ipd11_new
ipd12=ipd12_new

! judge if variable are included

ifvar(1:nvar)=0

do ivar = 1, nvar
  do jvar = 1, jnvar
    if( ipd1(ivar).eq. jpd1(jvar).and.   &
        ipd2(ivar).eq. jpd2(jvar).and.   &
       ipd10(ivar).eq.jpd10(jvar).and.   &
       ipd11(ivar).eq.jpd11(jvar).and.   &
       ipd12(ivar).eq.jpd12(jvar) ) then
       ifvar(ivar)=1
       bar0(ivar)=bar(jvar)
       exit
    else
      ifvar(ivar)=0
    endif
  enddo
enddo

allocate(agrid(maxgrd), fgrid(maxgrd),abar(maxgrd),r2(maxgrd), &
          fbar(maxgrd),sffbar(maxgrd),saabar(maxgrd),sfabar(maxgrd))

do ivar = 1, nvar  
 if(ifvar(ivar).eq.1) then

  iret=0
  iret_abar=0
  iret_fbar=0
  iret_saabar=0
  iret_sffbar=0
  iret_sfabar=0 

  agrid=-9999.99
  fgrid=-9999.99
  r2=-9999.99
  abar=0.
  fbar=0.
  saabar=0.
  sffbar=0.
  sfabar=0.

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized mean estimation

  if(icstart.eq.1) then
    print *, '----- Cold Start for Mean Estimation -----'
    print*, '  '
    saabar= 0.0
    sffbar= 0.0
    sfabar= 0.0
    abar = bar0(ivar)
    fbar = bar0(ivar)
  else
    print *, '----- Initialized Five Bar for Current Time -----'
    print*, '  '

    igdtn=-1
    ipdtn=15            

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(abarfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_abar)
    if(iret_abar.ne.0) then
      print*, 'There is no abar variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if(iret_abar .eq. 0) then
      abar(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      abar=0.0
    endif

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(fbarfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_fbar)
    if(iret_fbar.ne.0) then
      print*, 'There is no fbar variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if(iret_fbar .eq. 0) then
      fbar(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      fbar=0.0
    endif

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(saabarfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_saabar)
    if(iret_saabar.ne.0) then
      print*, 'There is no saabar variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if(iret_saabar .eq. 0) then
      saabar(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      saabar=0.0
    endif

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(sffbarfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_sffbar)
    if(iret_sffbar.ne.0) then
      print*, 'There is no sffbar variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if(iret_sffbar .eq. 0) then
      sffbar(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      sffbar=0.0
    endif

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(sfabarfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_sfabar)
    if(iret_sfabar.ne.0) then
      print*, 'There is no variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
    endif

    if(iret_sfabar .eq. 0) then
      sfabar(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
      call gf_free(gfld)
    else
      sfabar=0.0
    endif

  endif

  ! get ensemble forecast

  print *, '----- NCEP Ensemble Forecast for Current Time ------'
  print*, '  '

  ! ipdnm for ensemble average forecast

  igdtn=-1

  if(nens.eq.'avg') ipdtn=ipdnm(ivar)

  call init_parm(ipdtn,ipdt,igdtn,igdt)
  call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if(iret.ne.0) then
    print*, 'There is no forecast variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    print *, ' '
    call gf_free(gfldo)
  endif

  if(iret.ne.0) goto 100

  if(iret.eq.0) then
    call printinfr(gfldo,ivar)
    fgrid(1:maxgrd)=gfldo%fld(1:maxgrd)
  endif

  ! get analysis data

  print *, '----- Analysis for Current Time ------'
  print *, ' '

  igdtn=-1; ipdtn=ipdn(ivar)

  call init_parm(ipdtn,ipdt,igdtn,igdt)
  call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if(iret.ne.0) then
    print*, 'There is no analysis variable', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    print *, ' '
    call gf_free(gfld)
  endif

  if(iret.ne.0) goto 100

  if(iret.eq.0) then
    call printinfr(gfld,ivar)
    agrid(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  call gf_free(gfld)

  ! apply the decay average

  ! judge if all 5 bars files have correct data set

  if( iret_abar.eq.0.and.iret_fbar.eq.0.and.iret_saabar.eq.0.and.  &
    iret_sffbar.eq.0.and.iret_sfabar.eq.0) then

    print*, ' Apply Decay Method to Update 5 Bar Files '
    print*, ' '

    call decay(abar,agrid,agrid,maxgrd,dec_w,1)
    call decay(fbar,fgrid,fgrid,maxgrd,dec_w,1)
    call decay(saabar,agrid-abar,agrid-abar,maxgrd,dec_w,2)
    call decay(sffbar,fgrid-fbar,fgrid-fbar,maxgrd,dec_w,2)
    call decay(sfabar,agrid-abar,fgrid-fbar,maxgrd,dec_w,2)

    ! calculate squared correlation coefficient (65160=360*181)

    do iii=1,maxgrd
      if(saabar(iii).ne.0.and.sffbar(iii).ne.0) then
        if(saabar(iii).ne.-9999.99.and.sffbar(iii).ne.-9999.99.and.sfabar(iii).ne.-9999.99) then
          r2(iii)=100.*sfabar(iii)/sqrt(saabar(iii)*sffbar(iii))
          if(r2(iii).gt.100.) r2(iii)=100.                       
          r2(iii)=INT(r2(iii))/100.
        endif
      else
        r2(iii)=1.                                              
      endif
    enddo

    ! r2 = 1.  use decaying bias estimation only in calbration process
    ! r2 = 0.  poor correlation, use reforecast bias estimation only

    do iii=1,maxgrd
      if(r2(iii).gt.1.) then
        r2(iii)=1.
      endif
      if(r2(iii).lt.0.0.and.r2(iii).ne.-9999.99) then
        r2(iii)=0.
      endif
!     if(r2(iii).ne.-9999.99) then
!       r2(iii)=(r2(iii))*(r2(iii))
!     endif
    enddo

  else

  ! reset 5 bars and r2 in case no 5 normal data-set available  

    print*, ' '
    print*, ' No Update 5 Bar Files, Reset Values '
    print*, ' '

    r2=1.
!   abar=0.
!   fbar=0.
    saabar=0.
    sffbar=0.
    sfabar=0.
    abar = bar0(ivar)
    fbar = bar0(ivar)

  endif

  ! end of judge if all 5 bars files have correct data set

  ! save the output data

  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

  if(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.5) then
    continue
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.1) then
    gfldo%idrtmpl(3)=2
  elseif(gfldo%ipdtmpl(1).eq.3.and.gfldo%ipdtmpl(2).eq.0) then
    gfldo%idrtmpl(3)=2
  else
    gfldo%idrtmpl(3)=2
  endif

  ! change product difinition template from 4.1/4.11/4.2/4.12 to 4.15
  ! need change gfldo%ipdtmpl(16) and gfldo%ipdtmpl(17) 
  ! gfldo%ipdtmpl(16): statistical process used within the spatial area(Code Table 4.10) 
  ! gfldo%ipdtmpl(17): type of spatial processing(Code Table 4.15)
  ! gfldo%ipdtmpl(17)=0 : Data is calculated directly from the source 
  !                       grid with no interpolation (see note 1)

  if(gfldo%ipdtnum.eq.2.or.gfldo%ipdtnum.eq.1) then
    ipdtnum_out=15
    call change_template4(gfldo%ipdtnum,ipdtnum_out,gfldo)
    gfldo%ipdtmpl(17)=0
  endif

  if(gfldo%ipdtnum.eq.12.or.gfldo%ipdtnum.eq.11) then
    ipdtnum_out=15
    call change_template4(gfldo%ipdtnum,ipdtnum_out,gfldo)
    gfldo%ipdtmpl(17)=0
  endif

  gfldo%ipdtnum=15

  print *, '----- Output abar for Current Time ------'
  print *, ' '
  
  ! abar (decaying average analysis)
  ! gfldo%ipdtmpl(3)=0  : analysis in code table 4.3
  ! gfldo%ipdtmpl(16)=0 : average in code table 4.10

  gfldo%ipdtmpl(3)=0
  gfldo%ipdtmpl(16)=0
  gfldo%fld(1:maxgrd)=abar(1:maxgrd)
  call putgb2(oabar,gfldo,jret)
  call printinfr(gfldo,ivar)

  print *, '----- Output fbar for Current Time ------'
  print *, ' '
  
  ! fbar (decaying average forecast)
  ! gfldo%ipdtmpl(3)=4  : ensemble forecast in code table 4.3
  ! gfldo%ipdtmpl(16)=0 : average in code table 4.10

  gfldo%ipdtmpl(3)=4
  gfldo%ipdtmpl(16)=0
  gfldo%fld(1:maxgrd)=fbar(1:maxgrd)
  call putgb2(ofbar,gfldo,jret)
  call printinfr(gfldo,ivar)

  print *, '----- Output saabar for Current Time ------'
  print *, ' '
  
  ! saabar (decaying average analysis variance) 
  ! gfldo%ipdtmpl(3)=0    : analysis in code table 4.3
  ! gfldo%ipdtmpl(16)=208 : variance in code table 4.10

  gfldo%ipdtmpl(3)=0
  gfldo%ipdtmpl(16)=208
  gfldo%fld(1:maxgrd)=saabar(1:maxgrd)
  call putgb2(osaabar,gfldo,jret)
  call printinfr(gfldo,ivar)

  print *, '----- Output sffbar for Current Time ------'
  print *, ' '
  
  ! sffbar (decaying average forecast variance) 
  ! gfldo%ipdtmpl(3)=4    : ensemble forecast in code table 4.3
  ! gfldo%ipdtmpl(16)=208 : variance in code table 4.10

  gfldo%ipdtmpl(3)=4
  gfldo%ipdtmpl(16)=208
  gfldo%fld(1:maxgrd)=sffbar(1:maxgrd)
  call putgb2(osffbar,gfldo,jret)
  call printinfr(gfldo,ivar)

  print *, '----- Output sfabar for Current Time ------'
  print *, ' '
  
  ! sfabar (decaying average analysis-forecast co-variance)
  ! gfldo%ipdtmpl(3)=4  : ensemble forecast in code table 4.3
  ! gfldo%ipdtmpl(16)=7 : covariance in code table 4.10

  gfldo%ipdtmpl(3)=4
  gfldo%ipdtmpl(16)=7
  gfldo%fld(1:maxgrd)=sfabar(1:maxgrd)
  call putgb2(osfabar,gfldo,jret)
  call printinfr(gfldo,ivar)

  print *, '----- Output R for Current Time ------'
  print *, ' '

  ! gfldo%ipdtmpl(3)=4    : ensemble forecast in code table 4.3
  ! gfldo%ipdtmpl(16)=209 : coefficient in code table 4.10 

  gfldo%ipdtmpl(3)=4
  gfldo%ipdtmpl(16)=209
! gfldo%idrtmpl(3)=4
  gfldo%fld(1:maxgrd)=r2(1:maxgrd)
  call putgb2(or2,gfldo,jret)
  call printinfr(gfldo,ivar)
  call gf_free(gfldo)

  100 continue

! end of estimation 

 endif
enddo
 
call baclose(afile,iret)
call baclose(cfile,iret)

call baclose(abarfile,iret)
call baclose(fbarfile,iret)
call baclose(saabarfile,iret)
call baclose(sffbarfile,iret)
call baclose(sfabarfile,iret)

call baclose(oabar,iret)
call baclose(ofbar,iret)
call baclose(osaabar,iret)
call baclose(osffbar,iret)
call baclose(osfabar,iret)
call baclose(or2,iret)

deallocate(agrid, fgrid,abar, &
           fbar,sffbar,saabar,sfabar,r2)

print *,'R2 Estimation Successfully Complete'

stop

1020  continue

stop
end


      subroutine decay(da,a1,a2,maxgrd,dw,ic)

!     apply the decaying average scheme -- Bo Cui (WX20CB) 12/15/2008
!     aad the case for the product of two parameters -- Hong Guan (Hong.Guan) 08/17/2016
!
!     parameters
!         inputs:
!            da ---> prior decaying average
!            a1 ---> analysis/forecast
!            a2 ---> analysis/forecast
!            dw ---> decaying weight
!            ic ---> 1: using a1 only - (a1)
!               ---> 2: using a1 and a2 (a1*a2)
!         output:
!            da ---> new decaying average
!         special value -- -9999.99
!

      dimension a1(maxgrd),a2(maxgrd),da(maxgrd)


      do ij = 1, maxgrd
        if (ic.eq.1) then
          if (a1(ij).ne.-9999.99) then
            if (da(ij).ne.-9999.99) then
              da(ij) = (1.0-dw)*da(ij) + dw*a1(ij)
            else
              da(ij) =                 +    a1(ij)
              if (ij.eq.10000) then
                print *, "===========   Warning   ============="
                print *, " input priors are special values!!!  "
                print *, "====================================="
              endif
            endif
          else
            if (ij.eq.10000) then
              print *, "===========   Warning   ============="
              print *, " input a1/a2  are special values!!!  "
              print *, "====================================="
            endif
          endif
        else if (ic.eq.2) then
          if (a1(ij).ne.-9999.99.and.a2(ij).ne.-9999.99) then
            if (da(ij).ne.-9999.99) then
              da(ij) = (1.0-dw)*da(ij) + dw*a1(ij)*a2(ij)
            else
              da(ij) =                 +    a1(ij)*a2(ij)
              if (ij.eq.10000) then
                print *, "===========   Warning   ============="
                print *, " input priors are special values!!!  "
                print *, "====================================="
              endif
            endif
          else
            if (ij.eq.10000) then
              print *, "===========   Warning   ============="
              print *, " input a1/a2  are special values!!!  "
              print *, "====================================="
            endif
          endif
        else
          print *, "======= Problem, check up!!! ======="
          print *, " ic = ", ic, " is not defined, quit!!! "
          return
        endif
      enddo
      return
      end

