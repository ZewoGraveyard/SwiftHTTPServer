//
//  uri_wrapper.h
//  HTTP
//
//  Created by Paulo Faria on 8/2/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

#ifndef uri_wrapper_c
#define uri_wrapper_c

#include <stdio.h>
#include "Uri.h"

struct uri_info {
    char *scheme;
    char *userInfo;
    char *host;
    char *port;
    char *path;
    UriQueryListA *queryList;
    char *fragment;
};

struct uri_info* get_uri_info(const char *text);
void free_uri_info(struct uri_info*);

#endif /* uri_wrapper_c */
