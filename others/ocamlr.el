;; ocamlr.el - revised OCaml mode for Emacs.

;; Author: Christian Gillot <cgillot@neo-rousseaux.org>
;; Revised by Christopher Dutchyn <cdutchyn@cs.ubc.ca> in 2003-2005.

;; Copyright (C) 2002 Christian Gillot, all rights reserved.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

(defconst ocamlr-mode-version "revised OCaml Version 0.1"
  "      Copyright © 2002 Christian Gillot, all rights reserved.
         Copying is covered by the GNU General Public License.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                        Emacs versions support

(defconst ocamlr-with-xemacs (string-match "XEmacs" emacs-version))

(defconst ocamlr-window-system
  (or (and (boundp 'window-system) window-system)
      (and (fboundp 'console-type) (or (eq (console-type) 'x)
				       (eq (console-type) 'gtk)
				       (eq (console-type) 'win32))))
  "Are we running under a window system?")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       User customizable variables

;; use the standard `customize' interface or `ocamlr-mode-hook' to
;; configure these variables

(require 'custom)

(defgroup ocamlr nil
  "Support for the revised Objective Caml language."
  :group 'languages)

(defcustom ocamlr-default-indent 2
  "*Default indentation.

Global indentation variable (large values may lead to indentation overflows).
When no governing keyword is found, this value is used to indent the line
if it has to."
  :group 'ocamlr :type 'integer)

;; customizable faces for Font-Lock mode

(defgroup ocamlr-faces nil
  "Special faces for the Ocamlr mode.

Face description is the following:
  color for LIGHT backgrounds,
  color for DARK backgrounds,
  ITALIC font, font+color fontification mode,
  BOLD font, font+color fontification mode,
  ITALIC font, font-only fontification mode,
  BOLD font, font-only fontification mode."
  :group 'ocamlr)

(defcustom ocamlr-font-lock-governing '("darkorange3" "orange" nil t nil t)
  "Face description for governing/leading keywords."
  :group 'ocamlr-faces)

(defcustom ocamlr-font-lock-operator '("brown" "khaki" nil nil nil nil)
  "Face description for all toplevel errors."
  :group 'ocamlr-faces)

(defcustom ocamlr-font-lock-interactive-output '("blue4" "cyan" nil nil t nil)
  "Face description for all toplevel outputs."
  :group 'ocamlr-faces)

(defcustom ocamlr-font-lock-interactive-error '("firebrick" "plum1" t t t t)
  "Face description for all toplevel errors."
  :group 'ocamlr-faces)

;; end of customizable variables

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                  Font-Lock

(defun cadar (x)
  (car (cdar x)))

(defun cddar (x)
  (cdr (cdar x)))

(if (and (featurep 'font-lock)
         (or ocamlr-window-system ocamlr-with-xemacs))
    (progn
      (defun ocamlr-after-change-fontify (begin end length)
        (ocamlr-fontify begin end))  ; old Emacs Font-Lock way of life

      (defun ocamlr-fontify-buffer ()
        (font-lock-default-fontify-buffer)
        (ocamlr-fontify (point-min) (point-max)))

      (defun ocamlr-fontify-region (begin end &amp;optional verbose)
        (font-lock-default-fontify-region begin end verbose)
        (ocamlr-fontify begin end))

      (defun ocamlr-after-fontify-buffer () ; XEmacs 20.x
        (ocamlr-fontify (point-min) (point-max)))

      (defun ocamlr-fontify (begin end)
        (if (eq major-mode 'ocamlr-mode)
            (save-excursion
              (let ((modified (buffer-modified-p))) ; Emacs hack (see below)
                (goto-char begin) (beginning-of-line) (setq begin (point))
                (goto-char (1- end)) (end-of-line) (setq end (point))
                (while (&gt; end begin)
                  (goto-char (1- end))
                  (ocamlr-in-literal-or-comment)
                  (cond
                   ((cdr ocamlr-last-loc)
                    (ocamlr-beginning-of-literal-or-comment)
                    (put-text-property (max begin (point)) end 'face
                                       (if (looking-at "(\\*[tT][eE][xX]")
                                           'font-lock-doc-string-face
                                         'font-lock-comment-face))
                    (setq end (1- (point))))
                   ((car ocamlr-last-loc)
                    (ocamlr-beginning-of-literal-or-comment)
                    (put-text-property (max begin (point)) end 'face
                                       'font-lock-string-face)
                    (setq end (point)))
                   (t (while (and ocamlr-cache-local
                                  (or (&gt; (caar ocamlr-cache-local) end)
                                      (eq 'b (cadar ocamlr-cache-local))))
                        (setq ocamlr-cache-local (cdr ocamlr-cache-local)))
                      (setq end (if ocamlr-cache-local
                                    (caar ocamlr-cache-local) begin)))))
                (if (not (or ocamlr-with-xemacs modified)) ; properties taken
                    (set-buffer-modified-p nil)))))) ; too seriously...

      (defun ocamlr-font-lock-hook ()
        "Function called by `font-lock-mode' for initialization purposes."
        (if (eq major-mode 'ocamlr-mode)
            (ocamlr-set-font-lock-faces)))

      (defun ocamlr-make-face-italic (face)
        (condition-case nil (make-face-italic face) (error nil)))
      (defun ocamlr-make-face-bold (face)
        (condition-case nil (make-face-bold face) (error nil)))
      (defun ocamlr-make-face-unitalic (face)
        (condition-case nil (make-face-unitalic face) (error nil)))
      (defun ocamlr-make-face-unbold (face)
        (condition-case nil (make-face-unbold face) (error nil)))

      ;;FIXME: Éventuellement, retirer cela si les face standards
      ;; suffisent
      (defun ocamlr-set-font-lock-faces ()
        "Set faces for Font-Lock mode."
        (let* ((use-fonts
                (or (and (boundp 'font-lock-use-fonts)
                         font-lock-use-fonts
                         (not (and (boundp 'font-lock-use-colors)
                                   font-lock-use-colors)))
                    (and (fboundp 'device-class)
                         (eq (device-class) 'mono))
                    (and (not (fboundp 'device-class))
                         (fboundp 'x-display-color-p)
                         (not (x-display-color-p)))))
               (light-bg
                (if ocamlr-window-system
                    (if ocamlr-with-xemacs
                        (if (and (fboundp 'color-rgb-components)
                                 (&lt; (apply '+ (color-rgb-components
                                               (make-color-specifier
                                                [default background])))
                                    (* (apply '+
                                              (color-rgb-components
                                               (make-color-specifier "white")))
                                       0.6))) nil t)
                      (let ((param (cdr (assq 'background-color
(frame-parameters))))) (cond ((boundp 'font-lock-background-mode) (if
(eq font-lock-background-mode 'dark) nil t)) ((eq system-type 'ms-dos)
(if (string-match "light" param) t nil)) ((and param (fboundp
'x-color-values) (&lt; (apply '+ (x-color-values param)) (* (apply '+
(x-color-values "white")) 0.6))) nil) (t t)))))) (default-color (if
light-bg "black" "white"))) (mapcar (lambda (name) (let ((desc (eval
(intern name))) (face (intern (concat name "-face")))) (if (or (and
(functionp 'find-face) (find-face face)) (facep face)) () (make-face
face) (set-face-foreground face (if use-fonts default-color (if
light-bg (nth 0 desc) (nth 1 desc)))) (if use-fonts (progn (if (nth 4
desc) (ocamlr-make-face-italic face) (ocamlr-make-face-unitalic face))
(if (nth 5 desc) (ocamlr-make-face-bold face) (ocamlr-make-face-unbold
face))) (if (nth 2 desc) (ocamlr-make-face-italic face)
(ocamlr-make-face-unitalic face)) (if (nth 3 desc)
(ocamlr-make-face-bold face) (ocamlr-make-face-unbold face))))))
'("ocamlr-font-lock-governing" "ocamlr-font-lock-operator"
"ocamlr-font-lock-interactive-output"
"ocamlr-font-lock-interactive-error")))) ;; FIXME ;; les commentaires
sont correctement en rouge tout va bien ;; les indications au
préprocesseur dovent être en rose pale ;; dans une déclaration de type
les noms de variables en jaune-orange pâle ;; les types standards et
les nom de classe en vert ;; les nom de fonctions dans les déclarations
en bleu ;; les mot-clés du langages en violet ;; Les importations
pourrait se faire comment en java mot-clé en violet ;; paquetage
importé en vert pâle ;; dans les commentaires en javadoc en vert pâle
le nom des tags, ;; en jaune type les params ;; Dans ce même vert pâle
les valeurs standards de langage True False etc ;; FIXME: dans un futur
lointain je mettrais en vert tout les types, et ;; jaune clair que
l'utilisateur veut bien créer. ;; FIXME: definir les faces de emacs21
pour xemacs ;; càd builtin-face défini à partir de preprocessor-face ;;
constant-face défini à partir de reference-face ;; FIXME comme cc, on
définit les faces par group c'est plus puissant ;; Dans un futur
lointain, séparer en trois niveau
;; val is no longer a keyword (defvar ocamlr-font-lock-keywords (list
'("^#\\(\\w+\\) \"?\\(\\w+\\)\"?;" (1 'font-lock-builtin-face) (2
'font-lock-variable-name-face))
'("\\&lt;\\(external\\|open\\|include\\)\\&gt;[
\t\n]*\\([_A-Za-z\277-\377]\\(\\w\\|[._]\\)*\\);" (1
'font-lock-builtin-face) (2 'font-lock-constant-face) nil)
'("\\&lt;\\(and\\|as\\|assert\\|asr\\|closed\\|constraint\\|do\\|done\\|downto\\|else\\|for\\|fun\\|functor\\|if\\|in\\|include\\|land\\|lazy\\|lor\\|lsl\\|lsr\\|lxor\\|match\\|mod\\|mutable\\|new\\|of\\|or\\|parse\\|parser\\|private\\|ref\\|then\\|to\\|try\\|virtual\\|when\\|where\\|while\\|with\\)\\&gt;"
0 'font-lock-keyword-face nil)
'("\\&lt;\\(begin\\|class\\|end\\|external\\|inherit\\|method\\|module\\|rec\\|sig\\|struct\\|value\\)\\&gt;"
0 'font-lock-builtin-face)
;; value rec, colorier le nom de fonction
'("\\&lt;\\(and\\|value\\)\\s-*\\(\\<rec\\>\\s-*\\)?\\(\\w+\\)\\s-+="
            (3 'font-lock-function-name-face))
;; value rec, colorier le nom de fonction ET les variables
          '("\\&lt;\\(and\\|value\\)\\s-*\\(\\<rec\\>\\s-*\\)?\\(\\w+\\)\\s-+\\([^=]+\\)="
            (3 'font-lock-function-name-face) (4 'font-lock-variable-name-face))
          '("\\&lt;\\(type\\)[ \t\n]+\\([^=]+\\)="
            (1 'font-lock-builtin-face) (2 'font-lock-type-face))
          '("\\&lt;\\(let\\)[ \t\n]*\\([^=]+\\)="
            (1 'font-lock-keyword-face) (2 'font-lock-variable-name-face))
          '("\\&lt;\\(exception\\)\\&gt;[ \t]*\\(\\&lt;[_A-Za-z\277-\377]\\(\\w\\|_\\)*\\&gt;\\)"
            (1 'font-lock-keyword-face) (2 'font-lock-variable-name-face))
          '("[][;,()|{}@^!:*=&lt;&gt;&amp;/%+~?---]\\.?\\|\\.\\." 0 'ocamlr-font-lock-operator-face nil)
          '("\\([?~]?[_A-Za-z\277-\377]\\(\\w\\|_\\)*[ \t\n]*:\\)[^:&gt;=]"
            1 'font-lock-variable-name-face nil)
;; Not so sure it's for the record definition. See if it conflicts with another thing.
          '("\\&lt;\\(\\w+\\)\\s-+:\\s-+" 1 'font-lock-variable-name-face nil)
          '("\\&lt;\\(array\\|bool\\|float\\|int\\|list\\|string\\|unit\\)\\&gt;"
            0 'font-lock-type-face nil)
          '("\\&lt;\\([A-Z]\\(\\w\\|_\\)*\\)"
            1 'font-lock-constant-face nil)
          )
        "Additional expressions to highlight in OCamlr mode.  Default set.")
      (defvar ocamlr-font-lock-keywords-1 ocamlr-font-lock-keywords
        "Additional expressions to highlight in OCamlr mode.  Minimal set.")
      (defvar ocamlr-font-lock-keywords-2 ocamlr-font-lock-keywords
        "Additional expressions to highlight in Ocamlr mode.  Maximal set")

      (if (featurep 'sym-lock)
	  ;; to change this table, xfd -fn '-adobe-symbol-*--12-*' may be
	  ;; used to determine the symbol character codes.
	  (defvar ocamlr-sym-lock-keywords
	    '(("&lt;-" 0 1 172)
	      ("-&gt;" 0 1 174)
	      (":=" 0 1 220)
	      ("&lt;=" 0 1 163)
	      ("&gt;=" 0 1 179)
	      ("&lt;&gt;" 0 1 185)
	      ("==" 0 1 186)
	      ("||" 0 1 218)
	      ("&amp;&amp;" 0 1 217)
	      ("[^*]\\(\\*\\)\\." 1 8 180)
	      ("\\(/\\)\\." 1 3 184)
	      (":&gt;" 0 1 202)
	      (";;" 0 1 191)
	      ;; ("\\&lt;_\\&gt;" 0 3 188)
	      ("\\<sqrt\\>" 0 3 214)
	      ("\\<unit\\>" 0 3 198)
	      ;; ("\\<fun\\>" 0 3 108)
	      ("\\<or\\>" 0 3 218)
	      ("\\<not\\>" 0 3 216))
	    "If non nil: Overrides default Sym-Lock patterns for Ocamlr."))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                    Keymap

(defvar ocamlr-mode-map nil
  "Keymap used in Ocamlr mode.")
(setq ocamlr-mode-map (make-sparse-keymap))
(define-key ocamlr-mode-map "\t" 'ocamlr-indent-command)
(define-key ocamlr-mode-map "\M-\C-a" 'ocamlr-beginning-of-phrase)
(define-key ocamlr-mode-map "\M-\C-e" 'ocamlr-end-of-phrase)

(defvar ocamlr-mode-syntax-table ()
  "Syntax table in use in Ocamlr mode buffers.")
(setq ocamlr-mode-syntax-table (make-syntax-table))
(modify-syntax-entry ?_ "_" ocamlr-mode-syntax-table)
(modify-syntax-entry ?_ "w" ocamlr-mode-syntax-table)
(modify-syntax-entry ?? "w" ocamlr-mode-syntax-table)
(modify-syntax-entry ?~ "w" ocamlr-mode-syntax-table)
(modify-syntax-entry ?: "." ocamlr-mode-syntax-table)
(modify-syntax-entry ?' "w" ocamlr-mode-syntax-table)
;; ' is part of words (for primes)
(modify-syntax-entry ?` "." ocamlr-mode-syntax-table)
(modify-syntax-entry ?\" "\"" ocamlr-mode-syntax-table)
;; " is a string delimiter
(modify-syntax-entry ?\\ "\\" ocamlr-mode-syntax-table)
(modify-syntax-entry ?\( "()1" ocamlr-mode-syntax-table)
(modify-syntax-entry ?*  ".23" ocamlr-mode-syntax-table)
(modify-syntax-entry ?\) ")(4" ocamlr-mode-syntax-table)
(let ((i 192))
  (while (&lt; i 256)
    (modify-syntax-entry i "w" ocamlr-mode-syntax-table)
    (setq i (1+ i))))

(defconst ocamlr-font-lock-syntax
  '((?_ . "w") (?` . ".") (?\" . ".") (?\( . ".") (?\) . ".") (?* . "."))
  "Syntax changes for Font-Lock.")

(defvar ocamlr-mode-abbrev-table ()
  "Abbrev table used for Ocamlr mode buffers.")
(defun ocamlr-define-abbrev (keyword)
  (define-abbrev ocamlr-mode-abbrev-table keyword keyword 'ocamlr-abbrev-hook))
(if ocamlr-mode-abbrev-table ()
  (setq ocamlr-mode-abbrev-table (make-abbrev-table))
  (mapcar 'ocamlr-define-abbrev
	  '("module" "class" "object" "type" "inherit" "virtual"
	    "constraint" "exception" "external" "open" "method" "and"
	    "initializer" "to" "downto" "do" "done" "else" "begin" "end"
	    "let" "in" "then" "with"))
  (setq abbrevs-changed nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                              The major mode

(defun ocamlr-mode ()
  "Major mode for editing revised OCaml code.

Dedicaced to Emacs, Version 21 and higher. Provides
automatic indentation and compilation interface. Performs font/color
highlighting using Font-Lock. It is only designed for Objective Caml
combined with the revised syntax, in all other cases please use ocamlr-mode.

Report bugs, remarks and questions to cgillot@neo-rousseaux.org
"
  (interactive)
  ;; hooks for ocamlr-mode, use them for ocamlr-mode configuration
  (run-hooks 'ocamlr-mode-hook)
;;  (ocamlr-install-font-lock)
  (kill-all-local-variables)
  (setq major-mode 'ocamlr-mode)
  (setq mode-name "Ocamlr")
  (use-local-map ocamlr-mode-map)
  (set-syntax-table ocamlr-mode-syntax-table)
;;  (setq local-abbrev-table ocamlr-mode-abbrev-table)
  (make-local-variable 'comment-start)
  (setq comment-start "(*")
  (make-local-variable 'comment-end)
  (setq comment-end "*)")
  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)
  (make-variable-buffer-local 'before-change-functions)
  (add-hook 'before-change-functions 'ocamlr-before-change-function)
  (set (make-local-variable 'beginning-of-defun-function)
       'ocamlr-beginning-of-phrase)
  (set (make-local-variable 'end-of-defun-function)
       'ocamlr-end-of-phrase)
  (make-local-variable 'comment-end)
  (ocamlr-install-font-lock)
  (message (concat "Major mode for revised OCaml programs, "
		   ocamlr-mode-version ".")))

(defun ocamlr-install-font-lock (&amp;optional no-sym-lock)
  (if (and (featurep 'font-lock)
           (or ocamlr-window-system ocamlr-with-xemacs))
      (progn
        (ocamlr-set-font-lock-faces)
        (if (and (not no-sym-lock)
                 (featurep 'sym-lock)) ; AFTER ocamlr-set-font-lock-faces
            (progn
              (setq sym-lock-color
                    (face-foreground 'ocamlr-font-lock-operator-face))
              (if (not sym-lock-keywords)
                  (sym-lock ocamlr-sym-lock-keywords))))
        (add-hook 'font-lock-mode-hook 'ocamlr-font-lock-hook)
        (make-variable-buffer-local 'font-lock-defaults)
;;        (setq font-lock-defaults 
;;              '(('ocamlr-font-lock-keywords ocamlr-font-lock-keywords-1 
;;                                           ocamlr-font-lock-keywords-2)))
              
         (setq font-lock-defaults
               (list 'ocamlr-font-lock-keywords t nil
                     ocamlr-font-lock-syntax nil))
        (make-variable-buffer-local 'font-lock-fontify-buffer-function)
        (if (boundp 'font-lock-fontify-buffer-function)
            (setq font-lock-fontify-buffer-function 'ocamlr-fontify-buffer)
          (add-hook 'font-lock-after-fontify-buffer-hook
                    'ocamlr-after-fontify-buffer))
        (make-variable-buffer-local 'font-lock-fontify-region-function)
        (if (boundp 'font-lock-fontify-region-function)
            (setq font-lock-fontify-region-function 'ocamlr-fontify-region))
        (font-lock-set-defaults)
;;         (if (not (or ocamlr-with-xemacs font-lock-mode))
;;             (font-lock-mode 1)) ; useful for beginners if not standard
        'font-lock)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                              Motion code (to be put in ocamlr-motion)

(defun ocamlr-skip-blank-and-comments ()
  (skip-chars-forward " \t\n")
  (while (and (&lt; (point) (point-max)) (ocamlr-in-comment-p)
              (re-search-forward "\\*)" (point-max) t))
    (skip-chars-forward " \t\n")))

(defun ocamlr-skip-back-blank-and-comments ()
  (skip-chars-backward " \t\n")
  (while (save-excursion (ocamlr-backward-char)
                         (and (&gt; (point) (point-min)) (ocamlr-in-comment-p)))
    (ocamlr-backward-char)
    (ocamlr-beginning-of-literal-or-comment) (skip-chars-backward " \t\n")))

(defmacro ocamlr-even (var)
  (list '= 0 (list 'mod var 2)))

(defmacro ocamlr-odd (var)
  (list '/= 0 (list 'mod var 2)))

;; I don't understand why such a feature don't exist in the standard library
;; FIXME: about making them macros ?
(defun ocamlr-re-nbr-matches-forward-helper (regexp limit count)
  (if (re-search-forward regexp limit t)
      (ocamlr-re-nbr-matches-forward-helper regexp limit (1+ count))
    count))

(defun ocamlr-re-nbr-matches-forward (regexp limit)
  "Return the number of matches forward between point and limit."
  (save-excursion (ocamlr-re-nbr-matches-forward-helper regexp limit 0)))

(defun ocamlr-re-nbr-matches-backward-helper (regexp limit count)
  (if (re-search-backward regexp limit t)
      (ocamlr-re-nbr-matches-backward-helper regexp limit (1+ count))
    count))

(defun ocamlr-re-nbr-matches-backward (regexp limit)
  "Return the number of matches backward between point and limit."
  (save-excursion (ocamlr-re-nbr-matches-backward-helper regexp limit 0)))

(defun ocamlr-is-in-string ()
  "Return t if the point is in a string, nil otherwise"
  (interactive)
  (save-excursion 
    (let* ((nbr-quotes-backward 
	    (progn 
	      (forward-char)
	      (ocamlr-re-nbr-matches-backward "[^\\\\]\"" (1- (line-beginning-position)))))
	   (nbr-quotes-forward 
	    (prog2 
		(backward-char 2)
		(ocamlr-re-nbr-matches-forward "[^\\\\]\"" (1+ (line-end-position)))
	      (forward-char)))
	   ;; This is for managing the multiline strings
	   (last-char-before (1- (line-beginning-position))))
      (when (and (&gt; last-char-before (point-min))
		 (= (char-before last-char-before) ?\\))
	(setq nbr-quotes-backward (1+ nbr-quotes-backward)))
      (when (= (char-before (line-end-position)) ?\\)
	(setq nbr-quotes-forward (1+ nbr-quotes-forward)))
      ;; if both nbr-quotes-backward and nbr-quotes-forward are odd
      ;; then we are in a string
      ;; if both are even then we are not in a string
      ;; if one is even and the other odd then we have something unexpected
      ;; we are likely to be in a commentary so we fake we are not in a string in that case
      ;; FIXME: check if we can improve it
      (if (and (ocamlr-odd nbr-quotes-backward)
	       (ocamlr-odd nbr-quotes-forward))
	  (progn t)
      (progn  nil)))))
;;	  (progn (message "We are in a string f:%d b%d" nbr-quotes-forward nbr-quotes-backward) t)
;;	(progn (message "We are NOT in a string f:%d b:%d" nbr-quotes-forward nbr-quotes-backward) nil)))))

;; Ça ne servira jamais pour ce mode mais c'est pour voir...
(defun tian-insert-list (start end)
  "Insert a list in the current buffer with the form 01\\n02\\n..end"
  (interactive "nStart:\nnEnd:")
  (setq counter start)
  (while (&lt;= counter end)
    (if (&lt; counter 10)
	(insert (format "0%d\n" counter))
      (insert (format "%d\n" counter)))
    (setq counter (1+ counter))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             Indentation code (to be put in ocamlr-indent)


;; 1. A lo bourrin +2 à chaque ligne
;; 2. Vérifier que ce n'est pas une déclaration
;; 3. Si c'est un ; final ne pas indenter
;; 4. Gérer les listes (records, tuples, etc)
;; 5. Gérer la correspondance de motif (pattern matching)
;; 6. Ja ho veurem...

;;
(defun ocamlr-indent-command ()
  "Indent the current line in Ocamlr mode.
It only indent the ocaml code with the revised syntax."
  (interactive "*")
  (save-excursion
    (back-to-indentation)
    (let ((indent (ocamlr-calculate-indent)))
      (if (eq indent nil)
          ()
        (indent-line-to indent)))))


;; FIXME EL IN NO FUNCIONA...
;; ES CLAR està posat al principi i per això pot funcionar..
(defconst ocamlr-new-block-regexp
  "\\(type.+=\\|where.+=\\|value.+=\\|let.+=\\|^\\s-*in\\|then\\|else\\)\\(\\s-*\\|.+;\\)$")
(defconst ocamlr-declaration-regexp
  "\\(type.+=\\|where.+=\\|value.+=\\|open\\s-\\|exception\\s-\\|#\\w+\\s-\\)\\(\\s-*\\|.+;\\)$")
(defconst ocamlr-end-block-regexp
  "^\\s-\\(else\\)")
(defconst ocamlr-new-list-regexp
  "\\({\\|\\[\\)")
(defconst ocamlr-end-list-regexp
  "\\(}\\|\\]\\)")
(defconst ocamlr-elt-list-regexp
  "[;]$")

;; TODO:
;; 2-characters sexp navigation (nécessaire ?)
;; in fait un nouveau bloc
;; -&gt; fait un nouveau bloc
;; where mal géré
;; [: considéré comme faisant partie d'un match
;; [ de liste également...
;; Problème de création de bloc quand il ne faut pas cf l98
;; P.e L200 max-lisp-eval-depth
;; L214
;; try fait un nouveau bloc
;; cf L243 récursion de let in
;; les objets.
;; 
;; RÈGLE GÉNÉRALE:
;;
;; le where c'est un truc chiant
;; à gérer plus ou moins comme let in

;; TÂCHES À RÉALISER :
;; * la gestion des phrases n'est pas encore optimale.
;; * une liste n'est pas bien indenté mais est reconnue comme faisant partie d'un match
;; * Aparemment mon code prend les ; d'une liste comme fin de phrase
;; * with/try [FIXME: imbrication]
;;
;; Dans un futur hipothétique repérer le ( qui fait qu'on indente à plus trois

(defun ocamlr-calculate-indent ()
  "Return appropriate indentation for current line as revised Ocaml code.
In usual case returns an integer: the column to indent to.
Returns nil if line is in a comment."
  (save-excursion
    (back-to-indentation)
;;    (setq inici (float-time) calcul-frase nil fi nil)
    (if (ocamlr-in-comment-p) nil
      (let ((phrase-limits (ocamlr-discover-phrase)))
;;        (setq calcul-frase (float-time))
        (cond 
         ;; New phrase
         ((or (= (point) (car phrase-limits))
              ;;FIXME: ça dépend comment fonctionne mark-phrase,
              ;; là il part devant, je ne sais pas s'il faut que je le laisse...
              (&lt; (point) (car phrase-limits)))
          (progn (message "NEW PHRASE!!!")
                 (if  (&lt; (point) (car phrase-limits)) 
                     (message "BETWEEN TWO PHRASES!!!"))
                 (ocamlr-phrase-indentation)))
         ((save-excursion (looking-at ocamlr-end-list-regexp))
          (progn (message "END OF LIST:«%s»..." (match-string 0))
                 (save-excursion 
                   (goto-char (match-end 0))
                   (ocamlr-backward-sexp)
                   (back-to-indentation)
;;                   (if (save-excursion (backward-word 1) (looking-at "do"))
;;                       (backward-word 1))
                   (current-column))))
         ((looking-at "and\\&gt;") 
          ;; FIXME: sempre com per la phrase, segurament fer-ne una function
          (progn (message "AND")
                 (ocamlr-phrase-indentation)))
         ((looking-at "with\\&gt;") 
          ;;FIXME ça ne gère pas les imbrications...
          (progn (message "WITH")
                 (ocamlr-re-search-backward "\\<try\\>" (car phrase-limits))
                 (back-to-indentation)
                 (current-column)))
         ((save-excursion (re-search-forward "^\\s-*;$" (line-end-position) t))
          (progn (message "PUTAIN OF THE END OF THE LINE OF MERDE") (ocamlr-phrase-indentation)))
;; NO procedent
;;         ((save-excursion (re-search-forward ocamlr-declaration-regexp (line-end-position) t))
;;          (progn (message "C UNE DECLARATION DE PHRASE") (current-column)))
         ;; FIXME: no va això podria ser una cosa estil Anythingelse
         ;; pigé?
         ((save-excursion (looking-at "in\\&gt;"))
          (progn (message "LOOKING AT IN") (re-search-backward "\\<let\\s-*.+\\s-*=.*") (current-column)))="" ((save-excursion="" (looking-at="" then\\="">"))
          (progn (message "LOOKING AT THEN") (ocamlr-backward-to-start-of-if)
                 (current-column)))
         ((save-excursion (looking-at "else\\&gt;"))
          (progn (message "LOOKING AT ELSE") (ocamlr-backward-to-start-of-if) 
                 (current-column)))
         ((= (following-char) ?|)
          (progn (message "LOOKING AT | IN A MATCH") 
                 (ocamlr-calculate-indent-match (car phrase-limits))))
         ((save-excursion 
            (and (= (following-char) ?\[)
                 (progn (ocamlr-skip-back-blank-and-comments)
                        (backward-word 1)
                        (looking-at "\\(with\\|fun\\)\\&gt;"))))
          (progn 
            (setq try-with nil)
            (save-excursion
              (ocamlr-skip-back-blank-and-comments) 
              (back-to-indentation)
              (setq try-with (looking-at "with")))
            (if try-with
                (progn (message "LOOKING AT [ INSIDE WITH")
                       (ocamlr-skip-back-blank-and-comments) 
                       (back-to-indentation)
                       (+ ocamlr-default-indent (current-column)))
              (message "LOOKING AT [ INSIDE MATCH")
              (ocamlr-calculate-indent-match (car phrase-limits)))))
         (t
          (save-excursion
            (ocamlr-skip-back-blank-and-comments)
            (back-to-indentation)
;;            (forward-line -1) ;; Remplacer cette fonction par une qui 
            ;;renvoit la ligne précédente intéressante c-à-d sautant les lignes vides et les commentaires
            (cond 
             ;; Process a -&gt;
             ((save-excursion (end-of-line)
                              (backward-char 2)
                              (looking-at "-&gt;"))
              (message "-&gt;") 
              (skip-chars-forward "| ")
              (+ ocamlr-default-indent (current-column)))
             ;; Process let .+ in
             ((looking-at "let\\&gt;.+\\<in\\s-*$") (progn="" (message="" looking="" at="" let="" body="" )="" (current-column)))="" ;;="" process="" a="" with="" pattern="" match="" ((looking-at="" with\\="">\\s-*$")
              (progn (message "with PATTERN MATCHING")
                     (+ ocamlr-default-indent (current-column))))
             ;; process a list
             ((save-excursion (end-of-line)
                              (= (preceding-char) ?\;))
              (end-of-line)
              (ocamlr-go-to-beginning-list)
              (skip-chars-forward "[{:")
;;              (forward-char 1)
              (ocamlr-skip-blank-and-comments)
              (message "LIST")
              (current-column))
             ;; otherwise we consider it to be a new group
             ;; process a new block
             (t (progn
                  (message "new group +2")
                  (+ ocamlr-default-indent (current-column))
                  ))
             )
            )
          )
         )
;;        (setq fi (float-time))
;;        (sit-for 0 200)
;;        (message "Récapitulatiu total %f inici frase %f altre %f" 
;;                 (- fi inici) (- calcul-frase inici) (- fi calcul-frase))
        ))))

;; Get to the preceding phrase
;; si le point n'a pas changé ou est égal à 1
;; indentation 0
;; if the preceding one is a «module/struct/object» +2
;; sinon la même chose
(defun ocamlr-phrase-indentation ()
  "Returns the indentation of the first line of the current phrase"
  (save-excursion 
    (beginning-of-line)
    (ocamlr-beginning-of-phrase)
    (if (= (point) (point-min)) 0
      (back-to-indentation)
      (if (looking-at
           "\\&lt;\\(module\\|struct\\|object\\)\\&gt;")
          (+ ocamlr-default-indent (current-column))
        (current-column)
        ))))

;; Les funcions de emacs no funcionene com haurian de fer-ho
(defun ocamlr-backward-sexp (&amp;optional no)
  (backward-sexp no))

(defun ocamlr-backward-up-list (&amp;optional no)
  "Safe up-list regarding comments, literals and errors."
  (let ((balance (if no no 1)) (op (point)) (oc nil))
    (ocamlr-in-literal-or-comment)
    (while (and (&gt; (point) (point-min)) (&gt; balance 0))
      (setq oc (if ocamlr-cache-local (caar ocamlr-cache-local) (point-min)))
      (condition-case nil (up-list -1) (error (goto-char (point-min))))
      (if (&gt;= (point) oc) (setq balance (1- balance))
        (goto-char op)
        (skip-chars-backward "^[]{}()") (ocamlr-backward-char)
        (if (not (ocamlr-in-literal-or-comment-p))
            (cond
             ((looking-at "[[{(]")
              (setq balance (1- balance)))
             ((looking-at "[]})]")
              (setq balance (1+ balance))))
          (ocamlr-beginning-of-literal-or-comment-fast)))
      (setq op (point)))))


(defun ocamlr-forward-sexp (&amp;optional no)
  (forward-sexp no))

;; Go to the beginning of a list, with the point in the list
;; move the point to the beginning of the list
(defun ocamlr-go-to-beginning-list ()
  "FIXME"
;; FIXME::: attention à prendre la liste qui a matché
  (let ((origin (point))
        (new-list (save-excursion (ocamlr-re-search-backward ocamlr-new-list-regexp))))
    (if (ocamlr-re-search-backward ocamlr-end-list-regexp new-list t)
        (progn (forward-char 1) (backward-sexp) 
               (ocamlr-go-to-beginning-list))
      (goto-char new-list))))

;; FIXME: Tian t'es un imbécile !!!!
;; Et emacs aussi...
(defun ocamlr-go-to-beginning-match (beginning-phrase)
  (let ((origin (point))
        (beginning-match
         (ocamlr-re-search-backward
          "\\(\\]\\|\\&lt;\\(fun\\|match\\|parse\\|parser\\)\\&gt;\\)" beginning-phrase t)))
        (if (= (following-char) ?\])
            (progn (backward-char 1)
                   (ocamlr-go-to-beginning-match beginning-phrase)
                   (backward-char 1)
                   (ocamlr-go-to-beginning-match beginning-phrase)))))

(defun ocamlr-calculate-indent-match (beginning-phrase)
  "FIXME"
  (save-excursion
    (if (= (following-char) ?\[)
        (progn
          (ocamlr-re-search-backward
           "\\&lt;\\(fun\\|match\\|parse\\|parser\\)\\&gt;" beginning-phrase t))
      (ocamlr-backward-up-list))
    (current-column)
    ))

;; Un cop un d'aquest s'hagi trobat s'ha de pensar una miqueta  
;;   (back-to-indentation)
;;   (ocamlr-skip-back-blank-and-comments)
;;   (if (= (preceding-char) ?\]) 
;;       (progn
;;         (backward-sexp)
;;         (backward-word 1)
;;         (if (looking-at "fun\\&gt;\\|with\\&gt;")
;;             (ocamlr-calculate-indent-match))))
;;   (back-to-indentation)
;;   (if (looking-at "\\(|\\|\\[\\|\\<fun\\>\\|\\<match\\>\\)")
;;       (current-column)
;;     (ocamlr-calculate-indent-match)))

(defun ocamlr-backward-to-start-of-if (&amp;optional lim)
  (interactive)
  ;; En català : cerco el if.
  ;; Cerco si hi ha entre el if i el punt d'origen else
  ;; Si en trobo cap, ja està, sino cal fer re-search-backward de if
  ;; el numero de cop trobat - 1 (clar per que ja estem al primer)
  (progn 
    (let ((start (point)))
      (ocamlr-re-search-backward "\\<if\\>" nil t)
      (let ((no-else (save-excursion  
                       (ocamlr-re-nbr-matches-forward "\\<else\\>" start))))
        ;; Qu'est-ce que je dois faire ?
        ;; Donc retourner en arrière le nombre de fois requis
        (if (= no-else 0) t
          (when (&gt; no-else 1) (ocamlr-re-search-backward "\\<if\\>" (1- no-else) t))
          ;; Et faire une itération de plus....
          (ocamlr-backward-to-start-of-if)
          )))))

(defun ocamlr-backward-to-start-of-then (&amp;optional lim)
  (interactive)
  (progn 
    (let ((start (point)))
      (ocamlr-re-search-backward "\\<then\\>" nil t)
      (let ((no-else (save-excursion  
                       (ocamlr-re-nbr-matches-forward "\\<else\\>" start))))
        ;; Qu'est-ce que je dois faire ?
        ;; Donc retourner en arrière le nombre de fois requis
        (if (= no-else 0) t
          (when (&gt; no-else 1) (ocamlr-re-search-backward "\\<then\\>" (1- no-else) t))
          ;; Et faire une itération de plus....
          (ocamlr-backward-to-start-of-then)
          )))))

;; FIXME: trouver un meilleur nom
(defun ocamlr-backward-skipping-subconstruction 
  (re-looked-for re-neutralizing)
  "FIXME"
  (let ((start (point)))
    (ocamlr-re-search-backward re-looked-for)
    (let ((end (point)))
          (if (save-excursion
                (goto-char start)
                (ocamlr-re-search-backward re-neutralizing end t))
              (progn (message "Neutralizing found ! %d" end) 
                     (sit-for 0 500)
                     (goto-char start)
                     (ocamlr-re-search-backward re-neutralizing end t)
                     (ocamlr-backward-skipping-subconstruction re-looked-for
                                                               re-neutralizing))
            (progn (message "Neutralizing *NOT* found ! %d %d" (point) end) (sit-for 0 500))))))

;; The same than the standard one but skipping the comments(
(defun ocamlr-re-search-forward (regexp &amp;optional limit noerror
                                        repeat)
  (interactive)
  (let ((no (if repeat repeat 1)))
    (when (re-search-forward regexp limit noerror)
      (if (ocamlr-in-literal-or-comment-p)
          (ocamlr-re-search-forward regexp limit noerror no)
        (if (&gt; no 1)
            (ocamlr-re-search-forward regexp limit noerror (1- no))
          (point))))))

(defun ocamlr-re-search-backward (regexp &amp;optional limit noerror
                                        repeat)
  (interactive)
  (let ((no (if repeat repeat 1)))
    (when (re-search-backward regexp limit noerror)
      (if (ocamlr-in-literal-or-comment-p)
          (ocamlr-re-search-backward regexp limit noerror no)
        (if (&gt; no 1)
            (ocamlr-re-search-backward regexp limit noerror (1- no))
          (point))))))

;;(save-excursion (goto-char (point-min)) (bobp)) ;; beginning of the buffer
        ;; si es tracta de un element dins un llistat
        ;; en altres casos
;;         (if (= (current-column) 0)
;;             (current-column)
;;           (+ ocamlr-default-indent
;;              (current-column)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                  Font-Lock

;; (defun ocamlr-install-font-lock 
;;   (when (featurep 'font-lock)
;;       (message "I'll do it one day...")))
;; FAIS CHIER !!!!!!!!

;; Refaire l'algorithme de navigation entre les phrases.
;; Sûrement passer à un cache semblable à celui des commentaires
;; de ocamlr
;; FIXME:  le - 10 doit être inutile mainte règle le problème...
(defun ocamlr-before-change-function (begin end)
  (setq ocamlr-cache-stop (min ocamlr-cache-stop (1- begin))
        ocamlr-phrase-break-cache-stop 
        (min ocamlr-phrase-break-cache-stop (- begin 10))))

(defvar ocamlr-cache-stop (point-min))
(make-variable-buffer-local 'ocamlr-cache-stop)
(defvar ocamlr-cache nil)
(make-variable-buffer-local 'ocamlr-cache)
(defvar ocamlr-cache-local nil)
(make-variable-buffer-local 'ocamlr-cache-local)
(defvar ocamlr-cache-last-local nil)
(make-variable-buffer-local 'ocamlr-cache-last-local)
(defvar ocamlr-last-loc (cons nil nil))

;; FIXME: Il faudrait fusioner les deux caches.
(defvar ocamlr-phrase-break-cache-stop (point-min))
(make-variable-buffer-local 'ocamlr-phrase-break-cache-stop)
(defvar ocamlr-phrase-break-cache nil)
(make-variable-buffer-local 'ocamlr-phrase-break-cache)

(defun ocamlr-forward-char (&amp;optional step)
  (if step (goto-char (+ (point) step))
    (goto-char (1+ (point)))))

(defun ocamlr-backward-char (&amp;optional step)
  (if step (goto-char (- (point) step))
    (goto-char (1- (point)))))

(defun ocamlr-in-literal-p ()
  "Returns non-nil if point is inside a Caml literal."
  (car (ocamlr-in-literal-or-comment)))
(defun ocamlr-in-comment-p ()
  "Returns non-nil if point is inside a Caml comment."
  (cdr (ocamlr-in-literal-or-comment)))
(defun ocamlr-in-literal-or-comment-p ()
  "Returns non-nil if point is inside a Caml literal or comment."
  (ocamlr-in-literal-or-comment)
  (or (car ocamlr-last-loc) (cdr ocamlr-last-loc)))

(defun ocamlr-in-literal-or-comment ()
  "Returns the pair `((ocamlr-in-literal-p) . (ocamlr-in-comment-p))'."
  (if (and (&lt;= (point) ocamlr-cache-stop) ocamlr-cache)
      (progn
        (if (or (not ocamlr-cache-local) (not ocamlr-cache-last-local)
                (and (&gt;= (point) (caar ocamlr-cache-last-local))))
            (setq ocamlr-cache-local ocamlr-cache))
        (while (and ocamlr-cache-local (&lt; (point) (caar ocamlr-cache-local)))
          (setq ocamlr-cache-last-local ocamlr-cache-local
                ocamlr-cache-local (cdr ocamlr-cache-local)))
        (setq ocamlr-last-loc
              (if ocamlr-cache-local
                  (cons (eq (cadar ocamlr-cache-local) 'b)
                        (&gt; (cddar ocamlr-cache-local) 0))
                (cons nil nil))))
    (let ((flag t) (op (point)) (mp (min (point) (1- (point-max))))
          (balance 0) (end-of-comment nil))
      (while (and ocamlr-cache (&lt;= ocamlr-cache-stop (caar ocamlr-cache)))
        (setq ocamlr-cache (cdr ocamlr-cache)))
      (if ocamlr-cache
          (if (eq (cadar ocamlr-cache) 'b)
              (progn
                (setq ocamlr-cache-stop (1- (caar ocamlr-cache)))
                (goto-char ocamlr-cache-stop)
                (setq balance (cddar ocamlr-cache))
                (setq ocamlr-cache (cdr ocamlr-cache)))
            (setq balance (cddar ocamlr-cache))
            (setq ocamlr-cache-stop (caar ocamlr-cache))
            (goto-char ocamlr-cache-stop)
            (skip-chars-forward "("))
        (goto-char ocamlr-cache-stop))
      (skip-chars-backward "\\\\*")
      (while flag
        (if end-of-comment (setq balance 0 end-of-comment nil))
        (skip-chars-forward "^\\\\'`\"(\\*")
        (cond
         ((looking-at "\\\\")
          (ocamlr-forward-char 2))
         ((looking-at "'\\([^\n']\\|\\\\..?.?\\)'")
          (ocamlr-forward-char)
          (setq ocamlr-cache (cons (cons (point) (cons 'b balance))
                                   ocamlr-cache))
          (skip-chars-forward "^'") (ocamlr-forward-char)
          (setq ocamlr-cache (cons (cons (point) (cons 'e balance))
                                   ocamlr-cache)))
         ((looking-at "\\*)")
          (ocamlr-forward-char 2)
          (if (&gt; balance 1)
              (prog2
                  (setq balance (1- balance))
                  (setq ocamlr-cache (cons (cons (point) (cons nil balance))
                                           ocamlr-cache)))
            (setq end-of-comment t)
            (setq ocamlr-cache (cons (cons (point) (cons nil 0))
                                     ocamlr-cache))))
         ((looking-at "(\\*")
          (setq balance (1+ balance))
          (setq ocamlr-cache (cons (cons (point) (cons nil balance))
                                   ocamlr-cache))
          (ocamlr-forward-char 2))
         ((looking-at "\"")
          (ocamlr-forward-char)
          (setq ocamlr-cache (cons (cons (point) (cons 'b balance))
                                   ocamlr-cache))
          (skip-chars-forward "^\\\\\"")
          (while (looking-at "\\\\")
            (ocamlr-forward-char 2) (skip-chars-forward "^\\\\\""))
          (ocamlr-forward-char)
          (setq ocamlr-cache (cons (cons (point) (cons 'e balance))
                                   ocamlr-cache)))
         (t (ocamlr-forward-char)))
        (setq flag (&lt;= (point) mp)))
      (setq ocamlr-cache-local ocamlr-cache
            ocamlr-cache-stop (point))
      (goto-char op)
      (if ocamlr-cache (ocamlr-in-literal-or-comment) 
        (setq ocamlr-last-loc (cons nil nil))
        ocamlr-last-loc))))

(defun ocamlr-beginning-of-literal-or-comment ()
  "Skips to the beginning of the current literal or comment (or buffer)."
  (interactive)
  (if (ocamlr-in-literal-or-comment-p)
      (ocamlr-beginning-of-literal-or-comment-fast)))

(defun ocamlr-beginning-of-literal-or-comment-fast ()
  (while (and ocamlr-cache-local
	      (or (eq 'b (cadar ocamlr-cache-local))
		  (&gt; (cddar ocamlr-cache-local) 0)))
    (setq ocamlr-cache-last-local ocamlr-cache-local
	  ocamlr-cache-local (cdr ocamlr-cache-local)))
  (if ocamlr-cache-last-local
      (goto-char (caar ocamlr-cache-last-local))
    (goto-char (point-min)))
  (if (eq 'b (cadar ocamlr-cache-last-local)) (ocamlr-backward-char)))



;; (defun ocamlr-auto-fill-function ()
;;   (if (not (ocamlr-in-literal-p))
;;       (do-auto-fill)))
;;
;; ocamlr-cache-end-of-phrase
;; Une liste contenant les position de fin de phrase (";")
;; En ordre inverse, c p-e plus simple
;; 3 6 100 394 504
;; 504 394 100 6 3 -&gt; ainsi on peut retirer tout ceux qui sont en trop.
;; Utiliser cache-stop comme le fait ce bonhomme

;; L'algorithme c'est :
;; S'il y a qqch dans le cache, faire le scan entre le point et le dernier 
;; caché
;; Sinon faire le scan entre point-min et point
;; Pour savoir si un ; précis est une fin de phrase c'est très facile.
;; S'il y a un do  non fermé entre le dernier ; et le point ça n'en est pas un
;; C général.
;; Est ; de fin de phrase tout ce qui n'est pas inclus dans un {} ou un []
;; A veure, al millor un parse-sexp m'ho fa.
;; Sûrement séparer en deux fonctions.
;; Parce qu'il faut que je puisse naviguer entre les fonctions
;; et également déterminer si un ; est une fin de déclaration.
;; Aparemment il ne faut pas que je le laisse ainsi mais
;; faire que ocamlr-beginning-of-phrase  et ocamlr-end-of-phrase 
;; retourne le point de fin i ja està...

;; FIXME Aparemment il gère de telle manière que le discover-phrase marque
;; le module en entier... Il faudra y faire attention un jour

;; FIXME MARCHE PAS AVEC LES PHRASES D'UNE LIGNE
(defun ocamlr-discover-phrase ()
  (interactive)
  (save-excursion
    (ocamlr-manage-phrase-break-cache)
    (end-of-line)
    (backward-char 1) ;; for the one-line phrases
    (let ((end (point)))

      (ocamlr-end-of-phrase)
      (setq end (point))
      (ocamlr-beginning-of-phrase)
      (list (point) end))))

(defun ocamlr-mark-phrase ()
  "Put mark at end of this OCaml phrase, point at beginning.
The OCaml phrase is the phrase just before the point."
  (interactive)
  (let ((pair (ocamlr-discover-phrase)))
    (goto-char (nth 1 pair)) (push-mark (nth 0 pair) t t)))

(defun ocamlr-beginning-of-phrase (&amp;optional arg)
  "Move backward to the beginning of a phrase.
With argument, do it that many times.  Negative arg -N
means move forward to Nth following beginning of defun.
Returns t unless search stops due to beginning or end of buffer."
  (interactive "p")
  (unless arg (setq arg 1))
  (ocamlr-manage-phrase-break-cache)
  (if (&lt; arg 0)
      (ocamlr-end-of-phrase (- arg))
    (let* ((origin (point))
           (phrase-breaks ocamlr-phrase-break-cache))
      ;; Trouver le phrase break qui est supérieur à ça
      ;; sachant que la liste est en ordre inverse
      ;; Pb s'il y a moins de deux définitions.
      (while (and (car phrase-breaks) (&gt; (car phrase-breaks) (point)))
        (setq phrase-breaks (cdr phrase-breaks)))
      (if (not phrase-breaks) 
          (progn 
            (if (and (not (bolp))
                     (progn (end-of-line) (ocamlr-at-phrase-break-p)))
                (beginning-of-line)
              (goto-char (point-min))))
        (goto-char (car phrase-breaks))
        (ocamlr-skip-blank-and-comments))
      (if (and phrase-breaks
               (&lt;= origin (point)))
          (progn
            (ocamlr-skip-back-blank-and-comments)
            (goto-char (1- (point)))
            (ocamlr-beginning-of-phrase arg)))
      (if (&gt; arg 1)
          (ocamlr-beginning-of-phrase (1- arg)))
      )))

(defun ocamlr-end-of-phrase (&amp;optional arg)
  "Move forward to next end of defun.  With argument, do it that many times.
Negative argument -N means move back to Nth preceding end of defun.
Returns t unless search stops due to beginning or end of buffer.

An end of a defun occurs right after the phrase-break `;'."
  (interactive "p")
  (unless arg (setq arg 1))
  (if (&lt; arg 0)
      (ocamlr-beginning-of-phrase (- arg))
    (progn
      (ocamlr-manage-phrase-break-cache)
      ;; Trouver le phrase break qui est supérieur à ça
      ;; sachant que la liste est en ordre inverse
      ;; Pb s'il y a moins de deux définitions.
      (let ((phrase-breaks ocamlr-phrase-break-cache))
        (cond ((and (car phrase-breaks) (&gt;= (point) (car phrase-breaks)))
               (goto-char (point-max)))
              ;;             ((not (cadr phrase-breaks)) 
              ;;              (goto-char (car phrase-breaks)))
              (t    
               (while (and (cadr phrase-breaks) 
                           (&gt; (cadr phrase-breaks) (point)))
                 (setq phrase-breaks (cdr phrase-breaks)))
               (goto-char (car phrase-breaks)))))
      (if (&gt; arg 1)
          (ocamlr-end-of-phrase (1- arg))))))

(defun ocamlr-manage-phrase-break-cache  (&amp;optional limit)
  (save-excursion 
    ;; if the cache is not enough, we update it
    (if (&gt;= (point) ocamlr-phrase-break-cache-stop)
        (progn
          ;; Delete the outdated entries
          (while (and (car ocamlr-phrase-break-cache)
                      (&gt;= (car ocamlr-phrase-break-cache)
                          ocamlr-phrase-break-cache-stop))
            (setq ocamlr-phrase-break-cache (cdr
                                             ocamlr-phrase-break-cache)))
;;           (message 
;;            "S'ha esborrat les entrade cache-stop : %d cache %s"
;;            ocamlr-phrase-break-cache-stop ocamlr-phrase-break-cache)
          ;; And update the content, 
          ;; we go to the last valid phrase break if such one exists.
          (if ocamlr-phrase-break-cache
              (goto-char (car ocamlr-phrase-break-cache))
            (goto-char ocamlr-phrase-break-cache-stop))
          (let ((limit  (if limit limit (point-max)))
                (end t) (result t))
            (while end
              (setq end (save-excursion
                          (ocamlr-re-search-forward "\\[\\|{" limit t)))
              (if end
                  (progn
                    (setq result t)
                    (while result
                      (setq result (ocamlr-re-search-forward ";" end t))
                      (if result
                          (setq ocamlr-phrase-break-cache
                                (cons (point) ocamlr-phrase-break-cache))))
                    (goto-char (1- end))
                    (forward-sexp))))
            ;;     ;; After the last sexp [FIXME: use a macro ?]
            (setq result t)
            (while result
              (setq result (ocamlr-re-search-forward ";" limit t))
              (if result
                  (setq ocamlr-phrase-break-cache
                        (cons (point) ocamlr-phrase-break-cache))))
;;             (message 
;;            "Resultat cache-stop : %d cache %s"
;;            ocamlr-phrase-break-cache-stop ocamlr-phrase-break-cache)
            (setq ocamlr-phrase-break-cache-stop limit)
            )))))

(defun ocamlr-at-phrase-break-p ()
  (progn
    (ocamlr-manage-phrase-break-cache)
    ;; We show a message indicating whether the ; is a phrase break
    (if (memq (point) ocamlr-phrase-break-cache) t nil)))

(defun ocamlr-at-phrase-break-p-nocache (&amp;optional limit)
  (interactive)
  (setq avant (float-time))
;;  (ocamlr-skip-blank-and-comments)
  (let ((limit  (if limit limit (point-max)))
        (end t)
        (result t))
    (while end
      (setq end 
            (save-excursion 
              (ocamlr-re-search-forward "\\[\\|{" limit t)))
      (if end
          (progn
            (setq result t)
            (while result
              (setq result (ocamlr-re-search-forward ";" end t))
              (if result
                    (setq ocamlr-phrase-break-cache
                          (cons (point) ocamlr-phrase-break-cache))))
            (goto-char (1- end))
            (forward-sexp)
            )))
;;     ;; After the last sexp [FIXME: use a macro ?]
    (setq result t)
    (while result
      (setq result (ocamlr-re-search-forward ";" limit t))
      (if result
          (setq ocamlr-phrase-break-cache
                (cons (point) ocamlr-phrase-break-cache))))
    (message "time taken: %f" (- (float-time) avant))
    (sit-for 1)
    (message "End of phrase: %s" ocamlr-phrase-break-cache)))
