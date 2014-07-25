#include "rmtools.h"

using namespace std;

// shortcuts for debug r_r
extern void rb_log(const char* str)
{
  rb_funcall(rb_gv_get("$log"), rb_intern("debug"), 1, rb_str_new2(str));
}
extern void rb_log_obj(VALUE obj)
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

/****** NUMERIC ******/

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
 *  timer(1000000) {1073741823.factorize} # 2**30-1 : the biggest Fixnum on x86 arch
 *  res: [3, 3, 7, 11, 31, 151, 331]
 *  one: 0.0031ms, total: 3091.0ms
 *  timer {4611686018427387903.factorize} # 2**62-1 : the biggest Fixnum on amd64 arch
 *  res: [3, 715827883, 2147483647]
 *  one: 8422.0000ms, total: 8422.0ms
 *
 *  Fixnum: x1-x30 speed, Bignum: x1 - x3 speed ~_~
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
  rb_ary_set_len(factors, len);
  return factors;
}
/*
 *  From Ruby 2+ it is broken due to missed headers/defines. 
 *  I'm not sure if want to find a fix right now.
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
  rb_ary_set_len(factors, len);
  return factors;
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



/****** HASH ******/

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
static int replace_pairs_i(VALUE key, VALUE value, VALUE hash)
{
  if (key == Qundef) return ST_CONTINUE;
  VALUE kv = rb_yield(rb_assoc_new(key, value));
  rb_hash_aset(hash, RARRAY_PTR(kv)[0], RARRAY_PTR(kv)[1]);
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
 *  Calls |value|, modifies values only 
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
 *  Calls |key|, modifies keys only
 */
static VALUE rb_hash_map_keys(VALUE hash)
{
  VALUE new_hash = rb_hash_new();
  rb_hash_foreach(hash, (int (*)(ANYARGS))map_keys_i, new_hash);
  return new_hash;
}

/*
 *  Hashes map methods that doesn't make hash into array
 *  Calls |key, value|, modifies values only
 */
static VALUE rb_hash_map_pairs(VALUE hash)
{
  VALUE new_hash = rb_hash_new();
  rb_hash_foreach(hash, (int (*)(ANYARGS))map_pairs_i, new_hash);
  return new_hash;
}

/*
 *  Hashes map methods that doesn't make hash into array
 *  Calls |key, value|, modifies {key => value} pairs based on 2-items tuple result
 *  a = randarr(100); h = Hash[a.div(2)];
 *  timer(1000) {Hash[a.map {|i| [i, i%10]}]}
 *  one: *1.4690ms*, total: 1469.0ms
 *  timer(1000) {Hash[h.map {|k, v| [k, v%10]}]}
 *  one: *1.4910ms*, total: 1491.0ms
 *  timer(10000) {a.map_hash {|i| [i, i%10]}}
 *  one: *0.0578ms*, total: 578.0ms
 *  timer(10000) {h.map_hash {|k, v| [k, v%10]}}
 *  one: *0.0356ms*, total: 356.0ms
 */
static VALUE rb_hash_map_hash(VALUE hash)
{
  VALUE new_hash = rb_hash_new();
  rb_hash_foreach(hash, (int (*)(ANYARGS))replace_pairs_i, new_hash);
  return new_hash;
}



/****** ARRAY ******/

/*
 *   Make hash with unique items of +self+ or (when block given)
 *   unique results of items yield for keys and 
 *   count of them in +self+, 
 *   or (with option :indices) arrays of indexes of them,
 *   or (with option :group) arrays of themselves for values
 *   
 *   [1, 2, 2, 2, 3, 3].arrange
 *   => {1=>1, 2=>3, 3=>2}
 *   [1, 2, 2, 2, 3, 3].arrange {|i| i%2}
 *   => {0=>3, 1=>3}
 *   [1, 2, 2, 2, 3, 3].arrange :indices
 *   => {1=>[0], 2=>[1, 2, 3], 3=>[4, 5]}
 *   [1, 2, 2, 2, 3, 3].arrange(:indices) {|i| i%2}
 *   => {0=>[1, 2, 3], 1=>[0, 4, 5]}
 *
 *   :group is analogue to rails' group_by but twice faster
 *   (OBSOLETE: in Ruby 2+ native implementation of Array#group is 10 times faster)
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
  ind = arg == ID2SYM(rb_intern("indices"));
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

static VALUE rb_ary_map_hash(VALUE ary)
{
  VALUE kv, hash;
  long i, len;

  hash = rb_hash_new();
  RETURN_ENUMERATOR(ary, 0, 0);
  len = RARRAY_LEN(ary);
  for (i = 0; i < len; i++) {
    kv = rb_yield(RARRAY_PTR(ary)[i]);
    rb_hash_aset(hash, RARRAY_PTR(kv)[0], RARRAY_PTR(kv)[1]);
  }
  
  return hash;
}

/*
 *  call-seq:
 *     ary.map_hash {| obj | block }  => {block-result[0] => block-result[1]}
 *  
 *    (1...10).map_hash {|i| [i, i%2]} # => {1=>1, 2=>0, 3=>1, 4=>0, 5=>1, 6=>0, 7=>1, 8=>0, 9=>1}
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

extern VALUE mRMTools = rb_define_module("RMTools");
extern VALUE mRMToolsC = rb_define_module_under(mRMTools, "C");

extern "C" void Init_rmtools()
{
  RMTOOLSEXTEND(rb_cFixnum, FixnumExtension);
  rb_define_method(FixnumExtension, "fact", RUBY_METHOD_FUNC(rb_math_factorial), 0);
  rb_define_method(FixnumExtension, "factorize", RUBY_METHOD_FUNC(rb_math_factorization), 0);
  //RMTOOLSDEFMOD(rb_cBignum, BignumExtension);
  //rb_define_method(BignumExtension, "factorize", RUBY_METHOD_FUNC(rb_math_big_factorization), 0);

  RMTOOLSEXTEND(rb_cHash, HashExtension);
  rb_define_method(HashExtension, "map_keys", RUBY_METHOD_FUNC(rb_hash_map_keys), 0);
  rb_define_method(HashExtension, "map_values", RUBY_METHOD_FUNC(rb_hash_map_values), 0);
  rb_define_method(HashExtension, "map_hash", RUBY_METHOD_FUNC(rb_hash_map_hash), 0);
  rb_define_method(HashExtension, "map2", RUBY_METHOD_FUNC(rb_hash_map_pairs), 0);
  rb_define_method(HashExtension, "map_keys!", RUBY_METHOD_FUNC(rb_hash_map_keys_bang), 0);
  rb_define_method(HashExtension, "map_values!", RUBY_METHOD_FUNC(rb_hash_map_values_bang), 0);
  rb_define_method(HashExtension, "map!", RUBY_METHOD_FUNC(rb_hash_map_pairs_bang), 0);

  RMTOOLSEXTEND(rb_cArray, ArrayExtension);
  rb_define_method(ArrayExtension, "arrange", RUBY_METHOD_FUNC(rb_ary_count_items), -1);
  rb_define_method(ArrayExtension, "partition", RUBY_METHOD_FUNC(rb_ary_partition), 0);
  rb_define_method(ArrayExtension, "map_hash", RUBY_METHOD_FUNC(rb_ary_map_hash), 0);
}

