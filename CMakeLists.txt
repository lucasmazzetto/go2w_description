cmake_minimum_required(VERSION 3.8)
project(go2w_description NONE)

find_package(ament_cmake REQUIRED)

install(DIRECTORY config dae launch rviz urdf
  DESTINATION share/${PROJECT_NAME}
)

install(FILES LICENSE README.md
  DESTINATION share/${PROJECT_NAME}
)
if(BUILD_TESTING)
  find_package(ament_cmake_pytest REQUIRED)
  ament_add_pytest_test(appearance test/test_appearance.py
    ENV "GO2W_DESCRIPTION_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}"
  )
endif()

ament_package()
