Red/System [
	Title:   "binary! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	binary: 	 %binary.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

binary: context [
	verbose: 0

	push: func [
		binary [red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/push"]]
		
		copy-cell as red-value! binary stack/push*
	]

	get-length: func [
		bin		   [red-binary!]
		return:	   [integer!]
		/local
			s	   [series!]
			offset [integer!]
	][
		s: GET_BUFFER(bin)
		offset: bin/head
		if negative? offset [offset: 0]					;-- @@ beware of symbol/index leaking here...
		(as-integer s/tail - s/offset) - offset
	]

	;-- Actions --

	make: func [
		spec	 [red-value!]
		return:	 [red-binary!]
		/local
			binary [red-binary!]
			size   [integer!]
			int	   [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/make"]]
		
		size: 4 ;default size at least 4 bytes... or should we choose another number?
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				size: int/value
			]
			default [--NOT_IMPLEMENTED--]
		]
		binary: as red-binary! stack/push*
		binary/header: TYPE_BINARY							;-- implicit reset of all header flags
		binary/head: 	0
		binary/node: 	alloc-bytes size					;-- alloc enough space for at least a Latin1 string
		binary
	]

	form: func [
		value      [red-binary!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			bin    [series!]
			formed [c-string!]
			len    [integer!]
			bytes  [integer!]
			pout   [byte-ptr!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
			byte   [integer!]
			h	   [c-string!]
			i	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/form"]]
		bin: GET_BUFFER(value)
		bytes: (as-integer bin/tail - bin/offset)
		len: (2 * bytes) + 4 
		formed: as c-string! allocate len
		pout: as byte-ptr! formed
		pout/1: #"#"
		pout/2: #"{"
		pout: pout + 2
		head: as byte-ptr! bin/offset
		tail: as byte-ptr! bin/tail

		h: "0123456789ABCDEF"

		while [head < tail][
			byte: as-integer head/1
			i: byte and 15 + 1								;-- byte // 16 + 1
			pout/1: h/i
			i: byte >> 4 and 15 + 1
			pout/2: h/i

			head: head + 1
			pout: pout + 2
		]
		pout/1: #"}"
		pout/2: null-byte
		string/concatenate-literal buffer formed
		part - len
	]

	mold: func [
		binary    [red-binary!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			int	   [red-integer!]
			limit  [integer!]
			s	   [series!]
			cp	   [integer!]
			p	   [byte-ptr!]
			p4	   [int-ptr!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/mold"]]

		form binary buffer arg part
	]

	copy: func [
		binary    [red-binary!]
		new		[red-string!]
		arg		[red-value!]
		deep?	[logic!]
		types	[red-value!]
		return:	[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/copy"]]
				
		binary: as red-binary! string/copy as red-string! binary new arg deep? types
		binary/header: TYPE_BINARY
		as red-series! binary
	]

;	rs-make-at: func [
;		slot	[cell!]
;		size 	[integer!]								;-- number of cells to pre-allocate
;		return:	[red-binary!]
;		/local 
;			p	[node!]
;			str	[red-binary!]
;	][
;		p: alloc-series size 1 0
;		set-type slot TYPE_BINARY						;@@ decide to use or not 'set-type...
;		binary: as red-binary! slot
;		binary/head: 0
;		binary/node: p
;		binary
;	]
	;--- Property reading actions ---

	head?: func [
		return:	  [red-value!]
		/local
			bin	  [red-binary!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/head?"]]

		bin:   as red-binary! stack/arguments
		state: as red-logic! bin

		state/header: TYPE_LOGIC
		state/value:  zero? bin/head
		as red-value! state
	]

	tail?: func [
		return:	  [red-value!]
		/local
			bin	  [red-binary!]
			state [red-logic!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/tail?"]]

		bin:   as red-binary! stack/arguments
		state: as red-logic! bin

		s: GET_BUFFER(bin)

		state/header: TYPE_LOGIC
		state/value:  (as byte-ptr! s/offset) + bin/head = as byte-ptr! s/tail
		as red-value! state
	]

	index?: func [
		return:	  [red-value!]
		/local
			bin	  [red-binary!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/index?"]]

		bin:   as red-binary! stack/arguments
		index: as red-integer! bin

		index/header: TYPE_INTEGER
		index/value:  bin/head + 1
		as red-value! index
	]

	length?: func [
		bin		[red-binary!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/length?"]]

		get-length bin
	]


	init: does [
		datatype/register [
			TYPE_BINARY
			TYPE_VALUE
			"binary!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			null			;eval-path
			null			;set-path
			null			;compare
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
			:head?
			:index?
			null			;insert
			:length?
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
			:tail?
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
