#!/bin/bash
#
# This script will create a bootable ISO image from the installer application for
# - El Capitan (10.11)
# - Sierra (10.12) macOS
# - High Sierra (10.13) macOS


#
# createISO
#
# This function creates the ISO image for the user.
# Inputs:  $1 = The name of the installer - located in your Applications folder or in your local folder/PATH.
#          $2 = The Name of the ISO you want created.
#
function createISO()
{
  tmpSuffix=$RANDOM #nicetodo: A filestystem timestamp would be nicer

  #pretty sure these should be the same (they were different, but should be merged)
  install_build="unpacked_installer.${tmpSuffix}"
  expanded_orig_installer="unpacked_installer.${tmpSuffix}"

  mountedName="OS X Base System" #this is what the apple decided to call the .dmg'd disk


  if [ $# -eq 2 ] ; then
    local installerAppName=${1}
    local OsFamiliarName=${2}
    tmpIsoName="${OsFamiliarName}.${tmpSuffix}"

    local error=0

    # echo Debug: installerAppName = ${installerAppName} , isoName = ${OsFamiliarName}

    # ==============================================================
    # 10.11 & 10.12: How to make an ISO from the Install app
    # ==============================================================
    echo
    echo Mount the installer image
    echo -----------------------------------------------------------

    if [ -e "${installerAppName}" ] ; then
      echo "------ Installer is in local dir ------"
      installerAppLongName="${installerAppName}"
    elif [ -e /Applications/"${installerAppName}" ] ; then
      echo "------ Installer is in /Applications dir ------"
      installerAppLongName="/Applications/${installerAppName}"
    else
      echo Installer Not found!
      error=1
    fi
    set -x
    hdiutil attach "${installerAppLongName}"/Contents/SharedSupport/InstallESD.dmg -noverify -nobrowse -mountpoint /Volumes/"${install_build}"
    error=$?
    set +x


    if [ ${error} -ne 0 ] ; then
      echo "Failed to mount the InstallESD.dmg from the instaler at ${installerAppLongName}.  Exiting. (${error})"
      return ${error}
    fi

    echo
    echo "Create ${OsFamiliarName} as a temporary blank ISO image called ${TmpIsoName} with a Single Partition - Apple Partition Map"
    echo --------------------------------------------------------------------------
     #quasi random name to help with development so subsequent runs don't step on each other
    set -x
    hdiutil create -o /tmp/${tmpIsoName} -size 8g -layout SPUD -fs HFS+J -type SPARSE
    set +x

    echo
    echo Mount the sparse bundle for package addition
    echo --------------------------------------------------------------------------
    set -x
    hdiutil attach /tmp/${tmpIsoName}.sparseimage -noverify -nobrowse -mountpoint /Volumes/"${install_build}"
    set +x

    echo
    echo Restore the Base System into the ${tmpIsoName} ISO image
    echo ---------------------------- ${OsFamiliarName} ----------------------------------------------
    #if [ "${OsFamiliarName}" == "HighSierra" ] ; then
      set -x
      time asr restore -source "${installerAppLongName}"/Contents/SharedSupport/BaseSystem.dmg -target /Volumes/"${install_build}" -noprompt -noverify -erase
      set +x
    #else
    #  set -x
    #       asr restore -source /Volumes/"${expanded_orig_installer}"/BaseSystem.dmg -target /Volumes/"${install_build}" -noprompt -noverify -erase
    #  set +x
    #fi



    echo
    echo Remove Package link and replace with actual files
    echo ----------------------------- ${OsFamiliarName} ---------------------------------------------
    #if [ "${OsFamiliarName}" == "HighSierra" ] ; then
      set -x
      #rm "/Volumes/${mountedName}/System/Installation/Packages " #<-- Look, yes this trailing space is real (FYI, this step might probably not be necessary)
      time ditto -V /Volumes/"${expanded_orig_installer}"/Packages "/Volumes/${mountedName}/System/Installation/"
      set +x
    #else
    #  set -x
    #  rm "/Volumes/${mountedName}/System/Installation/Packages"
    #  cp -rp /Volumes/"${expanded_orig_installer}"/Packages "/Volumes/${mountedName}/System/Installation/"
    #  set +x
    #fi


    echo
    echo Copy macOS ${OsFamiliarName} installer dependencies
    echo -------------------------------- ${OsFamiliarName} ------------------------------------------
    #if [ "${OsFamiliarName}" == "HighSierra" ] ; then
      set -x
      ditto -V "${installerAppLongName}"/Contents/SharedSupport/BaseSystem.chunklist "/Volumes/${mountedName}/BaseSystem.chunklist"
      time ditto -V "${installerAppLongName}"/Contents/SharedSupport/BaseSystem.dmg "/Volumes/${mountedName}/BaseSystem.dmg"
      set +x
    #else
    #  set -x
    #  cp -rp /Volumes/"${expanded_orig_installer}"/BaseSystem.chunklist "/Volumes/${mountedName}/BaseSystem.chunklist"
    #  cp -rp /Volumes/"${expanded_orig_installer}"/BaseSystem.dmg "/Volumes/${mountedName}/BaseSystem.dmg"
    #  set +x
    #fi



    echo
    echo Unmount the installer image
    echo --------------------------------------------------------------------------
    set -x
    hdiutil detach /Volumes/"${expanded_orig_installer}"
    set +x

    echo
    echo Unmount the sparse bundle
    echo --------------------------------------------------------------------------
    set -x
    hdiutil detach "/Volumes/${mountedName}/"
    set +x

    echo
    echo Resize the partition in the sparse bundle to remove any free space
    echo --------------------------------------------------------------------------
    set -x
    hdiutil resize -size `hdiutil resize -limits /tmp/${tmpIsoName}.sparseimage | tail -n 1 | awk '{ print $1 }'`b /tmp/${tmpIsoName}.sparseimage
    set +x

    echo
    echo Convert ${OsFamiliarName} the sparse bundle to ISO/CD master
    echo --------------------------------------------------------------------------
    set -x
    time hdiutil convert /tmp/${tmpIsoName}.sparseimage -format UDTO -o /tmp/${OsFamiliarName}
    set +x

    echo
    echo Remove the sparse bundle
    echo --------------------------------------------------------------------------
    set -x
    rm /tmp/${tmpIsoName}.sparseimage
    set +x

    echo
    echo Rename the ISO and move it to the desktop
    echo --------------------------------------------------------------------------
    set -x
    mv /tmp/${OsFamiliarName}.cdr ~/Downloads/${OsFamiliarName}.iso
    set +x
  fi
}

#
# installerExists
#
# Returns 0 if the installer was found either locally or in the /Applications directory.  1 if not.
#
function installerExists()
{
  local installerAppName=$1
  local result=1
  if [ -e "${installerAppName}" ] ; then
    result=0
  elif [ -e /Applications/"${installerAppName}" ] ; then
    result=0
  fi
  return ${result}
}

#
# Main script code
#
# Eject installer disk in case it was opened after download from App Store
hdiutil info | grep /dev/disk | grep partition | cut -f 1 | xargs --no-run-if-empty hdiutil detach -force

# See if we can find an elligible installer.
# If successful, then create the iso file from the installer.

installerExists "Install macOS High Sierra.app"
result=$?
if [ ${result} -eq 0 ] ; then
  createISO "Install macOS High Sierra.app" "HighSierra"
#else
#  installerExists "Install macOS Sierra.app"
#  result=$?
#  if [ ${result} -eq 0 ] ; then
#    createISO "Install macOS Sierra.app" "Sierra"
#  else
#    installerExists "Install OS X El Capitan.app"
#    result=$?
#    if [ ${result} -eq 0 ] ; then
#      createISO "Install OS X El Capitan.app" "ElCapitan"
#    else
#      installerExists "Install OS X Yosemite.app"
#      result=$?
#      if [ ${result} -eq 0 ] ; then
#        createISO "Install OS X Yosemite.app" "Yosemite"
else
    echo "Could not find installer.  I looked in Applications and in the local dir."
#      fi
#    fi
#  fi
fi
