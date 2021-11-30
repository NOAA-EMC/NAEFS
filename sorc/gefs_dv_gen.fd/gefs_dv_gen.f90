program gefs_dv_gen
!
! main program: gefs_dv_gen          
!
! prgmmr: Bo Cui           org: np/wx20        date: 2016-10-01
!
! abstract: calculate downscaling vector for 03z 09z 15z and 21z
! 
!  PROGRAM HISTORY LOG:
!    2021-11-12  Bo Cui - update code for new g2 lib routine gf_free,the old gf_free use to
!                         nullify a pointer, and the newer one deallocates it.  
! usage:
!
!   input file: downscaling vector at cyc-03 and cyc+03
!
!   output file: downscaling vector at cyc

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib reader
!   putgb2           grib writer
!   init_parm        define grid definition and product definition
!   printinfr        print grib2 data information

! exit states:
!   cond =   0 - successful run
!   cond =   1 - I/O abort
!
! attributes:
!   language: fortran 90
!
! notes:
!       1. tmax and tmin at 3hr,9hr,15hr... are for 3 hour period. Bias from 06hr, 12hr
!          and etc. are for 6 hour period. Therefor, no bias output for tmax and tmin
!       2. tcdc and ulwrf are also for 3 hour average at 3hr, 9hr and ect. no output
!$$$

use grib_mod
use params

implicit none

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: kids,kpdt,kgdt
integer kskp,kdisc,kpdtn,kgdtn

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer     n,inum 
parameter   (inum=2)

real, allocatable :: fbias(:,:),bias_avg(:)
real  weight(inum)

integer     maxgrd,iret,jret,icount,i
integer     ipd1,ipd2,ipd3,ipd10,ipd11,ipd12,ipdn
integer     iunit,icfipg(inum)
integer     nfiles,iskip(inum),tfiles,ifile
integer     lfopg1,icfopg1,lenfile

character*150 cfipg(inum)
character*100 cfopg1

real    gmin,gmax
integer nbit

namelist /namens/cfipg,nfiles,iskip,cfopg1
 
read (5,namens)
!write (6,namens)

print *, ' '; print *, 'Input files size ', nfiles                  

if(nfiles.eq.0) goto 1020

! set the fort.* of intput file, open forecast files

print *, '   '
print *, 'Input files include '

iunit=10

do ifile=1,inum   
  iunit=iunit+1
  icfipg(ifile)=iunit
  lenfile=len_trim(cfipg(ifile))
  if(iskip(ifile).eq.0) then 
    print *, 'fort.',iunit, cfipg(ifile)(1:lenfile)
    call baopenr(icfipg(ifile),cfipg(ifile)(1:lenfile),iret)
    if ( iret .ne. 0 ) then
      print *,'there is no GEFS bias, ifile,iret = ',cfipg(ifile)(1:lenfile),iret
    endif
  endif
enddo

! set the fort.* of output file

print *, '   '
print *, 'Output files include '

iunit=iunit+1
icfopg1=iunit
lfopg1=len_trim(cfopg1)
call baopenwa(icfopg1,cfopg1(1:lfopg1),iret)
print *, 'fort.',icfopg1, cfopg1(1:lfopg1)
if(iret.ne.0) then
  print *,'there is no Output DV average =  ',cfopg1(1:lfopg1),iret
endif

! find grib message, maxgrd: number of grid points in the defined grid

do ifile=1,inum  
  if(iskip(ifile).eq.0) then 
    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    if(iret.eq.0) maxgrd=gfld%ngrdpts
    call gf_free(gfld)
    if(iret.eq.0) exit
  endif       
enddo

if(iret.ne.0) print *,'there is no maxgrd information'
if(iret.ne.0) goto 1020

allocate(fbias(maxgrd,inum),bias_avg(maxgrd))

print *, '   '

! loop over all variables

kids=-9999;kpdt=-9999; kgdt=-9999
kdisc=-1;  kpdtn=-1;   kgdtn=-1

icount=0
kskp=0
if(iskip(2).eq.1) jskp=0

do
 
  fbias=-9999.9999

  iret=99
  if(iskip(2).eq.0) then 
    call getgb2(icfipg(2),0,kskp,kdisc,kids,kpdtn,kpdt,kgdtn,kgdt,unpack,kskp,gfld,iret)
    if(iret.ne.0) then
      if(iret.eq.99 ) exit
      print *,' getgb2 error = ',iret
      cycle
    endif

    icount=icount+1

    print *, '----- Start Read Downscaling Vector 3hr Later ------'
    print *, '   '

    if(iret.eq.0) then
      call printinfr(gfld,icount)
      fbias(1:maxgrd,2)=gfld%fld(1:maxgrd)
    else
      print*, 'there is no bias for 3hr later'
      print *, '   '
      fbias(1:maxgrd,2)=0.0                        
    endif

    ! save parameter message for other members 

    ipd1=gfld%ipdtmpl(1)
    ipd2=gfld%ipdtmpl(2)
    ipd3=gfld%ipdtmpl(3)
    ipd10=gfld%ipdtmpl(10)
    ipd11=gfld%ipdtmpl(11)
    ipd12=gfld%ipdtmpl(12)
    ipdn=gfld%ipdtnum

  else
    print*, 'there is no DV input for 3hr later'
    print*, '  '
    fbias(1:maxgrd,2)=0.0                        
  endif

  if(iskip(2).eq.0.and.iret.ne.0) exit           

  ! loop over for another bias file

  jret=99

  if(iskip(1).eq.0) then 

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1

    if(iskip(2).eq.0.and.iret.eq.0) then
      ipdt(1)=ipd1; ipdt(2)=ipd2; ipdt(10)=ipd10; ipdt(11)=ipd11; ipdt(12)=ipd12
      igdtn=-1; ipdtn=ipdn
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    endif
    call getgb2(icfipg(1),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,jret)

    ! only loop icount if file (3 hour later) not available

    if(iskip(2).eq.1.and.jret.ne.0) then
      if(jret.eq.99 ) exit
      print *,' getgb2 error = ',jret
      cycle
    endif

    if(iskip(2).eq.1.and.jret.eq.0) then
      icount=icount+1
    endif

  ! print DV data message

    print *, '----- Downscaling Vector for 3hr Ago ------'
    print *, '   '

    if(jret.eq.0) then
      call printinfr(gfldo,icount)
      fbias(1:maxgrd,1)=gfldo%fld(1:maxgrd)
    else
      print*, 'there is no bais for 3hr ago '
      fbias(1:maxgrd,1)=0.0                 
    endif

    ! clean gfld 
    call gf_free(gfld)

  else

    ! if there is no DV file 3hr ago, save the grib message from another file 

    if(iret.eq.0) then
      gfldo=gfld
    endif
    print*, 'there is no bias input for 3hr before'
    fbias(1:maxgrd,1)=0.0                 
!   call gf_free(gfld)   

  endif

  if(iret.ne.0.and.jret.ne.0) exit           

  do n=1,maxgrd
    bias_avg(n)=0.5*(fbias(n,1)+fbias(n,2))
  enddo

  print *, '   ';
  print *, 'Downscaling Vector Example at Point 8601 ' 
  print '(3f8.2)', (fbias(8601,i),i=1,inum), bias_avg(8601)
  print *, '   ';

  ! modify the analysis time in grib2 message
  ! gfld%idsect(6:9) 

  gfldo%idsect(9)=gfldo%idsect(9)+3 
  gfldo%fld(1:maxgrd)=bias_avg(1:maxgrd)

  print *, '-----  Downscaling Vector for Current Time ------'
  call putgb2(icfopg1,gfldo,jret)
  call printinfr(gfldo,icount)

  ! end of downscaling vector calculation               

  call gf_free(gfldo)

enddo 

! close files

do ifile=1,inum  
  if(iskip(ifile).eq.0) then 
    call baclose(icfipg(ifile),iret)
  endif
enddo

call baclose(icfopg1,iret)

deallocate(fbias,bias_avg)

print *,'DV Calculation Successfully Complete'

stop

1020  continue

print *, 'There is not Enough Files Input, Stop!'
!call errmsg('There is not Enough Files Input, Stop!')
!call errexit(1)

stop
end


