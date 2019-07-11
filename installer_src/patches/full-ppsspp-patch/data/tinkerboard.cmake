include_directories(SYSTEM
  /usr/local/include
  /usr/include
)

set(ARCH_FLAGS "-O3 -marm -march=armv7-a -mfpu=neon-vfpv4 -mtune=cortex-a17 -mfloat-abi=hard -ftree-vectorize -funsafe-math-optimizations -pipe")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARCH_FLAGS}"  CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARCH_FLAGS}" CACHE STRING "" FORCE)
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${ARCH_FLAGS}" CACHE STRING "" FORCE)

set(OPENGL_LIBRARIES GLESv2)
set(ARMV7 ON)
set(USING_GLES2 ON)

set(ARM_NO_VULKAN ON)
set(USING_X11_VULKAN OFF CACHE BOOL "" FORCE)
