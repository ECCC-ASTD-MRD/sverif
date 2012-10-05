#FFLAGS = =-C -g

COMM_VERSION  = _40007
RMN_VERSION   = rmn_013
COMM_stubs    = rpn_commstubs$(COMM_VERSION) 
COMM          = rpn_comm$(COMM_VERSION) $(COMM_stubs)
VGRID         = descrip modelutils_base
LIBS          = modelutils $(VGRID) $(COMM)

OBJS = base_stats_mod.o calc_stat_mod.o

%.o : %.ftn90
	s.compile -optf "$(FFLAGS)" -src $< -O 2

all: sverif_prep sverif_eval sverif_fname

calc_stats_mod.o: base_stats_mod.o

sverif_prep: sverif_prep.ftn90 $(OBJS)
	s.compile -optf "$(FFLAGS)" -O 2 -o $@ -src $< -librmn $(RMN_VERSION) -obj $(OBJS) -libappl $(LIBS)

sverif_eval: sverif_eval.ftn90 $(OBJS)
	s.compile -optf "$(FFLAGS)" -O 2 -o $@ -src $< -librmn $(RMN_VERSION) -obj $(OBJS) -libappl  $(LIBS)

sverif_fname: sverif_fname.ftn90 $(OBJS)
	s.compile -optf "$(FFLAGS)" -O 2 -o $@ -src $< -librmn $(RMN_VERSION) -obj $(OBJS) -libappl  $(LIBS)

clean:
	rm -f *.o *.mod *.f90 *~

distclean: clean
	rm -f sverif_prep sverif_eval sverif_fname
