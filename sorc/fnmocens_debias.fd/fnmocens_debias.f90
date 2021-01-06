program fnmoccens_debias_g2   
!
! main program: fnmocens_debias_g2
!
! prgmmr: Bo Cui           org: np/wx20        date: 2013-10-01
!
! abstract: bias correct global ensemble forecast
!
! usage:
!
!   input file: grib
!     unit 11 -    : GEFS ensmeble mean bias estimation                                               
!     unit 12 -    : GEFS one member forecast
!
!   output file: grib
!     unit 51 -    : bias-corrected forecast  
!
!   parameters
!     fgrid_ens -  : one ensemble member's forecast
!     bias_ens  -  : GEFS ensemble mean bias estimation
!     nvar      -  : number of variables

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgbe2          grib reader
!   putgbe2          grib writer

!
! attributes:
!   language: fortran 90
!
!$$$

use naefs_mod

implicit none

integer     ivar,i,icstart_ens
!parameter  (nvar=50)

real,       allocatable :: fgrid_ens(:),bias_ens(:)
real        pi

integer     ifile_ens,ibias_ens,ofile

integer     maxgrd,ndata,nfhr
integer     index,j,n,iret,jret             
character*7 cfortnn

namelist/message/icstart_ens,nfhr

read(5,message,end=1020)
write(6,message)

ibias_ens=11
ifile_ens=12
ofile=51

! set the fort.* of intput files

if(icstart_ens.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ibias_ens
  call baopenr(ibias_ens,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no GEFS bias estimation'; endif
endif

write(cfortnn,'(a5,i2)') 'fort.',ifile_ens
call baopenr(ifile_ens,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no GEFS forecast'; endif
if (iret .ne. 0) goto 1020

! set the fort.* of output file

write(cfortnn,'(a5,i2)') 'fort.',ofile
call baopenw(ofile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no bias-corrected output, stop!'; endif
if (iret .ne. 0) goto 1020

! find grib message

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(ifile_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
maxgrd=gfld%ngrdpts
call gf_free(gfld)

if (iret .ne. 0) then; print*,' getgbeh ,ifile_ens,index,iret =',ifile_ens,index,iret; endif
if (iret .ne. 0) goto 1020

allocate (fgrid_ens(maxgrd),bias_ens(maxgrd))

do ivar = 1, nvar  

  bias_ens=0.0             
  fgrid_ens=-9999.99

  ! read and process variable of input data

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(12)=ipd12(ivar)

  ! get initialized GEFS bias estimation

  if(icstart_ens.eq.1) then
    print *, '----- Cold Start for GEFS Bias Correction -----'
    print*, '  '
    bias_ens=0.0
  else
    print *, '----- Initialized GEFS Bias for Current Time -----'

    igdtn=-1
    ipdtn=ipdnm(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(ibias_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

    if (iret.ne.0) print*, 'There is no Bias for', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    if (iret.ne.0) bias_ens=0.0
    print*, '     '

    if(iret.eq.0) then
      print *, '----- Initialized GEFS Bias for Current Time -----'
      bias_ens(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
    endif

    call gf_free(gfld)

  endif

  ! get operational GEFS forecast 

  igdtn=-1
  ipdtn=ipdn(ivar)

  ! FNMOC has variable  RH, no bias correction for RH

  if(ipd1(ivar).eq.1.and.ipd2(ivar).eq.1.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) goto 100

  ! fnmoc tmax and tmin have message different from ncep, input different pds information

  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.4.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    ipdt(1)=0; ipdt(2)=0; ipdt(10)=103; ipdt(12)=2; ipdt(27)=2
  endif
    
  if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.5.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
    ipdt(1)=0; ipdt(2)=0; ipdt(10)=103; ipdt(12)=2; ipdt(27)=3
  endif
  
  call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
  call getgb2(ifile_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

  if (iret.ne.0) then
    print*, 'There is no GEFS', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    print *, ' '
    call gf_free(gfldo)
  endif

  if (iret.ne.0) goto 100

  print *, '----- GEFS operational forecast for current Time ------'
  call printinfr(gfldo,ivar)
  fgrid_ens(1:maxgrd)=gfldo%fld(1:maxgrd)

  call debias(bias_ens,fgrid_ens,maxgrd)

  ! output bias corrected forecast

  gfldo%fld(1:maxgrd)=fgrid_ens(1:maxgrd)

! gfldo%ipdtmpl(3)=3                ! code table 4.3, bias corrected forecast
  gfldo%ipdtmpl(3)=11               ! code table 4.3, bias corrected ensemble forecast

  gfldo%ipdtmpl(4)=0                ! Background generating process identifiea, 0 for NCEP
  gfldo%ipdtmpl(16)=3               ! code table 4.6, positively perturbed forecast

  gfldo%idsect(2)=2                 ! table c, 2=NCEP Ensemble Products
  gfldo%idsect(3)=2                 ! 2=Version Implemented on 4 November 2003
  gfldo%idsect(4)=1                 ! version number of GRIB
  gfldo%idsect(5)=1                 ! reference time, 1=start of forecast
  gfldo%idsect(13)=4                ! 4=perturbed forecast products

  print *, '----- Output Bias Corrected Forecast -----'

  ! fnmoc tmax and tmin have message different from ncep, modify to same as NCEP

  if(gfldo%ipdtnum.eq.11) then
    if(gfldo%ipdtmpl(1).eq.0.and.gfldo%ipdtmpl(2).eq.0.and.gfldo%ipdtmpl(27).eq.2) then
      gfldo%ipdtmpl(1)=0
      gfldo%ipdtmpl(2)=4
    endif
    if(gfldo%ipdtmpl(1).eq.0.and.gfldo%ipdtmpl(2).eq.0.and.gfldo%ipdtmpl(27).eq.3) then
      gfldo%ipdtmpl(1)=0
      gfldo%ipdtmpl(2)=5
    endif
  endif

  call putgb2(ofile,gfldo,iret)
  call printinfr(gfldo,ivar)

! end of bias estimation for one forecast lead time

100 continue

enddo

call baclose(ifile_ens,iret)
call baclose(ibias_ens,iret)
call baclose(ofile,iret)

print *,'Bias Estimation Successfully Complete'

stop

1020  continue

print *,'Wrong Data Input or Wrong Message Input'

stop
end

subroutine debias(bias_ens,fgrid_ens,maxgrd)

!   apply the bias correction

!   input
!         fgrid_ens  ---> ensemble forecast
!         bias-ens   ---> bias estimation       
!         maxgrid    ---> number of grid points in the defined grid
!
!   output
!         fgrid_ens  ---> bias corrected ensemble forecast

implicit none

integer maxgrd,ij
real    bias_ens(maxgrd),fgrid_ens(maxgrd)
real    weight

do ij=1,maxgrd
  if(fgrid_ens(ij).gt.-9999.0.and.fgrid_ens(ij).lt.999999.0.and.   &
     bias_ens(ij).gt.-9999.0.and.bias_ens(ij).lt.999999.0) then
      fgrid_ens(ij)=fgrid_ens(ij)-bias_ens(ij)
  else
    fgrid_ens(ij)=fgrid_ens(ij)
  endif
enddo

return
end

