set(F_FILES base_stats_mod.F90 calc_stat_mod.F90 rng_mod.F90)

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/modules)

add_library(sverif STATIC ${F_FILES} ${C_FILES})
add_dependencies(sverif ${PROJECT_NAME}_build_info)

#target_include_directories(sverif PUBLIC $<BUILD_INTERFACE:${CMAKE_Fortran_MODULE_DIRECTORY}>)
target_include_directories(sverif PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>)

target_link_libraries(sverif PUBLIC
  rmn::rmn)

add_executable(sverif_fname.Abs sverif_fname.F90)
target_link_libraries(sverif_fname.Abs
  sverif
  rmn::rmn)

add_executable(sverif_prep.Abs sverif_prep.F90)
target_link_libraries(sverif_prep.Abs
  sverif
  rmn::rmn)

add_executable(sverif_eval.Abs sverif_eval.F90)
target_link_libraries(sverif_eval.Abs
  sverif
  rmn::rmn)

install(TARGETS sverif_fname.Abs sverif_prep.Abs sverif_eval.Abs RUNTIME DESTINATION bin)
