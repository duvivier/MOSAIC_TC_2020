;***************************************
; PROGRAM DESCRIPTION: Plot map showing likely weekly visits
; INPUT DATA: Ensemble track data, model grid information,
;                      file of counts per grid cell 
; OUTPUT DATA: Spatial raster map showing # counts per cell for
;                      given 2 week period
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
  ;  track = "st_85_125_oct15"
  ;  selectweek = 1
; ******************************************************
; BEGIN SCRIPT

; paths
if ((yy_in .eq. "2021") .or. (yy_in .eq. "1980"))
   indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/"+track
end if
if (yy_in .eq. "obs")
   indir_track = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/CDR_PATHS/"+track
end if
indir_LENS = "/project/ppc/duvivier/projects/mosaic/DATA/CESM-CAM5-BGC-LE_additional_output/ice/proc/tseries/daily/aice_d/"

yy_start = stringtofloat(yy_in)
yy_end = yy_start+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get liits track info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; get liits tracks
;;;;;;;;;;;;;
print("Loading tracks")
innames   = systemfunc("ls "+indir_track+"/*.txt")
; get dimensions for array
ntracks = dimsizes(innames)
ndays = 366
ncol = 5   ; number of columns
nhead = 1   ; number of header lines to ignore

; preallocate data
yy_track = new((/ndays/),"string")
mm_track = new((/ndays/),"string")
dd_track = new((/ndays/),"string")
date_track = new((/ndays/),"string")
lat_track = new((/ntracks,ndays/),"float")
lon_track = new((/ntracks,ndays/),"float")

; read in track lat/lons
n = 0
do n = 0, ntracks -1
   data = readAsciiTable(innames(n), ncol, "float", nhead)
   dims = dimsizes(data)
   nd = dims(0)
   if (n .eq. 1)
      yy_track = tostring(tointeger((/data(:,0)/)))
      mm_track = tostring(tointeger((/data(:,1)/)))
      dd_track = tostring(tointeger((/data(:,2)/)))
      date_track = yy_track+"-"+mm_track+"-"+dd_track
   end if
   lat_track(n,0:nd-1) = (/data(:,3)/)
   lon_track(n,0:nd-1) = (/data(:,4)/)
   delete([/data,dims,nd/])
end do

; replace nans (from Matlab calculations...) with _FillValue
replace_ieeenan(lat_track,lat_track@_FillValue,0)
replace_ieeenan(lon_track,lon_track@_FillValue,0)

delete(innames) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load Shapefiles for EEZ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Getting shapefiles")
indir_s    = "/project/ppc/duvivier/projects/mosaic/DATA/EEZ_shapefiles/"
innames_s   = systemfunc("ls "+indir_s+"/*.shp")
nshape = dimsizes(innames_s)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load LENS data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; Get LENS dates
;;;;;;;;;;;;;
print("Getting CICE lat/lon")
; path to the data of interest
indir  = indir_LENS
innames   = systemfunc("ls "+indir+"/*.???-mosaic.cice.h1.*.nc")
nensembles = dimsizes(innames)

; get lat/lon 2d data
f0 = addfile(innames(0),"r")
lat2d = f0->TLAT
lon2d = f0->TLON
dims = dimsizes(lat2d)
nlat = dims(0)
nlon = dims(1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get most probable track
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;set number of days to subset
twoweeks = 14.0
nweeks = round(tofloat(ndays)/twoweeks,3)

; load file of counts by 2 week intervals for this track
fin = addfile("./"+yy_in+"_"+track+"_counts_for_2wk_chunks.nc","r")
loc_2wk = fin->loc_2wk

; now get index of lat/lon with the highest count
; note that many of these will were manually chosen
; and I chose the "best fit" point and put it in the
; lat/lon max array
lat_2wk = new((/nweeks/),"float")
lon_2wk = new((/nweeks/),"float")
date_2wk = new((/nweeks/),"string")
lat1d = ndtooned(lat2d)
lon1d = ndtooned(lon2d)

; return
nweeks = tointeger(selectweek)

w = 0
do w = 0, nweeks -1
   ; get correct time indices for this week
   if (w .eq. 0)
      ind_st = 0     
   end if
   ind_ed = tointeger(ind_st + (twoweeks -1))
   date_2wk(w) = "Dates "+date_track(ind_st)+" to "+date_track(ind_ed)
   ; set next start index
   ind_st = ind_ed +1
   ; get count/location data for this week
   loc1d = ndtooned(loc_2wk(w,:,:))
   ; for each week set, have different "rules" to get reasonable location
   if ((w .eq. 0))
      inds = ind(loc1d .ge. 50)
      lat_2wk(w) = avg(lat1d(inds))
      lon_2wk(w) = avg(lon1d(inds))      
   end if
   if (w .eq. 1)
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = avg(lat1d(inds(2:4)))
      lon_2wk(w) = avg(lon1d(inds(2:4)))
   end if
   if ((w .eq. 2))
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = avg(lat1d(inds(1:2)))
      lon_2wk(w) = avg(lon1d(inds(1:2)))
   end if
   if ((w .eq. 3))
      inds = ind(loc1d .ge. 15)
      lat_2wk(w) = avg(lat1d(inds(1:2)))
      lon_2wk(w) = avg(lon1d(inds(1:2)))
   end if
   if ((w .eq. 4))
      inds = ind(loc1d .ge. 14)
      lat_2wk(w) = avg(lat1d(inds(1:4)))
      lon_2wk(w) = avg(lon1d(inds(1:4)))
   end if
   if ((w .eq. 5))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(1)))
      lon_2wk(w) = avg(lon1d(inds(0:1)))
   end if
   if ((w .eq. 6))
      inds = ind(loc1d .ge. 10)
      lat_2wk(w) = avg(lat1d(inds(0:4)))
      lon_2wk(w) = avg(lon1d(inds(0:4))) + 10.0
   end if
   if ((w .eq. 7))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(1))) + 0.5
      lon_2wk(w) = avg(lon1d(inds(1))) - 5.0
   end if
   if ((w .eq. 8))
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = avg(lat1d(inds(:)))
      lon_2wk(w) = avg(lon1d(inds(:)))
   end if
   if ((w .eq. 9))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(1))) + 1.0
      lon_2wk(w) = avg(lon1d(inds(1))) + 10.0
   end if
   if ((w .eq. 10))
      inds = ind(loc1d .ge. 10)
      lat_2wk(w) = avg(lat1d(inds(2))) - 0.5
      lon_2wk(w) = avg(lon1d(inds(2))) + 15.0
   end if
   if ((w .eq. 11))
      inds = ind(loc1d .ge. 16)
      lat_2wk(w) = avg(lat1d(inds(:)))
      lon_2wk(w) = avg(lon1d(inds(:)))
   end if
   if ((w .eq. 12))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(:)))
      lon_2wk(w) = avg(lon1d(inds(:)))
   end if
   if ((w .eq. 13))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(2)))
      lon_2wk(w) = avg(lon1d(inds(1))) + 20.0
   end if
   if ((w .eq. 14))
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = avg(lat1d(inds(:)))
      lon_2wk(w) = avg(lon1d(inds(:)))
   end if
   if ((w .eq. 15))
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = avg(lat1d(inds(:))) - 0.5
      lon_2wk(w) = avg(lon1d(inds(:))) - 10.0
   end if
   if ((w .eq. 16))
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = avg(lat1d(inds(:))) - 0.75
      lon_2wk(w) = avg(lon1d(inds(:)))
   end if
   if ((w .eq. 17))
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = 87.0
      lon_2wk(w) = 340.0
   end if
   if ((w .eq. 18))
      inds = ind(loc1d .ge. 16)
      lat_2wk(w) = 86.9   ;avg(lat1d(inds(1))) 
      lon_2wk(w) = 352.0  ;avg(lon1d(inds(1)))
   end if
   if ((w .eq. 19))
      inds = ind(loc1d .ge. 18)
      lat_2wk(w) = 85.97
      lon_2wk(w) = 350.0
   end if
   if ((w .eq. 20))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(:))) 
      lon_2wk(w) = avg(lon1d(inds(:)))
   end if
   if ((w .eq. 21))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(1))) 
      lon_2wk(w) = avg(lon1d(inds(1)))
   end if
   if ((w .eq. 22))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = avg(lat1d(inds(1:3))) 
      lon_2wk(w) = avg(lon1d(inds(1:2)))
   end if
   if ((w .eq. 23))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = 84.34
      lon_2wk(w) = 4.7
   end if
   if ((w .eq. 24))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = 84.24
      lon_2wk(w) = 0.0
   end if
   if ((w .eq. 25))
      inds = ind(loc1d .ge. 12)
      lat_2wk(w) = 83.87
      lon_2wk(w) = 358.0
   end if
   ; return
   delete(inds)
end do

; convert all lons to same convention
lon_2wk = where(lon_2wk .gt. 180.0, lon_2wk - 360.0, lon_2wk)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get ready for plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; get probability in one year
;prob_2wk = (loc_2wk/(30.0*twoweeks))*100.0

; assign lat/lon
loc_2wk@lat2d = lat2d
loc_2wk@lon2d = lon2d

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Zones for tracks info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Getting track zones")
  ; North Pole
  distkm = gc_latlon(90.0,180.0,87.0,180.0,5,4)
  circle = geolocation_circle(90.0,180.0,distkm,1,180,False)
  circle_lat = circle[0]
  circle_lon = circle[1]
  lats_circle = circle_lat(0,0,:)
  lons_circle = circle_lon(0,0,:)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print ("Creating plot")
; resources
  res                     = True          ; plot mods desired
  res@gsnDraw             = False         ; don't draw the plot yet
  res@gsnFrame            = False         ; or the frame
  res@cnLinesOn           = False         ; turn off contour lines
  res@txFontHeightF       = 0.020          ; set subtitle text font
  res@gsnLeftString       = ""
  res@gsnRightString      = ""
  res@gsnCenterString     = ""

  ; contour resources for everything
  res@cnFillOn            = True          ; turn on color
  res@cnFillMode          = "CellFill" ;RasterFill"
  res@cnLinesOn           = False
  res@lbLabelBarOn        = False ;True         ; turn off label bars
  res@cnInfoLabelOn       = False         ; turn off contour info labels
  res@cnLineLabelsOn      = False 
  res@cnMissingValFillColor = "white"
  res@cnLevelSelectionMode    = "ExplicitLevels"
  prob_cntrs=(/2,4,6,8,10,12,14,16,18,20,25,50/)
  res@cnLevels            = prob_cntrs
  res@cnConstFEnableFill  = True
  
; Map resources for main dataset
  res@gsnPolar             = "NH"
  res@mpMinLatF            = 82.0 ;78.0
  res@mpGridAndLimbOn      = False            ; Turn on lat/lon grid
  res@mpFillOn             = True             ; Enables map fill
  res@mpGridAndLimbOn      = False    ; set to true to show lat and lon lines
  res@mpLandFillColor      = "grey"
  res@mpGeophysicalLineColor      = "black"          ; Color of continents
  res@mpGeophysicalLineThicknessF = 1.5
  res@gsnSpreadColorStart        = 4
  res@gsnSpreadColorEnd          = 18
  res@trGridType                 = "TriangularMesh"

; start marker res
  mkres = True
  mkres@gsMarkerColor = "black"
  mkres@gsMarkerIndex = 5 ;16
  mkres@gsMarkerSizeF = 0.02

; most probable marker res
  mkres1 = True
  mkres1@gsMarkerColor = "black"
  mkres1@gsMarkerIndex = 4 
  mkres1@gsMarkerSizeF = 0.02

; set line res 
  lnres                           = True
  lnres@gsLineThicknessF          = 2.5
  lnres@gsLineColor               = "black"

; set line res to zones
  lnres_c                           = True
  lnres_c@gsLineThicknessF          = 0.75
  lnres_c@gsLineColor               = "black"
  lnres_c@gsLineDashPattern         = 2

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

;;;;;;;;;;;;;
; Make individual plots
;;;;;;;;;;;;;
;w = 0
;do w = 0, nweeks -1

w = nweeks -1

   print ("plotting week "+(w+1))
   ; set info for this plot
   fout = "supp_fig_1_2wk_visits_week_"+(w+1)
   title_fin = "Track location probabilities for "+date_2wk(w)
   wks = gsn_open_wks("ps",fout)
   gsn_define_colormap(wks,"julies")

   plot = new(1, graphic)
   dum1 = new(1,graphic)
   dum2 = new(1,graphic)
   dum3 = new(1,graphic)

   mark_lat = new((/2/),"float")
   mark_lon = new((/2/),"float")
   mark_lat(0) = lat_track(0,0)
   mark_lat(1) = 90.0
   mark_lon(0) = lon_track(0,0)
   mark_lon(1) = 180.0
   
   ; plot the probabiliy for this week
   plot(0) = gsn_csm_contour_map(wks,loc_2wk(w,:,:),res)
   dum1(0) = gsn_add_polymarker(wks,plot(0),mark_lon,mark_lat,mkres)
   dum2(0) = gsn_add_polymarker(wks,plot(0),lon_2wk(w),lat_2wk(w),mkres1)
   dum3(0) = gsn_add_polyline(wks,plot(0),lons_circle,lats_circle,lnres_c)

  ; make panel plot
  pnlres@txString  = title_fin
  gsn_panel(wks,(/plot/),(/1,1/),pnlres)                   ; create final panel plot
  delete(wks)
  print("converting to png")
  system("convert -trim -border 5 -bordercolor white -density 300 "+  \
         "-rotate -90 -trim -border 5 "+fout+".ps "+fout+".png")
  delete([/fout,title_fin,plot,dum1,dum2/])

;end do

print("Done with all plots. Hooray!")
;;;;;;;;;;;;;;;;;;;;;; END script
end
