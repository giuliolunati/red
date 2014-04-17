Red/System [
	Title:	"Simple file IO functions (temporary)"
	Author: "Nenad Rakocevic"
	File: 	%simple-io.reds
	Tabs: 	4
	Rights: "Copyright (C) 2012-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

simple-io: context [

	#either OS = 'Windows [

		#define GENERIC_WRITE			40000000h
		#define GENERIC_READ 			80000000h
		#define FILE_SHARE_READ			00000001h
		#define FILE_SHARE_WRITE		00000002h
		#define OPEN_EXISTING			00000003h
		#define FILE_ATTRIBUTE_NORMAL	00000080h

		#import [
			"kernel32.dll" stdcall [
				CreateFile:	"CreateFileA" [
					filename	[c-string!]
					access		[integer!]
					share		[integer!]
					security	[int-ptr!]
					disposition	[integer!]
					flags		[integer!]
					template	[int-ptr!]
					return:		[integer!]
				]
				ReadFile:	"ReadFile" [
					file		[integer!]
					buffer		[byte-ptr!]
					bytes		[integer!]
					read		[int-ptr!]
					overlapped	[int-ptr!]
					return:		[integer!]
				]
				GetFileSize: "GetFileSize" [
					file		[integer!]
					high-size	[integer!]
					return:		[integer!]
				]
				CloseHandle:	"CloseHandle" [
					obj			[integer!]
					return:		[integer!]
				]
			]
		]
	][
		#define O_RDONLY	0
		
		#import [
			LIBC-file cdecl [
				_open:	"open" [
					filename	[c-string!]
					flags		[integer!]
					mode		[integer!]
					return:		[integer!]
				]
				_read:	"read" [
					file		[integer!]
					buffer		[byte-ptr!]
					bytes		[integer!]
					return:		[integer!]
				]
				_close:	"close" [
					file		[integer!]
					return:		[integer!]
				]
			]
		]
		
		#case [
			OS = 'FreeBSD [
				;-- http://fxr.watson.org/fxr/source/sys/stat.h?v=FREEBSD10
				stat!: alias struct! [
					st_dev		[integer!]
					st_ino		[integer!]
					st_modelink	[integer!]					;-- st_mode & st_link are both 16bit fields
					st_uid		[integer!]
					st_gid		[integer!]
					st_rdev		[integer!]
					atv_sec		[integer!]					;-- struct timespec inlined
					atv_msec	[integer!]
					mtv_sec		[integer!]					;-- struct timespec inlined
					mtv_msec	[integer!]
					ctv_sec		[integer!]					;-- struct timespec inlined
					ctv_msec	[integer!]
					st_size		[integer!]
					st_size_h	[integer!]
					st_blocks_l	[integer!]
					st_blocks_h	[integer!]
					st_blksize	[integer!]
					st_flags	[integer!]
					st_gen		[integer!]
					st_lspare	[integer!]
					btm_sec     [integer!]
					btm_msec    [integer!]                  ;-- struct timespec inlined
					pad0		[integer!]
					pad1		[integer!]
				]
			]
			OS = 'MacOSX [
				stat!: alias struct! [
					st_dev		[integer!]
					st_ino		[integer!]
					st_modelink	[integer!]					;-- st_mode & st_link are both 16bit fields
					st_uid		[integer!]
					st_gid		[integer!]
					st_rdev		[integer!]
					atv_sec		[integer!]					;-- struct timespec inlined
					atv_msec	[integer!]
					mtv_sec		[integer!]					;-- struct timespec inlined
					mtv_msec	[integer!]
					ctv_sec		[integer!]					;-- struct timespec inlined
					ctv_msec	[integer!]
					st_size		[integer!]
					st_blocks	[integer!]
					st_blksize	[integer!]
					st_flags	[integer!]
					st_gen		[integer!]
				]
			]
			OS = 'Syllable [
				;-- http://glibc.sourcearchive.com/documentation/2.7-18lenny7/glibc-2_87_2bits_2stat_8h_source.html
				stat!: alias struct! [
					st_mode		[integer!]
					st_ino		[integer!]
					st_dev		[integer!]
					st_nlink	[integer!]
					st_uid		[integer!]
					st_gid		[integer!]
					filler1		[integer!]				;-- not in spec above...
					filler2		[integer!]				;-- not in spec above...
					st_size		[integer!]
					;...incomplete...
				]
			]
			all [legacy find legacy 'stat32] [
				stat!: alias struct! [
					st_dev		[integer!]
					st_ino		[integer!]
					st_mode		[integer!]
					st_nlink	[integer!]
					st_uid		[integer!]
					st_gid		[integer!]
					st_rdev		[integer!]
					st_size		[integer!]
					st_blksize	[integer!]
					st_blocks	[integer!]
					st_atime	[integer!]
					st_mtime	[integer!]
					st_ctime	[integer!]
				]
			]
			true [ ; else
				;-- http://lxr.free-electrons.com/source/arch/x86/include/uapi/asm/stat.h
				stat!: alias struct! [				;-- stat64 struct
					st_dev_l	  [integer!]
					st_dev_h	  [integer!]
					pad0		  [integer!]
					__st_ino	  [integer!]
					st_mode		  [integer!]
					st_nlink	  [integer!]
					st_uid		  [integer!]
					st_gid		  [integer!]
					st_rdev_l	  [integer!]
					st_rdev_h	  [integer!]
					pad1		  [integer!]
					st_size		  [integer!]
					st_size_h	  [integer!]
					st_blksize	  [integer!]
					st_blocks	  [integer!]
					st_atime	  [integer!]
					st_atime_nsec [integer!]
					st_mtime	  [integer!]
					st_mtime_nsec [integer!]
					st_ctime	  [integer!]
					st_ctime_nsec [integer!]
					st_ino_h	  [integer!]
					st_ino_l	  [integer!]
					;...optional padding skipped
				]
			]
		]

		#case [
			any [OS = 'MacOSX OS = 'FreeBSD] [
				#import [
					LIBC-file cdecl [
						;-- https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/10.6/man2/stat.2.html?useVersion=10.6
						_stat:	"fstat" [
							file		[integer!]
							restrict	[stat!]
							return:		[integer!]
						]
					]
				]
			]
			true [
				#import [
					LIBC-file cdecl [
						;-- http://refspecs.linuxbase.org/LSB_3.0.0/LSB-Core-generic/LSB-Core-generic/baselib-xstat-1.html
						_stat:	"__fxstat" [
							version		[integer!]
							file		[integer!]
							restrict	[stat!]
							return:		[integer!]
						]
					]
				]
			]

		]
	]
	
	open-file: func [
		filename [c-string!]
		return:	 [integer!]
		/local
			file [integer!]
	][
		#either OS = 'Windows [
			file: CreateFile 
				filename
				GENERIC_READ
				FILE_SHARE_READ
				null
				OPEN_EXISTING
				FILE_ATTRIBUTE_NORMAL
				null
		][
			file: _open filename O_RDONLY 0
		]
		if file = -1 [
			print-line "*** Error: File not found"
			quit -1
		]
		file
	]
	
	file-size?: func [
		file	 [integer!]
		return:	 [integer!]
		/local s
	][
		#case [
			OS = 'Windows [
				GetFileSize file null
			]
			any [OS = 'MacOSX OS = 'FreeBSD] [
				s: declare stat!
				_stat file s
				s/st_size
			]
			true [ ; else
				s: declare stat!
				_stat 3 file s
				s/st_size
			]
		]
	]
	
	read-file: func [
		file	[integer!]
		buffer	[byte-ptr!]
		size	[integer!]
		return:	[integer!]
		/local
			read-sz [integer!]
			res		[integer!]
			error?	[logic!]
	][
		#either OS = 'Windows [
			read-sz: -1
			res: ReadFile file buffer size :read-sz null
			error?: any [zero? res read-sz <> size]
		][
			res: _read file buffer size
			error?: res <= 0
		]
		if error? [
			print-line "*** Error: cannot read file"
			quit -3
		]
		res
	]
	
	close-file: func [
		file	[integer!]
		return:	[integer!]
	][
		#either OS = 'Windows [
			CloseHandle file
		][
			_close file
		]
	]
	
	read-txt: func [
		filename [c-string!]
		return:	 [red-string!]
		/local
			buffer	[byte-ptr!]
			file	[integer!]
			size	[integer!]
			str		[red-string!]
	][
		file: open-file filename
		size: file-size? file
		if size <= 0 [
			print-line "*** Error: empty file"
			quit -2
		]
		
		buffer: allocate size + 1						;-- account for terminal NUL
		read-file file buffer size
		close-file file
		
		size: size + 1
		buffer/size: null-byte
		str: string/load as-c-string buffer size UTF-8
		free buffer
		str
	]
]