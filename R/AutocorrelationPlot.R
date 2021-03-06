#' Generates an autocorrelation plot from a Java MCMC results class object
#' 
#' @export
#' @title Autocorrelation plot for model selection. Model inclusion of each predictor is
#' represented across all iterations as a black and white "heatmap".
#' @name AutocorrelationPlot
#' @inheritParams ResultsTable
#' @inheritParams ManhattanPlot
#' @param plot.file Path to a PDF to print plot to.
#' @param include.var.names Include variable names perpendicularly below the x-axis. Turn off if it looks too crowded.
#' @param include.post.probs Include a barplot of posterior probabilities at the top.
#' @return NA
#' @author Paul Newcombe
#' @example Examples/AutocorrelationPlot_Examples.R
AutocorrelationPlot <- function(
  results,
  vars.to.include=NULL,
  plot.file=NULL,
  include.var.names=TRUE,
  var.dictionary=NULL,
  include.post.probs=TRUE) {
  
  # Possible future arguments:
  cex.x.axis.ticks<-0.5
  cex.y.axis.ticks<-2
  cex.y.axis.labels<-2
  mar.for.varnames<-8  
  
  # Setup for plot
  if (!is.null(vars.to.include)) {
    results$results <- results$results[,vars.to.include]
  } else {
    # Exclude sensible stuff
    results$results <- results$results[,-c(1:results$args$startRJ)]
    results$results <- results$results[,colnames(results$results)[!colnames(results$results)%in%c("alpha","LogBetaPriorSd","LogLikelihood")]]
  }
  n.var <- ncol(results$results)
  if ("n.mi.chains" %in% names(results)) {
    # Keep only first chain for the plot
    results$results <- results$results[1:(nrow(results$results)/results$n.mi.chains),  ]
  }
  x <- c(1:n.var)
  y <- seq(from=(results$args$iterations/2+results$args$thin),to=results$args$iterations, by=results$args$thin)
  z <- results$results!=0
  z <- t(z)+0 # Makes numeric
  
  # Initiate Plot
  if(!is.null(plot.file)) {
    pdf(file=plot.file,
        paper="special",
        width=8,
        height=11)
  }
  if (include.post.probs) {
    par(mfrow=c(8,1))
    layout(matrix(c(1,2,2,2,2,2,2,2), 8, 1, byrow = TRUE))
    par(mar=c(0, 4*cex.y.axis.labels, 4, 2) + 0.1)
    
    # 1 - Barplot  
    barplot(
      height=apply(results$results,MAR=2,function(x) sum(x!=0)/length(x) ),
      ylim=c(0,1),
      axes=FALSE,
      ylab="Post Prob",
      xlab="",
      names.arg=rep("",ncol(results$results)),
      space=0,
      xlim=c(0,ncol(results$results)),
      xaxs="i",
      col="black", cex.lab=cex.y.axis.labels)
    axis(2,
         at=seq(from=0,to=1,by=0.25),
         labels=c("","0.25","0.5","0.75","1"), cex.axis=cex.y.axis.ticks)
    mar.top <- 0.1
  } else {
    mar.top <- 4
  }
  
  # 2 - Autocorrelation plot
  if (include.var.names) {
    par(mar=c(mar.for.varnames, 4*cex.y.axis.labels, mar.top, 2) + 0.1)
    image(x,y,z, axes=F, xlab="", ylab="Iteration", col=c("white", "black"), cex.lab=cex.y.axis.labels)
    tick.labels <- colnames(results$results)
    if (!is.null(var.dictionary)) {
      tick.labels[tick.labels%in%names(var.dictionary)] <- var.dictionary[tick.labels[tick.labels%in%names(var.dictionary)]]
    }
    axis(side=1, at=c(1:ncol(results$results)), labels=tick.labels, las=2, cex.axis=cex.x.axis.ticks)
  } else {
    par(mar=c(5, 4*cex.y.axis.labels, mar.top, 2) + 0.1)
    image(x,y,z, axes=F, xlab="Predictors", ylab="Iteration", col=c("white", "black"), cex.lab=cex.y.axis.labels)
    axis(side=1,at=c(0.5, (length(x)+0.5)),labels=rep("",2), cex.axis=cex.x.axis.ticks)
  }
  y.ticks <- seq(from=(results$args$iterations/2),to=results$args$iterations, by=0.5e6)
  y.tick.labs <- paste(y.ticks/1e6,"m",sep="")
  y.tick.labs[grep(".5m",y.tick.labs)] <- ""
  axis(side=2, at=y.ticks, labels=y.tick.labs, col.axis="black", cex.axis=cex.y.axis.ticks)
  
  # Close pdf
	if(!is.null(plot.file)) {
	  dev.off()
	}
	
}	
