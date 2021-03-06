% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mc.r
\name{mcell_new_mc}
\alias{mcell_new_mc}
\title{Generate a new metacell in scdb}
\usage{
mcell_new_mc(mc_id, mc, outliers, scmat)
}
\arguments{
\item{mc_id}{id of scdb meta cell object ot be added}

\item{mc}{assignment of metacell id to cell}

\item{outliers}{the list of outliers}

\item{scmat}{a single cell RNA matrix object}
}
\description{
This constructs a meta cell cover object and puts it into scdb. It gets an MC assignment (cell->MC_ID), and a matrix, and call standard api of this class to compute the footprints.
}
