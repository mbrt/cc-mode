;;; cc-align.el --- custom indentation functions for CC Mode

;; Copyright (C) 1985,87,92,93,94,95,96,97 Free Software Foundation, Inc.

;; Authors:    1992-1997 Barry A. Warsaw
;;             1987 Dave Detlefs and Stewart Clamen
;;             1985 Richard M. Stallman
;; Maintainer: cc-mode-help@python.org
;; Created:    22-Apr-1997 (split from cc-mode.el)
;; Version:    5.01
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
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.


;; Standard indentation line-ups
(defun c-lineup-arglist (langelem)
  ;; lineup the current arglist line with the arglist appearing just
  ;; after the containing paren which starts the arglist.
  (save-excursion
    (let* ((containing-sexp
	    (save-excursion
	      ;; arglist-cont-nonempty gives relpos ==
	      ;; to boi of containing-sexp paren. This
	      ;; is good when offset is +, but bad
	      ;; when it is c-lineup-arglist, so we
	      ;; have to special case a kludge here.
	      (if (memq (car langelem) '(arglist-intro arglist-cont-nonempty))
		  (progn
		    (beginning-of-line)
		    (backward-up-list 1)
		    (skip-chars-forward " \t" (c-point 'eol)))
		(goto-char (cdr langelem)))
	      (point)))
	   (cs-curcol (save-excursion
			(goto-char (cdr langelem))
			(current-column))))
      (if (save-excursion
	    (beginning-of-line)
	    (looking-at "[ \t]*)"))
	  (progn (goto-char (match-end 0))
		 (forward-sexp -1)
		 (forward-char 1)
		 (c-forward-syntactic-ws)
		 (- (current-column) cs-curcol))
	(goto-char containing-sexp)
	(or (eolp)
	    (not (memq (following-char) '(?{ ?\( )))
	    (let ((eol (c-point 'eol))
		  (here (progn
			  (forward-char 1)
			  (skip-chars-forward " \t")
			  (point))))
	      (c-forward-syntactic-ws)
	      (if (< (point) eol)
		  (goto-char here))))
	(- (current-column) cs-curcol)
	))))

(defun c-lineup-arglist-intro-after-paren (langelem)
  ;; lineup an arglist-intro line to just after the open paren
  (save-excursion
    (let ((cs-curcol (save-excursion
		       (goto-char (cdr langelem))
		       (current-column)))
	  (ce-curcol (save-excursion
		       (beginning-of-line)
		       (backward-up-list 1)
		       (skip-chars-forward " \t" (c-point 'eol))
		       (current-column))))
      (- ce-curcol cs-curcol -1))))

(defun c-lineup-arglist-close-under-paren (langelem)
  ;; lineup an arglist-intro line to just after the open paren
  (save-excursion
    (let ((cs-curcol (save-excursion
		       (goto-char (cdr langelem))
		       (current-column)))
	  (ce-curcol (save-excursion
		       (beginning-of-line)
		       (backward-up-list 1)
		       (current-column))))
      (- ce-curcol cs-curcol))))

(defun c-lineup-streamop (langelem)
  ;; lineup stream operators
  (save-excursion
    (let* ((relpos (cdr langelem))
	   (curcol (progn (goto-char relpos)
			  (current-column))))
      (re-search-forward "<<\\|>>" (c-point 'eol) 'move)
      (goto-char (match-beginning 0))
      (- (current-column) curcol))))

(defun c-lineup-multi-inher (langelem)
  ;; line up multiple inheritance lines
  (save-excursion
    (let (cs-curcol
	  (eol (c-point 'eol))
	  (here (point)))
      (goto-char (cdr langelem))
      (setq cs-curcol (current-column))
      (skip-chars-forward "^:" eol)
      (skip-chars-forward " \t:" eol)
      (if (or (eolp)
	      (looking-at c-comment-start-regexp))
	  (c-forward-syntactic-ws here))
      (- (current-column) cs-curcol)
      )))

(defun c-lineup-java-inher (langelem)
  ;; line up Java implements and extends continuations
  (save-excursion
    (let ((cs-curcol (progn (goto-char (cdr langelem))
			    (current-column))))
      (forward-word 1)
      (if (looking-at "[ \t]*$")
	  cs-curcol
	(c-forward-syntactic-ws)
	(- (current-column) cs-curcol)))))

(defun c-lineup-C-comments (langelem)
  ;; line up C block comment continuation lines
  (save-excursion
    (let ((here (point))
	  (stars (progn (back-to-indentation)
			(skip-chars-forward "*")))
	  (cs-curcol (progn (goto-char (cdr langelem))
			    (current-column))))
      (back-to-indentation)
      (if (not (re-search-forward "/[*]+" (c-point 'eol) t))
	  (progn
	    (if (not (looking-at "[*]+"))
		(progn
		  ;; we now have to figure out where this comment begins.
		  (goto-char here)
		  (back-to-indentation)
		  (if (looking-at "[*]+/")
		      (progn (goto-char (match-end 0))
			     (forward-comment -1))
		    (goto-char (cdr langelem))
		    (back-to-indentation))))
	    (- (current-column) cs-curcol))
	(if (zerop stars)
	    (skip-chars-forward " \t"))
	(- (current-column) stars cs-curcol))
      )))

(defun c-lineup-comment (langelem)
  ;; support old behavior for comment indentation. we look at
  ;; c-comment-only-line-offset to decide how to indent comment
  ;; only-lines
  (save-excursion
    (back-to-indentation)
    ;; this highly kludgiforous flag prevents the mapcar over
    ;; c-syntactic-context from entering an infinite loop
    (let ((recurse-prevention-flag (boundp 'recurse-prevention-flag)))
      (cond
       ;; CASE 1: preserve comment-column
       (recurse-prevention-flag 0)
       ((= (current-column) comment-column)
	;; we have to subtract out all other indentation
	(- comment-column (apply '+ (mapcar 'c-get-offset
					    c-syntactic-context))))
       ;; indent as specified by c-comment-only-line-offset
       ((not (bolp))
	(or (car-safe c-comment-only-line-offset)
	    c-comment-only-line-offset))
       (t
	(or (cdr-safe c-comment-only-line-offset)
	    (car-safe c-comment-only-line-offset)
	    -1000))			;jam it against the left side
       ))))

(defun c-lineup-runin-statements (langelem)
  ;; line up statements in coding standards which place the first
  ;; statement on the same line as the block opening brace.
  (if (= (char-after (cdr langelem)) ?{)
      (save-excursion
	(let ((curcol (progn
			(goto-char (cdr langelem))
			(current-column))))
	  (forward-char 1)
	  (skip-chars-forward " \t")
	  (- (current-column) curcol)))
    0))

(defun c-lineup-math (langelem)
  ;; line up math statement-cont after the equals
  (save-excursion
    (let* ((relpos (cdr langelem))
	   (equalp (save-excursion
		     (goto-char (c-point 'boi))
		     (skip-chars-forward "^=" (c-point 'eol))
		     (and (= (following-char) ?=)
			  (- (point) (c-point 'boi)))))
	   (curcol (progn
		     (goto-char relpos)
		     (current-column)))
	   donep)
      (while (and (not donep)
		  (< (point) (c-point 'eol)))
	(skip-chars-forward "^=" (c-point 'eol))
	(if (c-in-literal (cdr langelem))
	    (forward-char 1)
	  (setq donep t)))
      (if (/= (following-char) ?=)
	  ;; there's no equal sign on the line
	  c-basic-offset
	;; calculate indentation column after equals and ws, unless
	;; our line contains an equals sign
	(if (not equalp)
	    (progn
	      (forward-char 1)
	      (skip-chars-forward " \t")
	      (setq equalp 0)))
	(- (current-column) equalp curcol))
      )))

(defun c-lineup-ObjC-method-call (langelem)
  ;; Line up methods args as elisp-mode does with function args: go to
  ;; the position right after the message receiver, and if you are at
  ;; (eolp) indent the current line by a constant offset from the
  ;; opening bracket; otherwise we are looking at the first character
  ;; of the first method call argument, so lineup the current line
  ;; with it.
  (save-excursion
    (let* ((extra (save-excursion
		    (back-to-indentation)
		    (c-backward-syntactic-ws (cdr langelem))
		    (if (= (preceding-char) ?:)
			(- c-basic-offset)
		      0)))
	   (open-bracket-pos (cdr langelem))
           (open-bracket-col (progn
			       (goto-char open-bracket-pos)
			       (current-column)))
           (target-col (progn
			 (forward-char)
			 (forward-sexp)
			 (skip-chars-forward " \t")
			 (if (eolp)
			     (+ open-bracket-col c-basic-offset)
			   (current-column))))
	   )
      (- target-col open-bracket-col extra))))

(defun c-lineup-ObjC-method-args (langelem)
  ;; Line up the colons that separate args. This is done trying to
  ;; align colons vertically.
  (save-excursion
    (let* ((here (c-point 'boi))
	   (curcol (progn (goto-char here) (current-column)))
	   (eol (c-point 'eol))
	   (relpos (cdr langelem))
	   (first-col-column (progn
			       (goto-char relpos)
			       (skip-chars-forward "^:" eol)
			       (and (= (following-char) ?:)
				    (current-column)))))
      (if (not first-col-column)
	  c-basic-offset
	(goto-char here)
	(skip-chars-forward "^:" eol)
	(if (= (following-char) ?:)
	    (+ curcol (- first-col-column (current-column)))
	  c-basic-offset)))))

(defun c-lineup-ObjC-method-args-2 (langelem)
  ;; Line up the colons that separate args. This is done trying to
  ;; align the colon on the current line with the previous one.
  (save-excursion
    (let* ((here (c-point 'boi))
	   (curcol (progn (goto-char here) (current-column)))
	   (eol (c-point 'eol))
	   (relpos (cdr langelem))
	   (prev-col-column (progn
			      (skip-chars-backward "^:" relpos)
			      (and (= (preceding-char) ?:)
				   (- (current-column) 1)))))
      (if (not prev-col-column)
	  c-basic-offset
	(goto-char here)
	(skip-chars-forward "^:" eol)
	(if (= (following-char) ?:)
	    (+ curcol (- prev-col-column (current-column)))
	  c-basic-offset)))))

(defun c-snug-do-while (syntax pos)
  "Dynamically calculate brace hanginess for do-while statements.
Using this function, `while' clauses that end a `do-while' block will
remain on the same line as the brace that closes that block.

See `c-hanging-braces-alist' for how to utilize this function as an
ACTION associated with `block-close' syntax."
  (save-excursion
    (let (langelem)
      (if (and (eq syntax 'block-close)
	       (setq langelem (assq 'block-close c-syntactic-context))
	       (progn (goto-char (cdr langelem))
		      (if (= (following-char) ?{)
			  (c-safe (forward-sexp -1)))
		      (looking-at "\\<do\\>[^_]")))
	  '(before)
	'(before after)))))

(defun c-gnu-impose-minimum ()
  "Imposes a minimum indentation for lines inside a top-level construct.
The variable `c-label-minimum-indentation' specifies the minimum
indentation amount."
  (let ((non-top-levels '(defun-block-intro statement statement-cont
			   statement-block-intro statement-case-intro
			   statement-case-open substatement substatement-open
			   case-label label do-while-closure else-clause
			   ))
	(syntax c-syntactic-context)
	langelem)
    (while syntax
      (setq langelem (car (car syntax))
	    syntax (cdr syntax))
      ;; don't adjust comment-only lines
      (cond ((eq langelem 'comment-intro)
	     (setq syntax nil))
	    ((memq langelem non-top-levels)
	     (save-excursion
	       (setq syntax nil)
	       (back-to-indentation)
	       (if (zerop (current-column))
		   (insert (make-string c-label-minimum-indentation 32)))
	       ))
	    ))))


;; Useful for c-hanging-semi&comma-criteria
(defun c-semi&comma-inside-parenlist ()
  "Determine if a newline should be added after a semicolon.
If a comma was inserted, no determination is made.  If a semicolon was
inserted inside a parenthesis list, no newline is added otherwise a
newline is added.  In either case, checking is stopped.  This supports
exactly the old newline insertion behavior."
  ;; newline only after semicolon, but only if that semicolon is not
  ;; inside a parenthesis list (e.g. a for loop statement)
  (if (/= last-command-char ?\;)
      nil				; continue checking
    (if (condition-case nil
	    (save-excursion
	      (up-list -1)
	      (/= (following-char) ?\())
	  (error t))
	t
      'stop)))


(provide 'cc-align)
;;; cc-align.el ends here
