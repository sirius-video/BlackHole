#!/usr/bin/env zsh



# create installer for different channel versions

for driver_name in "SiriusA" "SiriusB" #16 #64 128 256
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
mv build/BlackHole.driver Installer/root/BlackHole_$driver_name.driver
rm -r build

# Sign
codesign --force --deep --options runtime --sign 924D2BA9B9CC4F2965E32FFA2AC6DC69A88962358 Installer/root/BlackHole_$driver_name.driver

# Create package with pkgbuild
chmod 755 Installer/Scripts/preinstall
chmod 755 Installer/Scripts/postinstall

pkgbuild --sign "24D2BA9B9CC4F2965E32FFA2AC6DC69A88962358" --root Installer/root --scripts Installer/Scripts --install-location /Library/Audio/Plug-Ins/HAL Installer/BlackHole_$driver_name.pkg
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
    <pkg-ref id=\"$bundleID\" version=\"$version\" onConclusion='none'>BlackHole_$driver_name.pkg</pkg-ref>
</installer-gui-script>" >> distribution.xml


productbuild --sign "24D2BA9B9CC4F2965E32FFA2AC6DC69A88962358" --distribution distribution.xml --resources . --package-path BlackHole_$driver_name.pkg $output_package_name.pkg
rm distribution.xml
rm -f BlackHole_$driver_name.pkg

# Notarize
xcrun notarytool submit $output_package_name.pkg --team-id 4M658Z2K2X --progress --wait --keychain-profile "Notarize"  --verbose

#xattr -rc $output_package_name.pkg

xcrun stapler staple $output_package_name.pkg

cd ..

done


