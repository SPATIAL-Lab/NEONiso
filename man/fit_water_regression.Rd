% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/reference_data_regression.R
\name{fit_water_regression}
\alias{fit_water_regression}
\title{fit_water_regression}
\usage{
fit_water_regression(stds, calibration_half_width, slope_tolerance, r2_thres)
}
\arguments{
\item{stds}{Reference data.frame from which to estimate
calibration parameters.}

\item{calibration_half_width}{Determines the period (in days)
from which reference data are selected (period
is 2*calibration_half_width).}

\item{slope_tolerance}{Allows for filtering of slopes that deviate
from 1 by slope_tolerance.}

\item{r2_thres}{What is the minimum r2 value permitted in a 'useful'
calibration relationship.}
}
\value{
Returns a data.frame of calibration parameters.
Output data.frame includes slope, intercept, and r^2 values
for d13C and CO2 values.
}
\description{
fit_water_regression
}
