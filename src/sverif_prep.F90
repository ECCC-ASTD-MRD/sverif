!/@*
program sverif_prep
   use App
   use calc_stat_mod, only: calc_filename,calc_read, calc_t1, calc_r, calc_nt,calc_nmembers,CALC_ENSPAK_SIZE,calc_ens_pak
   use rng_mod, only: rng_t,rng_seed
   implicit none
   !@objective 
   !@description
   !  Calling Sequence:
   !     sverif_prep FIELD_NAME LEVEL HOUR CONTROLE_FILE_NAME OUT_DIRNAME
   !  Control File format
   !     NENTRIES NMEMBERS
   !     MEMBER1_FILE_NAME
   !     MEMBER2_FILE_NAME
   !     ...
   !     ENTRY1_MEMBER_NB LIST_OF_CONTROL_MEMBERS_NB
   !     ENTRY2_MEMBER_NB LIST_OF_CONTROL_MEMBERS_NB
   !     ...
   !  Ouput
   !     3 numbers per line (one per test result)
   !     One line per entry
   !     .FtoR_GZ500_120h.dat
   !*@/

#include <rmn/clib_interface.cdk>
#include <rmnlib_basics.hf>

   integer,parameter :: MAX_MEMBERS = 32, LONG_CHAR = 1024,  &
        NSTAT = 4, T1 = 1, NT1 = 2, NT5 = 3, R = 4

   type :: memberdata_T
      character(len=LONG_CHAR) :: f_S
      real,pointer :: d(:,:,:)
   end type memberdata_T

   character(len=4) :: varname_S
   character(len=LONG_CHAR) :: ctrl_filename_S,out_dirname_S
   integer :: istat,level,hour,nentries,nmembers,nn,ni,nj,niPrev,njPrev
   integer,allocatable :: entries(:,:)
   real :: scale
   real :: exavg0,gss0
   real, dimension(:,:,:), allocatable :: flds0
   real,dimension(:,:),allocatable :: tstat,evar0,eavg0
   real, dimension(:,:,:), allocatable :: mdata
   type(memberdata_T) :: members(MAX_MEMBERS)
   type(rng_t), dimension(:), allocatable :: rng

   logical :: success
   !----------------------------------------------------------------------

   ! Read inputs to program (arguments, control file and data)
   istat = parse_args(varname_S,level,hour,ctrl_filename_S,out_dirname_S)
   if (.not.RMN_IS_OK(istat)) stop
   write(RMN_STDOUT,*) trim(varname_S),level,hour,trim(ctrl_filename_S)
   istat = read_control_file(ctrl_filename_S)
   if (.not.RMN_IS_OK(istat)) stop
   write(RMN_STDOUT,*) 'nentries, nmembers',nentries,nmembers
   calc_nmembers = nmembers
   do nn=1,nmembers
      write(RMN_STDOUT,*) nn,':',trim(members(nn)%f_S)
      success = calc_read(members(nn)%d,members(nn)%f_S,varname_S,level,hour)
      if (.not. success) then
         call app_log(APP_ERROR,'sverif_prep: Error returned by calc_read')
         stop
      endif
      ni = size(members(nn)%d,dim=1); nj = size(members(nn)%d,dim=2)
      if (nn > 1) then
         if (ni /= niPrev .or. nj /= njPrev) then
            call app_log(APP_ERROR,'sverif_prep: Grid dimension mismatch for '//trim(members(nn)%f_S))
            stop
         endif
      endif
      niPrev = ni; njPrev = nj
   enddo

   ! Allocate space based on input sizes
   allocate(tstat(nentries,NSTAT),stat=istat)
   if (istat /= 0) then
      call app_log(APP_ERROR,'sverif_prep: Unable to allocate space for basic variables')
      stop
   endif
   allocate(flds0(ni,nj,nmembers),stat=istat)
   if (istat /= 0) then
      call app_log(APP_ERROR,'sverif_prep: Unable to allocate space for fields')
      stop
   endif
   allocate(rng(nentries),stat=istat)
   if (istat /= 0) then
      call app_log(APP_ERROR,'sverif_prep: Unable to allocate space for pseudorandom numbers')
      stop
   endif

   ! Initialize and write unperturbed estimates
   allocate(eavg0(ni,nj),evar0(ni,nj),stat=istat)
   evar0 = -1.
   if (istat /= 0) then
      call app_log(APP_ERROR,'sverif_prep: Unable to allocate space for first-entry fields')
      stop
   endif
   call rng_seed(rng(1),932118)
   istat = prep_entry(1,evar0,0.,rng(1),exavg0,eavg0,gss0,evar0,dump=.true.)

   ! Compute test statistics for each sample entry
!$omp parallel private(istat)
!$omp do
   do nn=1,nentries
      call rng_seed(rng(nn),932117+nn)  !create thread-safe random number seeds
      istat = test_entry(nn,evar0,scale,rng(nn),tstat(nn,:))
   enddo
!$omp enddo
!$omp end parallel

   ! Create a list of test statistics for each entry
   istat = write_tstat_file(tstat)
   if (.not.RMN_IS_OK(istat)) stop
   !----------------------------------------------------------------------

contains

   !/@*
   function parse_args(F_varname_S,F_level,F_hour,F_ctrl_filename_S,F_out_dirname_S) result(F_istat)
      implicit none
      character(len=*),intent(out) :: F_varname_S
      character(len=*),intent(out) :: F_ctrl_filename_S,F_out_dirname_S
      integer,intent(out) :: F_level,F_hour
      integer :: F_istat
      !*@/
      character(len=128) :: arg_S
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
      call get_command_argument(4,F_ctrl_filename_S,mylen,istat)
      if (istat /= 0) F_istat = RMN_ERR
      call get_command_argument(5,F_out_dirname_S,mylen,istat)
      if (istat /= 0) F_istat = RMN_ERR
      if (.not.RMN_IS_OK(F_istat)) then
         call app_log(APP_ERROR,'parse_args: Wrong args, Usage: sverif_prep VARNAME LEVEL HOUR CTRL_FILENAME OUT_DIRNAME')
      endif
      !----------------------------------------------------------------------
      return
   end function parse_args

   !/@*
   function read_control_file(F_filename_S) result(F_istat)
      implicit none
      character(len=*),intent(in) :: F_filename_S
      integer :: F_istat
      !*@/
      integer :: istat, fileid, nn
      character(len=1024) :: fpath
      !----------------------------------------------------------------------
      F_istat = clib_isfile(trim(F_filename_S))
      F_istat = min(clib_isreadok(trim(F_filename_S)),F_istat)
      if (.not.RMN_IS_OK(F_istat)) then
         call app_log(APP_ERROR,'read_control_file: Control File not found or not readable: '//trim(F_filename_S))
         return
      endif
      fileid = 0
      F_istat = fnom(fileid,F_filename_S,'SEQ/FMT+R/O+OLD',0)
      if (.not.RMN_IS_OK(F_istat) .or. fileid <= 0) then
         call app_log(APP_ERROR,'read_control_file: Problem opening Control file: '//trim(F_filename_S))
         return
      endif

      read(fileid,*,iostat=istat) nentries,nmembers,scale
      if (istat /=0 ) then
         call app_log(APP_ERROR,'read_control_file: Problem reading Control file: '//trim(F_filename_S))
         return
      endif
      if (nmembers > MAX_MEMBERS) then
         call app_log(APP_ERROR,'read_control_file: (sverif_prep) Too many members')
         F_istat = RMN_ERR
         return
      endif
      do nn=1,nmembers
         read(fileid,*,iostat=istat) fpath
         if (istat /=0 ) then
            call app_log(APP_ERROR,'read_control_file: Problem reading members filenames in Control file: '//trim(F_filename_S))
            F_istat = RMN_ERR
         endif
         do while (index(fpath,':') > 0)
            fpath(index(fpath,':'):index(fpath,':')) = '/'
         enddo
         members(nn)%f_S = trim(fpath)
      enddo

      allocate(entries(nentries,0:nmembers),stat=istat)
      if (istat /= 0) then
         call app_log(APP_ERROR,'read_control_file: Problem allocating memory for control file entries')
         F_istat = RMN_ERR
      endif
      do nn=1,nentries
         read(fileid,*,iostat=istat) entries(nn,0:nmembers)
         if (istat /=0 ) then
            call app_log(APP_ERROR,'read_control_file: Problem reading entries in Control file: '//trim(F_filename_S))
            F_istat = RMN_ERR
            return
         endif
      enddo

      istat = fclos(fileid)
      !----------------------------------------------------------------------
      return
   end function read_control_file


   !/@*
   function write_tstat_file(F_tstat) result(F_istat)
      implicit none
      real,dimension(:,:),intent(in) :: F_tstat
      integer :: F_istat
      !*@/
      integer :: fd,nn
      character(len=1024) :: filename_S,filepath_S
      !----------------------------------------------------------------------
      F_istat = calc_filename(filename_S,'tstat',varname_S,level,hour)
      filepath_S = trim(out_dirname_S)//'/'//trim(filename_S)
      fd = 0
      F_istat = fnom(fd,filepath_S,'SEQ/FMT',0)
      if (.not.RMN_IS_OK(F_istat) .or. fd <= 0) then
         call app_log(APP_ERROR,'write_tstat_file: Problem opening output file: '//trim(filepath_S))
         return
      endif
      do nn=1,size(F_tstat,dim=1)
         write(fd,'(100f15.9)') F_tstat(nn,:)
      enddo
      F_istat = fclos(fd)
      return
    end function write_tstat_file


   !/@*
   function write_ens_stats(F_exavg,F_eavg,F_gss,F_evar) result(F_istat)
     implicit none
     real,intent(in) :: F_exavg,F_gss
     real,dimension(:,:),intent(in) :: F_eavg,F_evar
     integer :: F_istat
     !*@/
     integer, external :: fst_data_length
     integer, parameter :: MYNPAK = -32
     real :: pakdata(CALC_ENSPAK_SIZE)
     integer :: fd,istat,ni,nj
     character(len=1024) :: filename_S,filepath_S
    !----------------------------------------------------------------------
     F_istat = RMN_OK
     F_istat = calc_filename(filename_S,'pre',varname_S,level,hour)
     filepath_S = trim(out_dirname_S)//'/'//trim(filename_S)
     ni = size(F_evar,1)
     nj = size(F_evar,2)
     F_istat = calc_ens_pak(pakdata,varname_S,level,hour,ni,nj,nmembers,F_exavg,F_gss)
     fd = 0
     istat = fnom(fd,trim(filepath_S),'RND+R/W',0)
     istat = fstouv(fd,'RND')
     istat = fstecr(pakdata,pakdata,MYNPAK,fd,0,0,0, &
              size(pakdata),1,1,level,hour,0,' ',varname_S,' ', &
              'X',0,0,0,0,RMN_DTYPE_IEEE+fst_data_length(4),.true.)
     istat = fstecr(F_eavg,F_eavg,MYNPAK,fd,0,0,0, &
              ni,nj,1,level,hour,0,' ','eavg',' ', &
              'X',0,0,0,0,RMN_DTYPE_IEEE+fst_data_length(4),.true.)
     istat = fstecr(F_evar,F_evar,MYNPAK,fd,0,0,0, &
              ni,nj,1,level,hour,0,' ','evar',' ', &
              'X',0,0,0,0,RMN_DTYPE_IEEE+fst_data_length(4),.true.)
     istat = fstfrm(fd)
     istat = fclos(fd)
    return
   end function write_ens_stats


   !/@*
   function test_entry(F_entry,F_evar0,F_scale,F_rng,F_tstat) result(F_istat)
      use rng_mod, only: rng_t
      implicit none
      integer, intent(in) :: F_entry
      real, intent(in) :: F_scale
      type(rng_t), intent(inout) :: F_rng
      real, dimension(:,:), intent(in) :: F_evar0
      real, dimension(:), intent(out) :: F_tstat
      integer :: F_istat
      !*@/
      integer :: err
      real :: exavg,gss
      real, dimension(size(F_evar0,dim=1),size(F_evar0,dim=2)) :: eavg,evar
      !----------------------------------------------------------------------
      F_istat = RMN_ERR
      !#      test member number    is in entries(F_entry,0)
      !#      control members list  is in entries(F_entry,1:nmembers)
      F_istat = prep_entry(F_entry,F_evar0,F_scale,F_rng,exavg,eavg,gss,evar)
      if (F_istat /= RMN_OK) then
         call app_log(APP_ERROR,'test_entry: Error returned by prep_entry')
         return
      endif
      F_istat = calc_t1(members(entries(F_entry,0))%d(:,:,1),exavg,gss0,gss,F_tstat(T1))
      if (F_istat /= RMN_OK) then
         call app_log(APP_ERROR,'test_entry: Error returned by calc_t1')
         return
      endif
      F_istat = calc_nt(0.01,members(entries(F_entry,0))%d(:,:,1),eavg,evar0,evar,F_tstat(NT1))
      if (F_istat /= RMN_OK) then
         call app_log(APP_ERROR,'test_entry: Error returned by calc_nt(1)')
         return
      endif
      F_istat = calc_nt(0.05,members(entries(F_entry,0))%d(:,:,1),eavg,evar0,evar,F_tstat(NT5))
      if (F_istat /= RMN_OK) then
         call app_log(APP_ERROR,'test_entry: Error returned by calc_nt(5)')
         return
      endif
      F_istat = calc_r(members(entries(F_entry,0))%d(:,:,1),exavg,eavg,F_tstat(R))
      if (F_istat /= RMN_OK) then
         call app_log(APP_ERROR,'test_entry: Error returned by calc_r')
         return
      endif
      !----------------------------------------------------------------------
      return
   end function test_entry

   !/@*
   function prep_entry(F_entry,F_evar0,F_scale,F_rng,F_exavg,F_eavg,F_gss,F_evar,dump) result(F_istat)
      implicit none
      integer, intent(in) :: F_entry
      real, dimension(:,:), intent(in) :: F_evar0
      real, intent(in) :: F_scale
      type(rng_t), intent(inout) :: F_rng
      real, intent(out) :: F_exavg,F_gss
      real, dimension(:,:), intent(out) :: F_eavg,F_evar
      logical, intent(in), optional :: dump
      integer :: F_istat
      !*@/
      integer :: imember,ii,jj,ni,nj
      real(RDOUBLE) :: exavg_8,gss_8,rni,rnj,rnt
      real(RDOUBLE), dimension(:,:),allocatable :: eavg_8,evar_8
      real(RDOUBLE), dimension(:,:,:), allocatable :: data
      logical :: myDump
      !----------------------------------------------------------------------
      F_istat = RMN_OK
      myDump = .false.
      if (present(dump)) myDump = dump
      ni = size(F_eavg,dim=1)
      nj = size(F_eavg,dim=2)
      rni = dble(size(F_eavg,dim=1))
      rnj = dble(size(F_eavg,dim=2))
      rnt = dble(nmembers)

      ! Allocate space for calculations
      if (allocated(eavg_8)) then
         if (size(eavg_8,dim=1) /= ni .or. size(eavg_8,dim=2) /= nj) then
            deallocate(eavg_8,evar_8)
            deallocate(data)
         endif
      endif
      if (.not.allocated(eavg_8)) then
         allocate(eavg_8(ni,nj),evar_8(ni,nj))
         allocate(data(ni,nj,nmembers))
      endif

      ! Perturb fields based on a parameteric model
      do imember=1,nmembers
         F_istat = perturb(members(entries(F_entry,imember))%d(:,:,1),F_evar0,F_scale,F_rng,data(:,:,imember))
      enddo

      ! Compute the ensemble mean value
      exavg_8 = sum(dble(data))/dble(ni*nj*(nmembers))
      F_exavg = real(exavg_8)

      ! Compute the ensemble mean field
      eavg_8 = 0.d0
      do jj=1,nj
         do ii=1,ni
            eavg_8(ii,jj) = sum(dble(data(ii,jj,:)))
         enddo
      enddo
      eavg_8 = eavg_8/dble(nmembers)
      F_eavg = real(eavg_8)

      ! Compute the global sum of squares
      gss_8 = 0.d0
      do imember=1,nmembers
         do jj=1,nj
            do ii=1,ni
               gss_8 = gss_8 + (data(ii,jj,imember) - exavg_8)**2
            enddo
         enddo
      enddo
      gss_8 = gss_8/(rni*rnj*rnt*(rni*rnj*rnt-1d0))
      F_gss = real(gss_8)

      ! Compute the ensemble standard deviation
      evar_8 = 0.d0
      do imember=1,nmembers
         do jj=1,nj
            do ii=1,ni
               evar_8(ii,jj) = evar_8(ii,jj) + (data(ii,jj,imember) - eavg_8(ii,jj))**2
            enddo
         enddo
      enddo
      evar_8 = evar_8/dble(nmembers)
      F_evar = real(evar_8)

      ! Dump results for first (ordered) vector
      if (myDump) then
         F_istat = write_ens_stats(F_exavg,F_eavg,F_gss,F_evar)
         if (F_istat /= RMN_OK) then
            call app_log(APP_ERROR,'prep_entry: Error returned by write_ens_stats')
         endif
      endif

      !----------------------------------------------------------------------
      return
   end function prep_entry

   !/@*
   function perturb(F_data,F_var,F_scale,F_rng,F_perturb_data) result(F_istat)
     use rng_mod, only: rng_t,rng_uniform
     ! Select a Gaussian perturbation based on the scaled ensemble variance
     implicit none
     real, dimension(:,:), intent(in) :: F_data
     real, dimension(:,:), intent(in) :: F_var
     real, intent(in) :: F_scale
     type(rng_t), intent(inout) :: F_rng
     real(RDOUBLE), dimension(:,:), intent(out) :: F_perturb_data
     integer :: F_istat
     !*@/
     integer :: ii,jj
     real, parameter :: PI=3.14159
     F_istat = RMN_OK

     to_perturb: if (F_scale < epsilon(F_scale)) then
        F_perturb_data = dble(F_data)
     else
        do jj=1,size(F_data,dim=2)
           do ii=1,size(F_data,dim=1)
              F_perturb_data(ii,jj) = dble(F_data(ii,jj) + sqrt(F_var(ii,jj)) * &
                   (F_scale * (3. - 2.*(rng_uniform(F_rng)+rng_uniform(F_rng)+rng_uniform(F_rng)))))
           enddo
        enddo
     endif to_perturb
     return
   end function perturb

end program sverif_prep
