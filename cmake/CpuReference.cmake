# Codex CUDA Port: optional build wrapper around the untouched MKL CPU source.
# The files in reference/gpe1d_2-master are compiled directly and never edited.
find_package(MKL CONFIG REQUIRED)

set(GPE_CPU_REFERENCE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/reference/gpe1d_2-master/gpe1d_2"
)
add_executable(gpe1d_cpu_reference
    "${GPE_CPU_REFERENCE_DIR}/gpe1d_2.cpp"
    "${GPE_CPU_REFERENCE_DIR}/array_tools.cpp"
    "${GPE_CPU_REFERENCE_DIR}/config.cpp"
    "${GPE_CPU_REFERENCE_DIR}/dynamic_potential_1d.cpp"
    "${GPE_CPU_REFERENCE_DIR}/dynamic_potential_2d.cpp"
    "${GPE_CPU_REFERENCE_DIR}/dynamic_potential_3d.cpp"
    "${GPE_CPU_REFERENCE_DIR}/file_tools.cpp"
    "${GPE_CPU_REFERENCE_DIR}/math_routines_1d.cpp"
    "${GPE_CPU_REFERENCE_DIR}/math_routines_2d.cpp"
    "${GPE_CPU_REFERENCE_DIR}/math_routines_3d.cpp"
    "${GPE_CPU_REFERENCE_DIR}/reduction_3d.cpp"
)
target_include_directories(gpe1d_cpu_reference PRIVATE "${GPE_CPU_REFERENCE_DIR}")
target_link_libraries(gpe1d_cpu_reference PRIVATE MKL::MKL HDF5::HDF5)
target_compile_definitions(gpe1d_cpu_reference PRIVATE _CRT_SECURE_NO_WARNINGS NOMINMAX)
set_target_properties(gpe1d_cpu_reference PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/bin"
)

