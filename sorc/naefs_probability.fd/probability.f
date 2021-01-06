      subroutine probability(fst,inum,fvalue10,fvalue90,fvalue50)

c  subroutine program    probability
c  Prgmmr: Yuejian Zhu           Org: np23          Date: 2004-09-30
c          Bo Cui                mod: wx20          Date: 2007-07-18
c
c This is subroutine to get 10%, 50% and 90% probability forecast               
c
c   subroutine
c              sort  ---> sorts the array x into ascending order 
c              samlmr---> sample L_moments of a dada array           
c              pelgev---> parameter estimation via L-moments for the genaralized extreme-value distribution
c              quagev---> quantile function of the generalized extreme-value diftribution                     
c
c   output 
c         favalue10    -- 10% probabilaity forecast
c         favalue90    -- 90% probabilaity forecast
c         favalue50    -- 50% probabilaity forecast
c         mode         -- mode forecast
c
c   Fortran 77 on IBMSP
c
C--------+---------+---------+---------+---------+----------+---------+--

      implicit none
      double precision fst(inum),fmon(3),opara(3),prob,amt
      double precision fvalue,fvalue10,fvalue50,fvalue90,mode,maxdif
      double precision diff(inum-1)
      double precision quagev
      integer          inum,numzero

ccc
ccc       Using L-moment ratios and GEV method
ccc
C--------+---------+---------+---------+---------+---------+---------+---------+
c     print *, 'Calculates the L-moment ratios, by prob. weighted'

      call sort(fst,inum)

      opara = 0.0D0

ccc for unbiased estimation, A=B=ZERO

      call samlmr(fst,inum,fmon,3,-0.0D0,0.0D0,*10)
c     print *, "fmon=",fmon
      call pelgev(fmon,opara,*10)
c     print *, "opara=",opara

      prob=0.1
      fvalue10=quagev(prob,opara)
c     print *, "10% value is ",fvalue10

      prob=0.5
      fvalue50=quagev(prob,opara)
c     print *, "50% value is ",fvalue50

c     mode=3*fvalue50-2*fmon(1)
c     print *, "mode is ",mode  

      prob=0.9
      fvalue90=quagev(prob,opara)
c     print *, "90% value is ",fvalue90

      return

  10  print *, '  '
      print *, "Recalculate Probabilistic Forecast"
c     write (*,'(10f8.2)') (fst(ii),ii=1,inum)

      fvalue10=0.5*(fst(1)+fst(2))
      fvalue90=0.5*(fst(inum)+fst(inum-1))
      if (fvalue90.eq.fst(inum)) then
       fvalue50=0.2*fvalue10+0.8*fvalue90
      else
       fvalue50=0.8*fvalue10+0.2*fvalue90
      endif

      print *, '  '
      print *, "10%,50% and 90% values are"
      write (*,'(3f8.2)') fvalue10, fvalue50,fvalue90
      print *, '  '

      return
      end

