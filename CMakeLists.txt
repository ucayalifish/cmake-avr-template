
cmake_minimum_required(VERSION 3.0)

set(AVR_MCU "atmega328p")

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/cmake/avr-gcc.toolchain.cmake")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

project(myproject C CXX ASM)

if(COMMAND add_avr_executable)
	# debugging output
	message(STATUS "AVR toolchain configured")
	message(STATUS "Toolchain root: ${TOOLCHAIN_ROOT}")
	message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
	message(STATUS "C compiler ID: ${CMAKE_C_COMPILER_ID}")
	message(STATUS "C compiler version: ${CMAKE_C_COMPILER_VERSION}")
	message(STATUS "Assembler: ${CMAKE_ASM_COMPILER}")
	message(STATUS "Assembler ID: ${CMAKE_ASM_COMPILER_ID}")
	message(STATUS "Assembler version: ${CMAKE_ASM_COMPILER_VERSION}")
else()
	message(FATAL_ERROR "Failed to configure AVR toolchain")
endif()

add_avr_executable(
	${PROJECT_NAME}

	test/main.cpp
)
