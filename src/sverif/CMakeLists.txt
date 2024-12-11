file(GLOB F_FILES base_stats_mod.F90 calc_stat_mod.F90 rng_mod.F90)

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/modules)

add_library(sverif STATIC ${F_FILES} ${C_FILES})
add_dependencies(sverif ${PROJECT_NAME}_build_info)

target_include_directories(sverif PUBLIC $<BUILD_INTERFACE:${CMAKE_Fortran_MODULE_DIRECTORY}>)

target_link_libraries(sverif PUBLIC
  modelutils
  )

add_executable(sverif_fname sverif_fname.F90)
target_link_libraries(sverif_fname
  sverif
  modelutils
  rmn::rmn
  ${LAPACK_LIBRARIES}
  ${BLAS_LIBRARIES} )

add_executable(sverif_prep sverif_prep.F90)
target_link_libraries(sverif_prep
  sverif
  modelutils
  rmn::rmn
  ${LAPACK_LIBRARIES}
  ${BLAS_LIBRARIES} )

add_executable(sverif_eval sverif_eval.F90)
target_link_libraries(sverif_eval
  sverif
  modelutils
  rmn::rmn
  ${LAPACK_LIBRARIES}
  ${BLAS_LIBRARIES} )

install(TARGETS sverif_fname sverif_prep sverif_eval RUNTIME DESTINATION bin)
