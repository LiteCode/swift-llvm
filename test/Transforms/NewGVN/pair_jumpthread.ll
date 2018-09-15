; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -newgvn -S | FileCheck %s
; RUN: opt < %s -newgvn -jump-threading -S | FileCheck --check-prefix=CHECK-JT %s
; This test is expected to fail until the transformation is committed.
; XFAIL: *

define signext i32 @testBI(i32 signext %v) {
; Test with std::pair<bool, int>
; based on the following C++ code
; std::pair<bool, int> callee(int v) {
;   int a = dummy(v);
;   if (a) return std::make_pair(true, dummy(a));
;   else return std::make_pair(v < 0, v);
; }
; int func(int v) {
;   std::pair<bool, int> rc = callee(v);
;   if (rc.first) dummy(0);
;   return rc.second;
; }
; CHECK-LABEL: @testBI(
; CHECK:  _ZL6calleei.exit:
; CHECK:    [[PHIOFOPS:%.*]] = phi i64 [ 1, %if.then.i ], [ {{%.*}}, %if.else.i ]
; CHECK:    [[TOBOOL:%.*]] = icmp eq i64 [[PHIOFOPS]], 0
;
; CHECK-JT-LABEL: @testBI(
; CHECK-JT:       _ZL6calleei.exit.thread:
;

entry:
  %call.i = call signext i32 @dummy(i32 signext %v)
  %tobool.i = icmp eq i32 %call.i, 0
  br i1 %tobool.i, label %if.else.i, label %if.then.i

if.then.i:                                        ; preds = %entry
  %call2.i = call signext i32 @dummy(i32 signext %call.i)
  %retval.sroa.22.0.insert.ext.i.i = zext i32 %call2.i to i64
  %retval.sroa.22.0.insert.shift.i.i = shl nuw i64 %retval.sroa.22.0.insert.ext.i.i, 32
  %retval.sroa.0.0.insert.insert.i.i = or i64 %retval.sroa.22.0.insert.shift.i.i, 1
  br label %_ZL6calleei.exit

if.else.i:                                        ; preds = %entry
  %.lobit.i = lshr i32 %v, 31
  %0 = zext i32 %.lobit.i to i64
  %retval.sroa.22.0.insert.ext.i8.i = zext i32 %v to i64
  %retval.sroa.22.0.insert.shift.i9.i = shl nuw i64 %retval.sroa.22.0.insert.ext.i8.i, 32
  %retval.sroa.0.0.insert.insert.i11.i = or i64 %retval.sroa.22.0.insert.shift.i9.i, %0
  br label %_ZL6calleei.exit

_ZL6calleei.exit:                                 ; preds = %if.then.i, %if.else.i
  %retval.sroa.0.0.i = phi i64 [ %retval.sroa.0.0.insert.insert.i.i, %if.then.i ], [ %retval.sroa.0.0.insert.insert.i11.i, %if.else.i ]
  %rc.sroa.43.0.extract.shift = lshr i64 %retval.sroa.0.0.i, 32
  %rc.sroa.43.0.extract.trunc = trunc i64 %rc.sroa.43.0.extract.shift to i32
  %1 = and i64 %retval.sroa.0.0.i, 1
  %tobool = icmp eq i64 %1, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %_ZL6calleei.exit
  %call1 = call signext i32 @dummy(i32 signext 0)
  br label %if.end

if.end:                                           ; preds = %_ZL6calleei.exit, %if.then
  ret i32 %rc.sroa.43.0.extract.trunc
}


define signext i32 @testIB(i32 signext %v) {
; Test with std::pair<int, bool>
; based on the following C++ code
; std::pair<int, bool> callee(int v) {
;   int a = dummy(v);
;   if (a) return std::make_pair(dummy(v), true);
;   else return std::make_pair(v, v < 0);
; }
; int func(int v) {
;   std::pair<int, bool> rc = callee(v);
;   if (rc.second) dummy(0);
;   return rc.first;
; }
; CHECK-LABEL: @testIB(
; CHECK:  _ZL6calleei.exit:
; CHECK:     [[PHIOFOPS:%.*]] = phi i64 [ 4294967296, %if.then.i ], [ {{%.*}}, %if.else.i ]
; CHECK:     [[TOBOOL:%.*]] = icmp eq i64 [[PHIOFOPS]], 0
;
; CHECK-JT-LABEL: @testIB(
; CHECK-JT:       _ZL6calleei.exit.thread:
;

entry:
  %call.i = call signext i32 @dummy(i32 signext %v)
  %tobool.i = icmp eq i32 %call.i, 0
  br i1 %tobool.i, label %if.else.i, label %if.then.i

if.then.i:                                        ; preds = %entry
  %call1.i = call signext i32 @dummy(i32 signext %v)
  %retval.sroa.0.0.insert.ext.i.i = zext i32 %call1.i to i64
  %retval.sroa.0.0.insert.insert.i.i = or i64 %retval.sroa.0.0.insert.ext.i.i, 4294967296
  br label %_ZL6calleei.exit

if.else.i:                                        ; preds = %entry
  %.lobit.i = lshr i32 %v, 31
  %0 = zext i32 %.lobit.i to i64
  %retval.sroa.2.0.insert.shift.i8.i = shl nuw nsw i64 %0, 32
  %retval.sroa.0.0.insert.ext.i9.i = zext i32 %v to i64
  %retval.sroa.0.0.insert.insert.i10.i = or i64 %retval.sroa.2.0.insert.shift.i8.i, %retval.sroa.0.0.insert.ext.i9.i
  br label %_ZL6calleei.exit

_ZL6calleei.exit:                                 ; preds = %if.then.i, %if.else.i
  %retval.sroa.0.0.i = phi i64 [ %retval.sroa.0.0.insert.insert.i.i, %if.then.i ], [ %retval.sroa.0.0.insert.insert.i10.i, %if.else.i ]
  %rc.sroa.0.0.extract.trunc = trunc i64 %retval.sroa.0.0.i to i32
  %1 = and i64 %retval.sroa.0.0.i, 4294967296
  %tobool = icmp eq i64 %1, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %_ZL6calleei.exit
  %call1 = call signext i32 @dummy(i32 signext 0)
  br label %if.end

if.end:                                           ; preds = %_ZL6calleei.exit, %if.then
  ret i32 %rc.sroa.0.0.extract.trunc
}

declare signext i32 @dummy(i32 signext %v)
