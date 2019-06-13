;***************************************
; PROGRAM DESCRIPTION: Plot melt season mass budget diff
; INPUT DATA: Ensemble model data interpolated to tracks
; OUTPUT DATA: Line plot showing ensemble mean difference
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
print("Getting mbudget difference")

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
; meltb
var = "meltb"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
meltb1 = fin->data_tracks
delete([/innames,fin/])

; meltt
var = "meltt"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
meltt1 = fin->data_tracks
delete([/innames,fin/])

; meltl
var = "meltl"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
meltl1 = fin->data_tracks
delete([/innames,fin/])

; congel
var = "congel"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
congel1 = fin->data_tracks
delete([/innames,fin/])

; frazil
var = "frazil"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
frazil1 = fin->data_tracks
delete([/innames,fin/])

; snoice
var = "snoice"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years1+"*.nc")
fin = addfile(innames(0),"r")
snoice1 = fin->data_tracks
delete([/innames,fin/])

;;;;;;;;;;;;;
; Get track data for time period 2
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS2
; meltb
var = "meltb"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
meltb2 = fin->data_tracks
delete([/innames,fin/])

; meltt
var = "meltt"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
meltt2 = fin->data_tracks
delete([/innames,fin/])

; meltl
var = "meltl"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
meltl2 = fin->data_tracks
delete([/innames,fin/])

; congel
var = "congel"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
congel2 = fin->data_tracks
delete([/innames,fin/])

; frazil
var = "frazil"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
frazil2 = fin->data_tracks
delete([/innames,fin/])

; snoice
var = "snoice"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years2+"*.nc")
fin = addfile(innames(0),"r")
snoice2 = fin->data_tracks
delete([/innames,fin/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Basic stats
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stats for track 1
; meltb
meltb_mean1 = -1.0*dim_avg_n_Wrap(meltb1,0)
; meltt
meltt_mean1 = -1.0*dim_avg_n_Wrap(meltt1,0)
; meltl
meltl_mean1 = -1.0*dim_avg_n_Wrap(meltl1,0)
; congel
congel_mean1 = dim_avg_n_Wrap(congel1,0)
; frazil
frazil_mean1 = dim_avg_n_Wrap(frazil1,0)
; snowice
snoice_mean1 = dim_avg_n_Wrap(snoice1,0)
; calculate net mass budget
mbud_net1 = -1.0*(meltb1 + meltt1 + meltl1) + (congel1 + frazil1 + snoice1)
mbud_net_mean1 = dim_avg_n_Wrap(mbud_net1,0)

; stats for track 2
; meltb
meltb_mean2 = -1.0*dim_avg_n_Wrap(meltb2,0)
; meltt
meltt_mean2 = -1.0*dim_avg_n_Wrap(meltt2,0)
; meltl
meltl_mean2 = -1.0*dim_avg_n_Wrap(meltl2,0)
; congel
congel_mean2 = dim_avg_n_Wrap(congel2,0)
; frazil
frazil_mean2 = dim_avg_n_Wrap(frazil2,0)
; snowice
snoice_mean2 = dim_avg_n_Wrap(snoice2,0)
; calculate net mass budget
mbud_net2 = -1.0*(meltb2 + meltt2 + meltl2) + (congel2 + frazil2 + snoice2)
mbud_net_mean2 = dim_avg_n_Wrap(mbud_net2,0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Cacluate differences
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Seasonal - Perennial
; track2 - track1

; return  - do I need to shift by one day?

; meltb
meltb_diff = meltb_mean2 - meltb_mean1
; meltt
meltt_diff = meltt_mean2 - meltt_mean1
; meltl
meltl_diff = meltl_mean2 - meltl_mean1
; congel
congel_diff = congel_mean2 - congel_mean1
; frazil
frazil_diff = frazil_mean2 - frazil_mean1
; snowice
snoice_diff = snoice_mean2 - snoice_mean1
; net budget
mbud_net_diff = mbud_net_mean2 - mbud_net_mean1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Plotting mass budget")

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
  opts@tiYAxisString     = "Mass Budget Components (cm/day)"
  opts@trYMinF           = -1.5
  opts@trYMaxF           = 0.1

; resources for text
  txres = True
  txres@txFontHeightF = 0.015
  txres@txFontThicknessF = 2.0

  ; diff title
  txres_d = txres
  txres_d@txFontColor = "black"
  x_d = 230.0
  y_d = -0.3
  str_d = "Diff: Seasonal-Perennial"

  ; net budget
  opts_n = opts
  opts_n@xyLineColors = (/"black","black","black"/)
  txres_n = txres
  txres_n@txFontColor = "black"
  x_n = 230.0
  y_n = -0.4
  str_n = "Net Mass Budget"

  ; meltb
  opts_b = opts
  opts_b@xyLineColors = (/"firebrick","firebrick","firebrick"/)
  txres_b = txres
  txres_b@txFontColor = "firebrick"
  x_b = 230.0
  y_b = -0.5
  str_b = "Bottom Melt"

  ; meltt
  opts_t = opts
  opts_t@tiMainString = ""
  opts_t@xyLineColors = (/"darkorange","darkorange","darkorange"/)
  txres_t = txres
  txres_t@txFontColor = "darkorange"
  x_t = 230.0
  y_t = -0.6
  str_t = "Top melt"

  ; meltl
  opts_l = opts
  opts_l@tiMainString = ""
  opts_l@xyLineColors = (/"gold","gold","gold"/)
  txres_l = txres
  txres_l@txFontColor = "gold"
  x_l = 230.0
  y_l = -0.7
  str_l = "Lateral melt"

  ; congel
  opts_c = opts
  opts_c@xyLineColors = (/"blue","blue","blue"/)
  txres_c = txres
  txres_c@txFontColor = "blue"
  x_c = 230.0
  y_c = -0.8
  str_c = "Congelation Growth"

  ; frazil
  opts_f = opts
  opts_f@tiMainString = ""
  opts_f@xyLineColors = (/"deepskyblue","deepskyblue","deepskyblue"/)
  txres_f = txres
  txres_f@txFontColor = "deepskyblue"
  x_f = 230.0
  y_f = -0.9
  str_f = "Frazil Growth"

  ; snowice
  opts_s = opts
  opts_s@tiMainString = ""
  opts_s@xyLineColors = (/"green","green","green"/)
  txres_s = txres
  txres_s@txFontColor = "green"
  x_s = 230.0
  y_s = -1.0
  str_s = "Snowice Growth"

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
 fout1 = outdir+"fig_6_mass_budget_diff"
 wks = gsn_open_wks("ps" ,fout1)
 plot = new(1, graphic)    ; one cross section plot and one spatial plot

   ; Plot along track info
   opts_b@tiMainString = "" ;Melt Season Difference (Seasonal - Perennial)"
   ; meltb
   lplot = gsn_csm_xy(wks,xdata_leg,meltb_diff,opts_b)
   ; meltt
   oplot = gsn_csm_xy(wks,xdata_leg,meltt_diff,opts_t)
   overlay(lplot,oplot)
   ; meltl
   oplot = gsn_csm_xy(wks,xdata_leg,meltl_diff,opts_l)
   overlay(lplot,oplot)
   ; congel
   oplot = gsn_csm_xy(wks,xdata_leg,congel_diff,opts_c)
   overlay(lplot,oplot)
   ; frazil
   oplot = gsn_csm_xy(wks,xdata_leg,frazil_diff,opts_f)
   overlay(lplot,oplot)
   ; snoice
   oplot = gsn_csm_xy(wks,xdata_leg,snoice_diff,opts_s)
   overlay(lplot,oplot)
   oplot = gsn_csm_xy(wks,xdata_leg,mbud_net_diff,opts_n)
   overlay(lplot,oplot)
   dum0 = new(1,graphic)
   dum0 = gsn_add_text(wks,lplot,str_d,x_d,y_d,txres_d)
   dum1 = new(1,graphic)
   dum1 = gsn_add_text(wks,lplot,str_b,x_b,y_b,txres_b)
   dum2 = new(1,graphic)
   dum2 = gsn_add_text(wks,lplot,str_t,x_t,y_t,txres_t)
   dum3 = new(1,graphic)
   dum3 = gsn_add_text(wks,lplot,str_l,x_l,y_l,txres_l)
   dum4 = new(1,graphic)
   dum4 = gsn_add_text(wks,lplot,str_c,x_c,y_c,txres_c)
   dum5 = new(1,graphic)
   dum5 = gsn_add_text(wks,lplot,str_f,x_f,y_f,txres_f)
   dum6 = new(1,graphic)
   dum6 = gsn_add_text(wks,lplot,str_s,x_s,y_s,txres_s)   
   dum7 = new(1,graphic)
   dum7 = gsn_add_text(wks,lplot,str_n,x_n,y_n,txres_n)   
   plot(0) = lplot

 ;;;;;;;;;;;;;
; Final Plots
;;;;;;;;;;;;;
  ; make panel plot
  ;pnlres@txString  = "Mass budget terms"
  gsn_panel(wks,(/plot/),(/1,1/),pnlres)                   ; create final panel plot
  delete(wks)
  print("converting to png")
  system("convert -trim -border 5 -bordercolor white -density 300 "+  \
         "-rotate -90 -trim -border 5 "+fout1+".ps "+fout1+".png")

delete(plot)

;;;;;;;;;;;;;;;;;;;;;; END script
end
