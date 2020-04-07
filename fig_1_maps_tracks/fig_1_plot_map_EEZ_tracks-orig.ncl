;***************************************
; PROGRAM DESCRIPTION: Plot Arctic EEZ and floe tracks
; INPUT DATA: shape files, LENS tracks, most probable track
; OUTPUT DATA: Map of individual and highly likely tracks
; and shaded EEZ
; CREATOR: Alice DuVivier - May 2019 
;***************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;***************************************
begin
; BEGIN SCRIPT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load CESM data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;
; CLM
;;;;;;;;;;;;;
; names of files
  file_clm = "/project/ppc/duvivier/projects/mosaic/analysis/paper_figures/MOSAIC_TC_2019/fig_1_maps_tracks_most_probable/files_needed/land_topo.10min.nc"

print ("Loading CLM data")
; Loading files to be used in this script
  fSim = addfile(file_clm, "r")
; loading the topography
  topo = fSim->TOPO_ICE
  lat2d = fSim->LATIXY
  lon2d = fSim->LONGXY
  topo@lat2d = lat2d
  topo@lon2d = lon2d
  topo@_FillValue = -999.99
; set all points in domain that are below sea level to 0
  topo = where(topo .eq. 0.0, topo@_FillValue, topo)

delete(fSim)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Get LIITS track info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Getting liits tracks")
; Lagrangian tracks done consistent with CESM velocities

; Get original starting locations
lats_st = (/"85"/)
lons_st = (/"125"/)
dates_st = (/"oct15"/)
ndates = dimsizes(dates_st)
d = 0

lats_flt = tofloat(lats_st)
lons_flt = tofloat(lons_st)

; get dimensions for array
ndays = 366
ncol = 5   ; number of columns
nhead = 1   ; number of header lines to ignore

;;;;;;;;;;;;;
; get liits tracks
;;;;;;;;;;;;;
print("Getting 2021 tracks")
indir_l    = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/st_"+lats_st(d)+"_"+lons_st(d)+"_"+dates_st(d)+"/"
innames_l   = systemfunc("ls "+indir_l+"/*.txt")
ntracks_l = dimsizes(innames_l)

; preallocate data
lat_track_l = new((/ntracks_l,ndays/),"float")
lon_track_l = new((/ntracks_l,ndays/),"float")

; read in track lat/lons
n = 0
do n = 0, ntracks_l -1
   data = readAsciiTable(innames_l(n), ncol, "float", nhead)
   dims = dimsizes(data)
   nd_l = dims(0)
   lat_track_l(n,0:nd_l-1) = (/data(:,3)/)
   lon_track_l(n,0:nd_l-1) = (/data(:,4)/)
   delete([/data,dims,nd_l/])
end do

; replace nans (from Matlab calculations...) with _FillValue
replace_ieeenan(lat_track_l,lat_track_l@_FillValue,0)
replace_ieeenan(lon_track_l,lon_track_l@_FillValue,0)

;;;;;;;;;;;;;
; get observed tracks
;;;;;;;;;;;;;
print("Getting pathfinder tracks")
indir_o    = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/CDR_PATHS/st_"+lats_st(d)+"_"+lons_st(d)+"_"+dates_st(d)+"/"
innames_o   = systemfunc("ls "+indir_o+"/*.txt")
ntracks_o = dimsizes(innames_o)

; preallocate data
lat_track_o = new((/ntracks_o,ndays/),"float")
lon_track_o = new((/ntracks_o,ndays/),"float")

; read in track lat/lons
n = 0
do n = 0, ntracks_o -1
   data = readAsciiTable(innames_o(n), ncol, "float", nhead)
   dims = dimsizes(data)
   nd_o = dims(0)
   lat_track_o(n,0:nd_o-1) = (/data(:,3)/)
   lon_track_o(n,0:nd_o-1) = (/data(:,4)/)
   delete([/data,dims,nd_o/])
end do

; replace nans (from Matlab calculations...) with _FillValue
replace_ieeenan(lat_track_o,lat_track_o@_FillValue,0)
replace_ieeenan(lon_track_o,lon_track_o@_FillValue,0)

;;;;;;;;;;;;;
; get LENS historical (1980's) tracks
;;;;;;;;;;;;;
print("Getting 1980 tracks")
indir_h    = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/LENS_PATHS/st_hist_"+lats_st(d)+"_"+lons_st(d)+"_"+dates_st(d)+"/"
innames_h   = systemfunc("ls "+indir_h+"/*.txt")
ntracks_h = dimsizes(innames_h)

; preallocate data
lat_track_h = new((/ntracks_h,ndays/),"float")
lon_track_h = new((/ntracks_h,ndays/),"float")

; read in track lat/lons
n = 0
do n = 0, ntracks_h -1
   data = readAsciiTable(innames_h(n), ncol, "float", nhead)
   dims = dimsizes(data)
   nd_h = dims(0)
   lat_track_h(n,0:nd_h-1) = (/data(:,3)/)
   lon_track_h(n,0:nd_h-1) = (/data(:,4)/)
   delete([/data,dims,nd_h/])
end do

; replace nans (from Matlab calculations...) with _FillValue
replace_ieeenan(lat_track_h,lat_track_h@_FillValue,0)
replace_ieeenan(lon_track_h,lon_track_h@_FillValue,0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load Most probable tracks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Getting most probable tracks")
indir_p    = "/project/ppc/duvivier/projects/mosaic/analysis/paper_figures/MOSAIC_TC_2019/fig_1_maps_tracks_most_probable/files_needed/"
innames_p   = systemfunc("ls "+indir_p+"/*.txt")

; 2021 data
data = asciiread(innames_p(0),-1,"string")
delim = ","
prob_dates = str_get_field(data,1,delim)
prob_lat_0 = tofloat(str_get_field(data,2,delim))
prob_lon_0 = tofloat(str_get_field(data,3,delim))
delete(data)
; obs data
data = asciiread(innames_p(1),-1,"string")
delim = ","
prob_dates = str_get_field(data,1,delim)
prob_lat_1 = tofloat(str_get_field(data,2,delim))
prob_lon_1 = tofloat(str_get_field(data,3,delim))
delete(data)
; 1980 data
data = asciiread(innames_p(2),-1,"string")
delim = ","
prob_dates = str_get_field(data,1,delim)
prob_lat_2 = tofloat(str_get_field(data,2,delim))
prob_lon_2 = tofloat(str_get_field(data,3,delim))
delete(data)

; divide up
nmonths = 13
; index groups by month
; oct: 0 - deeppink3
; nov: 1-2 - firebrick
; dec: 3-5 - darkorange2
; jan: 6-7 - darkgoldenrod2
; feb: 8-9 - gold
; mar: 10-11 - green1
; apr: 12-13 - green4
; may: 14-15 - turquoise3
; jun: 16-18 - deepskyblue1
; jul: 19-20 - blue
; aug: 21-22 - blueviolet
; sept: 23-24 - darkorchid1
; oct: 25 - deeppink3

; assign lats
prob_lats = new((/3,nmonths,4/),"float")
; 2021
prob_lats(:,0,0) = lat_track_l(0,0)
prob_lats(0,0,1) = prob_lat_0(0)
prob_lats(0,1,0:2) = prob_lat_0(0:2)
prob_lats(0,2,0:3) = prob_lat_0(2:5)
prob_lats(0,3,0:2) = prob_lat_0(5:7)
prob_lats(0,4,0:2) = prob_lat_0(7:9)
prob_lats(0,5,0:2) = prob_lat_0(9:11)
prob_lats(0,6,0:2) = prob_lat_0(11:13)
prob_lats(0,7,0:2) = prob_lat_0(13:15)
prob_lats(0,8,0:3) = prob_lat_0(15:18)
prob_lats(0,9,0:2) = prob_lat_0(18:20)
prob_lats(0,10,0:2) = prob_lat_0(20:22)
prob_lats(0,11,0:2) = prob_lat_0(22:24)
prob_lats(0,12,0:1) = prob_lat_0(24:25)
; obs
prob_lats(1,0,1) = prob_lat_1(0)
prob_lats(1,1,0:2) = prob_lat_1(0:2)
prob_lats(1,2,0:3) = prob_lat_1(2:5)
prob_lats(1,3,0:2) = prob_lat_1(5:7)
prob_lats(1,4,0:2) = prob_lat_1(7:9)
prob_lats(1,5,0:2) = prob_lat_1(9:11)
prob_lats(1,6,0:2) = prob_lat_1(11:13)
prob_lats(1,7,0:2) = prob_lat_1(13:15)
prob_lats(1,8,0:3) = prob_lat_1(15:18)
prob_lats(1,9,0:2) = prob_lat_1(18:20)
prob_lats(1,10,0:2) = prob_lat_1(20:22)
prob_lats(1,11,0:2) = prob_lat_1(22:24)
prob_lats(1,12,0:1) = prob_lat_1(24:25)
; 1980
prob_lats(2,0,1) = prob_lat_2(0)
prob_lats(2,1,0:2) = prob_lat_2(0:2)
prob_lats(2,2,0:3) = prob_lat_2(2:5)
prob_lats(2,3,0:2) = prob_lat_2(5:7)
prob_lats(2,4,0:2) = prob_lat_2(7:9)
prob_lats(2,5,0:2) = prob_lat_2(9:11)
prob_lats(2,6,0:2) = prob_lat_2(11:13)
prob_lats(2,7,0:2) = prob_lat_2(13:15)
prob_lats(2,8,0:3) = prob_lat_2(15:18)
prob_lats(2,9,0:2) = prob_lat_2(18:20)
prob_lats(2,10,0:2) = prob_lat_2(20:22)
prob_lats(2,11,0:2) = prob_lat_2(22:24)
prob_lats(2,12,0:1) = prob_lat_2(24:25)

; assign lons
prob_lons = new((/3,nmonths,4/),"float")
; 2021
prob_lons(:,0,0) = lon_track_l(0,0)
prob_lons(0,0,1) = prob_lon_0(0)
prob_lons(0,1,0:2) = prob_lon_0(0:2)
prob_lons(0,2,0:3) = prob_lon_0(2:5)
prob_lons(0,3,0:2) = prob_lon_0(5:7)
prob_lons(0,4,0:2) = prob_lon_0(7:9)
prob_lons(0,5,0:2) = prob_lon_0(9:11)
prob_lons(0,6,0:2) = prob_lon_0(11:13)
prob_lons(0,7,0:2) = prob_lon_0(13:15)
prob_lons(0,8,0:3) = prob_lon_0(15:18)
prob_lons(0,9,0:2) = prob_lon_0(18:20)
prob_lons(0,10,0:2) = prob_lon_0(20:22)
prob_lons(0,11,0:2) = prob_lon_0(22:24)
prob_lons(0,12,0:1) = prob_lon_0(24:25)
; obs
prob_lons(1,0,1) = prob_lon_1(0)
prob_lons(1,1,0:2) = prob_lon_1(0:2)
prob_lons(1,2,0:3) = prob_lon_1(2:5)
prob_lons(1,3,0:2) = prob_lon_1(5:7)
prob_lons(1,4,0:2) = prob_lon_1(7:9)
prob_lons(1,5,0:2) = prob_lon_1(9:11)
prob_lons(1,6,0:2) = prob_lon_1(11:13)
prob_lons(1,7,0:2) = prob_lon_1(13:15)
prob_lons(1,8,0:3) = prob_lon_1(15:18)
prob_lons(1,9,0:2) = prob_lon_1(18:20)
prob_lons(1,10,0:2) = prob_lon_1(20:22)
prob_lons(1,11,0:2) = prob_lon_1(22:24)
prob_lons(1,12,0:1) = prob_lon_1(24:25)
; 1980
prob_lons(2,0,1) = prob_lon_2(0)
prob_lons(2,1,0:2) = prob_lon_2(0:2)
prob_lons(2,2,0:3) = prob_lon_2(2:5)
prob_lons(2,3,0:2) = prob_lon_2(5:7)
prob_lons(2,4,0:2) = prob_lon_2(7:9)
prob_lons(2,5,0:2) = prob_lon_2(9:11)
prob_lons(2,6,0:2) = prob_lon_2(11:13)
prob_lons(2,7,0:2) = prob_lon_2(13:15)
prob_lons(2,8,0:3) = prob_lon_2(15:18)
prob_lons(2,9,0:2) = prob_lon_2(18:20)
prob_lons(2,10,0:2) = prob_lon_2(20:22)
prob_lons(2,11,0:2) = prob_lon_2(22:24)
prob_lons(2,12,0:1) = prob_lon_2(24:25)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Load Shapefiles for EEZ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Getting shapefiles")
indir_s    = "/project/ppc/duvivier/projects/mosaic/DATA/EEZ_shapefiles/"
innames_s   = systemfunc("ls "+indir_s+"/*.shp")
nshape = dimsizes(innames_s)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; Zones for tracks info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print("Getting track zones")
; Add zones
  ; Canadia
  lons_zone1 = (/-60.0,-60.0/)
  lats_zone1 = (/78.0,87.0/)
  ; Russian Zone
  lons_zone2 = (/35.0,35.0/)  
  ;lons_zone2 = (/50.0,50.0/)  
  lats_zone2 = lats_zone1
  ; Date line
  lons_zone3 = (/180.0,180.0/)
  lats_zone3 = lats_zone1  
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
print ("Creating plots")
  res                     = True          ; plot mods desired
  res@gsnDraw             = False         ; don't draw the plot yet
  res@gsnFrame            = False         ; or the frame
  res@cnLinesOn           = False         ; turn off contour lines
  lats_zone2 = lats_zone1
  ; Date line
  lons_zone3 = (/180.0,180.0/)
  lats_zone3 = lats_zone1  
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
print ("Creating plots")
  res                     = True          ; plot mods desired
  res@gsnDraw             = False         ; don't draw the plot yet
  res@gsnFrame            = False         ; or the frame
  res@cnLinesOn           = False         ; turn off contour lines
  res@txFontHeightF       = 0.020          ; set subtitle text font
  res@gsnLeftString       = ""
  res@gsnRightString      = ""
  res@gsnCenterString     = ""

  ; axes resources
  res@tiXAxisOn            = False
  res@tiYAxisOn            = False  

  ; contour resources for everything
  res@cnFillOn            = True          ; turn on color
  res@cnFillMode          = "RasterFill"  ; rasters (no smoothing by default)
  res@cnLinesOn           = False
  res@lbLabelBarOn        = False         ; turn off label bars
  res@cnInfoLabelOn       = False         ; turn off contour info labels
  res@cnLineLabelsOn      = False
  res@cnMissingValFillColor = "grey" ;white"
  
; Map resources for main dataset
  res_main = res
  res_main@mpDataBaseVersion    = "MediumRes"
  res_main@gsnPolar             = "NH"
  res_main@mpMinLatF            = 78.0 ;75.0
  res_main@mpGridAndLimbOn      = False            ; Turn on lat/lon grid
  res_main@mpFillOn             = True             ; Enables map fill
  res_main@mpGridAndLimbOn      = False    ; set to true to show lat and lon lines
  res_main@mpGeophysicalLineColor      = "black"          ; Color of continents
  res_main@mpGeophysicalLineThicknessF = 1.5
  res_main@mpLandFillColor = "white"    

; Options for land height plot
  res_clm = res_main
  res_clm@cnLevelSelectionMode       = "ExplicitLevels"
  res_clm@cnFillMode                 = "AreaFill"
  res_clm@cnLevels                   = fspan(0.0, 2000.0, 25)
  res_clm@gsnSpreadColorStart        = 3
  res_clm@gsnSpreadColorEnd          = 100
  res_clm@trGridType                 = "TriangularMesh"

; choose data to plot
  data_plot = topo
  res_final = res_clm

; start marker res
  mkres = True
  mkres@gsMarkerColor             = "deeppink3"
  mkres@gsMarkerIndex             = 16
  mkres@gsMarkerSizeF             = 0.0075 ;0.01

; set line res to liits tracks
  lnres_l                           = True
  lnres_l@gsLineThicknessF          = 1.25
  lnres_l@gsLineColor               = "grey50" ;black"

; set line res to zones
  lnres_z                           = True
  lnres_z@gsLineThicknessF          = 0.75
  lnres_z@gsLineColor               = "black"
  lnres_z@gsLineDashPattern         = 2

; set line res to most probable track
  lnres_p                           = lnres_l
  lnres_p@gsLineThicknessF          = 3.75
  colors_prob = (/"deeppink3","firebrick","darkorange2","darkgoldenrod2","gold","green1","green4","turquoise3","deepskyblue1","blue","blueviolet","darkorchid1","deeppink3"/)
  lnres_p@gsLineColor               = "firebrick"

; Add EEZs outlines - the colors match those of Patricia and several use the Norway mask color (orange)
  lnres_eez = True
  colors_eez = (/"purple","dodgerblue","blue","green4","darkorange","darkorange","red","darkorange"/)
  ;lnres_eez@gsFillOpacityF = 0.15 ;0.3
  lnres_eez@gsFillIndex = 17 ;0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print ("Plotting tracks")
  fout = "fig_1_liits_tracks_eez"
  wks_type = "ps" ;"png"
  wks = gsn_open_wks(wks_type,fout)
  gsn_define_colormap(wks,"cesm2_press")
  plot = new(3,graphic)

; 2021 tracks
  l = 1
  res_final@tiMainString = "b)  Seasonal CESM-LE"
  ; initial land plot
  cplot = gsn_csm_contour_map(wks,data_plot,res_final)
  ; add shapefiles
  dum0a = new(nshape,graphic)
  n = 0
  do n = 0, nshape -1
     lnres_eez@gsFillColor = colors_eez(n)
     dum0a(n) = gsn_add_shapefile_polygons(wks,cplot,innames_s(n),lnres_eez)
  end do
  ; add liits paths
  dum1a = new(ntracks_l,graphic)
  n = 0
  do n = 0, ntracks_l-1
     dum1a(n) = gsn_add_polyline(wks,cplot,lon_track_l(n,:),lat_track_l(n,:),lnres_l)
  end do
  ; add zone lines
  dum2a = new(1, graphic)
  dum2a = gsn_add_polyline(wks,cplot,lons_zone1,lats_zone1,lnres_z)
  dum3a = new(1, graphic)
  dum3a = gsn_add_polyline(wks,cplot,lons_zone2,lats_zone2,lnres_z)
  dum4a = new(1, graphic)
  dum4a = gsn_add_polyline(wks,cplot,lons_zone3,lats_zone3,lnres_z)  
  dum5a = new(1, graphic)
  dum5a = gsn_add_polyline(wks,cplot,lons_circle,lats_circle,lnres_z)
  ; add most probable track
  dum6a = new(nmonths,graphic)
  n = 0
  do n = 0, nmonths-1
     lnres_p@gsLineColor = colors_prob(n)
     dum6a(n) = gsn_add_polyline(wks,cplot,prob_lons(0,n,:),prob_lats(0,n,:),lnres_p)
  end do
  ; add starting point marker
  dum7a = new(1, graphic)
  dum7a = gsn_add_polymarker(wks,cplot,lons_flt(0),lats_flt(0),mkres)
  ; final panel
  plot(l) = cplot

; Pathfinder tracks
  l = 0
  res_final@tiMainString = "a)    Satellite"
  ; initial land plot
  cplot = gsn_csm_contour_map(wks,data_plot,res_final)
  ; add shapefiles
  dum0b = new(nshape,graphic)
  n = 0
  do n = 0, nshape -1
     lnres_eez@gsFillColor = colors_eez(n)
     dum0b(n) = gsn_add_shapefile_polygons(wks,cplot,innames_s(n),lnres_eez)
  end do
  ; add liits paths
  dum1b = new(ntracks_l,graphic)
  n = 0
  do n = 0, ntracks_o-1
     dum1b(n) = gsn_add_polyline(wks,cplot,lon_track_o(n,:),lat_track_o(n,:),lnres_l)
  end do
  ; add zone lines
  dum2b = new(1, graphic)
  dum2b = gsn_add_polyline(wks,cplot,lons_zone1,lats_zone1,lnres_z)
  dum3b = new(1, graphic)
  dum3b = gsn_add_polyline(wks,cplot,lons_zone2,lats_zone2,lnres_z)
  dum4b = new(1, graphic)
  dum4b = gsn_add_polyline(wks,cplot,lons_zone3,lats_zone3,lnres_z)    
  dum5b = new(1, graphic)
  dum5b = gsn_add_polyline(wks,cplot,lons_circle,lats_circle,lnres_z)
  ; add most probable track
  dum6b = new(nmonths,graphic)
  n = 0
  do n = 0, nmonths-1
     lnres_p@gsLineColor = colors_prob(n)
     dum6b(n) = gsn_add_polyline(wks,cplot,prob_lons(1,n,:),prob_lats(1,n,:),lnres_p)
  end do
  ; add starting point marker
  dum7b = new(1, graphic)
  dum7b = gsn_add_polymarker(wks,cplot,lons_flt(0),lats_flt(0),mkres)
  ; final panel
  plot(l) = cplot

; 1980's tracks
  l = 2
  res_final@tiMainString = "c)  Perennial CESM-LE"
  ; initial land plot
  cplot = gsn_csm_contour_map(wks,data_plot,res_final)
  ; add shapefiles
  dum0c = new(nshape,graphic)
  n = 0
  do n = 0, nshape -1
     lnres_eez@gsFillColor = colors_eez(n)
     dum0c(n) = gsn_add_shapefile_polygons(wks,cplot,innames_s(n),lnres_eez)
  end do
  ; add liits paths
  dum1c = new(ntracks_l,graphic)
  n = 0
  do n = 0, ntracks_h-1
     dum1c(n) = gsn_add_polyline(wks,cplot,lon_track_h(n,:),lat_track_h(n,:),lnres_l)
  end do
  ; add zone lines
  dum2c = new(1, graphic)
  dum2c = gsn_add_polyline(wks,cplot,lons_zone1,lats_zone1,lnres_z)
  dum3c = new(1, graphic)
  dum3c = gsn_add_polyline(wks,cplot,lons_zone2,lats_zone2,lnres_z)
  dum4c = new(1, graphic)
  dum4c = gsn_add_polyline(wks,cplot,lons_zone3,lats_zone3,lnres_z)    
  dum5c = new(1, graphic)
  dum5c = gsn_add_polyline(wks,cplot,lons_circle,lats_circle,lnres_z)
  ; add most probable track
  dum6c = new(nmonths,graphic)
  n = 0
  do n = 0, nmonths-1
     lnres_p@gsLineColor = colors_prob(n)
     dum6c(n) = gsn_add_polyline(wks,cplot,prob_lons(2,n,:),prob_lats(2,n,:),lnres_p)
  end do
  ; add starting point marker
  dum7c = new(1, graphic)
  dum7c = gsn_add_polymarker(wks,cplot,lons_flt(0),lats_flt(0),mkres)
  ; final panel
  plot(l) = cplot

print("Paneling")
  ;gsn_panel(wks,(/plot/),(/3,1/),False)
  gsn_panel(wks,(/plot/),(/1,3/),False)

  delete(wks)
  print("converting to png")
  system("convert -trim -border 5 -bordercolor white -density 300 "+  \
         "-trim -border 5 "+fout+".ps "+fout+".png")

print("Done with plot. Hooray!")
;;;;;;;;;;;;;;;;;;;;;; END script
end
