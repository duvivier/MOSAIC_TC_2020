#! /bin/tcsh -f

# Script to plot figure 7 panels
# Alice DuVivier- May 2019
#################################################
##############
# USER INPUTS
##############
set cases = ('b.e11.BRCP85C5CNBDRD.f09_g16' 'b.e11.BRCP85C5CNBDRD.f09_g16' 'b.e11.B20TRC5CNBDRD.f09_g16' 'b.e11.B20TRC5CNBDRD.f09_g16') 
set year_range = ('20210101-20221231' '20210101-20221231' '19800101-19811231' '19800101-19811231')
set yy = ('2021' '2021' '1980' '1980')
set tracks = ('st_85_125_oct15' 'st_85_125_oct1' 'st_hist_85_125_oct15' 'st_hist_85_125_oct1')

##############
# start loops
# Loop for casename/date
set t = 1
while ($t <= 4)  # max: 4

set case = $cases[$t]
set years = $year_range[$t]
set yy_in = $yy[$t]
set track = $tracks[$t]

##############
# Input into ncl
##############

        echo 'Plotting table for LENS correlations thru time'
        ncl 'case          = "'$case'"'\
            'yy_in         = "'$yy_in'"' \
            'years         = "'$years'"' \
            'track         = "'$track'"' \
            ./fig_8_plot_autocorr_table.ncl
	    
@ t ++
end



