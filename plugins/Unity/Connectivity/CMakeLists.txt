set(CONNECTIVITY_SOURCES
    plugin.cpp
    Connectivity.cpp
)

add_library(Connectivity MODULE ${CONNECTIVITY_SOURCES})

target_link_libraries(Connectivity Qt5::Qml Qt5::DBus Qt5::Core)

add_unity8_plugin(Unity.Connectivity 0.1 Unity/Connectivity TARGETS Connectivity)
