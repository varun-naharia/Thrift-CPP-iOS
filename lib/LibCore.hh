
#ifndef LIBCORE_HH
#define LIBCORE_HH

#include <iostream>
#include <openssl/opensslv.h> // Include OpenSSL version header


class LibCore {
public:
    void print_hello_world();
    void print_openssl_version(); // New function declaration

};

#endif // LIBCORE_HH