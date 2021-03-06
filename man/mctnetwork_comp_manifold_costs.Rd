% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mctnetwork.r
\name{mctnetwork_comp_manifold_costs}
\alias{mctnetwork_comp_manifold_costs}
\title{Compute and update manifold costs for a mc time network}
\usage{
mctnetwork_comp_manifold_costs(mct, t_exp = 1, T_cost = 1000)
}
\arguments{
\item{mct}{mct network object}

\item{t_exp}{time parameter for the markov exponential}

\item{T_cost}{threshold on the cost for retan}
}
\value{
an updated mct object
}
\description{
Compute and update manifold costs for a mc time network
}
