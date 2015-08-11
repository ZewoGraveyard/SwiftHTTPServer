//
//  FCGI.c
//  HTTP
//
//  Created by Paulo Faria on 8/11/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

#include "FCGI.h"

void dumpEnv() {

    for (char **env = environ; *env; ++env) {

        printf("%s\n", *env);

    }

}

int FCGI_printf0(const char *format) {

    return FCGI_printf(format);

}

size_t FCGI_fread0(void *ptr, size_t size) {

    return FCGI_fread(ptr, 1, size, stdin);

}

size_t FCGI_fwrite0(void *ptr, size_t size) {

    return FCGI_fwrite(ptr, size, 1, stdout);

}