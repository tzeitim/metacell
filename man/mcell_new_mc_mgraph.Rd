% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mgraph.r
\name{mcell_new_mc_mgraph}
\alias{mcell_new_mc_mgraph}
\title{Generate a new metacell manifold graph object}
\usage{
mcell_new_mc_mgraph(mgraph_id, mc_id, mgraph)
}
\arguments{
\item{mc_id}{id of scdb meta cell object ot be added}

\item{mgraph}{the mgraph data frame containing fields mc1, mc2, distance}
}
\description{
This constructs a meta cell manifold graph object - only encapsulating an edge list data frame
}
