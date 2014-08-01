Red/System [
	Title:   "Logic! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %logic.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

true-value:  declare red-logic!							;-- preallocate TRUE value
false-value: declare red-logic!							;-- preallocate FALSE value

logic: context [
	verbose: 0
	
	get: func [											;-- unboxing integer value
		value	 [red-value!]
		return:  [logic!]
		/local
			cell [red-logic!]
	][
		assert TYPE_OF(value) = TYPE_LOGIC
		cell: as red-logic! value
		cell/value
	]
	
	box: func [
		value	[logic!]
		return: [red-logic!]
		/local
			cell [red-logic!]
	][
		cell: as red-logic! stack/arguments
		cell/header: TYPE_LOGIC
		cell/value: value
		cell
	]
	
	top-true?: func [
		return:  [logic!]
	][
		not top-false?										;-- true if not none or false
	]

	top-false?: func [
		return:  [logic!]
		/local
			arg	 [red-logic!]
			type [integer!]
	][
		arg: as red-logic! stack/top - 1
		type: TYPE_OF(arg)

		any [											;-- true if not none or false
			type = TYPE_NONE
			all [type = TYPE_LOGIC not arg/value]
		]
	]
		
	true?: func [
		return:  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/true?"]]
		
		not false?										;-- true if not none or false
	]
	
	false?: func [
		return:  [logic!]
		/local
			arg	 [red-logic!]
			type [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/false?"]]
		
		arg: as red-logic! stack/arguments
		type: TYPE_OF(arg)
		
		any [											;-- true if not none or false
			type = TYPE_NONE
			all [type = TYPE_LOGIC not arg/value]
		]
	]
	
	push: func [
		value 	 [logic!]
		return:	 [red-logic!]
		/local
			cell [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/push"]]

		cell: as red-logic! stack/push*
		cell/header: TYPE_LOGIC							;-- implicit reset of all header flags
		cell/value: value
		cell
	]
	
	;-- Actions -- 

	make: func [
		proto	 [red-value!]	
		spec	 [red-value!]
		return:	 [red-logic!]							;-- return cell pointer
		/local
			bool  [red-logic!]
			int	  [red-integer!]
			value [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/make"]]

		value: switch TYPE_OF(spec) [
			TYPE_NONE  [no]
			TYPE_LOGIC [
				bool: as red-logic! spec
				bool/value
			]
			TYPE_INTEGER [
				int: as red-integer! spec
				int/value <> 0
			]
			default [yes]
		]
		
		bool: as red-logic! stack/push*
		bool/header: TYPE_LOGIC							;-- implicit reset of all header flags
		bool/value:  value
		bool
	]

	random: func [
		logic	[red-logic!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-logic!]
		/local
			res	 [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/random"]]

		either seed? [
			_random/srand as-integer logic/value
			logic/header: TYPE_UNSET
		][
			logic/value: _random/rand % 2 <> 0
		]
		logic
	]

	form: func [
		boolean	[red-logic!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/form"]]

		string/concatenate-literal buffer either boolean/value ["true"]["false"]
		part - either boolean/value [4][5]
	]
	
	mold: func [
		boolean	[red-logic!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/mold"]]

		form boolean buffer arg part
	]
	
	compare: func [
		arg1      [red-logic!]							;-- first operand
		arg2	  [red-logic!]							;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [logic!]
		/local
			type  [integer!]
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/compare"]]

		type: TYPE_OF(arg2)
		switch op [
			COMP_EQUAL 
			COMP_STRICT_EQUAL [res: all [type = TYPE_LOGIC  arg1/value = arg2/value]]
			COMP_NOT_EQUAL	  [res: any [type <> TYPE_LOGIC arg1/value <> arg2/value]]
			default [
				print-line ["Error: cannot use: " op " comparison on logic! value"]
			]
		]
		res
	]
	
	complement: func [
		bool	[red-logic!]
		return:	[red-value!]
	][
		bool/value: not bool/value
		as red-value! bool
	]

	do-bitwise: func [
		type	  [integer!]
		return:	  [red-logic!]
		/local
			left  [red-logic!]
			right [red-logic!]
	][
		left: as red-logic! stack/arguments
		right: left + 1
		if any [
			TYPE_OF(left) <> TYPE_LOGIC
			TYPE_OF(right) <> TYPE_LOGIC
		][
			;@@ throw error
			print-line "*** Script error: incompatible argument for bitwise of logic!"
		]
		left/value: switch type [
			OP_AND [left/value and right/value]
			OP_OR  [left/value or right/value]
			OP_XOR [left/value xor right/value]
		]
		left
	]

	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "logic/and~"]]
		as red-value! do-bitwise OP_AND
	]

	or~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "logic/or~"]]
		as red-value! do-bitwise OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "logic/xor~"]]
		as red-value! do-bitwise OP_XOR
	]

	init: does [
		true-value/header:  TYPE_LOGIC
		true-value/value: 	yes
		
		false-value/header: TYPE_LOGIC
		false-value/value: 	no
	
		datatype/register [
			TYPE_LOGIC
			TYPE_VALUE
			"logic!"
			;-- General actions --
			:make
			:random
			null			;reflect
			null			;to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			:and~
			:complement
			:or~
			:xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;next
			null			;pick
			null			;poke
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]