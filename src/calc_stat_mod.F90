module calc_stat_mod
   use App
   use rmn_common
   use rmn_fst24
   use base_stats_mod, only: tTest
   implicit none
   private
   public :: calc_filename,calc_read,calc_t1, calc_r, calc_nt,calc_ens_pak,calc_ens_unpak

#include <rmn/msg.h>
#include <rmn/clib_interface.cdk>
#include <rmnlib_basics.hf>

   integer,parameter,public :: CALC_ENSPAK_SIZE = 8
   integer,save,public :: calc_nmembers = 0

contains

   !/@*
      function calc_filename(F_filename_S,F_class_S,F_varname_S,F_level,F_hour) result(F_istat)
      character(len=*),intent(out) :: F_filename_S
      character(len=*),intent(in) :: F_class_S
      character(len=*),intent(in) :: F_varname_S
      integer,intent(in) :: F_level,F_hour
      integer :: F_istat
      !*@/
      character(len=4) :: varname_S
      character(len=128) :: prefix_S,class_S
      integer :: istat
      !----------------------------------------------------------------------
      F_istat = RMN_ERR
      class_S = F_class_S
      istat = clib_tolower(class_S)
      select case (class_S)
      case ('pre')
         prefix_S = 'sverif-precalc_'
      case ('tstat')
         prefix_S = 'sverif-tstats_'
      case ('aux')
         prefix_S = 'sverif-aux_'
      case DEFAULT
         call msg(MSG_ERROR,'(calc_stat_mod) Unknown class '//trim(F_class_S)//' ... use "pre", "tstat" or "aux"')
         return
      end select
      varname_S = F_varname_S
      istat = clib_tolower(varname_S)
      write(F_filename_S,'(a,I4.4,a,I4.4,a)') trim(prefix_S)//trim(varname_S),F_level,'_',F_hour,'h.dat'
      F_istat = RMN_OK
      !----------------------------------------------------------------------
   end function calc_filename


   !/@*
   function calc_read(F_data,F_filename_S,F_varname_S,F_level,F_hour) result(success)
      implicit none

      real, pointer :: F_data(:,:,:)
      character(len=*), intent(in) :: F_filename_S,F_varname_S
      integer, intent(in) :: F_level,F_hour

      logical          :: success
      type(fst_file)   :: file
      type(fst_record) :: record
      type(fst_query)  :: query

      success = file%open(trim(F_filename_S),'RND+OLD+R/O')
      if (.not. success) then
         call msg(MSG_ERROR,'(calc_stat_mod) Problem opening member file '//trim(F_filename_S))
         return
      endif
      
      record%data=c_loc(F_data)
      record%nomvar=F_varname_S
      record%ip1=F_level
      record%ip2=F_hour
      
      query = file%new_query() 
      success = query%read_next(record)
      if (.not. success) then
         call msg(MSG_ERROR,'(calc_stat_mod) Problem finding member file field: '//trim(F_varname_S)//' in '//trim(F_filename_S))
         return
      endif

      call query%free()

      success = file%close()
      call msg(MSG_INFO,'(calc_stat_mod) Reading member file field: '//trim(F_varname_S)//' in '//trim(F_filename_S))

      return
   end function calc_read


   !/@*
   function calc_ens_pak(F_pakdata,F_varname_S,F_level,F_hour,F_ni,F_nj,F_nmembers,F_exavg,F_gss) result(F_istat)
      implicit none
      real, intent(out) :: F_pakdata(CALC_ENSPAK_SIZE)
      character(len=*), intent(in) :: F_varname_S
      integer, intent(in) :: F_level,F_hour,F_ni,F_nj,F_nmembers
      real, intent(in) :: F_exavg,F_gss
      integer :: F_istat
      !*@/
      character(len=4) :: varanme_S
      integer :: ivarname
      !----------------------------------------------------------------------
      F_istat = RMN_ERR
      varanme_S = F_varname_S
      ivarname = transfer(varanme_S,ivarname)
      F_pakdata(1) = F_ni
      F_pakdata(2) = F_nj
      F_pakdata(3) = ivarname
      F_pakdata(4) = F_level
      F_pakdata(5) = F_hour
      F_pakdata(6) = F_nmembers
      F_pakdata(7) = F_exavg
      F_pakdata(8) = F_gss
      F_istat = RMN_OK
     !----------------------------------------------------------------------
      return
   end function calc_ens_pak


   !/@*
   function calc_ens_unpak(F_pakdata,F_varname_S,F_level,F_hour,F_ni,F_nj,F_nmembers,F_exavg,F_gss) result(F_istat)
      implicit none
      real, intent(in) :: F_pakdata(CALC_ENSPAK_SIZE)
      character(len=*), intent(out) :: F_varname_S
      integer, intent(out) :: F_level,F_hour,F_ni,F_nj,F_nmembers
      real, intent(out) :: F_exavg,F_gss
      integer :: F_istat
      !*@/
      character(len=4) :: varanme_S
      integer :: ivarname
      !----------------------------------------------------------------------
      F_istat = RMN_ERR
      F_ni = nint(F_pakdata(1))
      F_nj = nint(F_pakdata(2))
      ivarname = nint(F_pakdata(3))
      varanme_S = transfer(ivarname,varanme_S)
      F_varname_S = varanme_S
      F_level = nint(F_pakdata(4))
      F_hour = nint(F_pakdata(5))
      F_nmembers = nint(F_pakdata(6))
      F_exavg = F_pakdata(7)
      F_gss = F_pakdata(8)
      F_istat = RMN_OK
      !----------------------------------------------------------------------
      return
   end function calc_ens_unpak


   !/@*
   function calc_t1(F_data,F_exavg,F_gss0,F_gss,F_tstat) result(F_istat)
      implicit none
      real, dimension(:,:), intent(in) :: F_data
      real, intent(in) :: F_exavg,F_gss0,F_gss
      real, intent(out) :: F_tstat
      integer :: F_istat
      !*@/
      integer :: ii,jj
      real :: rni,rnj,rnt
      !----------------------------------------------------------------------
      if (calc_nmembers < 3) then
         F_istat = RMN_ERR
         call msg(MSG_ERROR,'(calc_stat_mod) Numbers of members should be >= 3')
         return
      endif
      F_istat = RMN_OK
      F_tstat = (F_exavg - sum(dble(F_data))/size(F_data))/sqrt(F_gss+F_gss0)
      !----------------------------------------------------------------------
   end function calc_t1

   !/@*
   function calc_r(F_data,F_exavg,F_eavg,F_tstat) result(F_istat)
      implicit none
      real, dimension(:,:), intent(in) :: F_data
      real, intent(in) :: F_exavg
      real, dimension(:,:), intent(in) :: F_eavg
      real, intent(out) :: F_tstat
      integer :: F_istat
      !*@/
      integer :: ii,jj
      real :: avg
      real(RDOUBLE) :: exss_8,excor_8
      !----------------------------------------------------------------------
      if (calc_nmembers < 3) then
         F_istat = RMN_ERR
         call msg(MSG_ERROR,'(calc_stat_mod) Numbers of members should be >= 3')
         return
      endif
      F_istat = RMN_OK
      avg = (sum(dble(F_data))/size(F_data))
      excor_8 = 0.d0
      exss_8 = 0.d0
      do jj=1,size(F_data,dim=2)
         do ii=1,size(F_data,dim=1)
            excor_8 = excor_8 + &
                 dble(F_eavg(ii,jj)-F_exavg)*dble(F_data(ii,jj)-avg)
            exss_8 = exss_8 + &
                 sqrt(dble(F_eavg(ii,jj)-F_exavg)**2 * dble(F_data(ii,jj)-avg)**2)
         enddo
      enddo
      F_tstat = real(log(1. - min(excor_8/exss_8,1.-epsilon(exss_8))))
      !----------------------------------------------------------------------
   end function calc_r

   !/@*
   function calc_nt(F_crit,F_data,F_eavg,F_evar0,F_evar,F_tstat) result(F_istat)
      implicit none
      real, intent(in) :: F_crit
      real, dimension(:,:), intent(in) :: F_data
      real, dimension(:,:), intent(in) :: F_eavg,F_evar0,F_evar
      real, intent(out) :: F_tstat
      integer :: F_istat
      !*@/
      integer :: ii,jj,ni,nj,cnt
      real :: norm
      real, dimension(size(F_data,dim=1),size(F_data,dim=2)) :: tfld
      real, dimension(:,:), pointer :: pfld=>null()
      !----------------------------------------------------------------------
      if (calc_nmembers < 3) then
         F_istat = RMN_ERR
         call msg(MSG_ERROR,'(calc_stat_mod) Numbers of members should be >= 3')
         return
      endif
      F_istat = RMN_OK
      ni = size(F_data,dim=1)
      nj = size(F_data,dim=2)
      norm = sqrt(real(calc_nmembers-1))
      do jj=1,nj
         do ii=1,ni
            tfld(ii,jj) = norm * (F_eavg(ii,jj) - F_data(ii,jj)) / sqrt(max(0.5*(F_evar(ii,jj)+F_evar0(ii,jj)),epsilon(F_evar)))
         enddo
      enddo
      pfld => tTest(tfld,2*(calc_nmembers-1))
      cnt = 0
      do jj=1,nj
         do ii=1,ni
            if (pfld(ii,jj) < F_crit) cnt = cnt+1
         enddo
      enddo
      deallocate(pfld)
      F_tstat = real(cnt)/real(ni*nj)
      !----------------------------------------------------------------------
   end function calc_nt

end module calc_stat_mod
