;***************************************
; PROGRAM DESCRIPTION: Plot spatial ice variables and 
;                      associated floe tracks.
; INPUT DATA: Ensemble track data, ensemble model data, most
;                      probable track.
; OUTPUT DATA: Plot of 3 randomly selected ensemble members
;                      and ensemble mean for variable chosen.
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
  ;varcode = "hi"
  ;track = "st_85_125_oct15"
  ;case = "b.e11.BRCP85C5CNBDRD.f09_g16"
  ;years = "20210101-20221231"
; ******************************************************
; BEGIN SCRIPT
date_in = "1980-10-15"  ; set date manually
print("Getting "+varcode+" for "+date_in)

; paths
indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/"+track
indir_LENS = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/ice/proc/tseries/daily/"+varcode+"_d/"
indir_aice_LENS = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/ice/proc/tseries/daily/aice_d/"
indir_p    = "/project/ppc/duvivier/projects/mosaic/analysis/paper_figures/version_6/fig_1_maps_tracks_most_probable/files/"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get liits track info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; get liits tracks
;;;;;;;;;;;;;
innames   = systemfunc("ls "+indir_track+"/*.txt")
; get dimensions for array
ntracks = dimsizes(innames)
ndays = 366
ncol = 5   ; number of columns
nhead = 1   ; number of header lines to ignore

; preallocate data
yy_track = new((/ndays/),"float")
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
      yy_track = (/data(:,0)/)
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
; get most probable track
;;;;;;;;;;;;;
innames_p   = systemfunc("ls "+indir_p+"/*.txt")

; 1980 data
data = asciiread(innames_p(0),-1,"string")
delim = ","
prob_dates = str_get_field(data,1,delim)
prob_lat = tofloat(str_get_field(data,2,delim))
prob_lon = tofloat(str_get_field(data,3,delim))
delete(data)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load LENS data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; Get LENS dates
;;;;;;;;;;;;;
; path to the data of interest
indir  = indir_LENS
innames   = systemfunc("ls "+indir+"/"+case+".???-mosaic.cice.h1.*"+years+".nc")
nensembles = dimsizes(innames)

; get lat/lon 2d data
f0 = addfile(innames(0),"r")
lat2d = f0->TLAT
lon2d = f0->TLON
dims = dimsizes(lat2d)
nlat = dims(0)
nlon = dims(1)

; get times
time = cd_calendar(f0->time,0)
LENS_dates = flt2string(time(:,0))+"-"+flt2string(time(:,1))+"-"+flt2string(time(:,2))

; based on user inputs, get specific time index that you want to plot
date_ind = ind(LENS_dates .eq. date_in)

delete([/indir,innames/])

;;;;;;;;;;;;;
; Load LENS concentrations
;;;;;;;;;;;;;
; paths
indir  = indir_aice_LENS
var_in = "aice_d"
innames   = systemfunc("ls "+indir+"/"+case+".???-mosaic.cice.h1.*"+years+".nc")

; preallocate
data_aice_all = new((/nensembles, nlat, nlon/), float)

e = 0
do e = 0, nensembles -1
  fin = addfile(innames(e),"r")
  if (e .eq. 0)
     dum = fin->$var_in$(0,0,0)
     units_aice = dum@units
     name_aice = dum@long_name
     delete(dum)
  end if
  data_aice_all(e,:,:) = fin->$var_in$(date_ind,:,:)
end do

delete([/indir,var_in,innames/])

; Get average and variance of LENS fields - before masking!
data_aice_avg = dim_avg_n_Wrap(data_aice_all,0)
data_aice_stddev = dim_stddev_n_Wrap(data_aice_all,0)

;;;;;;;;;;;;;
; Load LENS variable
;;;;;;;;;;;;;
; paths
indir  = indir_LENS
var_in = varcode+"_d"
innames   = systemfunc("ls "+indir+"/"+case+".???-mosaic.cice.h1.*"+years+".nc")

; preallocate
data_all = new((/nensembles, nlat, nlon/), float)

e = 0
do e = 0, nensembles -1
  fin = addfile(innames(e),"r")
  if (e .eq. 0)
     dum = fin->$var_in$(0,0,0)
     units = dum@units
     name = dum@long_name
     delete(dum)
  end if
  data_all(e,:,:) = fin->$var_in$(date_ind,:,:)
end do

delete([/indir,var_in,innames/])

; Get average and variance of LENS fields - before masking!
data_avg = dim_avg_n_Wrap(data_all,0)
data_stddev = dim_stddev_n_Wrap(data_all,0)

;;;;;;;;;;;;;
; mask for plotting
;;;;;;;;;;;;;
;return
;; mask everything that is <5% conc
;data_all = where(data_all .lt. 5.0, data_all@_FillValue, data_all)
;data_avg = where(data_avg .lt. 5.0, data_avg@_FillValue, data_avg)

;;;;;;;;;;;;;
; assign lat/lon
;;;;;;;;;;;;;
data_all@lat2d = lat2d
data_all@lon2d = lon2d
data_avg@lat2d = lat2d
data_avg@lon2d = lon2d

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print ("Creating plot")

; set variable specific info
if (varcode .eq. "aice")
  CM = "julies"
  NH_cntrs=(/1,5,15,30,40,50,60,70,80,85,90,95/)
end if
if (varcode .eq. "hi")
  CM = "julies"
  NH_cntrs=(/0.25,0.5,1.0,1.5,2.0,2.5,3.0,3.5/) ; regular spacing
  ;NH_cntrs=(/0,0.3,0.6,1.0,1.4,1.9,2.4,3.0,3.6/) ; by category spacing
end if
if (varcode .eq. "iage")
  CM = "julies"
  NH_cntrs=(/0.25,0.5,0.75,1.0,1.5,2.0,3.0,4.0/)
end if

; define output file
  fout = "fig_3_"+varcode+"_LENS_maps_on_"+date_in

; output file
  wks_type = "ps" 
  wks = gsn_open_wks(wks_type,fout)
  gsn_define_colormap(wks,CM)

  res                     = True          ; plot mods desired
  res@gsnDraw             = False         ; don't draw the plot yet
  res@gsnFrame            = False         ; or the frame
  res@cnLinesOn           = False         ; turn off contour lines
  res@txFontHeightF       = 0.030          ; set subtitle text font
  res@gsnLeftString       = ""
  res@gsnRightString      = ""
  res@gsnCenterString     = ""

  ; contour resources for everything
  res@cnFillOn            = True          ; turn on color
  res@cnFillMode          = "AreaFill"
  res@cnLinesOn           = False
  res@lbLabelBarOn        = False ;True         ; turn off label bars
  res@cnInfoLabelOn       = False         ; turn off contour info labels
  res@cnLineLabelsOn      = False 
  res@cnMissingValFillColor = "white"
  res@cnLevelSelectionMode    = "ExplicitLevels"
  
; Map resources for main dataset
  res@gsnPolar             = "NH"
  res@mpMinLatF            = 70.0
  res@mpGridAndLimbOn      = False            ; Turn on lat/lon grid
  res@mpFillOn             = True             ; Enables map fill
  res@mpGridAndLimbOn      = False    ; set to true to show lat and lon lines
  res@mpLandFillColor      = "grey"
  res@mpGeophysicalLineColor      = "black"          ; Color of continents
  res@mpGeophysicalLineThicknessF = 1.5
  res@gsnSpreadColorStart        = 4
  res@gsnSpreadColorEnd          = 18
  res@trGridType                 = "TriangularMesh"
  res@cnLevels            = NH_cntrs

; set line res to show mosaic tracks
  lnres                            = True
  lnres@gsLineThicknessF          = 2.0
  lnres@gsLineColor               = "black"

; start marker res
  mkres = True
  mkres@gsMarkerColor = "black"
  mkres@gsMarkerIndex = 5
  mkres@gsMarkerSizeF = 0.015
  mkres@gsMarkerThicknessF = 3.0

; Set panel resources
  pnlres                            = True
  pnlres@txFontHeightF              = 0.013
  pnlres@gsnPaperOrientation        = "landscape"      ; landscape mode
  pnlres@gsnMaximize                = True             ; fill the page
  pnlres@gsnPanelYWhiteSpacePercent = 2                ; Add white space b/w plots.
  pnlres@gsnPanelXWhiteSpacePercent = 2                ; Add white space b/w plots.
  pnlres@gsnPanelScalePlotIndex     = 1
  pnlres@gsnMaximize                = True	       ; fill the page
  pnlres@gsnPanelLabelBar           = True
  ;pnlres@lbOrientation              = "vertical"
  ;pnlres@lbLabelStride              = 1
  pnlres@lbTitleString              = units
  pnlres@lbTitlePosition            = "Right"
  pnlres@lbTitleFontHeightF         = 0.015
  pnlres@lbTitleDirection           = "Across"

;;;;;;;;;;;;;
; Make individual plots
;;;;;;;;;;;;;
print ("Plotting ice area")
   plot = new(4, graphic)
   dum0 = new(4,graphic)
   dum1 = new(4,graphic)

; individual ensemble members

;ens 2:
n = 0
e = 1
res@gsnCenterString = "" ;Ens."+(e+1)
plot(n) = gsn_csm_contour_map(wks,data_all(e,:,:),res)
dum0(n) = gsn_add_polyline(wks,plot(n),lon_track(e,:),lat_track(e,:),lnres)
dum1(n) = gsn_add_polymarker(wks,plot(n),lon_track(e,0),lat_track(e,0),mkres)

;ens 20:
n = 1
e = 19
res@gsnCenterString = "" ;Ens."+(e+1)
plot(n) = gsn_csm_contour_map(wks,data_all(e,:,:),res)
dum0(n) = gsn_add_polyline(wks,plot(n),lon_track(e,:),lat_track(e,:),lnres)
dum1(n) = gsn_add_polymarker(wks,plot(n),lon_track(e,0),lat_track(e,0),mkres)

;ens 26:
n = 2
e = 25
res@gsnCenterString = "" ;Ens."+(e+1)
plot(n) = gsn_csm_contour_map(wks,data_all(e,:,:),res)
dum0(n) = gsn_add_polyline(wks,plot(n),lon_track(e,:),lat_track(e,:),lnres)
dum1(n) = gsn_add_polymarker(wks,plot(n),lon_track(e,0),lat_track(e,0),mkres)

; ensemble mean
n = 3
res@gsnCenterString     = "" ;Ensemble Mean"
plot(n) = gsn_csm_contour_map(wks,data_avg,res)
dum0(n) = gsn_add_polyline(wks,plot(n),prob_lon,prob_lat,lnres)
dum1(n) = gsn_add_polymarker(wks,plot(n),lon_track(e,0),lat_track(e,0),mkres)

;;;;;;;;;;;;;
; Panel plot
;;;;;;;;;;;;;
print("Paneling")
  ; make panel plot
  ;pnlres@txString  = date_in
  gsn_panel(wks,(/plot/),(/1,4/),pnlres)                   ; create final panel plot
  delete(wks)
  print("converting to png")
  system("convert -trim -border 5 -bordercolor white -density 300 "+  \
         "-rotate -90 -trim -border 5 "+fout+".ps "+fout+".png")

print("Done with all ens plots. Hooray!")
;;;;;;;;;;;;;;;;;;;;;; END script
end
