      PROGRAM CQPF_BIAS                                        
!
! MAIN PROGRAM: CQPF_BIAS
!   PRGMMR: YUEJIAN ZHU          DATE: 2006-02-06
!   PRGMMR: YAN LUO              DATE: 2016-12-05
!
!  ABSTRACT:
!    PQPF - Probabilitistic Quatitative Precipitation Forecast        
!   CPQPF - Calibrated PQPF by using reduced bias method             
!                                                                    
!   This program will read in 22 ensemble members and multiply        
!        by the coefficents for different threshold amount            
!        of every individual members. The coefficents will be         
!        two sets: one for MRF high resolution, another is           
!        low resolution control which based on past month/season      
!        statistics by using QTPINT interpolation program                              
!
!  PARAMETERS:
!     1. jpoint  ---> model resolution or total grid points ( 259920 )
!     2. iensem ---> number of ensember members ( 22 )
!     3. nfhrs   ---> total number of 6hrs
!     4. numreg  ---> number of RFC regions
!     5. ncat    ---> number of thresholds for bias correction
!     6. istd    ---> number of thresholds for PQPF output
!
! PROGRAM HISTORY LOG:
! 2001-03-22 YUEJIAN ZHU IBM-ASP
! 2001-09-25 YUEJIAN ZHU IBM-ASP modefied
! 2004-02-09 YUEJIAN ZHU IBM-frost implememtation
! 2006-02-06 YUEJIAN ZHU For new configuration
! 2011-12-15 YAN LUO Upgrade to 1 deg and 6 hourly
! 2013-12-18 YAN LUO Convert I/O from GRIB1 to GRIB2
! 2016-12-05 YAN LUO Upgrade to 0.5 deg and 6 hourly
! 2021-10-26 YAN LUO Modify for WCOSS2 transition
! 2022-09-22 BO CUI  Change ensemble size from 22 to 32
!
! USAGE:
!
!   INPUT FILE:
!     
!     UNIT 05 -    : CONTROL INPUT FOR RUNNING THE CODE
!     UNIT 11 -    : RFC mask file, binary format     
!     UNIT 12 -    : statistics numbers for GFS deterministic (mrf)
!     UNIT 13 -    : statitsics numbers for GEFS control (ctl)               
!     UNIT 20 -    : QPF GRIB2 file           
!
!   OUTPUT FILE: 
! 
!     UNIT 50 -    : bias-free calibrated precipitation forecast, GRIB2 format
!     UNIT 51 -    : raw PQPF, GRIB2 format
!     UNIT 52 -    : bias-free CPQPF, GRIB2 format
!
! PROGRAMS CALLED:
!   
!   BAOPENW          GRIB I/O
!   BACLOSE          GRIB I/O
!   GETGRB2          GRIB2 READER
!   PUTGB2           GRIB2 WRITER
!   GF_FREE          FREE UP MEMORY FOR GRIB2 
!   INIT_PARM        DEFINE GRID DEFINITION AND PRODUCT DEFINITION
!   PRINTINFR        PRINT GRIB2 DATA INFORMATION
!   QTPINT           INTERPOLATION PROGRAM
!   CPCOEF           CALCULATE THE PRECIPITATION CALIBRATION
!                    COEFFICENT/RATIO BY USING STATISTICAL DISTRIBUTIONS
!   
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
      use grib_mod
      use params

!      implicit none

      integer jpoint,iensem,nfhrs,numreg,ncat,istd,ipdtnum_out
      parameter(jpoint=720*361,iensem=32,nfhrs=64,numreg=12,ncat=9)
      parameter(istd=13)
      real rk(istd),smask(jpoint)
      real rti(ncat),rob(ncat),rft(ncat)
      real rmrf(ncat),rctl(ncat) 
      real rmrf_us(ncat),rctl_us(ncat)
      real rti_r(ncat),rmrf_r(ncat),rctl_r(ncat)
      real aaa,bbb
      real, allocatable :: rmrf_reg(:,:),rctl_reg(:,:)
      real, allocatable :: thit_mrf(:,:,:),tobs_mrf(:,:,:)
      real, allocatable :: tfcs_mrf(:,:,:),ttot_mrf(:,:,:)
      real, allocatable :: thit_ctl(:,:,:),tobs_ctl(:,:,:)
      real, allocatable :: tfcs_ctl(:,:,:),ttot_ctl(:,:,:)
      real, allocatable :: usobs(:,:),usfcs(:,:)
      real, allocatable :: f(:),q(:),fst(:),avg(:),spr(:),wgt(:)
      real, allocatable :: ff(:,:),fff(:,:),qqq(:,:)
      integer fhrs,icyc,maxgrd 
      integer kk,n,ii,jj,iend,k,ijk
      integer maskreg(jpoint)
      integer lctmpd,lpgb,lpgs,lpgr,lpgm
      integer ier20,ier50,ier51,ier52,iret
      integer e16(iensem),e17(iensem)
      integer ee16(iensem-1),ee17(iensem-1)
      integer temp(200)

      integer ipd1,ipd2,ipd10,ipd11,ipd12
      integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
      integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
      common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

      type(gribfield) :: gfld,gfldo
      integer :: currlen=0
      logical :: unpack=.true.
      logical :: expand=.false.

      logical :: first=.true.

      character datcmd*3,datcyc*2
      character*255 clmrf,fclmrf,clctl,fclctl,pcpda,cmask,dmask,ctmpd
      character*255 cpgbf,coptr,copts,coptm 
! VAIABLE: APCP

      data ipd1 /1/
      data ipd2 /8/
      data ipd10/1/
      data ipd11/0/
      data ipd12/0/
      data e16/0,1,3,3,3,3,3,3,3,3,3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3/
      data e17/0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30/
      data ee16/1,3,3,3,3,3,3,3,3,3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3/
      data ee17/0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30/

      data rk/0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4, &
              50.8,101.6,152.4/
      data rti/25.0,15.0,10.0,7.0,5.0,3.2,2.0,1.0,0.2/

 90   format(a90)
!  READ IN FOR TEMP DIRECTORY                                
      read   (5,90,end=9000) ctmpd 
      write  (6,*) 'FOR TEMP DIRECTORY: ',ctmpd(1:90) 
      lctmpd=len_trim(ctmpd)
!  READ IN MODEL INFO FILE NAME AND OPENED
      read   (5,90,end=9000) clmrf
      fclmrf=ctmpd(1:lctmpd) // '/' //clmrf(1:40)
      write  (6,*) 'STATITICAL DATA FILE: ',fclmrf
!  READ IN MODEL INFO FILE NAME AND OPENED
      read   (5,90,end=9000) clctl
      fclctl=ctmpd(1:lctmpd) // '/' //clctl(1:40)
      write  (6,*) 'STATITICAL DATA FILE: : ',fclctl
!  READ IN US REGIONAL DATA FILE                   
      read   (5,90,end=9000) cmask 
      write  (6,*) 'RFC REGIONAL MASK: ',cmask(1:90) 
!  READ IN FOR CYCLE                                
      read   (5,*,end=9000) icyc
      write  (6,*) 'FOR CYCLE: ', icyc 
!  READ IN FOR FORECAST HOUR
      read   (5,*,END=9000)  fhrs
      write  (6,*) 'FOR : FORECAST HOUR', fhrs
!
!  READ IN REGIONAL MASKS FOR THIS GRID
      open   (unit=11,file=cmask,form='unformatted',status='old')
      read(11) smask
      close(11)
      do kk=1, jpoint
       maskreg(kk)=nint(smask(kk))
      enddo
      allocate(rmrf_reg(ncat,numreg),rctl_reg(ncat,numreg))
      allocate(thit_mrf(ncat,numreg,40),tobs_mrf(ncat,numreg,40))
      allocate(tfcs_mrf(ncat,numreg,40),ttot_mrf(ncat,numreg,40))
      allocate(thit_ctl(ncat,numreg,nfhrs),tobs_ctl(ncat,numreg,nfhrs))
      allocate(tfcs_ctl(ncat,numreg,nfhrs),ttot_ctl(ncat,numreg,nfhrs))
      allocate(usobs(ncat,nfhrs),usfcs(ncat,nfhrs))

      thit_mrf=0.0
      tobs_mrf=0.0
      tfcs_mrf=0.0
      ttot_mrf=0.0
      thit_ctl=0.0
      tobs_ctl=0.0
      tfcs_ctl=0.0
      ttot_ctl=0.0
      usobs=0.0
      usfcs=0.0

      open   (unit=12,file=fclmrf,form='unformatted',status='old')
      open   (unit=13,file=fclctl,form='unformatted',status='old')

      do n = 1, 40     ! for GFS
       do kk = 1, numreg
        read(12) (tfcs_mrf(ii,kk,n),ii=ncat,1,-1)
        read(12) (tobs_mrf(ii,kk,n),ii=ncat,1,-1)
        read(12) (thit_mrf(ii,kk,n),ii=ncat,1,-1)
        read(12) (ttot_mrf(ii,kk,n),ii=ncat,1,-1)
!        write(6,*)(tfcs_mrf(ii,kk,n),ii=ncat,1,-1)
!        write(6,*)(tobs_mrf(ii,kk,n),ii=ncat,1,-1)  
       enddo
      enddo
      do n = 1, 64     ! for CTL
       do kk = 1, numreg
        read(13) (tfcs_ctl(ii,kk,n),ii=ncat,1,-1)
        read(13) (tobs_ctl(ii,kk,n),ii=ncat,1,-1)
        read(13) (thit_ctl(ii,kk,n),ii=ncat,1,-1)
        read(13) (ttot_ctl(ii,kk,n),ii=ncat,1,-1)
       enddo
      enddo
      close (12)
      close (13)
!ccc
!ccc   Step 1: read in the data on GRIB 3 ( 720*361 ) of global
!ccc
      n = fhrs/6      
       print *, " ***********************************"
       print *, " ***      SIX HOURS = ",n,"        ***"
       print *, " ***********************************"
!      if (fhrs.lt.100) then
!        write (datcmd,121) fhrs
!      else 
        write (datcmd,122) fhrs
!      endif
      write (datcyc,121) icyc
121   format(i2.2)
122   format(i3.3)

           cpgbf=ctmpd(1:lctmpd) // '/' //'geprcp.t'// &
                 datcyc(1:2)// 'z.pgrb2a.0p50.f' //datcmd           
           copts=ctmpd(1:lctmpd) // '/' //'geprcp.t'// &
                 datcyc(1:2)// 'z.pgrb2a.0p50.bc_f' //datcmd
           coptr=ctmpd(1:lctmpd) // '/' //'gepqpf.t'// &
                 datcyc(1:2)// 'z.pgrb2a.0p50.f' //datcmd
           coptm=ctmpd(1:lctmpd) // '/' //'gepqpf.t'// &
                 datcyc(1:2)// 'z.pgrb2a.0p50.bc_f' //datcmd
!
!        CALL FUNCTION STAT TO FIND NUMBER OF BYTES IN FILE
!
        write  (6,*) '=============================================='
           write  (6,*) 'FORECAST DATA NAME: ',cpgbf(1:100)
           write  (6,*) 'BIAS CORRECTED FORECAST DATA NAME: ',copts(1:100)
           lpgb=len_trim(cpgbf)
           lpgs=len_trim(copts)
           lpgr=len_trim(coptr)
           lpgm=len_trim(coptm)
           call baopenr(20,cpgbf(1:lpgb),ier20)
           call baopenw(50,copts(1:lpgs),ier50)
           call baopenw(51,coptr(1:lpgr),ier51)           
           call baopenw(52,coptm(1:lpgm),ier52)

!  READ IN PRECIP FORECAST
      if (n.le.40) then
       iend=iensem
      else
       iend=iensem-1
      endif

      allocate(f(jpoint),q(jpoint))
      allocate(avg(jpoint),spr(jpoint))
      allocate(fst(iend),wgt(iend))
      allocate(ff(jpoint,iend),fff(jpoint,istd),qqq(jpoint,istd))

       do jj = 1, iend   ! iend = # of ensemble 
         iids=-9999;ipdt=-9999; igdt=-9999
         idisc=-1;  ipdtn=-1;   igdtn=-1
         ipdt(1)=ipd1
         ipdt(2)=ipd2
         ipdt(5)=107
         ipdt(10)=ipd10
         ipdt(11)=ipd11
         ipdt(12)=ipd12
         if (n.le.40) then
          if (jj.eq.1) ipdt(5)=96
          ipdt(16)=e16(jj)
          ipdt(17)=e17(jj)
         else
          ipdt(16)=ee16(jj)
          ipdt(17)=ee17(jj)
         endif
         ipdtn=11; igdtn=-1
         call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
         call getgb2(20,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,&
                  unpack,jskp,gfld,iret)
        if (iret.eq.0) then
         maxgrd=gfld%ngrdpts
         if (maxgrd .ne. jpoint) then
         print*,'Mismatched resolution between mask and forecast, stop!'
         endif
         if (maxgrd .ne. jpoint) goto 9000
          f(1:jpoint) = gfld%fld(1:jpoint)
         call printinfr(gfld,jj)
        do ii = 1, jpoint
          ff(ii,jj) = f(ii)
        enddo
        endif  ! if (iret.eq.0)
        if (jj.ne.iend) call gf_free(gfld)
       enddo   ! for jj = 1, iend; iend = # of ensemble 
       gfldo=gfld

       print *,'fcst= ', ff(4600,iend) 
       print *, "============================================"

!ccc
!ccc    Step 2: calculate the PQPF
!ccc
       do k = 1, istd
        f   = 0.0
        do ii = 1, jpoint
!ccccc to exclude GFS/AVN high resolution forecast
       if (n.le.40) then
         do jj = 2, iend
          if (ff(ii,jj).ge.rk(k)) then
           f(ii) = f(ii) + 1.0
          endif
         enddo
         else
         do jj = 1, iend
          if (ff(ii,jj).ge.rk(k)) then
           f(ii) = f(ii) + 1.0
          endif
         enddo
       endif
         f(ii) = f(ii)*100.00/float(21)
         if (f(ii).ge.99.0) then
          f(ii) = 100.0
         endif
        enddo
         do ii = 1, jpoint
         fff(ii,k)=f(ii)
          enddo        
       enddo

!ccc
!ccc    Step 3: get statistical coefficents and multiply by it
!ccc

       if (n.le.40) then
       do ii=1,ncat
       usfcs(ii,n)=0
       usobs(ii,n)=0
       enddo
       do kk = 1, numreg
       do ii=1,ncat
        usfcs(ii,n)=usfcs(ii,n)+tfcs_mrf(ii,kk,n)
        usobs(ii,n)=usobs(ii,n)+tobs_mrf(ii,kk,n)
        rft(ii)=tfcs_mrf(ii,kk,n)
        rob(ii)=tobs_mrf(ii,kk,n)
        enddo
       call cpcoef(rti,rob,rft,rmrf,ncat,2)
      do ii = 1, ncat
        rti_r(ii)  = rti(ncat-ii+1)
        rmrf_reg(ii,kk) = rmrf(ncat-ii+1)
      enddo
!ccc    print out ratio/coefficences for mrf
       write (*,'(8x,9f7.2)') (rmrf_reg(ii,kk),ii=ncat,1,-1)
      enddo
        do ii = 1,ncat
        rft(ii)=usfcs(ii,n)
        rob(ii)=usobs(ii,n)
        enddo
       call cpcoef(rti,rob,rft,rmrf,ncat,2)
       do ii = 1, ncat
        rmrf_us(ii) = rmrf(ncat-ii+1)
       enddo
!ccc    print out ratio/coefficences for mrf
       write (*,'(8x,9f7.2)') (rmrf_us(ii),ii=ncat,1,-1)
      endif
      do ii = 1, ncat
       usfcs(ii,n)=0
       usobs(ii,n)=0
        enddo
       do kk = 1, numreg
        do ii = 1,ncat
        usfcs(ii,n)=usfcs(ii,n)+tfcs_ctl(ii,kk,n)
        usobs(ii,n)=usobs(ii,n)+tobs_ctl(ii,kk,n)
        rft(ii)=tfcs_ctl(ii,kk,n)
        rob(ii)=tobs_ctl(ii,kk,n)
        enddo
       call cpcoef(rti,rob,rft,rctl,ncat,2)
       do ii = 1, ncat
        rti_r(ii)  = rti(ncat-ii+1)
        rctl_reg(ii,kk) = rctl(ncat-ii+1)
       enddo
!ccc    print out ratio/coefficences for ctl
       write (*,'(8x,9f7.2)') (rctl_reg(ii,kk),ii=ncat,1,-1)
      enddo
        do ii = 1,ncat
        rft(ii)=usfcs(ii,n)
        rob(ii)=usobs(ii,n)
        enddo
       call cpcoef(rti,rob,rft,rctl,ncat,2)
       do ii = 1, ncat
        rctl_us(ii) = rctl(ncat-ii+1)
       enddo
!ccc    print out ratio/coefficences for ctl
       write (*,'(8x,9f7.2)') (rctl_us(ii),ii=ncat,1,-1)

!ccc    main loop for each grid points ( 264 points )
!ccc    =============================================
!ccc    the new program didn't use 264 boxes -Y. ZHU (06/30/2003)
!ccc    calibration apply to globally.
!ccc
       do ii = 1, jpoint
        if (ii.eq.25010) then
         write(*,'("example of first 10 ens value at point 25010")')
         write(*,899)  maskreg(ii),(ff(ii,jj),jj=2,11)
        endif
!ccc
!ccc     Notes:
!ccc     rti_r(n) is thread amount of precipitation
!ccc     rtmrf_r(n) is the ratio/coefficences of rti_r(n) for mrf forecast
!ccc     rtctl_r(n) is the ratio/coefficences of rti_r(n) for ctl forecast
!ccc
!ccc     for qtpint:
!ccc     input: rti_r(n)
!ccc     input: rtmrf_r(n)
!ccc     input request: aaa -> single value
!ccc     output for aaa: bbb-> single value (ratio value for aaa )
!ccc     calibrated precipitation = aaa*bbb
!ccc

        do jj = 1, iend
         aaa = ff(ii,jj)
         if (aaa.eq.0.0) then
          ff(ii,jj) = 0.0
         else
          if (jj.eq.1.and.n.le.40) then
         if (maskreg(ii).gt.0) then
          kk=maskreg(ii)
         do ijk=1,ncat
          rmrf_r(ijk)=rmrf_reg(ijk,kk)
         enddo
         else
         do ijk=1,ncat
          rmrf_r(ijk)=rmrf_us(ijk)
         enddo
          endif
!          call stpint(rti_r,rmrf_r,9,2,aaa,bbb,1,aux,naux)
          call qtpint(rti_r,rmrf_r,9,2,aaa,bbb,1)
           ff(ii,jj) = aaa*bbb
          else

         if (maskreg(ii).gt.0) then
          kk=maskreg(ii)
         do ijk=1,ncat
          rctl_r(ijk)=rctl_reg(ijk,kk)
         enddo
         else
         do ijk=1,ncat
          rctl_r(ijk)=rctl_us(ijk)
         enddo
          endif
!           call stpint(rti_r,rctl_r,9,2,aaa,bbb,1,aux,naux)
           call qtpint(rti_r,rctl_r,9,2,aaa,bbb,1)
           ff(ii,jj) = aaa*bbb
         endif
         endif
        enddo  

         if (ii.eq.25010) then
         write(*,899) maskreg(ii),(ff(ii,jj),jj=2,11)
         write (*,'(8x,9f7.2)') (rti_r(ijk),ijk=ncat,1,-1)
         if (n.le.40) write (*,'(8x,9f7.2)') (rmrf_r(ijk),ijk=ncat,1,-1)
         write (*,'(8x,9f7.2)') (rctl_r(ijk),ijk=ncat,1,-1)
        endif

 899   format(2x,i6,10f7.2)

       enddo     ! for ind loop  / ii loop 

!ccc
!ccc    write out the bias-corrected QPF results
!ccc
        print *, '----- Output Bias Corrected QPF -----'
       do jj = 1, iend
        ! gfld%ipdtmpl(3) = 3               ! code table 4.3, Bias corrected forecast
          gfld%ipdtmpl(3) = 11              ! code table 4.3, Bias corrected ensemble forecast 
          gfld%ipdtmpl(5) = 107
          gfld%idsect(13) = 4

        if (n.le.40) then
          if (jj.eq.1)  gfld%ipdtmpl(5) = 96
          gfld%ipdtmpl(16) = e16(jj)
          gfld%ipdtmpl(17) = e17(jj)
        else
          gfld%ipdtmpl(16) = ee16(jj)
          gfld%ipdtmpl(17) = ee17(jj)
        endif
!       we need to set up a lower limit, for example: ff = 0.01 mm/day

        do ii = 1, jpoint
         if (ff(ii,jj).lt.0.01) then
          f(ii) = 0.0
          ff(ii,jj) = 0.0
         else
          f(ii) = ff(ii,jj)
         endif
        enddo

! get the number of bits
! gfld%idrtmpl(3) : GRIB2 DRT 5.40 decimal scale factor

! gfld%idrtmpl(4) : GRIB2 DRT 5.40 number of bits

        gfld%fld(1:jpoint)=f(1:jpoint)
        call putgb2(50,gfld,iret)
        call printinfr(gfld,1)
       enddo

! calculate ensemble mean & spread
       do ii = 1, jpoint

          fst(1:iend)=ff(ii,1:iend)

        do jj = 1, iend
           wgt(jj)=1/float(iend)
        enddo

        avg(ii)=epdf(fst,wgt,iend,1.0,0)
        spr(ii)=epdf(fst,wgt,iend,2.0,0)

       enddo

       print *, 'avg(8601)= ',avg(8601)
       print *, 'spr(8601)= ',spr(8601)

! when product difinition template 4.1/4.11 chenge to 4.2/4.12
! ipdtlen aslo change, need do modification for output
! code table 4.0, 2=derived forecast

       if(gfld%ipdtnum.eq.1) ipdtnum_out=2
       if(gfld%ipdtnum.eq.11) ipdtnum_out=12

       call change_template4(gfld%ipdtnum,ipdtnum_out,gfld%ipdtmpl,gfld%ipdtlen)

! extensions for ensemble mean

       gfld%ipdtmpl(16)=0      ! code table 4.7, 0=unweighted mean of all Members
       gfld%ipdtmpl(17)=iend   ! template 4.2, number of forecast in the ensemble

        gfld%fld(1:jpoint) = avg(1:jpoint)

        print *, '-----  Ensemble Average for Current Time ------'
        call putgb2(50,gfld,iret)
        call printinfr(gfld,1)

! extensions for ensemble spread

        gfld%ipdtmpl(16)=2        ! code table 4.7, 2=standard deviation w.r.t cluster mean
        gfld%ipdtmpl(17)=iend     ! template 4.2, number of forecast in the ensemble

        gfld%fld(1:jpoint) = spr(1:jpoint)

        print *, '-----  Ensemble Spread for Current Time ------'
        call putgb2(50,gfld,iret)
        call printinfr(gfld,1)

!        call gf_free(gfld)
     
       print *,"======================================================"

!ccc
!ccc    calculate the CPQPF
!ccc
       do k = 1, istd
        f   = 0.0
        do ii = 1, jpoint
!ccccc to exclude GFS/AVN high resolution forecast
       if (n.le.40) then
         do jj = 2, iend
          if (ff(ii,jj).ge.rk(k)) then
           f(ii) = f(ii) + 1.0
          endif
         enddo
         else
         do jj = 1, iend
          if (ff(ii,jj).ge.rk(k)) then
           f(ii) = f(ii) + 1.0
          endif
         enddo
       endif
         f(ii) = f(ii)*100.00/float(21)
         if (f(ii).ge.99.0) then
          f(ii) = 100.0
         endif
        enddo
         do ii = 1, jpoint
         qqq(ii,k)=f(ii)
         enddo
       enddo  ! for do k = 1, istd
!ccc
!ccc    write out the PQPF/CPQPF results
!ccc
        print *, '----- Output PQPF/CPQPF -----'

      temp=-9999

      ! change grib2 pdt message for new ensemble products

      gfldo%idsect(2)=2  ! Identification of originating/generating subcenter
                         ! 2: NCEP Ensemble Products

      gfldo%idsect(13)=5 ! Type of processed data in this GRIB message       
                         ! 5: Control and Perturbed Forecast Products

!     print *, 'gfldo%ipdtlen=',gfldo%ipdtlen 
!     print *, 'gfldo%ipdtmpl=',gfldo%ipdtmpl 

      temp(1:gfldo%ipdtlen)=gfldo%ipdtmpl(1:gfldo%ipdtlen)

      deallocate (gfldo%ipdtmpl)
                              ! 5: Probability Forecast 
      gfldo%ipdtnum=9         ! Probability forecasts from ensemble 
      if(gfldo%ipdtnum.eq.9) gfldo%ipdtlen=36
      if(gfldo%ipdtnum.eq.9) allocate (gfldo%ipdtmpl(gfldo%ipdtlen))

      gfldo%ipdtmpl(1:15)=temp(1:15)

      gfldo%ipdtmpl(1)=1      ! Parameter category : 1 Moisture
      gfldo%ipdtmpl(2)=8      ! Parameter number : 8 Total Precipitation(APCP)

      gfldo%ipdtmpl(16)=0     ! Forecast probability number 
      gfldo%ipdtmpl(17)= iensem-1  ! Total number of forecast probabilities
       if (n.le.40) gfldo%ipdtmpl(17)= iensem
      gfldo%ipdtmpl(18)=1     ! Probability Type
                              ! 1: Probability of event above upper limit
      gfldo%ipdtmpl(19)=0     ! Scale factor of lower limit
      gfldo%ipdtmpl(20)=0     ! Scaled value of lower limit
      gfldo%ipdtmpl(21)=3     ! Scale factor of upper limit

      ! gfldo%ipdtmpl(22) will be set below 

      gfldo%ipdtmpl(23:36)=temp(18:31)
     ! gfldo%ipdtmpl(22): Scaled value of upper limit

       do k = 1, istd

        do ii = 1, jpoint
          f(ii) = fff(ii,k)
          q(ii) = qqq(ii,k)
        enddo

      gfldo%ipdtmpl(3) = 5
      gfldo%ipdtmpl(22)=rk(k)*(10**gfldo%ipdtmpl(21))

      gfldo%fld(1:jpoint)=f(1:jpoint)

!     print *, 'gfldo%ipdtlen=',gfldo%ipdtlen
!     print *, 'gfldo%ipdtmpl=',gfldo%ipdtmpl
!      print *, 'k=',k,  'temp=', (temp(i), i=1,32)

      call putgb2(51,gfldo,iret)

      gfldo%ipdtmpl(3) = 11              ! code table 4.3, Bias corrected ensemble forecast
      gfldo%fld(1:jpoint)=q(1:jpoint)

      call putgb2(52,gfldo,iret)

       enddo    ! for k = 1, istd
!      call gf_free(gfldo)

       call baclose (20,ier20)
       call baclose (50,ier50)
       call baclose (51,ier51)
       call baclose (52,ier52)
       deallocate(f,q)
       deallocate(fst,wgt)
       deallocate(avg,spr)
       deallocate(ff,fff,qqq)
       deallocate(rmrf_reg,rctl_reg)
       deallocate(thit_mrf,tobs_mrf)
       deallocate(tfcs_mrf,ttot_mrf)
       deallocate(thit_ctl,tobs_ctl)
       deallocate(tfcs_ctl,ttot_ctl)
       deallocate(usobs,usfcs)
       
9000      stop
          end


!--------+---------+---------+---------+---------+---------+---------+---------+
      subroutine cpcoef(x,y,z,r,n,ictl)
!
!     This program will calculate the precipitation calibration
!     coefficence by using statistical distributions
!
!     Program: IBM-ASP     By: Yuejian Zhu ( 03/22/2001 )
!              Modified    By: Yuejian Zhu ( 03/21/2004 )
!
!     Input:    x(n)-vector for preciptation threshold amount
!               y(n)-vector for observation numbers at x(n)
!               z(n)-vector for forecasting numbers at x(n)
!               n   -length of the vector
!               ictl-to control the interpolation bases
!                    1 - standard
!                    2 - logrithm
!     Output:   r(n)-coefficents/ratio of each threshold amount x(n)
!               which will apply to particular precipitation amount
!               multiply the ratio at this point (linear interpolation)
!
      real x(n),y(n),z(n),r(n),a(n),b(n)             
      real rnti(n-2),rnto(n-2)

!     Safty check of x-axis (dimension y)
!      Repeating to confirm the x-axis is ascending
      do i = 1, n-1
       do j = 1, n-2
        if (y(i).eq.y(i+1)) then
         y(i) = y(i) + 1.0  
        endif
       enddo
      enddo

      if ( ictl.eq.1) then

!
!   input: y(n) as abscissas (x-axis)
!   input: x(n) as ordinates (y-axis) 
!   input: z(n) as request abscissas values ( x-axis )
!   output: b(n) as cooresponding values of z(n)
!           similar to the thread amount, but shifted

!       call stpint(y,x,n,2,z,r,n,aux,naux)
       call qtpint(y,x,n,2,z,r,n)

       write(*,991) (y(i),i=1,n)
       write(*,993) (x(i),i=1,n)
       write(*,992) (z(i),i=1,n)
       write(*,994) (r(i),i=1,n)
       write(*,995) (r(i)/x(i),i=1,n)
  
!      do i = 1, n-2
!       rnti(i) = x(n-i)
!       rnto(i) = r(n-i)/x(n-i)
!      enddo
!      call stpint(rnti,rnto,n-2,2,x,r,n,aux,naux)
!      write(*,993) (r(i),i=1,n)
!      if (r(n).lt.0.0.and.r(n-1).gt.0.0) then
!       r(n) = r(n-1)*r(n-2)
!      endif
!      write(*,993) (r(i),i=1,n)

      else
!
!  Tested both of log and log10, log is better
!
!   input: y(n) as abscissas (x-axis)
!   input: x(n) as ordinates (y-axis) -- using logrithem a(n) instead
!   input: z(n) as request abscissas values ( x-axis )
!   output: b(n) as cooresponding values of z(n)
!           similar to the thread amount, but shifted

       do i = 1, n
        a(i) = alog(x(i))
!       a(i) = log10(x(i))
       enddo

!       call stpint(y,a,n,2,z,b,n,aux,naux)
       call qtpint(y,a,n,2,z,b,n)

       do i = 1, n
        r(i) = exp(b(i))
!       r(i) = exp(b(i)*log(10.0))
        if (r(i).gt.100.0) then
         print *, "i=",i,"  r(i)=",r(i)," problem, use default"
         r(i) = x(i)
        endif
       enddo

       write(*,991) (y(i),i=1,n)
       write(*,993) (x(i),i=1,n)
       write(*,992) (z(i),i=1,n)
       write(*,994) (r(i),i=1,n)
       write(*,995) (r(i)/x(i),i=1,n)
   
!      do i = 1, n-2
!       rnti(i) = x(n-i)
!       rnto(i) = exp(b(n-i))/x(n-i)
!       rnto(i) = exp(b(n-i)*log(10.0))/x(n-i)
!      enddo
!      call stpint(rnti,rnto,n-2,2,x,r,n,aux,naux)
!      write(*,993) (r(i),i=1,n)
!      if (r(n).lt.0.0.and.r(n-1).gt.0.0) then
!       r(n) = r(n-1)*r(n-2)
!      endif
!      write(*,993) (r(i),i=1,n)
      endif

      do i = 1, n
       r(i) = r(i)/x(i)
      enddo

 991  format ('input = ',9f7.2,' OBS')
 992  format ('input = ',9f7.2,' FST')
 993  format ('input = ',9f7.2,' thrd    ')
 994  format ('output= ',9f7.2,' thrd_FST')
 995  format ('ratio = ',9f7.2,' tFST/thrd')
      return
      end

!           ==== using p50 results ====
!input =   75.00  50.00  35.00  25.00  15.00  10.00   5.00   2.00    .20
!output=   78.57  78.57  57.14  30.83  15.71   9.86   4.41   1.07  -3.19
!ratio =    1.05   1.57   1.63   1.23   1.05    .99    .88    .54 -15.95

!           ==== using t62 results ====
!input =   75.00  50.00  35.00  25.00  15.00  10.00   5.00   2.00    .20
!output=   78.57  67.86  41.32  25.83  14.36   9.27   4.17   1.19  -2.42
!ratio =    1.05   1.36   1.18   1.03    .96    .93    .83    .59 -12.10
!ratio =    1.65   1.36   1.18   1.03    .96    .93    .83    .59    .45
