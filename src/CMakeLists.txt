add_executable(sverif_fname sverif_fname.F90)
target_link_libraries(sverif_fname
  modelutils
  rmn::rmn
  ${LAPACK_LIBRARIES}
  ${BLAS_LIBRARIES} )

add_executable(sverif_prep sverif_prep.F90)
target_link_libraries(sverif_prep
  modelutils
  rmn::rmn
  ${LAPACK_LIBRARIES}
  ${BLAS_LIBRARIES} )

add_executable(sverif_eval sverif_eval.F90)
target_link_libraries(sverif_eval
  modelutils
  rmn::rmn
  ${LAPACK_LIBRARIES}
  ${BLAS_LIBRARIES} )

install(TARGETS sverif_fname sverif_prep sverif_eval RUNTIME DESTINATION bin)
