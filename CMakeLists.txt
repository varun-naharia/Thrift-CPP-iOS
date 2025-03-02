
cmake_minimum_required(VERSION 3.18)

project(ThriftTest)


# Specify the C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(IOS_CMAKE_DIR ${CMAKE_SOURCE_DIR}/cmake-iostoolchain)


# Include ExternalProject module
include(ExternalProject)

file(MAKE_DIRECTORY ${SDK_STAGING_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(TARGET_PLATFORM "macOS" CACHE STRING "Target platform for the build") # Options are macOS, Linux, iOS, Android.
set(ARCHITECTURE "arm64" CACHE STRING "Target Arch for the build") # Options are arm64, x86_64, android-arm64, 

# # Add the ThirdParty directory
# add_subdirectory(ThirdParty)


# # Add the lib directory
# add_subdirectory(lib)

# find_package(OpenSSL REQUIRED)

# # Add the main executable
# add_executable(main main.cc)

# # Link the LibCore library and OpenSSL to the main executable
# target_link_libraries(main LibCore OpenSSL::SSL OpenSSL::Crypto)

# # Ensure that the main executable depends on OpenSSL being built
# add_dependencies(main OpenSSL)

# Define the SDK staging directory
if (NOT DEFINED SDK_STAGING_DIR)
    set(SDK_STAGING_DIR ${CMAKE_BINARY_DIR}/staging)
endif ()

ExternalProject_Add(
    SDKThirdParty
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ThirdParty
    INSTALL_DIR ${SDK_STAGING_DIR}
    CMAKE_CACHE_ARGS
        -DTHIRDPARTY_INSTALL_DIR:PATH=<INSTALL_DIR>
        -DTARGET_PLATFORM:PATH=${TARGET_PLATFORM}
        -DARCHITECTURE:PATH=${ARCHITECTURE}
        -DIPHONE_SDKVERSION:PATH=${IPHONE_SDKVERSION}
    INSTALL_COMMAND "" # Disable the install step
)

if(TARGET_PLATFORM STREQUAL "iOS")
    message("building for iOS")
    set(EXTERNAL_PROJECT_CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${IOS_CMAKE_DIR}/ios.toolchain.cmake
        -DPLATFORM=OS64
        -DCMAKE_BUILD_TYPE=Release
    )
endif ()

ExternalProject_Add(
    LibCore
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lib
    INSTALL_DIR ${SDK_STAGING_DIR}
    CMAKE_ARGS ${EXTERNAL_PROJECT_CMAKE_ARGS}
    DEPENDS SDKThirdParty
    CMAKE_CACHE_ARGS
        -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
        -DTHIRDPARTY_INSTALL_DIR:PATH=${SDK_STAGING_DIR}
        -DOPENSSL_ROOT_DIR:PATH=${SDK_STAGING_DIR}
    BUILD_ALWAYS ON
)

# Install public headers
install(FILES
    "${SDK_STAGING_DIR}/include/LibCore.hh"
    DESTINATION include
)


# Install libraries for Unix-like systems
if (UNIX)
    if (APPLE)
        install(DIRECTORY "${SDK_STAGING_DIR}/lib"
            DESTINATION .
            FILES_MATCHING
            PATTERN "*.dylib"
            PATTERN "cmake" EXCLUDE
            PATTERN "pkg-config" EXCLUDE
            PATTERN "pkgconfig" EXCLUDE
            REGEX "engines*" EXCLUDE
        )
    else ()
        install(DIRECTORY "${SDK_STAGING_DIR}/lib"
            DESTINATION .
            FILES_MATCHING
            PATTERN "*.so"
            PATTERN "cmake" EXCLUDE
            PATTERN "pkg-config" EXCLUDE
            PATTERN "pkgconfig" EXCLUDE
            REGEX "engines*" EXCLUDE
        )
    endif ()
endif ()