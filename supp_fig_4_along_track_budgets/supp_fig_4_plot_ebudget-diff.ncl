;***************************************
; PROGRAM DESCRIPTION: Plot melt season energy budget diff
; INPUT DATA: Ensemble model data interpolated to tracks
; OUTPUT DATA: Line plot showing ensemble mean differences
; CREATOR: Alice DuVivier - May 2019
;***************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;***************************************
begin
; INPUTS READ IN FROM CSH SCRIPT
; ******************************************************
    yy_in1 = "1980" 
    years1 = "19800101-19811231"
    track1 = "st_hist_85_125_oct15"
    yy_in2 = "2021"
    years2 = "20210101-20221231"
    track2 = "st_85_125_oct15"    
; ******************************************************
; BEGIN SCRIPT
print("Getting ebudget difference")

; paths
indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/"+track2
indir_LENS1 = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track1
indir_LENS2 = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get liits track info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; get liits tracks
;;;;;;;;;;;;;
indir    = indir_track
innames   = systemfunc("ls "+indir+"/*.txt")
; get dimensions for array
ntracks = dimsizes(innames)
ndays = 366
ncol = 5   ; number of columns
nhead = 1   ; number of header lines to ignore

; preallocate data
mm_track = new((/ndays/),"float")
dd_track = new((/ndays/),"float")
lat_track = new((/ntracks,ndays/),"float")
lon_track = new((/ntracks,ndays/),"float")

; read in track lat/lons
n = 0
do n = 0, ntracks -1
   data = readAsciiTable(innames(n), ncol, "float", nhead)
   dims = dimsizes(data)
   nd = dims(0)
   if (n .eq. 1)
      mm_track = (/data(:,1)/)
      dd_track = (/data(:,2)/)
   end if
   lat_track(n,0:nd-1) = (/data(:,3)/)
   lon_track(n,0:nd-1) = (/data(:,4)/)
   delete([/data,dims,nd/])
end do

;;;;;;;;;;;;;
; convert to date array
;;;;;;;;;;;;;
yy_start = stringtofloat(yy_in2)
yy_end = yy_start+1

track_dates = new(ndays,"string")
mm_dd = new(ndays,"string")
d = 0
do d = 0, ndays-1
   mm_dd(d) = flt2string(mm_track(d))+"-"+flt2string(dd_track(d)) 
   if(mm_track(d) .lt. 10.0)
      track_dates(d) = flt2string(yy_end)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
   end if
   if(mm_track(d) .eq. 10.0)
      if (dd_track(d) .ge. 15)
         track_dates(d) = flt2string(yy_start)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
      end if
      if (dd_track(d) .lt. 15)
         track_dates(d) = flt2string(yy_end)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
      end if      
   end if
   if(mm_track(d) .gt. 10.0)
      track_dates(d) = flt2string(yy_start)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
   end if   
end do

; first of each month
label_inds = (/17,47,78,109,137,168,198,229,259,290,321,351/)

; if older, shift because 1980 was a leap year
;   label_inds = label_inds -1  ; to account for leap year

delete([/indir,innames/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load LENS data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; Get track data for time period 1
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS1
; swdn
var = "fswdn"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
swdn1 = fin->data_tracks
delete([/innames,fin/])

; swup
var = "fswup"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
swup1 = fin->data_tracks
delete([/innames,fin/])

; lwdn
var = "flwdn"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
lwdn1 = fin->data_tracks
delete([/innames,fin/])

; lwup
var = "flwup_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
lwup1 = fin->data_tracks
delete([/innames,fin/])

; lat
var = "flat_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
lat1 = fin->data_tracks
delete([/innames,fin/])

; sens
var = "fsens_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
sens1 = fin->data_tracks
delete([/innames,fin/])

; fcondtop
var = "fcondtop_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
fcondtop1 = fin->data_tracks
delete([/innames,fin/])

;;;;;;;;;;;;;
; Get track data for time period 2
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS2
; swdn
var = "fswdn"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
swdn2 = fin->data_tracks
delete([/innames,fin/])

; swup
var = "fswup"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
swup2 = fin->data_tracks
delete([/innames,fin/])

; lwdn
var = "flwdn"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
lwdn2 = fin->data_tracks
delete([/innames,fin/])

; lwup
var = "flwup_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
lwup2 = fin->data_tracks
delete([/innames,fin/])

; lat
var = "flat_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
lat2 = fin->data_tracks
delete([/innames,fin/])

; sens
var = "fsens_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
sens2 = fin->data_tracks
delete([/innames,fin/])

; fcondtop
var = "fcondtop_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
fcondtop2 = fin->data_tracks
delete([/innames,fin/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Basic stats
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stats for track 1
; swnet
swnet1 = swdn1 + (-1.0*swup1)
swnet_mean1 = dim_avg_n_Wrap(swnet1,0)

; lwnet
lwnet1 = lwdn1 + lwup1
lwnet_mean1 = dim_avg_n_Wrap(lwnet1,0)
; sens
sens_mean1 = dim_avg_n_Wrap(sens1,0)
; lat
lat_mean1 = dim_avg_n_Wrap(lat1,0)
; fcondtop
fcondtop_mean1 = dim_avg_n_Wrap(fcondtop1,0)
; calculate net energy budget
ebud_net1 = swnet1+lwnet1+sens1+lat1+fcondtop1
ebud_net_mean1 = dim_avg_n_Wrap(ebud_net1,0)

; stats for track 2
; swnet
swnet2 = swdn2 + (-1.0*swup2)
swnet_mean2 = dim_avg_n_Wrap(swnet2,0)
; lwnet
lwnet2 = lwdn2 + lwup2
lwnet_mean2 = dim_avg_n_Wrap(lwnet2,0)
; sens
sens_mean2 = dim_avg_n_Wrap(sens2,0)
; lat
lat_mean2 = dim_avg_n_Wrap(lat2,0)
; fcondtop
fcondtop_mean2 = dim_avg_n_Wrap(fcondtop2,0)
; calculate net energy budget
ebud_net2 = swnet2+lwnet2+sens2+lat2+fcondtop2
ebud_net_mean2 = dim_avg_n_Wrap(ebud_net2,0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Cacluate differences
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Seasonal - Perennial
; track2 - track1

; return  - do I need to shift by one day?

; swnet
swnet_diff = swnet_mean2 - swnet_mean1
; lwnet
lwnet_diff = lwnet_mean2 - lwnet_mean1
; sens
sens_diff = sens_mean2 - sens_mean1
; lat
lat_diff = lat_mean2 - lat_mean1
; fcondtop
fcondtop_diff = fcondtop_mean2 - fcondtop_mean1
; net ebudget
ebud_net_diff = ebud_net_mean2 - ebud_net_mean1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Plotting energy budget diff")

; array against which to plot 
xdata_leg = ispan(0,(ndays-1),1)

; set outdir
   outdir = "./"

;;;;;;;;;;;;;
; XY Cross Section Plot Resources
;;;;;;;;;;;;;
; set resources used for all plots
  opts                             = True              ; plot mods desired
  opts@gsnFrame                    = False             ; Do not draw plot 
  opts@gsnDraw                     = False             ; Do not advance frame
  opts@gsnMaximize                 = False             ; maximize plot
  ;opts@vpWidthF                    = 1.75               ; set aspect ratio
  ;opts@vpHeightF                   = 0.55

; set title resources
  opts@tiMainOn                    = True
  opts@tiMainFontHeightF           = 0.02
  opts@tiMainFontThicknessF        = 1.5
  opts@tmXBOn                      = True
  opts@tmXBMode                    = "Explicit"
  opts@tmXBValues                  = label_inds
  opts@tmXBLabels                  = mm_dd(label_inds)
  opts@tiXAxisString               = "Date"
  opts@gsnYRefLine                 = 0.0
  opts@gsnYRefLineDashPattern      = 2
  opts@gsnYRefLineColor            = "black"
  opts@gsnXRefLine                 = (/198.0,229.0,259.0,290.0,321.0/)
  opts@trXMinF                     = 198.0
  opts@trXMaxF                     = 336.0     
  opts@gsnXRefLineDashPattern      = 2
  opts@gsnXRefLineColor            = "black"  
  opts@tiXAxisFontHeightF          = 0.02              ; set font size for x axis
  opts@tmXBLabelFontHeightF        = 0.02              ; set tick mark label size for x axis
  opts@tmXBLabelAngleF             = 45.0
  opts@tiYAxisFontHeightF          = 0.02              ; set font size for y axis
  opts@tmYLLabelFontHeightF        = 0.02              ; set tick mark label size for y axis

; resources for stats lines
  opts@xyMarkLineModes = (/"Lines","Lines","Lines"/)
  opts@xyMonoLineColor = False
  opts@xyDashPatterns = (/0,2,2/)
  opts@xyLineThicknesses = (/3.0,3.0,3.0/)
  opts@tiYAxisString     = "Energy Budget Component (W/m~S~2~N~)"
  opts@trYMinF           = -25.
  opts@trYMaxF           = 75.0

; resources for text
  txres = True
  txres@txFontHeightF = 0.015
  txres@txFontThicknessF = 2.0

  ; diff title
  txres_d = txres
  txres_d@txFontColor = "black"
  x_d = 230.0
  y_d = 70.0
  str_d = "Diff: Seasonal-Perennial"

  ; net budget
  opts_n = opts
  opts_n@xyLineColors = (/"black","black","black"/)
  txres_n = txres
  txres_n@txFontColor = "black"
  x_n = 230.0
  y_n = 65.0
  str_n = "Net Energy Budget"

  ; net shortwave
  opts_s = opts
  opts_s@xyLineColors = (/"firebrick","firebrick","firebrick"/)
  txres_s = txres
  txres_s@txFontColor = "firebrick"
  x_s = 230.0
  y_s = 60.0
  str_s = "Net Shortwave"

  ; net longwave
  opts_l = opts
  opts_l@tiMainString = ""
  opts_l@xyLineColors = (/"darkorange","darkorange","darkorange"/)
  txres_l = txres
  txres_l@txFontColor = "darkorange"
  x_l = 230.0
  y_l = 55.0
  str_l = "Net Longwave"

  ; latent
  opts_la = opts
  opts_la@xyLineColors = (/"blue","blue","blue"/)
  txres_la = txres
  txres_la@txFontColor = "blue"
  x_la = 230.0
  y_la = 50.0
  str_la = "Latent Heat Flux"

  ; sensible
  opts_se = opts
  opts_se@tiMainString = ""
  opts_se@xyLineColors = (/"deepskyblue","deepskyblue","deepskyblue"/)
  txres_se = txres
  txres_se@txFontColor = "deepskyblue"
  x_se = 230.0
  y_se = 45.0
  str_se = "Sensible Heat Flux"
  
  ; fcondtop
  opts_f = opts
  opts_f@tiMainString = ""
  opts_f@xyLineColors = (/"green","green","green"/)
  txres_f = txres
  txres_f@txFontColor = "green" 
  x_f = 230.0
  y_f = 40.0
  str_f = "Top Conduction"

; Set panel resources
  pnlres                            = True
  pnlres@txFontHeightF              = 0.013
  pnlres@gsnPaperOrientation        = "landscape"      ; landscape mode
  pnlres@gsnMaximize                = True             ; fill the page
  pnlres@gsnPanelYWhiteSpacePercent = 3                ; Add white space b/w plots.
  pnlres@gsnPanelXWhiteSpacePercent = 3                ; Add white space b/w plots.
  pnlres@gsnPanelScalePlotIndex     = 1
  pnlres@gsnMaximize                = True	       ; fill the page

;;;;;;;;;;;;;
; Make plots
;;;;;;;;;;;;;
 fout1 = outdir+"supp_fig_4_energy_budget_diff"
 wks = gsn_open_wks("ps" ,fout1)
 plot = new(1, graphic)    ; one cross section plot and one spatial plot

   ; Plot along track info
   opts_s@tiMainString = "" ;Melt Season Difference (Seasonal - Perennial)"
   ; net shortwave
   lplot = gsn_csm_xy(wks,xdata_leg,swnet_diff,opts_s)
   ; net longwave
   oplot = gsn_csm_xy(wks,xdata_leg,lwnet_diff,opts_l)
   overlay(lplot,oplot)
   ; sensible
   oplot = gsn_csm_xy(wks,xdata_leg,sens_diff,opts_se)
   overlay(lplot,oplot)
   ; latent
   oplot = gsn_csm_xy(wks,xdata_leg,lat_diff,opts_la)
   overlay(lplot,oplot)
   ; fcondtop
   oplot = gsn_csm_xy(wks,xdata_leg,fcondtop_diff,opts_f)
   overlay(lplot,oplot)
   ; net
   oplot = gsn_csm_xy(wks,xdata_leg,ebud_net_diff,opts_n)
   overlay(lplot,oplot)
   dum0 = new(1,graphic)
   dum0 = gsn_add_text(wks,lplot,str_d,x_d,y_d,txres_d)   
   dum1 = new(1,graphic)
   dum1 = gsn_add_text(wks,lplot,str_s,x_s,y_s,txres_s)
   dum2 = new(1,graphic)
   dum2 = gsn_add_text(wks,lplot,str_l,x_l,y_l,txres_l)
   dum3 = new(1,graphic)
   dum3 = gsn_add_text(wks,lplot,str_se,x_se,y_se,txres_se)
   dum4 = new(1,graphic)
   dum4 = gsn_add_text(wks,lplot,str_la,x_la,y_la,txres_la)
   dum5 = new(1,graphic)
   dum5 = gsn_add_text(wks,lplot,str_f,x_f,y_f,txres_f)
   dum6 = new(1,graphic)
   dum6 = gsn_add_text(wks,lplot,str_n,x_n,y_n,txres_n)   
   plot(0) = lplot
   
;;;;;;;;;;;;;
; Final Plots
;;;;;;;;;;;;;
  ; make panel plot
  ;pnlres@txString  = "Energy budget terms"
  gsn_panel(wks,(/plot/),(/1,1/),pnlres)                   ; create final panel plot
  delete(wks)
  print("converting to png")
  system("convert -trim -border 5 -bordercolor white -density 300 "+  \
         "-rotate -90 -trim -border 5 "+fout1+".ps "+fout1+".png")

delete(plot)

;;;;;;;;;;;;;;;;;;;;;; END script
end
