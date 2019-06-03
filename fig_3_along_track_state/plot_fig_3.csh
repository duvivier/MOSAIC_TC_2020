#! /bin/tcsh -f

# Script to plot figure 3 panels
# Alice DuVivier- May 2019
#################################################
##############
# USER INPUTS
##############
set cases = ('b.e11.BRCP85C5CNBDRD.f09_g16' 'b.e11.B20TRC5CNBDRD.f09_g16') 
set year_range = ('20210101-20221231' '19800101-19811231')
set yy = ('2021' '1980')
set tracks = ('st_85_125_oct15' 'st_hist_85_125_oct15')
set tracks2 = ('70_90_N' '70_90_N_hist')

set vars = ('aice' 'hi' 'hs' 'fs' 'hs' 'apond' 'albedo')

##############
# start loops
# Loop for casename/date
set y = 1
while ($y <= 2)  # max: 2
# Loop for variables to plot
set v = 1
while ($v <= 2) # variable loop (max: 2)

set case = $cases[$y]
set years = $year_range[$y]
set yy_in = $yy[$y]
set track = $tracks[$y]
set track2 = $tracks2[$y]
set varcode = $vars[$v]

##############
# Input into ncl
##############
        echo 'Plotting ' $varcode ' for LENS on mosaic tracks '$years
        ncl 'case          = "'$case'"'\
            'varcode       = "'$varcode'"' \
            'yy_in         = "'$yy_in'"' \
            'years         = "'$years'"' \
            'track         = "'$track'"' \
            'track2        = "'$track2'"' \
            ./fig_3_plot_along_track_ice_state.ncl

        echo 'getting statistics for '$years
        ncl 'case          = "'$case'"'\
            'varcode       = "'$varcode'"' \
            'yy_in         = "'$yy_in'"' \
            'years         = "'$years'"' \
            'track         = "'$track'"' \
            'track2        = "'$track2'"' \
            ./get_variability_stats.ncl
	    	    
@ v ++
end
@ y ++
end



