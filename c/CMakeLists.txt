cmake_minimum_required(VERSION 3.10)

project(mobula C)

set(CMAKE_C_STANDARD 11)

find_package(OpenSSL REQUIRED)
add_executable(mobula main.c)

target_link_libraries(${PROJECT_NAME} OpenSSL::Crypto)
target_include_directories(${PROJECT_NAME} PRIVATE ${OPENSSL_INCLUDE_DIR})
