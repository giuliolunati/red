Red [
	Title:	"Red console"
	Author: ["Nenad Rakocevic" "Kaj de Vos"]
	File: 	%console.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#system-global [
	#either OS = 'Windows [
		#import [
			"kernel32.dll" stdcall [
				ReadConsole: 	 "ReadConsoleW" [
					consoleInput	[integer!]
					buffer			[byte-ptr!]
					charsToRead		[integer!]
					numberOfChars	[int-ptr!]
					inputControl	[int-ptr!]
					return:			[integer!]
				]
			]
		]
		line-buffer-size: 15 * 1024
		line-buffer: allocate line-buffer-size * 2 + 1
	][
		#switch OS [
			MacOSX [
				#define ReadLine-library "libreadline.dylib"
			]
			#default [
				#define ReadLine-library "libreadline.so.6"
				#define History-library  "libhistory.so.6"
			]
		]
		#import [
			ReadLine-library cdecl [
				read-line: "readline" [  ; Read a line from the console.
					prompt			[c-string!]
					return:			[c-string!]
				]
				rl-bind-key: "rl_bind_key" [
					key				[integer!]
					command			[integer!]
					return:			[integer!]
				]
				rl-insert:	 "rl_insert" [
					count			[integer!]
					key				[integer!]
					return:			[integer!]
				]
			]
			#if OS <> 'MacOSX [
				History-library cdecl [
					add-history: "add_history" [  ; Add line to the history.
						line		[c-string!]
					]
				]
			]
		]

		rl-insert-wrapper: func [
			[cdecl]
			count   [integer!]
			key	    [integer!]
			return: [integer!]
		][
			rl-insert count key
		]
	]
]

wprint: func [str [string!]][prin str]

ask: routine [
	prompt [string!]
	/local
		len ret str buffer line pos
][
	#either OS = 'Windows [
		#call [wprint prompt]
		len: 0
		ret: ReadConsole stdin line-buffer line-buffer-size :len null
		if zero? ret [print-line "ReadConsole failed!" halt]
		pos: (len * 2) - 3								;-- position at lower 8bits of CR character
		line-buffer/pos: null-byte						;-- overwrite CR with NUL
		str: string/load as-c-string line-buffer len - 1 UTF-16LE
	][
		line: read-line unicode/to-utf8 prompt -1       ;-- -1: all chars
		if line = null [halt]  ; EOF

		 #if OS <> 'MacOSX [add-history line]

		str: string/load line  1 + length? line UTF-8
;		free as byte-ptr! line
	]
	SET_RETURN(str)
]

input: func [][
	ask ""
]