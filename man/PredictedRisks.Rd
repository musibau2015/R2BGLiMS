% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/PredictedRisks.R
\name{PredictedRisks}
\alias{PredictedRisks}
\title{Calculate predicted risks for new data}
\usage{
PredictedRisks(data, results, times.var = NULL, t = NULL,
  use.top.n.pred = NULL)
}
\arguments{
\item{data}{Matrix or dataframe containing the data to analyse. Rows are indiviuals, and columns are variables, named in concordance
with the following options.}

\item{results}{Reversible Jump results object from running \code{\link{R2BGLiMS}}.}

\item{times.var}{If survival data, the column in data which contains the event times (default NULL)}

\item{t}{If a Weibull model has been fitted, the length of time to calculate risks over}

\item{use.top.n.pred}{Generate predictions using only the predictors with the top N marginal posterior probabilities (that appear together). Default NULL to use all predictors}
}
\value{
A list including a vector of event risks, ordered as the rows of `data'
}
\description{
Calculates predicted risks for new data according to a RJMCMC logistic or Weibull regression analysis (for the latter
risks are provied for within a user specified time interval)
}
\author{
Paul Newcombe
}

