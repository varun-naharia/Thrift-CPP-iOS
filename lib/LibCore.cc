#include "LibCore.hh"
#include <openssl/opensslv.h> // Include OpenSSL version header

void LibCore::print_hello_world() {
    std::cout << "Hello, World!" << std::endl;
}

void LibCore::print_openssl_version() {
    std::cout << "OpenSSL version: " << OPENSSL_VERSION_TEXT << std::endl;
}