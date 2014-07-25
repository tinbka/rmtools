#include <ruby.h>

#include <ruby/intern.h>
#include <ruby/defines.h>
#include <ruby/re.h>
#include <assert.h>

#define ARY_EMBED_P(ary) \
    (assert(!FL_TEST(ary, ELTS_SHARED) || !FL_TEST(ary, RARRAY_EMBED_FLAG)), \
     FL_TEST(ary, RARRAY_EMBED_FLAG))
#define ARY_SET_EMBED_LEN(ary, n) \
    long tmp_n = n; \
    RBASIC(ary)->flags &= ~RARRAY_EMBED_LEN_MASK; \
    RBASIC(ary)->flags |= (tmp_n) << RARRAY_EMBED_LEN_SHIFT;
#define ARY_SET_HEAP_LEN(ary, n) \
    RARRAY(ary)->as.heap.len = n;
#define rb_ary_set_len(ary, n) \
    if (ARY_EMBED_P(ary)) {ARY_SET_EMBED_LEN(ary, n);} \
    else {ARY_SET_HEAP_LEN(ary, n);}

#ifdef RBIGNUM_DIGITS
# define BDIGITS(x) ((BDIGIT*)RBIGNUM_DIGITS(x))
#else
# define BDIGITS(x) ((BDIGIT*)RBIGNUM(x)->digits)
#endif

#define RMTOOLSEXTEND(rbc, modname) \
    VALUE modname = rb_define_module_under(mRMToolsC, #modname); \
    rb_include_module(rbc, modname);