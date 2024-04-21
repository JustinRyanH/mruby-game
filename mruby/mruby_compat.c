/* Copyright (c) 2022 Dante Catalfamo */
/* SPDX-License-Identifier: MIT */

#include <mruby.h>
#include <mruby/array.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/error.h>
#include <mruby/range.h>
#include <mruby/value.h>

/*
 *  mruby.h
 */

extern struct RObject *mrb_c_state_get_exc(mrb_state *mrb) { return mrb->exc; }
extern void mrb_state_set_exc(mrb_state *mrb, struct RObject *exc) {
  mrb->exc = exc;
}
extern struct RObject *mrb_c_state_get_top_self(mrb_state *mrb) {
  return mrb->top_self;
}
extern struct RClass *mrb_c_state_get_object_class(mrb_state *mrb) {
  return mrb->object_class;
}
extern struct RClass *mrb_c_state_get_class_class(mrb_state *mrb) {
  return mrb->class_class;
}
extern struct RClass *mrb_c_state_get_module_class(mrb_state *mrb) {
  return mrb->module_class;
}
extern struct RClass *mrb_c_state_get_proc_class(mrb_state *mrb) {
  return mrb->proc_class;
}
extern struct RClass *mrb_c_state_get_string_class(mrb_state *mrb) {
  return mrb->string_class;
}
extern struct RClass *mrb_c_state_get_array_class(mrb_state *mrb) {
  return mrb->array_class;
}
extern struct RClass *mrb_c_state_get_hash_class(mrb_state *mrb) {
  return mrb->hash_class;
}
extern struct RClass *mrb_c_state_get_range_class(mrb_state *mrb) {
  return mrb->range_class;
}
extern struct RClass *mrb_c_state_get_float_class(mrb_state *mrb) {
  return mrb->float_class;
}
extern struct RClass *mrb_c_state_get_integer_class(mrb_state *mrb) {
  return mrb->integer_class;
}
extern struct RClass *mrb_c_state_get_true_class(mrb_state *mrb) {
  return mrb->true_class;
}
extern struct RClass *mrb_c_state_get_false_class(mrb_state *mrb) {
  return mrb->false_class;
}
extern struct RClass *mrb_c_state_get_nil_class(mrb_state *mrb) {
  return mrb->nil_class;
}
extern struct RClass *mrb_c_state_get_symbol_class(mrb_state *mrb) {
  return mrb->symbol_class;
}

extern void *mrb_c_state_alloc_ud(mrb_state *mrb) { return mrb->allocf_ud; }
extern struct RClass *mrb_c_state_get_kernel_module(mrb_state *mrb) {
  return mrb->kernel_module;
}
extern struct mrb_context *mrb_c_state_get_context(mrb_state *mrb) {
  return mrb->c;
}
extern struct mrb_context *mrb_c_state_get_root_context(mrb_state *mrb) {
  return mrb->root_c;
}

extern struct RClass *mrb_c_state_get_exception_class(struct mrb_state *mrb) {
  return E_EXCEPTION;
}

extern struct RClass *
mrb_c_state_get_std_exception_class(struct mrb_state *mrb) {
  return E_STANDARD_ERROR;
}

extern struct mrb_context *mrb_c_context_prev(struct mrb_context *cxt) {
  return cxt->prev;
}
extern mrb_callinfo *mrb_c_context_callinfo(struct mrb_context *cxt) {
  return cxt->ci;
}
extern enum mrb_fiber_state mrb_c_context_fiber_state(struct mrb_context *cxt) {
  return cxt->status;
}
extern struct RFiber *mrb_c_context_fiber(struct mrb_context *cxt) {
  return cxt->fib;
}

extern int mrb_c_gc_arena_save(struct mrb_state *mrb) {
  return mrb->gc.arena_idx;
}
extern void mrb_c_gc_arena_restore(struct mrb_state *mrb, int idx) {
  mrb->gc.arena_idx = idx;
}

extern mrb_aspec mrb_c_args_req(uint32_t n) { return MRB_ARGS_REQ(n); }
extern mrb_aspec mrb_c_args_opt(uint32_t n) { return MRB_ARGS_REQ(n); }
extern mrb_aspec mrb_c_args_rest() { return MRB_ARGS_REST(); }
extern mrb_aspec mrb_c_args_block() { return MRB_ARGS_BLOCK(); }
extern mrb_aspec mrb_c_args_key(uint32_t nk, uint32_t kd) {
  return MRB_ARGS_KEY(nk, kd);
}
extern mrb_aspec mrb_c_args_none() { return MRB_ARGS_NONE(); }

//
//  mruby/data.h
//

void mrb_c_data_init(mrb_value v, void *ptr, const mrb_data_type *type) {
  mrb_data_init(v, ptr, type);
}
void *mrb_c_rdata_data(struct RData data) { return data.data; }
const struct mrb_data_type *mrb_c_rdata_type(struct RData data) {
  return data.type;
}

//
//  mruby/value h
//

mrb_value mrb_c_float_value(struct mrb_state *mrb, mrb_float f) {
  return mrb_float_value(mrb, f);
}
mrb_value mrb_c_cptr_value(struct mrb_state *mrb, void *p) {
  return mrb_cptr_value(mrb, p);
}
mrb_value mrb_c_int_value(struct mrb_state *mrb, mrb_int i) {
  return mrb_int_value(mrb, i);
}
mrb_value mrb_c_fixnum_value(mrb_int i) { return mrb_fixnum_value(i); }
mrb_value mrb_c_symbol_value(mrb_sym i) { return mrb_symbol_value(i); }
mrb_value mrb_c_obj_value(void *p) { return mrb_obj_value(p); }
mrb_value mrb_c_nil_value(void) { return mrb_nil_value(); }
mrb_value mrb_c_false_value(void) { return mrb_false_value(); }
mrb_value mrb_c_true_value(void) { return mrb_true_value(); }
mrb_value mrb_c_bool_value(mrb_bool boolean) { return mrb_bool_value(boolean); }
mrb_value mrb_c_undef_value(void) { return mrb_undef_value(); }

mrb_bool mrb_c_immediate_p(mrb_value v) { return mrb_immediate_p(v); }
mrb_bool mrb_c_integer_p(mrb_value v) { return mrb_integer_p(v); }
mrb_bool mrb_c_fixnum_p(mrb_value v) { return mrb_fixnum_p(v); }
mrb_bool mrb_c_symbol_p(mrb_value v) { return mrb_symbol_p(v); }
mrb_bool mrb_c_undef_p(mrb_value v) { return mrb_undef_p(v); }
mrb_bool mrb_c_nil_p(mrb_value v) { return mrb_nil_p(v); }
mrb_bool mrb_c_false_p(mrb_value v) { return mrb_false_p(v); }
mrb_bool mrb_c_true_p(mrb_value v) { return mrb_true_p(v); }
mrb_bool mrb_c_float_p(mrb_value v) { return mrb_float_p(v); }
mrb_bool mrb_c_array_p(mrb_value v) { return mrb_array_p(v); }
mrb_bool mrb_c_string_p(mrb_value v) { return mrb_string_p(v); }
mrb_bool mrb_c_hash_p(mrb_value v) { return mrb_hash_p(v); }
mrb_bool mrb_c_cptr_p(mrb_value v) { return mrb_cptr_p(v); }
mrb_bool mrb_c_exception_p(mrb_value v) { return mrb_exception_p(v); }
mrb_bool mrb_c_free_p(mrb_value v) { return mrb_free_p(v); }
mrb_bool mrb_c_object_p(mrb_value v) { return mrb_object_p(v); }
mrb_bool mrb_c_class_p(mrb_value v) { return mrb_class_p(v); }
mrb_bool mrb_c_module_p(mrb_value v) { return mrb_module_p(v); }
mrb_bool mrb_c_iclass_p(mrb_value v) { return mrb_iclass_p(v); }
mrb_bool mrb_c_sclass_p(mrb_value v) { return mrb_sclass_p(v); }
mrb_bool mrb_c_proc_p(mrb_value v) { return mrb_proc_p(v); }
mrb_bool mrb_c_range_p(mrb_value v) { return mrb_range_p(v); }
mrb_bool mrb_c_env_p(mrb_value v) { return mrb_env_p(v); }
mrb_bool mrb_c_data_p(mrb_value v) { return mrb_data_p(v); }
mrb_bool mrb_c_fiber_p(mrb_value v) { return mrb_fiber_p(v); }
mrb_bool mrb_c_istruct_p(mrb_value v) { return mrb_istruct_p(v); }
mrb_bool mrb_c_break_p(mrb_value v) { return mrb_break_p(v); }

//
//  mruby/gc.h
//
size_t mrb_c_gc_get_live(struct mrb_state *mrb) { return mrb->gc.live; }
size_t mrb_c_gc_get_live_after_mark(struct mrb_state *mrb) {
  return mrb->gc.live_after_mark;
}

mrb_gc_state mrb_c_gc_get_state(struct mrb_state *mrb) { return mrb->gc.state; }
void mrb_c_gc_mark_value(struct mrb_state *mrb, mrb_value value) {
  mrb_gc_mark_value(mrb, value);
}

size_t mrb_c_gc_get_threshold(struct mrb_state *mrb) {
  return mrb->gc.threshold;
}

extern void mrb_c_set_data_type(struct RClass *cls, enum mrb_vtype tt) {
  MRB_SET_INSTANCE_TT(cls, tt);
}

extern mrb_sym mrb_c_get_mid(struct mrb_state *mrb) { return mrb_get_mid(mrb); }

//
// mruby/range.h
//

extern mrb_value mrb_c_range_beg(struct RRange* r) {
  return r->beg;
}

extern mrb_value mrb_c_range_end(struct RRange* r) {
  return r->end;
}

extern mrb_bool mrb_c_range_excl(struct RRange* r) {
  return r->excl;
}
