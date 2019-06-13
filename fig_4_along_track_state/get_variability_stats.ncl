; ***************************************
; PROGRAM DESCRIPTION: Plot seasonal cycle of ice variables
;                      along floe tracks.
; INPUT DATA: Ensemble track data, ensemble model data interpolated
;                      to tracks
; OUTPUT DATA: Print statements to screen of standard deviation info
; CREATOR: Alice DuVivier - May 2019
; ***************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
; ***************************************
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

; get maximum stddev and date of that
print("Maximum stddev for "+varcode+": "+max(ens_stddev))
ind_max = ind(ens_stddev .eq. max(ens_stddev))
print("On date: "+mm_dd(ind_max))

; get average stddev over the melt season
; melt season is ind 198-330 (May1-Sept.15)
ind_1 = 198
ind_2 = 330
print("Melt season: "+mm_dd(ind_1)+" to "+mm_dd(ind_2))
print("Avg stddev: "+avg(ens_stddev(ind_1:ind_2)))

;;;;;;;;;;;;;;;;;;;;;; END script
end
