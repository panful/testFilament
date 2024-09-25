set(target_name Demo)

add_executable(${target_name} ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp)

target_include_directories(${target_name} PRIVATE ${FILAMENT_INCLUDE_DIRS})
target_link_libraries(${target_name} PRIVATE ${Filament_Libs})
