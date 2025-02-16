!/@*
program sverif_eval
   use App
   use rmn_common
   use rmn_fst24
   use calc_stat_mod, only: calc_filename,calc_read, calc_t1, calc_r, calc_nt,calc_nmembers,calc_ens_unpak,CALC_ENSPAK_SIZE
   implicit none
   !@objective 
   !@description
   !   Calling Sequence:
   !      sverif_eval VARNAME LEVEL HOUR DATA_FILENAME CTRL_DIRNAME
   !   Controle File Format, every line has this format:
   !      VARNAME LEVEL HOUR NMEMBERS NI NJ EXAVG GSS MIN_T1 MAX_T1 MIN_NT1 MAX_NT1 MIN_NT5 MAX_NT5 MIN_R
   !      EAVG(NI,NJ)
   !      EVAR(NI,NJ)
   !*@/
#include <rmn/clib_interface.cdk>
#include <rmnlib_basics.hf>

   integer,parameter :: MIN_T1  = 1
   integer,parameter :: MAX_T1  = 2
   integer,parameter :: MIN_NT1 = 3
   integer,parameter :: MAX_NT1 = 4
   integer,parameter :: MIN_NT5 = 5
   integer,parameter :: MAX_NT5 = 6
   integer,parameter :: MIN_R   = 7
   integer,parameter :: MAX_R   = 8
   integer,parameter :: CI = 9
   integer,parameter :: NPARAMS = 9
   integer,parameter :: MAX_CI = 9
   integer,parameter :: LONG_STRING = 4096

   character(len=LONG_STRING) :: data_filename_S,ctrl_dirname_S
   character(len=4) :: varname_S
   integer :: istat,level,hour,nmembers,nci,ni,nj,i_ci
   real :: inflation
   real :: params(MAX_CI,NPARAMS),t1_stat,nt1_stat,nt5_stat,r_stat
   real,pointer :: data(:,:,:),data2d(:,:)
   real,pointer :: eavg(:,:),evar(:,:)
   real :: exavg,gss
   logical :: isok, success
   !----------------------------------------------------------------------

   istat = parse_args(data_filename_S,ctrl_dirname_S,varname_S,level,hour)
   if (.not.RMN_IS_OK(istat)) stop

   istat = read_ens_stats(ctrl_dirname_S,varname_S,level,hour,nmembers,nci,ni,nj,params,exavg,gss,eavg,evar,inflation)
   if (.not.RMN_IS_OK(istat)) stop

   calc_nmembers = nmembers
   success = calc_read(data,data_filename_S,varname_S,level,hour)
   if (.not. success) stop
   data2d => data(:,:,1)

   istat = calc_t1(data2d,exavg,gss,gss,t1_stat)
   write(app_msg,*) 'calc_t1=',t1_stat
   call app_log(APP_VERBATIM,app_msg)
   istat = calc_nt(0.01,data2d,eavg,evar,evar,nt1_stat)
   write(app_msg,*) 'calc_nt1=',nt1_stat
   call app_log(APP_VERBATIM,app_msg)
   istat = calc_nt(0.05,data2d,eavg,evar,evar,nt5_stat)
   write(app_msg,*) 'calc_nt5=',nt5_stat
   istat = calc_r(data2d,exavg,eavg,r_stat)
   write(app_msg,*) 'calc_r=',r_stat
   call app_log(APP_VERBATIM,app_msg)
   write(app_msg,*) 'inflation=',inflation
   call app_log(APP_VERBATIM,app_msg)

   do i_ci=1,nci
      isok = .true.
      write(app_msg,'(a,i4,a,i4,a,f4.2,a)') '(sverif_eval) '//trim(varname_S)//' [',level,'mb; ',hour,'h; CI=',real(params(i_ci,CI)),']'
      
      if (t1_stat <= params(i_ci,MAX_T1) .and. t1_stat >= params(i_ci,MIN_T1)) then
         call app_log(APP_VERBATIM,'PASS T1  '//trim(app_msg))
      else
         call app_log(APP_VERBATIM,'FAIL T1  '//trim(app_msg))
         isok = .false.
      endif

      if (nt1_stat <= params(i_ci,MAX_NT1)) then
         call app_log(APP_VERBATIM,'PASS NT1 '//trim(app_msg))
      else
         call app_log(APP_VERBATIM,'FAIL NT1 '//trim(app_msg))
         isok = .false.
      endif

      if (nt5_stat <= params(i_ci,MAX_NT5)) then
         call app_log(APP_VERBATIM,'PASS NT5 '//trim(app_msg))
      else
         call app_log(APP_VERBATIM,'FAIL NT5 '//trim(app_msg))
         isok = .false.
      endif

      if (r_stat <= params(i_ci,MAX_R)) then
         call app_log(APP_VERBATIM,'PASS R   '//trim(app_msg))
      else
         call app_log(APP_VERBATIM,'FAIL R   '//trim(app_msg))
         isok = .false.
      endif
      if (isok) then
         call app_log(APP_VERBATIM,'* PASS overall '//trim(app_msg))
      else
         call app_log(APP_VERBATIM,'* FAIL overall   '//trim(app_msg))
      endif
   enddo
   stop
   !----------------------------------------------------------------------

contains

   !/@*
   function parse_args(F_data_filename_S,F_crtl_dirname_S,F_varname_S,F_level,F_hour) result(F_istat)
      implicit none
      character(len=*),intent(out) :: F_data_filename_S
      character(len=*),intent(out) :: F_crtl_dirname_S
      character(len=*),intent(out) :: F_varname_S
      integer,intent(out) :: F_level,F_hour
      integer :: F_istat
      !*@/
      character(len=LONG_STRING) :: arg_S
      integer :: mylen,istat
      !----------------------------------------------------------------------
      F_istat = RMN_OK
      call get_command_argument(1,F_varname_S,mylen,istat)
      if (istat /= 0) F_istat = RMN_ERR
      call get_command_argument(2,arg_S,mylen,istat)
      if (istat /= 0) then
         F_istat = RMN_ERR
      else
         read(arg_S,*) F_level
      endif
      call get_command_argument(3,arg_S,mylen,istat)
      if (istat /= 0) then
         F_istat = RMN_ERR
      else
         read(arg_S,*) F_hour
      endif
      call get_command_argument(4,F_data_filename_S,mylen,istat)
      if (istat /= 0) F_istat = RMN_ERR
      call get_command_argument(5,F_crtl_dirname_S,mylen,istat)
      if (istat /= 0) F_istat = RMN_ERR

      if (.not.RMN_IS_OK(F_istat)) then
         call app_log(APP_ERROR,'Wrong args, Usage: sverif_eval VARNAME LEVEL HOUR DATA_FILENAME CRTL_DIRNAME')
         return
      endif
      write(app_msg,'(a,a,a,i4,a,i4,a,a,a,a)') '(sverif_eval) For: ',trim(F_varname_S),'; ',F_level,'; ',F_hour,'; ',trim(F_data_filename_S),'; ', trim(F_crtl_dirname_S)
      call app_log(APP_INFO,app_msg)
      !----------------------------------------------------------------------
      return
   end function parse_args

   !/@*
   function read_ens_stats(F_dirname_S,F_varname_S,F_level,F_hour,F_nmembers,F_nci,F_ni,F_nj,F_params,F_exavg,F_gss,F_eavg,F_evar,F_inflation) result(F_istat)
      implicit none
      character(len=*),intent(in) :: F_dirname_S,F_varname_S
      integer,intent(in) :: F_level,F_hour
      integer,intent(out) :: F_nmembers,F_nci,F_ni,F_nj
      real,intent(out) :: F_params(MAX_CI,NPARAMS),F_exavg,F_gss
      real,pointer :: F_eavg(:,:),F_evar(:,:)
      real, intent(out) :: F_inflation
      integer :: F_istat
      !*@/
      character(len=LONG_STRING) :: filename_S,line_S
      character(len=4) :: varname0_S, varname_S
      integer :: level, hour, istat, fileid, fd, auxid, ii,jj,ii1,jj1,idx,i_ci,datev,key,ni1,nj1,nk1
      logical :: isfound
      real :: v1,v2
      real, target :: pakdata(CALC_ENSPAK_SIZE)

      logical          :: success
      type(fst_file)   :: file
      type(fst_record) :: record

      !----------------------------------------------------------------------

      ! Open precomputed statistics file for reading
      F_istat = calc_filename(filename_S,'pre',F_varname_S,F_level,F_hour)
      filename_S = trim(F_dirname_S)//'/'//trim(filename_S)
      F_istat = clib_isfile(trim(filename_S))
      F_istat = min(clib_isreadok(trim(filename_S)),F_istat)
      if (.not.RMN_IS_OK(F_istat)) then
         call app_log(APP_ERROR,'read_ens_stats: Control File not found or not readable: '//trim(filename_S))
         return
      endif
      fileid = 0

      success = file%open(trim(filename_S),options='RND+OLD+R/O')
      if (.not. success) then
         call app_log(APP_ERROR,'read_ens_stats: Problem opening Control file: '//trim(filename_S))
         return
      endif

      ! Open auxiliary file for reading
      F_istat = calc_filename(filename_S,'aux',F_varname_S,F_level,F_hour)
      filename_S = trim(F_dirname_S)//'/'//trim(filename_S)
      F_istat = clib_isfile(trim(filename_S))
      F_istat = min(clib_isreadok(trim(filename_S)),F_istat)
      if (.not.RMN_IS_OK(F_istat)) then
         call app_log(APP_ERROR,'read_ens_stats: Control File not found or not readable: '//trim(filename_S))
         return
      endif
      auxid = 0
      F_istat = fnom(auxid,filename_S,'SEQ/FMT+R/O+OLD',0)
      if (.not.RMN_IS_OK(F_istat) .or. auxid <= 0) then
         call app_log(APP_ERROR,'read_ens_stats: Problem opening Control file: '//trim(filename_S))
         return
      endif

      ! Read in header and gridded data from precomputed statistics file     
      success = file%read(record,data=c_loc(pakdata),nomvar=F_varname_S,ip1=F_level,ip2=F_hour)
      F_istat = calc_ens_unpak(pakdata,varname_S,level,hour,F_ni,F_nj,F_nmembers,F_exavg,F_gss)

      allocate(F_eavg(F_ni,F_nj),F_evar(F_ni,F_nj))

      success = file%read(record,data=c_loc(F_eavg),nomvar='eavg')
      success = file%read(record,data=c_loc(F_evar),nomvar='evar')

      ! Read in basic text information from auxiliary file
      read(auxid,'(a)') line_S
      read(line_S,*) F_nci
      if (F_nci > MAX_CI) then
         F_istat = RMN_ERR
         write(app_msg,*) 'read_ens_stats: Too many CI ',F_nci
         call app_log(APP_ERROR,app_msg)
         return
      endif
      read(line_S,*) F_nci,F_params(1:F_nci,CI)
      do i_ci=1,F_nci
         read(auxid,*) idx,v1,v2
         idx = min(max(1,idx),F_nci)
         F_params(idx,MIN_T1) = v1; F_params(idx,MAX_T1) = v2
      enddo
      do i_ci=1,F_nci
         read(auxid,*) idx,v1,v2
         idx = min(max(1,idx),F_nci)
         F_params(idx,MIN_NT1) = v1; F_params(idx,MAX_NT1) = v2
      enddo
      do i_ci=1,F_nci
         read(auxid,*) idx,v1,v2
         idx = min(max(1,idx),F_nci)
         F_params(idx,MIN_NT5) = v1; F_params(idx,MAX_NT5) = v2
      enddo
      do i_ci=1,F_nci
         read(auxid,*) idx,v1,v2
         idx = min(max(1,idx),F_nci)
         F_params(idx,MIN_R) = v1; F_params(idx,MAX_R) = v2
      enddo
      read(auxid,*) F_inflation
      
      ! Close files and return
      success = file%close()
      istat = fclos(auxid)
      !----------------------------------------------------------------------
      return
   end function read_ens_stats

end program sverif_eval
