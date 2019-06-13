#! /bin/tcsh -f

# Script to plot supp figure 6 panels
# Alice DuVivier- May 2019
#################################################
##############
# USER INPUTS
##############
set year_range = ('20210101-20221231' '19800101-19811231')
set yy = ('2021' '1980')
set tracks = ('st_85_125_oct15' 'st_hist_85_125_oct15')

##############
# start loops
# Loop for casename/date
set t = 1
while ($t <= 2)  # max: 2

set years = $year_range[$t]
set yy_in = $yy[$t]
set track = $tracks[$t]

##############
# Input into ncl
##############

        echo 'Plotting budgets for LENS in meltseason'
        ncl 'yy_in         = "'$yy_in'"' \
            'years         = "'$years'"' \
            'track         = "'$track'"' \
            ./fig_6_plot_ebudget-meltseason.ncl
	    
        ncl 'yy_in         = "'$yy_in'"' \
            'years         = "'$years'"' \
            'track         = "'$track'"' \
            ./fig_6_plot_mbudget-meltseason.ncl

@ t ++
end

# Run difference plots
        ncl ./fig_6_plot_ebudget-diff.ncl

        ncl ./fig_6_plot_mbudget-diff.ncl
