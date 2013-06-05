#include "rmtools.h"

using namespace std;

/*
 * Assign new value by variable or constant address. Can't process numeric, nil, false and true. Though, it can process containers with all of that shit.
 *   a = 'Object.new'
 *   => "Object.new"
 *   def inspire x
 *       x.define! eval x
 *   end
 *   => nil
 *   inspire a
 *   => #<Object:0xb790bed0>
 *   a
 *   => #<Object:0xb790bed0>
 * It's quite buggy, you can get sudden segfault sometime after using method ^_^'\
 * Maybe it could mark used objects for GC not to collect  
 */
static VALUE object_define_new_value(VALUE self, VALUE new_obj)
{
    if (FIXNUM_P(self) || self == Qnil || self == Qfalse || self == Qtrue || self == Qundef) {
        VALUE tmp = rb_mod_name(rb_obj_class(self));
        const char* msg = StringValuePtr(tmp);
        rb_raise(rb_eTypeError, "can't redefine %s", msg);
    }
    if (FIXNUM_P(new_obj) || new_obj == Qnil || new_obj == Qfalse || new_obj == Qtrue  || new_obj == Qundef) {
        VALUE tmp = rb_mod_name(rb_obj_class(self));
        const char* msg = StringValuePtr(tmp);
        rb_raise(rb_eTypeError, "can't define object as %s", msg);
    }
    // Place the definition of the new object in the slot of self
    memcpy(reinterpret_cast<void*>(self), reinterpret_cast<void*>(rb_funcall(new_obj, rb_intern("clone"), 0)), SLOT_SIZE);
    return self;
}


/*
 *   puts ['123', '456', '789'].stranspose
 *   147
 *   258
 *   369
 */
static VALUE rb_ary_string_transpose(VALUE ary)
{
    long elen = -1, alen, i, j;
    VALUE tmp, result = 0;

    alen = RARRAY_LEN(ary);
    if (alen == 0) return rb_ary_dup(ary);
    for (i=0; i<alen; i++) {
        tmp = RARRAY_PTR(ary)[i];
        if (elen < 0) {                /* first element */
            elen = RSTRING_LEN(tmp);
            result = rb_ary_new2(elen);
            for (j=0; j<elen; j++) rb_ary_store(result, j, rb_str_new("", 0));
        }
        else if (elen != RSTRING_LEN(tmp))
            rb_raise(rb_eIndexError, "element size differs (%ld should be %ld)",
                     RARRAY_LEN(tmp), elen);
        for (j=0; j<elen; j++) rb_str_buf_cat(RARRAY_PTR(result)[j], &(RSTRING_PTR(tmp)[j]), 1);
    }
    return result;
}

/*
 *   puts ['123', '456', '789'].turn_ccw
 *   369
 *   258
 *   147
 */
static VALUE rb_ary_turn_ccw(VALUE ary)
{
  long elen, alen, i, j;
  VALUE tmp, result = 0;
  alen = RARRAY_LEN(ary);
  if (alen == 0) return rb_ary_dup(ary);
    
  tmp = RARRAY_PTR(ary)[0];
  if (TYPE(tmp) == T_STRING) {
    elen = RSTRING_LEN(tmp);
    result = rb_ary_new2(elen);
    for (j=0; j<elen; j++) rb_ary_store(result, j, rb_str_new("", 0));
    for (i=0; i<alen; i++) {
        if (i) tmp = RARRAY_PTR(ary)[i];
        if (elen != RSTRING_LEN(tmp))
            rb_raise(rb_eIndexError, "element size differs (%ld should be %ld)",
                     RARRAY_LEN(tmp), elen);
        for (j=0; j<elen; j++) rb_str_buf_cat(RARRAY_PTR(result)[j], &(RSTRING_PTR(tmp)[elen-1-j]), 1);
    }
  }
  else {
    elen = RARRAY_LEN(tmp);
    for (j=0; j<elen; j++) rb_ary_store(result, j, rb_ary_new2(alen));
    for (i=0; i<alen; i++) {
        if (i) tmp = RARRAY_PTR(ary)[i];
        if (elen != RARRAY_LEN(tmp))
            rb_raise(rb_eIndexError, "element size differs (%ld should be %ld)",
                     RARRAY_LEN(tmp), elen);
        for (j=0; j<elen; j++) rb_ary_store(RARRAY_PTR(result)[j], i, RARRAY_PTR(tmp)[elen-1-j]);
    }
  }
  
  return result;
}

/*
 *   puts ['123', '456', '789'].turn_cw
 *   147
 *   258
 *   369
 */
static VALUE rb_ary_turn_cw(VALUE ary)
{
  long elen, alen, i, j;
  VALUE tmp, result = 0;
  alen = RARRAY_LEN(ary);
  if (alen == 0) return rb_ary_dup(ary);
    
  tmp = RARRAY_PTR(ary)[0];
  if (TYPE(tmp) == T_STRING) {
    elen = RSTRING_LEN(tmp);
    result = rb_ary_new2(elen);
    for (j=0; j<elen; j++) rb_ary_store(result, j, rb_str_new("", 0));
    for (i=alen-1; i>-1; i--) {
        tmp = RARRAY_PTR(ary)[i];
        if (elen != RSTRING_LEN(tmp))
            rb_raise(rb_eIndexError, "element size differs (%ld should be %ld)",
                     RARRAY_LEN(tmp), elen);
        for (j=0; j<elen; j++) rb_str_buf_cat(RARRAY_PTR(result)[j], &(RSTRING_PTR(tmp)[j]), 1);
    }
  }
  else {
    elen = RARRAY_LEN(tmp);
    for (j=0; j<elen; j++) rb_ary_store(result, j, rb_ary_new2(alen));
    for (i=0; i<alen; i++) {
        if (i) tmp = RARRAY_PTR(ary)[i];
        if (elen != RARRAY_LEN(tmp))
            rb_raise(rb_eIndexError, "element size differs (%ld should be %ld)",
                     RARRAY_LEN(tmp), elen);
        for (j=0; j<elen; j++) rb_ary_store(RARRAY_PTR(result)[j], elen-1-i, RARRAY_PTR(tmp)[j]);
    }
  }
  
  return result;
}

/*
 *   "      @@@@@@".conj "   @@@   @@@"
 *   => "         @@@"
 */
static VALUE rb_str_disjunction(VALUE self, VALUE str)
{
  if (RSTRING_LEN(self) != RSTRING_LEN(str))
    rb_raise(rb_eIndexError, "strings sizes differs (%ld and %ld)",
                     RSTRING_LEN(self), RSTRING_LEN(str));
  VALUE new_str = rb_str_new("", 0);
  int i;
  const char *selfptr = RSTRING_PTR(self), *strptr = RSTRING_PTR(str);
  for (i=0;i<RSTRING_LEN(str);i++) {
    if (strptr[i] != ' ' || selfptr[i] != ' ')
      rb_str_buf_cat(new_str, "@", 1);
    else
      rb_str_buf_cat(new_str, " ", 1);
  }
  return new_str;
}

/*
 *   "      @@@@@@".disj "   @@@   @@@"
 *   => "   @@@@@@@@@"
 */
static VALUE rb_str_conjunction(VALUE self, VALUE str)
{
  if (RSTRING_LEN(self) != RSTRING_LEN(str))
    rb_raise(rb_eIndexError, "strings sizes differs (%ld and %ld)",
                     RSTRING_LEN(self), RSTRING_LEN(str));
  VALUE new_str = rb_str_new("", 0);
  int i;
  const char *selfptr = RSTRING_PTR(self), *strptr = RSTRING_PTR(str);
  for (i=0;i<RSTRING_LEN(str);i++) {
    if (strptr[i] == '@' && selfptr[i] == '@')
      rb_str_buf_cat(new_str, "@", 1);
    else
      rb_str_buf_cat(new_str, " ", 1);
  }
  return new_str;
}

/*
 *  Modifies array, throwing all elements not having unique block result 
 *  a = randarr 10
 *  => [8, 2, 0, 5, 4, 1, 7, 3, 9, 6]
 *  a.uniq_by! {|e| e%2}
 *  => [8, 5]
 *  a
 *  => [8, 5]
 * Here is implyied that callback block is +clean function+
 */
static VALUE rb_ary_uniq_by_bang(VALUE ary)
{
  long len = RARRAY_LEN(ary)
  if (len < 2)
      return Qnil;
  if (!rb_block_given_p())
      return rb_ary_new4(RARRAY_LEN(ary), RARRAY_PTR(ary));
  VALUE hash, res_hash, res, el;
  long i, j, len;

  hash = rb_hash_new();
  res_hash = rb_hash_new();
  for (i=j=0; i<len; i++) {
      // We store an element itself and so we won't calculate function of it 
      // other time we'll find it in source. Ruby store function is very fast, 
      // so we can neglect its runtime even if source array is allready uniq
      el = RARRAY_PTR(ary)[i];
      if (st_lookup(RHASH_TBL(hash), el, 0)) continue;
      res = rb_yield(el);
      if (st_lookup(RHASH_TBL(res_hash), res, 0)) continue;
      rb_hash_aset(hash, el, Qtrue);
      rb_hash_aset(res_hash, res, Qtrue);
      rb_ary_store(ary, j++, el);
  }
  ARY_SET_LEN(ary, j);
  
  return j == len ? Qnil : ary;
}

/*
 * Safe version of uniq_by!
 */
static VALUE rb_ary_uniq_by(VALUE ary)
{
  VALUE ary_dup = rb_ary_dup(ary);
  rb_ary_uniq_by_bang(ary_dup);
  return ary_dup;
}

/*
 *   Make hash with unique items of +self+ or (when block given)
 *   unique results of items yield for keys and 
 *   count of them in +self+, 
 *   or (with option :fill) arrays of yield results, 
 *   or (with option :indexes) arrays of indexes of them,
 *   or (with option :group) arrays of themselves for values
 *   
 *   [1, 2, 2, 2, 3, 3].arrange
 *   => {1=>1, 2=>3, 3=>2}
 *   [1, 2, 2, 2, 3, 3].arrange {|i| i%2}
 *   => {0=>3, 1=>3}
 *   [1, 2, 2, 2, 3, 3].arrange :fill
 *   => {1=>[1], 2=>[2, 2, 2], 3=>[3, 3]}
 *   [1, 2, 2, 2, 3, 3].arrange :indexes
 *   => {1=>[0], 2=>[1, 2, 3], 3=>[4, 5]}
 *   [1, 2, 2, 2, 3, 3].arrange(:indexes) {|i| i%2}
 *   => {0=>[1, 2, 3], 1=>[0, 4, 5]}
 *   :group is analogue to rails' group_by but twice faster
 *   [1, 2, 2, 2, 3, 3].arrange(:group) {|i| i%2}
 *   => {0=>[2, 2, 2], 1=>[1, 3, 3]}
 */
static VALUE rb_ary_count_items(int argc, VALUE *argv, VALUE ary)
{
  long i, alen, block_given;
  int fill, ind, group;
  VALUE key, arg, storage;
  VALUE hash = rb_hash_new();
  VALUE val = Qnil;
  
  block_given = rb_block_given_p();
  rb_scan_args(argc, argv, "01", &arg);
  ind = arg == ID2SYM(rb_intern("indexes"));
  group = arg == ID2SYM(rb_intern("group"));
  fill = ind || group || arg == ID2SYM(rb_intern("fill"));
  
  alen = RARRAY_LEN(ary);
  for (i=0; i<RARRAY_LEN(ary); i++) {
      key = block_given ? rb_yield(RARRAY_PTR(ary)[i]) : RARRAY_PTR(ary)[i];
      if (fill) 
      {
          if (st_lookup(RHASH_TBL(hash), key, 0))
              storage = rb_hash_aref(hash, key);
          else {
              storage = rb_ary_new2(alen);
              rb_hash_aset(hash, key, storage);
          }
          rb_ary_push(storage, ind ? LONG2FIX(i) : group ? RARRAY_PTR(ary)[i] : key);
      }
      else {
          if (st_lookup(RHASH_TBL(hash), key, &val))
              rb_hash_aset(hash, key, LONG2FIX(FIX2LONG(val) + 1));
          else
              rb_hash_aset(hash, key, INT2FIX(1));
      }
  }
  return hash;
}

/*
 *  call-seq:
 *     ary.partition {| obj | block }  => [ true_array, false_array ]
 *  
 *  Same as Enumerable#partition, but twice faster
 *     
 *     [5, 6, 1, 2, 4, 3].partition {|i| (i&1).zero?}   #=> [[2, 4, 6], [1, 3, 5]]
 *     
 */

static VALUE rb_ary_partition(VALUE ary)
{
  VALUE select, reject;
  long i, len;

  RETURN_ENUMERATOR(ary, 0, 0);
  len = RARRAY_LEN(ary);
  select = rb_ary_new2(len);
  reject = rb_ary_new2(len);
  for (i = 0; i < len; i++)
    rb_ary_push((RTEST(rb_yield(RARRAY_PTR(ary)[i])) ? select : reject), RARRAY_PTR(ary)[i]);
  
  return rb_assoc_new(select, reject);
}

// HASH

static int replace_keys_i(VALUE key, VALUE value, VALUE hash)
{
  if (key == Qundef) return ST_CONTINUE;
  rb_hash_delete(hash, key);
  rb_hash_aset(hash, rb_yield(key), value);
  return ST_CONTINUE;
}
static int map_keys_i(VALUE key, VALUE value, VALUE hash)
{
  if (key == Qundef) return ST_CONTINUE;
  rb_hash_aset(hash, rb_yield(key), value);
  return ST_CONTINUE;
}
static int map_values_i(VALUE key, VALUE value, VALUE hash)
{
  if (key == Qundef) return ST_CONTINUE;
  rb_hash_aset(hash, key, rb_yield(value));
  return ST_CONTINUE;
}
static int map_pairs_i(VALUE key, VALUE value, VALUE hash)
{
  if (key == Qundef) return ST_CONTINUE;
  rb_hash_aset(hash, key, rb_yield(rb_assoc_new(key, value)));
  return ST_CONTINUE;
}

/*
 *  Hashes map methods that doesn't make hash into array 
 *  New hash may get shorter than source
 */
static VALUE rb_hash_map_keys_bang(VALUE hash)
{
  rb_hash_foreach(hash, (int (*)(ANYARGS))replace_keys_i, hash);
  return hash;
}

/*
 *  Hashes map methods that doesn't make hash into array 
 */
static VALUE rb_hash_map_values_bang(VALUE hash)
{
  rb_hash_foreach(hash, (int (*)(ANYARGS))map_values_i, hash);
  return hash;
}

/*
 *  Hashes map methods that doesn't make hash into array 
 */
static VALUE rb_hash_map_pairs_bang(VALUE hash)
{
  rb_hash_foreach(hash, (int (*)(ANYARGS))map_pairs_i, hash);
  return hash;
}

/*
 *  Hashes map methods that doesn't make hash into array 
 */
static VALUE rb_hash_map_values(VALUE hash)
{
  VALUE new_hash = rb_hash_new();
  rb_hash_foreach(hash, (int (*)(ANYARGS))map_values_i, new_hash);
  return new_hash;
}

/*
 *  Hashes map methods that doesn't make hash into array 
 *  New hash may get shorter than source
 */
static VALUE rb_hash_map_keys(VALUE hash)
{
  VALUE new_hash = rb_hash_new();
  rb_hash_foreach(hash, (int (*)(ANYARGS))map_keys_i, new_hash);
  return new_hash;
}

/*
 *  Hashes map methods that doesn't make hash into array 
 */
static VALUE rb_hash_map_pairs(VALUE hash)
{
  VALUE new_hash = rb_hash_new();
  rb_hash_foreach(hash, (int (*)(ANYARGS))map_pairs_i, new_hash);
  return new_hash;
}

/*
 *  x! ( specially for /c/ ^__^ )
 *  5.fact # => 120
 *  x3 boost relative to 1.8.7
 */
static VALUE rb_math_factorial(VALUE x)
{
  long a = FIX2LONG(x);
  for (int i = 2; i < a; i++) 
    x = TYPE(x) == T_BIGNUM ? 
      rb_big_mul(x, rb_int2big(i)) : 
      rb_big_mul(rb_int2big(FIX2LONG(x)), rb_int2big(i));
  return x;
}

static int unsigned_big_lte(VALUE x, VALUE y)
{
  long xlen = RBIGNUM_LEN(x);
  long ylen = RBIGNUM_LEN(y);
  if (xlen < ylen) return 1;
  if (xlen > RBIGNUM_LEN(y)) return 0;
  while (xlen-- && (BDIGITS(x)[xlen]==BDIGITS(y)[xlen])) {};
  if (-1 == xlen) return 1; // ==
  return (BDIGITS(x)[xlen] > BDIGITS(y)[xlen]) ? 0 : 1;
}
/*
 *  timer(100000) {1073741823.factorize} 
 *  => "res: [3, 3, 7, 11, 31, 151, 331], one: 0.0053ms, total: 530.0ms"
 *  ruby count Bignums starting from 2**30
 *  < 2**30: x1-x30 speed, >= 2**30: x1 - x3 speed ~_~
 *  Caution! It can just hung up on numbers over 2**64 and you'll have to kill it -9
 *  And this shit doesn't think if you have 64-bit system, so it could be faster a bit
 */
static VALUE rb_math_factorization(VALUE x) {
  VALUE factors = rb_ary_new2(31);
  int len = 0;
  long y = FIX2LONG(x);
  long n = 2;
  while (n*n <= y) {
      if (y%n == 0) {
          y /= n;
          rb_ary_store(factors, len++, LONG2FIX(n));
      } else
          n++;
  }
  rb_ary_store(factors, len++, LONG2FIX(y));
  ARY_SET_LEN(factors, len);
  return factors;
}
/*
 *  timer(100000) {1073741823.factorize} 
 *  => "res: [3, 3, 7, 11, 31, 151, 331], one: 0.0053ms, total: 530.0ms"
 *  ruby count Bignums starting from 2**30
 *  < 2**30: x1-x30 speed, >= 2**30: x1 - x3 speed ~_~
 *  Caution! It can just hung up on numbers over 2**64 and you'll have to kill it -9
 *  And this shit doesn't think if you have 64-bit system, so it could be faster a bit
 */
static VALUE rb_math_big_factorization(VALUE y) {
  VALUE factors = rb_ary_new2(127);
  int len = 0;
  long n = 2;
  int cont = 0;
  VALUE big_n, divmod, mod;
  while (unsigned_big_lte(rb_int2big(n*n), y)) {
      divmod = rb_big_divmod(y, rb_int2big(n));
      mod = RARRAY_PTR(divmod)[1];
  
      if (FIXNUM_P(mod) && !FIX2LONG(mod)) {
          y = RARRAY_PTR(divmod)[0];
          if (FIXNUM_P(y)) y = rb_int2big(FIX2LONG(y));
          rb_ary_store(factors, len++, LONG2FIX(n));
      } else {
          n++;
          if (n == 46341) {
            big_n = rb_int2big(n);
            cont = 1;
            break;
          }
      }
  }
  if (cont)
    while (unsigned_big_lte(rb_big_mul(big_n, big_n), y)) {
      divmod = rb_big_divmod(y, big_n);
      mod = RARRAY_PTR(divmod)[1];
    
      if (FIXNUM_P(mod) && !FIX2LONG(mod)) {
          y = RARRAY_PTR(divmod)[0];
          if (FIXNUM_P(y)) y = rb_int2big(FIX2LONG(y));
          rb_ary_store(factors, len++, big_n);
      } else {
        big_n = (n < LONG_MAX) ? rb_int2big(++n) : rb_big_plus(big_n, rb_int2big(1));
      }
    }
  rb_ary_store(factors, len++, y);
  ARY_SET_LEN(factors, len);
  return factors;
}


/*
static VALUE rb_eval_frame(VALUE self, VALUE src, VALUE levv)
{
  struct FRAME *frame_orig = ruby_frame;
  NODE *node_orig = ruby_current_node;
  VALUE val;
  int i = 0, lev = FIX2INT(levv);
 
  while (lev-- > 0) {
	    ruby_frame = ruby_frame->prev;
	    if (!ruby_frame) break;
	}
  
  val = rb_funcall(self, rb_intern("eval"), 1, src);
  ruby_current_node = node_orig;
  ruby_frame = frame_orig;
 
  return val;
}
*/
extern "C" void Init_rmtools()
{
  //  rb_define_method(rb_mKernel, "eval_frame", RUBY_METHOD_FUNC(rb_eval_frame), 2);

    rb_define_method(rb_cFixnum, "fact", RUBY_METHOD_FUNC(rb_math_factorial), 0);
    rb_define_method(rb_cFixnum, "factorize", RUBY_METHOD_FUNC(rb_math_factorization), 0);
    rb_define_method(rb_cBignum, "factorize", RUBY_METHOD_FUNC(rb_math_big_factorization), 0);
  
    rb_define_method(rb_cHash, "map_keys", RUBY_METHOD_FUNC(rb_hash_map_keys), 0);
    rb_define_method(rb_cHash, "map_values", RUBY_METHOD_FUNC(rb_hash_map_values), 0);
    rb_define_method(rb_cHash, "map2", RUBY_METHOD_FUNC(rb_hash_map_pairs), 0);
    rb_define_method(rb_cHash, "map_keys!", RUBY_METHOD_FUNC(rb_hash_map_keys_bang), 0);
    rb_define_method(rb_cHash, "map_values!", RUBY_METHOD_FUNC(rb_hash_map_values_bang), 0);
    rb_define_method(rb_cHash, "map!", RUBY_METHOD_FUNC(rb_hash_map_pairs_bang), 0);
  
    rb_define_method(rb_cArray, "uniq_by", RUBY_METHOD_FUNC(rb_ary_uniq_by), 0);
    rb_define_method(rb_cArray, "uniq_by!", RUBY_METHOD_FUNC(rb_ary_uniq_by_bang), 0);
  
    rb_define_method(rb_cArray, "arrange", RUBY_METHOD_FUNC(rb_ary_count_items), -1);

    rb_define_method(rb_cArray, "partition", RUBY_METHOD_FUNC(rb_ary_partition), 0);
    
    rb_define_method(rb_cArray, "stranspose", RUBY_METHOD_FUNC(rb_ary_string_transpose), 0);
    rb_define_method(rb_cArray, "turn_cw", RUBY_METHOD_FUNC(rb_ary_turn_cw), 0);
    rb_define_method(rb_cArray, "turn_ccw", RUBY_METHOD_FUNC(rb_ary_turn_ccw), 0);
    
    rb_define_method(rb_cString, "conj", RUBY_METHOD_FUNC(rb_str_conjunction), 1);
    rb_define_method(rb_cString, "disj", RUBY_METHOD_FUNC(rb_str_disjunction), 1);
  
    rb_define_method(rb_cObject, "define!", RUBY_METHOD_FUNC(object_define_new_value), 1);
}

