ifneq (,$(DEBUGMAKE))
$(info ## ====================================================================)
$(info ## File: $$sverif/include/Makefile.ssm.mk)
$(info ## )
endif
#---- SSM build  upport  -------------------------------------------

SVERIF_SSMALL_NAME  = sverif$(SVERIF_SFX)_$(SVERIF_VERSION)_all
SVERIF_SSMARCH_NAME = sverif$(SVERIF_SFX)+$(COMP_ARCH)_$(SVERIF_VERSION)_$(SSMARCH)
SVERIF_SSMALL_FILES  = $(SVERIF_SSMALL_NAME).ssm
SVERIF_SSMARCH_FILES = $(SVERIF_SSMARCH_NAME).ssm

SSM_DEPOT_DIR := $(HOME)/SsmDepot
SSM_BASE      := $(HOME)/SsmBundles
SVERIF_SSM_BASE_DOM  = $(SSM_BASE)/ENV/d/$(SVERIF_VERSION_X)sverif
SVERIF_SSM_BASE_BNDL = $(SSM_BASE)/ENV/$(SVERIF_VERSION_X)sverif
SVERIF_INSTALL   = sverif_install
SVERIF_UNINSTALL = sverif_uninstall

.PHONY: sverif_ssm sverif_ssm_all.ssm rm_sverif_ssm_all.ssm sverif_ssm_all rm_sverif_ssm_all sverif_ssm_arch.ssm rm_sverif_ssm_arch.ssm sverif_ssm_arch sverif_ssm_arch_rm
sverif_ssm: sverif_ssm_all.ssm sverif_ssm_arch.ssm
rm_sverif_ssm: rm_sverif_ssm_all.ssm rm_sverif_ssm_all rm_sverif_ssm_arch.ssm sverif_ssm_arch_rm

sverif_ssm_all.ssm: $(SVERIF_SSMALL_FILES)
$(SVERIF_SSMALL_FILES): sverif_ssm_all rm_sverif_ssm_all.ssm $(SSM_DEPOT_DIR)/$(SVERIF_SSMALL_NAME).ssm
rm_sverif_ssm_all.ssm:
	rm -f $(SSM_DEPOT_DIR)/$(SVERIF_SSMALL_NAME).ssm
$(SSM_DEPOT_DIR)/$(SVERIF_SSMALL_NAME).ssm:
	cd $(BUILDSSM)  ;\
	chmod a+x $(basename $(notdir $@))/bin/* 2>/dev/null || true ;\
	tar czvf $@ $(basename $(notdir $@))
	ls -l $@

sverif_ssm_all: rm_sverif_ssm_all $(BUILDSSM)/$(SVERIF_SSMALL_NAME)
rm_sverif_ssm_all:
	rm -rf $(BUILDSSM)/$(SVERIF_SSMALL_NAME)
$(BUILDSSM)/$(SVERIF_SSMALL_NAME):
	rm -rf $@ ; mkdir -p $@ ; \
	rsync -av --exclude-from=$(DIRORIG_sverif)/.ssm.d/exclude $(DIRORIG_sverif)/ $@/ ; \
	echo "Dependencies (s.ssmuse.dot): " > $@/BUILDINFO ; \
	cat $@/ssmusedep.bndl >> $@/BUILDINFO ; \
	.rdemk_ssm_control sverif $(SVERIF_VERSION) "all ; $(BASE_ARCH)" $@/BUILDINFO $@/DESCRIPTION > $@/.ssm.d/control

sverif_ssm_arch.ssm: $(SVERIF_SSMARCH_FILES)
$(SVERIF_SSMARCH_FILES): sverif_ssm_arch rm_sverif_ssm_arch.ssm $(SSM_DEPOT_DIR)/$(SVERIF_SSMARCH_NAME).ssm
rm_sverif_ssm_arch.ssm:
	rm -f $(SSM_DEPOT_DIR)/$(SVERIF_SSMARCH_NAME).ssm
$(SSM_DEPOT_DIR)/$(SVERIF_SSMARCH_NAME).ssm:
	cd $(BUILDSSM) ; tar czvf $@ $(basename $(notdir $@))
	ls -l $@

sverif_ssm_arch: sverif_ssm_arch_rm $(BUILDSSM)/$(SVERIF_SSMARCH_NAME)
sverif_ssm_arch_rm:
	rm -rf $(BUILDSSM)/$(SVERIF_SSMARCH_NAME)
$(BUILDSSM)/$(SVERIF_SSMARCH_NAME):
	mkdir -p $@/lib/$(EC_ARCH) ; \
	cd $(LIBDIR) ; \
	rsync -av `ls libsverif*.a libsverif*.a.fl libsverif*.so 2>/dev/null` $@/lib/$(EC_ARCH)/ ; \
	if [[ x$(MAKE_SSM_NOMOD) != x1 ]] ; then \
		mkdir -p $@/include/$(EC_ARCH) ; \
		cd $(MODDIR) ; \
		cp $(SVERIF_MOD_FILES) $@/include/$(EC_ARCH) ; \
	fi ; \
	if [[ x$(MAKE_SSM_NOINC) != x1 ]] ; then \
		mkdir -p $@/include/$(EC_ARCH) ; \
		echo $(BASE_ARCH) > $@/include/$(BASE_ARCH)/.restricted ; \
		echo $(ORDENV_PLAT) >> $@/include/$(BASE_ARCH)/.restricted ; \
		echo $(EC_ARCH) > $@/include/$(EC_ARCH)/.restricted ; \
		echo $(ORDENV_PLAT)/$(COMP_ARCH) >> $@/include/$(EC_ARCH)/.restricted ; \
		.rdemkversionfile sverif $(SVERIF_VERSION) $@/include/$(EC_ARCH) f ; \
		.rdemkversionfile sverif $(SVERIF_VERSION) $@/include/$(EC_ARCH) c ; \
		.rdemkversionfile sverif $(SVERIF_VERSION) $@/include/$(EC_ARCH) sh ; \
	fi ; \
	if [[ x$(MAKE_SSM_NOABS) != x1 ]] ; then \
		mkdir -p $@/bin/$(BASE_ARCH) ; \
		cd $(BINDIR) ; \
		cp $(SVERIF_ABS_FILES) $@/bin/$(BASE_ARCH) ; \
	fi ; \
	cp -R $(DIRORIG_sverif)/.ssm.d $@/ ; \
	.rdemk_ssm_control sverif $(SVERIF_VERSION) "$(SSMORDARCH) ; $(SSMARCH) ; $(BASE_ARCH)" $@/BUILDINFO $@/DESCRIPTION > $@/.ssm.d/control 


.PHONY: sverif_install sverif_uninstall
sverif_install: 
	if [[ x$(CONFIRM_INSTALL) != xyes ]] ; then \
		echo "Please use: make $@ CONFIRM_INSTALL=yes" ;\
		exit 1;\
	fi
	cd $(SSM_DEPOT_DIR) ;\
	rdessm-install -v \
			--dest=$(SVERIF_SSM_BASE_DOM)/sverif_$(SVERIF_VERSION) \
			--bndl=$(SVERIF_SSM_BASE_BNDL)/$(SVERIF_VERSION).bndl \
			--pre=$(sverif)/ssmusedep.bndl \
			--post=$(sverif)/ssmusedep_post.bndl \
			--base=$(SSM_BASE) \
			sverif{_,+*_,-d+*_}$(SVERIF_VERSION)_*.ssm

sverif_uninstall:
	if [[ x$(UNINSTALL_CONFIRM) != xyes ]] ; then \
		echo "Please use: make $@ UNINSTALL_CONFIRM=yes" ;\
		exit 1;\
	fi
	cd $(SSM_DEPOT_DIR) ;\
	rdessm-install -v \
			--dest=$(SVERIF_SSM_BASE_DOM)/sverif_$(SVERIF_VERSION) \
			--bndl=$(SVERIF_SSM_BASE_BNDL)/$(SVERIF_VERSION).bndl \
			--base=$(SSM_BASE) \
			--uninstall

ifneq (,$(DEBUGMAKE))
$(info ## ==== $$sverif/include/Makefile.ssm.mk [END] ========================)
endif
