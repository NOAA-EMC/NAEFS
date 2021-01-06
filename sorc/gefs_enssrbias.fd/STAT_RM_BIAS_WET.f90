      program decay_30d
! MAIN PROGRAM: DECAY_30D
!   PRGMMR: YUEJIAN ZHU          DATE: 2002-02-15
!   PRGMMR: YAN LUO              DATE: 2016-05-26
!
! ABSTRACT: TO CALCULATE HISTORICAL STATISTICS BY USING 30-DAY
!           DECAYING FUNCTION
!           THIS PROGRAM COULD BE USED AS M ( NOT ONLY 30-DAY ) DAYS
!           DECAYING CALCULATION
!
! PROGRAM HISTORY LOG:
!   2002-02-15  YUEJIAN ZHU 
!   2011-12-15  YAN LUO  
!   2016-05-26  YAN LUO
!
! USAGE:
!
!   INPUT FILE:
!     
!     UNIT 11 -    : PRIOR DAYS' (DECAYING AVERAGE) BIAS STATISTICS IN BINARY
!     UNIT 12 -    : TODAY'S BIAS STATISTICS IN BINARY 
!
!   OUTPUT FILE: 
!     UNIT 51 -    : UPDATED (DECAYING AVERAGE) BIAS STATISTICS FOR
!                    TODAY IN ASCII (CREATED FOR RESULT CHECK)
!     UNIT 52 -    : UPDATED (DECAYING AVERAGE) BIAS STATISTICS FOR
!                    TODAY IN BINARY (CREATED FOR ACCURATE COMPUTATION)
!
! PROGRAMS CALLED: NONE
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$

      implicit none

      integer   ncat,nreg,nfhr,nday
      parameter (ncat=9,nreg=12,nfhr=64,nday=1)
      integer   hit(ncat,nreg,nfhr,nday)
      integer   obs(ncat,nreg,nfhr,nday)
      integer   fcs(ncat,nreg,nfhr,nday)
      integer   tot(ncat,nreg,nfhr,nday)
      real      thit(ncat,nreg,nfhr)
      real      tobs(ncat,nreg,nfhr)
      real      tfcs(ncat,nreg,nfhr)
      real      ttot(ncat,nreg,nfhr)
      real      dets(ncat,nreg,nfhr,nday)
      real      dbis(ncat,nreg,nfhr,nday)
      real      ets(ncat,nreg,nfhr)
      real      bis(ncat,nreg,nfhr)
      real      dday,ddaym1,weight
      character*255 cfile(2),ofile(2)
      integer   ifile(2),index(nfhr)
      integer   iymd,idday,mfhr,ii,jj,kk,ijk,ifhr,jfhr
      integer   iunit,junit,kunit,lunit
      
      namelist/namin/ cfile,ifile,ofile,iymd,idday,mfhr
      data iunit/11/,junit/12/,kunit/51/,lunit/52/
!ccc
      thit = 0.0
      tobs = 0.0
      tfcs = 0.0
      ttot = 0.0
      dets = 0.0
      dbis = 0.0
      ets  = 0.0
      bis  = 0.0
      index= 0
      obs  = -9999.99
      fcs  = -9999.99
      hit  = -9999.99
      tot  = -9999.99
!ccc
      read  (5,namin,end=1000)
 1000 continue
      write (6,namin)
      dday=float(idday)
      ddaym1=float(idday-1)
      weight=1/dday
!ccc

      ii = 1

      if (ifile(ii).eq.1) then
       open(unit=iunit,file=cfile(ii),form='FORMATTED', &
            status='OLD')
       do jj = 1, mfhr
        jfhr=(jj-1)*6+6
        read (iunit,902,end=101) ifhr
        if (ifhr.eq.jfhr) then
         index(jj) = 1
         backspace (iunit)
!         read (iunit,900)
!         read (iunit,901) obs(1,nreg,jj,ii),fcs(1,nreg,jj,ii),
!     .                    hit(1,nreg,jj,ii),tot(1,nreg,jj,ii),
!     .                    obs(2,nreg,jj,ii),fcs(2,nreg,jj,ii),
!     .                    hit(2,nreg,jj,ii),tot(2,nreg,jj,ii),
!     .                    obs(3,nreg,jj,ii),fcs(3,nreg,jj,ii),
!     .                    hit(3,nreg,jj,ii),tot(3,nreg,jj,ii) 
!         read (iunit,901) obs(4,nreg,jj,ii),fcs(4,nreg,jj,ii),
!     .                    hit(4,nreg,jj,ii),tot(4,nreg,jj,ii),
!     .                    obs(5,nreg,jj,ii),fcs(5,nreg,jj,ii),
!     .                    hit(5,nreg,jj,ii),tot(5,nreg,jj,ii),
!     .                    obs(6,nreg,jj,ii),fcs(6,nreg,jj,ii),
!     .                    hit(6,nreg,jj,ii),tot(6,nreg,jj,ii) 
!         read (iunit,911) obs(7,nreg,jj,ii),fcs(7,nreg,jj,ii),
!     .                    hit(7,nreg,jj,ii),tot(7,nreg,jj,ii),
!     .                    obs(8,nreg,jj,ii),fcs(8,nreg,jj,ii),
!     .                    hit(8,nreg,jj,ii),tot(8,nreg,jj,ii)
         do kk = 1, nreg
          read (iunit,900)      
          read (iunit,901) obs(1,kk,jj,ii),fcs(1,kk,jj,ii), &
                           hit(1,kk,jj,ii),tot(1,kk,jj,ii), &
                           obs(2,kk,jj,ii),fcs(2,kk,jj,ii), &
                           hit(2,kk,jj,ii),tot(2,kk,jj,ii), &
                           obs(3,kk,jj,ii),fcs(3,kk,jj,ii), &
                           hit(3,kk,jj,ii),tot(3,kk,jj,ii) 
          read (iunit,901) obs(4,kk,jj,ii),fcs(4,kk,jj,ii), &
                           hit(4,kk,jj,ii),tot(4,kk,jj,ii), &
                           obs(5,kk,jj,ii),fcs(5,kk,jj,ii), &
                           hit(5,kk,jj,ii),tot(5,kk,jj,ii), &
                           obs(6,kk,jj,ii),fcs(6,kk,jj,ii), &
                           hit(6,kk,jj,ii),tot(6,kk,jj,ii) 
          read (iunit,901) obs(7,kk,jj,ii),fcs(7,kk,jj,ii), &
                           hit(7,kk,jj,ii),tot(7,kk,jj,ii), &
                           obs(8,kk,jj,ii),fcs(8,kk,jj,ii), &
                           hit(8,kk,jj,ii),tot(8,kk,jj,ii), &
                           obs(9,kk,jj,ii),fcs(9,kk,jj,ii), &
                           hit(9,kk,jj,ii),tot(9,kk,jj,ii) 
         enddo
        else
         backspace(iunit)
        endif
 101   continue
       enddo
       close(iunit)
      else
       write (*,'("NO INPUT STAT FOR NEW STAT,QUIT!!!")')
       goto 9000
      endif
!--------+---------+---------+---------+---------+---------+---------+---------+
      ii = 2

      if (ifile(ii).eq.1) then
       open(unit=junit,file=cfile(ii),form='UNFORMATTED', &
            status='OLD')
       do jj = 1, mfhr
        jfhr=(jj-1)*6+6
        do kk = 1, nreg
!        read(junit,900)

!--------+---------+---------+---------+---------+----------+---------+---------+
!        read(junit,900)
!        read(junit,803) (tfcs(ijk,nreg,jj),ijk=1,ncat-1)
!        read(junit,804) (tobs(ijk,nreg,jj),ijk=1,ncat-1)
!        read(junit,808) (thit(ijk,nreg,jj),ijk=1,ncat-1)
!        read(junit,809) (ttot(ijk,nreg,jj),ijk=1,ncat-1)
!        read(junit,900)
        read(junit) (tfcs(ijk,kk,jj),ijk=1,ncat)
        read(junit) (tobs(ijk,kk,jj),ijk=1,ncat)
        read(junit) (thit(ijk,kk,jj),ijk=1,ncat)
        read(junit) (ttot(ijk,kk,jj),ijk=1,ncat)
       enddo
       enddo
       close(junit)

      do jj = 1, 30
      do kk = 1, nreg
       write(*,903) (tfcs(ijk,kk,jj),ijk=1,ncat)
       write(*,904) (tobs(ijk,kk,jj),ijk=1,ncat)
       write(*,908) (thit(ijk,kk,jj),ijk=1,ncat)
       write(*,909) (ttot(ijk,kk,jj),ijk=1,ncat)
      enddo
      enddo

!       do ijk = 1, ncat-1
!        do jj = 1, mfhr
!         if (index(jj).eq.1) then
!         ii = 1
!         kk = nreg
!         tfcs(ijk,kk,jj)=fcs(ijk,kk,jj,ii)+tfcs(ijk,kk,jj)*ddaym1/dday
!         tobs(ijk,kk,jj)=obs(ijk,kk,jj,ii)+tobs(ijk,kk,jj)*ddaym1/dday
!         thit(ijk,kk,jj)=hit(ijk,kk,jj,ii)+thit(ijk,kk,jj)*ddaym1/dday
!         ttot(ijk,kk,jj)=tot(ijk,kk,jj,ii)+ttot(ijk,kk,jj)*ddaym1/dday
!         endif
!        enddo
!       enddo
       do ijk = 1, ncat
        do jj = 1, mfhr
         do kk = 1, nreg
         if (index(jj).eq.1) then
         ii = 1
          if (fcs(ijk,kk,jj,ii).gt.0.and.obs(ijk,kk,jj,ii).gt.0) then
         tfcs(ijk,kk,jj)=fcs(ijk,kk,jj,ii)*weight+ &
                                tfcs(ijk,kk,jj)*(1-weight)
         tobs(ijk,kk,jj)=obs(ijk,kk,jj,ii)*weight+ &
                                tobs(ijk,kk,jj)*(1-weight)
         thit(ijk,kk,jj)=hit(ijk,kk,jj,ii)*weight+ &
                                thit(ijk,kk,jj)*(1-weight)
         ttot(ijk,kk,jj)=tot(ijk,kk,jj,ii)*weight+ &
                                ttot(ijk,kk,jj)*(1-weight)
          endif
         endif
         enddo
        enddo
       enddo
      endif

!
! SAFETY CHECK:
!
      do ijk = 1, ncat
       do jj = 1, mfhr
        if (ttot(ijk,1,jj).gt.500000) then
         ttot(ijk,1,jj)=307000.0
         write(6,*) "PLEASE CHECKING READ IN AND WRITE OUT FILE"
         write(6,*) "PROBLEM!!! PROBLEM!!! PROBLEM!!! *********"
        endif
       enddo
      enddo

      open(unit=kunit,file=ofile(1),form='FORMATTED',&
           status='NEW')
      open(unit=lunit,file=ofile(2),form='UNFORMATTED',&
           status='NEW')
      do jj = 1, mfhr
       do kk = 1, nreg
       write(*,'(2x)')
       write(*,907) (jj-1)*6,(jj-1)*6+6,kk
       write(kunit,907) (jj-1)*6,(jj-1)*6+6,kk
!--------+---------+---------+---------+---------+----------+---------+---------+
!       write(*,905) 
!       write(kunit,905) 
!       write(*,903)    (tfcs(ijk,nreg,jj),ijk=1,ncat-1)
!       write(*,904)    (tobs(ijk,nreg,jj),ijk=1,ncat-1)
!       write(kunit,903)(tfcs(ijk,nreg,jj),ijk=1,ncat-1)
!       write(kunit,904)(tobs(ijk,nreg,jj),ijk=1,ncat-1)
!       write(kunit,908)(thit(ijk,nreg,jj),ijk=1,ncat-1)
!       write(kunit,909)(ttot(ijk,nreg,jj),ijk=1,ncat-1)
       write(*,906) 
       write(kunit,906) 
       write(*,903)     (tfcs(ijk,kk,jj),ijk=1,ncat)
       write(*,904)     (tobs(ijk,kk,jj),ijk=1,ncat)
       write(kunit,903) (tfcs(ijk,kk,jj),ijk=1,ncat)
       write(kunit,904) (tobs(ijk,kk,jj),ijk=1,ncat)
       write(kunit,908) (thit(ijk,kk,jj),ijk=1,ncat)
       write(kunit,909) (ttot(ijk,kk,jj),ijk=1,ncat)
       write(lunit) (tfcs(ijk,kk,jj),ijk=1,ncat)
       write(lunit) (tobs(ijk,kk,jj),ijk=1,ncat)
       write(lunit) (thit(ijk,kk,jj),ijk=1,ncat)
       write(lunit) (ttot(ijk,kk,jj),ijk=1,ncat)
      enddo
      enddo

      if (ifile(2).eq.1) then
       write(kunit,910)
       write(kunit,912) iymd
      else
       write(kunit,910)
       write(kunit,913) iymd
      endif
      close(kunit)
!
 803  format (5x,9(f10.2))
 804  format (5x,9(f10.2))
 808  format (5x,9(f10.2))
 809  format (5x,9(f10.2))
 900  format (1x)
 901  format (6x,4(i5),6x,4(i5),6x,4(i5))         
 911  format (6x,4(i5),6x,4(i5))         
 902  format (32x,i3)                             
 903  format ('FST: ',9(f10.2))
 904  format ('OBS: ',9(f10.2))
 908  format ('HIT: ',9(f10.2))
 909  format ('TOT: ',9(f10.2))
 910  format ('--------------------------------------------------')
 912  format (i8,' has     been added ')
 913  format (i8,' has not been added ')
 905  format ('THOLD  >.01   >0.1   >.25   >.50   >.75 ',&
                  '  >1.0   >1.5   >2.0 (inch/day)')
 906  format ('THOLD      >0.2      >1.0      >2.0      >3.2',&
             '      >5.0      >7.0       >10.      >15.',&
             '      >25.  (mm/6hrs)')
 907  format (10x,'Leading Forecasts ',i3,'-',i3,&
            ' hours    RFC',i2.2) 
      STOP
 1030 print *, " there is a problem to open unit kunit"
 9000 STOP
      END
