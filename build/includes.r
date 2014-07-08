REBOL [
	Title:   "Red source files preprocessor"
	Author:  "Nenad Rakocevic"
	File: 	 %includes.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %..
do %system/utils/encap-fs.r

write %build/bin/sources.r set-cache [
	%version.r
	%usage.txt
	%boot.red
	%lexer.red
	%compiler.r
	%lexer.r
	%runtime/ [
		%actions.reds
		%allocator.reds
		%debug-tools.reds
		%interpreter.reds
		%macros.reds
		%natives.reds
		%parse.reds
		%random.reds
		%red.reds
		%stack.reds
		%stack.reds
		%tools.reds
		%unicode.reds
		%simple-io.reds
		%datatypes/ [
			%action.reds
			%block.reds
			%bitset.reds
			%char.reds
			%common.reds
			%context.reds
			%datatype.reds
			%file.reds
			%function.reds
			%get-path.reds
			%get-word.reds
			%integer.reds
			%issue.reds
			%lit-path.reds
			%lit-word.reds
			%logic.reds
			%native.reds
			%none.reds
			%op.reds
			%object.reds
			%paren.reds
			%path.reds
			%point.reds
			%refinement.reds
			%routine.reds
			%set-path.reds
			%set-word.reds
			%string.reds
			%structures.reds
			%symbol.reds
			%unset.reds
			%url.reds
			%word.reds
			%binary.reds
		]
		%platform/ [
			%android.reds
			%darwin.reds
			%linux.reds
			%POSIX.reds
			%syllable.reds
			%win32.reds
		]
		%console/ [
			%console.red
			%help.red
			%input.red
		]
	]
	%utils/ [
		%extractor.r
	]
	%system/ [
		%compiler.r
		%config.r
		%emitter.r
		%linker.r
		%loader.r
		%runtime/ [
			%android.reds
			%common.reds
			%darwin.reds
			%debug.reds
			%freebsd.reds
			%libc.reds
			%lib-names.reds
			%lib-natives.reds
			%linux.reds
			%linux-sigaction.reds
			%POSIX.reds
			%POSIX-signals.reds
			%start.reds
			%syllable.reds
			%system.reds
			%utils.reds
			%win32.reds
			%win32-driver.reds
		]
		%formats/ [
			%ELF.r
			%Mach-O.r
			%PE.r
		]
		%targets/ [
			%ARM.r
			%IA-32.r
			%target-class.r
		]
		%utils/ [
			%IEEE-754.r
			%int-to-bin.r
			%r2-forward.r
			%secure-clean-path.r
			%virtual-struct.r
			%profiler.r
		]
	]
]

change-dir %build/
