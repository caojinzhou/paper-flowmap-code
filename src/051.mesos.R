library(dplyr)

################################################
#  Mesos clustering
################################################

for ( SAVE_ALL in c(FALSE, TRUE)) {
  
  if (SAVE_ALL) {
    SAMPLE = 1000000000
  } else {
    SAMPLE = 400
  }
  
  Cs = c(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
  Ks = c(2, 4, 5, 4, 3, 4, 4, 3, 5, 5, 3, 3, 4, 3, 3)
  
  for ( i in seq(1, 14)) {
    
    C = Cs[i]
    K = Ks[i]
    
    dat <- read.csv(paste('data/mesos0825_s0dot2/',C,'.txt',sep=''), sep=',', head=F)
    colnames(dat) <- c('u1', 'u2', 'dist')
    
    # Sample users to reduce running time
    uuer <- unique(dat$u1)
    print(length(uuer))
    if (length(uuer) > SAMPLE) {
      suer <- sample(unique(dat$u1), SAMPLE, replace=F)
      dat2 <- dat %>% dplyr::filter(u1 %in% suer, u2 %in% suer)
    } else {
      dat2 <- dat
    }
    
    # 3column data frame to matrix.
    # Available functions: reshape2::dcast, plyr::daply, tidyr::spread,
    # reshape, reshape2::acast, xtabs etc.
    dm <- dat2[!duplicated(dat2[,c('u1','u2')]),] %>% tidyr::spread(u2, dist)
    dm <- as.matrix(dm[1:nrow(dm),2:ncol(dm)])
    dm[lower.tri(dm)] <- 0
    ind = which(is.na(dm), arr.ind=TRUE)
    dm[ind] <- rowMeans(dm, na.rm=TRUE)[ind[,1]]
    dm[lower.tri(dm)] <- t(dm)[lower.tri(dm)]
    
    clust <- hclust(as.dist(dm), method='ward.D2')
    ck <- cutree(clust, k = K)
    
    # Order cluster accordding to distance (small to big)
    cls <- data.frame(dist = apply(dm, 1, mean), lab = ck)
    cls_stat <- cls %>% group_by(lab) %>% summarize(mdist = mean(dist))
    cls_ord <- data.frame(lab = order(cls_stat$mdist), ord = seq(K))
    ck_ord <- data.frame(ck = ck) %>% left_join(cls_ord, by = c('ck' = 'lab'))
    ord <- order(ck_ord$ord)
    
    # Save cluster lables for each user
    if ( SAVE_ALL ) {
      for ( j in seq(K)) {
        selector <- ck==j
        dmj <- dm[selector,selector]
        write.table(dmj, paste('data/mesos0825_s0dot2/mesos0825_s0dot2_c',C,'_kn',j,sep=''),
                    sep=',', row.names=F, col.names=T,quote=F)
      }
      next  # Skip drawing below
    }
    
    # Dendrogram
    pdf(paste('figures/mesos0825_s0.2_dendrogram/mesos0825_s0.2_c',C,'_dendrogram.pdf',sep=''), width=7, height=6.2)
    par(mar=c(3,3,1,1), mgp=c(1.5,0.5,0), cex.lab=1.5)
    plot(as.dendrogram(clust), leaflab="none", xlab="Mobility Graph", ylab="Cophenetic distance")
    
    pal.1 <- colorRampPalette(c("blue", "cyan", "yellow", "red"), bias=0.5)
    
    # Dissimilarity matrix (inset)
    library(TeachingDemos)
    subplot(image(as.matrix(dm)[ord, ord], col=pal.1(10)), 
            x=grconvertX(c(0.55,0.95), from='npc'),
            y=grconvertY(c(0.55,0.95), from='npc'),
            type='fig', pars=list( mar=c(1.5,1.5,0,0)+0.1) )
    dev.off()
    
    # Standalone
    pdf(paste('figures/mesos0825_s0.2_dendrogram/mesos0825_s0.2_c',C,'_k',K,'_distmat.pdf',sep=''), width=7, height=6.2)
    par(mar=c(3.5,3.5,1,1), mgp=c(2,0.5,0), cex.lab=1.5)
    image(as.matrix(dm)[ord, ord], xlab='Mobility Graph', ylab='Mobility Graph',col=pal.1(10))  
    dev.off()
    
  }
}


################################################
#  Clusters in ALL-IN-ONE plot
################################################

SAMPLE = 300

pdf(paste('figures/mesos0825_s0.2_dendrogram/mesos0825_s0.2_distmat.pdf',sep=''), width=8, height=9)
par(mfrow=c(3,3), mar=c(3,1,1,1), mgp=c(1,0.5,0), cex.lab=1.5)

nlocdist <- read.csv('data/hcl_mesos0825_ndgr', sep=',', head=T)
hi <- hist(nlocdist$nloc, breaks=max(nlocdist$nloc), plot=FALSE)
dens <- hi$density

Cs = c(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
Ks = c(2, 4, 5, 4, 3, 4, 4, 3, 5, 5, 3, 3, 4, 3, 3)

for ( i in seq(1, 14) ) {
  
  C = Cs[i]
  K = Ks[i]
  
  dat <- read.csv(paste('data/mesos0825_s0dot2/',C,'.txt',sep=''), sep=',', head=F)
  colnames(dat) <- c('u1', 'u2', 'dist')
  
  # Sample users to reduce running time
  uuer <- unique(dat$u1)
  print(length(uuer))
  if (length(uuer) > SAMPLE) {
    suer <- sample(unique(dat$u1), SAMPLE, replace=F)
    dat2 <- dat %>% dplyr::filter(u1 %in% suer, u2 %in% suer)
    
    saveRDS(dat2, paste('data/mesos0825_s0dot2/',C,'_sample2.rds', sep=''))
    dat2 <- readRDS(paste('data/mesos0825_s0dot2/',C,'_sample2.rds', sep=''))
  } else {
    dat2 <- dat
  }
  
  # 3column data frame to matrix.
  # Available functions: reshape2::dcast, plyr::daply, tidyr::spread,
  # reshape, reshape2::acast, xtabs etc.
  dm <- dat2[!duplicated(dat2[,c('u1','u2')]),] %>% tidyr::spread(u2, dist)
  dm <- as.matrix(dm[1:nrow(dm),2:ncol(dm)])
  dm[lower.tri(dm)] <- t(dm)[lower.tri(dm)]
  dm[which(is.na(dm), arr.ind=TRUE)] <- 1
  
  clust <- hclust(as.dist(dm), method='ward.D2')
  k = K
  ck <- cutree(clust, k = k)
  
  # Order cluster accordding to distance (small to big)
  cls <- data.frame(dist = apply(dm, 1, mean), lab = ck)
  cls_stat <- cls %>% group_by(lab) %>% summarize(mdist = mean(dist))
  cls_ord <- data.frame(lab = order(cls_stat$mdist), ord = seq(k))
  ck_ord <- data.frame(ck = ck) %>% left_join(cls_ord, by = c('ck' = 'lab'))
  ord <- order(ck_ord$ord)
  
  pal.1 <- colorRampPalette(c("blue", "cyan", "yellow", "red"), bias=0.5)
  image(as.matrix(dm)[ord, ord], axes=F ,col=pal.1(10),
        xlab=paste('C=', C, ', K=', k, ', p=', format(dens[C-1]*100, digits=2), '%', sep=''))
}

dev.off()
