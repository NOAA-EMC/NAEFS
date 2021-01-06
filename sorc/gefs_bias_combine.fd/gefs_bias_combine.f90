program gefs_bias_combine
!
! main program: gefs_bias_combine
!
! prgmmr: Bo Cui           org: np/wx20        date: 2006-12-10
!                          mod: np/wx20        date: 2007-07-27
!                          mod: np/wx20        date: 2008-09-11
!                          mod:                date: 2013-12-01
!                          mod: Bo Cui         date: 2014-11-01
!                          mod: Hong.Guan      date: 2016-09-01
!
! abstract: calculated combined bias from decaying and reforecast
!
! Process to get combined bias  from combined method
!      1. read in squared correclation-coifficent between analysis and ensemble
!         mean foreacst      
!      2. read in reforeacst bias 
!      3. calculate total bias
!
! usage:
!
!   input file: grib
!     unit 11 -    : GEFS ensmeble mean bias estimation                                               
!     unit 12 -    : squared correlation coefficient
!     unit 13 -    : GEFS reforeacst bias estimation
!
!   output file: grib
!     unit 51 -    : cimbined bias                 
!
!   parameters
!     bias_ens  -      : GEFS ensemble mean bias estimation
!     bias_rf   -      : reforecast bias estimation
!     r2        -      : Squared correlation coefficient
!     nvar      -      : number of variables

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgb2           grib reader
!   putgb2           grib writer

!
! attributes:
!   language: fortran 90
!
!$$$

use naefs_mod

implicit none

integer     ivar,i,ij,icstart_ens,icstart_rf
!parameter  (nvar=52)

real,       allocatable :: bias_ens(:)
real,       allocatable :: r2(:),bias_rf(:)
real        dmin,dmax

integer     ibias_ens,ibias_rf,ifile_r2,ofile

! variables: u,v,t,h at 1000,925,850,700,500,250,200,100,50,10 mb,tmax,tmin,   &
!            slp,pres u10m v10m t2m,ULWRF(Surface),ULWRF(OLR),VVEL(850w), dpt2 rh2m

integer     maxgrd,ndata,nfhr
integer     index,j,n,iret_decay,iret_rf,iret,jret             
character*7 cfortnn

namelist/message/icstart_ens,icstart_rf,nfhr

read(5,message,end=1020)
write(6,message)

if(icstart_ens.eq.1.and.icstart_rf.eq.1) goto 1020

ibias_ens=11
ifile_r2=12
ibias_rf=13
ofile=51

! set the fort.* of intput files

if(icstart_ens.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ibias_ens
  call baopenr(ibias_ens,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no GEFS bias estimation'; endif
endif

if(icstart_rf.eq.0) then
  write(cfortnn,'(a5,i2)') 'fort.',ibias_rf
  call baopenr(ibias_rf,cfortnn,iret)
  if (iret .ne. 0) then; print*,'there is no GEFS reforeacst bias estimation'; endif
endif

write(cfortnn,'(a5,i2)') 'fort.',ifile_r2
call baopenr(ifile_r2,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no correlation coefficient estimation'; endif

! set the fort.* of output file

write(cfortnn,'(a5,i2)') 'fort.',ofile
call baopenw(ofile,cfortnn,iret)
if (iret .ne. 0) then; print*,'there is no combined bias output, stop!'; endif
if (iret .ne. 0) goto 1022

! find grib message, maxgrd: number of grid points in the defined grid

if(icstart_ens.eq.0) then
  ipdt=-9999; igdt=-9999
  ipdtn=-1; igdtn=-1
  call init_parm(ipdtn,ipdt,igdtn,igdt)
  call getgb2(ibias_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  maxgrd=gfld%ngrdpts
  call gf_free(gfld)
else
  ipdt=-9999; igdt=-9999
  ipdtn=-1; igdtn=-1
  call init_parm(ipdtn,ipdt,igdtn,igdt)
  call getgb2(ibias_rf,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
  maxgrd=gfld%ngrdpts
  call gf_free(gfld)
endif

if(iret.ne.0) then; 
  print*,' No Input Files '
endif

if(iret.ne.0) goto 1020

allocate(bias_ens(maxgrd),r2(maxgrd),bias_rf(maxgrd))

do ivar = 1, nvar

  bias_ens=0.0             
  bias_rf=0.0             
  r2=-9999.99

  iret_decay=99
  iret_rf=99

  ! read and process variable of input data

  ipdt=-9999
  igdt=-9999

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(11)=ipd11(ivar)
  ipdt(12)=ipd12(ivar)

  ! get GEFS bias estimation

  if(icstart_ens.eq.1) then
    print *, '----- Cold Start for GEFS Decaying Bias -----'
    bias_ens=0.0
    print *, '    '
  else
    igdtn=-1
    ipdtn=ipdnm(ivar)
    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ibias_ens,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret_decay)

    if(iret_decay.ne.0) then
      print*, ' No Decaying Bias for', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfldo)
      bias_ens=0.0
    else
      print *, '----- GEFS Decaying Bias for Current Time -----'
      bias_ens(1:maxgrd)=gfldo%fld(1:maxgrd)
      call printinfr(gfldo,ivar)
    endif
  endif

  ! get GEFS reforeacst bias estimation

  if(icstart_rf.eq.1) then
    print *, '----- Cold Start for GEFS Reforeacst Bias -----'
    bias_rf=0.0
    print *, '    '
  else

    ! read in reforeacst bias

    igdtn=-1
    ipdtn=-1
    ipdtn=ipdnm(ivar)

    call init_parm(ipdtn,ipdt,igdtn,igdt)
    call getgb2(ibias_rf,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret_rf)

    if(iret_rf.ne.0) then
      print*, ' No Reforecast Bias for', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
      call gf_free(gfld)
      bias_rf=0.0
    else
      print *, '----- GEFS Reforecast Bias for Current Time -----'
      bias_rf(1:maxgrd)=gfld%fld(1:maxgrd)
      call printinfr(gfld,ivar)
    endif

    if(iret_decay.ne.0.and.iret_rf.eq.0) then
      print *, '----- No Decaying Bias, Use Reforecast Bias Message -----'
      print *, '    '
      gfldo=gfld
    endif

    call gf_free(gfld)

  endif

  ! in case no reforecast and no decaying bias 

  if(iret_decay.ne.0.and.iret_rf.ne.0) then  
    print*, ' No Combination For This Variable '
    print*, ' '
  endif
  if(iret_decay.ne.0.and.iret_rf.ne.0) goto 100

  ! get r2 correlation coefficient

  igdtn=-1
  ipdtn=15            

  call init_parm(ipdtn,ipdt,igdtn,igdt)
  call getgb2(ifile_r2,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)

  if (iret.ne.0) then
    print*, ' No correlation coefficient', jpdt(1),jpdt(2),jpdt(10),jpdt(12)
    print *, ' '
    call gf_free(gfld)
    r2=1.
  else
    print *, '----- Correlation Coefficient for Current Time ----'
    call printinfr(gfld,ivar)
    r2(1:maxgrd)=gfld%fld(1:maxgrd)
  endif

  ! calculate combined bias

  do ij=1,maxgrd 
    if(bias_ens(ij).gt.-9999.0.and.bias_ens(ij).lt.999999.0.and.&
      bias_rf(ij).gt.-9999.0.and.bias_rf(ij).lt.999999.0.and.&
        r2(ij).gt.-9999.0) then
        bias_ens(ij)=bias_ens(ij)*r2(ij)+bias_rf(ij)*(1.-r2(ij))
     endif
  enddo

  ! output bias combination                         

  print *, '----- Output Combined Bias -----'

  gfldo%fld(1:maxgrd)=bias_ens(1:maxgrd)
  call putgb2(ofile,gfldo,iret)
  call printinfr(gfldo,ivar)

  call gf_free(gfldo)

! end of bias estimation for one forecast lead time

100 continue

enddo

call baclose(ibias_ens,iret)
call baclose(ibias_rf,iret)
call baclose(ifile_r2,iret)
call baclose(ofile,iret)

deallocate(bias_ens,r2,bias_rf)

print *,'Bias Combination Successfully Complete'

stop

1020  continue
print *,'No Decaying and Reforecast Bias Input'
stop

1022  continue
print *,'No Bias Combination Output'
stop

end

