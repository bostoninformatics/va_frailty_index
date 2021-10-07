# Code to compute the VA Frailty Index

## Overview

This repository contains code to calculate the VA Frailty Index based on ICD-9 and/or ICD-10 codes as described in the following paper:

> Cheng D, DuMontier C, Yildirim C, Charest B, Hawley C, Zhuo M, Paik J, Yaksic E, Gaziano JM, Do N, Brophy M, Cho K, Kim DH, Driver JA, Fillmore N, Orkaby AR. Updating and Validating the Veterans Affairs Frailty Index: Transitioning from ICD-9 to ICD-10. J Gerontol A Biol Sci Med Sci. 2021 Mar 9:glab071. doi: 10.1093/gerona/glab071. Epub ahead of print. PMID: 33693638.

Calculating the VA-FI requires the following steps:
- Step 1: Defining and index date and lookback period (typically 3 years) relative to which the VA-FI will be calculated.
- Step 2: Pulling diagnosis and procedure codes needed from the data source (within the VA, this is typically the VA Corporate Data Warehouse and possibly VA's CMS data).
- Step 3: Actually calculating the VA-FI based on the above.

This repo provides code to execute Step 3. Step 1 is inherently project specific and must be done by you. For Step 2, there are two options:

- Step 2, Option 1: You may pull diagnosis and procedure codes in a superset of the lookback period using your favorite method, e.g., writing a query in SQL Server Management Studio and downloading the results to a CSV file.
- Step 2, Option 2: For VA employees or WOCs, we can email you (at your VA.gov email address) a very efficient push-button code that we have already written to do steps 2 and 3 together. *This is the recommended option for internal VA users.* Email the senior authors Ariela Orkaby and Nathanael Fillmore (both emails are Firstname.Lastname@va.gov) and we will send you this code. 

In addition, if you'd like to reimplement Step 3 yourself for some reason, CSV versions of the code sets are available in icd_code_vafi_mapping.csv and procedure_code_vafi_mapping.csv. Note: Exercise caution if you edit these files in Excel. Opening the file and saving in Excel will likely corrupt ICD codes beginning or ending in 0s (e.g., 035.40 will be incorrectly rewritten as 35.4).

For further information or assistance with this code, please reach out to the authors.
