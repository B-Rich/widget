# digraph.tcl --
#
# This file defines the bindings for Tk widgets to provide
# procedures that allow the input of the extended latin charset
# (often referred to as digraphs).
#
# Copyright (c) 1998 Jeffrey Hobbs

package require Tk 8

namespace eval ::digraph {;

namespace export -clear digraph

variable wid
array set char {
    `A	�	A`	�	`a	�	a`	�
    'A	�	A'	�	'a	�	a'	�
    ^A	�	A^	�	^a	�	a^	�
    ~A	�	A~	�	~a	�	a~	�
    \"A	�	A\"	�	\"a	�	a\"	�
    *A	�	A*	�	*a	�	a*	�
    AE	�			ae	�

    ,C	�	C,	�	,c	�	c,	�

    -D	�	D-	�	-d	�	d-	�

    `E	�	E`	�	`e	�	e`	�
    'E	�	E'	�	'e	�	e'	�
    ^E	�	E^	�	^e	�	e^	�
    \"E	�	E\"	�	\"e	�	e\"	�

    `I	�	I`	�	`i	�	i`	�
    'I	�	I'	�	'i	�	i'	�
    ^I	�	I^	�	^i	�	i^	�
    \"I	�	I\"	�	\"i	�	i\"	�

    ~N	�	N~	�	~n	�	n~	�

    `O	�	O`	�	`o	�	o`	�
    'O	�	O'	�	'o	�	o'	�
    ^O	�	O^	�	^o	�	o^	�
    ~O	�	O~	�	~o	�	o~	�
    \"O	�	O\"	�	\"o	�	o\"	�
    /O	�	O/	�	/o	�	o/	�

    `U	�	U`	�	`u	�	u`	�
    'U	�	U'	�	'u	�	u'	�
    ^U	�	U^	�	^u	�	u^	�
    \"U	�	U\"	�	\"u	�	u\"	�

    'Y	�	'y	�	\"y	�	y\"	�

    ss	�

    !!	�	||	�	\"\"	�	,,	�
    c/	�	/c	�	C/	�	/C	�
    l-	�	-l	�	L-	�	-L	�
    ox	�	xo	�	OX	�	XO	�
    y-	�	-y	�	Y-	�	-Y	�

    co	�	oc	�	CO	�	OC	�
    <<	�	>>	�
    ro	�	or	�	RO	�	OR	�
    -^	�	^-	�	-+	�	+-	�
    ^2	�	2^	�	^3	�	3^	�
    ,u	�	u,	�	.^	�	^.	�
    P|	�	|P	�	p|	�	|p	�
    14	�	41	�	12	�	21	�
    34	�	43	�	??	�	xx	�
}

proc translate {c} {
    variable char
    if {[info exists char($c)]} {return $char($c)}
    return $c
}

proc insert {w type a k} {
    variable wid
    if {[info exists wid($w)]} {
	# This means we have already established the echar binding
	if {[info exists wid(FIRST.$w)]} {
	    # This means that we are in the middle of setting an echar
	    # By default, it will be these two chars
	    set char [translate "$wid(FIRST.$w)$a"]
	    switch -exact $type {
		TkConsole	{ tkConInsert $w $char }
		Text		{ tkTextInsert $w $char }
		Entry		{ tkEntryInsert $w $char }
		Table		{ $w insert active insert $char }
		default		{ catch { $w insert $char } }
	    }
	    bind $w <KeyPress> $wid($w)
	    unset wid($w)
	    unset wid(FIRST.$w)
	} else {
	    # This means we are getting the first part of the echar
	    if {[string compare $a {}]} {
		set wid(FIRST.$w) $a
	    } else {
		# For Text widget, after the Multi_key,
		# it does some weird things to Tk's keysym translations
		switch -glob $k {
		    apostrophe	{set wid(FIRST.$w) "'"}
		    grave	{set wid(FIRST.$w) "`"}
		    comma	{set wid(FIRST.$w) ","}
		    quotedbl	{set wid(FIRST.$w) "\""}
		    asciitilde	{set wid(FIRST.$w) "~"}
		    asciicurcum	{set wid(FIRST.$w) "^"}
		    Control* - Shift* - Caps_Lock - Alt* - Meta* {
			# ignore this anomaly
			return
		    }
		    default	{
			# bogus first char, just end state transition now
			bind $w <KeyPress> $wid($w)
			unset wid($w)
		    }
		}
	    }
	}
    } else {
	# Cache the widget's binding, it doesn't matter if there isn't one
	# If the class has a special binding, then this could be redone
	set wid($w) [bind $w <KeyPress>]
	# override the binding
	bind $w <KeyPress> [namespace code \
		"insert %W [list $type] %A %K; break"]
    }
}

# w is either a specific widget, or a class
proc digraph {w} {
    if {[winfo exists $w]} {
	# it is a specific widget
    } else {
	# it is a class of widgets
	if {[string compare [info commands digraph$w] {}]} {
	    digraph$w
	} else {
	    bind $w <<Digraph>> [namespace code \
		"insert %W [list $w] %A %K; break"]
	}
    }
}

proc digraphText args {
    bind Text <<Digraph>> [namespace code { insert %W Text %A %K; break }]
    bind Text <Key-Escape> {}
}

proc digraphEntry args {
    bind Entry <<Digraph>> [namespace code { insert %W Entry %A %K; break }]
    bind Entry <Key-Escape> {}
}

proc digraphTable args {
    bind Table <<Digraph>> [namespace code { insert %W Table %A %K; break }]
    #bind Table <Key-Escape> {}
}

proc digraphTkConsole args {
    bind TkConsole <<Digraph>> [namespace code {
	insert %W TkConsole %A %K
	break
    }
    ]
    event delete <<TkCon_ExpandFile>> <Key-Escape>
}

}; # end creation of digraph namespace

# THE EVENT YOU CHOOSE IS IMPORTANT - You should also make sure that that
# event is not bound to the class already (for example, most bind <Escape>
# to {# nothing}, but Table uses it for the reread and TkConsole uses it
# for TkCon_ExpandFile).  The Sun <Multi_key> works already, but you might
# want to define special state keys

event add <<Digraph>> <Key-Escape> <Mode_switch>


