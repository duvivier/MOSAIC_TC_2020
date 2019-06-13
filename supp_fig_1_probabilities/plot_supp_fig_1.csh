#! /bin/tcsh -f

# Script to plot figure 2 panels
# Alice DuVivier- May 2019 
#################################################
##############
# USER INPUTS
##############
set yy = ('2021')
set tracks = ('st_85_125_oct15')
set weeks = ('1' '13')

##############
# start loops
# Loop for casename/date
set t = 1
while ($t <= 1)  # max: 1
# Loop for week to plot
set w = 1
while ($w <= 2)  # max: 2

set yy_in = $yy[$t]
set track = $tracks[$t]
set selectweek = $weeks[$w]

##############
# Input into ncl
##############

        echo 'Plotting table for LENS correlations thru time'
        ncl 'yy_in         = "'$yy_in'"' \
            'track         = "'$track'"' \
            'selectweek    = "'$selectweek'"' \
            ./supp_fig_1_plot_lat_lon_by_week.ncl
	    
@ w ++
end
@ t ++
end



