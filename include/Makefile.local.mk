ifneq (,$(DEBUGMAKE))
$(info ## ====================================================================)
$(info ## File: $$sverif/include/Makefile.local.mk)
$(info ## )
endif

MAKE_NO_LIBSO=1

## Sverif definitions

# ifeq (,$(wildcard $(sverif)/VERSION))
#    $(error Not found: $(sverif)/VERSION)
# endif
# SVERIF_VERSION0  = $(shell cat $(sverif)/VERSION | sed 's|x/||')
#SVERIF_VERSION0  = x/5.8.rc7
SVERIF_VERSION0  = 1.0.1
SVERIF_VERSION   = $(notdir $(SVERIF_VERSION0))
SVERIF_VERSION_X = $(dir $(SVERIF_VERSION0))

PHYBINDIR = $(BINDIR)

## Some Shortcut/Alias to Lib Names
SVERIF_MPI_STUBS       = sverif_mpi_stubs
SVERIF_LIBS_DEP        = $(MODELUTILS_LIBS_V) $(MODELUTILS_LIBS_DEP) $(SVERIF_MPI_STUBS)
SVERIF_LIBS_SHARED_DEP = $(MODELUTILS_LIBS_SHARED_V) $(MODELUTILS_LIBS_SHARED_DEP)

SVERIF_LIBS_MERGED_0 = sverif_base
# SVERIF_LIBS_OTHER_0  = sverif_rmn
SVERIF_LIBS_OTHER_0  = $(SVERIF_MPI_STUBS)

SVERIF_SFX=$(RDE_BUILDDIR_SFX)
SVERIF_LIBS_MERGED = $(foreach item,$(SVERIF_LIBS_MERGED_0),$(item)$(SVERIF_SFX))
SVERIF_LIBS_OTHER  = $(foreach item,$(SVERIF_LIBS_OTHER_0),$(item)$(SVERIF_SFX))

SVERIF_LIBS_ALL_0  = $(SVERIF_LIBS_MERGED_0) $(SVERIF_LIBS_OTHER_0)
SVERIF_LIBS_ALL    = $(SVERIF_LIBS_MERGED) $(SVERIF_LIBS_OTHER)

SVERIF_LIBS_0      = sverif$(SVERIF_SFX)
SVERIF_LIBS        = $(SVERIF_LIBS_0) $(SVERIF_LIBS_OTHER) 
SVERIF_LIBS_V      = $(SVERIF_LIBS_0)_$(SVERIF_VERSION) $(SVERIF_LIBS_OTHER) 

ifeq (,$(MAKE_NO_LIBSO))
SVERIF_LIBS_SHARED_ALL = $(foreach item,$(SVERIF_LIBS_ALL),$(item)-shared)
SVERIF_LIBS_SHARED_0   = $(SVERIF_LIBS_0)-shared
SVERIF_LIBS_SHARED     = $(SVERIF_LIBS_SHARED_0) $(SVERIF_LIBS_OTHER) 
SVERIF_LIBS_SHARED_V   = $(SVERIF_LIBS_SHARED_0)_$(SVERIF_VERSION) $(SVERIF_LIBS_OTHER) 
endif

SVERIF_LIBS_OTHER_FILES = $(foreach item,$(SVERIF_LIBS_OTHER),$(LIBDIR)/lib$(item).a) 
SVERIF_LIBS_ALL_FILES = $(foreach item,$(SVERIF_LIBS_ALL),$(LIBDIR)/lib$(item).a)
                      # $(foreach item,$(SVERIF_LIBS_SHARED_ALL),$(LIBDIR)/lib$(item).so)
ifeq (,$(MAKE_NO_LIBSO))
SVERIF_LIBS_SHARED_FILES = $(LIBDIR)/lib$(SVERIF_LIBS_SHARED_0).so
endif
SVERIF_LIBS_ALL_FILES_PLUS = $(LIBDIR)/lib$(SVERIF_LIBS_0).a $(SVERIF_LIBS_SHARED_FILES) $(SVERIF_LIBS_ALL_FILES) 

OBJECTS_MERGED_sverif = $(foreach item,$(SVERIF_LIBS_MERGED_0),$(OBJECTS_$(item)))

SVERIF_MOD_FILES = $(foreach item,$(FORTRAN_MODULES_sverif),$(item).[Mm][Oo][Dd])

SVERIF_ABS       = sverif_prep sverif_eval sverif_fname
SVERIF_ABS_FILES = $(foreach item,$(SVERIF_ABS),$(BINDIR)/$(item).Abs)

## Base Libpath and libs with placeholders for abs specific libs
# MODEL2_LIBAPPL = $(SVERIF_LIBS_V)


##
.PHONY: sverif_vfiles
SVERIF_VFILES = sverif_version.inc sverif_version.h
sverif_vfiles: $(SVERIF_VFILES)
sverif_version.inc:
	.rdemkversionfile "sverif" "$(SVERIF_VERSION)" . f
sverif_version.h:
	.rdemkversionfile "sverif" "$(SVERIF_VERSION)" . c


#---- Abs targets -----------------------------------------------------

## Sverif Targets
.PHONY: sverif_prep sverif_eval sverif_fname allbin_sverif allbincheck_sverif

mainsverif_prep=sverif_prep.Abs
sverif_prep: | sverif_prep_rm $(BINDIR)/$(mainsverif_prep)
	ls -l $(BINDIR)/$(mainsverif_prep)
sverif_prep_rm:
	rm -f $(BINDIR)/$(mainsverif_prep)
$(BINDIR)/$(mainsverif_prep): | $(SVERIF_VFILES)
	export MAINSUBNAME="sverif_prep" ;\
	export ATM_MODEL_NAME="$${MAINSUBNAME} $(BUILDNAME)" ;\
	export ATM_MODEL_VERSION="$(SVERIF_VERSION)" ;\
	export RBUILD_LIBAPPL="$(SVERIF_LIBS_V) $(SVERIF_LIBS_DEP)" ;\
	export RBUILD_COMM_STUBS=$(LIBCOMM_STUBS) ;\
	$(RBUILD4objNOMPI)

mainsverif_eval=sverif_eval.Abs
sverif_eval: | sverif_eval_rm $(BINDIR)/$(mainsverif_eval)
	ls -l $(BINDIR)/$(mainsverif_eval)
sverif_eval_rm:
	rm -f $(BINDIR)/$(mainsverif_eval)
$(BINDIR)/$(mainsverif_eval): | $(SVERIF_VFILES)
	export MAINSUBNAME="sverif_eval" ;\
	export ATM_MODEL_NAME="$${MAINSUBNAME} $(BUILDNAME)" ;\
	export ATM_MODEL_VERSION="$(SVERIF_VERSION)" ;\
	export RBUILD_LIBAPPL="$(SVERIF_LIBS_V) $(SVERIF_LIBS_DEP)" ;\
	export RBUILD_COMM_STUBS=$(LIBCOMM_STUBS) ;\
	$(RBUILD4objNOMPI)

mainsverif_fname=sverif_fname.Abs
sverif_fname: | sverif_fname_rm $(BINDIR)/$(mainsverif_fname)
	ls -l $(BINDIR)/$(mainsverif_fname)
sverif_fname_rm:
	rm -f $(BINDIR)/$(mainsverif_fname)
$(BINDIR)/$(mainsverif_fname): | $(SVERIF_VFILES)
	export MAINSUBNAME="sverif_fname" ;\
	export ATM_MODEL_NAME="$${MAINSUBNAME} $(BUILDNAME)" ;\
	export ATM_MODEL_VERSION="$(SVERIF_VERSION)" ;\
	export RBUILD_LIBAPPL="$(SVERIF_LIBS_V) $(SVERIF_LIBS_DEP)" ;\
	export RBUILD_COMM_STUBS=$(LIBCOMM_STUBS) ;\
	$(RBUILD4objNOMPI)

allbin_sverif: | $(SVERIF_ABS)
allbincheck_sverif:
	for item in $(SVERIF_ABS_FILES) ; do \
		if [[ ! -x $${item} ]] ; then exit 1 ; fi ;\
	done ;\
	exit 0

#---- Lib target - automated ------------------------------------------
sverif_LIB_template1 = \
$$(LIBDIR)/lib$(2)_$$($(3)_VERSION).a: $$(OBJECTS_$(1)) ; \
rm -f $$@ $$@_$$$$$$$$; \
ar r $$@_$$$$$$$$ $$(OBJECTS_$(1)); \
mv $$@_$$$$$$$$ $$@

.PHONY: sverif_libs
sverif_libs: $(OBJECTS_sverif) $(SVERIF_LIBS_ALL_FILES_PLUS) | $(SVERIF_VFILES)
$(foreach item,$(SVERIF_LIBS_ALL_0),$(eval $(call sverif_LIB_template1,$(item),$(item)$(SVERIF_SFX),SVERIF)))
$(foreach item,$(SVERIF_LIBS_ALL),$(eval $(call LIB_template2,$(item),SVERIF)))

$(LIBDIR)/lib$(SVERIF_LIBS_0)_$(SVERIF_VERSION).a: $(OBJECTS_sverif) | $(SVERIF_VFILES)
	rm -f $@ $@_$$$$; ar r $@_$$$$ $(OBJECTS_MERGED_sverif); mv $@_$$$$ $@
$(LIBDIR)/lib$(SVERIF_LIBS_0).a: $(LIBDIR)/lib$(SVERIF_LIBS_0)_$(SVERIF_VERSION).a
	cd $(LIBDIR) ; rm -f $@ ;\
	ln -s lib$(SVERIF_LIBS_0)_$(SVERIF_VERSION).a $@

$(LIBDIR)/lib$(SVERIF_LIBS_SHARED_0)_$(SVERIF_VERSION).so: $(OBJECTS_sverif) $(SVERIF_LIBS_OTHER_FILES) | $(SVERIF_VFILES)
	export RBUILD_EXTRA_OBJ="$(OBJECTS_MERGED_sverif)" ;\
	export RBUILD_LIBAPPL="$(SVERIF_LIBS_OTHER) $(SVERIF_LIBS_DEP)" ;\
	$(RBUILD4MPI_SO)
	ls -l $@
$(LIBDIR)/lib$(SVERIF_LIBS_SHARED_0).so: $(LIBDIR)/lib$(SVERIF_LIBS_SHARED_0)_$(SVERIF_VERSION).so
	cd $(LIBDIR) ; rm -f $@ ;\
	ln -s lib$(SVERIF_LIBS_SHARED_0)_$(SVERIF_VERSION).so $@
	ls -l $@ ; ls -lL $@

ifneq (,$(DEBUGMAKE))
$(info ## ==== $$sverif/include/Makefile.local.mk [END] ======================)
endif
