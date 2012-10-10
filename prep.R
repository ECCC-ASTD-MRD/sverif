# User configuration
args<-commandArgs(trailingOnly=TRUE)
var<-args[1]
lev<-as.numeric(args[2])
prog<-as.numeric(args[3])
file.in<-args[4]
statpath<-args[5]
nboot<-as.numeric(args[6])
ci.number<-as.numeric(args[7])
ci.bounds<-as.numeric(args[8:(8+ci.number-1)])
dfiles<-args[(8+ci.number):length(args)]

# Utility functions
cinterval<-function(file.out,t.stat,t.name,bounds,init=FALSE){
  pde<-t.stat[sort.list(t.stat[[t.name]]),t.name]
  if (init){write(c(length(bounds),bounds),file=file.out,append=TRUE)}
  for (i in 1:length(bounds)){
    indx<-max(round(bounds[i]*nboot,digits=0),1)
    write(sprintf("%i %8.16f %8.16f",i,pde[indx],pde[nboot-indx]),file=file.out,append=TRUE)
  }
}

# Write to file for ftn calculations
write(c(nboot,length(dfiles)),file=file.in)
for (f in dfiles){
  write(gsub('/',':',f),file=file.in,append=TRUE)
}
write(c(1,seq(1,length(dfiles))),file=file.in,append=TRUE,ncolumns=length(dfiles)+1)
for (i in 1:(nboot-1)){
  write(c(sample(seq(1,length(dfiles)),1),sample(seq(1,length(dfiles)),length(dfiles),repl=TRUE)),file=file.in,append=TRUE,ncolumns=length(dfiles)+1)
}

# Run ftn code to compute test statistics
system(paste("sverif_prep.Abs",var,lev,prog,file.in,statpath))

# Retrieve return file and ensemble statistics file
t.stats<-read.table(paste(statpath,system(paste("sverif_fname.Abs tstat",var,lev,prog),intern=TRUE),sep='/'),header=FALSE)
colnames(t.stats)<-c("T1","NT1","NT5","R")
file.ens<-paste(statpath,system(paste("sverif_fname.Abs pre",var,lev,prog),intern=TRUE),sep='/')

# Retrieve T1 statistic results
cinterval(file.ens,t.stats,"T1",ci.bounds,init=TRUE)

# Retrieve NT statistic results
cinterval(file.ens,t.stats,"NT1",ci.bounds)
cinterval(file.ens,t.stats,"NT5",ci.bounds)

# Retrieve R statistic results
cinterval(file.ens,t.stats,"R",ci.bounds)
