#! /bin/tcsh -f

# Script to plot supp figure 3 panels
# Alice DuVivier- May 2019
#################################################
##############
# USER INPUTS
##############
set vars = ('aice' 'hi' 'fs' 'hs' 'apond' 'albedo')

##############
# start loops
# Loop to go through variables to plot
set v = 3
while ($v <= 6) # max: 6

set varcode = $vars[$v]

##############
# Input into ncl
##############
        echo 'Plotting ' $varcode ' for LENS'
        ncl 'varcode       = "'$varcode'"'\
            ./supp_fig_3_plot_along_track_surface_state.ncl

@ v ++
end



