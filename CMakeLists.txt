cmake_minimum_required(VERSION 3.16)

message(STATUS "(EC) Generating sverif Makefile")

#----- Append EC specific module path
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake_rpn/modules $ENV{EC_CMAKE_MODULE_PATH})

include(ec_init)           # Initialise compilers and ec specific functions
ec_git_version()           # Get version from git state
ec_parse_manifest()        # Parse MANIFEST file

project(${NAME} DESCRIPTION "${DESCRIPTION}" LANGUAGES C Fortran)
set(PROJECT_VERSION ${VERSION}${STATE})

ec_build_info()            # Generate build information

include(ec_compiler_presets)

set(MPI_COMPILER_FLAGS "${MPI_COMPILER_FLAGS} -static_mpi -nostrip")
set(STATIC_LINK_INTEL_FLAGS "-static-libgcc -static-libstdc++ -qopenmp-link=static")

set(WITH_OPENMP TRUE CACHE BOOL "Control whether to use OpenMP")
include(ec_openmp)

find_package(MPI)

if (NOT rmn_FOUND)
   find_package(rmn ${rmn_REQ_VERSION} REQUIRED)
endif()

install(PROGRAMS "${CMAKE_SOURCE_DIR}/scripts/sverif_eval" DESTINATION bin)
install(PROGRAMS "${CMAKE_SOURCE_DIR}/scripts/sverif_prep" DESTINATION bin)
install(FILES "${CMAKE_SOURCE_DIR}/scripts/eval.R" DESTINATION bin)
install(FILES "${CMAKE_SOURCE_DIR}/scripts/prep.R" DESTINATION bin)

add_subdirectory(src src)

#----- Generate the config file for the project to be usable via cmake's find_package command
set(INCLUDE_INSTALL_DIR include)
set(LIB_INSTALL_DIR     lib)
set(CONFIG_INSTALL_DIR  "${LIB_INSTALL_DIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}")

#----- Packaging
ec_package_name()                 # Define package prefix  
ec_build_config()                 # Create build configuration script
ec_prepare_ssm()                  # Prepare ssm packaging files

set(CPACK_GENERATOR "TGZ")
set(CPACK_PACKAGE_VENDOR "ECCC")
set(CPACK_PACKAGE_CONTACT "${MAINTAINER}")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
set(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/package")
set(CPACK_PACKAGE/_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set(CPACK_PACKAGE_FILE_NAME "${PACKAGE_NAME}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${NAME}_${PROJECT_VERSION}")
include(CPack)
