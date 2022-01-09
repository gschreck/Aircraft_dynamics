#
# This file is the aerodynamic drag calculations using "Zero Lift Drag"
# Individual components are calculated and the drags combined for an approximation
# This calculation is currently using the wing as well as the empennage.
# Wing lift induced drag will also be included so adds a velocity variable to the solution.
# Interference & excrescence drag are approximated using a factor based on the aircraft type.
# In this case = 1.15, which is slightly better than the general aviation factor of 1.2 - 1.3.
#
# This code is licensed under MIT license (see LICENSE.txt for details)
#
# Dec 12, 2021 		Initial code
#

using Plots

#						Mach	A		B	  R^2
Skin_friction_coeff =  [0.0	0.0391	-0.157	0.9967
						0.3	0.0399	-0.159	0.9976
						0.7	0.0392	-0.16	0.9971
						0.9	0.0376	-0.159	0.9965
						1.0	0.0381	-0.161	0.9970
						1.5	0.0371	-0.164	0.9966
						2.0	0.0329	-0.162	0.9941
						2.5	0.0286	-0.161	0.9944
						3.0	0.0261	-0.161	0.9936]

						Mach_indexes = [0.0, 0.3, 0.7, 0.9, 1.0, 1.5, 2.0, 2.5, 3.0]
	
# dataframe for keeping track of (book-keeping)drag variables
drag_vars = DataFrame( 
		Velocity			=	Float32[],
		Cd_fuselage 		=	Float32[],
		Cd_wing 			=	Float32[],
		Cd_horizontal_tail	=	Float32[],
		Cd_vertical_tail	=	Float32[],
		Cd0_total			=	Float32[]
	)

#  interference + excrescence drag coefficient
interference_drag = 1.15	
	
	#------------------------------ Find the Nearest Value in an Array) ------------------------------#
function findnearest(a,x)
   idx = searchsortedfirst(a,x)
   if (idx==1); return idx; end
   if (idx>length(a)); return length(a); end
   if (a[idx]==x); return idx; end
   if (abs(a[idx]-x) < abs(a[idx-1]-x))
      return idx
   else
      return idx-1
   end
end

	#------------------------------ Drag Simulation Wrapper (drag_sim) ------------------------------#
	#  These calculations assume "zero lift drag method"
	#  Itetrates through various temperatures and fills out a matrix of constituient drags 
	#  of various components									

function drag_sim(df)

	# define structures to hold definitions for the call: (name, value, units, stored)
	SVstart  	= req_vars("SVstart",  	0, "m/s", 	0)	# Lowest simulation velocity
	SVend	   	= req_vars("SVend",		0, "m/s",	0)	# Highest simulation velocity
	SVincr	   	= req_vars("SVincr",	0, "m/s",	0)	# Loop increment	
	
	var_array = [SVstart, SVend, SVincr]				# Array of structures to enable easy iteration	

	Extract_data(df, var_array)							# Loads the array of structures with data, checks units and presence

	# loop through the various velocities
	for V in SVstart.value:SVincr.value:SVend.value
            f_drag = fuselage_drag(df, V)
			w_drag = wing_drag(df, V)
			h_tail = 3.0
			v_tail = 4.0
			Cd0_total = (f_drag + w_drag + h_tail + v_tail) * interference_drag
		
		# write the results to the storage matrix
		push!(drag_vars,[V*2.237, f_drag, w_drag, h_tail, v_tail, Cd0_total])  ### temporarily changing velocity to MPH
       end


###----------------- some temporary display values to check results	   
# print("\n\n", drag_vars)
display(plot(drag_vars[:,1], drag_vars[:,2])); sleep(30)
	
end

	#---------------------------- Fuselage drag component (fuselage_drag) --------------------------#
	#	lf = fuselage length
	#	dfuse = maximum fuselage diameter
	#	Swetf = total fuselage surface area exposed to air 
	#	Sw = total wing area
	
function fuselage_drag(df, V)

	# define structures to hold definitions for the call: (name, value, units, stored)
	Sw  	= req_vars("Sw",  		0, 	"m^2", 	0)			# wing area
	Swetf 	= req_vars("Swetf",  	0, 	"m^2", 	0)			# fuselage wet area
	dfuse	= req_vars("dfuse",		0, 	"m", 	0)			# fuselage maximum diameter
	lf		= req_vars("lf",  		0, 	"m", 	0)			# fuselage maximum length
	
	var_array = [Sw, Swetf, dfuse, lf]						# Array of structures to enable easy iteration
	Extract_data(df, var_array)								# Loads the array of structures with data, checks units and presence

	Cf_fuse = Cf(df, V)										# calculate the skin friction coefficient
	df_equiv = sqrt((4/π)*dfuse.value)						# factor assumes a non-circular fuselage cross section
	
	Cd0_fueslage = Cf_fuse * ((1 + 60/(lf.value/df_equiv)^3) + (0.0025 * (lf.value/df_equiv))) * (Swetf.value/Sw.value)
	
	return (Cd0_fueslage)
end 	


	#--------------------------------  Wing drag component (wing_drag) -----------------------------#

function wing_drag(df, V)
			return (2)
end 	
		
	
	#------------------------------------- Speed of Sound (c) --------------------------------------#

function c(df)	

	# define structures to hold definitions for the call: (name, value, units, stored)
	T  	   = req_vars("T",  0, 	"C", 	0)			# T = Temperature

	var_array = [T]									# Array of structures to enable easy iteration	

	Extract_data(df, var_array)						# Loads the array of structures with data, checks units and presence
	
	return ((331.3 * sqrt(1 + T.value/273.15)))

end

	#--------------------------------- Skin Friction Coefficient (Cf) --------------------------------#
	#									Cf = A * Re^B

function Cf(df, V)	

	lf		= req_vars("lf",  		0, 	"m", 	0)			# fuselage maximum length
	var_array = [lf]										# Array of structures to enable easy iteration
	Extract_data(df, var_array)								# Loads the array of structures with data, checks units and presence

	Re_number = Re(V, lf.value)								# calculatealculate the fuselage reynolds number for velocity
	speed_of_sound = c(df)									# calculate the speed of sound for the temperature
	Mach_no = V / speed_of_sound							# calculate the mach number
	Mach_nearest = findnearest(Mach_indexes, Mach_no)		# find the index of the closest fit in the mach table

	Cf = Skin_friction_coeff[Mach_nearest,2] * Re_number^Skin_friction_coeff[Mach_nearest,3]
	return (Cf)

end

