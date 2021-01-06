! program gefs_enscqpf_24hr
!$$$  MAIN PROGRAM DOCUMENTATION BLOCK
!
! MAIN PROGRAM: 24hCQPF       QUANTITATIVE PRECIPITATION FORECAST
!   PRGMMR: YUEJIAN ZHU       ORG:NP23           DATE: 01-09-21
!   PRGMMR: Bo Cui            MOD:NP20           DATE: 15-07-06
!   PRGMMR: Yan Luo           MOD:NP20           DATE: 17-05-06
!
! ABSTRACT: THIS PROGRAM WAS ORIGINATED FROM gefs_pgrb_enspqpf.fd, BUT WAS ADOPTED 
!           TO CALCULATE ENSEMBLE BASED 24HR ACCUMULATED CALIBRATED QUANTITATIVE
!           PRECIPITATION FORECAST (24hrCQPF)
!
! PROGRAM HISTORY LOG:
!   01-09-21   YUEJIAN ZHU (WX20YZ)
!   15-07-06   BO Cui:  Modify for grib2 encode/decode.
!   17-05-06   Yan Luo: Modify for 24hr bias corrected QPF.
!
! USAGE:
!
!   INPUT FILES:
!     UNIT  11  PRECIPITATION GRIB FILE ( 144*73 )
!
!   OUTPUT FILES:
!     UNIT  51  PQPF GRIB FILE ( 144*73 )
!
!   SUBPROGRAMS CALLED:
!     GETGBE2 -- W3LIB ROUTINE
!     PUTGBE2 -- W3LIB ROUTINE
!     GRANGE  -- LOCAL ROUTINE ( included after main program )
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN
!
!$$$

program cqpf                                              

use grib_mod
use params

!implicit none

type(gribfield) :: gfldo

integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: kids,kpdt,kgdt
integer kskp,kdisc,kpdtn,kgdtn,i

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer   len,mem,icyc,ijd,ncnt,iclust,n,icnt,imems,m,ii,k,mm,irk
integer   lpgb,lpge
integer   iretb,irere,irefb,irefe,ireib,ireie,iresb,irese,iret
integer   irete,irerb,imem,ipdtnum_out 
integer   temp(200),ipdt8,ipdt9,ipdt30
integer   hrinter,jj
real      bb

parameter(len=64,mem=21,irk=13)

real, allocatable :: ff(:,:),ss(:,:),aa(:)
real, allocatable :: pp1(:,:),pp2(:,:),pp3(:,:)
real, allocatable :: avg(:),spr(:)

real      fst(mem),wgt(mem)

real      rk(irk)

character*255 cpgb,cpge

namelist /namin/icyc,hrinter,cpgb,cpge

data rk/0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4,50.8,101.6,152.4/

CALL W3TAGB('CQPF',2000,0110,0073,'NP20   ')

read (5,namin,end=1020)

lpgb   = len_trim(cpgb)
lpge   = len_trim(cpge)

print *, cpgb(1:lpgb)
print *, cpge(1:lpge)
call baopenr(11,cpgb(1:lpgb),iretb)
call baopenw(51,cpge(1:lpge),irete)

print*,'     '

! find grib message

iids=-9999;ipdt=-9999; igdt=-9999
idisc=-1;  ipdtn=-1;   igdtn=-1
call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1020

if(iret.eq.0) then

  ijd=gfldo%ngrdpts

  ! check Indicator of unit of time ranga 
  ! gfldo%ipdtmpl(8): indicator of unit of time range
  ! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours

  ipdt8=gfldo%ipdtmpl(8)

  if(gfldo%ipdtmpl(8).eq.1) then
     print *, ' Unit of time range is hour '; print *, ' '
  elseif(gfldo%ipdtmpl(8).eq.11) then
     print *, 'ipdtmpl(8)=1, unit of time range is 6 hours '; print *, ' '
  else
     print *, 'Unit of time range is not 1 hour or 6 hours, stop'; print *, ' '
  endif

  ! check gfldo%ipdtmpl(30) for PDT number 4.11
  ! length of the time range in units defined by the previous octet

  ipdt30=gfldo%ipdtmpl(30)

  if(gfldo%ipdtmpl(30).eq.6) then
     print *, ' length of time range is 6 hours '; print *, ' '
  else
     print *, ' length of time range is not 6 hours,'; print *, ' '
  endif

endif

call gf_free(gfldo)

allocate(ff(ijd,mem),ss(ijd,mem),aa(ijd))
allocate(pp1(ijd,mem),pp2(ijd,mem),pp3(ijd,mem))
allocate(avg(ijd),spr(ijd))

ncnt=0

print *, 'hrinter,len',hrinter,len

do n = 1, len         !### 16 (days) * 4 = 64 (6-hr)        

! Part I: get ctl + 10  ensemble members precipitation data

    icnt=0
    imems=1
    imem=mem
    do m = imems, imem

      iids=-9999;ipdt=-9999; igdt=-9999
      idisc=-1;  ipdtn=-1;   igdtn=-1
  
      ! read and process input ensemble member

      ipdt(17)=m-1           ! perturbation number                 

      ! read in control member                  

      if(m.eq.1) then
        ipdt(16)=1           ! type of ensemble forecast          
        ipdt(17)=0           ! perturbation number               
      endif

!     ipdt(8)=1            ! time unit: 1 hour  - kpds(13) in grib1

      ! gfldo%ipdtmpl(9): forecast time in units

      ipdt(9)=int((n-1)*6) ! forecast P2       - kpds(15) in grib1

      ! gfldo%ipdtmpl(29): indicator of unit of time ranga for process
      ! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours

      ipdt(29)=1           ! time unit: 1 for 1 hour

      ! check gfldo%ipdtmpl(30) for PDT number 4.11
      ! length of the time range in units defined by the previous octet

      ipdt(30)=6          ! length of the time range is 6 hours

      ipdtn=11; igdtn=-1

      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

      if(iret.ne.0) print *, 'there is no varibale for member ',m

      if(iret.eq.0) then
        icnt=icnt + 1
        print *, '----- Input Data for Current Time ------'
        call printinfr(gfldo,m)
        do ii=1,ijd   
           ff(ii,icnt)=gfldo%fld(ii)
        enddo
      else
        ncnt=ncnt+1
        if(ncnt.le.1) then
          print *,' n=',n,' iret=',iret
        endif
      endif  ! end of iret.eq.0

      if (m.ne.imem) call gf_free(gfldo)

    enddo   !### for m = imems, imem
  
    if(icnt.eq.0) goto 100

!
!  
!   PART II: to calculate the probability scores
!            icnt is a real read in members of ensemble
!            l=1, for tatol precipitation
!            l>1, for all categorical precipitation
!  
! l=1, calculate the probabilistic quatitative precipitation forecast

!   to calculate possible 12 hrs interval PQPF only for hrinter=12
!      such as 00-12 hrs
!              06-18 hrs
!              12-24 hrs
!              ......
!              366-378 hrs
!              372-384 hrs

!   to calculate poosible 24 hrs interval PQPF only for hrinter=24
!      such as 00-24 hrs
!              06-12 hrs
!              12-36 hrs
!              18-42 hrs
!              24-48 hrs
!              ......
!              360-384 hrs

!   change grib2 pdt message for new ensemble products

!   print *, 'gfldo%ipdtlen=',gfldo%ipdtlen
!   start to calculate the probability scores

    print *, '   '
    print *, '----- Output Information for Current Time ------'
    print *, '   '

        do ii = 1, ijd   
          do mm = 1, icnt
            if(hrinter.eq.24.and.n.ge.4) then
              bb=(ff(ii,mm)+pp1(ii,mm)+pp2(ii,mm)+pp3(ii,mm))
            elseif(hrinter.eq.12.and.n.ge.2) then
              bb=ff(ii,mm)+pp1(ii,mm)
            elseif(hrinter.eq.6) then
              bb=ff(ii,mm)
            endif
            if(k.eq.2.and.ii.eq.1250.and.mm.eq.1) then
              print *, 'ff,pp1,pp2,pp3,bb',hrinter,ff(ii,mm),pp1(ii,mm),pp2(ii,mm),pp3(ii,mm),bb
            endif
              ss(ii,mm)=bb
          enddo    ! end of mm=1,icnt
        enddo      ! end of ii=1,ijd

      
    do m = imems, imem
      ! gfldo%ipdtmpl(8): indicator of unit of time range
      ! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours
      ! gfldo%ipdtmpl(9): forecast time 

      ! change gfldo%ipdtmpl(8) to 11

      
      gfldo%ipdtmpl(8)=11
       
      if(gfldo%ipdtmpl(8).eq.1) gfldo%ipdtmpl(9)=int(6*n-hrinter)
      if(gfldo%ipdtmpl(8).eq.10) gfldo%ipdtmpl(9)=int((6*n-hrinter)/3)
      if(gfldo%ipdtmpl(8).eq.11) gfldo%ipdtmpl(9)=int((6*n-hrinter)/6)
      if(gfldo%ipdtmpl(8).eq.12) gfldo%ipdtmpl(9)=int((6*n-hrinter)/12)

      gfldo%ipdtmpl(16)=3
      gfldo%ipdtmpl(17)=m-1

      if(m.eq.1) then
      gfldo%ipdtmpl(16)=1       ! type of ensemble forecast          
      gfldo%ipdtmpl(17)=0       ! perturbation number               
      endif


      ! gfldo%ipdtmpl(33): indicator of unit of time ranga for process
      ! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours
      ! gfldo%ipdtmpl(34): PDT 4.12 length of the time range for process

      ! change gfldo%ipdtmpl(33) to 11

      gfldo%ipdtmpl(29)=11

      if(gfldo%ipdtmpl(29).eq.1) gfldo%ipdtmpl(30)=int(hrinter)
      if(gfldo%ipdtmpl(29).eq.10) gfldo%ipdtmpl(30)=int(hrinter/3)
      if(gfldo%ipdtmpl(29).eq.11) gfldo%ipdtmpl(30)=int(hrinter/6)
      if(gfldo%ipdtmpl(29).eq.12) gfldo%ipdtmpl(30)=int(hrinter/12)
      do  ii = 1, ijd
          aa(ii)=ss(ii,m)
      enddo
      gfldo%fld(1:ijd)=aa(1:ijd)

!     print *, 'gfldo%ipdtlen=',gfldo%ipdtlen
!     print *, 'gfldo%ipdtmpl=',gfldo%ipdtmpl

      if(hrinter.eq.24.and.n.ge.4) then
        call printinfr(gfldo,1)
        call putgb2(51,gfldo,iret)
      elseif(hrinter.eq.12.and.n.ge.2) then
        call printinfr(gfldo,1)
        call putgb2(51,gfldo,iret)
      elseif(hrinter.eq.6) then
        call printinfr(gfldo,1)
        call putgb2(51,gfldo,iret)
      endif
    enddo

    100 continue

! calculate ensemble mean & spread
       do ii = 1, ijd

          fst(1:imem)=ss(ii,1:imem)

        do jj = 1, imem
           wgt(jj)=1/float(imem)
        enddo

        avg(ii)=epdf(fst,wgt,imem,1.0,0)
        spr(ii)=epdf(fst,wgt,imem,2.0,0)

       enddo

       print *, 'avg(8601)= ',avg(8601)
       print *, 'spr(8601)= ',spr(8601)

! when product difinition template 4.1/4.11 chenge to 4.2/4.12
! ipdtlen aslo change, need do modification for output
! code table 4.0, 2=derived forecast

       if(gfldo%ipdtnum.eq.1) ipdtnum_out=2
       if(gfldo%ipdtnum.eq.11) ipdtnum_out=12

       call change_template4(gfldo%ipdtnum,ipdtnum_out,gfldo%ipdtmpl,gfldo%ipdtlen)

! extensions for ensemble mean

       gfldo%ipdtmpl(16)=0      ! code table 4.7, 0=unweighted mean of all Members
       gfldo%ipdtmpl(17)=imem   ! template 4.2, number of forecast in the ensemble

        gfldo%fld(1:ijd) = avg(1:ijd)

        print *, '-----  Ensemble Average for Current Time ------'
        call putgb2(51,gfldo,iret)
        call printinfr(gfldo,1)

! extensions for ensemble spread

        gfldo%ipdtmpl(16)=2        ! code table 4.7, 2=standard deviation w.r.t cluster mean
        gfldo%ipdtmpl(17)=imem     ! template 4.2, number of forecast in the ensemble

        gfldo%fld(1:ijd) = spr(1:ijd)

        print *, '-----  Ensemble Spread for Current Time ------'
        call putgb2(51,gfldo,iret)
        call printinfr(gfldo,1)

        call gf_free(gfldo)

       print *,"======================================================"

  if(hrinter.eq.24) then
    if (icnt.gt.0) then
      do ii = 1, ijd
        do jj = 1, mem
          if(n.eq.1) pp1(ii,jj)=ff(ii,jj)
          if(n.eq.2) pp2(ii,jj)=ff(ii,jj)
          if(n.eq.3) pp3(ii,jj)=ff(ii,jj)
          if(n.ge.4) then
            pp1(ii,jj)=pp2(ii,jj)
            pp2(ii,jj)=pp3(ii,jj)
            pp3(ii,jj)=ff(ii,jj)
          endif
        enddo      !### do jj = 1, mem
      enddo      !### do ii = 1, ijd
    endif        !### if icnt.gt.0
  endif        !### if hrinter.eq.24

  if(hrinter.eq.12) then
    if (icnt.gt.0) then
      do ii = 1, ijd
        do jj = 1, mem
          if(n.eq.1) pp1(ii,jj)=ff(ii,jj)
          if(n.ge.2) pp1(ii,jj)=ff(ii,jj)
        enddo      !### do ii = 1, ijd
      enddo       !### do jj = 1, mem
    endif        !### if (icnt.gt.0)
  endif        !### if hrinter.eq.12
  
enddo     !### for n = 1, len

deallocate(ff,ss,aa)
deallocate(pp1,pp2,pp3)
deallocate(avg,spr)

call baclose(11,iretb)
call baclose(51,irete)

CALL W3TAGE('CQPF')

stop    

1020 Continue

print *,'Wrong Data Input, Output or Wrong Message Input'

stop

end

