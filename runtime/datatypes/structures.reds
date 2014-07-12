Red/System [
	Title:   "Alias definitions for datatype structures"
	Author:  "Nenad Rakocevic"
	File: 	 %structures.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
	Note: {
		Putting all aliases in this file for early inclusion in %red.reds solves
		cross-referencing issues in datatypes definitions.
	}
]

#define red-value!	cell!

red-datatype!: alias struct! [
	header 	[integer!]								;-- cell header
	value	[integer!]								;-- datatype ID
	_pad2	[integer!]
	_pad3	[integer!]
]

red-unset!: alias struct! [
	header 	[integer!]								;-- cell header only, no payload
	_pad1	[integer!]
	_pad2	[integer!]
	_pad3	[integer!]
]

red-none!: alias struct! [
	header 	[integer!]								;-- cell header only, no payload
	_pad1	[integer!]
	_pad2	[integer!]
	_pad3	[integer!]
]

red-logic!: alias struct! [
	header 	[integer!]								;-- cell header
	value	[logic!]								;-- 1: TRUE, 0: FALSE
	_pad1	[integer!]
	_pad2	[integer!]
]

red-series!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- series's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-block!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- block's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-paren!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- paren's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-path!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- path's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-lit-path!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- path's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-set-path!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- path's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-get-path!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- path's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-string!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- string's head index (zero-based)
	node	[node!]									;-- series node pointer
	cache	[c-string!]								;-- UTF-8 cached version of the string (experimental)
]

red-file!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- string's head index (zero-based)
	node	[node!]									;-- series node pointer
	cache	[c-string!]								;-- UTF-8 cached version of the string (experimental)
]

red-url!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- string's head index (zero-based)
	node	[node!]									;-- series node pointer
	cache	[c-string!]								;-- UTF-8 cached version of the string (experimental)
]

red-binary!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- string's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-bitset!: alias struct! [
	header 	[integer!]								;-- cell header
	_pad1	[integer!]
	node	[node!]									;-- series node pointer
	_pad2	[integer!]
]

red-symbol!: alias struct! [
	header 	[integer!]								;-- cell header
	alias	[integer!]								;-- Alias symbol index
	node	[node!]									;-- string series node pointer
	cache	[c-string!]								;-- UTF-8 cached version of the string (experimental)
]

red-integer!: alias struct! [
	header 	[integer!]								;-- cell header
	padding	[integer!]								;-- align value on 64-bit boundary
	value	[integer!]								;-- 32-bit signed integer value
	_pad	[integer!]	
]

red-context!: alias struct! [
	header 	[integer!]								;-- cell header
	symbols	[node!]									;-- array of symbols ID
	values	[node!]									;-- block of values (do not move this field!)
	self	[node!]									;-- indirect auto-reference (optimization)
]

red-object!: alias struct! [
	header 	[integer!]								;-- cell header
	ctx		[node!]									;-- context reference
	_pad1	[integer!]
	_pad2	[integer!]
]

red-word!: alias struct! [
	header 	[integer!]								;-- cell header
	ctx		[node!]									;-- context reference
	symbol	[integer!]								;-- index in symbol table
	index	[integer!]								;-- index in context
]

red-refinement!: alias struct! [
	header 	[integer!]								;-- cell header
	ctx		[node!]									;-- context reference
	symbol	[integer!]								;-- index in symbol table
	index	[integer!]								;-- index in context
]

red-char!: alias struct! [
	header 	[integer!]								;-- cell header
	_pad1	[integer!]
	value	[integer!]								;-- UCS-4 codepoint
	_pad2	[integer!]	
]

red-point!: alias struct! [
	header 	[integer!]								;-- cell header
	x		[integer!]								;-- stores an integer! or float32! value
	y		[integer!]								;-- stores an integer! or float32! value
	z		[integer!]								;-- stores an integer! or float32! value
]

red-action!: alias struct! [
	header 	[integer!]								;-- cell header
	symbols	[node!]									;-- action cleaned-up spec block reference
	spec	[node!]									;-- action spec block reference
	code	[integer!]								;-- native code function pointer
]

red-native!: alias struct! [
	header 	[integer!]								;-- cell header
	symbols	[node!]									;-- native cleaned-up spec block reference
	spec	[node!]									;-- native spec block reference
	code	[integer!]								;-- native code function pointer
]

red-op!: alias struct! [
	header 	[integer!]								;-- cell header
	symbols	[node!]									;-- op cleaned-up spec block reference
	spec	[node!]									;-- op spec block reference
	code	[integer!]								;-- native code function pointer
]

red-function!: alias struct! [
	header 	[integer!]								;-- cell header
	ctx		[node!]									;-- function's context
	spec	[node!]									;-- native spec block buffer reference
	more	[node!]									;-- additional members storage block:
	;	body	 [red-block!]						;-- 	function's body block
	;	symbols	 [red-block!]						;-- 	native cleaned-up spec block reference
	;	native   [node!]							;-- 	JIT-compiled body (binary!)
	;   fun		 [red-function!]					;--		(optional) copy of parent function! value (used by op!)
]

red-routine!: alias struct! [
	header 	[integer!]								;-- cell header
	symbols	[node!]									;-- routine cleaned-up spec block reference
	spec	[node!]									;-- routine spec block buffer reference	
	more	[node!]									;-- additional members storage block:
	;	body	 [red-block!]						;-- 	routine's body block
	;	symbols	 [red-block!]						;-- 	routine cleaned-up spec block reference
	;	native   [node!]							;-- 	compiled body (binary!)
]

red-float!: alias struct! [
	header 	[integer!]								;-- cell header
	padding [integer!]
	value	[float!]								;-- 64-bit float value
]

red-float32!: alias struct! [
	header 	[integer!]								;-- cell header
	padding [integer!]
	value	[float32!]								;-- 32-bit float value
	_pad	[integer!]
]
