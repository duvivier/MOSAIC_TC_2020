#! /bin/tcsh -f

# Script to plot figure 2 panels
# Alice DuVivier- May 2019
#################################################
##############
# USER INPUTS
##############
set cases = ('b.e11.BRCP85C5CNBDRD.f09_g16')
set year_range = ('20210101-20221231')
set yy = ('2021')
set tracks = ('st_85_125_oct15')
set vars = ('aice' 'hi' 'iage')

##############
# start loops
# Loop for casename/date
set t = 1
while ($t <= 1)  # max: 1
# Loop for variables to plot
set v = 1
while ($v <= 3)  # max: 3

set case = $cases[$t]
set years = $year_range[$t]
set yy_in = $yy[$t]
set track = $tracks[$t]
set varcode = $vars[$v]

##############
# Input into ncl
##############

        echo 'Plotting table for LENS correlations thru time'
        ncl 'case          = "'$case'"'\
            'yy_in         = "'$yy_in'"' \
            'years         = "'$years'"' \
            'track         = "'$track'"' \
            'varcode       = "'$varcode'"' \
            ./fig_3_plot_select_ensemble_ice_maps.ncl
	    
@ v ++
end
@ t ++
end



