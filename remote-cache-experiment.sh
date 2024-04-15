#!/bin/bash

homeDir=build/HOME

# Initialize empty Gradle User Home with settings to run build, including Develocity access keys
echo "Initializing Gradle User Home directory at $homeDir"
mkdir -p $homeDir
cp ~/.gradle/gradle.properties $homeDir
cp -r ~/.gradle/develocity $homeDir
cp -r ~/.gradle/enterprise $homeDir

echo "------------------------------------------------------------"
echo "Priming build with HOME=$homeDir"
echo "------------------------------------------------------------"
./gradlew -g $homeDir -Dscan.tag.remote-cache-experiment-init --no-configuration-cache -Ddevelocity.deprecation.muteWarnings=true -Dscan.uploadInBackground=false help

caches='transforms groovy-dsl kotlin-dsl'
for cache in $caches
do
    for buildCache in 'build-cache' 'no-build-cache'
    do
        echo "------------------------------------------------------------"
        echo "Test caches/*/$cache removal with --$buildCache"
        echo "------------------------------------------------------------"
        killall -9 java
        
        # git clean -dfx -e HOME -e cleanup-help.sh
        echo "Removing $cache from $homeDir/caches"
        rm -rf $homeDir/caches/*/$cache
        rm -rf $homeDir/caches/$cache-* # Also remove the transforms for Gradle 8.7

        # Always remove the local build cache, since we are testing connection with remote build cache
        rm -rf $homeDir/caches/build-cache-1

        ./gradlew -g $homeDir --$buildCache -Dscan.tag.remote-cache-experiment-$cache-$buildCache --no-configuration-cache -Ddevelocity.deprecation.muteWarnings=true -Dscan.uploadInBackground=false help
        echo ""
    done
done
