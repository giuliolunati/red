Red/System [
	Title:   "Float! datatype runtime functions"
	Author:  "Nenad Rakocevic, Oldes"
	File: 	 %decimal.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define DBL_EPSILON		2.2204460492503131E-16

float: context [
	verbose: 4

	uint64!: alias struct! [int1 [byte-ptr!] int2 [byte-ptr!]]
	int64!:  alias struct! [int1 [integer!] int2 [integer!]]

	DOUBLE_MAX: 0.0
	+INF: 0.0											;-- rebol can't load INF, NaN
	QNaN: 0.0

	double-int-union: as int64! :DOUBLE_MAX				;-- set to largest number
	double-int-union/int2: 7FEFFFFFh
	double-int-union/int1: FFFFFFFFh

	double-int-union: as int64! :+INF
	double-int-union/int2: 7FF00000h

	double-int-union: as int64! :QNaN					;-- smallest quiet NaN
	double-int-union/int2: 7FF80000h

	abs: func [
		value	[float!]
		return: [float!]
		/local
			n	[int-ptr!]
	][
		n: (as int-ptr! :value) + 1
		n/value: n/value and 7FFFFFFFh
		value
	]

	get*: func [										;-- unboxing float value from stack
		return: [float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		assert TYPE_OF(fl) = TYPE_FLOAT
		fl/value
	]

	get-any*: func [									;-- special get* variant for SWITCH
		return: [float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		either TYPE_OF(fl) = TYPE_FLOAT [fl/value][0.0] ;-- accept NONE values
	]

	get: func [											;-- unboxing float value
		value	[red-value!]
		return: [float!]
		/local
			fl [red-float!]
	][
		assert TYPE_OF(value) = TYPE_FLOAT
		fl: as red-float! value
		fl/value
	]

	box: func [
		value	[float!]
		return: [red-float!]
		/local
			int [red-float!]
	][
		fl: as red-float! stack/arguments
		fl/header: TYPE_FLOAT
		fl/value: value
		fl
	]

	to-integer: func [
		number 	[float!]
		return:	[integer!]
		/local
			f	[float!]
			d	[int-ptr!]
	][
		;-- Based on this method: http://stackoverflow.com/a/429812/494472
		;-- A bit more explanation: http://lolengine.net/blog/2011/3/20/understanding-fast-float-integer-conversions
		f: number + 6755399441055744.0
		d: as int-ptr! :f
		d/value
	]

	form-float: func [
		f 		[float!]
		return: [c-string!]
		/local
			s	[c-string!]
			s0	[c-string!]
			p0	[c-string!]
			p	[c-string!]
			p1	[c-string!]
			dot? [logic!]
			d	[int64!]
			w0	[integer!]
	][
		d: as int64! :f
		w0: d/int2												;@@ Use little endian. Watch out big endian !

		if w0 and 7FF00000h = 7FF00000h [
			if all [
				zero? d/int1									;@@ Use little endian. Watch out big endian !
				zero? (w0 and 000FFFFFh)
			][
				return either 0 = (w0 and 80000000h) ["1.#INF"]["-1.#INF"]
			]
			return "1.#NaN"
		]

		s: "0000000000000000000000000000000"					;-- 32 bytes wide, big enough.
		sprintf [s "%.14g" f]

		dot?: no
		p:  null
		p1: null
		s0: s
		until [
			if s/1 = #"." [dot?: yes]
			if s/1 = #"e" [
				p: s
				until [
					s: s + 1
					s/1 > #"0"
				]
				p1: s
			]
			s: s + 1
			s/1 = #"^@"
		]

		if p1 <> null [											;-- remove #"+" and leading zero
			p0: p
			either p/2 = #"-" [p: p + 2][p: p + 1]
			move-memory as byte-ptr! p as byte-ptr! p1 as-integer s - p1
			s: p + as-integer s - p1
			s/1: #"^@"
			p: p0
		]
		unless dot? [											;-- added tailing ".0"
			either p = null [
				p: s
			][
				move-memory as byte-ptr! p + 2 as byte-ptr! p as-integer s - p
			]
			p/1: #"."
			p/2: #"0"
			s/3: #"^@"
		]
		s0
	]

	do-math: func [
		type	  [integer!]
		return:	  [red-float!]
		/local
			left  [red-float!]
			right [red-float!]
			int   [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/do-math"]]

		left:  as red-float! stack/arguments
		right: as red-float! left + 1

		assert any [									;@@ replace by typeset check when possible
			TYPE_OF(left) = TYPE_INTEGER
			TYPE_OF(left) = TYPE_FLOAT
		]
		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_CHAR
			TYPE_OF(right) = TYPE_FLOAT
		]

		if TYPE_OF(left) <> TYPE_FLOAT [
			int: as red-integer! left
			left/header: TYPE_FLOAT
			left/value: integer/to-float int/value
		]
		if TYPE_OF(right) <> TYPE_FLOAT [
			int: as red-integer! right
			right/value: integer/to-float int/value
		]

		left/value: switch type [
			OP_ADD [left/value + right/value]
			OP_SUB [left/value - right/value]
			OP_MUL [left/value * right/value]
			OP_DIV [left/value / right/value]
			OP_REM [left/value % right/value]
			default [print-line "*** Math Error: float don't support BITWISE OP!" left/value]
		]
		left
	]

	load-in: func [
		blk	  	[red-block!]
		value 	[float!]
		/local
			fl [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/load-in"]]

		fl: as red-float! ALLOC_TAIL(blk)
		fl/header: TYPE_FLOAT
		fl/value: value
	]
	
	push64: func [
		high	[integer!]
		low		[integer!]
		return: [red-float!]
		/local
			cell [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/push64"]]

		cell: stack/push*
		cell/header: TYPE_FLOAT
		cell/data2: low
		cell/data3: high
		as red-float! cell
	]

	push: func [
		value	[float!]
		return: [red-float!]
		/local
			fl [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/push"]]

		fl: as red-float! stack/push*
		fl/header: TYPE_FLOAT
		fl/value: value
		fl
	]

	;-- Actions --

	make: func [
		proto	 [red-value!]	
		spec	 [red-value!]
		return:	 [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/make"]]

		switch TYPE_OF(spec) [
			TYPE_FLOAT [
				as red-float! spec
			]
			default [
				--NOT_IMPLEMENTED--
				as red-float! spec					;@@ just for making it compilable
			]
		]
	]

	random: func [
		f		[red-float!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-float!]
		/local
			t	[float!]
			s	[float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/random"]]

		either seed? [
			_random/srand to-integer f/value
			f/header: TYPE_UNSET
		][
			s: (integer/to-float _random/rand) / 2147483647.0
			if s < 0.0 [s: 0.0 - s]
			f/value: s * f/value
		]
		f
	]

	to: func [
		type	[red-datatype!]
		spec	[red-float!]
		return: [red-value!]
		/local
			int [red-integer!]
			buf [red-string!]
			f	[float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "to/random"]]

		f: spec/value
		switch type/value [
			TYPE_INTEGER [
				int: as red-integer! type
				int/header: TYPE_INTEGER
				int/value: to-integer either f < 0.0 [f + 0.499999999999999][f - 0.499999999999999]
			]
			TYPE_STRING [
				buf: string/rs-make-at as cell! type 1			;-- 16 bits string
				string/concatenate-literal buf form-float f
			]
			default [
				print-line "** Script error: Invalid argument for TO float!"
				type/header: TYPE_UNSET
			]
		]
		as red-value! type
	]

	form: func [
		fl		   [red-float!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/form"]]

		formed: form-float fl/value
		string/concatenate-literal buffer formed
		part - length? formed							;@@ optimize by removing length?
	]

	mold: func [
		fl		[red-float!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/mold"]]

		form fl buffer arg part
	]

	NaN?: func [
		value	[float!]
		return: [logic!]
		/local
			n	[int-ptr!]
			m	[int-ptr!]
	][
		m: as int-ptr! :value
		n: m + 1
		either n/value and 7FF00000h = 7FF00000h [		;-- the exponent bits are all ones
			either any [								;-- the fraction bits are not entirely zeros
				m/value <> 0
				n/value and 000FFFFFh <> 0
			] [true][false]
		][false]
	]

	;@@ using 64bit integer will simplify it significantly.
	;-- returns false if either number is (or both are) NAN.
	;-- treats really large numbers as almost equal to infinity.
	;-- thinks +0.0 and -0.0 are 0 DLP's apart.
	;-- Max ULP: 4 (enough for ordinary use)
	;-- Ref: https://github.com/svn2github/googletest/blob/master/include/gtest/internal/gtest-internal.h
	;--      https://github.com/rebol/rebol/blob/master/src/core/t-decimal.c
	almost-equal: func [
		left	[float!]
		right	[float!]
		return: [logic!]
		/local
			a	 [uint64!]
			b	 [uint64!]
			lo1  [byte-ptr!]
			lo2  [byte-ptr!]
			hi1  [byte-ptr!]
			hi2  [byte-ptr!]
			diff [byte-ptr!]
	][
		if left = right [return true]					;-- for NaN, also raise error in default mode
		if any [NaN? left NaN? right] [return false]

		a: as uint64! :left
		b: as uint64! :right
		lo1: a/int1
		lo2: b/int1
		hi1: a/int2
		hi2: b/int2

		either (as-integer hi1) < 0 [
			hi1: as byte-ptr! (not as-integer hi1)
			lo1: as byte-ptr! (not as-integer lo1)
			either (as-integer lo1) = -1 [hi1: hi1 + 1 lo1: null][lo1: lo1 + 1]
		][
			hi1: as byte-ptr! (as-integer hi1) or 80000000h
		]

		either (as-integer hi2) < 0 [
			hi2: as byte-ptr! (not as-integer hi2)
			lo2: as byte-ptr! (not as-integer lo2)
			either (as-integer lo2) = -1 [hi2: hi2 + 1 lo2: null][lo2: lo2 + 1]
		][
			hi2: as byte-ptr! (as-integer hi2) or 80000000h
		]

		diff: either hi1 > hi2 [hi1 - hi2][hi2 - hi1]
		if diff > (as byte-ptr! 1) [return false]

		case [
			hi1 = hi2 [
				diff: either lo1 < lo2 [lo2 - lo1][lo1 - lo2]
			]
			hi1 > hi2 [
				either lo1 >= lo2 [return false][
					diff: (as byte-ptr! -1) - lo2 + lo1 + 1
				]
			]
			hi2 > hi1 [
				either lo2 >= lo1 [return false][
					diff: (as byte-ptr! -1) - lo1 + lo2 + 1
				]
			]
		]

		diff <= (as byte-ptr! 4)
	]

	compare: func [
		value1    [red-float!]						;-- first operand
		value2    [red-float!]						;-- second operand
		op	      [integer!]						;-- type of comparison
		return:   [logic!]
		/local
			int   [red-integer!]
			left  [float!]
			right [float!] 
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/compare"]]

		left: value1/value

		switch TYPE_OF(value2) [
			TYPE_CHAR
			TYPE_INTEGER [
				int: as red-integer! value2
				right: integer/to-float int/value
			]
			TYPE_FLOAT [right: value2/value]
			default [RETURN_COMPARE_OTHER]
		]
		switch op [
			COMP_EQUAL 			[res: almost-equal left right]
			COMP_NOT_EQUAL 		[res: not almost-equal left right]
			COMP_STRICT_EQUAL	[res: all [TYPE_OF(value2) = TYPE_FLOAT left = right]]
			COMP_LESSER			[res: left <  right]
			COMP_LESSER_EQUAL	[res: left <= right]
			COMP_GREATER		[res: left >  right]
			COMP_GREATER_EQUAL	[res: left >= right]
		]
		res
	]

	complement: func [
		fl		[red-float!]
		return:	[red-value!]
	][
		--NOT_IMPLEMENTED--
		;fl/value: not fl/value
		as red-value! fl
	]

	absolute: func [
		return: [red-float!]
		/local
			f	  [red-float!]
			value [float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/absolute"]]

		f: as red-float! stack/arguments
		f/value: abs f/value
		f 											;-- re-use argument slot for return value
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/add"]]
		as red-value! do-math OP_ADD
	]

	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/divide"]]
		as red-value! do-math OP_DIV
	]

	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/multiply"]]
		as red-value! do-math OP_MUL
	]

	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/subtract"]]
		as red-value! do-math OP_SUB
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/remainder"]]
		as red-value! do-math OP_REM
	]

	negate: func [
		return: [red-float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		fl/value: 0.0 - fl/value
		fl 											;-- re-use argument slot for return value
	]

	power: func [
		return:	 [red-float!]
		/local
			base [red-float!]
			exp  [red-float!]
			int	 [red-integer!]
	][
		base: as red-float! stack/arguments
		exp: base + 1
		if TYPE_OF(exp) = TYPE_INTEGER [
			int: as red-integer! exp
			exp/value: integer/to-float int/value
		]
		base/value: float-power base/value exp/value
		base
	]

	even?: func [
		int		[red-float!]
		return: [logic!]
	][
		;requires conversion to integer
		;not as-logic float/value and 1
		--NOT_IMPLEMENTED--
		false
	]

	odd?: func [
		int		[red-integer!]
		return: [logic!]
	][
		;requires conversion to integer
		;as-logic int/value and 1
		--NOT_IMPLEMENTED--
		false
	]

	#define FLOAT_TRUNC(x) [d: floor float/abs x either x < 0.0 [0.0 - d][d]]
	#define FLOAT_AWAY(x)  [d: ceil float/abs x  either x < 0.0 [0.0 - d][d]]

	round: func [
		value		[red-value!]
		scale		[red-float!]
		_even?		[logic!]
		down?		[logic!]
		half-down?	[logic!]
		floor?		[logic!]
		ceil?		[logic!]
		half-ceil?	[logic!]
		return:		[red-value!]
		/local
			int		[red-integer!]
			f		[red-float!]
			dec		[float!]
			sc		[float!]
			r		[float!]
			d		[float!]
			e		[integer!]
			v		[logic!]
	][
		e: 0
		f: as red-float! value
		dec: f/value
		sc: 1.0
		if OPTION?(scale) [
			if TYPE_OF(scale) = TYPE_INTEGER [
				int: as red-integer! value
				int/value: to-integer dec
				int/header: TYPE_INTEGER
				return integer/round value as red-integer! scale _even? down? half-down? floor? ceil? half-ceil?
			]
			sc: abs scale/value
		]

		if sc = 0.0 [
			print-line "*** Math Error: float overflow on ROUND"
			value/header: TYPE_UNSET
			return value
		]

		if sc < ldexp abs dec -53 [return value]		;-- is scale negligible?

		v: sc >= 1.0
		dec: either v [dec / sc][
			r: frexp sc :e
			either e <= -1022 [
				sc: r
				dec: ldexp dec e
			][e: 0]
			sc: 1.0 / sc
			dec * sc
		]

		d: abs dec
		r: 0.5 + floor d
		dec: case [
			down?		[FLOAT_TRUNC(dec)]
			floor?		[floor dec		 ]
			ceil?		[ceil dec		 ]
			r < d		[FLOAT_AWAY(dec) ]
			r > d		[FLOAT_TRUNC(dec)]
			_even?		[either d % 2.0 < 1.0 [FLOAT_TRUNC(dec)][FLOAT_AWAY(dec)]]
			half-down?	[FLOAT_TRUNC(dec)]
			half-ceil?	[ceil dec		 ]
			true		[FLOAT_AWAY(dec) ]
		]

		f/value: either v [
			dec: dec * sc
			if DOUBLE_MAX = abs dec [
				print-line "*** Math Error: float overflow on ROUND"
				value/header: TYPE_UNSET
			]
			dec
		][
			ldexp dec / sc e
		]
		value
	]

	init: does [
		datatype/register [
			TYPE_FLOAT
			TYPE_VALUE
			"float!"
			;-- General actions --
			:make
			:random
			null			;reflect
			:to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			:power
			:remainder
			:round
			:subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
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