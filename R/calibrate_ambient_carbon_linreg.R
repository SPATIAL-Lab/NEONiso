#' calibrate_ambient_carbon_linreg
#'
#' @author Rich Fiorella \email{rich.fiorella@@utah.edu}
#'
#' Function called by `calibrate_ambient_carbon_linreg` to apply
#' gain and offset parameters to the ambient datasets (000_0x0_09m and
#' 000_0x0_30m). This function should generally not be used independently,
#' but should be used with `calibrate_ambient_carbon_linreg`.
#'
#' @param amb_data_list List containing an ambient d13C dataset.
#'             Will include all variables in 000_0x0_xxm. (character)
#' @param caldf Calibration data frame containing gain and offset values for
#'             12C and 13C isotopologues.
#' @param outname Output variable name. Inherited from
#'             `calibrate_ambient_carbon_linreg`
#' @param site Four-letter NEON code corresponding to site being processed.
#' @param file Output file name. Inherited from
#'             `calibrate_ambient_carbon_linreg`
#' @param filter_data Apply median absolute deviation filter from Brock 86 to
#'             remove impulse spikes? Inherited from
#'             `calibrate_ambient_carbon_linreg`
#' @param force_to_end In given month, calibrate ambient data later than last
#'             calibration, using the last calibration? (default true)
#' @param force_to_beginning In given month, calibrate ambient data before than
#'             first calibration, using the first calibration? (default true)
#' @param r2_thres Minimum r2 value for calibration to be considered "good" and
#'             applied to ambient data.
#' @param gap_fill_parameters Should function attempt to 'gap-fill' across a 
#'            bad calibration by carrying the last known good calibration forward?
#'            Implementation is fairly primitive currently, as it only carries 
#'            the last known good calibration that's available forward rather
#'            than interpolating, etc. Default FALSE.
#'
#' @return Nothing to environment; returns calibrated ambient observations to
#'     the output file. This function is not designed to be called on its own,
#'     and is not exported to the namespace.
#'
#' @importFrom magrittr %>%
#'
calibrate_ambient_carbon_linreg <- function(amb_data_list,
                                            caldf,
                                            outname,
                                            site,
                                            file,
                                            filter_data = TRUE,
                                            force_to_end = TRUE,
                                            force_to_beginning = TRUE,
                                            gap_fill_parameters = FALSE,
                                            r2_thres = 0.9) {

    # only working on the d13C of the amb.data.list, so extract just this...
    d13C_ambdf <- amb_data_list$dlta13CCo2
    co2_ambdf  <- amb_data_list$rtioMoleDryCo2

    # ensure that time variables are in POSIXct.
    amb_start_times <- convert_NEONhdf5_to_POSIXct_time(d13C_ambdf$timeBgn)
    amb_end_times   <- convert_NEONhdf5_to_POSIXct_time(d13C_ambdf$timeEnd)

    # if force.to.end and/or force.to.beginning are true,
    # match out$start[1] to min(amb time)
    # and/or out$end[nrow] to max(amb time)

    if (force_to_end == TRUE) {
      caldf$end[nrow(caldf)] <- amb_end_times[length(amb_end_times)]
    }
    if (force_to_beginning == TRUE) {
      caldf$start[1] <- amb_start_times[1]
    }

    # determine which cal period each ambient data belongs to.
    var_inds_in_calperiod <- list()

    for (i in 1:nrow(caldf)) {
      int <- lubridate::interval(caldf$timeBgn[i], caldf$timeEnd[i])
      var_inds_in_calperiod[[i]] <- which(amb_end_times %within% int)

      if (gap_fill_parameters) {      
        
        # print notice that we're gap filling
        print("Gap filling calibrations...")
        
        if (!is.na(caldf$d13C_r2[i]) & caldf$d13C_r2[i] < r2_thres) {
          # if we're in calibration period 2 or later, carry previous
          # calibration period forward. else if the first calibration period
          # is bad, find the first good calibration period at index n,
          # and apply to first n periods.
          if (i > 1) {
            caldf$d13C_slope[i] <- caldf$d13C_slope[i - 1]
            caldf$d13C_intercept[i] <- caldf$d13C_intercept[i - 1]
            caldf$d13C_r2[i] <- caldf$d13C_r2[i - 1]
          } else { # i = 1, and need to find first good value.
            first_good_val <- min(which(caldf$d13C_r2 > r2_thres))
            caldf$d13C_slope[i] <- caldf$d13C_slope[first_good_val]
            caldf$d13C_intercept[i] <- caldf$d13C_intercept[first_good_val]
            caldf$d13C_r2[i] <- caldf$d13C_r2[first_good_val]
          }
        }
        
        # apply same logic to CO2 calibration.
        if (!is.na(caldf$co2_r2[i]) & caldf$co2_r2[i] < r2_thres) {
          if (i > 1) {
            caldf$co2_slope[i] <- caldf$co2_slope[i - 1]
            caldf$co2_intercept[i] <- caldf$co2_intercept[i - 1]
            caldf$co2_r2[i] <- caldf$co2_r2[i - 1]
          } else {
            first_good_val <- min(which(caldf$co2_r2 > r2_thres))
            caldf$co2_slope[i] <- caldf$co2_slope[first_good_val]
            caldf$co2_intercept[i] <- caldf$co2_intercept[first_good_val]
            caldf$co2_r2[i] <- caldf$co2_r2[first_good_val]
          }
        }
      }
    }

    # calibrate data at this height.
    #-------------------------------------
    # extract d13C and CO2 concentrations from the ambient data
    d13C_ambdf$mean_cal <- d13C_ambdf$mean
    co2_ambdf$mean_cal  <- co2_ambdf$mean

    for (i in 1:length(var_inds_in_calperiod)) {

      d13C_ambdf$mean_cal[var_inds_in_calperiod[[i]]] <- caldf$d13C_intercept[i] +
        d13C_ambdf$mean[var_inds_in_calperiod[[i]]] * caldf$d13C_slope[i]

      d13C_ambdf$min[var_inds_in_calperiod[[i]]]  <- caldf$d13C_intercept[i] +
        d13C_ambdf$min[var_inds_in_calperiod[[i]]] * caldf$d13C_slope[i]

      d13C_ambdf$max[var_inds_in_calperiod[[i]]]  <- caldf$d13C_intercept[i] +
        d13C_ambdf$max[var_inds_in_calperiod[[i]]] * caldf$d13C_slope[i]

      co2_ambdf$mean_cal[var_inds_in_calperiod[[i]]] <- caldf$co2_intercept[i] +
        co2_ambdf$mean[var_inds_in_calperiod[[i]]] * caldf$co2_slope[i]

      co2_ambdf$min[var_inds_in_calperiod[[i]]]  <- caldf$co2_intercept[i] +
        co2_ambdf$min[var_inds_in_calperiod[[i]]] * caldf$co2_slope[i]

      co2_ambdf$max[var_inds_in_calperiod[[i]]]  <- caldf$co2_intercept[i] +
        co2_ambdf$max[var_inds_in_calperiod[[i]]] * caldf$co2_slope[i]

    }

    # round variance down to 2 digits
    d13C_ambdf$vari <- round(d13C_ambdf$vari, digits = 2)
    co2_ambdf$vari <- round(co2_ambdf$vari, digits = 2)

    # apply median filter to data
    if (filter_data == TRUE) {
      
      d13C_ambdf$mean_cal <- filter_median_Brock86(d13C_ambdf$mean_cal)
      d13C_ambdf$min      <- filter_median_Brock86(d13C_ambdf$min)
      d13C_ambdf$max      <- filter_median_Brock86(d13C_ambdf$max)
      
      co2_ambdf$mean_cal <- filter_median_Brock86(co2_ambdf$mean_cal)
      co2_ambdf$min      <- filter_median_Brock86(co2_ambdf$min)
      co2_ambdf$max      <- filter_median_Brock86(co2_ambdf$max)

    }
    
    # replace ambdf in amb.data.list, return amb.data.list
    amb_data_list$dlta13CCo2 <- d13C_ambdf
    amb_data_list$rtioMoleDryCo2 <- co2_ambdf

    return(amb_data_list)

}
