
;; Style definitions and manipulation functions
(defconst c-style-alist
  '(("gnu"
     (c-basic-offset . 2)
     (c-comment-only-line-offset . (0 . 0))
     (c-offsets-alist . ((statement-block-intro . +)
			 (knr-argdecl-intro . 5)
			 (substatement-open . +)
			 (label . 0)
			 (statement-case-open . +)
			 (statement-cont . +)
			 (arglist-intro . c-lineup-arglist-intro-after-paren)
			 (arglist-close . c-lineup-arglist)
			 ))
     (c-special-indent-hook . c-gnu-impose-minimum)
     )
    ("k&r"
     (c-basic-offset . 5)
     (c-comment-only-line-offset . 0)
     (c-offsets-alist . ((statement-block-intro . +)
			 (knr-argdecl-intro . 0)
			 (substatement-open . 0)
			 (label . 0)
			 (statement-cont . +)
			 ))
     )
    ("bsd"
     (c-basic-offset . 4)
     (c-comment-only-line-offset . 0)
     (c-offsets-alist . ((statement-block-intro . +)
			 (knr-argdecl-intro . +)
			 (substatement-open . 0)
			 (label . 0)
			 (statement-cont . +)
			 ))
     )
    ("stroustrup"
     (c-basic-offset . 4)
     (c-comment-only-line-offset . 0)
     (c-offsets-alist . ((statement-block-intro . +)
			 (substatement-open . 0)
			 (label . 0)
			 (statement-cont . +)
			 ))
     )
    ("whitesmith"
     (c-basic-offset . 4)
     (c-comment-only-line-offset . 0)
     (c-offsets-alist . ((statement-block-intro . +)
			 (knr-argdecl-intro . +)
			 (substatement-open . 0)
			 (label . 0)
			 (statement-cont . +)
			 ))

     )
    ("ellemtel"
     (c-basic-offset . 3)
     (c-comment-only-line-offset . 0)
     (c-hanging-braces-alist     . ((substatement-open before after)))
     (c-offsets-alist . ((topmost-intro        . 0)
                         (topmost-intro-cont   . 0)
                         (substatement         . +)
			 (substatement-open    . 0)
                         (case-label           . +)
                         (access-label         . -)
                         (inclass              . ++)
                         (inline-open          . 0)
                         ))
     )
    ("linux"
     (c-basic-offset  . 8)
     (c-comment-only-line-offset . 0)
     (c-hanging-braces-alist . ((brace-list-open)
				(substatement-open after)
				(block-close . c-snug-do-while)))
     (c-cleanup-list . (brace-else-brace))
     (c-offsets-alist . ((statement-block-intro . +)
			 (knr-argdecl-intro     . 0)
			 (substatement-open     . 0)
			 (label                 . 0)
			 (statement-cont        . +)
			 ))
     )
    ("python"
     (indent-tabs-mode . t)
     (fill-column      . 72)
     (c-basic-offset   . 8)
     (c-offsets-alist  . ((substatement-open . 0)
			  ))
     (c-hanging-braces-alist . ((brace-list-open)
				(brace-list-intro)
				(brace-list-close)
				(substatement-open after)
				(block-close . c-snug-do-while)
				))
     )
    ("java"
     (c-basic-offset . 2)
     (c-comment-only-line-offset . (0 . 0))
     (c-offsets-alist . ((statement-block-intro . +)
 			 (knr-argdecl-intro     . 5)
 			 (substatement-open     . +)
 			 (label                 . 0)
 			 (statement-case-open   . +)
 			 (statement-cont        . +)
 			 (arglist-intro . c-lineup-arglist-intro-after-paren)
 			 (arglist-close . c-lineup-arglist)
 			 (access-label  . 0)
			 (inher-cont    . c-lineup-java-inher)
			 ))

     )
    )
  "Styles of Indentation.
Elements of this alist are of the form:

  (STYLE-STRING (VARIABLE . VALUE) [(VARIABLE . VALUE) ...])

where STYLE-STRING is a short descriptive string used to select a
style, VARIABLE is any CC Mode variable, and VALUE is the intended
value for that variable when using the selected style.

There is one special case when VARIABLE is `c-offsets-alist'.  In this
case, the VALUE is a list containing elements of the form:

  (SYNTACTIC-SYMBOL . VALUE)

as described in `c-offsets-alist'.  These are passed directly to
`c-set-offset' so there is no need to set every syntactic symbol in
your style, only those that are different from the default.

Note that all styles inherit from the `cc-mode' style, which is
computed at the time the mode is loaded.")

(defconst c-offsets-alist
  '((string                . -1000)
    (c                     . c-lineup-C-comments)
    (defun-open            . 0)
    (defun-close           . 0)
    (defun-block-intro     . +)
    (class-open            . 0)
    (class-close           . 0)
    (inline-open           . +)
    (inline-close          . 0)
    (func-decl-cont        . +)
    (knr-argdecl-intro     . +)
    (knr-argdecl           . 0)
    (topmost-intro         . 0)
    (topmost-intro-cont    . 0)
    (member-init-intro     . +)
    (member-init-cont      . 0)
    (inher-intro           . +)
    (inher-cont            . c-lineup-multi-inher)
    (block-open            . 0)
    (block-close           . 0)
    (brace-list-open       . 0)
    (brace-list-close      . 0)
    (brace-list-intro      . +)
    (brace-list-entry      . 0)
    (statement             . 0)
    ;; some people might prefer
    ;;(statement             . c-lineup-runin-statements)
    (statement-cont        . +)
    ;; some people might prefer
    ;;(statement-cont        . c-lineup-math)
    (statement-block-intro . +)
    (statement-case-intro  . +)
    (statement-case-open   . 0)
    (substatement          . +)
    (substatement-open     . +)
    (case-label            . 0)
    (access-label          . -)
    (label                 . 2)
    (do-while-closure      . 0)
    (else-clause           . 0)
    (comment-intro         . c-lineup-comment)
    (arglist-intro         . +)
    (arglist-cont          . 0)
    (arglist-cont-nonempty . c-lineup-arglist)
    (arglist-close         . +)
    (stream-op             . c-lineup-streamop)
    (inclass               . +)
    (cpp-macro             . -1000)
    (friend                . 0)
    (objc-method-intro     . -1000)
    (objc-method-args-cont . c-lineup-ObjC-method-args)
    (objc-method-call-cont . c-lineup-ObjC-method-call)
    (extern-lang-open      . 0)
    (extern-lang-close     . 0)
    (inextern-lang         . +)
    )
  "*Association list of syntactic element symbols and indentation offsets.
As described below, each cons cell in this list has the form:

    (SYNTACTIC-SYMBOL . OFFSET)

When a line is indented, CC Mode first determines the syntactic
context of the line by generating a list of symbols called syntactic
elements.  This list can contain more than one syntactic element and
the global variable `c-syntactic-context' contains the context list
for the line being indented.  Each element in this list is actually a
cons cell of the syntactic symbol and a buffer position.  This buffer
position is called the relative indent point for the line.  Some
syntactic symbols may not have a relative indent point associated with
them.

After the syntactic context list for a line is generated, CC Mode
calculates the absolute indentation for the line by looking at each
syntactic element in the list.  First, it compares the syntactic
element against the SYNTACTIC-SYMBOL's in `c-offsets-alist'.  When it
finds a match, it adds the OFFSET to the column of the relative indent
point.  The sum of this calculation for each element in the syntactic
list is the absolute offset for line being indented.

If the syntactic element does not match any in the `c-offsets-alist',
an error is generated if `c-strict-syntax-p' is non-nil, otherwise the
element is ignored.

Actually, OFFSET can be an integer, a function, a variable, or one of
the following symbols: `+', `-', `++', `--', `*', or `/'.  These
latter designate positive or negative multiples of `c-basic-offset',
respectively: *1, *-1, *2, *-2, *0.5, and *-0.5. If OFFSET is a
function, it is called with a single argument containing the cons of
the syntactic element symbol and the relative indent point.  The
function should return an integer offset.

Here is the current list of valid syntactic element symbols:

 string                 -- inside multi-line string
 c                      -- inside a multi-line C style block comment
 defun-open             -- brace that opens a function definition
 defun-close            -- brace that closes a function definition
 defun-block-intro      -- the first line in a top-level defun
 class-open             -- brace that opens a class definition
 class-close            -- brace that closes a class definition
 inline-open            -- brace that opens an in-class inline method
 inline-close           -- brace that closes an in-class inline method
 func-decl-cont         -- the nether region between a function
                           declaration and the defun opening brace.
                           In C++ and Java, this can include `throws'
                           declarations
 knr-argdecl-intro      -- first line of a K&R C argument declaration
 knr-argdecl            -- subsequent lines in a K&R C argument declaration
 topmost-intro          -- the first line in a topmost construct definition
 topmost-intro-cont     -- topmost definition continuation lines
 member-init-intro      -- first line in a member initialization list
 member-init-cont       -- subsequent member initialization list lines
 inher-intro            -- first line of a multiple inheritance list
 inher-cont             -- subsequent multiple inheritance lines
 block-open             -- statement block open brace
 block-close            -- statement block close brace
 brace-list-open        -- open brace of an enum or static array list
 brace-list-close       -- close brace of an enum or static array list
 brace-list-intro       -- first line in an enum or static array list
 brace-list-entry       -- subsequent lines in an enum or static array list
 statement              -- a C (or like) statement
 statement-cont         -- a continuation of a C (or like) statement
 statement-block-intro  -- the first line in a new statement block
 statement-case-intro   -- the first line in a case `block'
 statement-case-open    -- the first line in a case block starting with brace
 substatement           -- the first line after an if/while/for/do/else
 substatement-open      -- the brace that opens a substatement block
 case-label             -- a case or default label
 access-label           -- C++ private/protected/public access label
 label                  -- any non-special C (or like) label
 do-while-closure       -- the `while' that ends a do/while construct
 else-clause            -- the `else' of an if/else construct
 comment-intro          -- a line containing only a comment introduction
 arglist-intro          -- the first line in an argument list
 arglist-cont           -- subsequent argument list lines when no
                           arguments follow on the same line as the
                           arglist opening paren
 arglist-cont-nonempty  -- subsequent argument list lines when at
                           least one argument follows on the same
                           line as the arglist opening paren
 arglist-close          -- the solo close paren of an argument list
 stream-op              -- lines continuing a stream operator construct
 inclass                -- the construct is nested inside a class definition
 cpp-macro              -- the start of a cpp macro
 friend                 -- a C++ friend declaration
 objc-method-intro      -- the first line of an Objective-C method definition
 objc-method-args-cont  -- lines continuing an Objective-C method definition
 objc-method-call-cont  -- lines continuing an Objective-C method call
 extern-lang-open       -- brace that opens an external language block
 extern-lang-close      -- brace that closes an external language block
 inextern-lang          -- analogous to `inclass' syntactic symbol
")


(defvar c-read-offset-history nil)

(defun c-read-offset (langelem)
  ;; read new offset value for LANGELEM from minibuffer. return a
  ;; legal value only
  (let* ((oldoff (cdr-safe (assq langelem c-offsets-alist)))
	 (defstr (format "(default %s): " oldoff))
	 (errmsg (concat "Offset must be int, func, var, "
			 "or in [+,-,++,--,*,/] "
			 defstr))
	 (prompt (concat "Offset " defstr))
	 offset input interned raw)
    (while (not offset)
      (setq input (completing-read prompt obarray 'fboundp nil nil
				   'c-read-offset-history)
	    offset (cond ((string-equal "" input) oldoff)  ; default
			 ((string-equal "+" input) '+)
			 ((string-equal "-" input) '-)
			 ((string-equal "++" input) '++)
			 ((string-equal "--" input) '--)
			 ((string-equal "*" input) '*)
			 ((string-equal "/" input) '/)
			 ((string-match "^-?[0-9]+$" input)
			  (string-to-int input))
			 ;; a symbol with a function binding
			 ((fboundp (setq interned (intern input)))
			  interned)
			 ;; a lambda function
			 ((condition-case nil
			      (c-functionp (setq raw (read input)))
			    (error nil))
			  raw)
			 ;; a symbol with variable binding
			 ((boundp interned) interned)
			 ;; error, but don't signal one, keep trying
			 ;; to read an input value
			 (t (ding)
			    (setq prompt errmsg)
			    nil))))
    offset))

(defun c-set-offset (symbol offset &optional add-p)
  "Change the value of a syntactic element symbol in `c-offsets-alist'.
SYMBOL is the syntactic element symbol to change and OFFSET is the new
offset for that syntactic element.  Optional ADD says to add SYMBOL to
`c-offsets-alist' if it doesn't already appear there."
  (interactive
   (let* ((langelem
	   (intern (completing-read
		    (concat "Syntactic symbol to change"
			    (if current-prefix-arg " or add" "")
			    ": ")
		    (mapcar
		     (function
		      (lambda (langelem)
			(cons (format "%s" (car langelem)) nil)))
		     c-offsets-alist)
		    nil (not current-prefix-arg)
		    ;; initial contents tries to be the last element
		    ;; on the syntactic analysis list for the current
		    ;; line
		    (let* ((syntax (c-guess-basic-syntax))
			   (len (length syntax))
			   (ic (format "%s" (car (nth (1- len) syntax)))))
		      (cons ic 0))
		    )))
	  (offset (c-read-offset langelem)))
     (list langelem offset current-prefix-arg)))
  ;; sanity check offset
  (or (eq offset '+)
      (eq offset '-)
      (eq offset '++)
      (eq offset '--)
      (eq offset '*)
      (eq offset '/)
      (integerp offset)
      (c-functionp offset)
      (boundp offset)
      (error "Offset must be int, func, var, or in [+,-,++,--,*,/]: %s"
	     offset))
  (let ((entry (assq symbol c-offsets-alist)))
    (if entry
	(setcdr entry offset)
      (if add-p
	  (setq c-offsets-alist (cons (cons symbol offset) c-offsets-alist))
	(error "%s is not a valid syntactic symbol." symbol))))
  (c-keep-region-active))

(defun c-set-style-1 (stylevars)
  ;; given a style's variable alist, institute the style
  (mapcar
   (function
    (lambda (conscell)
      (let ((attr (car conscell))
	    (val  (cdr conscell)))
	(cond
	 ((eq attr 'c-offsets-alist)
	  (mapcar
	   (function
	    (lambda (langentry)
	      (let ((langelem (car langentry))
		    (offset (cdr langentry)))
		(c-set-offset langelem offset)
		)))
	   val))
	 ((eq attr 'c-special-indent-hook)
	  (if (listp val)
	      (while val
		(add-hook 'c-special-indent-hook (car val))
		(setq val (cdr val)))
	    (add-hook 'c-special-indent-hook val)))
	 (t (set attr val)))
	)))
   stylevars))

(defvar c-set-style-history nil)

;;;###autoload
(defun c-set-style (stylename)
  "Set CC Mode variables to use one of several different indentation styles.
STYLENAME is a string representing the desired style from the list of
styles described in the variable `c-style-alist'.  See that variable
for details of setting up styles.

The variable `c-indentation-style' always contains the buffer's current
style name."
  (interactive (list (let ((completion-ignore-case t)
			   (prompt (format "Which %s indentation style? "
					   mode-name)))
		       (completing-read prompt c-style-alist nil t
					(cons c-indentation-style 0)
					'c-set-style-history))))
  (let ((vars (cdr (or (assoc (downcase stylename) c-style-alist)
		       (assoc (upcase stylename) c-style-alist)
		       (assoc stylename c-style-alist)
		       )))
	(default (cdr (assoc "cc-mode" c-style-alist))))
    (or vars (error "Invalid indentation style `%s'" stylename))
    (or default (error "No `cc-mode' style found!"))
    ;; first reset the style to `cc-mode' to give every style a common
    ;; base. Then institute the new style.
    (c-set-style-1 default)
    (setq c-indentation-style stylename)
    (if (not (string= stylename "cc-mode"))
	(c-set-style-1 vars)))
  (c-keep-region-active))

;;;###autoload
(defun c-add-style (style descrip &optional set-p)
  "Adds a style to `c-style-alist', or updates an existing one.
STYLE is a string identifying the style to add or update.  DESCRIP is
an association list describing the style and must be of the form:

  ((VARIABLE . VALUE) [(VARIABLE . VALUE) ...])

See the variable `c-style-alist' for the semantics of VARIABLE and
VALUE.  This function also sets the current style to STYLE using
`c-set-style' if the optional SET-P flag is non-nil."
  (interactive
   (let ((stylename (completing-read "Style to add: " c-style-alist))
	 (description (eval-minibuffer "Style description: ")))
     (list stylename description
	   (y-or-n-p "Set the style too? "))))
  (setq style (downcase style))
  (let ((s (assoc style c-style-alist)))
    (if s
	(setcdr s (copy-alist descrip))	; replace
      (setq c-style-alist (cons (cons style descrip) c-style-alist))))
  (and set-p (c-set-style style)))


;; Dynamically append the default value of most variables. This is
;; crucial because future c-set-style calls will always reset the
;; variables first to the `cc-mode' style before instituting the new
;; style.  Only do this once!
(or (assoc "cc-mode" c-style-alist)
    (progn
      (c-add-style "cc-mode"
		   (mapcar
		    (function
		     (lambda (var)
		       (let ((val (symbol-value var)))
			 (cons var (if (atom val) val
				     (c-copy-tree val)
				     ))
			 )))
		    '(c-backslash-column
		      c-basic-offset
		      c-cleanup-list
		      c-comment-only-line-offset
		      c-electric-pound-behavior
		      c-hanging-braces-alist
		      c-hanging-colons-alist
		      c-hanging-comment-starter-p
		      c-hanging-comment-ender-p
		      c-offsets-alist
		      )))
      ;; the default style is now GNU.  This can be overridden in
      ;; c-mode-common-hook or {c,c++,objc,java}-mode-hook.
      (c-set-style c-site-default-style)))

(if c-style-variables-are-local-p
    (progn
      ;; style variables
      (make-variable-buffer-local 'c-offsets-alist)
      (make-variable-buffer-local 'c-basic-offset)
      (make-variable-buffer-local 'c-file-style)
      (make-variable-buffer-local 'c-file-offsets)
      (make-variable-buffer-local 'c-comment-only-line-offset)
      (make-variable-buffer-local 'c-cleanup-list)
      (make-variable-buffer-local 'c-hanging-braces-alist)
      (make-variable-buffer-local 'c-hanging-colons-alist)
      (make-variable-buffer-local 'c-hanging-comment-starter-p)
      (make-variable-buffer-local 'c-hanging-comment-ender-p)
      (make-variable-buffer-local 'c-backslash-column)
      (make-variable-buffer-local 'c-label-minimum-indentation)
      (make-variable-buffer-local 'c-special-indent-hook)
      (make-variable-buffer-local 'c-indentation-style)))

