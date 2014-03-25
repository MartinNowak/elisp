;;; hier-imenu.el --- Hierarchical index menus, using imenu.el.

;; Copyright (C) 1996, 1997, 2000, 2001 Y.Dirson <ydirson@altern.org>
;; Copyright (C) 2001 Alcove <http://www.alcove.com/>
;; Parts copyright (C) 1996 Paul Barham <prb12@cl.cam.ac.uk>

;; Author: Y.Dirson <ydirson@altern.org>
;; Keywords: tools hypermedia tex
;; Created: July 1996
;; URL: http://ydirson.free.fr/en/software/hier-imenu.html
;; RCS: $Id: hier-imenu.el,v 1.24 2001/06/06 22:07:59 dwitch Exp $

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, version 2 of the
;; License.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE®  See the
;; GNU General Public License for more details.
     
;; You should have received a copy of the GNU General Public License
;; along with GNU EMACS; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;; Creates an index-menu (using `imenu'), that reflects the
;; hierarchical structure of your documents, either with indentation
;; only, or with ASCII drawing.
;;
;; Sample configurations are given for latex-mode (both standard FSF's
;; one and the one from AUC), html-mode.  Support for FWEB-mode has
;; moved to my `web-mode.el'
;;
;; Bug reports, comments, and suggestions are welcome!
;;
;; WARNING: included support for LaTeX-mode will not work in Emacs 20.6
;; or older, or in Xemacs using packages dated 2000.01.24 of older, unless
;; you upgrade `imenu.el' !!  Please visit the homepage for updated versions.
;;
;; WARNING: variables `hier-imenu-do-*' have been obsoleted by
;; `hier-imenu-style'.
;;
;; WARNING: variable `hier-imenu-max-item-length' has been obsoleted
;; by `imenu-max-item-length', and moved to `imenu.el'.

;;; TO USE:
;; - place this file in your load path
;; - add the following lines to your .emacs:
;;
;;(autoload 'imenu-create-hierarchical-index "hier-imenu" 
;;  "Generate an alist for imenu from a buffer with hierarchical structure.")
;;(autoload 'hier-imenu-dtd-setup "hier-imenu" 
;;  "Scan buffer for a DTD and set `hier-imenu' parameters accordingly.")
;;
;; - to activate support for SGML mode:
;;
;;(add-hook 'sgml-mode-hook 'hier-imenu-dtd-setup)
;;
;; - for other modes in which you wish to use it:
;;
;;(add-hook 'tex-mode-hook 'imenu-add-menubar-index)
;;

;;; FEATURES:
;;
;; * provides a hierarchical index-menu for each buffer providing the
;; `hier-imenu-levels' and `hier-imenu-header-name-function' parameters.
;;
;; * adds standard support for LaTeX and HTML modes, and some support
;; for the DocBook, LinuxDoc, DebianDoc, AlcoveDoc, and HTML DTDs in
;; SGML mode.
;;
;; * `hier-imenu-indent-level' allow customization of sub-levels
;; intentation.
;;
;; * `hier-imenu-style' controls rendering of the index-menu. Valid
;; values are `indented', `numbered', `ascii'.

;; `ascii' allows a character-based tree-like hierarchical drawing
;; (still looks awful for now :-).
;;
;; `numbered' introduces section numbering inside imenu labels. In a
;; LaTeX document which is split across a number of files you can
;; specify the section number to start with
;; `hier-imenu-initial-section-numbers' from buffer-local variables,
;; e.g.
;;
;;  %%% Local Variables: %%%
;;  %%% hier-imenu-initial-section-numbers: [2 5] %%%
;;  %%% TeX-master: "toplevel" %%%
;;  %%% End: %%%
;;
;; * if a number, `hier-imenu-max-numbering-depth' controls the number
;; of levels that will be numbered. Whether this variable should be
;; controlled by the user or by the major-mode is dependant on the
;; latter. For exemple, `fweb-mode' should be given full control of
;; this parameter.  For sgml documents, it theoretically depends on
;; the DTD and on the converter that will be used, so the user may
;; want to choose what suits him best.


;;; ADDING SUPPORT FOR A NEW SGML DTD:
;;
;; In the simplest case, just add an entry to
;; `hier-imenu-sgml-definitions-alist', where DTD-REGEXP matches the
;; public identifiers for the DTDs you want to handle, and, in
;; VARS-ALIST, specify `hier-imenu-levels' and
;; `hier-imenu-header-name-function', maybe some other hier-imenu
;; parameters, and set `imenu-create-index-function' to
;; `imenu-create-hierarchical-index'.  Note that in the future
;; `hier-imenu-sgml-header-name' will probably make setting
;; `hier-imenu-header-name-function' superfluous.
;;
;; For more complicated settings, read more, and look at LaTeX support
;; for an example.


;;; ADDING SUPPORT FOR A NEW MAJOR-MODE:
;;
;; To support hier-imenu, a major mode must define the variables
;; `hier-imenu-levels' and `hier-imenu-header-name-function'. Custom
;; values for `hier-imenu-anchor-end-of-header', `hier-imenu-style'
;; and `hier-imenu-max-numbering-depth' might be needed to make it
;; behave as you wish. See docstrings for these parameters for more
;; information.
;;
;; These vars may be set either by the major-mode primary function, or
;; by a hook (see `add-hook').
;;
;; At this point, you have two alternatives: either using only
;; `hier-imenu' mechanism (then you should set
;; `imenu-create-index-function' to
;; `imenu-create-hierarchical-index'), or you can mix both a
;; hierarchical imenu and standard imenu regexps. See docstring for
;; variable `imenu-generic-expression', and example stuff for LaTeX at
;; the end of this file, for more information. Note that for this for
;; this last functionnality you need a patched version of `imenu.el'
;; that supports building part of the index with a function. Neither
;; FSFemacs 20.4 nor Xemacs 21.1.8 seem to be able to do that - except
;; maybe with the "special" undocumented feature which I did not
;; reverse-engineered yet.  A patched imenu.el for xemacs-21 (based on
;; the one in 21.1.8) and for FSF emacs (based on 20.6) is available at
;; http://ydirson.free.fr/en/software/hier-imenu.html

;;; TODO - items sorted in approximate priority order
;;
;; * support for customize.el
;;
;; * look at semantic.el (http://cedet.sf.net/semantic.shtml), and
;; find out whether it could be used as a base for some of hier-imenu
;; functionalities.
;;
;; * finish generic support for SGML (support for ommitable <heading>
;; tags, finalize and use `hier-imenu-sgml-header-name', replace
;; invocation of `imenu-add-menubar-index' by some use of
;; `global-imenu-add-menubar-index' when it comes into existence,
;; handle <tag/text/ in SGML header extraction, find a way in
;; HTML/SGML modes to remove tags from item names, ...)
;;
;; * find a way to easily add support for modes case-insensitive to
;; the strings we're matching.  A `hier-imenu-case-sensitive' tag may
;; do the trick.
;;
;; * add support for multilevel sectionning (eg: docbook's <sect>).
;; Think about SGML DTDs that use a given tag at different levels,
;; under different parents
;;
;; * make imenu split menus on highest-possible level (implement
;; balancing hooks in imenu.el ?)
;;
;; * improve numbering support (add support for different numbering
;; schemes (for LaTeX starred sections, FWEB modules, etc.)
;;
;; * find a generic way to handle header-strings in comments, strings,
;; etc.
;;
;; * add support for multiple `hier-imenu-levels'-like (optional
;; parameters to a function in `imenu.el' ?)
;;
;; * add support for appendix numbering
;;
;; * improve speed and look
;;
;; * handle quoted stuff
;;
;; * mouse folding inside menu ?
;;
;; * change some vars from buffer- to major-mode- locality to save
;; space and computing time
;;
;; * [1996] should detect and handle `case-fold-search' ?  With which
;; semantics ?  [2000] Hm, there's a `imenu-case-fold-search' out
;; there...

;;; TODO (imenu.el):
;;
;; * add optional parameters to submenu-generating functions ?
;;
;; * add a `global-imenu-add-menubar-index' function (see font-lock.el
;; and mmm-mode.el).
;;
;; * make robust against wrong generic expr (eg missing index)

;;; KNOWN BUGS:
;;
;; * SGML docs with non lowercase-only section tags trigger
;; (lisp-level) assertion
;;
;; * with mule support (xemacs only ?), accented chars are not
;; properly displayed in menubar index
;;
;; * support for setting `hier-imenu-levels' in the Local-Variables
;; section of a file is hackish, and will ignore headers starting with
;; a double-quote character.

;;; ACKNOWLEDGMENTS:
;;
;; Thanks to Paul Barham <prb12@cl.cam.ac.uk> for introducing
;; section-numbering support.
;;
;; Thanks to all of you who provided feedback and bug reports, and
;; special thanks to all of you at Marne-la-Vallée University who
;; provided beta-testing of the initial revisions, and encouragements
;; to go on developping this package.

;;; Code:

(require 'imenu)


;;;; user parameters
(defvar hier-imenu-indent-level 2
  "*Amount of space to indent each sub-item relatively to its parent")

(defvar hier-imenu-style 'indented
  "*Style to be used in a hierarchical index-menu.
Valid values are `indented', `numbered', `ascii'. Numbers fine for some
major modes, but maybe not suitable to all of them.")
(make-variable-buffer-local 'hier-imenu-style)

(defvar hier-imenu-initial-section-numbers nil
  "*Section numbers at the beginning of this buffer.")
(make-variable-buffer-local 'hier-imenu-initial-section-numbers)


;;;; mode-specific vars
(defvar hier-imenu-levels nil
  "Alist of mode-specific sectionning markup-strings versus sectionning levels.")
(make-variable-buffer-local 'hier-imenu-levels)

(defvar hier-imenu-header-name-function nil
  "Mode-specific function called after `re-search-backward'.
Should return the corresponding header.

Called within a `save-excursion'.")
(make-variable-buffer-local 'hier-imenu-header-name-function)

(defvar hier-imenu-anchor-end-of-header nil
  "Non-nil makes hier-imenu add \"\\>\" at end of regexp.

This is necessary for LaTeX and HTML modes, but breaks FWEB modes.")
(make-variable-buffer-local 'hier-imenu-anchor-end-of-header)

(defvar hier-imenu-max-numbering-depth nil
  "*If a number, use it to limit numbering to that number of section-levels.")
(make-variable-buffer-local 'hier-imenu-max-numbering-depth)


;;;; internal vars
(defvar hier-imenu-regexp nil
  "Autobuilt regexp, infered from `hier-imenu-levels'")
(make-variable-buffer-local 'hier-imenu-regexp)

(defvar hier-imenu-nblevels nil
  "Auto-computed value giving the number of levels allowed in this buffer.")
(make-variable-buffer-local 'hier-imenu-nblevels)

(defconst hier-imenu-ignore-label "$$ignore$$"
  "String used to specify section header that should not be displayed.")


;;;; support for old emacses
(if (not (fboundp 'buffer-substring-no-properties))
    (defalias 'buffer-substring-no-properties 'buffer-substring))


;;;###autoload
(defun imenu-create-hierarchical-index ()
  "Generate an alist for imenu from a buffer with hierarchical structure.
Use indentation, ASCII-drawings, or section-numbers to give
information on effective structure, according to `hier-imenu-style'."

  (message "Initializing hier-imenu mechanism for buffer...")

  ;; hierarchical imenus should not be sorted
  (and imenu-sort-function
       (progn
	 (make-local-variable 'imenu-sort-function)
	 (setq imenu-sort-function nil)))
  
  ;; verify current buffer supports this style of imenu
  (or (and (boundp 'hier-imenu-levels) hier-imenu-levels
	   (boundp 'hier-imenu-header-name-function) hier-imenu-header-name-function)
      (error "This buffer doesn't support hier-imenu"))
    
  ;; build regexp if necessary
  (or hier-imenu-regexp
      (setq hier-imenu-regexp (concat "\\("
				     (mapconcat (lambda (el)
						  (regexp-quote (car el)))
						hier-imenu-levels
						"\\|")
				     "\\)"
				     (if hier-imenu-anchor-end-of-header "\\>" ""))))

  ;; compute nblevels if necessary
  (or hier-imenu-nblevels
      (progn
	;; start knowing no level
	(setq hier-imenu-nblevels 0)
	;; check for each declaration
	(mapcar (lambda (el)
		  (setq hier-imenu-nblevels (max hier-imenu-nblevels (cdr el))))
		hier-imenu-levels)
	;; nb is max+1 to include level 0
	(setq hier-imenu-nblevels (1+ hier-imenu-nblevels))))

  (let (result
	before
	level
	position
	loop-index
	title
	;; array of bools showing in which column to draw
	(to-draw (make-vector hier-imenu-nblevels nil))
	;; initilize min-level with one that will never be used
	(min-level hier-imenu-nblevels))

    (message "Building index...")
  
    ;; let's search the buffer from bottom to top, to finally have
    ;; everything in the right order
    (goto-char (point-max))
    (while (re-search-backward hier-imenu-regexp nil t)

      ;; get point as a marker or buffer-position
      (setq position (if imenu-use-markers (point-marker) (point)))
      
      ;; get the type of header-level it is,
      ;; and memorize it
      (let* ((substr (buffer-substring-no-properties
			  (match-beginning 1)
			  (match-end 1)))
	     (cons (assoc substr hier-imenu-levels)))
	;; assert - known to trigger :}
	(or cons
	    (error (format "Match (%s) not found in known levels - case-sensitivity problem ?"
			   substr)))
	(setq level (cdr cons)))

      ;; update min-level
      (setq min-level (min level min-level))

      ;; get section title
      (setq title (save-excursion (funcall hier-imenu-header-name-function)))

      ;; put it in the index only if meaningful
      (if (not (equal title hier-imenu-ignore-label))
	  ;; ASCII draw if asked for
	  (if (eq hier-imenu-style 'ascii)
	      (progn
		;; handle this level if > 0
		(if (> level 0)
		    (setq title (concat (if (aref to-draw level)
					    "+"
					  "`")
					(make-string (1- hier-imenu-indent-level) ?-) title)))
		;; clear all lower levels
		(setq loop-index hier-imenu-nblevels)
		(while (> loop-index level)
		  (setq loop-index (1- loop-index))
		  (aset to-draw loop-index nil))
		;; set this one
		(aset to-draw level t)
		;; draw active higher levels
		(while (> loop-index 1)
		  (setq loop-index (1- loop-index))
		  (setq title (concat (if (aref to-draw loop-index)
					  "|"
					" ")
				      (make-string (1- hier-imenu-indent-level) ? ) title)))
	    
		;; construct index entry
		(setq result (cons (cons title
					 position)
				   result))
		)

	    ;; ELSE [space-indentation or numbered]
	    ;; construct temporary index entry, with conses (title . level)
	    ;; instead of label
	    (setq result (cons (cons (cons title
					   level)
				     position)
			       result))
	    ))
      )

    ;; post-process according to requested style
    (prog1
	(cond
	 ((eq hier-imenu-style 'ascii)
	  ;; OK as is
	  result)
	  
	 ((eq hier-imenu-style 'numbered)
	  ;;result is list of ((title . level) . position)
	  (let (;; array of section numbers
		(sec-num (make-vector hier-imenu-nblevels '0)))

	    ;; maybe set `sec-num' according to `hier-imenu-initial-section-numbers'
	    (if hier-imenu-initial-section-numbers
		(let ((loop-index 0))
		  (while (< loop-index (length hier-imenu-initial-section-numbers))
		    (aset sec-num (+ loop-index min-level)
			  (aref hier-imenu-initial-section-numbers loop-index))
		    (setq loop-index (1+ loop-index)))))

	    (mapcar (lambda (el)
		      (let (loop-index
			    secnum
			    (title (car (car el)))
			    (level (cdr (car el)))
			    (pos   (cdr el)))
			    
			;; handle this level if > 0
			(if (>= level min-level)
			    (setq title (concat "  " title)))
			    
			;; zero all lower levels
			(setq loop-index (1- hier-imenu-nblevels))
			(while (> loop-index level)
			  (aset sec-num loop-index 0)
			  (setq loop-index (1- loop-index)))
		  
			;; inc this one
			(aset sec-num level 
			      (1+ (aref sec-num level)))
			    
			;; generate section number
			(if (or (null hier-imenu-max-numbering-depth)
				(< level hier-imenu-max-numbering-depth))
			    (while (>= loop-index min-level)
			      (setq secnum 
				    (if secnum
					(concat (int-to-string (aref sec-num loop-index))
						"." secnum)
				      (int-to-string (aref sec-num loop-index))))
			      (setq loop-index (1- loop-index))))
			    
			;; construct index entry
			(cons (concat 
			       (make-string (* (- level min-level)
					       hier-imenu-indent-level) 
					    ? ) 
			       secnum title)
			      pos)
			))
		    result)))

	  ((eq hier-imenu-style 'indented)
	   ;; ELSE [space-indentation]
	   ;; turn the temporary alist into one suitable for imenu,
	   ;; inserting the spaces, and return it
	   (mapcar (lambda (el)
		     (cons (concat (make-string (* (- (cdr (car el)) min-level)
						   hier-imenu-indent-level)
						? )
				   (car (car el)))
			   (cdr el)))
		   result))

	 
	  ((error "Invalid style for hier-imenu: %s" hier-imenu-style)))

      (message "Building index... Done"))

    ))

(provide 'hier-imenu)


;;; Example configurations
;; (automatically installed)

;;; LaTeX-mode:

(defun hier-imenu-latex-header-name ()
  "Return the header-name of the next LaTeX section.

Ignores commented headers if AUC-TeX is used; Ignore \"headers\"
when they are inside a bracketed block, to allow \\renewcommand's."
  (if (or (and (fboundp 'TeX-in-comment)
	       (TeX-in-comment))
	  (not (condition-case nil
		   (save-excursion (backward-up-list 1))
		 (error t))))
      hier-imenu-ignore-label
    (buffer-substring-no-properties
     (progn
       (skip-chars-forward "^{")
       (1+ (point)))
     (progn
       (forward-sexp)
       (1- (point))))))
  
(defmacro hier-imenu-latex-hook ()
  (function (lambda ()
	      (setq hier-imenu-levels '(("\\part" . 0)		("\\part*" . 0)
					("\\chapter" . 1)	("\\chapter*" . 1)
					("\\section" . 2)	("\\section*" . 2)
					("\\subsection" . 3)	("\\subsection*" . 3)
					("\\subsubsection" . 4)	("\\subsubsection*" . 4)
					("\\paragraph" . 5)
					("\\subparagraph" . 6))
		    hier-imenu-header-name-function 'hier-imenu-latex-header-name
		    hier-imenu-anchor-end-of-header t
		    hier-imenu-style 'numbered
		    imenu-create-index-function 'imenu-default-create-index-function
		    imenu-generic-expression '(("Labels" "\\\\label{\\([^}]+\\)}" 1)
					       (nil imenu-create-hierarchical-index))
		    ))))


;; standard LaTeX mode and AUC-TeX  
(add-hook 'tex-mode-hook (hier-imenu-latex-hook))
(add-hook 'TeX-mode-hook (hier-imenu-latex-hook))

;; cleanup
(fmakunbound 'hier-imenu-latex-hook)



;;;; HTML-mode:
(defun hier-imenu-html-header-name ()
  "Return the header-name of the next HTML section.
Assume the point is just before the opening angle-braquet."
  (buffer-substring-no-properties
   (progn
     (search-forward ">")		; FIXME: may stop on ">" in attribute value ?
     (point))
   (progn
     (re-search-forward "</[Hh][1-6]>")
     (match-beginning 0))
   ))

(defmacro hier-imenu-html-hook ()
  (function (lambda ()
	      (setq hier-imenu-levels
		    '(("<H1" . 0)("<h1" . 0)
		      ("<H2" . 1)("<h2" . 1)
		      ("<H3" . 2)("<h3" . 2)
		      ("<H4" . 3)("<h4" . 3)
		      ("<H5" . 4)("<h5" . 4)
		      ("<H6" . 5)("<h6" . 5))
		    hier-imenu-header-name-function 'hier-imenu-html-header-name
		    hier-imenu-anchor-end-of-header t
		    imenu-create-index-function 'imenu-create-hierarchical-index))))

(add-hook 'html-mode-hook (hier-imenu-html-hook))
(add-hook 'html-helper-hook (hier-imenu-html-hook))

(fmakunbound 'hier-imenu-html-hook)



;;;; generic SGML support
(defvar hier-imenu-sgml-definitions-alist
  '((docbook "//DTD DocBook" . 
	     ((hier-imenu-levels . (("<sect1" . 2) ("<sect2" . 3)
				    ("<sect3" . 4) ("<sect4" . 5)))
	      (hier-imenu-sgml-header-regexps . (("<title\\( [^>/]*\\)?>\\(.*\\)</title>" . 2)
						 ("<title\\( [^>/]*\\)?/\\([^/]*\\)/" . 2)))
	      (hier-imenu-header-name-function . hier-imenu-sgml-header-name)
	      (hier-imenu-anchor-end-of-header . nil)
	      (hier-imenu-style . numbered)
	      (hier-imenu-max-numbering-depth . 3)
	      (imenu-create-index-function . imenu-create-hierarchical-index)))
    (debiandoc "//DTD \\(Debian\\|Alcove\\)Doc" . 
	      ((hier-imenu-levels . (("<chapt" . 0)("<appendix" . 0)
				     ("<sect1" . 2)("<sect2" . 3)
				     ("<sect3" . 4)("<sect4" . 5)
				     ("<sect" . 1)))
	       (hier-imenu-sgml-header-regexps . (("<heading\\( [^>/]*\\)?>\\(.*\\)</heading>" . 2)
						  ("<heading\\( [^>/]*\\)?/\\([^/]*\\)/" . 2)))
	       (hier-imenu-header-name-function . hier-imenu-sgml-header-name)
	       (hier-imenu-anchor-end-of-header . nil)
	       (hier-imenu-style . numbered)
	       (hier-imenu-max-numbering-depth . 3)
	       (imenu-create-index-function . imenu-create-hierarchical-index)))
    (linuxdoc "//DTD LinuxDoc" . 
	      ((hier-imenu-levels . (("<chapt" . 0)("<sect1" . 2)
				     ("<sect2" . 3)("<sect3" . 4)
				     ("<sect4" . 5)("<sect" . 1)))
	       (hier-imenu-sgml-header-regexps . (("<heading\\( [^>/]*\\)?>\\(.*\\)</heading>" . 2)
						  ("<heading\\( [^>/]*\\)?/\\([^/]*\\)/" . 2)))
	       (hier-imenu-header-name-function . hier-imenu-sgml-header-name)
	       (hier-imenu-anchor-end-of-header . nil)
	       (hier-imenu-style . numbered)
	       (hier-imenu-max-numbering-depth . 3)
	       (imenu-create-index-function . imenu-create-hierarchical-index)))
    (html "//DTD \\([^/]+ \\)?HTML" . 
	  ((hier-imenu-levels . (("<H1" . 0)("<h1" . 0)
				 ("<H2" . 1)("<h2" . 1)
				 ("<H3" . 2)("<h3" . 2)
				 ("<H4" . 3)("<h4" . 3)
				 ("<H5" . 4)("<h5" . 4)
				 ("<H6" . 5)("<h6" . 5)))
	   (hier-imenu-sgml-header-regexps . ((">\\(.*\\)</h[1-6]>" . 1)))
	   (hier-imenu-header-name-function . hier-imenu-sgml-header-name)
	   (hier-imenu-anchor-end-of-header . t)
	   (imenu-create-index-function . imenu-create-hierarchical-index)))
    )
  "Alist of DTD-ID against info to identify them and to handle them.
Elements are built like:
(DTD-ID DTD-REGEXP . VARS-ALIST)
Where DTD-REGEXP is a regexp matching the DTD public identifier,
and VARS-ALIST is an alist of dtd-specific settings for the `hier-imenu'
mechanism.")

;;;###autoload
(defun hier-imenu-dtd-setup ()
  "Scan buffer for a DTD and set `hier-imenu' parameters accordingly.
Per-DTD information is taken from `hier-imenu-sgml-definitions-alist'."
  (interactive)

  (and (or (eq major-mode 'sgml-mode)
	   (eq major-mode 'html-mode))
       (save-excursion
	 (let ((alist hier-imenu-sgml-definitions-alist)
	       (doctype-start (let ((case-fold-search t)) 
				(goto-char (point-min))
				(re-search-forward "<! *doctype\\>" nil t)))
	       ;; doctype may be like "<! ... >" or "<! ... [...]>"
	       (doctype-end (re-search-forward "[[>]" nil t))
	       found)
	   (and doctype-start doctype-end
		(while (and alist (not found))
		  (goto-char doctype-start)
		  (if (re-search-forward (car (cdr (car alist)))
					 doctype-end
					 t)
		      (progn
			(mapcar (lambda (el)
				  (make-local-variable (car el))
				  (set (car el) (cdr el)))
				(cdr (cdr (car alist))))
			(make-local-variable 'hier-imenu-sgml-dtd-id)
			(setq hier-imenu-sgml-dtd-id (car (car alist))
			      found t)
			(imenu-add-menubar-index))
		    (setq alist (cdr alist)))))))))


;; FIXME: multiple regexps are wrongly handled
(defun hier-imenu-sgml-header-name (&optional re-list)
  "Return the header-name of the next SGML section.
Assume the point is just before the opening angle-braquet."
  (if (null re-list)
      (hier-imenu-sgml-header-name hier-imenu-sgml-header-regexps)

    (re-search-forward (car (car re-list)) nil t)
    (or (match-string-no-properties (cdr (car re-list)))
	(and (cdr re-list)
	     (hier-imenu-sgml-header-name (cdr re-list))))))

;;; hier-imenu.el ends here
