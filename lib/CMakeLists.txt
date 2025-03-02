cmake_minimum_required(VERSION 3.4)

project(LibCore)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED on)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(LIB_SRC
    "LibCore.cc"
)

# Create a library from the source files
# add_library(LibCore LibCore.cc)
add_library(LibCore SHARED
    ${LIB_SRC})   
# Specify the include directories for the library
target_include_directories(LibCore PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

find_package(OpenSSL REQUIRED)

# Link OpenSSL to LibCore
target_link_libraries(LibCore PUBLIC OpenSSL::SSL OpenSSL::Crypto)


install(TARGETS LibCore
    LIBRARY DESTINATION lib)

install(FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/LibCore.hh"
    DESTINATION include)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
if(TARGET_PLATFORM STREQUAL "macOS")
    add_executable(
        libCore_test
        ../main.cc
        )
        
    target_link_libraries(
        libCore_test
        LibCore)
        
    install(TARGETS libCore_test 
            RUNTIME DESTINATION tests)
endif ()