! program gefs_pgrb_enspqpf
!$$$  MAIN PROGRAM DOCUMENTATION BLOCK
!
! MAIN PROGRAM: PQPF          PROBABILISTI! QUANTITATIVE SNOW FORECAST
!   PRGMMR: YUEJIAN ZHU       ORG:NP23           DATE: 01-09-21
!   PRGMMR: Bo Cui            MOD:NP20           DATE: 15-07-06
!
! ABSTRACT: THIS PROGRAM WILL CALCULATE ENSEMBLE BASED 
!           PROBABILISTI! QUANTITATIVE PRECIPITATION FORECAST (PQPF)
!           PROBABILISTI! QUANTITATIVE RAIN FORECAST          (PQRF)
!           PROBABILISTI! QUANTITATIVE SNOW FORECAST          (PQSF)
!           PROBABILISTI! QUANTITATIVE ICE PELLETS FORECAST   (PQIF)
!           PROBABILISTI! QUANTITATIVE FREEZING RAIN FORECAST (PQFF)
!
! PROGRAM HISTORY LOG:
!   01-09-21   YUEJIAN ZHU (WX20YZ)
!   03-05-05   YUEJIAN ZHU: calculate for 6-hour intevals. 
!   02-08-06   YUEJIAN ZHU: Modify for new implementation. 
!   07-01-09   BO Cui: Modify for new options (1 degree, 6hr, 12hr and 24hr interval)
!                      Calculate GEFS ensemble based (PQPF) at 1 by 1 degree resolution,
!                      24 hour output at 6 hour increments to 16 days for more threads
!                      (1, 2, 4 and 6 inches).
!   15-07-06   BO Cui: Modify for grib2 encode/decode.
!
! USAGE:
!
!   INPUT FILES:
!     UNIT  11  PRECIPITATION GRIB FILE ( 144*73 )
!     UNIT  12  CATEGORICAL RAIN          (1=RAIN, 0=NOT) GRIB FILE (144*73)
!     UNIT  13  CATEGORICAL FREEZING RAIN (1=FRAIN,0=NOT) GRIB FILE (144*73)
!     UNIT  14  CATEGORICAL ICE PELLETS   (1=ICE,  0=NOT) GRIB FILE (144*73)
!     UNIT  15  CATEGORICAL SNOW          (1=SNOW, 0=NOT) GRIB FILE (144*73)
!
!   OUTPUT FILES:
!     UNIT  51  PQPF GRIB FILE ( 144*73 )
!     UNIT  52  PQRF GRIB FILE ( 144*73 )
!     UNIT  53  PQFF GRIB FILE ( 144*73 )
!     UNIT  54  PQIF GRIB FILE ( 144*73 )
!     UNIT  55  PQSF GRIB FILE ( 144*73 )
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

program pqpf                                              

use grib_mod
use params

implicit none

type(gribfield) :: gfldo

integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: kids,kpdt,kgdt
integer kskp,kdisc,kpdtn,kgdtn,i

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer   len,mem,icyc,ijd,ncnt,iclust,n,l,icnt,imems,m,ii,k,mm,irk
integer   lpgb,lpge,lrain,lraino,lfrzr,lfrzro,licep,licepo,lsnow,lsnowo
integer   iretb,irere,irefb,irefe,ireib,ireie,iresb,irese,iret
integer   irete,irerb,imem 
integer   temp(200),ipdt8,ipdt9,ipdt30
integer   hrinter,ivar,jj
real      bb,cc

parameter(len=64,mem=21,irk=13)

real, allocatable :: ff(:,:),pp(:,:),ss(:,:),aa(:)
real, allocatable :: pp1(:,:),pp2(:,:),pp3(:,:)

real      rk(irk,5)

character*120 cpgb,cpge
character*120 crain,craino
character*120 cfrzr,cfrzro
character*120 cicep,cicepo
character*120 csnow,csnowo

namelist /namin/icyc,hrinter,cpgb,cpge,crain,craino,cfrzr,cfrzro,  &
                     cicep,cicepo,csnow,csnowo

data rk/0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4,50.8,101.6,152.4,&
        0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4,50.8,101.6,152.4,&
        0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4,50.8,101.6,152.4,&
        0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4,50.8,101.6,152.4,&
        0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4,50.8,101.6,152.4/

CALL W3TAGB('PQPF',2000,0110,0073,'NP20   ')

read (5,namin,end=1020)

lpgb   = len_trim(cpgb)
lpge   = len_trim(cpge)
lrain  = len_trim(crain)
lraino = len_trim(craino)
lfrzr  = len_trim(cfrzr)
lfrzro = len_trim(cfrzro)
licep  = len_trim(cicep)
licepo = len_trim(cicepo)
lsnow  = len_trim(csnow)
lsnowo = len_trim(csnowo)

print *, cpgb(1:lpgb)
print *, cpge(1:lpge)
call baopenr(11,cpgb(1:lpgb),iretb)
call baopenw(51,cpge(1:lpge),irete)

print *, crain(1:lrain)
print *, craino(1:lraino)
call baopenr(12,crain(1:lrain),irerb)
call baopenw(52,craino(1:lraino),irere)

print *, cfrzr(1:lfrzr)
print *, cfrzro(1:lfrzro)
call baopenr(13,cfrzr(1:lfrzr),irefb)
call baopenw(53,cfrzro(1:lfrzro),irefe)

print *, cicep(1:licep)
print *, cicepo(1:licepo)
call baopenr(14,cicep(1:licep),ireib)
call baopenw(54,cicepo(1:licepo),ireie)

print *, csnow(1:lsnow)
print *, csnowo(1:lsnowo)
call baopenr(15,csnow(1:lsnow),iresb)
call baopenw(55,csnowo(1:lsnowo),irese)

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

allocate(ff(ijd,mem),pp(ijd,mem),ss(ijd,mem),aa(ijd))
allocate(pp1(ijd,mem),pp2(ijd,mem),pp3(ijd,mem))

ncnt=0

if(hrinter.gt.6) ivar=1
if(hrinter.eq.6) ivar=5

print *, 'hrinter,len,ivar',hrinter,len,ivar

do n = 1, len         !### 16 (days) * 4 = 64 (6-hr)        
  do l = 1, ivar       !### 5 categorical

! Part I: get ctl + 10  ensemble members precipitation data

    icnt=0
    pp=0.0
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
      call getgb2(10+l,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)

      if(iret.ne.0) print *, 'there is no varibale for member ',m

      if(iret.eq.0) then
        icnt=icnt + 1
        print *, '----- Input Data for Current Time ------'
        call printinfr(gfldo,m)
        do ii=1,ijd   
         if (l.eq.1) then
           ff(ii,icnt)=gfldo%fld(ii)
         else
           pp(ii,icnt)=gfldo%fld(ii)
         endif
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

    gfldo%idsect(2)=2  ! Identification of originating/generating subcenter
                       ! 2: NCEP Ensemble Products

    gfldo%idsect(13)=5 ! Type of processed data in this GRIB message       
                       ! 5: Control and Perturbed Forecast Products

    temp=-9999

!   print *, 'gfldo%ipdtlen=',gfldo%ipdtlen

    temp(1:gfldo%ipdtlen)=gfldo%ipdtmpl(1:gfldo%ipdtlen)

    temp(3)=5               ! Type of generating process 
                            ! 5: Probability Forecast

    deallocate (gfldo%ipdtmpl) 

    gfldo%ipdtnum=9         ! Probability forecasts from ensemble 
    if(gfldo%ipdtnum.eq.9) gfldo%ipdtlen=36
    if(gfldo%ipdtnum.eq.9) allocate (gfldo%ipdtmpl(gfldo%ipdtlen))

    gfldo%ipdtmpl(1:15)=temp(1:15)

    gfldo%ipdtmpl(1)=1      ! Parameter category : 1 Moisture
    gfldo%ipdtmpl(2)=8      ! Parameter number : 8 Total Precipitation(APCP)

    gfldo%ipdtmpl(16)=0     ! Forecast probability number 
    gfldo%ipdtmpl(17)=mem   ! Total number of forecast probabilities
    gfldo%ipdtmpl(18)=1     ! Probability Type
                            ! 1: Probability of event above upper limit

    gfldo%ipdtmpl(19)=0     ! Scale factor of lower limit
    gfldo%ipdtmpl(20)=0     ! Scaled value of lower limit
    gfldo%ipdtmpl(21)=3     ! Scale factor of upper limit

    ! gfldo%ipdtmpl(22) will be set below

    gfldo%ipdtmpl(23:36)=temp(19:32)

!   start to calculate the probability scores

    print *, '   '
    print *, '----- Output Information for Current Time ------'
    print *, '   '

    do k = 1, irk
      aa=0.0
      if(l.eq.1) then
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
            if (bb.ge.rk(k,l)) then
              aa(ii) = aa(ii) + 1.0
            endif
          enddo    ! end of mm=1,icnt
        enddo      ! end of ii=1,ijd
        do ii = 1, ijd  
          aa(ii) = aa(ii)*100.0/float(icnt)
          if (aa(ii).ge.99.0) then
            aa(ii) = 100.0
          endif
        enddo
      else
        do ii = 1, ijd   
          do mm = 1, icnt
            bb=ff(ii,mm)
            cc=pp(ii,mm)
            if (cc.eq.1.0) then
              if (bb.ge.rk(k,l)) then
                aa(ii) = aa(ii) + 1.0
              endif
            endif
          enddo
        enddo
        do ii = 1, ijd  
          aa(ii) = aa(ii)*100.0/float(icnt)
          if (aa(ii).ge.99.0) then
            aa(ii) = 100.0
          endif
        enddo
      endif      ! end of if (l.eq.1)

!   
!     testing print
!  
!     1250-1259 (70N, 115W-95W)
!      if (n.eq.1.and.k.eq.2) then 
!        write(*,999) l,n,(aa(ii),ii=1250,1259)
!      endif
!999   format (2i3,10f8.1)


      ! gfldo%ipdtmpl(22): Scaled value of upper limit

      gfldo%ipdtmpl(22)=rk(k,l)*(10**gfldo%ipdtmpl(21))

      ! gfldo%ipdtmpl(8): indicator of unit of time range
      ! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours
      ! gfldo%ipdtmpl(9): forecast time 

      ! change gfldo%ipdtmpl(8) to 11
      
      gfldo%ipdtmpl(8)=11

      if(gfldo%ipdtmpl(8).eq.1) gfldo%ipdtmpl(9)=int(6*n-hrinter)
      if(gfldo%ipdtmpl(8).eq.10) gfldo%ipdtmpl(9)=int((6*n-hrinter)/3)
      if(gfldo%ipdtmpl(8).eq.11) gfldo%ipdtmpl(9)=int((6*n-hrinter)/6)
      if(gfldo%ipdtmpl(8).eq.12) gfldo%ipdtmpl(9)=int((6*n-hrinter)/12)

      ! gfldo%ipdtmpl(33): indicator of unit of time ranga for process
      ! 11: 6 hours; 1: hour; 10: 3 hour; 12: 12 hours
      ! gfldo%ipdtmpl(34): PDT 4.12 length of the time range for process

      ! change gfldo%ipdtmpl(33) to 11

      gfldo%ipdtmpl(33)=11

      if(gfldo%ipdtmpl(33).eq.1) gfldo%ipdtmpl(34)=int(hrinter)
      if(gfldo%ipdtmpl(33).eq.10) gfldo%ipdtmpl(34)=int(hrinter/3)
      if(gfldo%ipdtmpl(33).eq.11) gfldo%ipdtmpl(34)=int(hrinter/6)
      if(gfldo%ipdtmpl(33).eq.12) gfldo%ipdtmpl(34)=int(hrinter/12)

      gfldo%fld(1:ijd)=aa(1:ijd)

!     print *, 'gfldo%ipdtlen=',gfldo%ipdtlen
!     print *, 'gfldo%ipdtmpl=',gfldo%ipdtmpl

      if(hrinter.eq.24.and.n.ge.4) then
        call printinfr(gfldo,l)
        call putgb2(50+l,gfldo,iret)
      elseif(hrinter.eq.12.and.n.ge.2) then
        call printinfr(gfldo,l)
        call putgb2(50+l,gfldo,iret)
      elseif(hrinter.eq.6) then
        call printinfr(gfldo,l)
        call putgb2(50+l,gfldo,iret)
      endif

    enddo    !### for k = 1, irk

    call gf_free(gfldo)

    100 continue

  enddo    !### for l=1,ivar

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

call baclose(11,iretb)
call baclose(51,irete)
call baclose(12,iretb)
call baclose(52,irete)
call baclose(13,iretb)
call baclose(53,irete)
call baclose(14,iretb)
call baclose(54,irete)
call baclose(15,iretb)
call baclose(55,irete)

CALL W3TAGE('PQPF')

stop    

1020 Continue

print *,'Wrong Data Input, Output or Wrong Message Input'

stop

end

