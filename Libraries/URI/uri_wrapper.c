//
//  uri_wrapper.c
//  HTTP
//
//  Created by Paulo Faria on 8/2/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

#include "uri_wrapper.h"

void copy_uri_element(char **element, const char *first, const char *afterLast) {

    if (first != NULL && afterLast != NULL) {

        *element = (char *) malloc((afterLast - first + 1) * sizeof(char));
        strncpy(*element, first, afterLast - first);
        (*element)[afterLast - first] = '\0';

    }

}

void copy_uri_element_from_text_range(char **element, struct UriTextRangeStructA textRange) {

    copy_uri_element(element, textRange.first, textRange.afterLast);

}

struct uri_info* get_uri_info(const char *text) {

    UriParserStateA state;
    UriUriA uri;
    struct uri_info *uri_info = (struct uri_info *) malloc(sizeof(struct uri_info));
    memset(uri_info, 0, sizeof(struct uri_info));

    if (strcmp(text, "/") == 0) {

        uri_info->path = (char *) malloc(1 * sizeof(char));
        strcpy(uri_info->path, "");
        return uri_info;

    }

    state.uri = &uri;

    if (uriParseUriA(&state, text) != URI_SUCCESS) {

        uriFreeUriMembersA(&uri);
        free(uri_info);
        return NULL;

    }

    copy_uri_element_from_text_range(&uri_info->scheme, uri.scheme);
    copy_uri_element_from_text_range(&uri_info->userInfo, uri.userInfo);
    copy_uri_element_from_text_range(&uri_info->host, uri.hostText);
    copy_uri_element_from_text_range(&uri_info->port, uri.portText);

    if (uri.pathHead != NULL && uri.pathTail != NULL) {

        copy_uri_element(&uri_info->path, uri.pathHead->text.first, uri.pathTail->text.afterLast);

    }

    copy_uri_element_from_text_range(&uri_info->fragment, uri.fragment);

    if (uriDissectQueryMallocA(&uri_info->queryList, NULL, uri.query.first, uri.query.afterLast) != URI_SUCCESS) {

        uriFreeQueryListA(uri_info->queryList);

    }

    uriFreeUriMembersA(&uri);

    return uri_info;
    
}

void free_uri_info(struct uri_info *uri_info) {

    free(uri_info->scheme);
    free(uri_info->userInfo);
    free(uri_info->host);
    free(uri_info->port);

    if (uri_info->path != NULL) {

        free(uri_info->path);

    }

    uriFreeQueryListA(uri_info->queryList);
    free(uri_info->fragment);
    free(uri_info);

}