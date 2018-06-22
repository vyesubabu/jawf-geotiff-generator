#!/bin/csh
#
#######################################################################################
# File:              run-jawf-production.csh
# App Name:          jawf-geotiff-generator
# Functionality:     Driver script to generate geotiffs for JAWF operations
# Author:            Adam Allgood
# Date created:      2018-05-11
#######################################################################################
#

# --- Get the run-time date for generating the geotiff files ---

# Default date!

set runDate = `date +%Y%m%d --d 'today'`

# Override the default with a date from the command line if supplied!

if ($#argv >= 1) then
    set runDate = $1
endif

# Validate the date!

set date_test = `date --d ${runDate}`
echo

if ($?) then
   echo The date $runDate is invalid!
   goto error
else
   echo The date $runDate has been validated!
endif

set mnum = `date +%m --d ${runDate}`
set mday = `date +%d --d ${runDate}`

# --- Set up failure flag ---

set failure = 0

# --- Update precipitation archive ---

set precipDate = `date +%Y%m%d --d "${runDate}-2days"`

echo
echo Updating CMORPH-Gauge merge precipitation archive
perl ${JAWF_GEOTIFFS}/scripts/update-precipitation-archive.pl -d ${precipDate}

if ( $status != 0) then
    set failure = 1
endif

# --- Daily and weekly geotiffs ---

echo
echo Generating daily and weekly JAWF geotiffs
perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/daily-temperature.jobs -d ${runDate}

if ( $status != 0) then
    set failure = 1
endif

perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/daily-precipitation.jobs -d ${runDate}

if ( $status != 0) then
    set failure = 1
endif

# --- Monthly and seasonal geotiffs ---

if ( $mday == '02' ) then
    echo
    echo Generating monthly and seasonal geotiffs
    perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/monthly-temperature.jobs -d ${runDate}

    if ( $status != 0 ) then
        set failure = 1
    endif

    perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/monthly-precipitation.jobs -d ${runDate}

    if ( $status != 0 ) then
        set failure = 1
    endif

# --- Annual geotiffs ---

    if ($mnum == '01' ) then
        echo
        echo Generating annual geotiffs
        perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/annual-temperature.jobs -d ${runDate}

        if ( $status != 0 ) then
            set failure = 1
        endif

        perl ${JAWF_GEOTIFFS}/scripts/generate-geotiffs.pl -j ${JAWF_GEOTIFFS}/jobs/annual-precipitation.jobs -d ${runDate}

        if ( $status != 0 ) then
            set failure = 1
        endif

    endif

endif

# --- End script ---

if ($failure != 0) then
    goto error
endif

echo
echo All done for ${runDate}!
echo

exit 0

error:
echo
echo "Exiting with driver script errors :("
echo

exit 1

