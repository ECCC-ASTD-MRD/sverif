!/@*
program sverif_fname
   use calc_stat_mod, only: calc_filename
   implicit none
   !@objective 
   !@description
   !   Calling Sequence:
   !      sverif_fname VARNAME LEVEL HOUR
   !*@/
#include <arch_specific.hf>
#include <rmnlib_basics.hf>
   character(len=4) :: varname_S
   character(len=128) :: arg_S,filename_S,class_S,prefix_S
   integer :: mylen,istat,istat2,level,hour
   !----------------------------------------------------------------------
   istat2 = RMN_OK
   call get_command_argument(1,class_S,mylen,istat)
   if (istat /= 0) istat2 = RMN_ERR
   call get_command_argument(2,varname_S,mylen,istat)
   if (istat /= 0) istat2 = RMN_ERR
   call get_command_argument(3,arg_S,mylen,istat)
   if (istat /= 0) then
      istat2 = RMN_ERR
   else
      read(arg_S,*) level
   endif
   call get_command_argument(4,arg_S,mylen,istat)
   if (istat /= 0) then
      istat2 = RMN_ERR
   else
      read(arg_S,*) hour
   endif
   if (.not.RMN_IS_OK(istat2)) then
      write(RMN_STDERR,'(/a/)') '(sverif_fname) ERROR: Wrong args, Usage: sverif_fname CLASS(pre/tstat/aux) VARNAME LEVEL HOUR'
      stop
   endif
   istat = calc_filename(filename_S,class_S,varname_S,level,hour)
   if (.not.RMN_IS_OK(istat)) then
      write(RMN_STDERR,*) '(sverif_fname) ERROR: Cannot construct file name'
      stop
   endif
   write(RMN_STDOUT,'(a)') trim(filename_S)
   !----------------------------------------------------------------------
end program sverif_fname
