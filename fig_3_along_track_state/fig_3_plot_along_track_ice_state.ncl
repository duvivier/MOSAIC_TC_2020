;***************************************
; PROGRAM DESCRIPTION: Plot seasonal cycle of ice variables
;                      along floe tracks.
; INPUT DATA: Ensemble track data, ensemble model data interpolated
;                      to tracks
; OUTPUT DATA: Line plot showing seasonal cycle for each ensemble,
;                      ensemble mean and stddev, and 70-90N mean.
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
  ;  varcode = "fs"
  ;  case = "b.e11.BRCP85C5CNBDRD.f09_g16"
  ;  years = "20210101-20221231"
  ;  track = "st_85_125_oct15"
  ;  track2 = "70_90_N"
; ******************************************************
; BEGIN SCRIPT
print("Getting "+varcode+" for year "+yy_in)

; paths
indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/"+track
indir_LENS = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track
indir_hemi = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track2

yy_start = stringtofloat(yy_in)
yy_end = yy_start+1

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
; Load LENS liits data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; Get LENS data (pre-post processed to tracks)
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS
innames   = systemfunc("ls "+indir+"/LENS_"+varcode+"_*_"+years+"_"+track+".nc")
fin = addfile(innames(0),"r")
data_tracks = fin->data_tracks
units = data_tracks@units
name = data_tracks@long_name

; get data dimensions
dims = dimsizes(data_tracks)
ntracks = dims(0)

if (varcode .eq. "fs")
  data_tracks = data_tracks *100.0
  units = "%"
end if

;;;;;;;;;;;;;
; Basic liits stats
;;;;;;;;;;;;;
; stats for all ensembles, all tracks
ens_mean = dim_avg_n_Wrap(data_tracks,0)
ens_stddev = dim_stddev_n_Wrap(data_tracks,0)
ens_plus = ens_mean + ens_stddev
ens_plus = where(ens_plus .gt. 100.0, 100.0, ens_plus)
ens_minus = ens_mean - ens_stddev
ens_minus = where(ens_minus .lt. 0.0, 0.0, ens_minus)

; overlay plotting array
data_overlay = new((/3,ndays/),typeof(data_tracks))
data_overlay(0,:) = ens_mean
data_overlay(1,:) = ens_plus
data_overlay(2,:) = ens_minus

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load LENS hemispheric average data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; Get LENS data (pre-post processed to 70_90N)
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_hemi
innames   = systemfunc("ls "+indir+"/LENS_"+varcode+"_*_"+years+"_"+track2+".nc")
fin = addfile(innames(0),"r")
data_hemi = fin->data_tracks

if (varcode .eq. "fs")
  data_hemi = data_hemi *100.0
end if

;;;;;;;;;;;;;
; Basic hemi stats, for plotting
;;;;;;;;;;;;;
; stats for all ensembles, all tracks
hemi_mean = dim_avg_n_Wrap(data_hemi,0)
hemi_stddev = dim_stddev_n_Wrap(data_hemi,0)
hemi_plus = hemi_mean + hemi_stddev
hemi_minus = hemi_mean - hemi_stddev
hemi_minus = where(hemi_minus .lt. 0.0, 0.0, hemi_minus)

; overlay plotting array
hemi_overlay = new((/3,ndays/),typeof(data_tracks))
hemi_overlay(0,:) = hemi_mean
hemi_overlay(1,:) = hemi_plus
hemi_overlay(2,:) = hemi_minus

;;;;;;;;;;;;;
; Monthly hemi stats, for plotting
;;;;;;;;;;;;;
; array of months
months = (/10.0,11.0,12.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0/)
nmonths = dimsizes(months)
; indicies midway through the month
mid_month_inds = (/0,31,61,92,123,151,182,212,243,273,304,335/)
hemi_monthly_mean = new((/ndays/),typeof(data_hemi))
hemi_monthly_stddev = new((/ndays/),typeof(data_hemi))
; loop through months
m = 0
do m = 0, nmonths -1
   inds = ind(mm_track .eq. months(m))
   data_tmp = data_hemi(:,inds)
   hemi_monthly_mean(mid_month_inds(m)) = avg(data_tmp)
   hemi_monthly_stddev(mid_month_inds(m)) = stddev(data_tmp)
   delete([/inds,data_tmp/])
end do
; assign final date
hemi_monthly_mean(365) = hemi_monthly_mean(0)
hemi_monthly_stddev(365) = hemi_monthly_stddev(0)

hemi_monthly_plus = hemi_monthly_mean + hemi_monthly_stddev
hemi_monthly_minus = hemi_monthly_mean - hemi_monthly_stddev
hemi_monthly_minus = where(hemi_monthly_minus .lt. 0.0, 0.0, hemi_monthly_minus)

; overlay plotting array
hemi_monthly_overlay = new((/3,ndays/),typeof(data_tracks))
hemi_monthly_overlay(0,:) = hemi_monthly_mean
hemi_monthly_overlay(1,:) = hemi_monthly_plus
hemi_monthly_overlay(2,:) = hemi_monthly_minus

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get max and min limits for plots
; Also set legend locations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (yy_in .eq. "2021")
prefix = "Seasonal"
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
   ymax = 1.0
   xmin = 198.0
   xmax = 351.0
   x_e = 306.0
   y_e = 0.9
   x_s = x_e
   y_s = 0.8
   x_h = x_e
   y_h = 0.7
end if
end if

if (yy_in .eq. "1980")
prefix = "Perennial"
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
   y_e = 1.0
   x_s = x_e
   y_s = 0.6
   x_h = x_e
   y_h = 0.2
end if
if (varcode .eq. "hs")
   pref = "Snow depth"
   ymin = 0.0
   ymax = 1.0
   xmin = 197.0
   xmax = 350.0
   x_e = 306.0
   y_e = 0.9
   x_s = x_e
   y_s = 0.8
   x_h = x_e
   y_h = 0.7
end if
end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Plotting "+varcode)

; array against which to plot 
xdata_leg = ispan(0,(ndays-1),1)

; set outdir and fout names
   outdir = "./"
   fout1 = outdir+"fig_3_"+varcode+"_along_track_"+track

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
  if (yy_in .eq. "2021")
     opts@gsnXRefLine                 = (/198.0,229.0,259.0,290.0,321.0/)
  end if
  if (yy_in .eq. "1980")
     opts@gsnXRefLine                 = (/197.0,228.0,258.0,289.0,320.0/)
  end if  
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

; resources for all ensembles
  opts_e = opts
  opts_e@xyMarkLineMode = "Lines"
  opts_e@xyMonoLineColor = True
  opts_e@xyLineColor = "grey50"
  opts_e@xyDashPattern = 0
  opts_e@xyLineThicknessF = 1.0

; resources for ensembles' stats lines
  opts_s = opts
  opts_s@tiMainOn = False
  opts_s@xyMarkLineModes = (/"Lines","Lines","Lines"/)
  opts_s@xyMonoLineColor = False
  opts_s@xyLineColors = (/"black","black","black"/)
  opts_s@xyDashPatterns = (/0,1,1/)
  opts_s@xyLineThicknesses = (/2.0,2.0,2.0/)

; resources for 70_90_N daily mean
  opts_h = opts
  opts_h@tiMainOn = False
  opts_h@xyMarkLineModes = (/"Lines","Lines","Lines"/)
  opts_h@xyMonoLineColor = False
  opts_h@xyLineColors = (/"firebrick","firebrick","firebrick"/)
  opts_h@xyDashPatterns = (/0,1,1/)
  opts_h@xyLineThicknesses = (/2.0,2.0,2.0/)

; resources for 70_90_N monthly mean
  opts_h2 = opts
  opts_h2@tiMainOn = False
  opts_h2@xyMarkLineModes = (/"Markers","Markers","Markers"/)
  opts_h2@xyMarkerColors = (/"firebrick","firebrick","firebrick"/)
  opts_h2@xyMarkers = (/16,16,16/)
  opts_h2@xyMarkerSizes = (/0.01,0.01,0.01/)

; resources for text
  txres = True
  txres@txFontHeightF = 0.02 ;0.03
  txres@txFontThicknessF = 2.0
  ; ensembles
  txres_e = txres
  txres_e@txFontColor = "grey50"
  str_e = prefix+" ensembles"
  ; ensemble mean
  txres_s = txres
  txres_s@txFontColor = "black"
  str_s = prefix+" ensemble mean"
  ; hemispheric mean
  txres_h = txres
  txres_h@txFontColor = "firebrick"
  str_h = prefix+" 70-90~S~o~N~N mean"
  
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

   opts_e@tiMainString = "" ;"LENS "+yy_in+" "+name+" along possible Mosaic tracks for start: "+track
   ; do actual plotting
   lplot = gsn_csm_xy(wks,xdata_leg,data_tracks,opts_e)
   oplot = gsn_csm_xy(wks,xdata_leg,data_overlay,opts_s)
   overlay(lplot,oplot)
   oplot2 = gsn_csm_xy(wks,xdata_leg,hemi_overlay,opts_h)
   overlay(lplot,oplot2)
   ;oplot3 = gsn_csm_xy(wks,xdata_leg,hemi_monthly_overlay,opts_h2)
   ;overlay(lplot,oplot3)
   dum1 = new(1,graphic)
   dum1 = gsn_add_text(wks,lplot,str_e,x_e,y_e,txres_e)
   dum2 = new(1,graphic)
   dum2 = gsn_add_text(wks,lplot,str_s,x_s,y_s,txres_s)
   dum3 = new(1,graphic)
   dum3 = gsn_add_text(wks,lplot,str_h,x_h,y_h,txres_h)   
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
