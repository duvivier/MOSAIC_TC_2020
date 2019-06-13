;***************************************
; PROGRAM DESCRIPTION: Plot seasonal cycle of ice surface variables
; INPUT DATA: Ensemble track data, ensemble model data interpolated
;                      to tracks
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
  ;  varcode = "fs"
; ******************************************************
; BEGIN SCRIPT
print("Getting "+varcode+" for Perennial and Seasonal Arctic")

; set the files info
  yy_in_1 = "2021"
  yy_in_2 = "1980"
  case_1 = "b.e11.BRCP85C5CNBDRD.f09_g16"
  case_2 = "b.e11.B20TRC5CNBDRD.f09_g16"
  years_1 = "20210101-20221231"
  years_2 = "19800101-19811231"
  track_1 = "st_85_125_oct15"
  track_2 = "st_hist_85_125_oct15"

; paths
indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/"+track_1
indir_LENS_1 = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track_1
indir_LENS_2 = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track_2

; years
yy_start_1 = stringtofloat(yy_in_1)
yy_end_1 = yy_start_1+1
yy_start_2 = stringtofloat(yy_in_2)
yy_end_2 = yy_start_2+1

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

; replace nans (from Matlab calculations...) with _FillValue
replace_ieeenan(lat_track,lat_track@_FillValue,0)
replace_ieeenan(lon_track,lon_track@_FillValue,0)

;;;;;;;;;;;;;
; convert to date array
;;;;;;;;;;;;;
track_dates = new(ndays,"string")
mm_dd = new(ndays,"string")
d = 0
do d = 0, ndays-1
   mm_dd(d) = flt2string(mm_track(d))+"-"+flt2string(dd_track(d)) 
   if(mm_track(d) .lt. 10.0)
      track_dates(d) = flt2string(yy_end_1)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
   end if
   if(mm_track(d) .eq. 10.0)
      if (dd_track(d) .ge. 15)
         track_dates(d) = flt2string(yy_start_1)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
      end if
      if (dd_track(d) .lt. 15)
         track_dates(d) = flt2string(yy_end_1)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
      end if      
   end if
   if(mm_track(d) .gt. 10.0)
      track_dates(d) = flt2string(yy_start_1)+"-"+flt2string(mm_track(d))+"-"+flt2string(dd_track(d))
   end if   
end do

; first of each month
label_inds = (/17,47,78,109,137,168,198,229,259,290,321,351/)

delete([/indir,innames/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load LENS liits data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; Get LENS data for first year (pre-post processed to tracks)
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS_1
innames   = systemfunc("ls "+indir+"/LENS_"+varcode+"_*_"+years_1+"_"+track_1+".nc")
fin = addfile(innames(0),"r")
data_tracks_1 = fin->data_tracks
units = data_tracks_1@units
name = data_tracks_1@long_name

; get data dimensions
dims = dimsizes(data_tracks_1)
ntracks = dims(0)

if (varcode .eq. "fs")
  data_tracks_1 = data_tracks_1 *100.0
  units = "%"
end if

; Basic stats for all ensembles, all tracks
ens_mean_1 = dim_avg_n_Wrap(data_tracks_1,0)
ens_stddev_1 = dim_stddev_n_Wrap(data_tracks_1,0)
ens_plus_1 = ens_mean_1 + ens_stddev_1
ens_plus_1 = where(ens_plus_1 .gt. 100.0, 100.0, ens_plus_1)
ens_minus_1 = ens_mean_1 - ens_stddev_1
ens_minus_1 = where(ens_minus_1 .lt. 0.0, 0.0, ens_minus_1)

; overlay plotting array
data_overlay_1 = new((/3,ndays/),typeof(data_tracks_1))
data_overlay_1(0,:) = ens_mean_1
data_overlay_1(1,:) = ens_plus_1
data_overlay_1(2,:) = ens_minus_1

;;;;;;;;;;;;;
; Get LENS data for second year (pre-post processed to tracks)
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS_2
innames   = systemfunc("ls "+indir+"/LENS_"+varcode+"_*_"+years_2+"_"+track_2+".nc")
fin = addfile(innames(0),"r")
data_tracks_2 = fin->data_tracks

if (varcode .eq. "fs")
  data_tracks_2 = data_tracks_2 *100.0
end if

; Basic stats for all ensembles, all tracks
ens_mean_2 = dim_avg_n_Wrap(data_tracks_2,0)
ens_stddev_2 = dim_stddev_n_Wrap(data_tracks_2,0)
ens_plus_2 = ens_mean_2 + ens_stddev_2
ens_plus_2 = where(ens_plus_2 .gt. 100.0, 100.0, ens_plus_2)
ens_minus_2 = ens_mean_2 - ens_stddev_2
ens_minus_2 = where(ens_minus_2 .lt. 0.0, 0.0, ens_minus_2)

; overlay plotting array
data_overlay_2 = new((/3,ndays/),typeof(data_tracks_2))
data_overlay_2(0,:) = ens_mean_2
data_overlay_2(1,:) = ens_plus_2
data_overlay_2(2,:) = ens_minus_2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get max and min limits for plots
; Also set legend locations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (varcode .eq. "aice")
   pref = "Ice concentration"
   ymin = 15.0
   ymax = 100.0
   xmin = 0.0
   xmax = 365.0
   x_e = 100.0
   y_e = 30.0
   x_s = x_e
   y_s = 25.0
   x_h = x_e
   y_h = 20.0
end if
if (varcode .eq. "hi")
   pref = "Ice thickness"
   ymin = 0.0
   ymax = 5.5
   xmin = 0.0
   xmax = 365.0   
   x_e = 100.0
   y_e = 5.2
   x_s = x_e
   y_s = 4.8
   x_h = x_e
   y_h = 4.4
end if
if (varcode .eq. "hs")
   pref = "Snow depth"
   ymin = 0.0
   ymax = 0.7
   xmin = 198.0
   xmax = 336.0
   x_s = 302.0
   y_s = 0.65
   x_h = x_s
   y_h = 0.6
end if
if (varcode .eq. "fs")
   pref = "Snow fraction"
   ymin = 0.0
   ymax = 100.0
   xmin = 198.0
   xmax = 336.0
   x_s = 232.0
   y_s = 33.0
   x_h = x_s
   y_h = 26.0
end if
if (varcode .eq. "apond")
   pref = "Pond fraction"
   ymin = 0.0
   ymax = 45.0
   xmin = 198.0
   xmax = 336.0
   x_s = 232.0
   y_s = 40.0
   x_h = x_s
   y_h = 37.0
end if
if (varcode .eq. "albedo")
   pref = "Albedo"
   ymin = 0.4
   ymax = 1.0
   xmin = 198.0
   xmax = 336.0
   x_s = 232.0
   y_s = 0.5
   x_h = x_s
   y_h = 0.45
end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Plotting "+varcode)

; array against which to plot 
xdata_leg = ispan(0,(ndays-1),1)

; set outdir and fout names
   outdir = "./"
   fout1 = outdir+"supp_fig_5_"+varcode+"_mosaic"

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
  opts@trXMinF                     = xmin
  opts@trXMaxF                     = xmax
  opts@tiXAxisString               = "Date" 
  opts@tiYAxisString               = pref+" ("+units+")"
  opts@trYMinF                     = ymin
  opts@trYMaxF                     = ymax
  opts@gsnXRefLine                 = (/198.0,229.0,259.0,290.0,321.0/)
  opts@gsnXRefLineDashPattern      = 2
  opts@gsnXRefLineColor            = "black"
  opts@gsnYRefLine                 = 0.0
  opts@gsnYRefLineDashPattern      = 2
  opts@gsnYRefLineColor            = "black"
  opts@tiXAxisFontHeightF          = 0.02 ;0.03              ; set font size for x axis
  opts@tmXBLabelFontHeightF        = 0.02              ; set tick mark label size for x axis
  opts@tmXBLabelAngleF             = 45.0
  opts@tiYAxisFontHeightF          = 0.02              ; set font size for y axis
  opts@tmYLLabelFontHeightF        = 0.02              ; set tick mark label size for y axis

; resources for NEW arctic
  opts_s = opts
  opts_s@tiMainOn = False
  opts_s@xyMarkLineModes = (/"Lines","Lines","Lines"/)
  opts_s@xyMonoLineColor = False
  opts_s@xyLineColors = (/"blue","blue","blue"/)
  opts_s@xyDashPatterns = (/0,1,1/)
  opts_s@xyLineThicknesses = (/4.0,4.0,4.0/)

; resources for OLD arctic
  opts_h = opts
  opts_h@tiMainOn = False
  opts_h@xyMarkLineModes = (/"Lines","Lines","Lines"/)
  opts_h@xyMonoLineColor = False
  opts_h@xyLineColors = (/"firebrick","firebrick","firebrick"/)
  opts_h@xyDashPatterns = (/0,1,1/)
  opts_h@xyLineThicknesses = (/4.0,4.0,4.0/)

; resources for text
  txres = True
  txres@txFontHeightF = 0.0175
  txres@txFontThicknessF = 2.0
  ; ensemble mean
  txres_s = txres
  txres_s@txFontColor = "blue"
  str_s = "Seasonal ensemble mean"
  ; hemispheric mean
  txres_h = txres
  txres_h@txFontColor = "firebrick"
  str_h = "Perennial ensemble mean"
  
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
 wks = gsn_open_wks("ps" ,fout1)
 plot = new(1, graphic)    ; one cross section plot and one spatial plot

   ; do actual plotting
   lplot = gsn_csm_xy(wks,xdata_leg,data_overlay_1,opts_s)
   oplot = gsn_csm_xy(wks,xdata_leg,data_overlay_2,opts_h)
   overlay(lplot,oplot)
   dum1 = new(1,graphic)
   dum1 = gsn_add_text(wks,lplot,str_s,x_s,y_s,txres_s)
   dum2 = new(1,graphic)
   dum2 = gsn_add_text(wks,lplot,str_h,x_h,y_h,txres_h)   
   plot(0) = lplot

;;;;;;;;;;;;;
; Final Plots
;;;;;;;;;;;;;
  ; make panel plot
  ;pnlres@txString  = "LENS "+yy_in+" "+name+" along possible Mosaic tracks"
  gsn_panel(wks,(/plot/),(/1,1/),pnlres)                   ; create final panel plot
  delete(wks)
  print("converting to png")
  system("convert -trim -border 5 -bordercolor white -density 300 "+  \
         "-rotate -90 -trim -border 5 "+fout1+".ps "+fout1+".png")

delete(plot)

;;;;;;;;;;;;;;;;;;;;;; END script
end
