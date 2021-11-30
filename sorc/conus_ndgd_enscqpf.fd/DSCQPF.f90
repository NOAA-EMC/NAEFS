      PROGRAM DSCQPF_BIAS                                        
!
! MAIN PROGRAM: DSCQPF_BIAS
!   PRGMMR: YAN LUO          DATE: 2017-02-18
!
!  ABSTRACT:
!                                                                    
!   This program will read in bias-corrected 21 ensemble members and multiply        
!        by downscaling ratio to obtain downscaled forecasts (QPFs/PQPFs).
!        The ratio will be applied to each member. The ratio was calculated         
!        based on CCPA daily high/low resolution climatology.                          
!
!  PARAMETERS:
!     1. jpoint  ---> model resolution or total grid points ( 259920 )
!     2. iensem  ---> number of ensember members ( 21 )
!     3. fhrs    ---> total number of 6hrs
!     4. istd    ---> number of thresholds for PQPF output
!
! PROGRAM HISTORY LOG:
! 2017-02-18 YAN LUO IBM-Cray implementation              
! 2021-10-26 YAN LUO Modify for WCOSS2 transition
!
! USAGE:
!
!   INPUT FILE:
!     
!     UNIT 05 -    : CONTROL INPUT FOR RUNNING THE CODE
!     UNIT 11 -    : RFC mask file, GRIB2 format     
!     UNIT 12 -    : Daily Downsacling Ratio file, GRIB2 format      
!     UNIT 20 -    : 0.5 deg bias-corrected QPFs interpolated to 2.5km ndgd, GRIB2 format     
!
!   OUTPUT FILE: 
! 
!     UNIT 50 -    : Downscaled QPFs, GRIB2 format
!     UNIT 51 -    : Downscaled PQPFs, GRIB2 format
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
!   
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
      use grib_mod
      use params

      implicit none

      integer jpoint,iensem,fhrs,istd
      parameter(jpoint=2145*1377,iensem=21)
      parameter(istd=13)
      real rk(istd),smask(jpoint),rmax,rmin
      real, allocatable :: f(:),q(:),ratio(:)
      real, allocatable :: ff(:,:),qqq(:,:)
      integer icyc,iacc,vmm,maxgrd 
      integer kk,n,ii,jj,k,ijk
      integer maskreg(jpoint)
      integer lcmask,ldsr
      integer lctmpd,lpgb,lpgs,lpgr,lpgm
      integer ierrs,ier11,ier12,ier20,ier50,ier51,ier52,iret
      integer ee16(iensem),ee17(iensem)
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

      character datcmd*3,datcyc*2,datacc*2
      character*255 pcpda,cmask,dmask,ctmpd,cdsr
      character*255 cpgbf,coptr,copts
! VAIABLE: APCP

      data ipd1 /1/
      data ipd2 /8/
      data ipd10/1/
      data ipd11/0/
      data ipd12/0/
      data ee16/1,3,3,3,3,3,3,3,3,3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3/
      data ee17/0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20/

      data rk/0.254,1.00,1.27,2.54,5.00,6.35,10.00,12.7,20.0,25.4, &
              50.8,101.6,152.4/

 100   format(a100)
!  READ IN FOR TEMP DIRECTORY                                 
      read   (5,100,end=9000) ctmpd
      write  (6,*) 'FOR TEMP DIRECTORY: ',ctmpd(1:100) 
      lctmpd=len_trim(ctmpd)
!  READ IN US REGIONAL MASK FILE                   
      read   (5,100,end=9000) cmask 
      write  (6,*) 'RFC REGIONAL MASK: ',cmask(1:100) 
      lcmask=len_trim(cmask)

!  READ IN DOWNSCALING RATIO FILE                   
      read   (5,100,end=9000) cdsr
      write  (6,*) 'DOWNSCALING RATIO: ',cdsr(1:100)
      ldsr=len_trim(cdsr)

!  READ IN FOR CYCLE                                
      read   (5,*,end=9000) icyc
      write  (6,*) 'FOR CYCLE: ', icyc 

!  READ IN FOR FORECAST VALID MONTH
      read   (5,*,end=9000)  vmm
      write  (6,*) 'FOR : FORECAST VALID MONTH', vmm

!  READ IN FOR FORECAST HOUR
      read   (5,*,end=9000)  fhrs
      write  (6,*) 'FOR : FORECAST HOUR', fhrs

!  READ IN FOR ACCUMULATION HOURS
      read   (5,*,end=9000)  iacc
      write  (6,*) 'FOR : ACCUMULATION HOURS', iacc

      allocate(f(jpoint),q(jpoint),ratio(jpoint))
      allocate(ff(jpoint,iensem),qqq(jpoint,istd))

!
!  READ IN REGIONAL MASKS FOR THIS GRID
      call baopenr(11,cmask(1:lcmask),ier11)
      ierrs = ier11
      if (ierrs.ne.0) then
       write(6,*) 'GRIB:BAOPEN ERR FOR DATA ',cmask
       write(6,*) 'PLEASE CHECK DATA AVAILABLE OR NOT !!!'
       goto 9000
      endif

      iids=-9999;ipdt=-9999; igdt=-9999
      idisc=-1;  ipdtn=-1;   igdtn=-1

      ipdt(1)=ipd1
      ipdt(2)=ipd2
      ipdt(10)=ipd10
      ipdt(11)=ipd11
      ipdt(12)=ipd12

      ipdtn=8; igdtn=-1
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(11,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,&
                  unpack,jskp,gfld,iret)
      if (iret.eq.0) then
         maxgrd=gfld%ngrdpts
         if (maxgrd .ne. jpoint) then
         print*,'Mismatched resolution between mask and forecast, stop!'
         goto 9000
         endif
       smask(1:jpoint)=gfld%fld(1:jpoint)
       call printinfr(gfld,1)
      else
       write(6,*) 'GETGB PROBLEM FOR MASK : IRET=',iret
       goto 9000
      endif

      do kk=1, jpoint
       maskreg(kk)=nint(smask(kk))
      enddo
       call gf_free(gfld)
       call baclose(11,ier11)

!
!  READ IN DOWSCALING RATIO
      call baopenr(12,cdsr(1:ldsr),ier12)
      ierrs = ier12
      if (ierrs.ne.0) then
         write(6,*) 'GRIB:BAOPEN ERR FOR DATA ',cdsr
         write(6,*) 'PLEASE CHECK DATA AVAILABLE OR NOT'
         goto 9000
      endif

      iids=-9999;ipdt=-9999; igdt=-9999
      idisc=-1;  ipdtn=-1;   igdtn=-1

      ipdt(1)=ipd1
      ipdt(2)=ipd2
      ipdt(10)=ipd10
      ipdt(11)=ipd11
      ipdt(12)=ipd12

      ipdtn=8; igdtn=-1
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(12,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,&
                  unpack,jskp,gfld,iret)
      if (iret.eq.0) then
         maxgrd=gfld%ngrdpts
       if (maxgrd .ne. jpoint) then
        print*,'Mismatched resolution between ratio and forecast, stop!'
        goto 9000
       endif
       ratio(1:jpoint) = gfld%fld(1:jpoint)
       call printinfr(gfld,1)
      else
       write(6,*) 'GETGB PROBLEM FOR RATIO DATA: IRET=',iret
       goto 9000
      endif
       call gf_free(gfld)
       call baclose(12,ier12)

!ccc
!ccc   Step 1: determine the upper and lower limits of downscaling ratio 
!ccc           based on month

       if (vmm.ge.5.and.vmm.le.10) then
        rmax=5.0
        rmin=0.9
       else
        rmax=5.0
        rmin=0.3
       endif        
!ccc
!ccc   Step 2: read in the data on GRIB ndgd2p5 (2145*1377) of conus
!ccc
       print *, " *********************************************"
       print *, " ***      FORECAST HOURS = ",fhrs,"        ***"
       print *, " *********************************************"
 
       write (datcyc,121) icyc
       write (datcmd,122) fhrs
       write (datacc,121) iacc
121    format(i2.2)
122    format(i3.3)

           cpgbf=ctmpd(1:lctmpd) // '/' //'geprcp.t'// &
                 datcyc(1:2)// 'z.ndgd2p5.bc_'//datacc//'hf' //datcmd//'.gb2'
           copts=ctmpd(1:lctmpd) // '/' //'geprcp.t'// &
                 datcyc(1:2)// 'z.ndgd2p5_conus.'//datacc//'hf' //datcmd//'.gb2'
           coptr=ctmpd(1:lctmpd) // '/' //'gepqpf.t'// &
                 datcyc(1:2)// 'z.ndgd2p5_conus.'//datacc//'hf' //datcmd//'.gb2'

           lpgb=len_trim(cpgbf)
           lpgs=len_trim(copts)
           lpgr=len_trim(coptr)

        write  (6,*) '=============================================='
           write  (6,*) 'FORECAST DATA NAME: ',cpgbf(1:lpgb)
           write  (6,*) 'DOWN-SCALED FORECAST DATA NAME: ',copts(1:lpgs)

           call baopenr(20,cpgbf(1:lpgb),ier20)
           call baopenw(50,copts(1:lpgs),ier50)
           call baopenw(51,coptr(1:lpgr),ier51)           

!  READ IN PRECIP FORECAST

       do jj = 1, iensem   ! iensem = # of ensemble 
         iids=-9999;ipdt=-9999; igdt=-9999
         idisc=-1;  ipdtn=-1;   igdtn=-1
         ipdt(1)=ipd1
         ipdt(2)=ipd2
         ipdt(5)=107
         ipdt(10)=ipd10
         ipdt(11)=ipd11
         ipdt(12)=ipd12
         ipdt(16)=ee16(jj)
         ipdt(17)=ee17(jj)
         ipdtn=11; igdtn=-1
         call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
         call getgb2(20,0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,&
                  unpack,jskp,gfld,iret)
        if (iret.eq.0) then
         maxgrd=gfld%ngrdpts
         if (maxgrd .ne. jpoint) then
         print*,'Mismatched resolution between mask and forecast, stop!'
         goto 9000
         endif
          f(1:jpoint) = gfld%fld(1:jpoint)
         call printinfr(gfld,jj)
         else
          write(6,*) 'GETGB PROBLEM FOR FORECAST DATA: IRET=',iret
          goto 9000
        endif
        do ii = 1, jpoint
          ff(ii,jj) = f(ii)
!        if (ratio(ii).gt.4.0) then
!        write(6,'("Before downscaling: at point ratio(ii).qt.4.0")')
!        write(6,*)  maskreg(ii),ff(ii,jj)
!        endif

!ccc    =============================================
!ccc    downscaling apply to each grid point
!ccc    =============================================

        if (maskreg(ii).ge.1.and.maskreg(ii).le.12) then
            if (ratio(ii).lt.rmin) ratio(ii) = rmin
            if (ratio(ii).gt.rmax) ratio(ii) = rmax
            ff(ii,jj) = f(ii)*ratio(ii)
        else
            ff(ii,jj) = f(ii)
        endif
!        if (ratio(ii).gt.4.0) then
!        write(6,'("After downscaling: at point ratio(ii).qt.4.0")')
!        write(6,*)  maskreg(ii),ff(ii,jj)
!        endif
        enddo
        if (jj.ne.iensem) call gf_free(gfld)
       enddo   ! for jj = 1, iensem; iensem = # of ensemble
       gfldo=gfld
!      call gf_free(gfldo)

!ccc
!ccc    write out the downscaled CQPF results
!ccc
        print *, '----- Output Downscaled CQPF -----'
       do jj = 1, iensem
        ! gfld%ipdtmpl(3) = 3               ! code table 4.3, Bias corrected forecast
          gfld%ipdtmpl(3) = 11              ! code table 4.3, Bias corrected ensemble forecast
          gfld%ipdtmpl(5) = 107
          gfld%idsect(13) = 4
          gfld%ipdtmpl(16) = ee16(jj)
          gfld%ipdtmpl(17) = ee17(jj)
!       we need to set up a lower limit, for example: ff = 0.01 mm/day

        do ii = 1, jpoint
         if (ff(ii,jj).lt.0.01) then
          f(ii) = 0.0
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
!        call gf_free(gfld)

       print *,"======================================================"

!ccc
!ccc    calculate the downscaled CPQPF
!ccc
       do k = 1, istd
        f   = 0.0
        do ii = 1, jpoint
         do jj = 1, iensem
          if (ff(ii,jj).ge.rk(k)) then
           f(ii) = f(ii) + 1.0
          endif
         enddo
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
!ccc    write out the downscaled CPQPF results
!ccc
        print *, '----- Output downscaled CPQPF -----'

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
       if (fhrs.le.240) gfldo%ipdtmpl(17)= iensem
      gfldo%ipdtmpl(18)=1     ! Probability Type
                              ! 1: Probability of event above upper limit
      gfldo%ipdtmpl(19)=0     ! Scale factor of lower limit
      gfldo%ipdtmpl(20)=0     ! Scaled value of lower limit
      gfldo%ipdtmpl(21)=3     ! Scale factor of upper limit

      ! gfldo%ipdtmpl(22) will be set below

      gfldo%ipdtmpl(23:36)=temp(19:32)
     ! gfldo%ipdtmpl(22): Scaled value of upper limit

       do k = 1, istd

        do ii = 1, jpoint
          q(ii) = qqq(ii,k)
        enddo

      gfldo%ipdtmpl(3) = 11   ! code table 4.3, Bias corrected ensemble forecast
      gfldo%ipdtmpl(22)=rk(k)*(10**gfldo%ipdtmpl(21))

      gfldo%fld(1:jpoint)=q(1:jpoint)

!     print *, 'gfldo%ipdtlen=',gfldo%ipdtlen
!     print *, 'gfldo%ipdtmpl=',gfldo%ipdtmpl
!      print *, 'k=',k,  'temp=', (temp(i), i=1,32)

      call putgb2(51,gfldo,iret)

       enddo    ! for k = 1, istd
!      call gf_free(gfldo)

       call baclose (20,ier20)
       call baclose (50,ier50)
       call baclose (51,ier51)

       deallocate(f,q)
       deallocate(ff,qqq)
       
9000      stop
          end

