#' Writes a data file in the format required for Java MCMC program
#' @export
#' @title Write Java MCMC format data file
#' @name .WriteData
#' @param data.file Desired path for .txt data file to be written to
#' @param likelihood Type of model to fit. Current options are "Logistic" (for binary data), "Weibull" (for survival data), 
#' and "Gaussian" (for continuous data).
#' @param data Matrix of data to write - rows indiviuals, columns variables.
#' @param predictors vector of predictors. Leave as the default NULL to include all variables available in the data.frame will be used.
#' @param outcome.var Which column in data contains the binary outcome for logistic and survival data, or the integer count for
#' Poisson data (default "Disease")
#' @param times.var If survival data or Poisson data, the column in data which contains the follow-up times (default NULL)
#' @param xTx GaussianMarg ONLY: List containing each block's plug-in estimate for X'X.
#' @param t GaussianMarg ONLY: Vector of quantities calculated from the summary statistics.
#' @param residual.var GaussianMarg ONLY: An estimate of the residual variance of the trait.
#' @param residual.var.n GaussianMarg ONLY: Sample size the residual variance estimate came from
#' @param block.indices If Guassian marginal tests are being analysed, the external xTx data may be divided
#' into blocks, to simplify inversion. This vector should contain the indices of the block break points (default NULL)
#' @param cluster.var If hierarchical data and random intercepts are required, the column in data contains the clustering variable (default NULL)
#' @param initial.model Optionally, an initial model can be provided as a vector of 0's and 1's. Default is NULL
#' and the null model is used. If set to 1, the saturated model is used.
#' @return NA
#' @author Paul Newcombe
.WriteData <- function(
  data.file,
  likelihood,
  data,
  predictors=NULL,
  confounders=NULL,
  outcome.var=NULL,
  times.var=NULL,
  xTx=NULL,
  t=NULL,
  residual.var=NULL,
  residual.var.n=NULL,  
  cluster.var=NULL,
  beta.priors=NULL,
  model.space.priors,
  initial.model=NULL
) {
	### Pre-processing
  if (!likelihood%in%c("GaussianMarg")) {
    n.start <- nrow(data)
    if (!is.null(predictors)) {
      data <- data[, c(outcome.var, times.var, cluster.var, predictors)]
    }
    for (v in colnames(data)) {
      data <- data[!is.na(data[,v]), ]
    }
    # Extract disease var
    disease <- data[,outcome.var]
    data <- data[, colnames(data)[!colnames(data)%in%c(outcome.var)] ]
    # Extract survival times var
    if (!is.null(times.var) ) {
      times <- data[,times.var]
      data <- data[, colnames(data)[!colnames(data)%in%times.var] ]
    }
    # Extract cluster var
    if (!is.null(cluster.var) ) {
      clusters <- as.integer(as.factor(as.integer(data[,cluster.var])))	# This makes range 1,..nClusters
      data <- data[, colnames(data)[!colnames(data)%in%cluster.var] ]
      n.clusters <- length(unique(clusters))
    }
    
    V <- ncol(data)
    N <- nrow(data)
    var.names <- colnames(data)
    cat(paste((n.start-N),"observations deleted due to missingness"))
  } else {
    V <- length(t)
    N <- 99
    var.names <- unlist(lapply(xTx,colnames))
    block.sizes <- unlist(lapply(xTx,ncol))
    block.indices <- rep(1,length(xTx)+1)
    for (b in 1:length(xTx)) {
      block.indices[b+1] <- block.indices[b] + block.sizes[b]
    }
  }
  
	### Writing
	# Model
  write(likelihood, file = data.file , ncolumns = 1)    
	# V: Total number of variables
	write(V, file = data.file , ncolumns = 1, append = T)
  # Varnames: Variable names
	write(var.names, file = data.file , ncolumns = V, append = T)
  # VnoRJ: Total number of variables (from the beginning) to be fixed in the model
	write(length(confounders), file = data.file , ncolumns = 1, append = T) 				# from which variable RJ is performed
  # N: Number of individuals
	write(N, file = data.file , ncolumns = 1, append = T)
  # R: Number of clusters
	if (!is.null(cluster.var) ) {
		write( n.clusters, file = data.file , ncolumns = 1, append = T)				
	} else {
		write(0, file = data.file , ncolumns = 1, append = T)		
	}
  # N x V matrix of covariate values
  cat("\n\nWriting a BGLiMS formatted datafile...\n")
  # Block indices
  if (likelihood %in% c("GaussianMarg")) {
    write(residual.var, file = data.file , ncolumns = 1, append = T)
    write(residual.var.n, file = data.file , ncolumns = 1, append = T)
    write(length(xTx), file = data.file , ncolumns = 1, append = T)
    write(block.indices, file = data.file , ncolumns = length(block.indices), append = T)
    for (b in 1:length(xTx)) {
      write.table(xTx[[b]], row.names=F, col.names=F, file = data.file, append = T)
    }
  } else {
    # Covariate data
    write.table(data, row.names=F, col.names=F, file = data.file , append = T)    
  }
  cat("... finished writing datafile.\n")
  # If R>0 the vector of cluster labels
	if (!is.null(cluster.var) ) {
		write(t(clusters), file = data.file , ncolumns = n.clusters, append = T)
	}
  # Vector of disease labels
  if (likelihood %in% c("Logistic", "Weibull")) {
    write(t(as.integer(disease)), file = data.file , ncolumns = N, append = T)    
  } else if (likelihood %in% c("Gaussian")) {
    write(t(disease), file = data.file , ncolumns = N, append = T)        
  } else if (likelihood %in% c("GaussianMarg")) {
    write(t(t), file = data.file , ncolumns = V, append = T)        
  }
  if (!is.null(times.var)) {
    write(t(times), file = data.file , ncolumns = N, append = T)    
  }
  
  ### --- Fixed beta priors
  use.unknown.priors <- TRUE
  if (is.null(beta.priors)) {
    write(0, file = data.file , ncolumns = 1, append = T)    
  } else {
    write(nrow(beta.priors), file = data.file , ncolumns = 1, append = T)
    for (v in 1:nrow(beta.priors)) {
      write( c(beta.priors[v,1],beta.priors[v,2]), file = data.file , ncolumns = 2, append = T)
    }
    if (nrow(beta.priors)==length(predictors)) {
      use.unknown.priors <- FALSE
    }
  }
  
  ### --- Shared unknown beta priors
  if (!use.unknown.priors) {
    # Fixed priors provided for everything, no need for common unknown prior
    write(0, file = data.file , ncolumns = 1, append = T)    
  } else {
    # Use common unknown priors for model space components
    write(length(model.space.priors), file = data.file , ncolumns = 1, append = T)
    if (length(model.space.priors)>1) {
      for (c in 1:(length(model.space.priors)-1)) {
        write(length(model.space.priors[[c]]$Variables), file = data.file , ncolumns = 1, append = T)      
      }
    }    
  }
  
  # Initial model
  if (is.null(initial.model)) {
    write(0, file = data.file , ncolumns = 1, append = T)    
  } else if (length(initial.model)==1) {
    write(initial.model, file = data.file , ncolumns = 1, append = T)    
  } else {
    write(2, file = data.file , ncolumns = 1, append = T)    
    write(t(initial.model), file = data.file , ncolumns = length(initial.model), append = T)    
  }  
}
