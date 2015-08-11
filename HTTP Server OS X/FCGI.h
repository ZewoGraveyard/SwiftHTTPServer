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
void dumpEnv();
int FCGI_printf0(const char *format);
size_t FCGI_fread0(void *ptr, size_t size);
size_t FCGI_fwrite0(void *ptr, size_t size);

#endif /* FCGI_h */
