#!/usr/bin/env zsh



# create installer for different channel versions

for driver_name in "SiriusA" "SiriusB"
do
channels=2
ch=$channels"ch"
version=v$(head -n 1 VERSION)
bundleID="audio.existential.BlackHole."$driver_name
device_name=$driver_name
device2_name=$driver_name"2"
output_package_name=$driver_name


# Build
xcodebuild \
-project BlackHole.xcodeproj \
-configuration Release \
-target BlackHole CONFIGURATION_BUILD_DIR=build \
PRODUCT_BUNDLE_IDENTIFIER=$bundleID \
GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS kDriver_Name=\"'$driver_name'\"  kNumber_Of_Channels='$channels' kPlugIn_BundleID=\"'$bundleID'\" kDevice_Name=\"'$device_name'\" kDevice2_Name=\"'$device2_name'\"'

mkdir Installer/root
mv build/BlackHole.driver Installer/root/BlackHole.$driver_name.driver
rm -r build

# Sign with Developer ID Application
codesign --force --deep --options runtime --sign 4M658Z2K2X Installer/root/BlackHole.$driver_name.driver

# Create package with pkgbuild
chmod 755 Installer/Scripts/preinstall
chmod 755 Installer/Scripts/postinstall

# with Developer ID Installer/Application?
pkgbuild --sign "4M658Z2K2X" --root Installer/root --scripts Installer/Scripts --install-location /Library/Audio/Plug-Ins/HAL Installer/BlackHole.$driver_name.pkg
rm -r Installer/root

# Create installer with productbuild
cd Installer

echo "<?xml version=\"1.0\" encoding='utf-8'?>
<installer-gui-script minSpecVersion='2'>
    <title>Sirius.video Virtual Audio Driver</title>
    <welcome file='welcome.html'/>
    <license file='../LICENSE'/>
    <conclusion file='conclusion.html'/>
    <domains enable_anywhere='false' enable_currentUserHome='false' enable_localSystem='true'/>
    <pkg-ref id=\"$bundleID\"/>
    <options customize='never' require-scripts='false' hostArchitectures='x86_64,arm64'/>
    <volume-check>
        <allowed-os-versions>
            <os-version min='10.9'/>
        </allowed-os-versions>
    </volume-check>
    <choices-outline>
        <line choice=\"$bundleID\"/>
    </choices-outline>
    <choice id=\"$bundleID\" visible='true' title=\"BlackHole $driver_name\" start_selected='true'>
        <pkg-ref id=\"$bundleID\"/>
    </choice>
    <pkg-ref id=\"$bundleID\" version=\"$version\" onConclusion='none'>BlackHole.$driver_name.pkg</pkg-ref>
</installer-gui-script>" >> distribution.xml

# Developer ID Installer
productbuild --sign "2DA71F5976D336716B85829AE4F5E53CDE869B2D" --distribution distribution.xml --resources . --package-path BlackHole.$driver_name.pkg $output_package_name.pkg
rm distribution.xml
rm -f BlackHole.$driver_name.pkg

# Notarize with Developer ID Installer
xcrun notarytool submit $output_package_name.pkg --team-id 2DA71F5976D336716B85829AE4F5E53CDE869B2D --progress --wait --keychain-profile "Notarize"  #--verbose

xcrun stapler staple $output_package_name.pkg

cd ..

done


