
#
# Find Arduino Core
#
#
# @author Natesh Narain
# @since Feb 03 2016

if (CMAKE_HOST_APPLE)
	if (NOT ARDUINO_SEARCH_ROOT)
		set(ARDUINO_SEARCH_ROOT $ENV{HOME})
	endif (NOT ARDUINO_SEARCH_ROOT)

	set(ARDUINO_REVISION_FILE ${ARDUINO_SEARCH_ROOT}/Arduino/build/shared/revisions.txt)
	if (NOT ARDUINO_REVISION_FILE)
		message(FATAL_ERROR "Arduino Core sources could not be found")
	endif (NOT ARDUINO_REVISION_FILE)
	file(READ ${ARDUINO_REVISION_FILE} VERSION_TEXT)
	string(REGEX MATCH "ARDUINO [0-9]?[0-9]\\.[0-9]?[0-9]\\.[0-9]?[0-9]" TMP ${VERSION_TEXT})
	string(REPLACE "ARDUINO " "" TMP ${TMP})
	string(REPLACE "." "" ARDUINO_VERSION_NUMBER ${TMP})

	string(REPLACE "/build/shared/revisions.txt" "" ARDUINO_ROOT ${ARDUINO_REVISION_FILE})

elseif (CMAKE_HOST_UNIX AND NOT CMAKE_HOST_APPLE)

	# Find Arduino version file
	file(GLOB ARDUINO_VERSION_FILES
			 /usr/share/arduino/lib/version.txt
			 /usr/share/arduino-*/lib/version.txt)

	if (NOT ARDUINO_VERSION_FILES)
		message(FATAL_ERROR "Arduino Core could not be found")
	endif (NOT ARDUINO_VERSION_FILES)

	set(ARDUINO_VERSION_NUMBER 0)
	set(ARDUINO_VERSION_TEXT "")
	set(ARDUINO_VERSION_FILE "")

	# determine the latest version available
	foreach (versionFile ${ARDUINO_VERSION_FILES})

		# get version number from the text file
		file(READ ${versionFile} VERSION_TEXT)

		# remove the dots to make it a number
		string(REPLACE "." "" VERSION_NUMBER ${VERSION_TEXT})

		if (${VERSION_NUMBER} GREATER ${ARDUINO_VERSION_NUMBER})

			set(ARDUINO_VERSION_NUMBER ${VERSION_NUMBER})
			set(ARDUINO_VERSION_TEXT ${VERSION_TEXT})
			set(ARDUINO_VERSION_FILE ${versionFile})

		endif (${VERSION_NUMBER} GREATER ${ARDUINO_VERSION_NUMBER})

	endforeach (versionFile)

	# get arduino root
	string(REPLACE "/lib//version.txt" "" ARDUINO_ROOT ${ARDUINO_VERSION_FILE})

endif (CMAKE_HOST_APPLE)

# arduino folder locations
set(ARDUINO_LIB_ROOT "${ARDUINO_ROOT}/libraries")
set(ARDUINO_AVR_ROOT "${ARDUINO_ROOT}/hardware/arduino/avr/")
set(ARDUINO_CORE "${ARDUINO_AVR_ROOT}cores/arduino/")
set(ARDUINO_VARIANT_ROOT "${ARDUINO_AVR_ROOT}variants/standard")

if (CMAKE_HOST_APPLE)
	set(ARDUINO_INCLUDE_DIR ${ARDUINO_CORE} ${ARDUINO_VARIANT_ROOT})
else (CMAKE_HOST_APPLE)
	set(ARDUINO_INCLUDE_DIR ${ARDUINO_CORE} ${ARDUINO_VARIANT_ROOT} "/usr/lib/avr/include")
endif (CMAKE_HOST_APPLE)

file(
		GLOB ARDUINO_CORE_SOURCES
		${ARDUINO_CORE}*.cpp
		${ARDUINO_CORE}*.c
		${ARDUINO_CORE}*.S)

list(REMOVE_ITEM ARDUINO_CORE_SOURCES "${ARDUINO_CORE}main.cpp")

# finished finding package requirements
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
		ARDUINO
		DEFAULT_MSG
		ARDUINO_ROOT
		ARDUINO_VERSION_NUMBER
		ARDUINO_LIB_ROOT
		ARDUINO_INCLUDE_DIR
		ARDUINO_CORE_SOURCES)
