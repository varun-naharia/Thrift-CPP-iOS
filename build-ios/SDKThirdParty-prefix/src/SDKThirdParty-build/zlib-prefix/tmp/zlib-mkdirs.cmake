# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/Users/Technaharia/Downloads/Thrift-Test/ThirdParty/zlib-1.2.11")
  file(MAKE_DIRECTORY "/Users/Technaharia/Downloads/Thrift-Test/ThirdParty/zlib-1.2.11")
endif()
file(MAKE_DIRECTORY
  "/Users/Technaharia/Downloads/Thrift-Test/build-ios/SDKThirdParty-prefix/src/SDKThirdParty-build/zlib-prefix/src/zlib-build"
  "/Users/Technaharia/Downloads/Thrift-Test/build-ios/staging"
  "/Users/Technaharia/Downloads/Thrift-Test/build-ios/SDKThirdParty-prefix/src/SDKThirdParty-build/zlib-prefix/tmp"
  "/Users/Technaharia/Downloads/Thrift-Test/build-ios/SDKThirdParty-prefix/src/SDKThirdParty-build/zlib-prefix/src/zlib-stamp"
  "/Users/Technaharia/Downloads/Thrift-Test/build-ios/SDKThirdParty-prefix/src/SDKThirdParty-build/zlib-prefix/src"
  "/Users/Technaharia/Downloads/Thrift-Test/build-ios/SDKThirdParty-prefix/src/SDKThirdParty-build/zlib-prefix/src/zlib-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/Users/Technaharia/Downloads/Thrift-Test/build-ios/SDKThirdParty-prefix/src/SDKThirdParty-build/zlib-prefix/src/zlib-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/Users/Technaharia/Downloads/Thrift-Test/build-ios/SDKThirdParty-prefix/src/SDKThirdParty-build/zlib-prefix/src/zlib-stamp${cfgdir}") # cfgdir has leading slash
endif()
