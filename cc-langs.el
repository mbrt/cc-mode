;;; cc-langs.el --- language specific settings for CC Mode

;; Copyright (C) 1985,1987,1992-2001 Free Software Foundation, Inc.

;; Authors:    2000- Martin Stjernholm
;;	       1998-1999 Barry A. Warsaw and Martin Stjernholm
;;             1992-1997 Barry A. Warsaw
;;             1987 Dave Detlefs and Stewart Clamen
;;             1985 Richard M. Stallman
;; Maintainer: bug-cc-mode@gnu.org
;; Created:    22-Apr-1997 (split from cc-mode.el)
;; Version:    See cc-mode.el
;; Keywords:   c languages oop

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This file contains all the language dependent variables, except
;; those used for font locking which reside in cc-fonts.el.  As far as
;; possible, all the differences between the languages that CC Mode
;; supports are described with these variables only, so that the code
;; can be shared.
;;
;; The language constant system (see cc-defs.el) is used to specify
;; various language dependent info at a high level, such as lists of
;; keywords, and then from them generate - at compile time - the
;; various regexps and other low-level structures actually employed in
;; the code at runtime.
;;
;; This system is also designed to make it easy for developers of
;; derived modes to customize the source constants for new language
;; variants, without having to keep up with the exact regexps etc that
;; are used in each CC Mode version.  It's possible from an external
;; package to add a new language, optionally by copying an existing
;; one, and then change specific constants as necessary for the new
;; language.  The old values for those constants (and the values of
;; all the other high-level constants) may be used to build the new
;; ones, and those new values will in turn be used by the low-level
;; definitions here to build the runtime constants appropriately for
;; the new language in the current version of CC Mode.
;;
;; Like elsewhere in CC Mode, the existence of a doc string signifies
;; that a language constant is part of the external API, and that it
;; therefore can be used with a high confidence that it will continue
;; to work with future versions of CC Mode.  Even so, it's not
;; unlikely that such constants will change meaning slightly as this
;; system is refined further; a certain degree of dependence on the CC
;; Mode version is unavoidable when hooking in at this level.  Also
;; note that there's still work to be done to actually use these
;; constants everywhere inside CC Mode; there are still hardcoded
;; values in many places in the code.
;;
;; Separate packages will also benefit from the compile time
;; evaluation; the byte compiled file(s) for them will contain the
;; compiled runtime constants ready for use by (the byte compiled) CC
;; Mode, and the source values in this file don't have to be loaded
;; then.  However, if a byte compiled package is loaded that has been
;; compiled with a different version of CC Mode than the one currently
;; loaded then the compiled-in values will be discarded and new ones
;; will be built when the mode is initialized.  That will
;; automatically trig a load of the file(s) containing the source
;; definitions (i.e. this file and/or cc-fonts.el) if necessary.
;;
;; A small example of a derived mode is available at
;; <http://cc-mode.sourceforge.net/derived-mode-ex.el>.  It also
;; contains some useful hints for derived mode developers.

;; This file is only required at compile time, or when not running
;; from byte compiled files, or when the source values for the
;; language constants are requested.

;; HELPME: Many of the language constants here are likely more or less
;; bogus for IDL.  The effects of the erroneous values in the language
;; handling are mostly negligible since the constants that actually
;; matter in the syntax detection code are mostly correct in the
;; situations they are used.  The effects in font locking are probably
;; more evident, though.  Please send code samples that are treated
;; incorrectly to bug-cc-mode@gnu.org.

;;; Code:

(eval-when-compile
  (let ((load-path
	 (if (and (boundp 'byte-compile-dest-file)
		  (stringp byte-compile-dest-file))
	     (cons (file-name-directory byte-compile-dest-file) load-path)
	   load-path)))
    (require 'cc-bytecomp)))

(cc-require 'cc-defs)
(cc-require 'cc-vars)

(require 'cl)


;;; Setup for the `c-lang-defvar' system.

(cc-eval-when-compile
  ;; These are used to collect the init forms from the subsequent
  ;; `c-lang-defvar'.  They are used to build the lambda in
  ;; `c-make-init-lang-vars-fun' below.
  (defconst c-lang-variable-inits (list nil))
  (defconst c-lang-variable-inits-tail c-lang-variable-inits)

  (defmacro c-lang-defvar (var val &optional doc)
    ;; Declares the buffer local variable VAR to get the value VAL at
    ;; mode initialization, at which point VAL is evaluated.
    ;; `c-lang-const' is typically used in VAL to get the right value
    ;; for the language being initialized, and such calls will be
    ;; macro expanded to the evaluated constant value at compile time.
    ;;
    ;; This function does not do any hidden buffer changes.

    (when (and (not doc)
	       (eq (car-safe val) 'c-lang-const)
	       (eq (nth 1 val) var)
	       (not (nth 2 val)))
      ;; Special case: If there's no docstring and the value is a
      ;; simple (c-lang-const foo) where foo is the same name as VAR
      ;; then take the docstring from the language constant foo.
      (setq doc (get (intern (symbol-name (nth 1 val)) c-lang-constants)
		     'variable-documentation)))
    (or (stringp doc)
	(setq doc nil))

    (let ((elem (assq var (cdr c-lang-variable-inits))))
      (if elem
	  (setcdr elem (list val doc))
	(setcdr c-lang-variable-inits-tail (list (list var val doc)))
	(setq c-lang-variable-inits-tail (cdr c-lang-variable-inits-tail))))

    ;; Return the symbol, like the other def* forms.
    `',var)

  (put 'c-lang-defvar 'lisp-indent-function 'defun)
  (eval-after-load "edebug"
    '(def-edebug-spec c-lang-defvar
       (&define name def-form &optional stringp))))


;;; Various mode specific values that aren't language related.

(c-lang-defconst c-mode-menu
  ;; The definition for the mode menu.  The menu title is prepended to
  ;; this before it's fed to `easy-menu-define'.
  t `(["Comment Out Region"     comment-region
       (c-fn-region-is-active-p)]
      ["Uncomment Region"       (comment-region (region-beginning)
						(region-end) '(4))
       (c-fn-region-is-active-p)]
      ["Indent Expression"      c-indent-exp
       (memq (char-after) '(?\( ?\[ ?\{))]
      ["Indent Line or Region"  c-indent-line-or-region t]
      ["Fill Comment Paragraph" c-fill-paragraph t]
      "----"
      ["Backward Statement"     c-beginning-of-statement t]
      ["Forward Statement"      c-end-of-statement t]
      ,@(when (c-lang-const c-opt-cpp-prefix)
	  ;; Only applicable if there's a cpp preprocessor.
	  `(["Up Conditional"         c-up-conditional t]
	    ["Backward Conditional"   c-backward-conditional t]
	    ["Forward Conditional"    c-forward-conditional t]
	    "----"
	    ["Macro Expand Region"    c-macro-expand
	     (c-fn-region-is-active-p)]
	    ["Backslashify"           c-backslash-region
	     (c-fn-region-is-active-p)]))
      "----"
      ("Toggle..."
       ["Syntactic indentation" c-toggle-syntactic-indentation t]
       ["Auto newline"          c-toggle-auto-state t]
       ["Hungry delete"         c-toggle-hungry-state t])))


;;; Syntax tables.

(defun c-populate-syntax-table (table)
  "Populate the given syntax table as necessary for a C-like language.
This includes setting ' and \" as string delimiters, and setting up
the comment syntax to handle both line style \"//\" and block style
\"/*\" \"*/\" comments."

  (modify-syntax-entry ?_  "_"     table)
  (modify-syntax-entry ?\\ "\\"    table)
  (modify-syntax-entry ?+  "."     table)
  (modify-syntax-entry ?-  "."     table)
  (modify-syntax-entry ?=  "."     table)
  (modify-syntax-entry ?%  "."     table)
  (modify-syntax-entry ?<  "."     table)
  (modify-syntax-entry ?>  "."     table)
  (modify-syntax-entry ?&  "."     table)
  (modify-syntax-entry ?|  "."     table)
  (modify-syntax-entry ?\' "\""    table)
  (modify-syntax-entry ?\240 "."   table)

  ;; Set up block and line oriented comments.  The new C
  ;; standard mandates both comment styles even in C, so since
  ;; all languages now require dual comments, we make this the
  ;; default.
  (cond
   ;; XEmacs
   ((memq '8-bit c-emacs-features)
    (modify-syntax-entry ?/  ". 1456" table)
    (modify-syntax-entry ?*  ". 23"   table))
   ;; Emacs
   ((memq '1-bit c-emacs-features)
    (modify-syntax-entry ?/  ". 124b" table)
    (modify-syntax-entry ?*  ". 23"   table))
   ;; incompatible
   (t (error "CC Mode is incompatible with this version of Emacs")))

  (modify-syntax-entry ?\n "> b"  table)
  ;; Give CR the same syntax as newline, for selective-display
  (modify-syntax-entry ?\^m "> b" table))

(c-lang-defconst c-make-mode-syntax-table
  "Functions that generates the mode specific syntax tables.
The syntax tables aren't stored directly since they're quite large."
  t `(lambda ()
       (let ((table (make-syntax-table)))
	 (c-populate-syntax-table table)
	 ;; Mode specific syntaxes.
	 ,(cond ((c-major-mode-is 'objc-mode)
		 `(modify-syntax-entry ?@ "_" table))
		((c-major-mode-is 'pike-mode)
		 `(modify-syntax-entry ?@ "." table)))
	 table)))

(c-lang-defconst c-mode-syntax-table
  ;; The syntax tables in evaluated form.  Only used temporarily when
  ;; the constants in this file are evaluated.
  t (funcall (c-lang-const c-make-mode-syntax-table)))

(c-lang-defconst make-c++-template-syntax-table
  ;; A variant of `c++-mode-syntax-table' that defines `<' and `>' as
  ;; parenthesis characters.  Used temporarily when template argument
  ;; lists are parsed.  Note that this encourages incorrect parsing of
  ;; templates since they might contain normal operators that uses the
  ;; '<' and '>' characters.  Therefore this syntax table might go
  ;; away when CC Mode handles templates correctly everywhere.
  t   nil
  c++ `(lambda ()
	 (let ((table (funcall ,(c-lang-const c-make-mode-syntax-table))))
	   (modify-syntax-entry ?< "(>" table)
	   (modify-syntax-entry ?> ")<" table)
	   table)))
(c-lang-defvar c++-template-syntax-table
  (and (c-lang-const make-c++-template-syntax-table)
       (funcall (c-lang-const make-c++-template-syntax-table))))

(c-lang-defconst c-identifier-syntax-modifications
  "A list that describes the modifications that should be done to the
mode syntax table to get a syntax table that matches all identifiers
and keywords as words.

The list is just like the one used in `font-lock-defaults': Each
element is a cons where the car is the character to modify and the cdr
the new syntax, as accepted by `modify-syntax-entry'."
  t    '((?_ . "w") (?$ . "w"))
  objc (append '((?@ . "w"))
	       (c-lang-const c-identifier-syntax-modifications)))
(c-lang-defvar c-identifier-syntax-modifications
  (c-lang-const c-identifier-syntax-modifications))

(c-lang-defvar c-identifier-syntax-table
  (let ((table (copy-syntax-table (c-mode-var "mode-syntax-table")))
	(mods c-identifier-syntax-modifications)
	mod)
    (while mods
      (setq mod (car mods)
	    mods (cdr mods))
      (modify-syntax-entry (car mod) (cdr mod) table))
    table)
  "Syntax table built on the mode syntax table but additionally
classifies symbol constituents like '_' and '$' as word constituents,
so that all identifiers are recognized as words.")


;;; Lexer-level syntax (identifiers, tokens etc).

(c-lang-defconst c-symbol-start
  "Regexp that matches the start of a symbol.
I.e. any identifier, not excluding keywords.  It's unspecified how far
it matches.  Does not contain a \\| operator at the top level."
  ;; This definition isn't correct for the first character in the
  ;; languages that accept the full range of Unicode word constituents
  ;; in identifiers (e.g. Java and Pike).  For that we'd need to make a
  ;; regexp that matches all characters in the word constituent class
  ;; except 0-9, and the regexp engine currently can't do that.
  t    "[_a-zA-Z]"
  pike "[_a-zA-Z`]")
(c-lang-defvar c-symbol-start (c-lang-const c-symbol-start))

(c-lang-defconst c-symbol-key
  "Regexp matching an identifier, not excluding keywords."
  ;; We cannot use just `word' syntax class since `_' cannot be in
  ;; word class.  Putting underscore in word class breaks forward word
  ;; movement behavior that users are familiar with.  Besides, it runs
  ;; counter to Emacs convention.
  t    "[_a-zA-Z]\\(\\w\\|\\s_\\)*"
  pike (concat (c-lang-const c-symbol-key) "\\|"
	       (c-make-keywords-re nil
		 (c-lang-const c-overloadable-operators))))
(c-lang-defvar c-symbol-key (c-lang-const c-symbol-key))

(c-lang-defconst c-symbol-key-depth
  ;; Number of regexp grouping parens in `c-symbol-key'.
  t (c-regexp-opt-depth (c-lang-const c-symbol-key)))

(c-lang-defconst c-nonsymbol-key
  "Regexp that matches any character that can't be part of a symbol.
It's usually appended to other regexps to avoid matching a prefix.
It's assumed to not contain any submatchers."
  ;; The same thing regarding Unicode identifiers applies here as to
  ;; `c-symbol-key'.
  t "[^_a-zA-Z0-9$]")

(c-lang-defconst c-opt-identifier-concat-key
  "Regexp matching the operators that join symbols to fully qualified
identifiers, or nil in languages that doesn't have such things.  Does
not contain a \\| operator at the top level."
  t    nil
  c++  "::"
  java "\\."
  pike "\\(::\\|\\.\\)")
(c-lang-defvar c-opt-identifier-concat-key
  (c-lang-const c-opt-identifier-concat-key)
  'dont-doc)

(c-lang-defconst c-identifier-start
  "Regexp that matches the start of an \(optionally qualified)
identifier.  It's unspecified how far it matches."
  t   (concat (c-lang-const c-symbol-start)
	      (if (c-lang-const c-opt-identifier-concat-key)
		  (concat "\\|" (c-lang-const c-opt-identifier-concat-key))
		""))
  c++ (concat (c-lang-const c-identifier-start)
	      "\\|"
	      "~[ \t\n\r\f\v]*" (c-lang-const c-symbol-start)))
(c-lang-defvar c-identifier-start (c-lang-const c-identifier-start))

(c-lang-defconst c-identifier-key
  "Regexp matching a fully qualified identifier, like \"A::B::c\" in
C++.  It does not recognize the full range of syntactic whitespace
between the tokens; `c-forward-name' has to be used for that."
  t    (c-lang-const c-symbol-key)	; Default to `c-symbol-key'.
  ;; C++ allows a leading qualifier operator and a `~' before the last
  ;; symbol.  This regexp is more complex than strictly necessary to
  ;; ensure that it can be matched with a minimum of backtracking.
  c++  (concat
	"\\(" (c-lang-const c-opt-identifier-concat-key) "[ \t\n\r\f\v]*\\)?"
	(concat
	 "\\("
	 ;; The submatch below is depth of `c-opt-identifier-concat-key' + 3.
	 "\\(" (c-lang-const c-symbol-key) "\\)"
	 (concat "\\("
		 "[ \t\n\r\f\v]*"
		 (c-lang-const c-opt-identifier-concat-key)
		 "[ \t\n\r\f\v]*"
		 ;; The submatch below is: `c-symbol-key-depth' +
		 ;; 2 * depth of `c-opt-identifier-concat-key' + 5.
		 "\\(" (c-lang-const c-symbol-key) "\\)"
		 "\\)*")
	 (concat "\\("
		 "[ \t\n\r\f\v]*"
		 (c-lang-const c-opt-identifier-concat-key)
		 "[ \t\n\r\f\v]*"
		 "~"
		 "[ \t\n\r\f\v]*"
		 ;; The submatch below is: 2 * `c-symbol-key-depth' +
		 ;; 3 * depth of `c-opt-identifier-concat-key' + 7.
		 "\\(" (c-lang-const c-symbol-key) "\\)"
		 "\\)?")
	 "\\|"
	 "~[ \t\n\r\f\v]*"
	 ;; The submatch below is: 3 * `c-symbol-key-depth' +
	 ;; 3 * depth of `c-opt-identifier-concat-key' + 8.
	 "\\(" (c-lang-const c-symbol-key) "\\)"
	 "\\)"))
  ;; Pike allows a leading qualifier operator.
  pike (concat
	"\\(" (c-lang-const c-opt-identifier-concat-key) "[ \t\n\r\f\v]*\\)?"
	;; The submatch below is depth of `c-opt-identifier-concat-key' + 2.
	"\\(" (c-lang-const c-symbol-key) "\\)"
	(concat "\\("
		"[ \t\n\r\f\v]*"
		(c-lang-const c-opt-identifier-concat-key)
		"[ \t\n\r\f\v]*"
		;; The submatch below is: `c-symbol-key-depth' +
		;; 2 * depth of `c-opt-identifier-concat-key' + 4.
		"\\(" (c-lang-const c-symbol-key) "\\)"
		"\\)*"))
  ;; Java does not allow a leading qualifier operator.
  java (concat "\\(" (c-lang-const c-symbol-key) "\\)" ; 1
	       (concat "\\("
		       "[ \t\n\r\f\v]*"
		       (c-lang-const c-opt-identifier-concat-key)
		       "[ \t\n\r\f\v]*"
		       ;; The submatch below is `c-symbol-key-depth' +
		       ;; depth of `c-opt-identifier-concat-key' + 3.
		       "\\(" (c-lang-const c-symbol-key) "\\)"
		       "\\)*")))
(c-lang-defvar c-identifier-key (c-lang-const c-identifier-key))

(c-lang-defconst c-identifier-last-sym-match
  "Used to identify the submatch in `c-identifier-key' that surrounds
the last symbol in the qualified identifier.  It's a list of submatch
numbers, of which the first that has a match is taken.  It's assumed
that at least one does when the regexp has matched."
  t    '(0)
  c++  (list (+ (* 3 (c-lang-const c-symbol-key-depth))
		(* 3 (c-regexp-opt-depth
		      (c-lang-const c-opt-identifier-concat-key)))
		8)
	     (+ (* 2 (c-lang-const c-symbol-key-depth))
		(* 3 (c-regexp-opt-depth
		      (c-lang-const c-opt-identifier-concat-key)))
		7)
	     (+ (c-lang-const c-symbol-key-depth)
		(* 2 (c-regexp-opt-depth
		      (c-lang-const c-opt-identifier-concat-key)))
		5)
	     (+ (c-regexp-opt-depth
		 (c-lang-const c-opt-identifier-concat-key))
		3))
  pike (list (+ (c-lang-const c-symbol-key-depth)
		(* 2 (c-regexp-opt-depth
		      (c-lang-const c-opt-identifier-concat-key)))
		4)
	     (+ (c-regexp-opt-depth
		 (c-lang-const c-opt-identifier-concat-key))
		2))
  java (list (+ (c-lang-const c-symbol-key-depth)
		(c-regexp-opt-depth
		 (c-lang-const c-opt-identifier-concat-key))
		3)
	     1))
(c-lang-defvar c-identifier-last-sym-match
  (c-lang-const c-identifier-last-sym-match)
  'dont-doc)

(c-lang-defconst c-opt-cpp-prefix
  "Regexp matching the prefix of a cpp directive in the languages that
normally uses that macro preprocessor.  Tested at bol.  Assumed to not
contain any submatches."
  t nil
  (c c++ objc pike) "\\s *#\\s *")
(c-lang-defvar c-opt-cpp-prefix (c-lang-const c-opt-cpp-prefix))

(c-lang-defconst c-cpp-defined-fns
  ;; Name of functions in cpp expressions that take an identifier as
  ;; the argument.
  t    (if (c-lang-const c-opt-cpp-prefix)
	   '("defined"))
  pike '("defined" "efun" "constant"))

(c-lang-defconst c-operators
  "List describing all operators, along with their precedence and
associativity.  The order in the list corresponds to the precedence of
the operators: The operators in each element is a group with the same
precedence, and the group has higher precedence than the groups in all
following elements.  The car of each element describes the type of of
the operator group, and the cdr is a list of the operator tokens in
it.  The operator group types are:

'prefix         Unary prefix operators.
'postfix        Unary postfix operators.
'left-assoc     Binary left associative operators (i.e. a+b+c means (a+b)+c).
'right-assoc    Binary right associative operators (i.e. a=b=c means a=(b=c)).
'right-assoc-sequence
                Right associative operator that constitutes of a
                sequence of tokens that separate expressions.  All the
                tokens in the group are in this case taken as
                describing the sequence in one such operator, and the
                order between them is therefore significant.

Operators containing a character with paren syntax are taken to match
with a corresponding open/close paren somewhere else.  A postfix
operator with close paren syntax is taken to end a postfix expression
started somewhere earlier, rather than start a new one at point.  Vice
versa for prefix operators with open paren syntax.

Note that operators like \".\" and \"->\" which in language references
often are described as postfix operators are considered binary here,
since CC Mode treats every identifier as an expression."

  ;; There's currently no code in CC Mode that exploits all the info
  ;; in this variable; precedence, associativity etc are present as a
  ;; preparation for future work.

  t `(;; Preprocessor.
      ,@(when (c-lang-const c-opt-cpp-prefix)
	  `((prefix "#"
		    ,@(when (c-major-mode-is '(c-mode c++-mode))
			'("%:" "??=")))
	    (left-assoc "##"
			,@(when (c-major-mode-is '(c-mode c++-mode))
			    '("%:%:" "??=??=")))))

      ;; Primary.  Info duplicated in `c-opt-identifier-concat-key'
      ;; and `c-identifier-key'.
      ,@(cond ((c-major-mode-is 'c++-mode)
	       `((postfix-if-paren "<" ">") ; Templates.
		 (prefix "~" "??-" "compl")
		 (right-assoc "::")
		 (prefix "::")))
	      ((c-major-mode-is 'pike-mode)
	       `((left-assoc "::")
		 (prefix "::" "global" "predef")))
	      ((c-major-mode-is 'java-mode)
	       `(;; Not necessary since it's also in the postfix group below.
		 ;;(left-assoc ".")
		 (prefix "super"))))

      ;; Postfix.
      ,@(when (c-major-mode-is 'c++-mode)
	  ;; The following need special treatment.
	  `((prefix "dynamic_cast" "static_cast"
		    "reinterpret_cast" "const_cast" "typeid")))
      (left-assoc "."
		  ,@(unless (c-major-mode-is 'java-mode)
		      '("->")))
      (postfix "++" "--" "[" "]" "(" ")"
	       ,@(when (c-major-mode-is '(c-mode c++-mode))
		   '("<:" ":>" "??(" "??)")))

      ;; Unary.
      (prefix "++" "--" "+" "-" "!" "~"
	      ,@(when (c-major-mode-is 'c++-mode) '("not" "compl"))
	      ,@(when (c-major-mode-is '(c-mode c++-mode))
		  '("*" "&" "sizeof" "??-"))
	      ,@(when (c-major-mode-is 'objc-mode)
		  '("@selector" "@protocol" "@encode"))
	      ;; The following need special treatment.
	      ,@(cond ((c-major-mode-is 'c++-mode)
		       '("new" "delete"))
		      ((c-major-mode-is 'java-mode)
		       '("new"))
		      ((c-major-mode-is 'pike-mode)
		       '("class" "lambda" "catch" "throw" "gauge")))
	      "(" ")")			; Cast.

      ;; Member selection.
      ,@(when (c-major-mode-is 'c++-mode)
	  `((left-assoc ".*" "->*")))

      ;; Multiplicative.
      (left-assoc "*" "/" "%")

      ;; Additive.
      (left-assoc "+" "-")

      ;; Shift.
      (left-assoc "<<" ">>"
		  ,@(when (c-major-mode-is 'java-mode)
		      '(">>>")))

      ;; Relational.
      (left-assoc "<" ">" "<=" ">="
		  ,@(when (c-major-mode-is 'java-mode)
		      '("instanceof")))

      ;; Equality.
      (left-assoc "==" "!="
		  ,@(when (c-major-mode-is 'c++-mode) '("not_eq")))

      ;; Bitwise and.
      (left-assoc "&"
		  ,@(when (c-major-mode-is 'c++-mode) '("bitand")))

      ;; Bitwise exclusive or.
      (left-assoc "^"
		  ,@(when (c-major-mode-is '(c-mode c++-mode))
		      '("??'"))
		  ,@(when (c-major-mode-is 'c++-mode) '("xor")))

      ;; Bitwise or.
      (left-assoc "|"
		  ,@(when (c-major-mode-is '(c-mode c++-mode))
		      '("??!"))
		  ,@(when (c-major-mode-is 'c++-mode) '("bitor")))

      ;; Logical and.
      (left-assoc "&&"
		  ,@(when (c-major-mode-is 'c++-mode) '("and")))

      ;; Logical or.
      (left-assoc "||"
		  ,@(when (c-major-mode-is '(c-mode c++-mode))
		      '("??!??!"))
		  ,@(when (c-major-mode-is 'c++-mode) '("or")))

      ;; Conditional.
      (right-assoc-sequence "?" ":")

      ;; Assignment.
      (right-assoc "=" "*=" "/=" "%=" "+=" "-=" ">>=" "<<=" "&=" "^=" "|="
		   ,@(when (c-major-mode-is 'java-mode)
		       '(">>>="))
		   ,@(when (c-major-mode-is 'c++-mode)
		       '("and_eq" "or_eq" "xor_eq")))

      ;; Exception.
      ,@(when (c-major-mode-is 'c++-mode)
	  '((prefix "throw")))

      ;; Sequence.
      (left-assoc ",")))

(c-lang-defconst c-operator-list
  ;; The operators as a flat list (without duplicates).
  t (delete-duplicates (mapcan (lambda (elem) (append (cdr elem) nil))
			       (c-lang-const c-operators))
		       :test 'string-equal))

(c-lang-defconst c-overloadable-operators
  "List of the operators that are overloadable, in their \"identifier form\"."
  t    nil
  c++  '("new" "delete" ;; Can be followed by "[]" but we ignore that.
	 "+" "-" "*" "/" "%"
	 "^" "??'" "xor" "&" "bitand" "|" "??!" "bitor" "~" "??-" "compl"
	 "!" "=" "<" ">" "+=" "-=" "*=" "/=" "%=" "^="
	 "??'=" "xor_eq" "&=" "and_eq" "|=" "??!=" "or_eq"
	 "<<" ">>" ">>=" "<<=" "==" "!=" "not_eq" "<=" ">="
	 "&&" "and" "||" "??!??!" "or" "++" "--" "," "->*" "->"
	 "()" "[]" "<::>" "??(??)")
  ;; These work like identifiers in Pike.
  pike '("`+" "`-" "`&" "`|" "`^" "`<<" "`>>" "`*" "`/" "`%" "`~"
	 "`==" "`<" "`>" "`!" "`[]" "`[]=" "`->" "`->=" "`()" "``+"
	 "``-" "``&" "``|" "``^" "``<<" "``>>" "``*" "``/" "``%"
	 "`+="))

(c-lang-defconst c-overloadable-operators-regexp
  ;; Regexp tested after an "operator" token in C++.
  t   nil
  c++ (c-make-keywords-re nil (c-lang-const c-overloadable-operators)))
(c-lang-defvar c-overloadable-operators-regexp
  (c-lang-const c-overloadable-operators-regexp))

(c-lang-defconst c-other-op-syntax-tokens
  "List of the tokens made up of characters in the punctuation or
parenthesis syntax classes that have uses other than as expression
operators."
  t '("{" "}" "(" ")" "[" "]" ";" ":" "," "=" "/*" "*/" "//")
  (c c++ pike) (append '("#" "##"	; Used by cpp.
			 "::" "...")
		       (c-lang-const c-other-op-syntax-tokens))
  (c c++) (append '("<%" "%>" "<:" ":>" "%:" "%:%:" "*")
		  (c-lang-const c-other-op-syntax-tokens))
  c++  (append '("&") (c-lang-const c-other-op-syntax-tokens))
  objc (append '("#" "##"		; Used by cpp.
		 "+" "-") (c-lang-const c-other-op-syntax-tokens))
  pike (append '("..")
	       (c-lang-const c-other-op-syntax-tokens)
	       (c-lang-const c-overloadable-operators)))

(c-lang-defconst c-nonsymbol-token-regexp
  ;; Regexp matching all tokens in the punctuation and parenthesis
  ;; syntax classes.
  t (c-make-keywords-re nil
      (c-with-syntax-table (c-lang-const c-mode-syntax-table)
	(mapcan (lambda (op)
		  (if (string-match "\\`\\(\\s.\\|\\s\(\\|\\s\)\\)+\\'" op)
		      (list op)))
		(append (c-lang-const c-other-op-syntax-tokens)
			(c-lang-const c-operator-list))))))
(c-lang-defvar c-nonsymbol-token-regexp
  (c-lang-const c-nonsymbol-token-regexp))

(c-lang-defconst c-<-op-cont-regexp
  ;; Regexp matching the second and subsequent characters of all
  ;; multicharacter tokens that begin with "<".
  t (c-make-keywords-re nil
      (mapcan (lambda (op)
		(if (string-match "\\`<." op)
		    (list (substring op 1))))
	      (append (c-lang-const c-other-op-syntax-tokens)
		      (c-lang-const c-operator-list)))))
(c-lang-defvar c-<-op-cont-regexp (c-lang-const c-<-op-cont-regexp))

(c-lang-defconst c->-op-cont-regexp
  ;; Regexp matching the second and subsequent characters of all
  ;; multicharacter tokens that begin with ">".
  t (c-make-keywords-re nil
      (mapcan (lambda (op)
		(if (string-match "\\`>." op)
		    (list (substring op 1))))
	      (append (c-lang-const c-other-op-syntax-tokens)
		      (c-lang-const c-operator-list)))))
(c-lang-defvar c->-op-cont-regexp (c-lang-const c->-op-cont-regexp))

(c-lang-defvar c-stmt-delim-chars "^;{}?:")
;; The characters that should be considered to bound statements.  To
;; optimize `c-crosses-statement-barrier-p' somewhat, it's assumed to
;; begin with "^" to negate the set.  If ? : operators should be
;; detected then the string must end with "?:".

(c-lang-defvar c-stmt-delim-chars-with-comma "^;,{}?:")
;; Variant of `c-stmt-delim-chars' that additionally contains ','.


;;; Syntactic whitespace.

(c-lang-defconst c-comment-start-regexp
  ;; Regexp to match the start of any type of comment.
  ;;
  ;; TODO: Ought to use `c-comment-prefix-regexp' with some
  ;; modifications instead of this.
  ;;
  ;; Might seem like overkill to make this a language dependent
  ;; constant, but awk-mode is on its way..
  t "/[/*]")
(c-lang-defvar c-comment-start-regexp (c-lang-const c-comment-start-regexp))

(c-lang-defconst c-doc-comment-start-regexp
  "Regexp to match the start of documentation comments."
  t    "\\<\\>"
  ;; From font-lock.el: `doxygen' uses /*! while others use /**.
  (c c++ objc) "/\\*[*!]"
  java "/\\*\\*"
  pike "/[/*]!")
(c-lang-defvar c-doc-comment-start-regexp
  (c-lang-const c-doc-comment-start-regexp))

(c-lang-defconst comment-start
  "String that starts comments inserted with M-; etc.
`comment-start' is initialized from this."
  t "// "
  c "/* ")
(c-lang-defvar comment-start (c-lang-const comment-start)
  'dont-doc)

(c-lang-defconst comment-end
  "String that ends comments inserted with M-; etc.
`comment-end' is initialized from this."
  t ""
  c "*/")
(c-lang-defvar comment-end (c-lang-const comment-end)
  'dont-doc)

(c-lang-defvar c-syntactic-ws-start "[ \n\t\r\v\f#]\\|/[/*]\\|\\\\[\n\r]")
;; Regexp matching any sequence that can start syntactic whitespace.
;; The only uncertain case is '#' when there are cpp directives."

(c-lang-defvar c-syntactic-ws-end "[ \n\t\r\v\f/]")
;; Regexp matching any single character that might end syntactic
;; whitespace.

(c-lang-defconst c-nonwhite-syntactic-ws
  ;; Regexp matching a piece of syntactic whitespace that isn't a
  ;; sequence of simple whitespace characters.  As opposed to
  ;; `c-(forward|backward)-syntactic-ws', this doesn't regard cpp
  ;; directives as syntactic whitespace.
  t (concat "/" (concat
		 "\\("
		 "/[^\n\r]*[\n\r]"	; Line comment.
		 "\\|"
		 ;; Block comment. We intentionally don't allow line
		 ;; breaks in them to avoid going very far and risk
		 ;; running out of regexp stack; this regexp is
		 ;; intended to handle only short comments that
		 ;; might be put in the middle of limited constructs
		 ;; like declarations.
		 "\\*\\([^*\n\r]\\|\\*[^/\n\r]\\)*\\*/"
		 "\\)")
	    "\\|"
	    "\\\\[\n\r]"))		; Line continuations.

(c-lang-defconst c-syntactic-ws
  ;; Regexp matching syntactic whitespace, including possibly the
  ;; empty string.  As opposed to `c-(forward|backward)-syntactic-ws',
  ;; this doesn't regard cpp directives as syntactic whitespace.  Does
  ;; not contain a \| operator at the top level.
  t (concat "[ \t\n\r\f\v]*\\("
	    "\\(" (c-lang-const c-nonwhite-syntactic-ws) "\\)"
	    "[ \t\n\r\f\v]*\\)*"))

(c-lang-defconst c-syntactic-ws-depth
  ;; Number of regexp grouping parens in `c-syntactic-ws'.
  t (c-regexp-opt-depth (c-lang-const c-syntactic-ws)))

(c-lang-defconst c-nonempty-syntactic-ws
  ;; Regexp matching syntactic whitespace, which is at least one
  ;; character long.  As opposed to `c-(forward|backward)-syntactic-ws',
  ;; this doesn't regard cpp directives as syntactic whitespace.  Does
  ;; not contain a \| operator at the top level.
  t (concat "\\([ \t\n\r\f\v]\\|"
	    (c-lang-const c-nonwhite-syntactic-ws)
	    "\\)+"))

(c-lang-defconst c-nonempty-syntactic-ws-depth
  ;; Number of regexp grouping parens in `c-nonempty-syntactic-ws'.
  t (c-regexp-opt-depth (c-lang-const c-nonempty-syntactic-ws)))

(c-lang-defconst c-single-line-syntactic-ws
  ;; Regexp matching syntactic whitespace without any line breaks.  As
  ;; opposed to `c-(forward|backward)-syntactic-ws', this doesn't
  ;; regard cpp directives as syntactic whitespace.  Does not contain
  ;; a \| operator at the top level.
  t (concat "[ \t]*\\("
	    "/\\*\\([^*\n\r]\\|\\*[^/\n\r]\\)*\\*/" ; Block comment
	    "[ \t]*\\)*"))

(c-lang-defconst c-single-line-syntactic-ws-depth
  ;; Number of regexp grouping parens in `c-single-line-syntactic-ws'.
  t (c-regexp-opt-depth (c-lang-const c-single-line-syntactic-ws)))

(c-lang-defvar c-syntactic-eol
  ;; Regexp that matches when there is no syntactically significant
  ;; text before eol.  Macros are regarded as syntactically
  ;; significant text here.
  (concat (concat
	   ;; Match horizontal whitespace and block comments that
	   ;; doesn't contain newlines.
	   "\\(\\s \\|"
	   (concat "/\\*"
		   "\\([^*\n\r]\\|\\*[^/\n\r]\\)*"
		   "\\*/")
	   "\\)*")
	  (concat
	   ;; Match eol (possibly inside a block comment), or the
	   ;; beginning of a line comment.  Note: This has to be
	   ;; modified for awk where line comments start with '#'.
	   "\\("
	   (concat "\\("
		   "/\\*\\([^*\n\r]\\|\\*[^/\n\r]\\)*"
		   "\\)?"
		   "$")
	   "\\|//\\)")))


;;; In-comment text handling.

(c-lang-defconst c-paragraph-start
  "Regexp to append to `paragraph-start'."
  t    "$"
  java "\\(@[a-zA-Z]+\\>\\|$\\)"	; For Javadoc.
  pike "\\(@[a-zA-Z]+\\>\\([^{]\\|$\\)\\|$\\)") ; For Pike refdoc.
(c-lang-defvar c-paragraph-start (c-lang-const c-paragraph-start))

(c-lang-defconst c-paragraph-separate
  "Regexp to append to `paragraph-separate'."
  t    "$"
  pike (c-lang-const c-paragraph-start))
(c-lang-defvar c-paragraph-separate (c-lang-const c-paragraph-separate))

(c-lang-defconst c-in-comment-lc-prefix
  ;; Prefix added to `c-current-comment-prefix' to set
  ;; `c-opt-in-comment-lc', or nil if it should be nil.
  t    nil
  pike "@[\n\r]\\s *")

(c-lang-defvar c-opt-in-comment-lc
  ;; Regexp to match in-comment line continuations, or nil in
  ;; languages where that isn't applicable.  It's assumed that it only
  ;; might match from and including the last character on a line.
  ;; Built from `*-in-comment-lc-prefix' and the current value of
  ;; `c-current-comment-prefix'.
  (if (c-lang-const c-in-comment-lc-prefix)
      (concat (c-lang-const c-in-comment-lc-prefix)
	      c-current-comment-prefix)))


;;; Keywords.

(c-lang-defconst c-primitive-type-kwds
  "Primitive type keywords, excluding those on `c-complex-type-kwds'."
  t    '("char" "double" "float" "int" "long" "short" "signed"
	 "unsigned" "void")
  c    (append '("complex" "imaginary")	; Conditionally defined in C99.
	       (c-lang-const c-primitive-type-kwds))
  c++  (append '("bool" "wchar_t")
	       (c-lang-const c-primitive-type-kwds))
  ;; Objective-C extends C, but probably not the new stuff in C99.
  objc (append '("id" "Class" "SEL" "IMP" "BOOL")
	       (c-lang-const c-primitive-type-kwds))
  java '("boolean" "byte" "char" "double" "float" "int" "long" "short" "void")
  pike '(;; this_program isn't really a keyword, but it's practically
	 ;; used as a builtin type.
	 "float" "mixed" "string" "this_program" "void"))

(c-lang-defconst c-primitive-type-key
  ;; An adorned regexp that matches `c-primitive-type-kwds'.
  t (c-make-keywords-re t (c-lang-const c-primitive-type-kwds)))
(c-lang-defvar c-primitive-type-key (c-lang-const c-primitive-type-key))

(c-lang-defconst c-primitive-type-prefix-kwds
  "Keywords that might act as prefixes for primitive types.  Note that
this is assumed to be a subset of `c-primitive-type-kwds'."
  t nil
  (c c++) '("long" "short" "signed" "unsigned"))

(c-lang-defconst c-complex-type-kwds
  "Keywords that can precede a parenthesis that contains a complex
type, e.g. \"mapping(int:string)\" in Pike."
  t    nil
  pike '("array" "function" "int" "mapping" "multiset" "object" "program"))

(c-lang-defconst c-opt-complex-type-key
  ;; An adorned regexp that matches `c-complex-type-kwds', or nil in
  ;; languages without such things.
  t (and (c-lang-const c-complex-type-kwds)
	 (c-make-keywords-re t (c-lang-const c-complex-type-kwds))))
(c-lang-defvar c-opt-complex-type-key (c-lang-const c-opt-complex-type-key))

(c-lang-defconst c-type-kwds
  ;; All keywords that are primitive types, i.e. the union of
  ;; `c-primitive-type-kwds' and `c-complex-type-kwds'.
  t (if (c-lang-const c-complex-type-kwds)
	;; Don't need `delete-duplicates' since these two are
	;; defined to be exclusive.
	(append (c-lang-const c-primitive-type-kwds)
		(c-lang-const c-complex-type-kwds))
      (c-lang-const c-primitive-type-kwds)))

(c-lang-defconst c-type-prefix-kwds
  "Keywords where the following name - if any - is a type name, and
where the keyword together with the symbol works as a type in
declarations."
  t    nil
  c    '("struct" "union" "enum")
  c++  '("class" "struct" "typename" "union" "enum")
  objc '("struct" "union" "enum"
	 "@interface" "@implementation" "@protocol")
  java '("class")
  pike '("class" "enum"))

(c-lang-defconst c-type-prefix-key
  ;; Adorned regexp matching `c-type-prefix-kwds'.
  t (c-make-keywords-re t (c-lang-const c-type-prefix-kwds)))
(c-lang-defvar c-type-prefix-key (c-lang-const c-type-prefix-key))

(c-lang-defconst c-type-modifier-kwds
  "Type modifier keywords.  These can occur almost anywhere in types
but they don't build a type of themselves.  They are fontified like
keywords, similar to `c-specifier-kwds'."
  t    nil
  c    '("const" "restrict" "volatile")
  c++  '("const" "volatile" "throw")
  objc '("const" "volatile"))

(c-lang-defconst c-opt-type-modifier-key
  ;; Adorned regexp matching `c-type-modifier-kwds', or nil in
  ;; languages without such keywords.
  t (and (c-lang-const c-type-modifier-kwds)
	 (c-make-keywords-re t (c-lang-const c-type-modifier-kwds))))
(c-lang-defvar c-opt-type-modifier-key (c-lang-const c-opt-type-modifier-key))

(c-lang-defconst c-opt-type-component-key
  ;; An adorned regexp that matches `c-primitive-type-prefix-kwds' and
  ;; `c-type-modifier-kwds', or nil in languages without any of them.
  t (and (or (c-lang-const c-primitive-type-prefix-kwds)
	     (c-lang-const c-type-modifier-kwds))
	 (c-make-keywords-re t
	   (append (c-lang-const c-primitive-type-prefix-kwds)
		   (c-lang-const c-type-modifier-kwds)))))
(c-lang-defvar c-opt-type-component-key
  (c-lang-const c-opt-type-component-key))

(c-lang-defconst c-specifier-kwds
  "Declaration specifier keywords.  These are keywords that may
prefix declarations but that aren't part of a type, e.g. \"struct\" in
C isn't a specifier since the whole \"struct foo\" is a type, but
\"typedef\" is since it precedes the declaration that defines the
type."
  t nil
  (c c++) '("auto" "extern" "inline" "register" "typedef" "static")
  c++  (append '("explicit" "friend" "mutable" "template" "virtual")
	       (c-lang-const c-specifier-kwds))
  objc '("auto" "extern" "typedef" "static"
	 "bycopy" "byref" "in" "inout" "oneway" "out")
  ;; I have no idea about IDL, so just use the specifiers in C.
  idl  (c-lang-const c-specifier-kwds c)
  ;; Note: "const" is not used in Java, but it's still a reserved keyword.
  java '("abstract" "const" "final" "native" "private" "protected"
	 "public" "static" "strictfp" "synchronized" "transient" "volatile")
  pike '("constant" "final" "inline" "local" "nomask" "optional"
	 "private" "protected" "public" "static" "typedef" "variant"))

(c-lang-defconst c-specifier-key
  ;; `c-specifier-kwds' as an adorned regexp.
  t (c-make-keywords-re t (c-lang-const c-specifier-kwds)))
(c-lang-defvar c-specifier-key (c-lang-const c-specifier-key))

(c-lang-defconst c-typedef-specifier-kwds
  "Declaration specifier keywords that causes the declaration to
declare the identifiers in it as types.  Assumed to be a subset of
`c-specifier-kwds'."
  t nil
  (c c++ objc pike) '("typedef"))

(c-lang-defconst c-typedef-specifier-key
  ;; `c-typedef-specifier-kwds' as an adorned regexp.
  t (c-make-keywords-re t (c-lang-const c-typedef-specifier-kwds)))
(c-lang-defvar c-typedef-specifier-key (c-lang-const c-typedef-specifier-key))

(c-lang-defconst c-protection-kwds
  "Protection label keywords in classes."
  t nil
  c++  '("private" "protected" "public")
  objc '("@private" "@protected" "@public"))

(c-lang-defconst c-opt-access-key
  ;; Regexp matching an access protection label in a class, or nil in
  ;; languages that doesn't have such things.
  t    (if (c-lang-const c-protection-kwds)
	   (c-make-keywords-re t (c-lang-const c-protection-kwds)))
  c++  (concat "\\("
	       (c-make-keywords-re nil (c-lang-const c-protection-kwds))
	       "\\)[ \t\n\r\f\v]*:"))
(c-lang-defvar c-opt-access-key (c-lang-const c-opt-access-key))

(c-lang-defconst c-class-kwds
  "Class/struct declaration keywords."
  t    nil
  c    '("struct" "union")
  c++  '("class" "struct" "union")
  objc '("struct" "union"
	 "@interface" "@implementation" "@protocol")
  java '("class" "interface")
  idl  '("class" "interface" "struct" "union" "valuetype")
  pike '("class"))

(c-lang-defconst c-class-key
  ;; Regexp matching the start of a class.
  t (c-make-keywords-re t (c-lang-const c-class-kwds)))
(c-lang-defvar c-class-key (c-lang-const c-class-key))

(c-lang-defconst c-brace-list-kwds
  "Keywords introducing declarations where the following block is a
brace list (containing identifier declarations)."
  t nil
  (c c++ objc pike) '("enum"))

(c-lang-defconst c-brace-list-key
  ;; Regexp matching the start of declarations where the following
  ;; block is a brace list.
  t (c-make-keywords-re t (c-lang-const c-brace-list-kwds)))
(c-lang-defvar c-brace-list-key (c-lang-const c-brace-list-key))

(c-lang-defconst c-other-decl-block-kwds
  "Keywords introducing blocks that contain another declaration level,
besides classes."
  t   nil
  c   '("extern")
  c++ '("namespace" "extern")
  idl '("module"))

(c-lang-defconst c-other-decl-block-key
  ;; Regexp matching the start of blocks besides classes that contain
  ;; another declaration level.
  t (c-make-keywords-re t (c-lang-const c-other-decl-block-kwds)))
(c-lang-defvar c-other-decl-block-key (c-lang-const c-other-decl-block-key))

(c-lang-defconst c-block-decls-with-vars
  "Keywords introducing declarations that can contain a block which
might be followed by variable declarations, e.g. like \"foo\" in
\"class Foo { ... } foo;\".  So if there is a block in a declaration
like that, it ends with the following ';' and not right away.

These keywords are assumed to be a subset of the union of
`c-class-kwds', `c-typedef-specifier-kwds' and
`c-other-decl-block-kwds'."
  t        nil
  (c objc) '("struct" "union" "enum" "typedef")
  c++      '("class" "struct" "union" "enum" "typedef"))

(c-lang-defconst c-opt-block-decls-with-vars-key
  ;; Regexp matching the `c-block-decls-with-vars' keywords, or nil in
  ;; languages without such constructs.
  t (and (c-lang-const c-block-decls-with-vars)
	 (c-make-keywords-re t (c-lang-const c-block-decls-with-vars))))
(c-lang-defvar c-opt-block-decls-with-vars-key
  (c-lang-const c-opt-block-decls-with-vars-key))

(c-lang-defconst c-other-decl-kwds
  "Keywords introducing declarations that has not been accounted for by
any other keyword list that can be applied at the beginning of a
declaration.  They are: `c-primitive-type-kwds',
`c-complex-type-kwds', `c-type-prefix-kwds', `c-type-modifier-kwds',
`c-specifier-kwds', `c-typedef-specifier-kwds', `c-protection-kwds',
`c-class-kwds', `c-other-decl-block-kwds'."
  t    nil
  c++  '("using")
  objc '("@class" "@end" "@defs")
  java '("import" "package")
  pike '("import" "inherit"))

(c-lang-defconst c-decl-spec-kwds
  "Keywords introducing extra declaration specifiers in the region
between the header and the body \(i.e. the \"K&R-region\") in
declarations.  These are all followed by comma separated lists of type
names."
  t    nil
  java '("extends" "implements" "throws"))

(c-lang-defconst c-<>-arglist-kwds
  "Keywords that can be followed by a C++ style template arglist; see
`c-recognize-<>-arglists' for details.  That language constant is
assumed to be set if this isn't nil."
  t    nil
  c++  '("template")
  objc '("id")
  idl  '())

(c-lang-defconst c-<>-arglist-key
  ;; `c-<>-arglist-kwds' as an adorned regexp.
  t (c-make-keywords-re t (c-lang-const c-<>-arglist-kwds)))
(c-lang-defvar c-<>-arglist-key (c-lang-const c-<>-arglist-key))

(c-lang-defconst c-block-stmt-1-kwds
  "Statement keywords followed directly by a substatement."
  t    '("do" "else")
  c++  '("do" "else" "try")
  java '("do" "else" "finally" "try"))

(c-lang-defconst c-block-stmt-1-key
  ;; Regexp matching the start of any statement followed directly by a
  ;; substatement (doesn't match a bare block, however).
  t (c-make-keywords-re t (c-lang-const c-block-stmt-1-kwds)))
(c-lang-defvar c-block-stmt-1-key (c-lang-const c-block-stmt-1-key))

(c-lang-defconst c-block-stmt-2-kwds
  "Statement keywords followed by a paren sexp and then by a substatement."
  t    '("for" "if" "switch" "while")
  c++  '("for" "if" "switch" "while" "catch")
  java '("for" "if" "switch" "while" "catch" "synchronized")
  pike '("for" "if" "switch" "while" "foreach"))

(c-lang-defconst c-block-stmt-2-key
  ;; Regexp matching the start of any statement followed by a paren sexp
  ;; and then by a substatement.
  t (c-make-keywords-re t (c-lang-const c-block-stmt-2-kwds)))
(c-lang-defvar c-block-stmt-2-key (c-lang-const c-block-stmt-2-key))

(c-lang-defconst c-opt-block-stmt-key
  ;; Regexp matching the start of any statement that has a
  ;; substatement (except a bare block).  Nil in languages that
  ;; doesn't have such constructs.
  t (if (or (c-lang-const c-block-stmt-1-kwds)
	    (c-lang-const c-block-stmt-2-kwds))
	(c-make-keywords-re t
	  (append (c-lang-const c-block-stmt-1-kwds)
		  (c-lang-const c-block-stmt-2-kwds)))))
(c-lang-defvar c-opt-block-stmt-key (c-lang-const c-opt-block-stmt-key))

(c-lang-defconst c-simple-stmt-kwds
  "Statement keywords followed by an expression or nothing."
  t    '("break" "continue" "goto" "return")
  ;; Note: `goto' is not valid in Java, but the keyword is still reserved.
  java '("break" "continue" "goto" "return" "throw")
  pike '("break" "continue" "return"))

(c-lang-defconst c-paren-stmt-kwds
  "Statement keywords followed by a parenthesis expression that
nevertheless contains a list separated with ';' and not ','."
  t '("for"))

(c-lang-defconst c-paren-stmt-key
  ;; Adorned regexp matching `c-paren-stmt-kwds'.
  t (c-make-keywords-re t (c-lang-const c-paren-stmt-kwds)))
(c-lang-defvar c-paren-stmt-key (c-lang-const c-paren-stmt-key))

(c-lang-defconst c-asm-stmt-kwds
  "Statement keywords followed by an assembler expression."
  t nil
  (c c++) '("asm" "__asm__")) ;; Not standard, but common.

(c-lang-defconst c-opt-asm-stmt-key
  ;; Regexp matching the start of an assembler statement.  Nil in
  ;; languages that doesn't support that.
  t (if (c-lang-const c-asm-stmt-kwds)
	(c-make-keywords-re t (c-lang-const c-asm-stmt-kwds))))
(c-lang-defvar c-opt-asm-stmt-key (c-lang-const c-opt-asm-stmt-key))

(c-lang-defconst c-label-kwds
  "Keywords introducing labels in blocks."
  t   '("case" "default")
  idl nil)

(c-lang-defconst c-before-label-kwds
  "Keywords that may be followed by a label or a label reference."
  t           '("case" "goto")
  (java pike) (append '("break" "continue")
		      (c-lang-const c-before-label-kwds))
  idl         nil)

(c-lang-defconst c-label-kwds-regexp
  ;; Regexp matching any keyword that introduces a label.
  t (c-make-keywords-re t (c-lang-const c-label-kwds)))
(c-lang-defvar c-label-kwds-regexp (c-lang-const c-label-kwds-regexp))

(c-lang-defconst c-constant-kwds
  "Keywords for constants."
  t       nil
  (c c++) '("NULL") ;; Not a keyword, but practically works as one.
  c++     (append '("false" "true")
		  (c-lang-const c-constant-kwds))
  objc    '("nil" "Nil")
  pike    '("UNDEFINED")) ;; Not a keyword, but practically works as one.

(c-lang-defconst c-expr-kwds
  "Keywords that can occur anywhere in expressions."
  ;; Start out with all keyword operators in `c-operators'.
  t    (c-with-syntax-table (c-lang-const c-mode-syntax-table)
	 (mapcan (lambda (op)
		   (and (string-match "\\`\\(\\w\\|\\s_\\)+\\'" op)
			(list op)))
		 (c-lang-const c-operator-list)))
  c++  (append '("operator" "this")
	       (c-lang-const c-expr-kwds))
  objc (append '("super" "self")
	       (c-lang-const c-expr-kwds))
  java (append '("this")
	       (c-lang-const c-expr-kwds))
  pike (append
	'("this") ;; Not really a keyword, but practically works as one.
	(c-lang-const c-expr-kwds)))

(c-lang-defconst c-lambda-kwds
  "Keywords that start lambda constructs, i.e. function definitions in
expressions."
  t    nil
  pike '("lambda"))

(c-lang-defconst c-opt-lambda-key
  ;; Adorned regexp matching the start of lambda constructs, or nil in
  ;; languages that doesn't have such things.
  t (and (c-lang-const c-lambda-kwds)
	 (c-make-keywords-re t (c-lang-const c-lambda-kwds))))
(c-lang-defvar c-opt-lambda-key (c-lang-const c-opt-lambda-key))

(c-lang-defconst c-inexpr-block-kwds
  "Keywords that start constructs followed by statement blocks which can
be used in expressions \(the gcc extension for this in C and C++ is
handled separately)."
  t    nil
  pike '("catch" "gauge"))

(c-lang-defconst c-opt-inexpr-block-key
  ;; Regexp matching the start of in-expression statements, or nil in
  ;; languages that doesn't have such things.
  t    nil
  pike (c-make-keywords-re t (c-lang-const c-inexpr-block-kwds)))
(c-lang-defvar c-opt-inexpr-block-key (c-lang-const c-opt-inexpr-block-key))

(c-lang-defconst c-inexpr-class-kwds
  "Keywords that can start classes inside expressions."
  t    nil
  java '("new")
  pike '("class"))

(c-lang-defconst c-opt-inexpr-class-key
  ;; Regexp matching the start of a class in an expression, or nil in
  ;; languages that doesn't have such things.
  t (and (c-lang-const c-inexpr-class-kwds)
	 (c-make-keywords-re t (c-lang-const c-inexpr-class-kwds))))
(c-lang-defvar c-opt-inexpr-class-key (c-lang-const c-opt-inexpr-class-key))

(c-lang-defconst c-inexpr-brace-list-kwds
  "Keywords that can start brace list blocks inside expressions.
Note that Java specific rules are currently applied to tell this from
`c-inexpr-class-kwds'."
  t    nil
  java '("new"))

(c-lang-defconst c-opt-inexpr-brace-list-key
  ;; Regexp matching the start of a brace list in an expression, or
  ;; nil in languages that doesn't have such things.  This should not
  ;; match brace lists recognized through `c-special-brace-lists'.
  t (and (c-lang-const c-inexpr-brace-list-kwds)
	 (c-make-keywords-re t (c-lang-const c-inexpr-brace-list-kwds))))
(c-lang-defvar c-opt-inexpr-brace-list-key
  (c-lang-const c-opt-inexpr-brace-list-key))

(c-lang-defconst c-any-class-key
  ;; Regexp matching the start of any class, both at top level and in
  ;; expressions.
  t (c-make-keywords-re t
      (append (c-lang-const c-class-kwds)
	      (c-lang-const c-inexpr-class-kwds))))
(c-lang-defvar c-any-class-key (c-lang-const c-any-class-key))

(c-lang-defconst c-decl-block-key
  ;; Regexp matching the start of any declaration-level block that
  ;; contain another declaration level, i.e. that isn't a function
  ;; block or brace list.
  t (c-make-keywords-re t
      (append (c-lang-const c-class-kwds)
	      (c-lang-const c-other-decl-block-kwds)
	      (c-lang-const c-inexpr-class-kwds))))
(c-lang-defvar c-decl-block-key (c-lang-const c-decl-block-key))

(c-lang-defconst c-bitfield-kwds
  "Keywords that can introduce bitfields."
  t nil
  (c c++ objc) '("char" "int" "long" "signed" "unsigned"))

(c-lang-defconst c-opt-bitfield-key
  ;; Regexp matching the start of a bitfield (not uniquely), or nil in
  ;; languages without bitfield support.
  t       nil
  (c c++) (c-make-keywords-re t (c-lang-const c-bitfield-kwds)))
(c-lang-defvar c-opt-bitfield-key (c-lang-const c-opt-bitfield-key))

(c-lang-defconst c-keywords
  ;; All keywords as a list.
  t (delete-duplicates (append (c-lang-const c-type-kwds)
			       (c-lang-const c-type-modifier-kwds)
			       (c-lang-const c-specifier-kwds)
			       (c-lang-const c-protection-kwds)
			       (c-lang-const c-class-kwds)
			       (c-lang-const c-brace-list-kwds)
			       (c-lang-const c-other-decl-block-kwds)
			       (c-lang-const c-block-decls-with-vars)
			       (c-lang-const c-type-prefix-kwds)
			       (c-lang-const c-other-decl-kwds)
			       (c-lang-const c-decl-spec-kwds)
			       (c-lang-const c-<>-arglist-kwds)
			       (c-lang-const c-block-stmt-1-kwds)
			       (c-lang-const c-block-stmt-2-kwds)
			       (c-lang-const c-simple-stmt-kwds)
			       (c-lang-const c-paren-stmt-kwds)
			       (c-lang-const c-asm-stmt-kwds)
			       (c-lang-const c-label-kwds)
			       (c-lang-const c-constant-kwds)
			       (c-lang-const c-expr-kwds)
			       (c-lang-const c-lambda-kwds)
			       (c-lang-const c-inexpr-block-kwds)
			       (c-lang-const c-inexpr-class-kwds)
			       (c-lang-const c-inexpr-brace-list-kwds)
			       (c-lang-const c-bitfield-kwds)
			       nil)
		       :test 'string-equal))

(c-lang-defconst c-keywords-regexp
  ;; All keywords as an adorned regexp.
  t (c-make-keywords-re t (c-lang-const c-keywords)))
(c-lang-defvar c-keywords-regexp (c-lang-const c-keywords-regexp))

(c-lang-defconst c-regular-keywords-regexp
  ;; Adorned regexp matching all keywords that aren't types or
  ;; constants.
  t (c-make-keywords-re t
      (set-difference (c-lang-const c-keywords)
		      (append (c-lang-const c-type-kwds)
			      (c-lang-const c-constant-kwds))
		      :test 'string-equal)))
(c-lang-defvar c-regular-keywords-regexp
  (c-lang-const c-regular-keywords-regexp))

(c-lang-defconst c-not-decl-init-keywords
  ;; Adorned regexp matching all keywords that can't appear at the
  ;; start of a declaration.
  t (c-make-keywords-re t
      (set-difference (c-lang-const c-keywords)
		      (append (c-lang-const c-type-kwds)
			      (c-lang-const c-type-prefix-kwds)
			      (c-lang-const c-type-modifier-kwds)
			      (c-lang-const c-specifier-kwds)
			      (c-lang-const c-class-kwds)
			      (c-lang-const c-other-decl-block-kwds)
			      (c-lang-const c-block-decls-with-vars)
			      (c-lang-const c-protection-kwds))
		      :test 'string-equal)))
(c-lang-defvar c-not-decl-init-keywords
  (c-lang-const c-not-decl-init-keywords))

(c-lang-defconst c-label-key
  "Regexp matching a normal label, i.e. a label that doesn't begin with
a keyword like switch labels.  It's only used at the beginning of a
statement."
  t "\\<\\>"
  (c c++ objc java pike) (concat "\\(" (c-lang-const c-symbol-key) "\\)"
				 "[ \t\n\r\f\v]*:\\([^:]\\|$\\)"))
(c-lang-defvar c-label-key (c-lang-const c-label-key)
  'dont-doc)

(c-lang-defconst c-opt-decl-spec-key
  ;; Regexp matching the beginning of a declaration specifier in the
  ;; region between the header and the body of a declaration.
  ;;
  ;; TODO: This is currently not used uniformly; c++-mode and
  ;; java-mode each have their own ways of using it.
  t nil
  c++ (concat ":?[ \t\n\r\f\v]*\\(virtual[ \t\n\r\f\v]+\\)?\\("
	      (c-make-keywords-re nil (c-lang-const c-protection-kwds))
	      "\\)[ \t\n\r\f\v]+"
	      "\\(" (c-lang-const c-symbol-key) "\\)")
  java (c-make-keywords-re t (c-lang-const c-decl-spec-kwds)))
(c-lang-defvar c-opt-decl-spec-key (c-lang-const c-opt-decl-spec-key))

(c-lang-defconst c-opt-friend-key
  ;; Regexp describing friend declarations classes, or nil in
  ;; languages that doesn't have such things.
  ;;
  ;; TODO: Ought to use `c-specifier-kwds' or similar, and the
  ;; template skipping isn't done properly.
  t nil
  c++ "friend[ \t]+\\|template[ \t]*<.+>[ \t]*friend[ \t]+")
(c-lang-defvar c-opt-friend-key (c-lang-const c-opt-friend-key))

(c-lang-defconst c-opt-method-key
  ;; Special regexp to match the start of Objective-C methods.  The
  ;; first submatch is assumed to end after the + or - key.
  t nil
  objc (concat
	;; TODO: Ought to use a better method than anchoring on bol.
	"^[ \t]*\\([+-]\\)[ \t\n\r\f\v]*"
	"\\(([^)]*)[ \t\n\r\f\v]*\\)?"	; return type
	"\\(" (c-lang-const c-symbol-key) "\\)"))
(c-lang-defvar c-opt-method-key (c-lang-const c-opt-method-key))


;;; Additional constants for parser-level constructs.

(c-lang-defconst c-decl-prefix-re
  "Regexp matching something that might precede a declaration or a cast,
such as the last token of a preceding statement or declaration.  It
should not match bob, though.  It can't require a match longer than
one token.  The end of the token is taken to be at the end of the
first submatch.  It must not include any following whitespace."
  ;; We match a sequence of characters to skip over things like \"};\"
  ;; more quickly.
  t "\\([\{\}\(;,]+\\)"
  ;; We additionally match ")" in C for K&R region declarations, and
  ;; in C, C++ and Objective-C for when a cpp macro definition begins
  ;; with a declaration.
  c "\\([\{\}\(\);,]+\\)"
  ;; Match open paren syntax in C++ to get the first argument in a
  ;; template arglist, where the "<" got that syntax.  This means that
  ;; "[" also is matched, which we really don't want.
  ;; `c-font-lock-declarations' has a special kludge to check for
  ;; that.
  ;;
  ;; Also match a single ":" for protection labels.  We cheat a little
  ;; and require a symbol immediately before to avoid false matches
  ;; when starting directly on a single ":", which can be the start of
  ;; a base class member initializer list.
  c++ "\\([\}\);,]+\\|\\s\(\\|\\(\\w\\|\\s_\\):\\)\\([^:]\\|\\'\\)"
  ;; Additionally match the protection directives in Objective-C.
  ;; Note that this doesn't cope with the longer directives, which we
  ;; would have to match from start to end since they don't end with
  ;; any easily recognized characters.
  objc (concat "\\([\{\}\(\);,]+\\|"
	       (c-make-keywords-re nil (c-lang-const c-protection-kwds))
	       "\\)")
  ;; Pike is like C but we also match "[" for multiple value
  ;; assignments and type casts.
  pike "\\([\{\}\(\)\[;,]+\\)")
(c-lang-defvar c-decl-prefix-re (c-lang-const c-decl-prefix-re)
  'dont-doc)

(c-lang-defconst c-opt-cast-close-paren-key
  "Regexp matching the close paren(s) of a cast, or nil in languages
without casts.  Note that the corresponding open paren(s) should be
matched by `c-decl-prefix-re'."
  t    nil
  (c c++ objc java) "\)"
  pike "[\]\)]")
(c-lang-defvar c-opt-cast-close-paren-key
  (c-lang-const c-opt-cast-close-paren-key)
  'dont-doc)

(c-lang-defconst c-type-decl-prefix-key
"Regexp matching the operators that might precede the identifier in a
declaration, e.g. the \"*\" in \"char *argv\".  This regexp should
match \"(\" if parentheses are valid in type declarations.  The end of
the first submatch is taken as the end of the operator."
  t    "\\<\\>" ;; Default to a regexp that never matches.
  (c objc) "\\([*\(]\\)\\($\\|[^=]\\)"
  c++  (concat "\\("
	       "[*\(&]"
	       "\\|"
	       (concat "\\("	; 3
		       ;; If this matches there's special treatment in
		       ;; `c-font-lock-declarators' and
		       ;; `c-font-lock-declarations' that check for a
		       ;; complete name followed by ":: *".
		       (c-lang-const c-identifier-start)
		       "\\)")
	       "\\|"
	       (c-make-keywords-re nil
		 (c-lang-const c-type-modifier-kwds)) "\\>"
	       "\\)"
	       "\\([^=]\\|$\\)")
  pike "\\([*\(!~]\\)\\($\\|[^=]\\)")
(c-lang-defvar c-type-decl-prefix-key (c-lang-const c-type-decl-prefix-key)
  'dont-doc)

(c-lang-defconst c-type-decl-suffix-key
  "Regexp matching the operators that might follow after the identifier
in a declaration, e.g. the \"[\" in \"char argv[]\".  This regexp
should match \")\" if parentheses are valid in type declarations.  If
it matches an open paren of some kind, the type declaration check
continues at the corresponding close paren, otherwise the end of the
first submatch is taken as the end of the operator."
  ;; Default to a regexp that matches only a function argument list
  ;; parenthesis.
  t    "\\(\(\\)"
  (c objc) "\\([\)\[\(]\\)"
  c++  (concat "\\("
	       "[\)\[\(]"
	       "\\|"
	       ;; "throw" in `c-type-modifier-kwds' is followed by a
	       ;; parenthesis list, but no extra measures are
	       ;; necessary to handle that.
	       "\\(" (c-make-keywords-re nil
		       (c-lang-const c-type-modifier-kwds)) "\\)\\>"
	       "\\)")
  java "\\([\[\(]\\)")
(c-lang-defvar c-type-decl-suffix-key (c-lang-const c-type-decl-suffix-key)
  'dont-doc)

(c-lang-defconst c-after-suffixed-type-decl-key
  "This regexp is matched after a type declaration expression where
`c-type-decl-suffix-key' has matched.  If it matches then the
construct is taken as a declaration.  It's typically used to match the
beginning of a function body or whatever might occur after the
function header in a function declaration or definition."
  t "{"
  ;; If K&R style declarations should be recognized then one could
  ;; consider to match the start of any symbol since we want to match
  ;; the start of the first declaration in the "K&R region".  That
  ;; could however produce false matches on code like "FOO(bar) x"
  ;; where FOO is a cpp macro.
  t (if (c-lang-const c-decl-spec-kwds)
	;; Add on the keywords in `c-decl-spec-kwds'.
	(concat (c-lang-const c-after-suffixed-type-decl-key)
		"\\|"
		(c-make-keywords-re t (c-lang-const c-decl-spec-kwds)))
      (c-lang-const c-after-suffixed-type-decl-key))
  ;; Also match the colon that starts a base class member initializer
  ;; list in C++.  That can be confused with a function call before
  ;; the colon in a ? : operator, but we count on that
  ;; `c-decl-prefix-re' won't match before such a thing (as a
  ;; declaration-level construct; matches inside arglist contexts are
  ;; already excluded).
  c++ "[{:]")
(c-lang-defvar c-after-suffixed-type-decl-key
  (c-lang-const c-after-suffixed-type-decl-key)
  'dont-doc)

(c-lang-defconst c-opt-type-concat-key
  "Regexp matching operators that concatenate types, e.g. the \"|\" in
\"int|string\" in Pike.  The end of the first submatch is taken as the
end of the operator.  nil in languages without such operators."
  t nil
  pike "\\([|.&]\\)\\($\\|[^|.&]\\)")
(c-lang-defvar c-opt-type-concat-key (c-lang-const c-opt-type-concat-key)
  'dont-doc)

(c-lang-defconst c-opt-type-suffix-key
  "Regexp matching operators that might follow after a type, or nil in
languages that doesn't have such operators.  The end of the first
submatch is taken as the end of the operator.  This should not match
things like C++ template arglists if `c-recognize-<>-arglists' is
set."
  t nil
  (c c++ objc pike) "\\(\\.\\.\\.\\)"
  java "\\(\\[[ \t\n\r\f\v]*\\]\\)")
(c-lang-defvar c-opt-type-suffix-key (c-lang-const c-opt-type-suffix-key))

(c-lang-defvar c-known-type-key
  ;; Regexp matching the known type identifiers.  This is initialized
  ;; from the type keywords and `*-font-lock-extra-types'.  The first
  ;; submatch is the one that matches the type.  Note that this regexp
  ;; assumes that symbol constituents like '_' and '$' have word
  ;; syntax.
  (let ((extra-types (c-mode-var "font-lock-extra-types")))
    (concat "\\<\\("
	    (c-make-keywords-re nil (c-lang-const c-type-kwds))
	    (if (consp extra-types)
		(concat "\\|" (mapconcat 'identity extra-types "\\|"))
	      "")
	    "\\)\\>")))

(c-lang-defconst c-special-brace-lists
"List of open- and close-chars that makes up a pike-style brace list,
i.e. for a ([ ]) list there should be a cons (?\\[ . ?\\]) in this
list."
  t    nil
  pike '((?{ . ?}) (?\[ . ?\]) (?< . ?>)))
(c-lang-defvar c-special-brace-lists (c-lang-const c-special-brace-lists))

(c-lang-defconst c-recognize-knr-p
  "Non-nil means K&R style argument declarations are valid."
  t nil
  c t)
(c-lang-defvar c-recognize-knr-p (c-lang-const c-recognize-knr-p))

(c-lang-defconst c-recognize-<>-arglists
  "Non-nil means C++ style template arglists should be handled.  More
specifically, this means a comma separated list of types or
expressions surrounded by \"<\" and \">\".  It's always preceded by an
identifier or one of the keywords on `c-<>-arglist-kwds'.  If there's
an identifier before then the whole expression is considered to be a
type."
  t (consp (c-lang-const c-<>-arglist-kwds)))
(c-lang-defvar c-recognize-<>-arglists (c-lang-const c-recognize-<>-arglists))

(c-lang-defconst c-opt-<>-arglist-start
  ;; Regexp matching the start of angle bracket arglists in languages
  ;; where `c-recognize-<>-arglists' is set.  Does not exclude
  ;; keywords outside `c-<>-arglist-kwds'.
  t (if (c-lang-const c-recognize-<>-arglists)
	(concat "\\("
		(c-lang-const c-symbol-key)
		"\\)"
		(c-lang-const c-syntactic-ws)
		"<")))
(c-lang-defvar c-opt-<>-arglist-start (c-lang-const c-opt-<>-arglist-start))


;;; Wrap up the `c-lang-defvar' system.

;; Compile in the list of language variables that has been collected
;; with the `c-lang-defvar' macro.  Note that the first element is
;; nil.
(defconst c-lang-variable-inits (cc-eval-when-compile c-lang-variable-inits))

(defun c-make-init-lang-vars-fun (mode)
  "Create a function that initializes all the language dependent variables
for the given mode.

This function should be evaluated at compile time, so that the
function it returns is byte compiled with all the evaluated results
from the language constants.  Use the `c-init-language-vars' macro to
accomplish that conveniently.

This function does not do any hidden buffer changes."

  (if (and (not load-in-progress)
	   (boundp 'byte-compile-dest-file)
	   (stringp byte-compile-dest-file))

      ;; No need to byte compile this lambda since the byte compiler is
      ;; smart enough to detect the `funcall' construct in the
      ;; `c-init-language-vars' macro below and compile it all straight
      ;; into the function that contains `c-init-language-vars'.
      `(lambda ()

	 ;; This let sets up the context for `c-mode-var' and similar
	 ;; that could be in the result from `cl-macroexpand-all'.
	 (let ((c-buffer-is-cc-mode ',mode))

	   (if (eq c-version-sym ',c-version-sym)
	       (setq ,@(let ((c-buffer-is-cc-mode mode)
			     (c-lang-const-expansion 'immediate))
			 ;; `c-lang-const' will expand to the evaluated
			 ;; constant immediately in `cl-macroexpand-all'
			 ;; below.
			 (mapcan
			  (lambda (init)
			    `(,(car init) ,(cl-macroexpand-all (elt init 1))))
			  (cdr c-lang-variable-inits))))

	     (unless (get ',mode 'c-has-warned-lang-consts)
	       (message ,(concat "%s compiled with CC Mode %s "
				 "but loaded with %s - evaluating "
				 "language constants from source")
			',mode ,c-version c-version)
	       (put ',mode 'c-has-warned-lang-consts t))

	     (require 'cc-langs)
	     (let ((init (cdr c-lang-variable-inits)))
	       (while init
		 (set (caar init) (eval (cadar init)))
		 (setq init (cdr init)))))))

    ;; Being evaluated from source.  Always use the dynamic method to
    ;; work well when `c-lang-defvar's in this file are reevaluated
    ;; interactively.
    `(lambda ()
       (require 'cc-langs)
       (let ((c-buffer-is-cc-mode ',mode)
	     (init (cdr c-lang-variable-inits)))
	 (while init
	   (set (caar init) (eval (cadar init)))
	   (setq init (cdr init)))))))

(defmacro c-init-language-vars (mode)
  "Initialize all the language dependent variables for the given mode.
This macro is expanded at compile time to a form tailored for the mode
in question, so MODE must be a constant.  Therefore MODE is not
evaluated and should not be quoted.

This function does not do any hidden buffer changes."
  `(funcall ,(c-make-init-lang-vars-fun mode)))


(cc-provide 'cc-langs)

;;; cc-langs.el ends here
