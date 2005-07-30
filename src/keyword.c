/*
 * keyword.c - keyword implementation
 *
 *   Copyright (c) 2000-2004 Shiro Kawai, All rights reserved.
 * 
 *   Redistribution and use in source and binary forms, with or without
 *   modification, are permitted provided that the following conditions
 *   are met:
 * 
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   3. Neither the name of the authors nor the names of its contributors
 *      may be used to endorse or promote products derived from this
 *      software without specific prior written permission.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  $Id: keyword.c,v 1.16 2005-07-30 23:39:50 shirok Exp $
 */

#define LIBGAUCHE_BODY
#include "gauche.h"

/*
 * Keywords
 */

static void keyword_print(ScmObj obj, ScmPort *port, ScmWriteContext *ctx)
{
    if (SCM_WRITE_MODE(ctx) != SCM_WRITE_DISPLAY) {
        SCM_PUTC(':', port);
    }
    SCM_PUTS(SCM_KEYWORD(obj)->name, port);
    return;
}

SCM_DEFINE_BUILTIN_CLASS_SIMPLE(Scm_KeywordClass, keyword_print);

/* Global keyword table. */
static struct {
    ScmHashTable *table;
    ScmInternalMutex mutex;
} keywords = { NULL };

/* Returns a keyword whose name is NAME.  Note that preceding ':' is not
 * a part of the keyword name.
 */
ScmObj Scm_MakeKeyword(ScmString *name)
{
    ScmHashEntry *e;
    ScmObj r;

    (void)SCM_INTERNAL_MUTEX_LOCK(keywords.mutex);
    e = Scm_HashTableGet(keywords.table, SCM_OBJ(name));
    if (e) r = e->value;
    else {
        ScmKeyword *k = SCM_NEW(ScmKeyword);
        SCM_SET_CLASS(k, SCM_CLASS_KEYWORD);
        k->name = SCM_STRING(Scm_CopyString(name));
        Scm_HashTablePut(keywords.table, SCM_OBJ(name), SCM_OBJ(k));
        r = SCM_OBJ(k);
    }
    (void)SCM_INTERNAL_MUTEX_UNLOCK(keywords.mutex);
    return r;
}

ScmObj Scm_GetKeyword(ScmObj key, ScmObj list, ScmObj fallback)
{
    ScmObj cp;
    SCM_FOR_EACH(cp, list) {
        if (!SCM_PAIRP(SCM_CDR(cp))) {
            Scm_Error("incomplete key list: %S", list);
        }
        if (key == SCM_CAR(cp)) return SCM_CADR(cp);
        cp = SCM_CDR(cp);
    }
    if (SCM_UNBOUNDP(fallback)) {
        Scm_Error("value for key %S is not provided: %S", key, list);
    }
    return fallback;
}

ScmObj Scm_DeleteKeyword(ScmObj key, ScmObj list)
{
    ScmObj cp;
    SCM_FOR_EACH(cp, list) {
        if (!SCM_PAIRP(SCM_CDR(cp))) {
            Scm_Error("incomplete key list: %S", list);
        }
        if (key == SCM_CAR(cp)) {
            /* found */
            ScmObj h = SCM_NIL, t = SCM_NIL;
            ScmObj tail = Scm_DeleteKeyword(key, SCM_CDR(SCM_CDR(cp)));
            ScmObj cp2;
            SCM_FOR_EACH(cp2, list) {
                if (cp2 == cp) {
                    SCM_APPEND(h, t, tail);
                    return h;
                } else {
                    SCM_APPEND1(h, t, SCM_CAR(cp2));
                }
            }
        }
        cp = SCM_CDR(cp);
    }
    return list;
}

ScmObj Scm_DeleteKeywordX(ScmObj key, ScmObj list)
{
    ScmObj cp, prev = SCM_FALSE;
    SCM_FOR_EACH(cp, list) {
        if (!SCM_PAIRP(SCM_CDR(cp))) {
            Scm_Error("incomplete key list: %S", list);
        }
        if (key == SCM_CAR(cp)) {
            /* found */
            if (SCM_FALSEP(prev)) {
                /* we're at the head of list */
                return Scm_DeleteKeywordX(key, SCM_CDR(SCM_CDR(cp)));
            } else {
                ScmObj tail = Scm_DeleteKeywordX(key, SCM_CDR(SCM_CDR(cp)));
                SCM_SET_CDR(prev, tail);
                return list;
            }
        }
        cp = SCM_CDR(cp);
        prev = cp;
    }
    return list;
}

void Scm__InitKeyword(void)
{
    (void)SCM_INTERNAL_MUTEX_INIT(keywords.mutex);
    keywords.table = SCM_HASH_TABLE(Scm_MakeHashTableSimple(SCM_HASH_STRING, 256));
}
