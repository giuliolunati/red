Red/System [
	Title:   "Red native functions"
	Author:  "Nenad Rakocevic"
	File: 	 %natives.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define RETURN_NONE [
	stack/reset
	none/push-last
	exit
]

#define RETURN_UNSET [
	stack/reset
	unset/push-last
]

natives: context [
	verbose: 0
	lf?: 	 no											;-- used to print or not an ending newline
	
	table: declare int-ptr!
	top: 1
	
	buffer-blk: as red-block! 0

	register: func [
		[variadic]
		count	   [integer!]
		list	   [int-ptr!]
		/local
			offset [integer!]
	][
		offset: 0
		
		until [
			table/top: list/value
			top: top + 1
			assert top <= NATIVES_NB
			list: list + 1
			count: count - 1
			zero? count
		]
	]
	
	;--- Natives ----
	
	if*: does [
		either logic/false? [
			RETURN_NONE
		][
			interpreter/eval as red-block! stack/arguments + 1 yes
		]
	]
	
	unless*: does [
		either logic/false? [
			interpreter/eval as red-block! stack/arguments + 1 yes
		][
			RETURN_NONE
		]
	]
	
	either*: func [
		/local offset [integer!]
	][
		offset: either logic/true? [1][2]
		interpreter/eval as red-block! stack/arguments + offset yes
	]
	
	any*: func [
		/local
			value [red-value!]
			tail  [red-value!]
	][
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		
		while [value < tail][
			value: interpreter/eval-next value tail no
			if logic/true? [exit]
		]
		RETURN_NONE
	]
	
	all*: func [
		/local
			value [red-value!]
			tail  [red-value!]
	][
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		
		if value = tail [RETURN_NONE]
		
		while [value < tail][
			value: interpreter/eval-next value tail no
			if logic/false? [RETURN_NONE]
		]
	]
	
	while*:	func [
		/local
			cond [red-block!]
			body [red-block!]
	][
		cond: as red-block! stack/arguments
		body: as red-block! stack/arguments + 1
		
		stack/mark-native words/_body
		while [
			interpreter/eval cond yes
			logic/true?
		][
			stack/reset
			interpreter/eval body yes
		]
		stack/unwind
		RETURN_UNSET
	]
	
	until*: func [
		/local
			body [red-block!]
	][
		body: as red-block! stack/arguments

		stack/mark-native words/_body
		until [
			stack/reset
			interpreter/eval body yes
			logic/true?
		]
		stack/unwind-last
	]
	
	loop*: func [
		/local
			body [red-block!]
			i	 [integer!]
	][
		i: integer/get*
		unless positive? i [RETURN_NONE]				;-- if counter <= 0, no loops
		
		body: as red-block! stack/arguments + 1
	
		stack/mark-native words/_body
		until [
			stack/reset
			interpreter/eval body yes
			i: i - 1
			zero? i
		]
		stack/unwind-last
	]
	
	repeat*: func [
		/local
			w	   [red-word!]
			body   [red-block!]
			count  [red-integer!]
			cnt	   [integer!]
			i	   [integer!]
	][
		w: 	   as red-word!    stack/arguments
		count: as red-integer! stack/arguments + 1
		body:  as red-block!   stack/arguments + 2
		
		i: integer/get as red-value! count
		unless positive? i [RETURN_NONE]				;-- if counter <= 0, no loops
		
		count/value: 1
	
		stack/mark-native words/_body
		until [
			stack/reset
			_context/set w as red-value! count
			interpreter/eval body yes
			count/value: count/value + 1
			i: i - 1
			zero? i
		]
		stack/unwind-last
	]
	
	foreach*: func [
		/local
			value [red-value!]
			body  [red-block!]
			size  [integer!]
	][
		value: stack/arguments
		body: as red-block! stack/arguments + 2
		
		stack/push stack/arguments + 1					;-- copy arguments to stack top in reverse order
		stack/push value								;-- (required by foreach-next)
		
		stack/mark-native words/_body
		stack/set-last unset-value
		
		either TYPE_OF(value) = TYPE_BLOCK [
			size: block/rs-length? as red-block! value
			
			while [foreach-next-block size][			;-- foreach [..]
				stack/reset
				interpreter/eval body yes
			]
		][
			while [foreach-next][						;-- foreach <word!>
				stack/reset
				interpreter/eval body yes
			]
		]
		stack/unwind-last
	]
	
	forall*: func [
		/local
			w 	   [red-word!]
			body   [red-block!]
			saved  [red-value!]
			series [red-series!]
	][
		w:    as red-word!  stack/arguments
		body: as red-block! stack/arguments + 1
		
		saved: word/get w							;-- save series (for resetting on end)
		w: word/push w								;-- word argument
		
		stack/mark-native words/_body
		while [
			loop? as red-series! _context/get w
		][
			stack/reset
			interpreter/eval body yes
			series: as red-series! _context/get w
			series/head: series/head + 1
		]
		stack/unwind-last
		_context/set w saved
	]
	
	func*: does [
		_function/validate as red-block! stack/arguments
		_function/push 
			as red-block! stack/arguments
			as red-block! stack/arguments + 1
			null
			0
		stack/set-last stack/top - 1
	]
	
	function*:	does [
		_function/collect-words
			as red-block! stack/arguments
			as red-block! stack/arguments + 1
		func*
	]
	
	does*: does [
		copy-cell stack/arguments stack/push*
		block/make-at as red-block! stack/arguments 1
		func*
	]
	
	has*: func [/local blk [red-block!]][
		blk: as red-block! stack/arguments
		block/insert-value blk as red-value! refinements/local
		blk/head: blk/head - 1
		func*
	]
		
	switch*: func [
		default? [integer!]
		/local
			pos	 [red-value!]
			blk  [red-block!]
			alt  [red-block!]
			end  [red-value!]
			s	 [series!]
	][
		blk: as red-block! stack/arguments + 1
		alt: as red-block! stack/arguments + 2
		
		pos: actions/find
			as red-series! blk
			stack/arguments
			null
			yes											;-- /only
			no
			no
			null
			null
			no
			no
			yes											;-- /tail
			no
			
		either TYPE_OF(pos) = TYPE_NONE [
			either negative? default? [
				RETURN_NONE
			][
				interpreter/eval alt yes
				exit									;-- early exit with last value on stack
			]
		][
			s: GET_BUFFER(blk)
			end: s/tail
			pos: block/pick as red-series! pos 1 null
			
			while [pos < end][							;-- find first following block
				if TYPE_OF(pos) = TYPE_BLOCK [
					stack/reset
					interpreter/eval as red-block! pos yes	;-- do the block
					exit								;-- early exit with last value on stack
				]
				pos: pos + 1
			]
		]
		RETURN_NONE
	]
	
	case*: func [
		all? 	  [integer!]
		/local
			value [red-value!]
			tail  [red-value!]
	][
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		if value = tail [RETURN_NONE]
		
		while [value < tail][
			value: interpreter/eval-next value tail no	;-- eval condition
			either logic/true? [
				either TYPE_OF(value) = TYPE_BLOCK [	;-- if true, eval what follows it
					stack/reset
					interpreter/eval as red-block! value yes
				][
					value: interpreter/eval-next value tail no
				]
				if negative? all? [exit]				;-- early exit with last value on stack (unless /all)
			][
				value: value + 1						;-- single value only allowed for cases bodies
			]
		]
		RETURN_NONE
	]
	
	do*: func [
		/local
			arg [red-value!]
			str	[red-string!]
			s	[series!]
	][
		arg: stack/arguments
		switch TYPE_OF(arg) [
			TYPE_BLOCK [
				interpreter/eval as red-block! arg yes
			]
			TYPE_PATH [
				interpreter/eval-path arg arg arg + 1 no
				stack/set-last arg + 1
			]
			TYPE_STRING [
				;#call [transcode str none]
				;str: as red-string! arg
				;s: GET_BUFFER(str)
				;tokenizer/scan as c-string! s/offset null	;@@ temporary limited to Latin-1
				;do*
			]
			default [
				interpreter/eval-expression arg arg + 1 no no
			]
		]
	]
	
	get*: func [
		any? [integer!]
	][
		stack/set-last _context/get as red-word! stack/arguments
	]
	
	set*: func [
		any? [integer!]
		/local
			w	  [red-word!]
			value [red-value!]
			blk	  [red-block!]
	][
		w: as red-word! stack/arguments
		value: stack/arguments + 1
		
		either TYPE_OF(w) = TYPE_BLOCK [
			blk: as red-block! w
			set-many blk value block/rs-length? blk
			stack/set-last value
		][
			stack/set-last _context/set w value
		]
	]

	print*: does [
		lf?: yes											;@@ get rid of this global state
		prin*
		lf?: no
	]
	
	prin*: func [
		/local
			arg		[red-value!]
			str		[red-string!]
			blk		[red-block!]
			series	[series!]
			offset	[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/prin"]]
		
		arg: stack/arguments
		
		either any [
			TYPE_OF(arg) = TYPE_STRING 						;@@ replace by ANY_STRING?
			TYPE_OF(arg) = TYPE_FILE
		][
			str: as red-string! arg
		][
			block/rs-clear buffer-blk
			stack/push as red-value! buffer-blk
			assert stack/top - 2 = stack/arguments			;-- check for correct stack layout
			
			if TYPE_OF(arg) = TYPE_BLOCK [
				reduce* 1
				blk: as red-block! arg
				blk/head: 0									;-- head changed by reduce/into
			]
			actions/form* -1
			str: as red-string! stack/arguments + 1
			assert any [
				TYPE_OF(str) = TYPE_STRING
				TYPE_OF(str) = TYPE_SYMBOL					;-- symbol! and string! structs are overlapping
			]
		]
		series: GET_BUFFER(str)
		offset: (as byte-ptr! series/offset) + (str/head << (GET_UNIT(series) >> 1))

		either lf? [
			switch GET_UNIT(series) [
				Latin1 [platform/print-line-Latin1 as c-string! offset]
				UCS-2  [platform/print-line-UCS2 				offset]
				UCS-4  [platform/print-line-UCS4   as int-ptr!  offset]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " GET_UNIT(series)]
				]
			]
		][
			switch GET_UNIT(series) [
				Latin1 [platform/print-Latin1 as c-string! offset]
				UCS-2  [platform/print-UCS2   			   offset]
				UCS-4  [platform/print-UCS4   as int-ptr!  offset]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " GET_UNIT(series)]
				]
			]
		]
		stack/set-last unset-value
	]
	
	compare: func [
		op		   [integer!]
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		args: stack/arguments
		result: as red-logic! args
		result/value: actions/compare args args + 1 op
		result/header: TYPE_LOGIC
		result
	]
	
	equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/equal?"]]
		compare COMP_EQUAL
	]
	
	not-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not-equal?"]]
		compare COMP_NOT_EQUAL
	]
	
	strict-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/strict-equal?"]]
		compare COMP_STRICT_EQUAL
	]
	
	lesser?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser?"]]
		compare COMP_LESSER
	]
	
	greater?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater?"]]
		compare COMP_GREATER
	]
	
	lesser-or-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser-or-equal?"]]
		compare COMP_LESSER_EQUAL
	]	
	
	greater-or-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater-or-equal?"]]
		compare COMP_GREATER_EQUAL
	]
	
	same?*: does []
	
	not*: func [
		/local bool [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not"]]
		
		bool: as red-logic! stack/arguments
		bool/value: logic/false?						;-- run test before modifying stack
		bool/header: TYPE_LOGIC
	]
	
	halt*: does [halt]
	
	type?*: func [
		word?	 [integer!]
		return:  [red-value!]
		/local
			dt	 [red-datatype!]
			w	 [red-word!]
			name [names!]
	][
		either negative? word? [
			dt: as red-datatype! stack/arguments		;-- overwrite argument
			dt/value: TYPE_OF(dt)						;-- extract type before overriding
			dt/header: TYPE_DATATYPE
			as red-value! dt
		][
			w: as red-word! stack/arguments				;-- overwrite argument
			name: name-table + TYPE_OF(w)				;-- point to the right datatype name record
			stack/set-last as red-value! name/word
		]
	]
	
	reduce*: func [
		into [integer!]
		/local
			value [red-value!]
			tail  [red-value!]
			blk	  [red-block!]
			arg	  [red-value!]
			into? [logic!]
	][
		arg: stack/arguments
		if TYPE_OF(arg) <> TYPE_BLOCK [					;-- pass-thru for non block! values
			interpreter/eval-expression arg arg + 1 no no
			exit
		]
		into?: into >= 0
		
		value: block/rs-head as red-block! arg
		tail:  block/rs-tail as red-block! arg
		
		stack/mark-native words/_body
		
		blk: either into? [
			as red-block! stack/push arg + into
		][
			block/push-only* (as-integer tail - value) >> 4
		]
		
		while [value < tail][
			value: interpreter/eval-next value tail yes
			either into? [actions/insert* -1 0 -1][block/append*]
			stack/keep									;-- preserve the reduced block on stack
		]
		stack/unwind-last
	]
	
	compose-block: func [
		blk		[red-block!]
		deep?	[logic!]
		only?	[logic!]
		into	[red-block!]
		root?	[logic!]
		return: [red-block!]
		/local
			value  [red-value!]
			tail   [red-value!]
			new	   [red-block!]
			result [red-value!]
			into?  [logic!]
	][
		value: block/rs-head blk
		tail:  block/rs-tail blk
		into?: all [root? OPTION?(into)]

		new: either into? [
			into
		][
			block/push-only* (as-integer tail - value) >> 4	
		]
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_BLOCK [
					blk: either deep? [
						compose-block as red-block! value deep? only? into no
					][
						as red-block! value
					]
					either into? [
						block/insert-value new as red-value! blk
					][
						copy-cell as red-value! blk ALLOC_TAIL(new)
					]
				]
				TYPE_PAREN [
					blk: as red-block! value
					unless zero? block/rs-length? blk [
						interpreter/eval blk yes
						result: stack/arguments
						blk: as red-block! result 
						
						unless any [
							TYPE_OF(result) = TYPE_UNSET
							all [
								not only?
								TYPE_OF(result) = TYPE_BLOCK
								zero? block/rs-length? blk
							]
						][
							either any [
								only? 
								TYPE_OF(result) <> TYPE_BLOCK
							][
								either into? [
									block/insert-value new result
								][
									copy-cell result ALLOC_TAIL(new)
								]
							][
								either into? [
									block/insert-block new as red-block! result
								][
									block/rs-append-block new as red-block! result
								]
							]
						]
					]
				]
				default [
					either into? [
						block/insert-value new value
					][
						copy-cell value ALLOC_TAIL(new)
					]
				]
			]
			value: value + 1
		]
		new
	]
	
	compose*: func [
		deep [integer!]
		only [integer!]
		into [integer!]
	][
		arg: stack/arguments
		if TYPE_OF(arg) <> TYPE_BLOCK [					;-- pass-thru for non block! values
			interpreter/eval-expression arg arg + 1 no no
			exit
		]
		stack/set-last 
			as red-value! compose-block
				as red-block! arg
				as logic! deep + 1 
				as logic! only + 1
				as red-block! stack/arguments + into
				yes
	]
	
	stats*: func [
		show [integer!]
		info [integer!]
		/local
			blk [red-block!]
	][
		case [
			show >= 0 [
				;TBD
				integer/box memory/total
			]
			info >= 0 [
				blk: block/push* 5
				memory-info blk 2
				stack/set-last as red-value! blk
			]
			true [
				integer/box memory/total
			]
		]
	]
	
	bind*: func [
		copy [integer!]
		/local
			value [red-value!]
			ref	  [red-value!]
			fun	  [red-function!]
			word  [red-word!]
			ctx	  [node!]
	][
		value: stack/arguments
		ref: value + 1
		
		either any [
			TYPE_OF(ref) = TYPE_FUNCTION
			;TYPE_OF(ref) = TYPE_OBJECT
		][
			fun: as red-function! ref
			ctx: fun/ctx
		][
			word: as red-word! ref
			ctx: word/ctx
		]
		
		either TYPE_OF(value) = TYPE_BLOCK [
			either negative? copy [
				_context/bind as red-block! value TO_CTX(ctx) no
			][
				stack/set-last 
					as red-value! _context/bind
						block/clone as red-block! value yes
						TO_CTX(ctx)
						no
			]
		][
			word: as red-word! value
			word/ctx: ctx
			word/index: _context/find-word TO_CTX(ctx) word/symbol no
		]
	]
	
	in*: func [
		/local
			obj  [red-object!]
			ctx  [red-context!]
			word [red-word!]
	][
		obj:  as red-object! stack/arguments
		word: as red-word! stack/arguments + 1
		ctx: GET_CTX(obj)

		switch TYPE_OF(word) [
			TYPE_WORD
			TYPE_GET_WORD
			TYPE_SET_WORD
			TYPE_LIT_WORD
			TYPE_REFINEMENT [
				stack/set-last as red-value!
				either negative? _context/bind-word ctx word [
					none-value
				][
					word
				]
			]
			TYPE_BLOCK
			TYPE_PAREN [
				0
			]
			default [0]
		]
	]

	parse*: func [
		case?  [integer!]
		;strict? [integer!]
		trace [integer!]
		/local
			op [integer!]
	][
		op: either as logic! case? + 1 [COMP_STRICT_EQUAL][COMP_EQUAL]
		
		stack/set-last parser/process
			as red-series! stack/arguments
			as red-block!  stack/arguments + 1
			op
			;as logic! strict? + 1
			as red-function!  stack/arguments + trace
	]
	
	union*: func [
		cased	 [integer!]
		skip	 [integer!]
		/local
			set1	 [red-value!]
			skip-arg [red-value!]
			case?	 [logic!]
	][
		set1:	  stack/arguments
		skip-arg: set1 + skip
		case?:	  as logic! cased + 1
		
		switch TYPE_OF(set1) [
			;TYPE_BLOCK  [stack/set-last block/union set1 set2 case? skip-arg]
			;TYPE_STRING [stack/set-last string/union set1 set2 case? skip-arg]
			TYPE_BITSET [
				stack/set-last as red-value! bitset/union
					as red-bitset! set1
					as red-bitset! set1 + 1
					no
					null
				]
			default [
				print-line "*** Error: argument type not supported by UNION"
			]
		]
	]
	
	intersect*: does []
	
	unique*: does []
	
	difference*: does []

	complement?*: func [
		return:    [red-logic!]
		/local
			bits   [red-bitset!]
			s	   [series!]
			result [red-logic!]
	][
		bits: as red-bitset! stack/arguments
		s: GET_BUFFER(bits)
		result: as red-logic! bits

		either TYPE_OF(bits) =  TYPE_BITSET [
			result/value: s/flags and flag-bitset-not = flag-bitset-not
		][
			result/value: false
			print-line "*** Error: argument type must be BITSET!"
		]

		result/header: TYPE_LOGIC
		result
	]

	dehex*: func [
		return:		[red-string!]
		/local
			str		[red-string!]
			buffer	[red-string!]
			s		[series!]
			p		[byte-ptr!]
			p4		[int-ptr!]
			tail	[byte-ptr!]
			unit	[integer!]
			cp		[integer!]
			len		[integer!]
	][
		str: as red-string! stack/arguments
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail

		len: string/rs-length? str
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push* len * unit

		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]

			p: p + unit
			if all [
				cp = as-integer #"%"
				p + (unit << 1) < tail					;-- must be %xx
			][
				p: string/decode-utf8-hex p unit :cp false
			]
			string/append-char GET_BUFFER(buffer) cp unit
		]
		stack/set-last as red-value! buffer
		buffer
	]

	negative?*: func [
		return:	[red-logic!]
		/local
			num [red-integer!]
			res [red-logic!]
	][
		num: as red-integer! stack/arguments
		res: as red-logic! num

		either TYPE_OF(num) =  TYPE_INTEGER [			;@@ Add time! money! pair!
			res/value: negative? num/value
		][
			res/value: false
			print-line "*** Error: argument type must be number!"
		]
		res/header: TYPE_LOGIC
		res
	]

	positive?*: func [
		return: [red-logic!]
		/local
			num [red-integer!]
			res [red-logic!]
	][
		num: as red-integer! stack/arguments
		res: as red-logic! num

		either TYPE_OF(num) =  TYPE_INTEGER [			;@@ Add time! money! pair!
			res/value: positive? num/value
		][
			res/value: false
			print-line "*** Error: argument type must be number!"
		]
		res/header: TYPE_LOGIC
		res
	]

	max*: func [
		/local
			args	[red-value!]
			result	[logic!]
	][
		args: stack/arguments
		result: actions/compare args args + 1 COMP_LESSER
		if result [
			stack/set-last args + 1
		]
	]

	min*: func [
		/local
			args	[red-value!]
			result	[logic!]
	][
		args: stack/arguments
		result: actions/compare args args + 1 COMP_LESSER
		unless result [
			stack/set-last args + 1
		]
	]

	;--- Natives helper functions ---

	loop?: func [
		series  [red-series!]
		return: [logic!]	
		/local
			s	 [series!]
			type [integer!]
	][
		s: GET_BUFFER(series)
	
		type: TYPE_OF(series)
		either any [									;@@ replace with any-block?
			type = TYPE_BLOCK
			type = TYPE_PAREN
			type = TYPE_PATH
			type = TYPE_GET_PATH
			type = TYPE_SET_PATH
			type = TYPE_LIT_PATH
		][
			s/offset + series/head < s/tail
		][
			(as byte-ptr! s/offset)
				+ (series/head << (GET_UNIT(s) >> 1))
				< (as byte-ptr! s/tail)
		]
	]
	
	set-many: func [
		words [red-block!]
		value [red-value!]
		size  [integer!]
		/local
			v		[red-value!]
			blk		[red-block!]
			i		[integer!]
			block?	[logic!]
	][
		block?: TYPE_OF(value) = TYPE_BLOCK
		if block? [blk: as red-block! value]
		i: 1
		
		while [i <= size][		
			v: either block? [block/pick blk i null][value]
			_context/set
				as red-word! block/pick words i null
				v
			i: i + 1
		]
	]
	
	foreach-next-block: func [
		size	[integer!]								;-- number of words in the block
		return: [logic!]
		/local
			series [red-series!]
			blk    [red-block!]
			result [logic!]
	][
		blk:    as red-block!  stack/arguments - 1
		series: as red-series! stack/arguments - 2

		assert any [									;@@ replace with any-block?/any-string? check
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_PAREN
			TYPE_OF(series) = TYPE_PATH
			TYPE_OF(series) = TYPE_GET_PATH
			TYPE_OF(series) = TYPE_SET_PATH
			TYPE_OF(series) = TYPE_LIT_PATH
			TYPE_OF(series) = TYPE_STRING
			TYPE_OF(series) = TYPE_FILE
		]
		assert TYPE_OF(blk) = TYPE_BLOCK

		result: loop? series
		if result [set-many blk as red-value! series size]
		series/head: series/head + size
		result
	]
	
	foreach-next: func [
		return: [logic!]
		/local
			series [red-series!]
			word   [red-word!]
			result [logic!]
	][
		word:   as red-word!   stack/arguments - 1
		series: as red-series! stack/arguments - 2
		
		assert any [									;@@ replace with any-block?/any-string? check
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_PAREN
			TYPE_OF(series) = TYPE_PATH
			TYPE_OF(series) = TYPE_GET_PATH
			TYPE_OF(series) = TYPE_SET_PATH
			TYPE_OF(series) = TYPE_LIT_PATH
			TYPE_OF(series) = TYPE_STRING
			TYPE_OF(series) = TYPE_FILE
		]
		assert TYPE_OF(word) = TYPE_WORD
		
		result: loop? series
		if result [_context/set word actions/pick series 1 null]
		series/head: series/head + 1
		result
	]
	
	forall-loop: func [									;@@ inline?
		return: [logic!]
		/local
			series [red-series!]
			word   [red-word!]
	][
		word: as red-word! stack/arguments - 1
		assert TYPE_OF(word) = TYPE_WORD

		series: as red-series! _context/get word
		loop? series
	]
	
	forall-next: func [									;@@ inline?
		/local
			series [red-series!]
	][
		series: as red-series! _context/get as red-word! stack/arguments - 1
		series/head: series/head + 1
	]
	
	forall-end: func [									;@@ inline?
		/local
			series [red-series!]
			word   [red-word!]
	][
		word: 	as red-word!   stack/arguments - 1
		series: as red-series! stack/arguments - 2
		
		assert any [									;@@ replace with any-block?/any-string? check
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_PAREN
			TYPE_OF(series) = TYPE_PATH
			TYPE_OF(series) = TYPE_GET_PATH
			TYPE_OF(series) = TYPE_SET_PATH
			TYPE_OF(series) = TYPE_LIT_PATH
			TYPE_OF(series) = TYPE_STRING
			TYPE_OF(series) = TYPE_FILE
		]
		assert TYPE_OF(word) = TYPE_WORD

		_context/set word as red-value! series			;-- reset series to its initial offset
	]
	
	repeat-init*: func [
		cell  	[red-value!]
		return: [integer!]
		/local
			int [red-integer!]
	][
		copy-cell stack/arguments cell
		int: as red-integer! cell
		int/value										;-- overlapping /value field for integer! and char!
	]
	
	repeat-set: func [
		cell  [red-value!]
		value [integer!]
		/local
			int [red-integer!]
	][
		assert any [
			TYPE_OF(cell) = TYPE_INTEGER
			TYPE_OF(cell) = TYPE_CHAR
		]
		int: as red-integer! cell
		int/value: value								;-- overlapping /value field for integer! and char!
	]
	
	init: does [
		table: as int-ptr! allocate NATIVES_NB * size? integer!
		buffer-blk: block/make-in red/root 32			;-- block buffer for PRIN's reduce/into

		register [
			:if*
			:unless*
			:either*
			:any*
			:all*
			:while*
			:until*
			:loop*
			:repeat*
			:foreach*
			:forall*
			:func*
			:function*
			:does*
			:has*
			:switch*
			:case*
			:do*
			:get*
			:set*
			:print*
			:prin*
			:equal?*
			:not-equal?*
			:strict-equal?*
			:lesser?*
			:greater?*
			:lesser-or-equal?*
			:greater-or-equal?*
			:same?*
			:not*
			:halt*
			:type?*
			:reduce*
			:compose*
			:stats*
			:bind*
			:in*
			:parse*
			:union*
			:intersect*
			:unique*
			:difference*
			:complement?*
			:dehex*
			:negative?*
			:positive?*
			:max*
			:min*
		]
	]

]
