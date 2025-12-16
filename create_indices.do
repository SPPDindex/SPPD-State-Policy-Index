*******************************************************************************
***Date: December 16, 2025
***
***This file accompanies the article, "U.S. State Policy Index for Population
***Health Analyses," by Montez, Gutin, and Monnat, published in 
***The Milbank Quarterly. 
***
***The file reads the State Policy & Politics Database V1.3.1, extracts the 11 
***policies used for the SPPD State Policy Index, and creates the index. The
***annual index calculated here and in the article spans 1980 to 2023. 
***
***Current versions of the State Policy & Politics Database and annual updates
***of the policy index are posted on the Interuniversity Consortium for 
***Political and Social Research website at www.icpsr.umich.edu/sites/icpsr/home 
*******************************************************************************

clear

***set the working directory
cd "INSERT PATH TO THE WORKING DIRECTORY WHERE THE SPPD DATA ARE SAVED"

********************************************************************************
***STEP 1: read the State Policy & Politics Database and recode variables*******
********************************************************************************
 
***read the SPPD V1.3.1*********************************************************
use SPPD_V1_3.1.dta

***keep calendar years 1980-2023
drop if year < 1980 | year > 2023

***keep the state and year identifiers and the policies needed for the index
keep state year TANF2023 SNAP_2023 eitc rtw preempt_total psl ui_max_2023 /// 
     state_minwage_2023 CAP SYG RTC tobaccotax_2023 medicaidexp

***simplify and standardize the names of some policy variables
rename (TANF2023 SNAP_2023 ui_max_2023 state_minwage_2023 tobaccotax_2023 eitc rtw psl medicaidexp) (TANF SNAP UnempIns MinWage TobTax EITC RTW PSL Medicaid)

***replace the value of the Medicaid expansion variable from '.' to 0, which
***occurs in years before the ACA expansion
replace Medicaid = 0 if Medicaid == .

***convert these two vars so that a higher value reflects a more liberal orientation
gen LessPreemption = -1*preempt_total
gen NoRTW = 1 - RTW	

***create a restrictive firearm variable from CAP, SYG, and RTC
gen part1=0
replace part1=1 if CAP==1

gen part2=0
replace part2=1 if SYG==0

gen part3=0
replace part3=1 if RTC==0

gen Firearms = part1 + part2 + part3  


********************************************************************************
***STEP 2: normalize the 11 policy variables to range from 0 to 1 and then******
***sum the 11 scores for each state-year observation****************************
********************************************************************************

***list of variables to normalize
local vars TANF SNAP EITC MinWage PSL NoRTW UnempIns LessPreemption TobTax Firearms Medicaid

***loop through each variable and normalize the variable to 0-1 scale
foreach var of local vars {
    quietly summarize `var', meanonly
    gen norm_`var' = (`var' - r(min)) / (r(max) - r(min))
}

***sum the 11 policy scores
gen sum11policies = (norm_TANF + norm_SNAP + norm_EITC + norm_MinWage + norm_PSL + norm_NoRTW + norm_UnempIns + norm_LessPreemption + norm_TobTax + norm_Firearms + norm_Medicaid)

***sum the 10 policy scores (excludes Medicaid expansion)
gen sum10policies = (norm_TANF + norm_SNAP + norm_EITC + norm_MinWage + norm_PSL + norm_NoRTW + norm_UnempIns + norm_LessPreemption + norm_TobTax + norm_Firearms)

********************************************************************************
***STEP 3: normalize the sums of the policy scores******************************
********************************************************************************

***loop through each index and normalize it to a 0-1 scale
local vars sum11policies sum10policies
foreach var of local vars {
    quietly summarize `var', meanonly
    gen index_`var' = (`var' - r(min)) / (r(max) - r(min))
}

********************************************************************************
***STEP 4: prepare final dataset************************************************
********************************************************************************

**rename and label the two policy indices
rename index_sum11policies SPPDindex1
label variable SPPDindex1  "SPPD State Policy Index with 11 policies"

rename index_sum10policies SPPDindex2
label variable SPPDindex2  "SPPD State Policy Index with 10 policies (no Medicaid expansion)"

***display descriptive statistics of the normalized policies and two indices
sum norm* SPPDindex1 SPPDindex2

***save the final dataset with the state-year identifiers, 11 policies, and 2 indices
keep state year TANF SNAP EITC MinWage PSL NoRTW UnempIns LessPreemption TobTax Firearms Medicaid SPPDindex1 SPPDindex2
save polices_and_indices, replace



