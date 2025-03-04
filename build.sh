#!/bin/bash

# Define the build directories
BUILD_DIR="build"
BUILD_MAC_DIR="build-mac"
BUILD_IOS_DIR="build-ios"
BUILD_LINUX_DIR="build-linux"
BUILD_ANDROID_DIR="build-android"

# Define the staging directory where successfully built libraries are copied
STAGING_LIB_DIR="build/staging/lib"

SKIP_CONFIRMATION=false  # Default is false (ask for confirmation)

CMAKE_TOOCHAIN=  $pwd/ThirdParty/cmake-iostoolchain/ios.toolchain.cmake

# Check if /f argument is passed to skip confirmation
for arg in "$@"; do
    if [[ "$arg" == "/f" ]]; then
        SKIP_CONFIRMATION=true
        echo "Skipping confirmation as /f is passed."
    fi
done

# Function to detect the correct build directory based on the platform
detect_build_and_prefix_dirs() {
    local platform="$1"
    echo "platform:$platform"
    STAGING_LIB_DIR="$platform/staging/lib"
    echo "STAGING_LIB_DIR:$STAGING_LIB_DIR"
    case "$platform" in
        build-mac) 
            BUILD_DIR="build"
            PREFIX_DIR="build/SDKThirdParty-prefix"
            ;;
        build-ios) 
            BUILD_DIR="build-ios"
            PREFIX_DIR="build-ios/SDKThirdParty-prefix"
            ;;
        build-linux) 
            BUILD_DIR="build-linux"
            PREFIX_DIR="build-linux/SDKThirdParty-prefix"
            ;;
        build-android) 
            BUILD_DIR="build-android"
            PREFIX_DIR="build-android/SDKThirdParty-prefix"
            ;;
        *)
            echo "Unknown platform: $platform"
            exit 1
            ;;
    esac
}
# Function to find expected library name inside a build folder
get_expected_lib_name() {
    local build_folder="$1"

    # Search for a .a, .so, .dylib, or .dll file inside the build directory
    local found_lib=$(find "$build_folder" -type f \( -name "*.a" -o -name "*.so" -o -name "*.dylib" -o -name "*.dll" \) | head -n 1)

    if [[ -n "$found_lib" ]]; then
        basename "$found_lib"
    else
        echo ""  # Return empty if no library is found
    fi
}

# Function to check if a library exists in staging/lib
is_library_built() {
    local folder_name="$1"
    echo "checking folder_name:$folder_name"
    # Handle special case where 'openssl' is actually 'libssl'
    if [[ "$folder_name" == "openssl-prefix" ]]; then
        folder_name="ssl"
    fi

    if [[ "$folder_name" == "zlib-prefix" ]]; then
        folder_name="z"
    fi

    if [[ "$folder_name" == "thrift-gen-prefix" ]]; then
        folder_name="bayunlo"
    fi

    if [[ "$folder_name" == "dd-opentracing-prefix" ]]; then
        folder_name="dd_opentracing"
    fi

     if [[ "$folder_name" == "msgpack-prefix" ]]; then
        folder_name="msgpackc"
    fi

    if [[ "$folder_name" == "jsoncpp-master-prefix" ]]; then
        folder_name="jsoncpp"
    fi


    # Remove '-prefix' suffix to get the expected library name pattern
    local lib_pattern=$(echo "$folder_name" | sed 's/-prefix//')

    # Print debug information
    echo "🔍 Checking for built library: '$lib_pattern' in staging/lib"

    # Print contents of staging/lib for debugging
    echo "📂 Contents of staging/lib:"
    ls "$STAGING_LIB_DIR"

    # Print grep command result to see what it's matching
    echo "🧐 Running: ls \"$STAGING_LIB_DIR\" | grep \"$lib_pattern\""
    ls "$STAGING_LIB_DIR" | grep "$lib_pattern"

    # Check if any file in staging/lib contains the folder name
    if ls "$STAGING_LIB_DIR" | grep -q "$lib_pattern"; then
        echo "✅ Library '$lib_pattern' was found. Keeping it."
        return 0  # Found, library was built successfully
    else
        echo "❌ Library '$lib_pattern' NOT found. Marking it for removal."
        return 1  # Not found, library build likely failed
    fi
}

# Function to clean up failed builds
clean_build_directory() {
    local platform="$1"
    echo "platform:$platform"
    detect_build_and_prefix_dirs "$platform"

    if [ ! -d "$BUILD_DIR" ]; then
        echo "Build directory missing: $BUILD_DIR"
        return
    fi

    echo "Cleaning failed builds in: $BUILD_DIR..."

    # If staging/lib does not exist, assume all builds failed and delete everything
    if [ ! -d "$STAGING_LIB_DIR" ]; then
        echo "Staging lib missing. Removing entire build and prefix directories..."
        rm -rf "$BUILD_DIR" "$PREFIX_DIR"
        return
    fi

    # Remove only the failed build folders
    if [ -d "$PREFIX_DIR/src" ]; then
        echo "Checking for failed builds inside $PREFIX_DIR/src/"

        for build_folder in "$PREFIX_DIR/src/"*-build; do
            if [ -d "$build_folder" ]; then
                build_name=$(basename "$build_folder" | sed 's/-build//')

                # Find subdirectories in the build folder (individual library builds)
                for subfolder in "$build_folder"/*; do
                    if [ -d "$subfolder" ]; then
                        subfolder_name=$(basename "$subfolder")

                        # Ignore CMake-related directories
                        if [[ "$subfolder_name" == "CMakeFiles" || "$subfolder_name" == "_deps" || "$subfolder_name" == "cmake_install.cmake" ]]; then
                            continue
                        fi

                        # Check if any library matching this name is in staging/lib
                        if ! is_library_built "$subfolder_name"; then
                            echo "Library $subfolder_name not found in staging/lib."

                            # Confirm before removing the specific library build folder unless skipping confirmation
                            if [ "$SKIP_CONFIRMATION" = true ]; then
                                echo "Removing failed build: $subfolder without confirmation."
                                rm -rf "$subfolder"
                            else
                                read -p "Are you sure you want to remove the failed build: $subfolder? (y/n) " confirm
                                if [[ "$confirm" == [Yy]* ]]; then
                                    echo "Removing failed build: $subfolder"
                                    rm -rf "$subfolder"
                                else
                                    echo "Skipping removal of: $subfolder"
                                fi
                            fi
                        else
                            echo "Library $subfolder_name exists in staging/lib. Keeping build."
                        fi
                    fi
                done
            fi
        done
    fi

    # Remove CMake cache and temporary build files
    echo "Removing CMake cache and temporary build files..."
    find "$BUILD_DIR" -type f \( -name "CMakeCache.txt" -o -name "*.cmake" -o -name "Makefile" -o -name "*.ninja" \) -exec rm -f {} \;

    echo "Cleanup completed for: $BUILD_DIR and $PREFIX_DIR"
}


# Function to build for macOS
    # Build the project for macOS using CMake. This function cleans the existing
    # build directory, creates a new one, and runs CMake to configure and build
    # the project for the macOS platform.

build_mac_project() {
    echo "Building for macOS..."
    clean_build_directory "$BUILD_MAC_DIR"
    mkdir "$BUILD_DIR"
    cd "$BUILD_DIR" || exit
    echo "Running CMake for macOS..."
    cmake -DTARGET_PLATFORM=macOS  ..
    echo "Building the macOS project..."
    cmake --build .
    echo "macOS build completed."
}

# Function to build for iOS
# Build the SDK for iOS using CMake. This function is called by the main
# script execution and is responsible for setting up the environment
# variables and running CMake for iOS.
build_ios_project() {
    echo "Building for iOS..."
    clean_build_directory "$BUILD_IOS_DIR"
    mkdir "$BUILD_IOS_DIR"
    cd "$BUILD_IOS_DIR" || exit
    echo "Setting iOS environment variables..."
    export CROSS_TOP=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
    export CROSS_SDK=iPhoneOS.sdk
    # export ARCH=arm64
    # export SDK=iphoneos
    # export DEPLOYMENT_TARGET=11.0
    # export CFLAGS="-arch $ARCH -isysroot $(xcrun -sdk $SDK --show-sdk-path) -m$SDK-version-min=$DEPLOYMENT_TARGET"

    echo "Running CMake for iOS..."
    cmake -G "Unix Makefiles" \
        -DCMAKE_TOOLCHAIN_FILE= $CMAKE_TOOCHAIN \
        -DPLATFORM=OS64 \
        -DTARGET_PLATFORM=iOS \
        -DARCHITECTURE=arm64 ..
        
    echo "Building the iOS project..."
    cmake  --build . -v | tee build-ios.log
    echo "iOS build completed."
}

# Function to build for Linux
# Build the SDK for Linux using CMake. This function is called by the main
# script execution and is responsible for setting up the environment
# variables and running CMake for Linux.
build_linux_project() {
    echo "Building for Linux..."
    clean_build_directory "$BUILD_LINUX_DIR"
    mkdir "$BUILD_LINUX_DIR"
    cd "$BUILD_LINUX_DIR" || exit
    echo "Running CMake for Linux..."
    cmake ..
    echo "Building the Linux project..."
    cmake --build .
    echo "Linux build completed."
}

# Function to build for Android
# Build the SDK for Android using CMake. This function is called by the main
# script execution and is responsible for setting up the environment
# variables and running CMake for Android.
build_android_project() {
    echo "Building for Android..."
    clean_build_directory "$BUILD_ANDROID_DIR"
    mkdir "$BUILD_ANDROID_DIR"
    cd "$BUILD_ANDROID_DIR" || exit
    echo "Running CMake for Android..."
    cmake -DCMAKE_TOOLCHAIN_FILE="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin" \
          -DANDROID_ABI=arm64-v8a \
          -DANDROID_PLATFORM=android-21 ..
    echo "Building the Android project..."
    cmake --build .
    echo "Android build completed."
}

# Check if the second argument is "/f" (force mode)
FORCE_MODE=false
if [[ "$2" == "/f" ]]; then
    FORCE_MODE=true
fi

# Main script execution
case "$1" in
    mac)
        build_mac_project
        ;;
    ios)
        build_ios_project
        ;;
    linux)
        build_linux_project
        ;;
    android)
        build_android_project
        ;;
    clean-ios)
        if [ "$FORCE_MODE" = true ]; then
            clean_build_directory "$BUILD_IOS_DIR" --force
        else
            clean_build_directory "$BUILD_IOS_DIR"
        fi
        ;;
    *)
        echo "Usage: $0 {mac|ios|linux|android|clean-ios} [/f]"
        exit 1
        ;;
esac

