      subroutine probability(fst,inum,opara,pdfval)

c  subroutine program    probability
c  Prgmmr: Yuejian Zhu           Org: np23          Date: 2004-09-30
c          Bo Cui                mod: wx20          Date: 2007-07-18
c
c This is subroutine to get 10%, 50% and 90% probability forecast               
c
c   subroutine
c              sort  ---> sorts the array x into ascending order 
c              samlmr---> sample L_moments of a dada array           
c              pelgam---> parameter estimation via L-moments for the gamma distribution
c              quagam---> quantile function of the gamma distribution                     
c
c   output 
c         fmon(4)    -- L-moments and L-moment ratios
c         prob(9)    -- every 10 precentage of probability
c
c   Fortran 77 on IBMSP
c
C--------+---------+---------+---------+---------+----------+---------+--

c     implicit none
      double precision fst(inum),fmon(2),opara(2),prob,amt
      double precision fvalue,pdfval
      double precision QUAGAM
      integer          inum

ccc
ccc       Using L-moment ratios and GAM method
ccc
C--------+---------+---------+---------+---------+---------+---------+---------+
c     print *, 'Calculates the L-moment ratios, by prob. weighted'

      call SORT(fst,inum)

      if( (fst(inum)-fst(1)).le.0.2.or.fst(inum-1).lt.0.2) then
c       print *, 'Almost all data are equal'
        opara=-9999.99
        pdfval=0.5*(fst(inum)+fst(1))
        return
       
      endif

      opara = 0.0D0

ccc for unbiased estimation, A=B=ZERO

      call SAMLMR(fst,inum,fmon,2,-0.0D0,0.0D0)
     
!      print *, "fmon=",fmon
      if (fmon(1).le.fmon(2).or.fmon(2).le.0.0) then
        opara=-9999.99
        pdfval=-9999.99    
        return
      else  
        call PELGAM(fmon,opara)
!        print *, "opara=",opara
        pdfval=QUAGAM(0.5D0,opara)
!      print *, "fst=",fst(1:20),inum,'hh'
!        print *, 'pdfval= ',pdfval
      endif

      return
      end

