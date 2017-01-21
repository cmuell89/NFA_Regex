cimport libc.stdlib
cimport libc.stdio
cimport libc.string
cimport posix.unistd

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
        static char[8000]
        int nalt
        int natom
        char* dst
        re2post_anon paren[100]
        p* re2post_anon

    p = paren
    dst = buf
    dst_idx = 0
    nalt = 0
    natom = 0
    if(len(re) >= (sizeof(buf)/2)):
        return None
    for chrctr in re:
        if chrctr == '(':
            if natom > 1:
                natom = natom - 1
                """ *dst++ = '.'; CORRECT?"""
                dst[0] = '.'
                dst[0] = dst[0] + 1
            if(p >= (paren+100)):
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
            while(--natom > 0):
                dst[0] = '.'
                dst[0] = dst[0] + 1
            nalt += nalt
            break
        elif chrctr == ')':
            if p == paren:
                return None
            if natom == 0:
                return None
            while(--natom):
                dst[0] = '.'
                dst[0] = dst[0] + 1
            while(nalt > 0):
                dst[0] = '|'
                dst[0] = dst[0] + 1
                nalt -= nalt
            --p
            nalt = p.nalt
            natom = p.natom
            natom += natom
            break
        elif chrctr == '?':
            if natom == 0
                return None
            dst[0] = chrctr
            dst[0] = dst[0] + 1
        else:
            if natom > 1:
                --natom
                dst[0] = '.'
                dst[0] = dst[0] + 1
            dst[0] = chrctr
            dst[0] = dst[0] + 1
            natom += natom
            break
    if p != paren
        return None
    while(--natom > 0):
        dst[0] = '.'
        dst[0] = dst[0] + 1
    while(nalt > 0):
        dst[0] = '|'
        dst[0] = dst[0] + 1
    dst[0] = 0
    return buf





