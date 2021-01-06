   program rtma_bias_g2          
!
! main program: rtma_bias_g2             
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-10-01
!                          
!
! abstract: update bias estimation between rtma analysis and NCEP operational analyis
!           add variable 2m dew point demperature and 2m relative humility
!           calculate RTMA RH2m from RTMA T2m and dpt, then calculate its downscaling vector
!
! usage:
!
!   input file: grib
!     unit 11 -    : prior bias estimation                                               
!     unit 12 -    : rtma analysis
!     unit 13 -    : ncep operational analysis
!
!   output file: grib
!     unit 51 -    : updated bias estimation pgrba file
!
!   parameters
!     fgrid -      : ensemble forecast
!     agrid -      : rtma 5km analysis data
!     bias  -      : bias estimation
!     dec_w -      : decay averaging weight 
!     nvar  -      : number of variables

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib reader
!   putgb2           grib writer
!   get_dpt_g2       calculate dew point temperature for given rh and tmp
!   get_rh_g2        relative humility for given dpt and tmp                       
!   init_parm        define grid definition and product definition
!   printinfr        print grib2 data information
!   getbits          comput number of bits and round field

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

integer   nvar,ivar,i,k,icstart
parameter (nvar=6)

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer ipd1(nvar),ipd2(nvar),ipd10(nvar),ipd11(nvar),ipd12(nvar)

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

! variables: pres u10m v10m t2m dpt2m rh2m

data ipd1 /  3,  2,  2,  0,  1,  0/
data ipd2 /  0,  2,  3,  0,  1,  6/
data ipd10/  1,103,103,103,103,103/
data ipd11/  0,  0,  0,  0,  0,  0/
data ipd12/  0, 10, 10,  2,  2,  2/

real,allocatable :: agrid(:),fgrid(:),bias(:)

real dec_w

integer ifile,afile,cfile,ofile

integer     maxgrd,ndata                                
integer     index,j,n,iret,jret             
character*7 cfortnn

real    gmin,gmax
integer nbit

namelist/message/icstart,dec_w

read(5,message,end=1020)
write(6,message)

ifile=11
afile=12
cfile=13
ofile=51

! set the fort.* of intput files

write(cfortnn,'(a5,i2)') 'fort.',afile
call baopenr(afile,cfortnn,iret)
if (iret.ne.0) then; print*,'there is no rtma data, stop!'; endif
if (iret.ne.0) goto 1020

write(cfortnn,'(a5,i2)') 'fort.',cfile
call baopenr(cfile,cfortnn,iret)
if (iret.ne.0) then; print*,'there is no NCEP analysis data, stop!'; endif
if (iret.ne.0) goto 1020

if(icstart.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ifile
  call baopenr(ifile,cfortnn,iret)
  if (iret.ne.0) then; print*,'there is no bias estimation data, please check!'; endif
endif

! set the fort.* of output file

write(cfortnn,'(a5,i2)') 'fort.',ofile
call baopenw(ofile,cfortnn,iret)
if (iret.ne.0) then; print*,'there is no output bias data, stop!'; endif
if (iret.ne.0) goto 1020

! find grib message

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

if (iret.ne.0) then; print*,' cannot set up grib message ',afile,iret; endif
if (iret.ne.0) goto 1020

maxgrd=gfld%ngrdpts
call gf_free(gfld)

allocate (agrid(maxgrd),fgrid(maxgrd),bias(maxgrd))

do ivar = 1, nvar  

  bias=-9999.9999
  agrid=-9999.9999
  fgrid=-9999.9999

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ! read and process variable of input data

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized bias estimation

  if(icstart.eq.1) then
    print *, '----- Cold Start for Bias Estimation -----'
    print*, '  '
    bias=0.0
  else
    print *, '----- Initialized Bias for Current Time -----'
    ipdtn=1; igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(ifile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.eq.0) bias(1:maxgrd)=gfld%fld(1:maxgrd)
    if (iret.eq.0) call printinfr(gfld,ivar)

    if (iret.ne.0) bias=0.0
    if (iret.ne.0) print*, 'there is no bias for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

  endif

  call gf_free(gfld)

  ! get rtma data; there is no no rtma rh2m, need to calculate it first 
  ! rtma have product template 4.0: ipdtn=0; variable from 2 generateing processing
  ! ground analysis:ipdt(3)=0 and ground analysis/forecast error:ipdt(3)=7 (code table 4.3)

  print *, '----- RTMA Analysis for Current Time ------'

  if(ipd1(ivar).eq.1.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '; print*, 'Start to Calcualte RTMA RH2m Analysis '; print *, ' '
    ipdtn=0; igdtn=-1; ipdt(3)=0
    call get_rh_g2(afile,maxgrd,ipdtn,ipdt,igdtn,igdt,idisc,iids,gfld,iret)
  else
    ipdtn=0; igdtn=-1;ipdt(3)=0
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(afile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  endif

  if (iret.eq.0) agrid(1:maxgrd)=gfld%fld(1:maxgrd)
  if (iret.ne.0) print*, 'there is no rtma for ', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

  if (iret.ne.0.and.icstart.eq.0) goto 200
  if (iret.ne.0.and.icstart.eq.1) goto 1020

  if (iret.eq.0) call printinfr(gfld,ivar)

  call gf_free(gfld)

  ! get operational analysis from GEFS control fcst 
  ! GEFS control test have product template 4.1: ipdtn=1
  ! type of generating process : ipdt(3)=4 for ensemble forecast (code table 4.3)

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    print *, ' '
    print*, 'Start to Calcualte NCEP Dew Point Temperature Analysis '; print *, ' '
    ipdtn=1; igdtn=-1; ipdt(3)=4
    call get_dpt_g2(cfile,maxgrd,ipdtn,ipdt,igdtn,igdt,idisc,iids,gfldo,iret)
  else
    print *, '----- NCEP operational analysis for current Time ------'
    ipdtn=1; igdtn=-1; ipdt(3)=4
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(cfile,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
  endif

  if (iret.ne.0) print*, 'there is no analysis', jpdt(1),jpdt(2),jpdt(10),jpdt(12)

  ! if there is no rtma analyis, save previous data message 

  if (iret.ne.0) goto 200

  if (iret.eq.0) call printinfr(gfldo,ivar)
  if (iret.eq.0) fgrid(1:maxgrd)=gfldo%fld(1:maxgrd)

  ! apply the decay average

  call decay(bias,fgrid,agrid,maxgrd,dec_w)

  200 continue
 
  ! outout downscle vector

  ! gfldo%ipdtmpl(3)=7 : GRIB2 code table 4.3 analysis error

  gfldo%ipdtmpl(3)=7 

  ! gfldo%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

  gfldo%idrtmpl(3)=2 

  ! get the number of bits

  call gtbits(0,gfldo%idrtmpl(3),maxgrd,0,bias,gmin,gmax,nbit)

  gfldo%fld(1:maxgrd)=bias(1:maxgrd)

  ! gfldo%idrtmpl(4) : GRIB2 DRT 5.40 number of bits      

  gfldo%idrtmpl(4)=nbit

  print *, '----- Output Bias Estimation for Current Time ------'

  call putgb2(ofile,gfldo,iret)
  call printinfr(gfldo,ivar)
  call gf_free(gfldo)

! end of bias estimation for one forecast lead time

100 continue

enddo

call baclose(ifile,iret)
call baclose(afile,iret)
call baclose(cfile,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Successfully Complete'

stop

1020  continue

print *,'Wrong Data Input, Output or Wrong Message Input'

stop
end

subroutine decay(aveeror,fgrid,agrid,maxgrd,dec_w)

!     apply the decaying average scheme
!
!     parameters
!                  fgrid  ---> ensemble forecast
!                  agrid  ---> analysis data
!                  aveeror---> bias estimation
!                  dec_w  ---> decay weight

implicit none

integer maxgrd,ij
real aveeror(maxgrd),fgrid(maxgrd),agrid(maxgrd)
real dec_w           

do ij=1,maxgrd
  if(fgrid(ij).gt.-9999.0.and.fgrid(ij).lt.999999.0.and.agrid(ij).gt.-999.0.and.agrid(ij).lt.999999.0) then
      if(aveeror(ij).gt.-9999.0.and.aveeror(ij).lt.999999.0) then
        aveeror(ij)= (1-dec_w)*aveeror(ij)+dec_w*(fgrid(ij)-agrid(ij))
      else
        aveeror(ij)= dec_w*(fgrid(ij)-agrid(ij))
      endif
  else
    if(aveeror(ij).gt.-9999.0 .and.aveeror(ij).lt.999999.0) then
      aveeror(ij)= aveeror(ij)                   
    else
      aveeror(ij)= 0.0                                
    endif
  endif
enddo

return
end


