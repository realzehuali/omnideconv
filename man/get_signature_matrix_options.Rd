% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CibersortX.R
\name{get_signature_matrix_options}
\alias{get_signature_matrix_options}
\title{Creation of the options of the "get signature matrix" docker command}
\usage{
get_signature_matrix_options(
  refsample,
  g_min = 300,
  g_max = 500,
  q_value = 0.01,
  filter = FALSE,
  k_max = 999,
  remake = FALSE,
  replicates = 5,
  sampling = 0.5,
  fraction = 0.75
)
}
\arguments{
\item{refsample}{The filename of the single cell data.}

\item{g_min}{\if{html}{\out{<int>}} Minimum number of genes per cell type in sig. matrix.}

\item{g_max}{\if{html}{\out{<int>}} Maximum number of genes per cell type in sig. matrix.}

\item{q_value}{\if{html}{\out{<int>}} Q-value threshold for differential expression.}

\item{filter}{\if{html}{\out{<bool>}} Remove non-hematopoietic genes.}

\item{k_max}{\if{html}{\out{<int>}} Maximum condition number. Will be added to the file name.}

\item{remake}{\if{html}{\out{<bool>}} Remake signature gene matrix.}

\item{replicates}{\if{html}{\out{<int>}} Number of replicates to use for building scRNAseq reference file.}

\item{sampling}{\if{html}{\out{<float>}} Fraction of available single cell GEPs selected using random sampling.}

\item{fraction}{\if{html}{\out{<float>}} Fraction of cells of same identity showing evidence of expression.}
}
\value{
A string in the correct format for the docker command, containing all parameters.
}
\description{
Creation of the options of the "get signature matrix" docker command
}
