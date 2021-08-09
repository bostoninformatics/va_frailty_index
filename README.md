# Code to compute the VA Frailty Index

## Overview

This repository contains code to calculate the VA Frailty Index based on ICD-9 and/or ICD-10 codes as described in the following paper:

> Cheng D, DuMontier C, Yildirim C, Charest B, Hawley C, Zhuo M, Paik J, Yaksic E, Gaziano JM, Do N, Brophy M, Cho K, Kim DH, Driver JA, Fillmore N, Orkaby AR. Updating and Validating the Veterans Affairs Frailty Index: Transitioning from ICD-9 to ICD-10. J Gerontol A Biol Sci Med Sci. 2021 Mar 9:glab071. doi: 10.1093/gerona/glab071. Epub ahead of print. PMID: 33693638.

In addition, CSV versions of the code sets are available in icd_code_vafi_mapping.csv and procedure_code_vafi_mapping.csv. Note: Exercise caution if you edit these files in Excel. Opening the file and saving in Excel will likely corrupt ICD codes beginning or ending in 0s (e.g., 035.40 will be incorrectly rewritten as 35.4).

For further information or assistance with this code, please reach out to the authors.
