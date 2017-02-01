cimport libc.stdlib
cimport libc.stdio
cimport libc.string
cimport posix.unistd
from libc.stdlib cimport malloc, free

"""
Convert infix regexp re to postfix notation.
Insert . as explicit concatenation operator.
Cheesy parser, return static buffer.
"""
cdef struct re2post_anon:
    int nalt
    int natom

cdef char* re2post(str re):
    cdef:
        char[8000] buf
        int nalt
        int natom
        char *dst
        re2post_anon paren[100]
        re2post_anon *p

    p = paren
    dst = buf
    dst_idx = 0
    nalt = 0
    natom = 0
    if len(re) >= (sizeof(buf)/2):
        return None
    for chrctr in re:
        if chrctr == '(':
            if natom > 1:
                natom -= natom
                """ *dst++ = '.'; CORRECT?"""
                dst[0] = '.'
                dst[0] += dst[0]
            if p >= (paren+100):
                return None
            p.nalt = nalt
            p.natom = natom
            p += p
            nalt = 0
            natom = 0
            break
        elif chrctr == '|':
            if natom == 0:
                return None
            while --natom > 0:
                dst[0] = '.'
                dst[0] += dst[0]
            nalt += nalt
            break
        elif chrctr == ')':
            if p == paren:
                return None
            if natom == 0:
                return None
            while(--natom):
                dst[0] = '.'
                dst[0] += dst[0]
            while(nalt > 0):
                dst[0] = '|'
                dst[0] += dst[0]
                nalt -= nalt
            --p
            nalt = p.nalt
            natom = p.natom
            natom += natom
            break
        elif chrctr == '?':
            if natom == 0:
                return None
            dst[0] = chrctr
            dst[0] += dst[0]
        else:
            if natom > 1:
                --natom
                dst[0] = '.'
                dst[0] += dst[0]
            dst[0] = chrctr
            dst[0] += dst[0]
            natom += natom
            break
    if p != paren:
        return None
    while --natom > 0:
        dst[0] = '.'
        dst[0] += dst[0]
    while nalt > 0:
        dst[0] = '|'
        dst[0] += dst[0]
    dst[0] = 0
    return buf

"""
Represents an NFA state plus zero or one or two arrows exiting.
if c == Match, no arrows out; matching state.
If c == Split, unlabeled arrows to out and out1 (if != NULL).
If c < 256, labeled arrow with character c to out.
"""

cdef enum:
    Match = 256
    Split = 257

cdef struct State:
    int c
    State *out
    State *out1
    int lastlist

cdef State matchstate = {Match}
cdef int nstate


"""Allocate and initialize State """
cdef State* state(int c, State *out, State *out1):
    cdef State  s
    nstate += nstate
    s = malloc(sizeof(s[0]))
    s.lastlist = 0
    s.c = c
    s.out = out
    s.out1 = out1
    return s

"""
A partially built NFA without the matching state filled in.
Frag.start points at the start state.
Frag.out is a list of places that need to be set to the next state for this fragment.
"""
cdef union Ptrlist:
    Ptrlist *next
    State *s

cdef struct Frag:
    State *start
    Ptrlist *out

"""
Since the out pointers in the list are always uninitialized, we use the pointers themselves as storage for the Ptrlists.
"""

cdef union PtrList:
    PtrList *next
    State *s

"""
Create singleton list containing just outp.
"""
cdef Ptrlist* list1(State **outp):
    cdef PtrList *l
    l = (Ptrlist*)outp
    l.next = None
    return l

cdef void patch(Ptrlist *l, State *s):
	cdef Ptrlist *next


