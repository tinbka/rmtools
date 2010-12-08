#ifndef __RUBY_INTERNALS_HH__
#define __RUBY_INTERNALS_HH__

#include <ruby.h>

#ifdef RUBY_IS_19

#include <ruby/intern.h>
#include <ruby/defines.h>
#include <ruby/re.h>
#include <assert.h>

# define ARY_EMBED_P(ary) \
    (assert(!FL_TEST(ary, ELTS_SHARED) || !FL_TEST(ary, RARRAY_EMBED_FLAG)), \
     FL_TEST(ary, RARRAY_EMBED_FLAG))
#define ARY_SET_EMBED_LEN(ary, n) do { \
    long tmp_n = n; \
    RBASIC(ary)->flags &= ~RARRAY_EMBED_LEN_MASK; \
    RBASIC(ary)->flags |= (tmp_n) << RARRAY_EMBED_LEN_SHIFT; \
} while (0)
#define ARY_SET_HEAP_LEN(ary, n) do { \
    RARRAY(ary)->as.heap.len = n; \
} while (0)
#define ARY_SET_LEN(ary, n) do { \
    if (ARY_EMBED_P(ary)) { \
        ARY_SET_EMBED_LEN(ary, n); \
    } \
    else { \
        ARY_SET_HEAP_LEN(ary, n); \
    } \
} while (0) 

#define BDIGITS(x) ((BDIGIT*)RBIGNUM_DIGITS(x))

// copied from utilrb gem
typedef struct RNode {
    unsigned long flags;
    char *nd_file;
    union {
	struct RNode *node;
	ID id;
	VALUE value;
	VALUE (*cfunc)(ANYARGS);
	ID *tbl;
    } u1;
    union {
	struct RNode *node;
	ID id;
	long argc;
	VALUE value;
    } u2;
    union {
	struct RNode *node;
	ID id;
	long state;
	struct global_entry *entry;
	long cnt;
	VALUE value;
    } u3;
} NODE;

typedef struct RVALUE {
    union {
	struct {
	    VALUE flags;		/* always 0 for freed obj */
	    struct RVALUE *next;
	} free;
	struct RBasic  basic;
	struct RObject object;
	struct RClass  klass;
	struct RFloat  flonum;
	struct RString string;
	struct RArray  array;
	struct RRegexp regexp;
	struct RHash   hash;
	struct RData   data;
	struct RStruct rstruct;
	struct RBignum bignum;
	struct RFile   file;
	struct RNode   node;
	struct RMatch  match;
	struct RRational rational;
	struct RComplex complex;
    } as;
} RVALUE;

static const size_t SLOT_SIZE = sizeof(RVALUE);

#else

#include <intern.h>
#include <node.h>
#include <env.h>
#include <re.h>

# define STR_SET_LEN(x, i) (RSTRING(x)->len = (i))
 
# define RFLOAT_VALUE(f) (RFLOAT(f)->value)
 
# define RBIGNUM_DIGITS(f) (RBIGNUM(f)->digits)
# define RBIGNUM_LEN(f) (RBIGNUM(f)->len)
 
# define ARY_SET_LEN(x, i) (RARRAY(x)->len = (i))

# define BDIGITS(x) ((BDIGIT*)RBIGNUM(x)->digits)

// copied from utilrb gem
typedef struct RVALUE {
    union {
        struct {
            unsigned long flags;        /* always 0 for freed obj */
            struct RVALUE *next;
        } free;
        struct RBasic  basic;
        struct RObject object;
        struct RClass  klass;
        struct RFloat  flonum;
        struct RString string;
        struct RArray  array;
        struct RRegexp regexp;
        struct RHash   hash;
        struct RData   data;
        struct RStruct rstruct;
        struct RBignum bignum;
        struct RFile   file;
        struct RNode   node;
        struct RMatch  match;
        struct RVarmap varmap;
        struct SCOPE   scope;
    } as;
#ifdef GC_DEBUG
    char *file;
    int   line;
#endif
} RVALUE;
static const size_t SLOT_SIZE = sizeof(RVALUE);


#endif // 1.9



// shortcuts for debug r_r
extern void rb_log_std(const char* str)
{
  rb_funcall(rb_gv_get("$log"), rb_intern("debug"), 1, rb_str_new2(str));
}
extern void rb_log_obj_std(VALUE obj)
{
  rb_funcall(rb_gv_get("$log"), rb_intern("debug"), 1, obj);
}
extern void rb_log_file(const char* str)
{
  rb_funcall(rb_gv_get("$log"), rb_intern("log"), 1, rb_str_new2(str));
}
extern void rb_log_file_obj(VALUE obj)
{
  rb_funcall(rb_gv_get("$log"), rb_intern("log"), 1, obj);
}

#endif