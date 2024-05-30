add_executable(
        structureStressTest
        structureStressTest.m
)

target_link_libraries(
        structureStressTest
        ${art_generic_link_libraries}
)

target_compile_options(structureStressTest PRIVATE -Wall -Wextra)

install (
        TARGETS
        structureStressTest
        DESTINATION
        ${art_executable_directory}
)
