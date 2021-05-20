#' Make VA Frailty Index
#'
#' The VA frailty index (vafi) is a quantitative measure to assess frailty.
#' The vafi is calculated by the sum of all deficits within x days_prior to
#' a specified index date divided by the total number of deficits (31).
#' More information about the vafi can be found in:
#'
#' Cheng D, DuMontier C, Yildirim C, Charest B, Hawley C, Zhuo M, Paik J,
#' Yaksic E, Gaziano JM, Do N, Brophy M, Cho K, Kim DH, Driver JA, Fillmore N,
#' Orkaby AR. Updating and Validating the Veterans Affairs Frailty Index:
#' Transitioning from ICD-9 to ICD-10. J Gerontol A Biol Sci Med Sci. 2021 Mar
#' 9:glab071. doi: 10.1093/gerona/glab071. Epub ahead of print. PMID: 33693638.
#'
#' Orkaby AR, Nussbaum L, Ho YL, Gagnon D, Quach L, Ward R, Quaden R, Yaksic E,
#' Harrington K, Paik JM, Kim DH, Wilson PW, Gaziano JM, Djousse L, Cho K, Driver
#' JA. The Burden of Frailty Among U.S. Veterans and Its Association With
#' Mortality, 2002-2012. J Gerontol A Biol Sci Med Sci. 2019 Jul
#' 12;74(8):1257-1264. doi: 10.1093/gerona/gly232. PMID: 30307533; PMCID:
#' PMC6625596.
#'
#' @param config The project configuration.
#'
#' @param index_date_tb A dataframe
#' with columns :
#' * PatientICN, character
#' * DateCol(Can be any name), date
#'
#' @param icds A dataframe of icd codes pulled from pull_icd_vafi
#' with columns :
#' * PatientICN, character
#' * ICDCode, character
#' * ICDCodeType, character
#' * Date, date
#'
#' @param prcd A dataframe of procedure codes pulled from pull_procedure_vafi
#' with columns:
#' * PatientICN, character
#' * ProcedureCode, character
#' * ProcedureCodeType, character
#' * Date, date
#'
#' @param index_date_col A string specifying the index date
#' column (DateCol)
#'
#' @param days_prior An integer specifying the number of days
#' prior to index date in which the vafi should be calculated.
#' Default is 3 * 365, or 3 years
#'
#' @param chunk_size An integer specifying how much to chunk
#' the icd and procedure codes by to calculate vafi.
#' Default is 1e6
#'
#' @return A dataframe with columns:
#' Note: Not all columns will be returned.
#' Only deficits found in the cohort
#' will appear. Deficits from AFIB to
#' WgtLoss are of data type integer
#' where 1 = TRUE and 0 = FALSE.
#' The reason why 1/0 is used rather
#' than TRUE/FALSE is because the original
#' author David Cheng used 1/0 and there
#' may be other downstream scripts that
#' rely on these deficits having 1/0
#' as their values rather than TRUE/FALSE
#' * PatientICN, character
#' * vafi, numeric
#' * AFIB (Atrial fibrillation), integer
#' * Anemia, integer
#' * Anxiety, integer
#' * Arthritis, integer
#' * CAD (Coronary artery disease), integer
#' * Cancer, integer
#' * Chronpain, integer
#' * CVA (cerebrovascular accident), integer
#' * Dementia, integer
#' * Depress, integer
#' * Diabetes, integer
#' * DuraMed (Durable medical device), integer
#' * Falls, integer
#' * Fatigue, integer
#' * FtoThrive (Failure to thrive), integer
#' * GaitAb (Abnormal gait), integer
#' * Hearing, integer
#' * HF (Heart failure), integer
#' * HTN (Hypertension), integer
#' * Incont (Incontinence), integer
#' * Kidney, integer
#' * Liver, integer
#' * Lung, integer
#' * Muscular, integer
#' * Osteo (Osteoporosis), integer
#' * PD (Parkinson's disease), integer
#' * PerNeuro (Peripheral neuropathy), integer
#' * PVD (Pulmonary vascular disease), integer
#' * Thyroid, integer
#' * Vision, integer
#' * WgtLoss, integer
make_vafi <- function(icds, prcd, index_date_tb,
                      index_date_col = "IndexDate",
                      days_prior = (3 * 365), chunk_size = 1e6) {
  index_date_tb[["IndexDate"]] <- index_date_tb[[index_date_col]]
  icds <- icds %>%
    dplyr::transmute(PatientICN,
      Code = ICDCode,
      CodeType = ICDCodeType,
      Date
    )
  icds <- .filter_icd_cutoff(icds)
  prcd <- prcd %>%
    dplyr::transmute(PatientICN,
      Code = ProcedureCode,
      CodeType = ProcedureCodeType,
      Date
    )
  prcd <- .filter_icd_cutoff(prcd)

  # These mappings were remapped to add the "." in David Cheng's mappings
  # which can be found if one loads deficitmappings.RData.
  # I believe these mappings were made from careful adjudication from
  # multiple medical collaborators, however Nate is probably best to
  # explain how the mappings were made.
  icd_mapping <- fst::read.fst("icd_code_vafi_mapping.fst")
  prcd_mapping <- fst::read.fst("procedure_code_vafi_mapping.fst")
  total_deficit <- length(
    unique(c(icd_mapping$Deficit, prcd_mapping$Deficit))
  )
  cat("Making deficits from icd codes \n")
  icd_dfct <- .make_deficit_chunk(chunk_size, icds, days_prior, index_date_tb, icd_mapping)
  cat("Making deficits from procedure codes \n")
  prcd_dfct <- .make_deficit_chunk(chunk_size, prcd, days_prior, index_date_tb, prcd_mapping)
  cat("Calculating vafi from icd and procedure codes\n")
  dfct <- list(icd_dfct, prcd_dfct) %>%
    dplyr::bind_rows() %>%
    dplyr::distinct() %>%
    dplyr::group_by(PatientICN) %>%
    dplyr::mutate(
      NumDeficit = dplyr::n(),
      vafi = NumDeficit / total_deficit,
      Value = 1
    ) %>%
    reshape2::dcast(PatientICN + vafi ~ Deficit, value.var = "Value") %>%
    # for those without any dfcts add them to dataframe
    dplyr::right_join(index_date_tb %>%
      dplyr::select(PatientICN), by = "PatientICN") %>%
    dplyr::mutate(vafi = ifelse(is.na(vafi), 0, vafi))

  dfct[is.na(dfct)] <- 0
  dfct
}

#' Filter ICD9 and ICD10 codes based on switch date
#'
#' ICD codes completely changed from ICD9 to ICD10 on 2015-10-01.
#' This function excludes all ICD9 codes after 2015-10-01
#' and all ICD10 codes before 2015-10-01
#'
#' @param config The project configuration.
#'
#' @param icd_df A dataframe of icd or procedure codes
#' with column names:
#' * PatientICN, character
#' * Code, character
#' * CodeType, character
#' * Date, date
#'
#' @return A dataframe with columns:
#' * PatientICN, character
#' * Code, character
#' * CodeType, character
#' * Date, date
#'
#' @noRd
.filter_icd_cutoff <- function(icd_df) {
  # All icd9 codes after 2015-10-01 and all icd10 codes before 2015-10-01
  switch_over_date <- "2015-10-01"
  icd_df <- icd_df %>%
    subset((grepl("ICD9", CodeType) & Date < switch_over_date) |
      (grepl("ICD10", CodeType) & Date >= switch_over_date) |
      CodeType == "CPT")
}

#' Chunking the deficit count
#'
#' This function chunks the icd or procedure code
#' dataframe and filters for codes within days_prior
#' to index date. Then the codes are mapped to deficits
#' for each given patient.
#'
#' @inheritParams make_vafi
#'
#' @inheritParams .filter_icd_cutoff
#'
#' @param mapping A dataframe mapping deficits to
#' codes with columns:
#' * Code, character
#' * CodeType, character
#' * NewCode, character
#' * Deficit, character
#'
#' @return A dataframe with columns:
#' * PatientICN, character
#' * Deficit, character
#'
#' @noRd
.make_deficit_chunk <- function(chunk_size, icd_df,
                                days_prior, index_date_tb, mapping) {
  n <- nrow(icd_df)
  result_icd <- pbapply::pblapply(seq(1, n, chunk_size), function(i_lo) {
    i_hi <- min(i_lo + chunk_size - 1, n)
    index_date_tb_sub <- icd_df[i_lo:i_hi, ] %>%
      dplyr::inner_join(index_date_tb, by = "PatientICN") %>%
      dplyr::mutate(
        IndexDate = lubridate::date(IndexDate),
        Date = lubridate::date(Date)
      ) %>%
      dplyr::filter(IndexDate >= Date) %>%
      dplyr::mutate(DateToIndex = as.numeric(IndexDate - Date)) %>%
      dplyr::filter(DateToIndex < days_prior) %>%
      dplyr::select(PatientICN, Code, CodeType) %>%
      dplyr::distinct() %>%
      dplyr::inner_join(mapping, by = c("Code", "CodeType")) %>%
      dplyr::select(PatientICN, Deficit) %>%
      dplyr::distinct()
  }) %>% dplyr::bind_rows()
}
