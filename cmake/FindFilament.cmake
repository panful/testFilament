if(NOT DEFINED Filament_DIR)
    set(Filament_DIR $ENV{Filament_DIR})
endif()

# 查找 Filament 的 include 目录
find_path(FILAMENT_INCLUDE_DIRS
    NAMES filament/Engine.h
    PATHS
        ${Filament_DIR}/include
    DOC "Path to Filament include directories"
)

# 设置搜索库的默认路径
set(FILAMENT_LIB_DIR_HINTS "${Filament_DIR}/lib/x86_64")

# 创建一个变量来保存所有找到的库文件
set(Filament_Libs "")

# Helper function to simplify library finding and importing
function(find_filament_library lib_name)
    find_library(${lib_name}_LIB
        NAMES ${lib_name}
        PATHS ${FILAMENT_LIB_DIR_HINTS}
    )

    if (NOT ${lib_name}_LIB)
        message(FATAL_ERROR "Could not find Filament library: ${lib_name}")
    endif()

    add_library(Filament::${lib_name} UNKNOWN IMPORTED)
    set_target_properties(Filament::${lib_name} PROPERTIES
        IMPORTED_LOCATION ${${lib_name}_LIB}
    )

    # 将库添加到 Filament_Libs 变量中
    list(APPEND Filament_Libs "Filament::${lib_name}")
    set(Filament_Libs ${Filament_Libs} PARENT_SCOPE)
endfunction()

# Filament core libraries
find_filament_library(filament)
find_filament_library(utils)
find_filament_library(viewer)
find_filament_library(backend)
find_filament_library(basis_transcoder)
find_filament_library(bluegl)
find_filament_library(bluevk)
find_filament_library(camutils)
find_filament_library(civetweb)
find_filament_library(dracodec)
find_filament_library(filabridge)
find_filament_library(filaflat)
find_filament_library(filamat)
find_filament_library(filament-iblprefilter)
find_filament_library(filameshio)
find_filament_library(geometry)
find_filament_library(gltfio)
find_filament_library(gltfio_core)
find_filament_library(ibl-lite)
find_filament_library(ibl)
find_filament_library(image)
find_filament_library(ktxreader)
find_filament_library(matdbg)
find_filament_library(meshoptimizer)
find_filament_library(mikktspace)
find_filament_library(shaders)
find_filament_library(smol-v)
find_filament_library(stb)
find_filament_library(uberarchive)
find_filament_library(uberzlib)
find_filament_library(vkshaders)
find_filament_library(zstd)

if(WIN32)
    list(APPEND Filament_Libs OpenGL32)
endif(WIN32)
