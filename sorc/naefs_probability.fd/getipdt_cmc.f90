subroutine getipdt_cmc(ipd11,ipd12,ipd11_cmc,ipd12_cmc)  
!
!     get grib2 ipdt message for cmc
!
!     parameters

!         ipdt : grib2 product definitation template

!     parameters
!
!        input
!                  ipd11 ---> scale factor of first fixed surface
!                  ipd12 ---> Scaled value of first fixed surface
!
!        output
!                  ipd11_cmc ---> CMC scale factor of first fixed surface
!                  ipd12_cmc ---> CMC Scaled value of first fixed surface

implicit none

integer     ipd11,ipd12,ipd11_cmc,ipd12_cmc 

! for 10 mb

if(ipd12.eq.1000.and.ipd11.eq.0) then
  ipd11_cmc=-3           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 50 mb

elseif(ipd12.eq.5000.and.ipd11.eq.0) then
  ipd11_cmc=-3           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 100 mb

elseif(ipd12.eq.10000.and.ipd11.eq.0) then
  ipd11_cmc=-4           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 200 mb

elseif(ipd12.eq.20000.and.ipd11.eq.0) then
  ipd11_cmc=-4           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 250 mb

elseif(ipd12.eq.25000.and.ipd11.eq.0) then
  ipd11_cmc=-3           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 500 mb

elseif(ipd12.eq.50000.and.ipd11.eq.0) then
  ipd11_cmc=-4           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 700 mb

elseif(ipd12.eq.70000.and.ipd11.eq.0) then
  ipd11_cmc=-4           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 850 mb

elseif(ipd12.eq.85000.and.ipd11.eq.0) then
  ipd11_cmc=-3           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 925 mb

elseif(ipd12.eq.92500.and.ipd11.eq.0) then
  ipd11_cmc=-2           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

! for 1000 mb

elseif(ipd12.eq.100000.and.ipd11.eq.0) then
  ipd11_cmc=-5           
  ipd12_cmc=int(ipd12*(10.**ipd11_cmc))

else

  ipd11_cmc=ipd11        
  ipd12_cmc=ipd12                                  

endif

return
end

