      subroutine probability(fst,inum,fvalue10,fvalue90,fvalue50)

c  subroutine program    probability
c  Prgmmr: Yuejian Zhu           Org: np23          Date: 2004-09-30
c          Bo Cui                mod: wx20          Date: 2007-07-18
c
c This is subroutine to get 10%, 50% and 90% probability forecast               
c
c   subroutine
c              sort  ---> sorts the array x into ascending order 
c              samlmr---> sample L_moments of a data array           
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

c     implicit none
      double precision fst(inum),fmon(3),opara(3),prob,amt
      double precision fvalue,fvalue10,fvalue50,fvalue90,mode
      double precision quagev
      integer          inum,ii,idiff
      double precision same                                   

ccc
ccc       Using L-moment ratios and GEV method
ccc
C--------+---------+---------+---------+---------+---------+---------+---------+
c     print *, 'Calculates the L-moment ratios, by prob. weighted'

      call sort(fst,inum)

!     if((fst(inum)-fst(1)).le.0.1) then
      if((fst(inum)-fst(1)).le.0.05) then
!       print *, 'Almost all data are equal'
        fvalue10=fst(1)
        fvalue90=fst(inum)
        mode=0.5*(fst(inum)+fst(1))
        return
      endif
 
      same=fst(1)
      idiff=1
      do ii=1,inum
        if(fst(ii).ne.same) then
          same=fst(ii)
          idiff=1+idiff
        endif
       enddo
!     print *, 'there are data type=', idiff

      if(idiff.le.2) then
!       print *, 'Almost all data are identical'
        fvalue10=fst(1)
        fvalue90=fst(inum)
        mode=0.5*(fst(inum)+fst(1))
        return
      endif

      opara = 0.0D0

ccc for unbiased estimation, A=B=ZERO

!     print *, "fst=",fst  

      call samlmr(fst,inum,fmon,3,-0.0D0,0.0D0)
c     print *, "fmon=",fmon
      call pelgev(fmon,opara)
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
      end

