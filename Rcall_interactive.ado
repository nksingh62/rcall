*cap prog drop Rcall_interactive

program define Rcall_interactive

	display  as txt "{hline 52} R (type {cmd:end} to exit) {hline}"
	scalar Rcall_counter = 0
	tempfile Rscript
	
	
	if "$Rcall_synchronize_mode" == "on" {
		Rcall_synchronize 	
		rcall: source("Rcall_synchronize")
		*local sync sync
		global Rcall_synchronize_mode2 "on"
		macro drop Rcall_synchronize_mode
	}
	
	
	while `"`macval(nextcommand)'"' != "end" {
		qui disp _request(_nextcommand)
		if `"`macval(nextcommand)'"' != "end" {
	
			global Rcall_interactive_mode on
			
			// Count opened brackets
			// -----------------------------------------------------------------
			Rcall_counter `nextcommand'
			
			// correct for the dollar sign
			local nextcommand: subinstr local nextcommand "$" "\$", all
			
			scalar Rcall_counter = Rcall_counter + r(Rcall_counter)
			
			if Rcall_counter == 0 {
				if missing("`tempfile'") {
					if trim(`"`macval(nextcommand)'"') != "" {
						rcall `sync': `nextcommand'
						macro drop Rcall_interactive_mode
					}	
				}
				else {
					file write `knot' `"`macval(nextcommand)'"' _n
					qui file close `knot'
					local tempfile 				//reset
					*quietly copy "`Rscript'" "mytemp.R", replace
					if trim(`"`macval(nextcommand)'"') != "" {
						rcall `sync': source("`Rscript'")
					}
					macro drop Rcall_interactive_mode
				}	
			}
			
			else {
				local indent = Rcall_counter - 1
				local a : display _dup(`indent') "    "
				display "`a'{bf:+}" 
				if missing("`tempfile'") {
					local tempfile 1
					tempname knot
					qui file open `knot' using "`Rscript'", write text replace
					file write `knot' `"`macval(nextcommand)'"' _n
				}
				else {
					file write `knot' `"`macval(nextcommand)'"' _n
				}
			}
		}	
	}
	
	else {
		display as txt "{hline}"
		
		macro drop Rcall_interactive_mode
		
		// Erase memory
		scalar drop Rcall_counter
		
		// if the interactive mode was also synchronized, define the marker
		global Rcall_synchronize_mode3 "on"
		if !missing("`debug'") di as err "set Rcall_synchronize_mode3 = $Rcall_synchronize_mode3"		
	}

end
