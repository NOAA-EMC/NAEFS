      subroutine verf(fcst,ana,lfc,lan,maskreg,jo,numreg,numthr,thresh,&
                      lthrun,igrid,igmdl,ianatyp,fmask,isyr,ismn,isda,ishr,&
                      iyr,imn,ida,ihr,ifhr,iacc,mdlnam,iounit,total,incomplete)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM: SUBROUTINE VERF(FCST,ANA,LFC,LAN,MASKREG,JO,NUMREG,NUMTHR,THRESH,&
!             lthrun,igrid,igmdl,ianatyp,fmask,isyr,ismn,isda,ishr,&
!             iyr,imn,ida,ihr,ifhr,iacc,MDLNAM,iounit)     
!   PRGMMR: YUEJIAN ZHU       ORG:NP23          DATE: FEB 2004
!
!   ABSTRACT:  THIS SUBROUTINE WILL PERFORM PRECIP VERIFICATION
! PROGRAM HISTORY LOG:
!   FEB 2004   YUEJIAN ZHU (WD20YZ)
!   MAY 2010   YAN LUO (WX22LU)
! USAGE:
!
!   INPUT ARGUMENTS:
!     FCST - FORECAST GRID
!     ANA  - ANALYSIS GRID
!     LFC  - BIT MAP FOR FORECAST GRID
!     LAN  - BIT MAP FOR ANALYSIS GRID TO DETERMINE VERF DOMAIN
!     MASKREG - INTEGER MAP FOR TO DETERMINE REGIONAL VERF DOMAINS
!     JO  - SIZE OF FCST,ANA,LFC,LAN
!     NUMREG  - NUMBER OF REGIONS
!     NUMTHR  - NUMBER OF THRESHOLDS
!     THRESH  - VERIFICATION THRESHOLDS
!     LTHRUN  - UNIT OF THRESHOLD INDICATOR (1=mm,2=in)
!     IGRID   - GRID NUMBER
!     IANATYP - ANALYSIS TYPE (1=NATV, 2=MPCP)
!     FMASK   - NAMES OF THE REGIONAL MASKS
!     ISYR    - START DATE YEAR
!     ISMN    - START DATE MONTH
!     ISDA    - START DATE DAY
!     ISHR    - START DATE HOUR
!     IYR     - VALID DATE YEAR
!     IMN     - VALID DATE MONTH
!     IDA     - VALID DATE DAY
!     IHR     - VALID DATE HOUR
!     IFHR    - FCST HOUR
!     IACC    - LENGTH OF ACCUMULATION
!     MDLNAM  - NAME OF MODEL
!     IOUNIT  - UNIT TO WRITE STATS OUT TO
!
!     OUTPUT IS WRITTEN TO IOUNIT IN THIS FORM:
!12345678*1*2345678*2*2345678*3*2345678*4*2345678*5*2345678*6*2345678*7*2345678*8
! modl    yyyymmddhh yyyymmddhh fhr acc grd grd thr un #obs #for #hit #tot
!                                  len ver mdl     it  pts  pts  pts  pts
! ERL     1997032412 1997032600 036 024 096 096 00.2mm 1777 1223 1432 7773
!Columns 02-08 is the forecast model verified.
!Columns 10-19 is the start date for the forecast.
!Columns 21-30 is the valid date for the forecast.
!Columns 32-34 is the forecast hour.
!Columns 36-38 is the accumulation length.
!Columns 40-42 is the verifying grid.
!Columns 43    is the verifying grid sub-domain.
!Columns 44-46 is the model grid.
!Columns 48-51 is the threshold.
!Columns 52-53 is the threshold unit.
!Columns 55-58 is the number of obs points.
!Columns 60-63 is the number of fcst points.
!Columns 65-68 is the number of correct points.
!Columns 70-73 is the number of total verifying points.
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
      implicit none

      integer jo,numreg,numthr
      integer maskreg(jo)
      integer iyr,imn,ida,ihr,ifhr
      integer isyr,ismn,isda,ishr
      integer f(numthr),h(numthr),o(numthr),t(numthr)
      integer total(numreg),incomplete,iounit
      integer lthrun,k,l,ij,iacc,igmdl,igrid,ianatyp
      real    fcst(jo),ana(jo),thresh(numthr)
      real    fctr,thrp,halftot
      logical*1 lfc(jo),lan(jo)
      character mdlnam*10,mdl*8,reg*3
      character fmask(numreg)*4,regful*4
      character anaty(2)*4,unit(2)*2
      data anaty/'NATV','MPCP'/
      data unit/'mm','in'/
      data reg/'RFC'/
!
      incomplete = 0
      mdl = mdlnam(1:8)
      fctr = 1.0
      if (lthrun.eq.2) fctr=25.4
      do k=1,numreg
!        regful=fmask(k)
!        reg=regful(1:1)
        do l = 1,numthr
          thrp = thresh(l) * fctr
          t(l) = 0.
          o(l) = 0.
          f(l) = 0.
          h(l) = 0.
          do  ij = 1,jo
!          if (lan(ij).and.lfc(ij).and.maskreg(ij).eq.k) then
           if (lan(ij).and.maskreg(ij).eq.k) then
            t(l) = t(l) + 1
            if (ana(ij).gt.thrp) o(l) = o(l) + 1
            if (fcst(ij).gt.thrp) f(l) = f(l) + 1
            if (ana(ij).gt.thrp.and.fcst(ij).gt.thrp) h(l) = h(l) + 1
           endif
          enddo
        enddo
         halftot = 0.5 * total(k)
         write(6,*) 'T(1)= ', t(1), 'TOTAL(K)=', total(k)
         if (t(1).eq.0.or.t(1).le.halftot) then
         incomplete = incomplete + 1
         else
         write(iounit,331) mdl,isyr,ismn,isda,ishr,iyr,imn,ida,ihr, &
               ifhr+6,iacc,reg,k,igmdl,numthr,unit(lthrun)
         write(iounit,333) (thresh(l),o(l),f(l),h(l),t(l),l=1,numthr)
         endif
      enddo
 331  format(1x,a8,1x,i4.4,3i2.2,1x,i4.4,3i2.2,1x,i3.3,1x,i3.3, &
             1x,a3,i2.2,1x,i3.3,1x,i2,1x,a2,' THR OBS FCS HIT TOT')
 333  format(3(f6.2,4i5))

      return
      end

