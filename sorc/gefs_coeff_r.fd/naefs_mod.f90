module naefs_mod

!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!                .      .    .                                       .
! MODULE:    naefs_mod
!   PRGMMR: Bo Cui          ORG: np/wx20    DATE: 2013-03-04
!
! ABSTRACT: This Fortran Module contains the bias corrected variables for NAEFS
!
!
! PROGRAM HISTORY LOG:
!
! 2013-10-01   Bo Cui 
! 2014-11-01   Bo Cui ( Add new variable Total Cloud Cover )
!
! USAGE:    use naefs_mod
!
! ATTRIBUTES:
!   LANGUAGE: Fortran 90
!   MACHINE:  IBM SP
!
!$$$

use grib_mod
use params

implicit none
integer nvar

parameter (nvar=53)

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer     ipd1(nvar),ipd2(nvar),ipd10(nvar),ipd11(nvar),ipd12(nvar),ipdn(nvar)
integer     ipdnm(nvar),ipdnr(nvar),ipdna(nvar)
integer     ipd11_cmc(nvar),ipd12_cmc(nvar)

! 01  02  03  04  05  06  07  08  09  10  11  12  13  14  15  16  17  18  19  20  
! 21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38  39  40
!  Z   Z   Z   Z   Z   Z   Z   Z   Z   Z   T   T   T   T   T   T   T   T   T   T
!  U   U   U   U   U   U   U   U   U   U   V   V   V   V   V   V   V   V   V   V
!
! 41   42  43  44   45   46   47   48         49             50         51   52    53
! pres slp t2m u10m v10m tmax tmin ULWRF(OLR) ULWRF(Surface) VVEL(850w) rh2m dpt2m tcdc
!
! -----------------------------------------------------------------------------------------

! ipdn: product definition template number grib2 - code table 4.0
! ipd1:  parameter category (3 means mass field)) 
! ipd2:  parameter number 
! ipd10: type of first fixed surface
! ipd11: scale factor of first fixed surface                                                    
! ipd12: Scaled value of first fixed surface

! ipdnm: ensemble average forecast, product template 4.2 or 4.12

data ipdnm/  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2, &
             2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2, & 
             2,  2,  2,  2,  2, 12, 12, 12, 12,  2,  2,  2, 12/

! ipdn: ensemble control forecast, product template 4.1 or 4.11

data ipdn /  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, &
             1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, & 
             1,  1,  1,  1,  1, 11, 11, 11, 11,  1,  1,  1, 11/

! ipdnr: cfs cdas reanalysis, product template 4.0 or 4.8

data ipdnr/  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, &
             0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, & 
             0,  0,  0,  0,  0,  8,  8,  8,  8,  0,  0,  0,  0/

! fnmoc nogaps analysis

data ipdna/  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, &
             0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, & 
             0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0/

data ipd1 /  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, &
             2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2, & 
             3,  3,  0,  2,  2,  0,  0,  5,  5,  2,  1,  0,  6 /

data ipd2 /  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, &
             2,  2,  2,  2,  2,  2,  2,  2,  2,  2 , 3,  3,  3,  3,  3,  3,  3,  3,  3,  3, &
             1,  0,  0,  2,  3,  4,  5,193,193,  8,  1,  6,  1/

data ipd10/100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100, &      
           100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100, &
           101,  1,103,103,103,103,103,  8,  1,100,103,103, 10/

data ipd11/  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, &
             0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, &
             0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0/

data ipd12/100000,92500, 85000, 70000, 50000, 25000, 20000, 10000, 5000,   1000,  &
           100000,92500, 85000, 70000, 50000, 25000, 20000, 10000, 5000,   1000,  &
           100000,92500, 85000, 70000, 50000, 25000, 20000, 10000, 5000,   1000,  &
           100000,92500, 85000, 70000, 50000, 25000, 20000, 10000, 5000,   1000,  &
             0,  0,   2, 10, 10,  2, 2,  0,  0,85000,2,  2,     0/

! for CMC ensemble forecast

data ipd11_cmc/ -5, -2, -3, -4, -4, -3, -4, -4, -3, -3,  &
                -5, -2, -3, -4, -4, -3, -4, -4, -3, -3,  &
                -5, -2, -3, -4, -4, -3, -4, -4, -3, -3,  &
                -5, -2, -3, -4, -4, -3, -4, -4, -3, -3,  &
                 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0/

data ipd12_cmc/  1,925, 85,  7,  5, 25,  2,  1,  5,  1,  &
                 1,925, 85,  7,  5, 25,  2,  1,  5,  1,  &
                 1,925, 85,  7,  5, 25,  2,  1,  5,  1,  &
                 1,925, 85,  7,  5, 25,  2,  1,  5,  1,  &
                 0,  0,   2, 10, 10,  2, 2,  0,  0,85000,2,  2,   0/

end module

