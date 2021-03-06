
#
# AVR GCC Toolchain file
#
# @author Natesh Narain
# @since Feb 06 2016

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_CROSS_COMPILING 1)

if (AVR_MCU)

	set(TRIPLE "avr")

	# predefined TOOLCHAIN_ROOT for using with arbitrary installed toolchain
	# set(TOOLCHAIN_ROOT "~/.platformio/packages/toolchain-atmelavr/bin")

	if (NOT TOOLCHAIN_ROOT)

		# find the toolchain root directory

		if (CMAKE_HOST_APPLE)

			# expect that osx-cross/avr-libc and tools is installed with homebrew
			set(OSS_SUFFIX "")
			find_path(TOOLCHAIN_ROOT
								NAMES
								${TRIPLE}-gcc${OS_SUFFIX}

								PATHS
								/usr/local/bin)

		elseif (CMAKE_HOST_UNIX AND NOT CMAKE_HOST_APPLE)

			set(OS_SUFFIX "")
			find_path(TOOLCHAIN_ROOT
								NAMES
								${TRIPLE}-gcc${OS_SUFFIX}

								PATHS
								/usr/bin/
								/usr/local/bin
								/bin/

								$ENV{AVR_ROOT})

		elseif (CMAKE_HOST_WIN32)

			set(OS_SUFFIX ".exe")
			find_path(TOOLCHAIN_ROOT
								NAMES
								${TRIPLE}-gcc${OS_SUFFIX}

								PATHS
								C:\\WinAVR\\bin
								$ENV{AVR_ROOT})

		else (APPLE AND UNIX)
			message(FATAL_ERROR "toolchain not supported on this OS")
		endif (APPLE AND UNIX)

	endif (NOT TOOLCHAIN_ROOT)

	if (NOT TOOLCHAIN_ROOT)
		message(FATAL_ERROR "Toolchain not found!")
	endif (NOT TOOLCHAIN_ROOT)

	# setup the AVR compiler variables

	set(CMAKE_C_COMPILER "${TOOLCHAIN_ROOT}/${TRIPLE}-gcc${OS_SUFFIX}" CACHE PATH "gcc" FORCE)
	set(CMAKE_CXX_COMPILER "${TOOLCHAIN_ROOT}/${TRIPLE}-g++${OS_SUFFIX}" CACHE PATH "g++" FORCE)
	set(CMAKE_AR "${TOOLCHAIN_ROOT}/${TRIPLE}-ar${OS_SUFFIX}" CACHE PATH "ar" FORCE)
	set(CMAKE_LINKER "${TOOLCHAIN_ROOT}/${TRIPLE}-ld${OS_SUFFIX}" CACHE PATH "linker" FORCE)
	set(CMAKE_NM "${TOOLCHAIN_ROOT}/${TRIPLE}-nm${OS_SUFFIX}" CACHE PATH "nm" FORCE)
	set(CMAKE_OBJCOPY "${TOOLCHAIN_ROOT}/${TRIPLE}-objcopy${OS_SUFFIX}" CACHE PATH "objcopy" FORCE)
	set(CMAKE_OBJDUMP "${TOOLCHAIN_ROOT}/${TRIPLE}-objdump${OS_SUFFIX}" CACHE PATH "objdump" FORCE)
	set(CMAKE_STRIP "${TOOLCHAIN_ROOT}/${TRIPLE}-strip${OS_SUFFIX}" CACHE PATH "strip" FORCE)
	set(CMAKE_RANLIB "${TOOLCHAIN_ROOT}/${TRIPLE}-ranlib${OS_SUFFIX}" CACHE PATH "ranlib" FORCE)
	set(AVR_SIZE "${TOOLCHAIN_ROOT}/${TRIPLE}-size${OS_SUFFIX}" CACHE PATH "size" FORCE)

	# avr uploader config
	find_program(AVR_UPLOAD
							 NAME
							 avrdude

							 PATHS
							 /usr/bin/
							 $ENV{AVR_ROOT})

	if (NOT AVR_UPLOAD_BUAD)
		if (CMAKE_HOST_APPLE)
			set(AVR_UPLOAD_BUAD 115200)
		else (CMAKE_HOST_APPLE)
			set(AVR_UPLOAD_BUAD 57600)
		endif (CMAKE_HOST_APPLE)
	endif (NOT AVR_UPLOAD_BUAD)

	if (NOT AVR_UPLOAD_PROGRAMMER)
		set(AVR_UPLOAD_PROGRAMMER "arduino")
	endif (NOT AVR_UPLOAD_PROGRAMMER)

	if (NOT AVR_UPLOAD_PORT)
		if (CMAKE_HOST_UNIX AND NOT CMAKE_HOST_APPLE)
			set(AVR_UPLOAD_PORT "/dev/ttyUSB0")
		elseif (CMAKE_HOST_APPLE AND CMAKE_HOST_UNIX)
			set(AVR_UPLOAD_PORT "/dev/cu.usbmodem1421")
		elseif (CMAKE_HOST_WIN32)
			set(AVR_UPLOAD_PORT "COM3")
		endif (CMAKE_HOST_UNIX AND NOT CMAKE_HOST_APPLE)
	endif (NOT AVR_UPLOAD_PORT)

	# simavr config
	find_program(SIMAVR
							 NAME
							 simavr

							 PATHS
							 /usr/bin/
							 $ENV{SIMAVR_HOME})

	if (NOT SIMAVR)
		message("-- Could not find simavr")
	else (NOT SIMAVR)
		message("-- Found simavr: ${SIMAVR}")
	endif (NOT SIMAVR)

	# setup the avr exectable macro
	if (NOT CMAKE_HOST_APPLE)
		# in case of osx-cross everything is built into compiler
		set(AVR_LIB_SEARCH_ARG "")
		set(AVR_LINKER_LIBS "")
	else (NOT CMAKE_HOST_APPLE)
		set(AVR_LIB_SEARCH_ARG "-L ${TOOLCHAIN_ROOT}/gcc/avr/${GCC_VERSION}")
		set(AVR_LINKER_LIBS "-lc -lm -lgcc")
	endif (NOT CMAKE_HOST_APPLE)

	macro(add_avr_executable target_name)

		set(elf_file ${target_name}-${AVR_MCU}.elf)
		set(map_file ${target_name}-${AVR_MCU}.map)
		set(hex_file ${target_name}-${AVR_MCU}.hex)
		set(lst_file ${target_name}-${AVR_MCU}.lst)

		# create elf file
		add_executable(${elf_file}
									 ${ARGN})

		set_target_properties(
				${elf_file}
				PROPERTIES
				C_EXTENTIONS True
				C_STANDARD 11
				CXX_EXTENTIONS True
				CXX_STANDARD 11
				LINK_FLAGS "-mmcu=${AVR_MCU} -Wl,-Map,${map_file} ${AVR_LIB_SEARCH_ARG} ${AVR_LINKER_LIBS}")

		target_compile_options(${elf_file} PUBLIC "-fno-fat-lto-objects;-O2;-Wall;-ffunction-sections;-fdata-sections;-flto;-mmcu=${AVR_MCU}")
		target_compile_options(${elf_file} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions -fno-threadsafe-statics -std=gnu++11>)
		target_compile_options(${elf_file} PUBLIC $<$<COMPILE_LANGUAGE:C>:-std=gnu11>)
		target_compile_options(${elf_file} PUBLIC $<$<CONFIG:Debug>:-g -Os>)
		target_compile_options(${elf_file} PUBLIC $<$<CONFIG:Release>:-O2>)
		target_include_directories(${elf_file} SYSTEM PUBLIC "${AVR_LIBC_ROOT}/include")
		# TODO: some definictions are taken from platformio projects and may be unnecessary
		add_definitions(-DF_CPU=16000000L -DARDUINO_ARCH_AVR -DARDUINO_AVR_UNO -DARDUINO=10612)

		# generate the lst file
		add_custom_command(
				OUTPUT ${lst_file}

				COMMAND
				${CMAKE_OBJDUMP} -h -S ${elf_file} > ${lst_file}

				DEPENDS ${elf_file})

		# create hex file
		add_custom_command(
				OUTPUT ${hex_file}

				COMMAND
				${CMAKE_OBJCOPY} -j .text -j .data -O ihex ${elf_file} ${hex_file}

				DEPENDS ${elf_file})

		add_custom_command(
				OUTPUT "print-size-${elf_file}"

				COMMAND
				${AVR_SIZE} ${elf_file}

				DEPENDS ${elf_file})

		# build the intel hex file for the device
		add_custom_target(
				${target_name}
				ALL
				DEPENDS ${hex_file} ${lst_file} "print-size-${elf_file}")

		set_target_properties(
				${target_name}

				PROPERTIES
				OUTPUT_NAME ${elf_file})

		# flash command
		add_custom_command(
				OUTPUT "flash-${hex_file}"

				COMMAND
				${AVR_UPLOAD} -b${AVR_UPLOAD_BUAD} -c${AVR_UPLOAD_PROGRAMMER} -p${AVR_MCU} -U flash:w:${hex_file} -P${AVR_UPLOAD_PORT})

		add_custom_target(
				"flash-${target_name}"

				DEPENDS "flash-${hex_file}")

		if (SIMAVR)
			# create sim avr targets
			add_custom_command(
					OUTPUT "sim-${elf_file}"

					COMMAND
					${SIMAVR} -m ${AVR_MCU} -f 16000000 ${elf_file})

			add_custom_target(
					"sim-${target_name}"

					DEPENDS "sim-${elf_file}")
		endif (SIMAVR)

	endmacro(add_avr_executable)

endif (AVR_MCU)
