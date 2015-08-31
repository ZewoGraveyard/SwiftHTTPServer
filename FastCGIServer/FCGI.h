//
//  FCGI.h
//  HTTP
//
//  Created by Paulo Faria on 8/11/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

#ifndef FCGI_h
#define FCGI_h

#include <fcgi_stdio.h>

extern char **environ;
int FCGI_writeString(const char *string);
size_t FCGI_readBuffer(void *buffer, size_t size);
size_t FCGI_writeBuffer(void *buffer, size_t size);

#endif /* FCGI_h */
