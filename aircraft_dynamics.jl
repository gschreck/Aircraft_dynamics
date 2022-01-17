#
# This file is the beginning a compilation of useful aerodynamic calculations
#
# August 20, 2021 		Initial code
# September 11, 2021		Added horizontal and vertical stabilizer volume ratios
# September 12, 2021		Restructured code to add the "Extract_data function"
# October 1, 2021		Data Conversions, AR, Sw and MAC functions added
# October 7, 2021		AC calculations	
# October 22, 2021		Added conversion to Newtons and stall speed calculation
# October 23, 2021		Added Cg, wing loading and wing load 
#
# This code is licensed under MIT license (see LICENSE.txt for details)

	#-------------------------- Data Conversion Dictionaries ---------------------------#

# convert arbitrary units to meters
To_meters 	 = Dict("in" => 0.0254, "ft" => 0.3048, "yd" => 0.9144, "cm" => 0.01)	
To_sq_meters = Dict("in^2" => 0.00064516, "ft^2" => 0.092903, "yd^2" => 0.836127, "cm^2" => 0.0001)
To_N		 = Dict("kg" => 9.80665, "lbs" => 4.448221615)
To_kg		 = Dict("lb" => 0.453592, "N" => 0.1019716213)
To_kgm		 = Dict("in lb" => 0.01152125)
	
	#--------------------------------- Extract Data ------------------------------------#
	# This is a helper function to pull data from the input matrix, load it into the 
	# working structure and check the data for presnece.   
	# This function also attempts to convert all units to metric
	
function Extract_data(df, var_array)	
	# load the data into the structure
	df_rows = size(df)

	for i = 1:df_rows[1]												# read all lines up to the maximum row count
		for j in eachindex(var_array)
			if var_array[j].name == df[i,1]									# look for first value
				var_array[j].value = df[i,2]								# load data from spreadsheet into structure

				if df[i,3] != var_array[j].units							# check the units to make sure they match

					# this series of if statements could be collapsed, but the result was difficult to read
					if (var_array[j].units == "m")
						if (get(To_meters, df[i,3], 0) != 0)					# check to see if scale factor exists
							corrected_value = df[i,2] * To_meters[df[i,3]]
							@printf("\n>>> Converted %2.2f %s to %2.2f m", df[i,2], df[i,3], corrected_value)
							df[i,2] = corrected_value					# update the data structure with the updated value
							df[i,3] = "m"							# update the data structure with the updated units
							var_array[j].value = df[i,2]					# update the data being returned
						else
							print("\nError: Could not convert unit type = \"", df[i,3], "\"\n")	
							exit(86)							# variable units are incorrect, stop the program
						end	
					
					elseif (var_array[j].units == "m^2")
						if (get(To_sq_meters, df[i,3], 0) != 0)					# check to see if scale factor exists
							corrected_value = df[i,2] * To_sq_meters[df[i,3]]
							@printf("\n>>> Converted %2.2f %s to %2.2f m^2", df[i,2], df[i,3], corrected_value)
							df[i,2] = corrected_value					# update the data structure with the updated value
							df[i,3] = "m^2"							# update the data structure with the updated units
							var_array[j].value = df[i,2]					# update the data being returned
						else
							print("\nError: Could not convert unit type = \"", df[i,3], "\"\n")	
							exit(86)							# variable units are incorrect, stop the program
						end	
					
					elseif (var_array[j].units == "N")
						if (get(To_N, df[i,3], 0) != 0)						# check to see if scale factor exists
							corrected_value = df[i,2] * To_N[df[i,3]]
							@printf("\n>>> Converted %2.2f %s to %2.2f N", df[i,2], df[i,3], corrected_value)
							df[i,2] = corrected_value					# update the data structure with the updated value
							df[i,3] = "N"							# update the data structure with the updated units
							var_array[j].value = df[i,2]					# update the data being returned
						else
							print("\nError: Could not convert unit type = \"", df[i,3], "\"\n")	
							exit(86)							# variable units are incorrect, stop the program
						end	

					elseif (var_array[j].units == "kg")
						if (get(To_kg, df[i,3], 0) != 0)					# check to see if scale factor exists
							corrected_value = df[i,2] * To_kg[df[i,3]]
							@printf("\n>>> Converted %2.2f %s to %2.2f kg", df[i,2], df[i,3], corrected_value)
							df[i,2] = corrected_value					# update the data structure with the updated value
							df[i,3] = "kg"							# update the data structure with the updated units
							var_array[j].value = df[i,2]					# update the data being returned
						else
							print("\nError: Could not convert unit type = \"", df[i,3], "\"\n")	
							exit(86)							# variable units are incorrect, stop the program
						end	

					elseif (var_array[j].units == "kgm")
						if (get(To_kgm, df[i,3], 0) != 0)					# check to see if scale factor exists
							corrected_value = df[i,2] * To_kgm[df[i,3]]
							@printf("\n>>> Converted %2.2f %s to %2.2f kgm", df[i,2], df[i,3], corrected_value)
							df[i,2] = corrected_value					# update the data structure with the updated value
							df[i,3] = "kgm"							# update the data structure with the updated units
							var_array[j].value = df[i,2]					# update the data being returned
						else
							print("\nError: Could not convert unit type = \"", df[i,3], "\"\n")	
							exit(86)							# variable units are incorrect, stop the program
						end	

					# note this is a special case since it is more than just multiplying by a coefficient
					elseif (var_array[j].units == "C")
					
						if (df[i,3] == "F")							# check to see if scale factor exists
							corrected_value = (df[i,2] - 32) * (5/9)
							@printf("\n>>> Converted %2.2f %s to %2.2f C", df[i,2], df[i,3], corrected_value)
							df[i,2] = corrected_value					# update the data structure with the updated value
							df[i,3] = "C"							# update the data structure with the updated units
							var_array[j].value = df[i,2]					# update the data being returned							
							
						elseif (df[i,3] == "K")
							corrected_value = df[i,2] - 273.15
							@printf("\n>>> Converted %2.2f %s to %2.2f C", df[i,2], df[i,3], corrected_value)
							df[i,2] = corrected_value					# update the data structure with the updated value
							df[i,3] = "C"							# update the data structure with the updated units
							var_array[j].value = df[i,2]					# update the data being returned	
						
#						elseif (df[i,3] == "C")
#							print("\n Celsius\n")						
							
						else
							print("\nError: Could not convert unit type = \"", df[i,3], "\"\n")	
							exit(86)							# variable units are incorrect, stop the program
						end
						
					else					
						print("\nInternal Error: ", var_array[j].name, " unknown units!!\n")	# report unit mismatch error
						
						exit(86)								# variable units are incorrect, stop the program
					end									
				end
				
			var_array[j].stored = 1										# data was loaded into this variable			
			end
		end
	end		

	# Check for missing variables in the return data
	for j in eachindex(var_array)
		if var_array[j].stored != 1
			print("\nError: ", var_array[j].name, " value is missing!\nExiting\n")
			exit(86)								
		end		
	end		
	
	return  				# note the array was passed in so no additional return pointer is needed	
end

#================================================================================================================#


	#---------------------------------- Wing Loading (Wload) -------------------------------------#

function Wload(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	W  		= req_vars("W",  	0, "kg", 	0)	# W = weight - a vector defined as the product of mass and acceleration
	Sw	   	= req_vars("Sw",	0, "m^2",	0)	# Surface area reference wing	
	
	var_array = [W, Sw]						# Array of structures to enable easy iteration	

	Extract_data(df, var_array)					# Loads the array of structures with data, checks units and presence
	
	return (W.value / Sw.value)
end


	#----------------------------------- Wing Load  (WL) ----------------------------------------#

function WL(df)	

	# define structures to hold definitions for the call: (name, value, units, stored)
	m  	   = req_vars("m",  	0, "kg", 	0)		# m = mass
	Cg	   = req_vars("Cg",	0, "m",		0)		# Cg location from nose
	lwdle  	   = req_vars("lwdle",  0, "m", 	0)		# Distance datum (nose) to wing LE
	lhdle  	   = req_vars("lhdle",  0, "m", 	0)		# Distance datum (nose) to horizontal stab LE
	AC	   = req_vars("AC",	0, "m",		0)		# Distance from wing LE to AC
	ACh	   = req_vars("ACh",	0, "m",		0)		# Distance from horizontal stab LE to AC
	
	var_array = [m, Cg, lwdle, lhdle, AC, ACh]			# Array of structures to enable easy iteration	

	Extract_data(df, var_array)					# Loads the array of structures with data, checks units and presence
	
	moment_1 = ((lwdle.value + AC.value) - Cg.value) * m.value
	tail_down_force = moment_1 / ((lhdle.value + ACh.value) - (lwdle.value + AC.value))

	return ((m.value + tail_down_force), tail_down_force)
end

	#-------------------------------- Center of Gravity (Cg) ------------------------------------#

function Cg(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	m  	= req_vars("m",  	0, "kg", 	0)		# m = mass
	M  	= req_vars("M",  	0, "kgm", 	0)		# M = moment kg meters
	
	var_array = [m, M]						# Array of structures to enable easy iteration	

	Extract_data(df, var_array)					# Loads the array of structures with data, checks units and presence

	return (M.value / m.value)
end

	#--------------------- Horizontal Stabilizer Stall Speed (Vhstall) ------------------------#

function Vhstall(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	Wh  	= req_vars("Wh",  	0,  "N", 	0)		# W = weight - a vector defined as the product of mass and acceleration (newtons)
	Clh  	= req_vars("Clh",  	0,  "kg/m^3",	0)		# Coefficient of lift
	Sht	= req_vars("Sht",	0,  "m^2",	0)		# Stabilizer surface area	
	
	var_array = [Wh, Clh, Sht]					# Array of structures to enable easy iteration	

	Extract_data(df, var_array)					# Loads the array of structures with data, checks units and presence
	
	ρ = 1.225							# freestream density of air - mass/unit volume of air upstream of a body
	
	intermediate_value = (2 * Wh.value) /  (ρ * Sht.value * Clh.value)

	return (sqrt(intermediate_value))
end

	#----------------------------- Wing Stall Speed (Vstall) ---------------------------------#

function Vstall(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	W  	= req_vars("W",  	0, "N", 	0)	# W = weight - a vector defined as the product of mass and acceleration (newtons)
	Cl  	= req_vars("Cl",  	0, "kg/m^3", 	0)	# Coefficient of lift
	Sw   	= req_vars("Sw",	0, "m^2",	0)	# Surface area reference wing	
	
	var_array = [W, Cl, Sw]					# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and presence
	
	ρ = 1.225						# freestream density of air - mass/unit volume of air upstream of a body
	
	intermediate_value = (2 * W.value) /  (ρ * Sw.value * Cl.value)

	return (sqrt(intermediate_value))
end


	#--------------- Distance between AC of Wing and Vertical Stab (Lvt) -------------------#

function Lvt(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	lwdle	= req_vars("lwdle",	0, "m", 0)		# Distance datum (nose) to wing LE
	lvdle	= req_vars("lvdle",	0, "m", 0)		# Distance datum (nose) to vertical stab LE
	AC	= req_vars("AC",	0, "m",	0)		# Distance from wing LE to AC
	ACv	= req_vars("ACv",	0, "m",	0)		# Distance from horizontal stab LE to AC	
	
	var_array = [lwdle, lvdle, AC, ACv]			# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and presence
	
	return (abs((lvdle.value + ACv.value) - (lwdle.value + AC.value)))
end


	#--------------- Distance between AC of Wing and Horizontal Stab (Lht) -------------------#

function Lht(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	lwdle  	= req_vars("lwdle",  	0, "m", 0)		# Distance datum (nose) to wing LE
	lhdle  	= req_vars("lhdle",  	0, "m", 0)		# Distance datum (nose) to horizontal stab LE
	AC	= req_vars("AC",	0, "m",	0)		# Distance from wing LE to AC
	ACh	= req_vars("ACh",	0, "m",	0)		# Distance from horizontal stab LE to AC	
	
	var_array = [lwdle, lhdle, AC, ACh]			# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence
	
	return (abs((lhdle.value + ACh.value) - (lwdle.value + AC.value)))
end


	#----------------- Vertical Stab Aerodynamic Center Calculation (ACv) --------------------#

function ACv(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	λv	  = req_vars("λv",    0, "degrees", 	0)	# Vertical stab sweep angle
	bv	  = req_vars("bv",    0, "m",   	0)	# Vertical stab span 
	cMACv	  = req_vars("cMACv", 0, "m",   	0)	# Vertical stab chord
	Crv	  = req_vars("Crv",   0, "m",   	0)	# Vertical stab root chord
	Ctv	  = req_vars("Ctv",   0, "m",   	0)	# Vertical stab tip chord
	
	var_array = [λv, bv, cMACv, Crv, Ctv]			# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence

	S = tan(deg2rad(λv.value))*bv.value/2						# Wing sweep distance from 0 sweep LE
	C = (S * (Crv.value + (2 * Ctv.value))) / (3 * (Crv.value + Ctv.value))		# Chord setback from 0 sweep LE
	
	return (C + (cMACv.value * 0.25))
end


	#------------ Vertical Stab Mean Aerodynamic Chord Calculation (cMACv) ----------------#

function MACv(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	Ctv  = req_vars("Ctv",  0, "m", 0)			# Vertical stab tip chord
	Crv  = req_vars("Crv",  0, "m",   0)			# Vertical stab root chord	
	
	var_array = [Ctv, Crv]					# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence
	
	taper_ratio = Ctv.value / Crv.value			# Taper ratio
	return (Crv.value*(2/3)*((1 + taper_ratio + taper_ratio^2)/(1+taper_ratio)))
end


	#------------ Horizontal Stab Mean Aerodynamic Chord Calculation (cMACh) ----------------#

function MACh(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	Cth  = req_vars("Cth",  0, "m",   0)			# Horizontal stab tip chord
	Crh  = req_vars("Crh",  0, "m",   0)			# Horizontal stab root chord	
	
	var_array = [Cth, Crh]					# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence
	
	taper_ratio = Cth.value / Crh.value			# Taper ratio
	return (Crh.value*(2/3)*((1 + taper_ratio + taper_ratio^2)/(1+taper_ratio)))
end


	#------------- Horizontal Stabilizer Aerodynamic Center Calculation (ACh) ---------------#

function ACh(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	λh	  = req_vars("λh",    0, "degrees", 	0)		# Horizontal Stab sweep angle
	bh	  = req_vars("bh",    0, "m",		0)		# Horizontal Stab span 
	cMACh	  = req_vars("cMACh", 0, "m",   	0)		# Mean horizontal stab chord
	Crh	  = req_vars("Crh",   0, "m",		0)		# Horizontal stab root chord
	Cth	  = req_vars("Cth",   0, "m",   	0)		# Horizontal stab tip chord
	
	var_array = [λh, bh, cMACh, Crh, Cth]				# Array of structures to enable easy iteration	

	Extract_data(df, var_array)					# Loads the array of structures with data, checks units and prenence

	S = tan(deg2rad(λh.value))*bh.value/2						# Wing sweep distance from 0 sweep LE
	C = (S * (Crh.value + (2 * Cth.value))) / (3 * (Crh.value + Cth.value))		# Chord setback from 0 sweep LE
	
	return (C + (cMACh.value * 0.25))
end

	#------------------------ Wing MAC distance from Chord (d) ----------------------------#

function d(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	b	 = req_vars("b",   0, "m",   0)			# Wing span 
	Cr	 = req_vars("Cr",  0, "m",   0)			# Wing root chord
	Ct	 = req_vars("Ct",  0, "m",   0)			# Wing tip chord
	
	var_array = [b, Cr, Ct]					# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence

	return ((b.value*((0.5*Cr.value)+Ct.value)) / (3 * (Cr.value+Ct.value)))
end

	#---------------------- Wing Aerodynamic Center Calculation (AC) ----------------------#

function AC(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	λ    	 = req_vars("λ",    0, "degrees", 0)		# Wing sweep angle
	b	 = req_vars("b",    0, "m",   	0)		# Wing span 
	cMAC 	 = req_vars("cMAC", 0, "m",   	0)		# Mean wing chord
	Cr	 = req_vars("Cr",   0, "m",   	0)		# Wing root chord
	Ct	 = req_vars("Ct",   0, "m",   	0)		# Wing tip chord
	
	var_array = [λ, b, cMAC, Cr, Ct]			# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence

	S = tan(deg2rad(λ.value))*b.value/2						# Wing sweep distance from 0 sweep LE
	C = (S * (Cr.value + (2 * Ct.value))) / (3 * (Cr.value + Ct.value))		# Chord setback from 0 sweep LE
	
	return (C + (cMAC.value * 0.25))
end

	#------------------- Vertical Stab Aspect Ratio Calculation (AR) ---------------------#

function ARv(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	Svt 	= req_vars("Svt",  0, "m^2", 0)			# Vertical stab area
	bv	= req_vars("bv",   0, "m",   0)			# Vertical stab span
	Nv	= req_vars("Nv",   0, "count",  0)		# Number of vertical stabs
	
	var_array = [Nv, Svt, bv]				# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence
	
	return (((bv.value^2)*Nv.value)/Svt.value)
end

	#----------------------- Vertical Stab Area Calculation (Svt) ----------------------#

function Svt(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	bv	= req_vars("bv",   0, "m",   	0)		# Wing span 
	Crv	= req_vars("Crv",  0, "m",   	0)		# Wing root chord
	Ctv	= req_vars("Ctv",  0, "m",  	0)		# Wing tip chord
	Nv	= req_vars("Nv",   0, "count",  0)		# Number of vertical stabs

	var_array = [Nv, bv, Crv, Ctv]				# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence

	average_chord = (Crv.value + Ctv.value)/2

	return (Nv.value*bv.value*average_chord)
end


	#------------------- Horizontal Stab Aspect Ratio Calculation (AR) ---------------------#

function ARh(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	Sht = req_vars("Sht",  0, "m^2", 0)		# Wing area
	bh	= req_vars("bh",   0, "m",   0)		# Wing span 
	
	var_array = [Sht, bh]				# Array of structures to enable easy iteration	

	Extract_data(df, var_array)			# Loads the array of structures with data, checks units and prenence
	
	return ((bh.value^2)/Sht.value)
end

	#----------------------- Horizontal Stab Area Calculation (Swh) ----------------------#

function Sht(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	bh	= req_vars("bh",   0, "m",   0)		# Wing span 
	Crh	= req_vars("Crh",  0, "m",   0)		# Wing root chord
	Cth	= req_vars("Cth",  0, "m",   0)		# Wing tip chord

	var_array = [bh, Crh, Cth]			# Array of structures to enable easy iteration	

	Extract_data(df, var_array)			# Loads the array of structures with data, checks units and prenence

	average_chord = (Crh.value + Cth.value)/2

	return (bh.value*average_chord)
end

	#----------------------------- Wing Area Calculation (Sw) ----------------------------#

function Sw(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	b	= req_vars("b",   0, "m",   0)		# Wing span 
	Cr	= req_vars("Cr",  0, "m",   0)		# Wing root chord
	Ct	= req_vars("Ct",  0, "m",   0)		# Wing tip chord

	var_array = [b, Cr, Ct]				# Array of structures to enable easy iteration	

	Extract_data(df, var_array)			# Loads the array of structures with data, checks units and prenence

	average_chord = (Cr.value + Ct.value)/2

	return (b.value*average_chord)
end

	#--------------------------- Aspect Ratio Calculation (AR) --------------------------#

function AR(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	Sw  = req_vars("Sw",  0, "m^2", 0)		# Wing area
	b	= req_vars("b",   0, "m",   0)		# Wing span 
	
	var_array = [Sw, b]				# Array of structures to enable easy iteration	

	Extract_data(df, var_array)			# Loads the array of structures with data, checks units and prenence
	
	return ((b.value^2)/Sw.value)
end

	#------------------------ Mean Aerodynamic Chord Calculation -----------------------#

function MAC(df)	
	# define structures to hold definitions for the call: (name, value, units, stored)
	Ct  = req_vars("Ct",  0, "m",   0)			# Wing tip chord
	Cr  = req_vars("Cr",  0, "m",   0)			# Wing root chord	
	
	var_array = [Ct, Cr]					# Array of structures to enable easy iteration	

	Extract_data(df, var_array)				# Loads the array of structures with data, checks units and prenence
	
	taper_ratio = Ct.value / Cr.value						# Wing taper ratio
	return (Cr.value*(2/3)*((1 + taper_ratio + taper_ratio^2)/(1+taper_ratio)))
end
	
	#--------------------------- Reynolds Number Calculation ---------------------------#
	# air density and dynamic_viscosity should be changed to calculations for improved accuracy 
	# The numbers included below will get the calculations in the right order of magnitude for STP

function Re(velocity, chord)		# velocity = m/sec, chord = m

	air_density = 1.138				# kg/m^3
	dynamic_viscosity = 1.73E-05	# m/sec^2

	return air_density*velocity*chord/dynamic_viscosity
end	

	#--------------------------- Horizontal Tail Volume Ratio ---------------------------#
function Cht(df)			# df = data matrix from excel file

	# define structures to hold definitions for the call: (name, value, units, stored)
	Sht  = req_vars("Sht",  0, "m^2", 0)		# Horizontal tail area
	Lht  = req_vars("Lht",  0, "m",   0)		# Length between the aerodynamic centers of the wing and horizontal tailplane
	Sw   = req_vars("Sw",   0, "m^2", 0)		# Wing area
	cMAC = req_vars("cMAC", 0, "m",   0)		# Mean aerodynamic chord

	var_array = [Sht, Lht, Sw, cMAC]		# Array of structures to enable easy iteration

	Extract_data(df, var_array)			# Loads the array of structures with data, checks units and prenence
	
	return ((Sht.value*Lht.value)/(Sw.value*cMAC.value))
end

	#--------------------------- Vertical Tail Volume Ratio ---------------------------#
function Cvt(df)			# df = data matrix from excel file

	# define structures to hold definitions for the call: (name, value, units, stored)
	Svt  = req_vars("Svt",  0, "m^2", 0)		# Vertical tail area	
	Lvt  = req_vars("Lvt",  0, "m",   0)		# Length between the aerodynamic centers of the wing and vertical tailplane
	Sw   = req_vars("Sw",   0, "m^2", 0)		# Wing area
	b    = req_vars("b",    0, "m",   0)		# Wing span
	
	var_array = [Svt, Lvt, Sw, b]			# Array of structures to enable easy iteration

	Extract_data(df, var_array)			# Loads the array of structures with data, checks units and prenence
	
	return ((Svt.value*Lvt.value)/(Sw.value*b.value))
end
