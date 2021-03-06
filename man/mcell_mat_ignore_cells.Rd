% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scmat.r
\name{mcell_mat_ignore_cells}
\alias{mcell_mat_ignore_cells}
\title{Generate a new matrix object with a given ignore cell list}
\usage{
mcell_mat_ignore_cells(new_mat_id, mat_id, ig_cells, reverse = F)
}
\arguments{
\item{new_mat_id}{id of matrix in scdb}

\item{mat_id}{existing matrix}

\item{ig_cells}{cells names to ignore}

\item{reverse}{set this to true to focus on cells instead of ignore them. False by default}
}
\description{
Generate a new matrix object with a given ignore cell list
}
