;***************************************
; PROGRAM DESCRIPTION: Plot Arctic EEZ and MOSAIC tracks
; INPUT DATA: shape files, tracks
; OUTPUT DATA: Map of tracks and shaded EEZ
; CREATOR: Alice DuVivier - Feb 2019
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
  file_clm = "/project/ppc/duvivier/CESM/CESM2_pr_figure/DATA/mksrf_topo.10min.c080912.nc"

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

lats_flt = tofloat(lats_st)
lons_flt = tofloat(lons_st)

; get dimensions for arrays
years = ispan(1988,2016,1)
ntracks = dimsizes(years)-1
ndays = 366
ncol = 5   ; number of columns
nhead = 1   ; number of header lines to ignore

;;;;;;;;;;;;;
; get liits tracks
;;;;;;;;;;;;;
; loop through each starting point
d = 0
do d = 0, ndates -1
   track = "st_"+lats_st(d)+"_"+lons_st(d)+"_"+dates_st(d)
   print("track: "+track)
   indir    = "/project/ppc/duvivier/projects/mosaic/DATA/LIITS/CDR_PATHS/"+track+"/"
   innames   = systemfunc("ls "+indir+"/*.txt")

   ; preallocate data
   yy_track = new((/ntracks,ndays/),"string")
   mm_track = new((/ntracks,ndays/),"string")
   dd_track = new((/ntracks,ndays/),"string")
   lat_track = new((/ntracks,ndays/),"float")
   lon_track = new((/ntracks,ndays/),"float")

   ; read in track lat/lons
   n = 0
   do n = 0, ntracks -1
      data = readAsciiTable(innames(n), ncol, "float", nhead)
      dims = dimsizes(data)
      nd = dims(0)
      yy_track(n,0:nd-1) = tostring(tointeger((/data(:,0)/)))
      mm_track(n,0:nd-1) = tostring(tointeger((/data(:,1)/)))
      dd_track(n,0:nd-1) = tostring(tointeger((/data(:,2)/)))
      lat_track(n,0:nd-1) = (/data(:,3)/)
      lon_track(n,0:nd-1) = (/data(:,4)/)
      delete([/data,dims,nd/])
   end do

   delete([/indir,innames/])
   ; replace nans (from Matlab calculations...) with _FillValue
   replace_ieeenan(lat_track,lat_track@_FillValue,0)
   replace_ieeenan(lon_track,lon_track@_FillValue,0)

   ; get melt out statistics for this starting point tracks
   last_date = new((/ntracks/),"string")
   ind_final = new((/ntracks/),"integer")
   ens_name = new((/ntracks/),"string")
   n = 0
   do n = 0, ntracks -1
      ens_name(n) = tostring(years(n))
      dum = lat_track(n,:)
      inds = ind(ismissing(dum))
      if (.not.all(ismissing(inds))) then
         last_date(n) = yy_track(inds(n,0)-1)+"-"+mm_track(inds(n,0)-1)+"-"+dd_track(inds(n,0)-1)
	 ind_final(n) = inds(0)-1
      else
         last_date(n) = yy_track(n,ndays-1)+"-"+mm_track(n,ndays-1)+"-"+dd_track(n,ndays-1)
	 ind_final(n) = ndays-1
      end if
      delete([/dum,inds/])
   end do

   ; get type of track satistics for this starting point tracks
   ; "Canadian - CA" tracks: lon_final < -60.0, lat_final <87.0
   ; "Russian - RU" tracks: lon_final > 35.0, lat_final <87.0
   ; "North Pole - NP" tracks: lat_final > 87.0
   ; "Transpolar Drift - TP" tracks: everything else
   path_type = new((/ntracks/),"string")
   n = 0
   do n = 0, ntracks -1
      lat_final = lat_track(n,ind_final(n))
      lon_final = lon_track(n,ind_final(n))

      ; divide into track type
      if ((lon_final .le. -60.0) .and. (lat_final .lt. 87.0))
         path_type(n) = "CA"
      end if
      if ((lon_final .gt. -60.0) .and. (lon_final .lt. 35.0) .and. (lat_final .lt. 87.0))
         path_type(n) = "TP"
      end if      
      if ((lon_final .ge. 35.0) .and. (lat_final .lt. 87.0))
         path_type(n) = "RU"
      end if
      if ((lat_final .ge. 87.0))
         path_type(n) = "NP"
      end if
    end do

    ; write out a text file with the stats
    fout = track+"_stats.txt"
    alist = [/ens_name+", "+last_date+", "+path_type/]
    write_table(fout,"w",alist,"%s")

   delete([/yy_track,mm_track,dd_track,lat_track,lon_track,ens_name,last_date,ind_final,path_type,fout,alist/])
end do

print("Done with calculating stats. Hooray!")
;;;;;;;;;;;;;;;;;;;;;; END script
end
