module anomaly_mod

!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!                .      .    .                                       .
! MODULE:    anomaly_mod
!   PRGMMR: Bo Cui          ORG: W/NP11    DATE: 2013-03-04
!
! ABSTRACT: This fortran module contains variables for GEFS/NAEFS anomaly forecasts
!
! PROGRAM HISTORY LOG:
!
! 2013-03-04   Bo Cui 
! 2017-04-01   Bo Cui ( Add new variable 10m wind speed )
!
! USAGE:    use anomaly_mod
!
! ATTRIBUTES:
!   LANGUAGE: Fortran 90
!   MACHINE:  IBM SP
!
!$$$

use grib_mod
use params

implicit none
integer iv

parameter (iv=20)

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer ipd1(iv),ipd2(iv),ipd10(iv),ipd11(iv),ipd12(iv)
integer ipdn(iv),ipdnc(iv),ipdnr(iv),ipdnm(iv)
integer ipd11_cmc(iv),ipd12_cmc(iv)

! ---------------------------
! Z   Z   Z   Z
! U   U   U 
! V   V   V
! T   T   T
! tmax tmin slp u10m v10m t2m wspd10m
! ---------------------------

! ipdn:  product definition template number grib2 - code table 4.0
! ipdnc: cfs climate product template 4.8
! ipd1:  parameter category (3 means mass field)) 
! ipd2:  parameter number 
! ipd10: type of first fixed surface
! ipd11: scale factor of first fixed surface                                                    
! ipd12: Scaled value of first fixed surface

! ipdn: ensemble forecast, product template 4.1 or 4.11

data ipdn /  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 11, 11,  1,  1,  1,  1,  1/

! ipdnm: ensemble derived forecast, product template 4.2 or 4.12

data ipdnm /  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2, 12, 12,  2,  2,  2,  2, 2/

! ipdnc: climate mean or standard deviation template 4.8

data ipdnc/  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8/

! ipdnr: cfs cdas reanalysis, product template 4.0 or 4.8

data ipdnr/  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  0,  0,  0,  0,  0/

data ipd1 /  3,  3,  3,  3,  2,  2,  2,  2,  2,  2,  0,  0,  0,  0,  0,  3,  2,  2,  0,  2/

data ipd2 /  5,  5,  5,  5,  2,  2,  2,  3,  3,  3,  0,  0,  0,  4,  5,  1,  2,  3,  0,  1/

data ipd10/100,100,100,100,100,100,100,100,100,100,100,100,100,103,103,101,103,103,103,103/

data ipd11/  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0/

data ipd12/100000, 70000, 50000, 25000, 85000, 50000, 25000,  &
            85000, 50000, 25000, 85000, 50000, 25000,         &
            2,   2,  0, 10, 10,  2,   10/

! for CMC ensemble forecast

data ipd11_cmc/ -5, -4, -4, -3, -3, -4, -3,  &
                -3, -4, -3, -3, -4, -3,      &
                 0,  0,  0,  0,  0,  0,  0/

data ipd12_cmc/  1,  7,  5, 25, 85,  5, 25,  &
                85,  5, 25, 85,  5, 25,      &
                 2,  2,  0, 10, 10,  2, 10/

end module
