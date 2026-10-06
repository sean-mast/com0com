cmake_minimum_required(VERSION 3.17)

# Enable C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Source files
set(SOURCES
    AssemblyInfo.cpp
    exec.cpp
    pinmap.cpp
    portprms.cpp
    setup.cpp
    stdafx.cpp
    app.rc
    com0com.ico
    Form1.resx
)

set(HEADERS
    exec.h
    Form1.h
    pinmap.h
    portprms.h
    resource.h
)

# Precompiled header
set(PCH_HEADER stdafx.h)
set(PCH_SOURCE stdafx.cpp)

# Add executable
add_executable(setupg ${SOURCES} ${HEADERS})
target_precompile_headers(setupg PRIVATE ${PCH_HEADER})
target_include_directories(setupg PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

#if(CMAKE_BUILD_TYPE STREQUAL "Debug")
#    target_compile_definitions(setupg PRIVATE _DEBUG)
#else()
#    target_compile_definitions(setupg PRIVATE NDEBUG)
#endif()

set_target_properties(setupg PROPERTIES
    COMMON_LANGUAGE_RUNTIME ""
    VS_CHARSET "Unicode"
    VS_GLOBAL_ROOTNAMESPACE SetupApp
    VS_GLOBAL_KEYWORD "ManagedCProj"
    #VS_GLOBAL_CLRSupport "true"
    VS_DOTNET_REFERENCES "System;System.Windows.Forms;System.Drawing;System.Data"
    VS_DOTNET_TARGET_FRAMEWORK_VERSION "v4.8"

    #DOTNET_TARGET_FRAMEWORK "v4.7.2"
    #VS_DOTNET_REFERENCES "System" "System.Data" "System.Drawing" "System.Windows.Forms" "System.Xml"
)

if(MSVC)
    # Remove /RTC and /EH flags from global flags
    string(REPLACE "/EHsc" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(REPLACE "/RTC1" "" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
    target_compile_options(setupg PRIVATE /clr /EHa /W4)
endif()
