;***************************************
; PROGRAM DESCRIPTION: Plot melt season mass budget
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
  ;  yy_in = "2021"
  ;  years = "20210101-20221231"
  ;  track = "st_85_125_oct15"
; ******************************************************
; BEGIN SCRIPT
print("Getting mbudget for year "+yy_in)

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
; meltb
var = "meltb"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
meltb = fin->data_tracks
delete([/innames,fin/])

; meltt
var = "meltt"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
meltt = fin->data_tracks
delete([/innames,fin/])

; meltl
var = "meltl"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
meltl = fin->data_tracks
delete([/innames,fin/])

; congel
var = "congel"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
congel = fin->data_tracks
delete([/innames,fin/])

; frazil
var = "frazil"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
frazil = fin->data_tracks
delete([/innames,fin/])

; snoice
var = "snoice"
innames = systemfunc("ls "+indir+"/LENS_"+var+"_mosaic*"+years+"*.nc")
fin = addfile(innames(0),"r")
snoice = fin->data_tracks
delete([/innames,fin/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Basic stats
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stats for along tracks
; meltb
meltb_plot = new((/3,ndays/),typeof(meltb))
meltb_mean = dim_avg_n_Wrap(meltb,0)
meltb_stddev = dim_stddev_n_Wrap(meltb,0)
meltb_plot(0,:) = -1.0*meltb_mean
meltb_plot(1,:) = -1.0*meltb_mean + meltb_stddev
meltb_plot(2,:) = -1.0*meltb_mean - meltb_stddev
meltb_plot(1,:) = where(meltb_plot(1,:) .gt. 0.0, 0.0, meltb_plot(1,:))

; meltt
meltt_plot = new((/3,ndays/),typeof(meltt))
meltt_mean = dim_avg_n_Wrap(meltt,0)
meltt_stddev = dim_stddev_n_Wrap(meltt,0)
meltt_plot(0,:) = -1.0*meltt_mean
meltt_plot(1,:) = -1.0*meltt_mean + meltt_stddev
meltt_plot(2,:) = -1.0*meltt_mean - meltt_stddev
meltt_plot(1,:) = where(meltt_plot(1,:) .gt. 0.0, 0.0, meltt_plot(1,:))

; meltl
meltl_plot = new((/3,ndays/),typeof(meltl))
meltl_mean = dim_avg_n_Wrap(meltl,0)
meltl_stddev = dim_stddev_n_Wrap(meltl,0)
meltl_plot(0,:) = -1.0*meltl_mean
meltl_plot(1,:) = -1.0*meltl_mean + meltl_stddev
meltl_plot(2,:) = -1.0*meltl_mean - meltl_stddev
meltl_plot(1,:) = where(meltl_plot(1,:) .gt. 0.0, 0.0, meltl_plot(1,:))

; congel
congel_plot = new((/3,ndays/),typeof(congel))
congel_mean = dim_avg_n_Wrap(congel,0)
congel_stddev = dim_stddev_n_Wrap(congel,0)
congel_plot(0,:) = congel_mean
congel_plot(1,:) = congel_mean + congel_stddev
congel_plot(2,:) = congel_mean - congel_stddev
congel_plot(2,:) = where(congel_plot(2,:) .lt. 0.0, 0.0, congel_plot(2,:))

; frazil
frazil_plot = new((/3,ndays/),typeof(frazil))
frazil_mean = dim_avg_n_Wrap(frazil,0)
frazil_stddev = dim_stddev_n_Wrap(frazil,0)
frazil_plot(0,:) = frazil_mean
frazil_plot(1,:) = frazil_mean + frazil_stddev
frazil_plot(2,:) = frazil_mean - frazil_stddev
frazil_plot(2,:) = where(frazil_plot(2,:) .lt. 0.0, 0.0, frazil_plot(2,:))

; snowice
snoice_plot = new((/3,ndays/),typeof(snoice))
snoice_mean = dim_avg_n_Wrap(snoice,0)
snoice_stddev = dim_stddev_n_Wrap(snoice,0)
snoice_plot(0,:) = snoice_mean
snoice_plot(1,:) = snoice_mean + snoice_stddev
snoice_plot(2,:) = snoice_mean - snoice_stddev
snoice_plot(1,:) = where(snoice_plot(2,:) .lt. 0.0, 0.0, snoice_plot(2,:))

; calculate net mass budget
mbud_net_plot = new((/3,ndays/),typeof(snoice))
mbud_net = -1.0*(meltb + meltt + meltl) + (congel + frazil + snoice) 
mbud_net_mean = dim_avg_n_Wrap(mbud_net,0)
mbud_net_stddev = dim_stddev_n_Wrap(mbud_net,0)
mbud_net_plot(0,:) = mbud_net_mean
mbud_net_plot(1,:) = mbud_net_mean + mbud_net_stddev
mbud_net_plot(2,:) = mbud_net_mean - mbud_net_stddev

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
  opts@xyDashPatterns = (/0,2,2/)
  opts@xyLineThicknesses = (/3.0,3.0,3.0/)
  opts@tiYAxisString     = "Mass Budget Components (cm/day)"
  opts@trYMinF           = -3.5
  opts@trYMaxF           = 1.5

; resources for text
  txres = True
  txres@txFontHeightF = 0.015
  txres@txFontThicknessF = 2.0

  ; net budget
  opts_n = opts
  opts_n@xyLineColors = (/"black","black","black"/)
  txres_n = txres
  txres_n@txFontColor = "black"
  x_n = 275.0
  y_n = 1.3
  str_n = prefix+" Net Mass Budget"

  ; meltb
  opts_b = opts
  opts_b@xyLineColors = (/"firebrick","firebrick","firebrick"/)
  txres_b = txres
  txres_b@txFontColor = "firebrick"
  x_b = 275.0
  y_b = 1.1
  str_b = "Bottom Melt"

  ; meltt
  opts_t = opts
  opts_t@tiMainString = ""
  opts_t@xyLineColors = (/"darkorange","darkorange","darkorange"/)
  txres_t = txres
  txres_t@txFontColor = "darkorange"
  x_t = 275.0
  y_t = 0.9
  str_t = "Top melt"

  ; meltl
  opts_l = opts
  opts_l@tiMainString = ""
  opts_l@xyLineColors = (/"gold","gold","gold"/)
  txres_l = txres
  txres_l@txFontColor = "gold"
  x_l = 275.0
  y_l = 0.7
  str_l = "Lateral melt"

  ; congel
  opts_c = opts
  opts_c@xyLineColors = (/"blue","blue","blue"/)
  txres_c = txres
  txres_c@txFontColor = "blue"
  x_c = 275.0
  y_c = 0.5
  str_c = "Congelation Growth"

  ; frazil
  opts_f = opts
  opts_f@tiMainString = ""
  opts_f@xyLineColors = (/"deepskyblue","deepskyblue","deepskyblue"/)
  txres_f = txres
  txres_f@txFontColor = "deepskyblue"
  x_f = 275.0
  y_f = 0.3
  str_f = "Frazil Growth"

  ; snowice
  opts_s = opts
  opts_s@tiMainString = ""
  opts_s@xyLineColors = (/"green","green","green"/)
  txres_s = txres
  txres_s@txFontColor = "green"
  x_s = 275.0
  y_s = 0.1
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
 fout1 = outdir+"supp_fig_4_mass_budget_meltseason_along_track_"+track
 wks = gsn_open_wks("ps" ,fout1)
 plot = new(1, graphic)    ; one cross section plot and one spatial plot

   ; Plot along track info
   opts_b@tiMainString = "" ;Mass Budget Along LENS Tracks"
   ; meltb
   lplot = gsn_csm_xy(wks,xdata_leg,meltb_plot,opts_b)
   ; meltt
   oplot = gsn_csm_xy(wks,xdata_leg,meltt_plot,opts_t)
   overlay(lplot,oplot)
   ; meltl
   oplot = gsn_csm_xy(wks,xdata_leg,meltl_plot,opts_l)
   overlay(lplot,oplot)
   ; congel
   oplot = gsn_csm_xy(wks,xdata_leg,congel_plot,opts_c)
   overlay(lplot,oplot)
   ; frazil
   oplot = gsn_csm_xy(wks,xdata_leg,frazil_plot,opts_f)
   overlay(lplot,oplot)
   ; snoice
   oplot = gsn_csm_xy(wks,xdata_leg,snoice_plot,opts_s)
   overlay(lplot,oplot)
   oplot = gsn_csm_xy(wks,xdata_leg,mbud_net_plot,opts_n)
   overlay(lplot,oplot)
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
