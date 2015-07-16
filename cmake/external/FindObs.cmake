# This module can be copied and used by external plugins for OBS
#
# Once done these will be defined:
#
#  LIBOBS_FOUND
#  LIBOBS_INCLUDE_DIRS
#  LIBOBS_LIBRARIES
#
# For use in OBS:
#
#  OBS_INCLUDE_DIR

find_package(PkgConfig QUIET)
if (PKG_CONFIG_FOUND)
	pkg_check_modules(_OBS QUIET obs)
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(_lib_suffix 64)
else()
	set(_lib_suffix 32)
endif()

if(DEFINED CMAKE_BUILD_TYPE)
	if(CMAKE_BUILD_TYPE STREQUAL "Debug")
		set(_build_type_base "debug")
	else()
		set(_build_type_base "release")
	endif()
endif()

find_path(OBS_INCLUDE_DIR
	NAMES obs.h
	HINTS
		ENV obsPath${_lib_suffix}
		ENV obsPath
		${obsPath}
	PATHS
		/usr/include /usr/local/include /opt/local/include /sw/include
	PATH_SUFFIXES
		libobs
	)

function(find_obs_lib base_name repo_build_path lib_name)
	string(TOUPPER "${base_name}" base_name_u)

	if(DEFINED _build_type_base)
		set(_build_type_${repo_build_path} "${_build_type_base}/${repo_build_path}")
		set(_build_type_${repo_build_path}${_lib_suffix} "${_build_type_base}${_lib_suffix}/${repo_build_path}")
	endif()

	find_library(${base_name_u}_LIB
		NAMES ${_${base_name_u}_LIBRARIES} ${lib_name} lib${lib_name}
		HINTS
			ENV obsPath${_lib_suffix}
			ENV obsPath
			${obsPath}
			${_${base_name_u}_LIBRARY_DIRS}
		PATHS
			/usr/lib /usr/local/lib /opt/local/lib /sw/lib
		PATH_SUFFIXES
			lib${_lib_suffix} lib
			libs${_lib_suffix} libs
			bin${_lib_suffix} bin
			../lib${_lib_suffix} ../lib
			../libs${_lib_suffix} ../libs
			../bin${_lib_suffix} ../bin
			# base repo non-msvc-specific search paths
			${_build_type_${repo_build_path}}
			${_build_type_${repo_build_path}${_lib_suffix}}
			build/${repo_build_path}
			build${_lib_suffix}/${repo_build_path}
			# base repo msvc-specific search paths on windows
			build${_lib_suffix}/${repo_build_path}/Debug
			build${_lib_suffix}/${repo_build_path}/RelWithDebInfo
			build/${repo_build_path}/Debug
			build/${repo_build_path}/RelWithDebInfo
		)
endfunction()

find_obs_lib(OBS libobs obs)

if(MSVC)
	find_obs_lib(W32_PTHREADS deps/w32-pthreads w32-pthreads)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libobs DEFAULT_MSG OBS_LIB OBS_INCLUDE_DIR)
mark_as_advanced(OBS_INCLUDE_DIR OBS_LIB)

if(LIBOBS_FOUND)
	if(MSVC)
		if (NOT DEFINED W32_PTHREADS_LIB)
			message(FATAL_ERROR "Could not find the w32-pthreads library" )
		endif()

		set(W32_PTHREADS_INCLUDE_DIR ${OBS_INCLUDE_DIR}/../deps/w32-pthreads)
	endif()

	set(LIBOBS_INCLUDE_DIRS ${OBS_INCLUDE_DIR} ${W32_PTHREADS_INCLUDE_DIR})
	set(LIBOBS_LIBRARIES ${OBS_LIB} ${W32_PTHREADS_LIB})
	include(${OBS_INCLUDE_DIR}/../cmake/external/ObsPluginHelpers.cmake)
else()
	message(FATAL_ERROR "Could not find the libobs library" )
endif()
