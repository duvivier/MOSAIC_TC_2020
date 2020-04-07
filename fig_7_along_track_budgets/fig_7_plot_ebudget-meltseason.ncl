;***************************************
; PROGRAM DESCRIPTION: Plot melt season energy budget
; INPUT DATA: Ensemble model data interpolated to tracks
; OUTPUT DATA: Line plot showing ensemble mean and stddev
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
    ;yy_in = "1980" 
    ;years = "19800101-19811231"
    ;track = "st_hist_85_125_oct15"
; ******************************************************
; BEGIN SCRIPT
print("Getting ebudget for year "+yy_in)

; paths
indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/"+track
indir_LENS = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track

yy_start = stringtofloat(yy_in)
yy_end = yy_start+1

; set prefix for labels
if (yy_in .eq. "2021")
   prefix = "Seasonal"
end if
if (yy_in .eq. "1980")
   prefix = "Perennial"
end if

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
if (yy_in .eq. "1980")
   label_inds = label_inds -1  ; to account for leap year
end if

delete([/indir,innames/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load LENS data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; Get track data
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS
; swdn
var = "fswdn"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
swdn = fin->data_tracks
delete([/innames,fin/])

; swup
var = "fswup"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
swup = fin->data_tracks
delete([/innames,fin/])

; lwdn
var = "flwdn"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
lwdn = fin->data_tracks
delete([/innames,fin/])

; lwup
var = "flwup_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
lwup = fin->data_tracks
delete([/innames,fin/])

; lat
var = "flat_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
lat = fin->data_tracks
delete([/innames,fin/])

; sens
var = "fsens_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
sens = fin->data_tracks
delete([/innames,fin/])

; fcondtop
var = "fcondtop_ai"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
fcondtop = fin->data_tracks
delete([/innames,fin/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Basic stats
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stats for along tracks
; stats for track
; swnet
swnet_plot = new((/3,ndays/),typeof(swup))
swnet = swdn + (-1.0*swup)
swnet_mean = dim_avg_n_Wrap(swnet,0)
swnet_stddev = dim_stddev_n_Wrap(swnet,0)
swnet_plot(0,:) = swnet_mean
swnet_plot(1,:) = swnet_mean + swnet_stddev
swnet_plot(2,:) = swnet_mean - swnet_stddev

; lwnet
lwnet_plot = new((/3,ndays/),typeof(swup))
lwnet = lwdn + lwup
lwnet_mean = dim_avg_n_Wrap(lwnet,0)
lwnet_stddev = dim_stddev_n_Wrap(lwnet,0)
lwnet_plot(0,:) = lwnet_mean
lwnet_plot(1,:) = lwnet_mean + lwnet_stddev
lwnet_plot(2,:) = lwnet_mean - lwnet_stddev

; sens
sens_plot = new((/3,ndays/),typeof(sens))
sens_mean = dim_avg_n_Wrap(sens,0)
sens_stddev = dim_stddev_n_Wrap(sens,0)
sens_plot(0,:) = sens_mean
sens_plot(1,:) = sens_mean + sens_stddev
sens_plot(2,:) = sens_mean - sens_stddev

; lat
lat_plot = new((/3,ndays/),typeof(lat))
lat_mean = dim_avg_n_Wrap(lat,0)
lat_stddev = dim_stddev_n_Wrap(lat,0)
lat_plot(0,:) = lat_mean
lat_plot(1,:) = lat_mean + lat_stddev
lat_plot(2,:) = lat_mean - lat_stddev

; fcondtop
fcondtop_plot = new((/3,ndays/),typeof(fcondtop))
fcondtop_mean = dim_avg_n_Wrap(fcondtop,0)
fcondtop_stddev = dim_stddev_n_Wrap(fcondtop,0)
fcondtop_plot(0,:) = fcondtop_mean
fcondtop_plot(1,:) = fcondtop_mean + fcondtop_stddev
fcondtop_plot(2,:) = fcondtop_mean - fcondtop_stddev

; calculate net energy budget
ebud_net_plot = new((/3,ndays/),typeof(lwnet))
ebud_net = swnet+lwnet+sens+lat+fcondtop
ebud_net_mean = dim_avg_n_Wrap(ebud_net,0)
ebud_net_stddev = dim_stddev_n_Wrap(ebud_net,0)
ebud_net_plot(0,:) = ebud_net_mean
ebud_net_plot(1,:) = ebud_net_mean + ebud_net_stddev
ebud_net_plot(2,:) = ebud_net_mean - ebud_net_stddev

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Plotting energy budget")

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
  if (yy_in .eq. "2021")
     opts@gsnXRefLine                 = (/198.0,229.0,259.0,290.0,321.0/)
     opts@trXMinF                     = 198.0
     opts@trXMaxF                     = 336.0     
  end if
  if (yy_in .eq. "1980")
     opts@gsnXRefLine                 = (/197.0,228.0,258.0,289.0,320.0/)
     opts@trXMinF                     = 197.0
     opts@trXMaxF                     = 335.0         
  end if  
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
  opts@xyDashPatterns = (/0,0,0/)
  opts@xyLineThicknesses = (/7.0,1.0,1.0/)
  opts@tiYAxisString     = "Energy Budget Components (W/m~S~2~N~)"
  opts@trYMinF           = -75.
  opts@trYMaxF           = 160. ;150.

; resources for text
  txres = True
  txres@txFontHeightF = 0.025 ;0.015
  txres@txFontThicknessF = 2.0

  ; net budget
  opts_n = opts
  opts_n@xyLineColors = (/"black","black","black"/)
  opts_n@xyLineThicknesses = (/7.0,3.0,3.0/)
  txres_n = txres
  txres_n@txFontColor = "black"
  x_n = 255.0 ;230.0
  y_n = 150.0
  str_n = prefix+" Net Energy Budget"

  ; net shortwave
  opts_s = opts
  opts_s@xyLineColors = (/"firebrick","firebrick","firebrick"/)
  opts_s@gsnXYFillColors = (/"mistyrose","mistyrose"/)
  txres_s = txres
  txres_s@txFontColor = "firebrick"
  x_s = 230.0
  y_s = 135.0 ;140.0
  str_s = "Net Shortwave"

  ; net longwave
  opts_l = opts
  opts_l@tiMainString = ""
  opts_l@xyLineColors = (/"darkorange","darkorange","darkorange"/)
  opts_l@gsnXYFillColors = (/"moccasin","moccasin"/)
  txres_l = txres
  txres_l@txFontColor = "darkorange"
  x_l = 230.0
  y_l = 120.0 ;130.0
  str_l = "Net Longwave"

  ; latent
  opts_la = opts
  opts_la@xyLineColors = (/"blue","blue","blue"/)
  txres_la = txres
  txres_la@txFontColor = "blue"
  x_la = 230.0
  y_la = 120.0
  str_la = "Latent Heat Flux"

  ; sensible
  opts_se = opts
  opts_se@tiMainString = ""
  opts_se@xyLineColors = (/"deepskyblue","deepskyblue","deepskyblue"/)
  txres_se = txres
  txres_se@txFontColor = "deepskyblue"
  x_se = 230.0
  y_se = 110.0
  str_se = "Sensible Heat Flux"
  
  ; fcondtop
  opts_f = opts
  opts_f@tiMainString = ""
  opts_f@xyLineColors = (/"purple","purple","purple"/)
  txres_f = txres
  txres_f@txFontColor = "purple"
  x_f = 230.0
  y_f = 100.0
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
 fout1 = outdir+"fig_7_energy_budget_meltseason_along_track_"+track
 wks = gsn_open_wks("ps" ,fout1)
 plot = new(1, graphic)    ; one cross section plot and one spatial plot

   ; Plot along track info
   opts_s@tiMainString = "" ;"Energy Budget Along LENS Tracks"
   ; net shortwave
   lplot = gsn_csm_xy(wks,xdata_leg,swnet_plot,opts_s)
   ; net longwave
   oplot = gsn_csm_xy(wks,xdata_leg,lwnet_plot,opts_l)
   overlay(lplot,oplot)
   ;; sensible
   ;oplot = gsn_csm_xy(wks,xdata_leg,sens_plot,opts_se)
   ;overlay(lplot,oplot)
   ;; latent
   ;oplot = gsn_csm_xy(wks,xdata_leg,lat_plot,opts_la)
   ;overlay(lplot,oplot)
   ;; fcondtop
   ;oplot = gsn_csm_xy(wks,xdata_leg,fcondtop_plot,opts_f)
   ;overlay(lplot,oplot)
   ; net
   oplot = gsn_csm_xy(wks,xdata_leg,ebud_net_plot,opts_n)
   overlay(lplot,oplot)   
   dum1 = new(1,graphic)
   dum1 = gsn_add_text(wks,lplot,str_s,x_s,y_s,txres_s)
   dum2 = new(1,graphic)
   dum2 = gsn_add_text(wks,lplot,str_l,x_l,y_l,txres_l)
   ;dum3 = new(1,graphic)
   ;dum3 = gsn_add_text(wks,lplot,str_se,x_se,y_se,txres_se)
   ;dum4 = new(1,graphic)
   ;dum4 = gsn_add_text(wks,lplot,str_la,x_la,y_la,txres_la)
   ;dum5 = new(1,graphic)
   ;dum5 = gsn_add_text(wks,lplot,str_f,x_f,y_f,txres_f)
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
