% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MOMF.R
\name{build_model_momf}
\alias{build_model_momf}
\title{Calculates the signature model with MOMF}
\usage{
build_model_momf(
  single_cell_object,
  cell_type_annotations,
  bulk_gene_expression
)
}
\arguments{
\item{single_cell_object}{A matrix with the single-cell data. Rows are genes, columns are
samples. Row and column names need to be set.}

\item{cell_type_annotations}{A vector of the cell type annotations. Has to be in the same order
as the samples in single_cell_object.}

\item{bulk_gene_expression}{A matrix of bulk data. Rows are genes, columns are samples. Row and
column names need to be set.}
}
\value{
The signature matrix. Rows are genes, columns are cell types.
}
\description{
Calculates the signature model with MOMF
}
