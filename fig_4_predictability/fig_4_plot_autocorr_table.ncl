;***************************************
; PROGRAM DESCRIPTION: Plot autocorrelations through year
; INPUT DATA: Ensemble track data, ensemble model data interpolated
;                      to tracks
; OUTPUT DATA: Table showing autocorrelation for each variable.
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
  ;  varcode = "aice"
  ;  case = "b.e11.BRCP85C5CNBDRD.f09_g16"
  ;  years = "20210101-20221231"
  ;  track = "st_85_125_oct15"
; ******************************************************
; BEGIN SCRIPT
print("Getting data for year "+yy_in)

; paths
indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/"+track
indir_LENS = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/liits_track_subset/ice/"+track

yy_start = stringtofloat(yy_in)
yy_end = yy_start+1

; vars with which to get autocorrelations
varcodes = (/"aicen005","aicen004","aicen003","aicen002","aicen001","aice","hi"/)
ynames = (/"CON5","CON4","CON3","CON2","CON1","CON","TH"/)
nvars = dimsizes(varcodes)

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
if (track .eq.  "st_85_125_oct15")
   start_str = "a)    NEW Start on Oct.15"
   label_inds = (/0,17,47,78,109,137,168,198,229,259,290,321/)
end if
if (track .eq.  "st_hist_85_125_oct15")
   start_str = "b)    OLD Start on Oct.15"
   label_inds = (/0,16,46,77,108,136,167,197,228,258,289,320/)
   mm_dd(0) = "10-15"
end if
if (track .eq.  "st_85_125_oct1")
   start_str = "c)    NEW Start on Oct.1"
   label_inds = (/0,14,45,75,106,137,165,196,226,257,287,318/)
end if
if (track .eq.  "st_hist_85_125_oct1")
   start_str = "b)    OLD Start on Oct.1"
   label_inds = (/0,13,44,74,105,136,164,195,225,256,286,317/)
   mm_dd(0) = "10-1"
end if
nsubset = dimsizes(label_inds)
delete([/indir,innames/])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load LENS data and calculate correlations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
data_all = new((/nvars,ntracks,ndays/),"float")
corr_all = new((/nvars,nsubset/),"float")
sig_all = new((/nvars,nsubset/),"float")

n =  0
do n = 0, nvars -1
   ; path to the data of interest
   innames   = systemfunc("ls "+indir_LENS+"/LENS_"+varcodes(n)+"_mosaic*"+years+"_"+track+".nc")
   fin = addfile(innames(0),"r")
   data_all(n,:,:) = fin->data_tracks
   delete([/innames,fin/])
   ; calculate correlations
   m = 0
   do m = 0, nsubset -1
      corr_all(n,m) = escorc(data_all(n,:,0),data_all(n,:,label_inds(m)))
      ; use r-test to check correlation's significance. If value is >= 95,
      ; it's at the 95% significance level
      sig_all(n,m) = 100.*(1-rtest(corr_all(n,m),ntracks,0))
   end do
end do

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Plotting table")
 outdir = "./"
 fout1 = outdir+"fig_4_autocorr_table_"+track
 title_fin = start_str+" start" ;: Correlation With Initial Value"

; arrays against which to give values 
xdata = ispan(0,(nsubset-1),1)
nx = dimsizes(xdata)
ydata = ispan(0,(nvars-1),1)
ny = dimsizes(ydata)
cor_levs = (/-0.95,-0.9,-0.85,-0.8,-0.75,-0.7,-0.6,-0.5,-0.25,0.0,0.25,0.5,0.6,0.7,0.75,0.8,0.85,0.9,0.95/)

;;;;;;;;;;;;;
; Raster contour plot resources
;;;;;;;;;;;;;
; set resources used for all plots
  opts                             = True              ; plot mods desired
  opts@gsnFrame                    = False             ; Do not draw plot 
  opts@gsnDraw                     = False             ; Do not advance frame
  opts@gsnMaximize                 = False             ; maximize plot
  opts@vpWidthF                    = 1.5
  opts@vpHeightF                   = 0.75
  opts@sfXArray                    = ispan(0,nsubset,1)  ; forces full boxes at edges
  opts@sfYArray                    = ispan(0,nvars,1)

; set title resources
  opts@tiMainOn                    = False
  opts@tmXBOn                      = True
  opts@tiXAxisFontHeightF          = 0.03      
  opts@tmXBLabelFontHeightF        = 0.03      
  opts@tiYAxisFontHeightF          = 0.03      
  opts@tmYLLabelFontHeightF        = 0.03      

; contour resources
  opts@cnFillOn                    = True
  opts@cnFillMode                  = "RasterFill"
  opts@cnLinesOn                   = False
  opts@cnFillPalette               = "BlueDarkRed18"
  opts@cnLevelSelectionMode        = "ExplicitLevels"
  opts@cnLevels                    = cor_levs

; label bar
  opts@lbLabelBarOn                = True
  opts@lbLabelFontHeightF          = 0.03
  opts@lbLabelStride               = 1

; axis resources  
  ; X axis
  opts@tiXAxisString               = "" ;Date"
  opts@tmXBMode                    = "Explicit"
  opts@tmXBValues                  = xdata + 0.5 
  opts@tmXBLabels                  = mm_dd(label_inds)
  opts@tmXBLabelFontHeightF        = 0.03 
  opts@tmXBLabelAngleF             = 45.0
  opts@tmXBMajorLengthF            = 0.0
  opts@tmXBMinorValues             = xdata
  ; Y axis
  opts@tiYAxisString               = "" ;Variable"
  opts@tmYLMode                    = "Explicit"
  opts@tmYLValues                  = ydata + 0.5
  opts@tmYLLabels                  = ynames
  opts@tmYLLabelFontHeightF        = 0.03 
  opts@tmYLMajorLengthF            = 0.0  
  opts@tmYLMinorValues             = ydata

; resources for the significance points
  ; resources for 95% significance (filled dot)
  sig_lvl_1    = 95.0
  opts_sig_1                       = True
  opts_sig_1@gsMarkerIndex         = 16
  opts_sig_1@gsMarkerSizeF         = 0.01
  ; resources for 90% significance (open dot)
  sig_lvl_2    = 90.0
  opts_sig_2                       = True
  opts_sig_2@gsMarkerIndex         = 4
  opts_sig_2@gsMarkerSizeF         = 0.01

; resources for panel plot
  pnlres                            = True
  pnlres@txFontHeightF              = 0.015
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
 dum = new((nx*ny),graphic)

 ; do actual plotting
 cplot = gsn_csm_contour(wks,corr_all,opts)

 ; add significance
 t = 0
 do j=0, ny-1
    do i=0, nx-1
        if (sig_all(j,i) .ge. sig_lvl_1)
           dum(t) = gsn_add_polymarker(wks,cplot,xdata(i)+0.5,ydata(j)+0.5,opts_sig_1)
        end if
        if ((sig_all(j,i) .lt. sig_lvl_1) .and. (sig_all(j,i) .ge. sig_lvl_2))
           dum(t) = gsn_add_polymarker(wks,cplot,xdata(i)+0.5,ydata(j)+0.5,opts_sig_2)
        end if
        ; otherwise skip - don't draw a dot!
        t = t+1
    end do
 end do
 plot(0) = cplot

;;;;;;;;;;;;;
; Final Plots
;;;;;;;;;;;;;
  ; make panel plot
  ;pnlres@txString  = title_fin
  gsn_panel(wks,(/plot/),(/1,1/),pnlres)                   ; create final panel plot
  delete(wks)
  print("converting to png")
  system("convert -trim -border 5 -bordercolor white -density 300 "+  \
         "-rotate -90 -trim -border 5 "+fout1+".ps "+fout1+".png")

;;;;;;;;;;;;;;;;;;;;;; END script
end
