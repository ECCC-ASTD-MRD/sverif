module base_stats_mod

  implicit none

  private
  public :: tTest

contains

  function tTest(tValue,n) result(pValue)
    ! Compute the probability of independence for a given t-value and sample size (n)

    implicit none

    !  Input variables
    real, dimension(:,:), intent(in) :: tValue                    !mean of the sample
    integer, intent(in) :: n                                      !sample size

    !  Output variables
    real, dimension(:,:), pointer :: pValue                       !test significance

    !  End_Header#
    !  Internal variables
    integer :: i,j,err
    real :: degf

    !  Allocate space for return value
    allocate(pValue(size(tValue,dim=1),size(tValue,dim=2)),stat=err)
    if (err /= 0) then
       write(0,*) 'Error allocating pValue'
       pValue=>null()
       return
    endif

    !  Compute the total variance and degrees of freedom
    degf = real(n-1)

    !  Compute probablity of independence
    do j=1,size(tValue,dim=2)
       do i=1,size(tValue,dim=1)
          pValue(i,j) = betai(.5*degf,0.5,degf/max((degf+tValue(i,j)**2),epsilon(tValue)))
       enddo
    enddo

    !  End of subprogram
    return
  end function tTest

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  function betai(a,b,x) result(value)

    !  This function computes the incomplete beta function for (a,b).
    !  This code is taken directly from Numerical Recipes in FORTRAN77
    !  (Press, Tuekolsky, Vetterling and Flannery: Second Edition,
    !  Cambridge University Press, 1996 - ISBN 0 521 43064 X) Section
    !  6.4, page 220.

    !  Input variables
    real, intent(in) :: a,b,x

    !  Output variables
    real :: value

    !  Internal variables
    real :: xError,bt,myX

    !  Warn on invalid x-entry
    myX = x
    if (x<0. .or. x>1.) then
       xError = x
       myX=min(max(x,0.),1.)
       write(6,*) 'WARNING: Invalid x-entry ',xError                              &
            ,'for incomplete beta function ... clipped to ',myX
    endif

    !  Compute front-end factors
    if (abs(myX)<epsilon(myX) .or. abs(myX-1.)<epsilon(myX)) then
       bt = 0.
    else
       bt = exp(gammln(a+b)-gammln(a)-gammln(b)+a*log(myX)+b*log(1.-myX))
    endif

    !  Apply continued fraction
    if (x < (a+1.)/(a+b+2.)) then
       value = bt*betacf(a,b,myX)/a
    else
       value = 1.-bt*betacf(b,a,1.-myX)/b
    endif

    !  End of subprogram
    return
  end function betai

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  function gammln(x) result(gamma)

    !  This function computes the gamma function for x.
    !  This code is taken directly from Numerical Recipes in FORTRAN77
    !  (Press, Tuekolsky, Vetterling and Flannery: Second Edition,
    !  Cambridge University Press, 1996 - ISBN 0 521 43064 X) Section
    !  6.1, page 207.

    !  Input variables
    real, intent(in) :: x

    !  Output variables
    real :: gamma

    !  Internal variables
    integer :: j
    real(kind=8) :: ser,tmp,x1,y
    real(kind=8), parameter :: STP=2.5066282746310005d0
    real(kind=8), dimension(6), parameter :: COF = &
         (/76.18009172947146d0,-86.50532032941677d0,24.01409824083091d0,         &
         -1.231739572450155d0,.1208650973866179d-2,-.5395239384953d-5/)

    !  Compute gamma function
    x1 = x
    y = x1
    tmp = x1+5.5d0
    tmp = (x1+0.5d0)*log(tmp)-tmp
    ser=1.000000000190015d0
    do j=1,size(COF)
       y = y+1.d0
       ser = ser + COF(j)/y
    enddo
    gamma = tmp+log(STP*ser/x1)

    !  End of subprogram
    return
  end function gammln

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  function betacf(a,b,x) result(cfrac)

    !  This function computes the continued fraction for a, b and x based
    !  on Lenz's method.
    !  This code is taken directly from Numerical Recipes in FORTRAN77
    !  (Press, Tuekolsky, Vetterling and Flannery: Second Edition,
    !  Cambridge University Press, 1996 - ISBN 0 521 43064 X) Section
    !  6.4, page 221.

    !  Input variables
    real, intent(in) :: a,b,x

    !  Output variables
    real :: cfrac

    !  Internal variables
    integer :: m
    integer, parameter :: maxIt=100
    real :: aa,c,d,del,h,qab,qam,qap,m2,rm
    real, parameter :: crit=3.e-7, fpmin=1.e-30
    logical :: converged

    !  Set coefficients and factors
    qab = a+b
    qap = a+1.
    qam = a-1.
    c = 1.
    d = 1.-qab*x/qap
    if (abs(d)<fpmin) d=fpmin
    d=1./d
    h=d

    !  Iterate for calculation
    converged = .false.
    m = 1
    do while (.not.converged .and. m <= maxIt)
       rm = real(m)
       m2 = 2*rm
       aa = rm*(b-rm)*x/((qam+m2)*(a+m2))
       d = 1.+aa*d
       if (abs(d)<fpmin) d=fpmin
       c = 1.+aa/c
       if (abs(c)<fpmin) c=fpmin
       d = 1./d
       h = h*d*c
       aa = -(a+rm)*(qab+rm)*x/((a+m2)*(qap+m2))
       d = 1.+aa*d
       if (abs(d)<fpmin) d=fpmin
       c = 1.+aa/c
       if (abs(c)<fpmin) c=fpmin
       d = 1./d
       del=d*c
       h = h*del
       if (abs(del-1.) < crit) converged=.true.
       m = m+1
    enddo

    !  Warn of non-convergence
    if (m > maxIt .and. .not.converged) &
         write(6,*) 'WARNING: Convergence failure in func_tTest sub betacf'

    !  Assign value and return
    cfrac = h
    return
  end function betacf

end module base_stats_mod
