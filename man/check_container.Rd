% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper.R
\name{check_container}
\alias{check_container}
\title{Checks wether docker/apptainer are available and can be used}
\usage{
check_container(container = c("docker", "apptainer"))
}
\arguments{
\item{container}{The container for which the commands are tested}
}
\value{
A boolean value
}
\description{
Checks wether docker/apptainer are available and can be used
}
