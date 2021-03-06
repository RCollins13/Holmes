#!/usr/bin/Rscript

#################################
#             HOLMES            #
#  The liWGS SV discovery tool  #
#################################

# Copyright (c) 2016 Ryan L. Collins and the laboratory of Michael E. Talkowski
# Contact: Ryan L. Collins <rlcollins@g.harvard.edu>
# Code development credits and citation availble on GitHub

#Positional argument (1): full path to Holmes QC.metrics file (input)
#Positional argument (2): full path to Holmes run summary file (text output)
#Positional argument (3): full path to metrics plot pdf (graphical output)

#Read command-line arguments
args <- commandArgs(TRUE)

##Ensures Standard Decimal Notation##
options(scipen=1000)

#Load file
x <- read.table(args[1],comment.char="#",header=F)
colnames(x) <- c("ID","Total Read Pairs","Read Alignment Rate","Pair Alignment Rate","Proper Pairs",
                 "Chimeras","Read Duplicates","Pair Duplicates","Median Insert Size",
                 "Insert MAD","Haploid Physical Coverage","Haploid Nucleotide Coverage","Reported Sex",
                 "Observed Sex","Absolute Dosage Z-Score")
x[,2] <- x[,2]/1000000
x[,3:8] <- 100*x[,3:8]

#Write metrics
df <- data.frame("a","b","c","d","e","f","g","h",stringsAsFactors=F)
for(i in c(2:12,15)){
  iqr <- summary(x[,i])[5]-summary(x[,i])[2]
  if(i==2){
    df <- rbind(df,as.character(c(colnames(x)[i],
                     paste(prettyNum(summary(x[,i]),big.mark=","),
                           "M",sep=""),
                     length(x[which(x[,i]>=median(x[,i])+(1.5*iqr) |
                                      x[,i]<=median(x[,i]-1.5*iqr)),i]))))
  }else if(i %in% c(3:8)){
    df <- rbind(df,as.character(c(colnames(x)[i],
                     paste(round(summary(x[,i]),2),
                           "%",sep=""),
                     length(x[which(x[,i]>=median(x[,i])+(1.5*iqr) |
                                      x[,i]<=median(x[,i]-1.5*iqr)),i]))))
  }else if(i %in% c(9,10)){
    df <- rbind(df,as.character(c(colnames(x)[i],
                     prettyNum(summary(x[,i]),big.mark=","),
                     length(x[which(x[,i]>=median(x[,i])+(1.5*iqr) |
                                      x[,i]<=median(x[,i]-1.5*iqr)),i]))))
  }else{
    df <- rbind(df,as.character(c(colnames(x)[i],
                     round(summary(x[,i]),2),
                     length(x[which(x[,i]>=median(x[,i])+(1.5*iqr) |
                                      x[,i]<=median(x[,i]-1.5*iqr)),i]))))
  }
}
write.table(df[2:nrow(df),],args[2],sep="\t",append=T,row.names=F,col.names=F,quote=F)

#Plot metrics
#sets layout & output
pdf(args[3],paper="USr",height=6.5,width=10.5)
layout(matrix(c(1,1,2,4,1,1,3,5,8,8,7,6),3,4,byrow=TRUE))

#[1] histogram of coverage
pl <- hist(x[,11],
           breaks=20,
           col="firebrick",
           main="Approximate Haploid Insert Coverage",
           ylab="Libraries",
           xaxt="n",
           xlab="",
           cex.axis=0.7)
axis(1,at=pl$breaks[seq(1,length(pl$breaks),by=2)],
     labels=paste(pl$breaks[seq(1,length(pl$breaks),by=2)],"X",sep=""))
abline(v=median(x[,11],na.rm=T),lwd=4,col="gold2")
legend("topright",legend="Median",
       lty=1,lwd=4,col="gold2",cex=0.8)

#[2] histogram of read alignment rate
pl <- hist(x[,3]/100,
           breaks=15,
           col="chocolate1",
           main="Read Alignment Rate",
           ylab="Libraries",
           xaxt="n",
           xlab="",
           cex.axis=0.7)
axis(1,at=pl$breaks[seq(2,length(pl$breaks),by=2)],
     labels=paste(pl$breaks[seq(2,length(pl$breaks),by=2)]*100,"%",sep=""))

#[3] histogram of pair alignment rate
pl <- hist(x[,4]/100,
           breaks=15,
           col="chocolate3",
           main="Pairwise Alignment Rate",
           ylab="Libraries",
           xaxt="n",
           xlab="",
           cex.axis=0.7)
axis(1,at=pl$breaks[seq(2,length(pl$breaks),by=2)],
     labels=paste(pl$breaks[seq(2,length(pl$breaks),by=2)]*100,"%",sep=""))

#[4] histogram of read dup rate
pl <- hist(x[,7]/100,
           breaks=15,
           col="cadetblue3",
           main="Read Duplicate Rate",
           ylab="Libraries",
           xlim=c(0,max(x[,7]/100)),
           xaxt="n",
           xlab="",
           cex.axis=0.7)
axis(1,at=seq(0,max(x[,7]/100)+0.05,by=0.05),
     labels=paste(seq(0,max(x[,7]/100)+0.05,by=0.05)*100,"%",sep=""))

#[5] histogram of pair dup rate
pl <- hist(x[,8]/100,
           breaks=15,
           col="cadetblue4",
           main="Pairwise Duplicate Rate",
           ylab="Libraries",
           xlim=c(0,max(x[,8]/100,na.rm=T)),
           xaxt="n",
           xlab="",
           cex.axis=0.7)
axis(1,at=seq(0,max(x[,8]/100,na.rm=T)+0.05,by=0.05),
     labels=paste(seq(0,max(x[,8]/100,na.rm=T)+0.05,by=0.05)*100,"%",sep=""))

#[6] histogram of chimera rate
pl <- hist(x[,6]/100,
           breaks=15,
           col="olivedrab1",
           ylab="Libraries",
           main="Chimera Rate",
           xlim=c(0,max(x[,6]/100,na.rm=T)),
           xaxt="n",
           xlab="",
           cex.axis=0.7)
axis(1,at=seq(0,max(x[,6]/100,na.rm=T)+0.05,by=0.05),
     labels=paste(seq(0,max(x[,6]/100,na.rm=T)+0.05,by=0.05)*100,"%",sep=""))

#[7] histogram of median insert
pl <- hist(x[,9],
           breaks=15,
           col="gold2",
           main="Median Insert Size",
           xlim=c(0.8*min(x[,9]),
                  1.2*max(x[,9])),
           xlab="",
           cex.axis=0.7)
abline(v=median(x[,9],na.rm=T),lwd=2,col="firebrick")
legend("topleft",legend="Median",
       lty=1,lwd=2,col="firebrick",cex=0.8)

#[8] boxplot of raw read pairs
pl <- boxplot(x[,2],
              horizontal=T,
              col="purple3",
              main="Raw Read Pairs",
              xaxt="n",
              xlab="",
              cex.axis=0.7)
axis(1,at=c(as.vector(pl$stats),max(x[,2])),
     labels=paste(c(prettyNum(c(as.vector(pl$stats),
                                max(x[,2])))),"M",sep=""))

dev.off()