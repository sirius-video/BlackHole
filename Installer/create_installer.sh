#!/usr/bin/env zsh



# create installer for different channel versions

for driver_name in "SiriusA" "SiriusB"
do
channels=2
ch=$channels"ch"
version=v$(head -n 1 VERSION)
bundleID="audio.existential.BlackHole."$driver_name

output_package_name=$driver_name

# Build
xcodebuild \
-project BlackHole.xcodeproj \
-configuration Release \
-target BlackHole CONFIGURATION_BUILD_DIR=build \
PRODUCT_BUNDLE_IDENTIFIER=$bundleID \
GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS kDriver_Name=\"'$driver_name'\" kNumber_Of_Channels='$channels' kPlugIn_BundleID=\"'$bundleID'\"'

mkdir Installer/root
mv build/BlackHole.driver Installer/root/BlackHole.driver
rm -r build

# Sign with Developer ID Application
codesign --force --deep --options runtime --sign 4M658Z2K2X Installer/root/BlackHole.driver

# Create package with pkgbuild
chmod 755 Installer/Scripts/preinstall
chmod 755 Installer/Scripts/postinstall

# with Developer ID Installer/Application?
pkgbuild --sign "4M658Z2K2X" --root Installer/root --scripts Installer/Scripts --install-location /Library/Audio/Plug-Ins/HAL Installer/BlackHole.pkg
rm -r Installer/root

# Create installer with productbuild
cd Installer

echo "<?xml version=\"1.0\" encoding='utf-8'?>
<installer-gui-script minSpecVersion='2'>
    <title>BlackHole: Virtual Audio Driver $ch $version</title>
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
    <pkg-ref id=\"$bundleID\" version=\"$version\" onConclusion='none'>BlackHole.pkg</pkg-ref>
</installer-gui-script>" >> distribution.xml

# Developer ID Installer
productbuild --sign "2DA71F5976D336716B85829AE4F5E53CDE869B2D" --distribution distribution.xml --resources . --package-path BlackHole.pkg $output_package_name.pkg
rm distribution.xml
rm -f BlackHole.pkg

# Notarize with Developer ID Installer
xcrun notarytool submit $output_package_name.pkg --team-id 2DA71F5976D336716B85829AE4F5E53CDE869B2D --progress --wait --keychain-profile "Notarize"  #--verbose

xcrun stapler staple $output_package_name.pkg

cd ..

done


