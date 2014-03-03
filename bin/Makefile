#FFLAGS = =-C -g
FORCE_RMN_VERSION_RC = _rc2
RMN_VERSION   = rmn_014$(FORCE_RMN_VERSION_RC)
COMM_VERSION  = _40510
COMM_stubs    = rpn_commstubs$(COMM_VERSION) 
COMM          = rpn_comm$(COMM_VERSION) $(COMM_stubs)
VGRID         = descrip modelutils_base
LIBS          = modelutils $(VGRID) $(COMM)
OMP	        = -openmp

ARMNLIB_BETAS = ../armnlib/fstd98.o

OBJS = base_stats_mod.o calc_stat_mod.o rng_mod.o 

%.o : %.ftn90
	s.compile -optf "$(FFLAGS)" $(OMP) -src $< -O 2

all: sverif_prep.Abs sverif_eval.Abs sverif_fname.Abs

calc_stats_mod.o: base_stats_mod.o

sverif_prep.Abs: sverif_prep.ftn90 $(OBJS)
	s.compile -optf "$(FFLAGS)" -O 2 $(OMP) -o $@ -src $< -librmn $(RMN_VERSION) -obj $(OBJS) $(ARMNLIB_BETAS) -libappl $(LIBS)

sverif_eval.Abs: sverif_eval.ftn90 $(OBJS)
	s.compile -optf "$(FFLAGS)" -O 2 $(OMP) -o $@ -src $< -librmn $(RMN_VERSION) -obj $(OBJS) $(ARMNLIB_BETAS) -libappl  $(LIBS)

sverif_fname.Abs: sverif_fname.ftn90 $(OBJS)
	s.compile -optf "$(FFLAGS)" -O 2 $(OMP) -o $@ -src $< -librmn $(RMN_VERSION) -obj $(OBJS) $(ARMNLIB_BETAS) -libappl  $(LIBS)

clean:
	rm -f *.o *.mod *.f90 *~

distclean: clean
	rm -f sverif_prep.Abs sverif_eval.Abs sverif_fname.Abs
