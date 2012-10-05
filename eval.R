# User configuration
args<-commandArgs(trailingOnly=TRUE)
var<-args[1]
lev<-as.numeric(args[2])
prog<-as.numeric(args[3])
statpath<-args[4]
file.out<-args[5]
ci.number<-as.numeric(args[6])
ci.bounds<-as.numeric(args[7:(7+ci.number-1)])
dfiles<-args[(7+ci.number):length(args)]

# Basic setup
t.stat.names<-c("T1","NT1","NT5","R")
t.stat.descrip<-list(T1="Grand Mean Test",NT1="Gridpoint Test at 99%",NT5="Gridpoint Test at 95%",R="Spatial Correlation Test")
line.width<-3

# Utility functions
addruns<-function(t.stats,t.name){
  for (i in 1:length(dfiles)){
    abline(v=t.stats[i,][[t.name]],
           col=i+1,
           lwd=3)
  }
}

# Retrieve test statistics for each model run
t.min<-list(T1=Inf,NT1=Inf,NT5=Inf,R=Inf)
t.max<-list(T1=-Inf,NT1=-Inf,NT5=-Inf,R=-Inf)
t.stats<-c()
for (file in dfiles){
  test.results<-system(paste("sverif_eval.Abs",var,lev,prog,file,statpath),intern=TRUE)
  for (t.name in t.stat.names){
    t.long<-paste("calc_",tolower(t.name),sep='')
    eval(parse(text=test.results[grep(t.long,test.results)])[[1]])
    t.min[[t.name]]<-min(t.min[[t.name]],get(t.long))
    t.max[[t.name]]<-max(t.max[[t.name]],get(t.long))
  }
  t.stats<-rbind(t.stats,list(name=(basename(dirname(file))),T1=calc_t1,NT1=calc_nt1,NT5=calc_nt5,R=calc_r))
}

# Retrieve pdes for test statistics
t.stat<-read.table(paste(statpath,system(paste("sverif_fname.Abs tstat",var,lev,prog),intern=TRUE),sep="/"))
colnames(t.stat)<-t.stat.names
pde<-list()
for (t.name in t.stat.names){
  pde[[t.name]]<-t.stat[sort.list(t.stat[[t.name]]),t.name]
}

# Select output device
ext<-strsplit(file.out,'\\.')[[1]][-1]
cex.mult<-1.
if (ext == 'png'){
  png(file.out,height=600,width=800,res=60)
  cex.mult<-1.5
} else if (ext == 'pdf'){
  pdf(file.out,width=8.5,height=8.5)
} else if (ext == 'ps'){
  postscript(file.out)
} else {
  message(paste("Unknown device associated with",file.out," ... using basic png driver"))
  png(file.out)
}

# Generate plots of model run positions relative to the pde
layout(matrix(c(1,2,3,4,5,5,6,6),ncol=2,byrow=TRUE),heights=c(.4,.4,.03,.17))
default<-par(mar=c(5,5,4,2))
for (t.name in t.stat.names){
  hist(pde[[t.name]],breaks=30,
     col="black",
     main=paste(t.stat.descrip[[t.name]]," (",t.name,")",sep=''),
     cex.main=cex.mult*1.7,
     xlim=c(min(t.min[[t.name]],pde[[t.name]][1]),max(t.max[[t.name]],pde[[t.name]][length(pde[[t.name]])])),
     xlab=paste(t.name,"Test Statistic"),
     cex.lab=cex.mult*1.3,
     cex.axis=cex.mult*1.3)
  for (i in 1:length(ci.bounds)){
    indx<-max(round(ci.bounds[i]*length(pde[[t.name]]),digits=0),1)
    axis(side=3,at=c(pde[[t.name]][indx],pde[[t.name]][length(pde[[t.name]])-indx]),
         tick=TRUE,
         line=0,
         col="grey",
         col.ticks=length(dfiles)+1+i,
         lwd.ticks=6,
         labels=FALSE)
  }
  addruns(t.stats,t.name)
}
par(default)
default<-par(mar=c(0,4,0,2))
plot(pde[["T1"]],type='n',xaxt='n',yaxt='n',xlab='',ylab='',bty='n')
legend(x="center",legend=paste(100-100*ci.bounds,"% Confidence Interval",sep=''),col=seq(length(dfiles)+2,length(dfiles)+2+length(ci.bounds)),
       lty=1,lwd=6,cex=cex.mult*1.1,horiz=TRUE,bty='n')
plot(pde[["T1"]],type='n',xaxt='n',yaxt='n',xlab='',ylab='',bty='n')
legend(x="center",legend=t.stats[,"name"],col=seq(2,length(dfiles)+1),ncol=round((length(dfiles)+1)/3,0),
       lty=1,lwd=3,cex=cex.mult*1.5,bg="white")
par(default)
dev.off()

