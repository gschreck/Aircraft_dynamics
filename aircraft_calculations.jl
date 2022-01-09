#=

	This file calculates various aircraft parameters
		horizontal stabilizer coefficient						August 20, 2021 	
		vertical stabilizer coefficient							September 11, 2021
		initial unit conversion, AR, Sw and MAC functions		October 1, 2021
		added AC calculations									October 7, 2021
		
=#

using DataFrames, ArgParse, Printf				# add functions
import XLSX										# add the Excel access routines

# data structure for keeping track of variables
mutable struct req_vars
		name  ::String
		value ::Float32
		units ::String
		stored::Int8
	end
	
include("aircraft_dynamics.jl")					# basic routines for dynamics calculations
include("aircraft_drag.jl")						# basic drag calculations		

#=  ###########################################################################################
	Parse the command line
	Useage: aircraft_calculations arguments
	Arguments:
			input_file_name is required
			-h or --help for help
			-o or --output_file filename (default no output)
			-s or --sheet_name is the name of the sheet to retrieve the data from
=#			
			
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--output_file", "-o"
            default = "null"
        "--sheet_name", "-s"
            default = "critical_data"			
        "input_file"
            help = "Excel spreadsheet name to read data from."
            required = true
    end

    return parse_args(s)
end

#   ###########################################################################################
#	Main function			

function main()

    parsed_args = parse_commandline() # parse the input arguments
	
	# assign the parsed arguments							
	AC_data = get(parsed_args, "input_file", "null")						# get the name of the input Excel filename
	output_file = get(parsed_args, "output_file", "null")					# get the name of the output file
	sheet_name = get(parsed_args, "sheet_name", "critical_data") 			# get the name of the sheet within the spreadsheet

	# read the Excel data into a matrix
	xf = XLSX.readxlsx(AC_data)												# open the aircraft data file
	df = (DataFrame(XLSX.readtable(AC_data, sheet_name)...))				# read the spreadsheet data into a data frame
	df_size=size(df)														# read the dataframe size
	
	if df_size[2] < 3														# check for at least 3 columns:  symbol, value, units
		print("\n\tError: Inadequate number of columns in spreadsheet!\n")	# print the error message if not enough columns
		exit(86)
	end

	## Call the routines that do the work on the input array and append result to data frame
	## Note that the order of these subroutines matters since later ones rely on results of
	## earlier calculations

	push!(df, ["Cg",  		Cg(df),			"m",   		"Center of gravity"])

	push!(df, ["cMAC",  	MAC(df),		"m",   		"Mean wing chord"])
	push!(df, ["Sw",    	Sw(df), 		"m^2", 		"Wing area"])
	push!(df, ["AR",    	AR(df),  		" ",   		"Wing aspect ratio"])
	push!(df, ["AC",    	AC(df),  		"m",   		"Wing AC from LE"])
	push!(df, ["d",			d(df),   		"m",   		"Wing MAC Distance to root"])	
	
	push!(df, ["cMACh", 	MACh(df), 		"m",   		"Horizontal stab mean chord"])	
	push!(df, ["Sht",   	Sht(df), 		"m^2", 		"Horizontal stab area"])
	push!(df, ["ARh",   	ARh(df), 		" ",   		"Horizontal stab aspect ratio"])
	push!(df, ["ACh",   	ACh(df),  		"m",   		"Horizontal stab AC from LE"])
	
	push!(df, ["cMACv", 	MACh(df), 		"m",   		"Vertical stab mean chord"])
	push!(df, ["Svt",   	Svt(df), 		"m^2", 		"Vertical stab area"])
	push!(df, ["ARv",   	ARv(df), 		" ",   		"Vertical stab aspect ratio"])
	push!(df, ["ACv",   	ACv(df),  		"m",   		"Vertical stab AC from LE"])
	
	push!(df, ["Lht",   	Lht(df), 		"m",   		"Length ACs of wing to h stab"])
	push!(df, ["Lvt",   	Lvt(df), 		"m",   		"Length ACs of wing to v stab"])
	push!(df, ["Cht",   	Cht(df), 		" ",   		"Coefficient of horizontal tail"])
	push!(df, ["Cvt",   	Cvt(df), 		" ",   		"Coefficient of vertical tail"])
	
	tup_1 = WL(df)
	push!(df, ["W",			tup_1[1],  		"kg",  		"Wing load (level flight)"])
	push!(df, ["Wh",		tup_1[2],  		"kg",  		"Horizontal stab load"])
	push!(df, ["Wload",    	Wload(df),  	"kg/m^2",   "Wing loading"])	

	push!(df, ["Vstall", 	Vstall(df), 	"m/s", 		"Wing stall speed"])	
	push!(df, ["Vhstall", 	Vhstall(df),	"m/s", 		"Horizontal stab stall speed"])
	
#	push!(df, ["c", 		c(df),			"m/s", 		"Speed of Sound"])

	
	drag_sim(df)

	# Print the dataframe
	print("\n\n", df)	
	
end

#   ###########################################################################################
#	Main function (called internally)

main()

print("\n\n\t>> End of Script <<\n")

#   ###########################################################################################
#	End

