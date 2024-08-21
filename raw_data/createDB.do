global rawdata S:/DAL-LAD/LAD_DAL_Allyear_v6/data_donnees/stata
global temp "T:/Projet 3985-S023/Xavier/temp"
global input "T:/Projet 3985-S023/Xavier/input"
global output "T:/Projet 3985-S023/Xavier/output"
sysdir set PERSONAL "T:/Projet 3985-S023/ado"
net from "T:/Projet 3985-S023/ado/estout"
net install estout

* Import LAD 
{

forvalues x = 0/6{
	clear
	local y=1985+`x'
	local a=59+`x'
	use LIN__I CQPP_I`y' PRCO_I`y' AGE__I`y' YOD__I`y' IEMCOI`y' SXCO_I`y' EI___I`y' SOP4AI`y' DISDNI`y' MSTCOI`y' WGT2_I FCMP_I if inrange(AGE__I`y', 59,`a') using "$rawdata/lad_dal_`y'_f1_v1.dta", clear
	gen year=`y'
	rename *`y' *
	merge 1:1 LIN__I using "$rawdata/lad_dal_reg_`y'_f1_v1.dta", keepusing(lndyri) nogen keep(master match)
	save "$temp/subset_`y'", replace
}

forvalues x = 0/27{
	clear
	local y=1992+`x'
	local a=66+`x'
	use LIN__I CQPP_I`y' PRCO_I`y' AGE__I`y' YOD__I`y' IEMCOI`y' SXCO_I`y' EI___I`y' SOP4AI`y' DISDNI`y' MSTCOI`y' WGT2_I FCMP_I DSBCQI if inrange(AGE__I`y', 59,`a') using "$rawdata/lad_dal_`y'_f1_v1.dta", clear
	gen year=`y'
	rename *`y' *
	merge 1:1 LIN__I using "$rawdata/lad_dal_reg_`y'_f1_v1.dta", keepusing(lndyri) nogen keep(master match)
	save "$temp/subset_`y'", replace
}

clear
use lin__i cqpp_i2020 prco_i2020 age__i2020 yod__i2020 sxco_i2020 ei___i2020 iemcoi2020 sop4ai2020 disdni2020 mstcoi2020 wgt2_i fcmp_i dsbcqi if inrange(age__i2020, 65,95) using "$rawdata/lad_dal_2020_f1_v1.dta", clear
merge 1:1 lin__i using "$rawdata/lad_dal_reg_2020_f1_v1.dta", keepusing(lndyri) nogen keep(master match)
rename *, upper
rename LNDYRI, lower
rename *2020 *
gen year=2020
save "$temp/subset_2020", replace

clear	
append using "$temp/subset_1985" "$temp/subset_1986" "$temp/subset_1987" "$temp/subset_1988" "$temp/subset_1989" "$temp/subset_1990" "$temp/subset_1991" "$temp/subset_1992" "$temp/subset_1993" "$temp/subset_1994" "$temp/subset_1995" "$temp/subset_1996" "$temp/subset_1997" "$temp/subset_1998" "$temp/subset_1999" "$temp/subset_2000" "$temp/subset_2001" "$temp/subset_2002" "$temp/subset_2003" "$temp/subset_2004" "$temp/subset_2005" "$temp/subset_2006" "$temp/subset_2007" "$temp/subset_2008" "$temp/subset_2009" "$temp/subset_2010" "$temp/subset_2011" "$temp/subset_2012" "$temp/subset_2013" "$temp/subset_2014" "$temp/subset_2015" "$temp/subset_2016" "$temp/subset_2017" "$temp/subset_2018" "$temp/subset_2019" "$temp/subset_2020"
save "$input/alldata", replace

}

* Create DB 
{
	
use "$input/alldata", clear

* Determine age entry, and keep if <=59
sort LIN__I (year)
egen t_age=tag(LIN__I)
gen age_entry=AGE__I if t_age==1
by LIN__I: egen age_entry_=max(age_entry)
drop if age_entry_>59
tab age_entry_ //shoulb be only equal to 59
drop t_age age_entry

* Determine year of entry / exit in LAD
sort LIN__I (year)
egen tagent=tag(LIN__I)
gen entry=year if tagent==1
by LIN__I: egen YENTRY=max(entry)
label var YENTRY "First year observed"
gsort +LIN__I -year
egen tagexit=tag(LIN__I)
gen ext=year if tagexit==1
by LIN__I: egen YEXIT=max(ext)
label var YEXIT "Last year observed"
drop tagent entry tagexit ext

* Determine age at YEXIT
gen age_ex=AGE__I if YEXIT==year
by LIN__I: egen AGE_EXIT=max(age_ex)
label var AGE_EXIT "Age at last year observed"
drop age_ex

* Determine age of death
gen yob=YENTRY-59
gen aod=YOD__I - yob if YOD__I!=0
bys LIN__I: egen AD=max(aod)
label var AD "Age of death"
drop yob aod

* Determine status of individual (censored, dead, migrated out)
gen status=2 if AD!=. //dead
replace status=0 if AD==. //alive
replace status=1 if IEMCOI=="2" //migrated out
by LIN__I: egen STATUS=max(status)
recode STATUS (2=1) (1=2)
label var STATUS "=1 if dead, =2 if migrated out of Ca, =0 otherwise"
drop status

* Recode sex
gen SEX=1 if SXCO_I=="M"
replace SEX=0 if SXCO_I=="F"
label var SEX "1=M"

* Determine pension cleaned of disability benefits
replace DSBCQI=0 if DSBCQI==.
gen pension_pub=CQPP_I-DSBCQI if year>=1992
replace pension_pub=CQPP_I if year<1992
drop if pension_pub>0 & AGE__I==59
sort LIN__I year
gen tag=1 if pension_pub>0 & pension_pub[_n-1]==0 & pension_pub[_n+1]>pension_pub
gen ac=AGE__I if tag==1
bys LIN__I (year): egen AC=min(ac)
label var AC "Age at which pension is claimed"
//Determine pension at AC+1 to get the amount to discount, unless dies at AC+1, in which case the biggest of the amount at AC and AC+1 is used
bys LIN__I (year): gen m_pension=pension_pub[_n+1] if AGE__I==AC & AGE__I[_n+1]!=AD
egen tag2=tag(LIN__I) if AGE__I==AC & AGE__I[_n+1]==AD
bys LIN__I (year): egen id=max(tag2)
bys LIN__I (year): egen pension_part=max(pension_pub) if id==1
replace m_pension=pension_part if id==1
by LIN__I (year): egen mm_pension=max(m_pension)
//Determine year of the pension saved, to be matched with the proper MGA
sort LIN__I year
gen year_mga=year[_n+1] if AGE__I==AC & id==0
replace year_mga=year if AGE__I==AC & m_pension==pension_pub
replace year_mga=year[_n+1] if AGE__I==AC & m_pension==pension_pub[_n+1]
bys LIN__I (year): egen year_touse=max(year_mga)
//input mga
merge m:1 year using "$temp/mga", keepusing(mga) keep(match master) nogen
//divide pension by mga
gen pension_rel=mm_pension/mga if year==year_touse
label var pension_rel "Pension/mga"
drop pension_pub tag ac m_pension tag2 id pension_part mm_pension year_mga year_touse

* Determine average private pension amount
replace SOP4AI=. if SOP4AI==0
bys LIN__I (year): egen m_ppens=mean(SOP4AI)
label var m_ppens "Mean private pension"

* Dummy for disability
gen dis_d=DSBCQI>0

* Drop people that have received disability lump sums around the time of claiming
bys LIN__I year: gen tag=1 if DSBCQI>DSBCQI[_n+1] & DSBCQI!=0 & DSBCQI[_n+1]!=0 & inrange(AGE__I,59,65) & year>=1992
bys LIN__I (year): egen drop_id=max(tag)
drop if drop_id==1
drop tag


bys LIN__I year: gen tag=1 if SOP4AI<SOP4AI[_n+1] & SOP4AI!=0 & SOP4AI[_n+1]!=0



* Create indicator var marital status
gen mrt=1 if inlist(FCMP_I,1,2,5,8) & AC==AGE__I //married
replace mrt=0 if inlist(FCMP_I,3,4,-7)  & AC==AGE__I //divorced/single
replace mrt=2 if inlist(FCMP_I,-1,-2,-3,-4,-5,-6,-9)  & AC==AGE__I //widowed
label var mrt "MS 0=div/sgle 1=marr 2=wid"

* Save dataset
save "$temp/dataprecollapse", replace
use "$temp/dataprecollapse", clear

* Restrict sample
drop if age_entry_!=59
keep if inrange(AC,60,65)
drop if AGE_EXIT<66
keep if AD>=66 | AD==.
bys LIN__I (year): egen prov_id=mean(PRCO_I) if inrange(AGE__I,60,65)
bys LIN__I (year): egen prov_dr=max(prov_id)
keep if prov_dr==4
collapse AC YENTRY YEXIT AD STATUS AGE_EXIT SEX lndyri m_ppens WGT2_I (max) mrt pension_rel dis_d, by(LIN__I)
gen YOB=YENTRY-59
keep if SEX==0 | SEX==1
drop if AGE_EXIT>AD
keep if pension_rel!=.
label var YOB "Year of birth"
label var AD "Age of death"
label var AC "Age at which pension is claimed"
label var YENTRY "First year observed"
label var YEXIT "Last year observed"
label var STATUS "=1 if dead, =2 if migrated out of Ca, =0 otherwise"
label var AGE_EXIT "Age at last year observed"
label var SEX "=0 if female, =1 if male"
label var m_ppens "Mean private pension payment"
label var dis_d "Claimed disability"
label var lndyri "Immigrant landing year"
label var mrt "0=div/single 1=married 2=widowed"
label var pension_rel "Pension at AC+1 / mga"
save"$temp/cleandata2", replace
}


use "$temp/cleandata2", clear

* Gen var
{
* Bin pension
gen diff=AC-59
gen YCLAIM=YENTRY+diff
gen p_lvl=.
forv yclaim=1991/2014{
	forv ac=60/65{
		sort YCLAIM AC pension_rel
		xtile p_lvl_`yclaim'_`ac'=pension_rel if YCLAIM==`yclaim' & AC==`ac', nquantiles(5)
		replace p_lvl=p_lvl_`yclaim'_`ac' if YCLAIM==`yclaim' & AC==`ac'
		drop p_lvl_`yclaim'_`ac'
	}
}
forv yclaim=1986/1990{
	local diff=`yclaim'-1986
	local ac_up=60+`diff'
	forv ac=60/`ac_up'{
		sort YCLAIM AC pension_rel
		xtile p_lvl_`yclaim'_`ac'=pension_rel if YCLAIM==`yclaim' & AC==`ac', nquantiles(5)
		replace p_lvl=p_lvl_`yclaim'_`ac' if YCLAIM==`yclaim' & AC==`ac'
		drop p_lvl_`yclaim'_`ac'
	}
}
forv yclaim=2015/2019{
	local diff=`yclaim'-2014
	local ac_dwn=60+`diff'
	forv ac=`ac_dwn'/65{
		sort YCLAIM AC pension_rel
		xtile p_lvl_`yclaim'_`ac'=pension_rel if YCLAIM==`yclaim' & AC==`ac', nquantiles(5)
		replace p_lvl=p_lvl_`yclaim'_`ac' if YCLAIM==`yclaim' & AC==`ac'
		drop p_lvl_`yclaim'_`ac'
	}
}
* Bin private pension
gen pp_lvl=.
forv yob=1926/1954{
		sort YOB m_ppens
		xtile pp_lvl_`yob'=m_ppens if YOB==`yob', nquantiles(5)
		replace pp_lvl=pp_lvl_`yob' if YOB==`yob'
		drop pp_lvl_`yob'
}
replace pp_lvl=0 if m_ppens==.
* Cohort
egen coh=cut(YOB), at(1926,1930(5)1955)
* Immigrant status
replace lndyri=. if lndyri>YENTRY
gen imm_d=lndyri>0 & lndyri!=.
* YOD
gen YOD=YOB+AD if AD!=.
drop if YOD==2021
* Exit var
egen QUIT=rowmax(AGE_EXIT AD)
}

save "$temp/cleandata3", replace
use "$temp/cleandata3", clear

*Stset
stset QUIT, failure(STATUS==1) origin(time 65) enter(time 59) exit(time QUIT)


* Reg

//Whole sample
eststo spe1: streg ib(65).AC ib(1940).coh i.dis_d, distribution(gompertz)
estout r(table) using "$output/output.csv", replace delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.dis_d i.SEX, distribution(gompertz)
estout r(table) using "$output/output.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.dis_d i.SEX i.imm_d ib(0).mrt, distribution(gompertz)
estout r(table) using "$output/output.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.dis_d i.SEX i.imm_d ib(0).mrt ib(3).p_lvl, distribution(gompertz)
estout r(table) using "$output/output.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.dis_d i.SEX i.imm_d ib(0).mrt ib(3).p_lvl ib(3).pp_lvl, distribution(gompertz)
estout r(table) using "$output/output.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

//Without disability sample
preserve
keep if dis_d!=1

eststo spe1: streg ib(65).AC ib(1940).coh, distribution(gompertz)
estout r(table) using "$output/output2.csv", replace delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output2.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.SEX, distribution(gompertz)
estout r(table) using "$output/output2.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output2.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.SEX i.imm_d ib(0).mrt, distribution(gompertz)
estout r(table) using "$output/output2.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output2.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.SEX i.imm_d ib(0).mrt ib(3).p_lvl, distribution(gompertz)
estout r(table) using "$output/output2.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output2.csv", append delimiter(;) stats(N N_fail chi2) drop(*)

eststo spe1: streg ib(65).AC ib(1940).coh i.SEX i.imm_d ib(0).mrt ib(3).p_lvl ib(3).pp_lvl, distribution(gompertz)
estout r(table) using "$output/output2.csv", append delimiter(;) keep(b se z pvalue ll ul)
estout spe1 using "$output/output2.csv", append delimiter(;) stats(N N_fail chi2) drop(*)




*Summary statistics
{

//Weighted summary stats, whole sample
use "$temp/cleandata3", clear //this is individual-level unweighted data 

replace WGT2_I=WGT2_I*5 //this multiplies the weights by 5
foreach v in SEX AC coh imm_d mrt p_lvl pp_lvl dis_d {
preserve
collapse (sum) WGT2_I, by(`v') //This gives us counts that are weighted
save "$temp/`v'", replace
restore
}
use "$temp/SEX", clear
append using "$temp/AC" "$temp/coh" "$temp/imm_d" "$temp/mrt" "$temp/p_lvl" "$temp/pp_lvl" "$temp/dis_d"
save "$temp/des_stats", replace
export excel using "$output/des_stats.xls", firstrow(varlabels) replace

//Weighted summary stats, subsample of no disability
use "$temp/cleandata3", clear //this is individual-level unweighted data 

keep if dis_d==0
replace WGT2_I=WGT2_I*5 //this multiplies the weights by 5
foreach v in SEX AC coh imm_d mrt p_lvl pp_lvl {
preserve
collapse (sum) WGT2_I, by(`v') //This gives us counts that are weighted
save "$temp/`v'", replace
restore
}
use "$temp/SEX", clear
append using "$temp/AC" "$temp/coh" "$temp/imm_d" "$temp/mrt" "$temp/p_lvl" "$temp/pp_lvl"
save "$temp/des_stats", replace
export excel using "$output/des_stats2.xls", firstrow(varlabels) replace

//Unweighted summary stats, whole sample
use "$temp/cleandata3", clear //This is individual level unweighted data

foreach v in SEX AC coh imm_d mrt p_lvl pp_lvl dis_d {
preserve
collapse (count) WGT2_I, by(`v') //This counts individuals, still unweighted
save "$temp/`v'", replace
restore
}
use "$temp/SEX", clear
append using "$temp/AC" "$temp/coh" "$temp/imm_d" "$temp/mrt" "$temp/p_lvl" "$temp/pp_lvl" "$temp/dis_d"
save "$temp/des_stats", replace
export excel using "$output/des_stats_uw.xls", firstrow(varlabels) replace

//Unweighted summary stats, subsample of no disability
use "$temp/cleandata3", clear //This is individual level unweighted data

keep if dis_d==0
foreach v in SEX AC coh imm_d mrt p_lvl pp_lvl {
preserve
collapse (count) WGT2_I, by(`v') //This counts individuals, still unweighted
save "$temp/`v'", replace
restore
}
use "$temp/SEX", clear
append using "$temp/AC" "$temp/coh" "$temp/imm_d" "$temp/mrt" "$temp/p_lvl" "$temp/pp_lvl"
save "$temp/des_stats", replace
export excel using "$output/des_stats2_uw.xls", firstrow(varlabels) replace

}




	
	
	
	
	
	
	
	
	


