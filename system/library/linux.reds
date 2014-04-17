Red/System [
	Title:   "Red/System unistd Binding"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %linux.reds
	Rights:  "Copyright (c) 2014 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#if target = 'IA-32 [
	system/fpu/mask/overflow: on
	system/fpu/mask/underflow: on
	system/fpu/mask/zero-divide: on
	system/fpu/mask/invalid-op: on
	system/fpu/update
]

#if OS <> 'Windows [
	; Wordexp enums
	#enum wrde-flag [
		WRDE_DOOFFS:     1
		WRDE_APPEND:     2
		WRDE_NOCMD:      4
		WRDE_REUSE:      8
		WRDE_SHOWERR:    16
		WRDE_UNDEF:      32
		__WRDE_FLAGS:    63
	]
	#enum wrde-error [
		WRDE_NOSPACE:     1
		WRDE_BADCHAR:     2
		WRDE_BADVAL:      3
		WRDE_CMDSUB:      4
		WRDE_SYNTAX:      5
	]
	; Wordexp types
	wordexp-type!: alias struct! [
		we_wordc  [integer!]
		we_wordv  [str-array!]
		we_offs   [integer!]
	]
	; Values for the second argument to fcntl
	#define F_DUPFD   0
	#define F_GETFD   1
	#define F_SETFD   2
	#define F_GETFL   3
	#define F_SETFL   4

	; Values for the third argument to fcntl
	#enum open-fnctl! [
		O_RDONLY:          00h
		O_WRONLY:          01h
		O_RDWR:            02h
		O_CREAT:         0100h
		O_EXCL:          0200h
		O_NOCTTY:        0400h
		O_TRUNC:     00001000h
		O_APPEND:    00002000h
		O_NONBLOCK:  00004000h
		O_SYNC:      04010000h
		O_ASYNC:     00020000h
		O_LARGEFILE: 00100000h

		O_DIRECTORY: 00200000h
		O_NOFOLLOW:  00400000h
		O_CLOEXEC:   02000000h
		O_DIRECT:    00040000h
		O_NOATIME:   01000000h
		O_PATH:      10000000h
		O_DSYNC:     00010000h
	]


	#import [ LIBC-file cdecl [
		fork: "fork" [ "Create a new process"
			return:        [integer!]
		]
		sleep: "sleep" [ "Make the process sleep for nb seconds"
			nb             [integer!]
			return:        [integer!]
		]
		execvp: "execvp" [
			cmd            [c-string!] "Command to run"
			args-list      [str-array!]
			return:        [integer!]
		]
		wordexp: "wordexp" [ "Perform word expansions"
			words          [c-string!]
			pwordexp       [wordexp-type!]
			flags          [integer!]
			return:        [integer!]
		]
		wordfree: "wordfree" [ "Free strings array"
			pwordexp       [wordexp-type!]
			return:        [integer!]
		]
		wait: "wait" [ "Wait for any child process to stop or terminate"
			status         [int-ptr!]
			return:        [integer!]
		]
		waitpid: "waitpid" [ "Wait for specified child process to stop or terminate"
			pid            [integer!]  "Process ID"
			status         [int-ptr!]
			options        [integer!]
			return:        [integer!]
		]
		pipe: "pipe" [ "Create a one-way communication channel"
			pipedes        [int-ptr!]  "Pointer to a 2 integers array"
			return:        [integer!]
		]
		dup2: "dup2" [ "Duplicate fd to fd2 closing fd2 and making it open on the same file"
			fd             [integer!]  "File descriptor"
			fd2            [integer!]  "File descriptor"
			return:        [integer!]
		]
		io-open: "open" [ "Open FILE and return a new file descriptor for it, or -1 on error"
			filename		[c-string!]
			flags			[integer!]
			return:			[integer!]
		]
		io-close: "close" [ "Close the file descriptor"
			fd             [integer!]  "File descriptor"
			return:        [integer!]
		]
		io-read: "read" [ "Read nbytes into buf from fd"
			fd             [integer!]  "File descriptor"
			buf            [byte-ptr!] "Pointer to allocated memory"
			nbytes         [integer!]  "Size of allocated memory"
			return:        [integer!]  "Number of bytes read or error"
		]
		io-write: "write" [ "Write nbytes into fd from buf"
			fd             [integer!]  "File descriptor"
			buf            [byte-ptr!] "Pointer to source data"
			nbytes         [integer!]  "Source data count (bytes)"
			return:        [integer!]  "Number of bytes written or error"
		]
		fcntl: "fcntl" [ "Manipulate file descriptor"
			[variadic]
			; fd           [integer!]    "File descriptor"
			; cmd          [integer!]    "Command"
			; ...                        "Optional arguments"
			return:        [integer!]
		]
	] ; cdecl
	] ; #import
] ; OS <> 'Windows
