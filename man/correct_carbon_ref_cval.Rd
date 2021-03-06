% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/standard_corrections.R
\name{correct_carbon_ref_cval}
\alias{correct_carbon_ref_cval}
\title{correct_carbon_ref_cval}
\usage{
correct_carbon_ref_cval(std_frame, site)
}
\arguments{
\item{std_frame}{Standard data frame to perform swap on.}

\item{site}{NEON four letter site code.}
}
\value{
A data.frame, based on \code{std_frame}, where NEON-supplied
reference values have been corrected if a mismatch has previously
been identified.
}
\description{
This ugly function is present out of necessity, and will
only exist for as long as it is necessary. It is an internal
correction within the NEONiso calibration routines that is
required as there are some mismatches between the 'true'
isotope reference values and those in the NEON HDF5 files.
NEON is working on correcting this, and after it has been
corrected, this function has no need to exist and will be
immediately deprecated. As a result, this function is
fairly messy but there is little incentive to improve it.
}
\author{
Rich Fiorella \email{rich.fiorella@utah.edu}
}
