//
//  FCGI.c
//  HTTP
//
//  Created by Paulo Faria on 8/11/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

#include "FCGI.h"

int FCGI_writeString(const char *string) {

    return FCGI_printf(string);

}

size_t FCGI_readBuffer(void *buffer, size_t size) {

    return FCGI_fread(buffer, 1, size, stdin);

}

size_t FCGI_writeBuffer(void *buffer, size_t size) {

    return FCGI_fwrite(buffer, size, 1, stdout);

}