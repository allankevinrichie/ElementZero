macro (generate_git_version _out_var)
    find_package (Git QUIET)
    if (GIT_FOUND)
        execute_process (
            COMMAND ${GIT_EXECUTABLE} describe --abbrev=6 --always --tags
            OUTPUT_VARIABLE ${_out_var}
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
        if (${_out_var} STREQUAL "")
            set (${_out_var} "unknown")
        endif ()
    endif ()
endmacro ()

function (find_and_install_package name)
    find_package (${name} ${ARGN})
    get_target_property (dll_files ${name} IMPORTED_LOCATION_RELEASE)
    install (FILES ${dll_files} DESTINATION .)
endfunction ()

function (install_pdb name)
    install (FILES $<TARGET_PDB_FILE:${name}> DESTINATION Lib)
endfunction ()

function (def_mod name)
    cmake_parse_arguments(ARG "BASEMOD" "" "LINK;DELAY_LINK" ${ARGN})
    file (GLOB_RECURSE srcs
        CONFIGURE_DEPENDS *.cpp)
    set (IS_BASEMOD $<BOOL:${ARG_BASEMOD}>)
    add_library (${name} SHARED ${srcs})
    target_compile_definitions (${name}
        PRIVATE MODNAME=${name} $<${IS_BASEMOD}:EZVERSION=\"${git_version}\">)
    target_link_libraries (${name}
        Boost::headers
        yaml-cpp
        ModLoader
        BedrockServer
        $<$<NOT:${IS_BASEMOD}>:Base>
        ${ARG_LINK}
        ${ARG_DELAY_LINK})
    install (TARGETS ${name}
        RUNTIME DESTINATION Mods
        ARCHIVE DESTINATION Lib)
    install_pdb (${name})
    set_target_properties (${name}
        PROPERTIES FOLDER $<IF:${IS_BASEMOD},Base,Mods>)
    if (ARG_DELAY_LINK)
        target_link_libraries (${name} delayimp)
        foreach (target ${ARGN})
            target_link_options (${name} PRIVATE /DELAYLOAD:${target}.dll)
        endforeach ()
    endif ()
endfunction ()