;;; prg-comment.el --- This package helps to comment source code

;; Copyright (C) 2003 by Aurélien Tisné
;; Author: Aurélien Tisné <aurelien.tisne@free.fr>
;; Keywords: convenience, comment

;; This file is not part of GNU Emacs.

;;{{{ GPL

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}

;;{{{ Commentary
;;; Commentary:

;; This package defines headers and comment facilities that help the
;; developer to document his source code.  Using this package, the developer
;; may add quality in his production.  The coding rules are described into
;; a charter.  You can define your own charter or use an existing one.
;; It is elisp definitions of some variables and templates.  These
;; definitions describe the conventions you use to comment your code.
;;
;; Let me know if you improve or add new languages to this package.

;; Usage:
;;
;; Byte-compile this file and put the compiled file into the scope of your
;; load-path.
;; There is several ways to use the package:
;; * manual call
;;   Add the line
;;     (autoload 'prg-comment-set-charter "prg-comment")
;;   to your emacs initialization file (.emacs/_emacs), then select your buffer
;;   and call interactively the function
;;     prg-comment-set-charter RET <charter> RET
;;   where <charter> is the name of a defined charter.
;;
;; * automatic call
;;   Add the lines
;;     (autoload 'prg-comment-use-it "prg-comment")
;;     (add-hook '<major-mode>-hook 'prg-comment-use-it)
;;     (setq prg-comment-charters-alist
;;        '(("~/gnu" . open-source)
;;          ("~/work" . my-company)
;;          ("~/work/airbus" . airbus)))
;;   to your emacs initialization file (.emacs/_emacs), where <major-mode>
;;   is the major mode that want to use prg-comment. Redefine the
;;   `prg-comment-charters-alist' variable according to each of your
;;   personal workspaces.
;;   In the previous example, each file edited with the <major-mode> and
;;   located into the "d:/users/atisne/work" subtree, will use the my-company
;;   charter; except the files located into the "d:/users/atisne/work/airbus"
;;   subtree that will use the airbus charter. The mode will choose the
;;   charter associated to the deeper path declared in the association list
;;   `prg-comment-charters-alist'.
;;
;; You can, of course, combine the both call types.

;; Material description
;;
;; * Charter
;; Charters are located in `prg-comment-material-path'/charter.
;; A charter describes all comment conventions.
;; The default charter is named 'default.el'.
;; An exhaustive declaration defines:
;;
;; - the language of the charter (`prg-comment-language')
;; - the maximum column that comments can used (`prg-comment-max-column')
;; - the column to align field values (`prg-comment-field-column')
;; - the name of the company you write for (`prg-comment-company')
;; - the character used to build module header (`prg-comment-mod-char')
;; - the character used to build function header (`prg-comment-fct-char')
;; - the character used to build maintenance block (`prg-comment-maint-char')
;; - the character used to build in-line comment (`prg-comment-in-line-char')
;; - the template for module header (`prg-comment-mod-header')
;; - the template for module footer (`prg-comment-mod-footer')
;; - the template for function header (`prg-comment-fct-header')
;; - the template to begin a maintenance block (`prg-comment-maint-header')
;; - the template to end a maintenance block (`prg-comment-maint-footer')
;; - the template for log header (`prg-comment-log-header')
;; - the number of colums used by in-line comment (`prg-comment-in-line-width')
;; - the template for in-line separator (`prg-comment-in-line-sep')
;;
;; The definition of a charter may require a bit of skill with
;; emacs lisp. (Please refer to the external package documentation.)
;;
;; * Language
;; Language string tables are located in `prg-comment-material-path'/lang.
;; It is a translation table for each field that may be used into templates.
;; The package will load the table according to the value set into the used
;; charter.  The default language is the one defined into the default charter.
;;
;; You can find detailed documentation at 
;; http://aurelien.tisne.free.fr/emacs-pages/emacs.html

;; TODO
;;
;; * Add a maintenance type (Technical Fact, Product Change Request: TF INT,
;;   TF VAL, PCR, ... defined in the charter)
;;   and a maintenance number into the maintenance header.

;;}}}

;;{{{ Code
;;; Code:

;; dependency
(require 'tempo)

;; group
(defgroup prg-comment nil
  "Package that helps to comment source code."
  :prefix "prg-comment-"
  :group 'programming
)

(defun prg-comment-customize ()
"Customization of the group prg-comment."
  (interactive)
  (customize-group "prg-comment"))

;; material (contains directories *lang* and *charters*)
(defcustom prg-comment-material-path
  (file-name-as-directory "~/.emacs-ext/prg-comment")
  "*Define the material location."
  :type 'directory
  :group 'prg-comment
)

;; automatic module header insertion
(defcustom prg-comment-build-new-buffer t
  "*If not nil, then insert a module header for new buffers."
  :type 'boolean
  :group 'prg-comment
)

;; language
(defvar prg-comment-string-table nil
  "String definitions used by `prg-comment' package.")
(make-variable-buffer-local 'prg-comment-string-table)

(defvar prg-comment-lang 'us
  "Language of the comments.

Setting this variable automatically makes it local to the current buffer.
Available languages are stored in the directory 'prg-comment/lang'.")
(make-variable-buffer-local 'prg-comment-lang)

(defun prg-comment-available-languages ()
  "Get available languages contained in the lang directory."
  (mapcar (lambda (s) (intern (file-name-sans-extension s)))
          (directory-files (concat prg-comment-material-path "lang") nil ".*\.el$")))

(defcustom prg-comment-default-lang 'us
  "Default language of the comments.  (Default value of `prg-comment-lang'.)

Setting this variable directly may cause trouble;
 use rather `customize-variable'."
  :set (lambda (symbol value)
         (setq prg-comment-default-lang value)
         (setq-default prg-comment-lang value))
  :type (if (> (length (prg-comment-available-languages)) 0)
            `(choice ,@(mapcar (lambda (s) `(const ,s))
                               (prg-comment-available-languages)))
          'symbol)
  :group 'prg-comment
)


(defun prg-comment-load-string-table (i-lang)
  "Load the string table I-LANG from the file <material_path>/lang/<i-lang>.el."
  (let* ((_lang (if (symbolp i-lang) (symbol-name i-lang) i-lang))
         (_lang-file (convert-standard-filename
                    (concat prg-comment-material-path
                            "lang/" _lang
                            ".el"))))
    (if (file-exists-p _lang-file)
        (load-file _lang-file)
      (error (concat "The language definition cannot be found. The file *"
                     _lang-file "* should exists."))))
  )

;;;###autoload
(defalias 'set-prg-comment-language 'prg-comment-set-language)
;;;###autoload
(defun prg-comment-set-language (lang)
  "Set the current language and initialize the string table according \
to this language.

Argument LANG the country code of the desired (and defined) language."
  ;; use defined languages as completion list
  (interactive (list
                (completing-read "Language: "
                                 (mapcar 'list
                                         (mapcar 'symbol-name
                                                 (prg-comment-available-languages)))
                                 nil t)))
  ;; for non-interactive use
  (if (memq (intern lang) (prg-comment-available-languages))
      (progn
        (setq prg-comment-lang (intern lang))
        (prg-comment-load-string-table lang))
    (error "The language '%s' is not supported by the package.  Please \
use one of the following %s or define a new language definition file"
           lang (prg-comment-available-languages))))

(defun prg-comment-get-text (key)
  "Get the binding text of the KEY.

This function searchs the KEY inside the current string table.
If the KEY does not exist inside the string table, it logs a warning and \
returns the string '??'."
  (let ((value (cdr (assoc key prg-comment-string-table))))
    (if value (format "%s" value)
      (message (concat "No value found for the key *" (symbol-name key)
                       "* in the string table *"
                       (symbol-name prg-comment-lang) "*."))
      "??")))

(defcustom prg-comment-company ""
  "*The name of the company you write for."
  :type 'string
  :group 'prg-comment
)

(defvar prg-comment-tags nil
  "An association list with tags and corresponding templates.

Define shortcuts for Tempo templates.")

;; Templates
;; Templates can be customize in the file prg-comment/charters/<charter>.el
(defvar prg-comment-mod-header nil "*The template of the module header.")
(defvar prg-comment-fct-header nil "*The template of the function header.")
(defvar prg-comment-maint-header nil "*The template of the maintenance header.")
(defvar prg-comment-maint-footer nil "*The template of the maintenance footer.")
(defvar prg-comment-log-header nil "*The template of the log file header.")
(defvar prg-comment-in-line nil "*The template of the in line comment.")

;; Charter

(defun prg-comment-available-charters ()
  "Get available charters contained in the charters directory."
  (mapcar (lambda (s) (intern (file-name-sans-extension s)))
          (directory-files (concat prg-comment-material-path "charters") nil ".*\.el$")))

(defvar prg-comment-charter 'default
  "Charter for comments of the current buffer.

Supported values are file names (without the extension) contained in the
directory `prg-comment-material-path'/charters.
Use `prg-comment-set-charter' (or `set-prg-coment-charter') to set/change \
the charter. You can also map files with charters using \
`prg-comment-charter-alist'.")
(make-variable-buffer-local 'prg-comment-charter)


;;;###autoload
(defalias 'set-prg-comment-charter 'prg-comment-set-charter)
;;;###autoload
(defun prg-comment-set-charter (i-charter)
  "Set the charter of the current buffer to I-CHARTER."
  ;; use defined charters as completion list
  (interactive (list
                (completing-read "Charter: "
                                 (mapcar 'list
                                         (mapcar 'symbol-name
                                                 (prg-comment-available-charters)))
                                 nil t)))
  (setq prg-comment-charter (intern i-charter))
  (let ((_default-charter (convert-standard-filename
                           (concat prg-comment-material-path
                                   "charters/default.el")))
        (_charter-file (convert-standard-filename
                        (concat prg-comment-material-path
                                "charters/" i-charter ".el"))))

    ;; load the default charter first, to define the default behaviour
    (if (file-exists-p _default-charter)
        (load-file _default-charter)
      (message "The default charter is missing. Some features may be missing."))
    ;; load a chosen charter (overload the default behaviour)
    (if (file-exists-p _charter-file)
        (progn
          ;; load charter definition
          (unless (string= _charter-file _default-charter)
            (load-file _charter-file))
          ;; define all templates
          (if prg-comment-mod-header
              (tempo-define-template (concat "mod-head-" i-charter)
                                     prg-comment-mod-header "modhead"
                                     "Template for module header."
                                     'prg-comment-tags))
          (if prg-comment-mod-footer
              (tempo-define-template (concat "mod-foot-" i-charter)
                                     prg-comment-mod-footer "modfoot"
                                     "Template for module footer."
                                     'prg-comment-tags))
          (if prg-comment-fct-header
              (tempo-define-template (concat "fct-head-" i-charter)
                                     prg-comment-fct-header "fcthead"
                                     "Template for function header."
                                     'prg-comment-tags))
          (if prg-comment-maint-header
              (tempo-define-template (concat "maint-head-" i-charter)
                                     prg-comment-maint-header "mainthead"
                                     "Template for header of maintenance block."
                                     'prg-comment-tags))
          (if prg-comment-maint-footer
              (tempo-define-template (concat "maint-foot-" i-charter)
                                     prg-comment-maint-footer "maintfoot"
                                     "Template for footer of maintenance block."
                                     'prg-comment-tags))
          (if prg-comment-in-line
              (tempo-define-template (concat "in-line-" i-charter)
                                     prg-comment-in-line "inline"
                                     "Template for in-line separator."
                                     'prg-comment-tags))
          (if prg-comment-log-header
              (tempo-define-template (concat "log-head-" i-charter)
                                     prg-comment-log-header "loghead"
                                     "Template for log header."
                                     'prg-comment-tags))
          (tempo-use-tag-list 'prg-comment-tags)
          ;; load the charter language
          (prg-comment-load-string-table prg-comment-lang)
          ;; insert a module header if the buffer is empty and if wanted
          (if (and prg-comment-build-new-buffer (zerop (buffer-size)))
              (progn
                (insert-mod-header)
                (let ((_here (point)))
                  (insert "\n\n\n")
                  (insert-mod-footer)
                  (goto-char (1+ _here)))))
          )

      (error (concat "The charter definition cannot be found. The file '"
                     _charter-file "' should exists.")))))

(defcustom prg-comment-charters-alist nil
  "*Define associations between paths and charters.

Each element has the form:
\(PATH . CHARTER)

A CHARTER definition must exists in `prg-comment-material-path'."
  :type `(alist :key-type directory 
                :value-type (choice ,@(mapcar (lambda (s) `(const ,s))
                                              (prg-comment-available-charters))))
  :group 'prg-comment
  )

(defun prg-comment-get-charter (i-file-name)
  "Get the charter associated with the path of I-FILE-NAME, if any.
Return the default charter otherwise."
  (let* ((exp-charters-alist (mapcar (lambda (s) (cons (expand-file-name (car s)) (cdr s))) prg-comment-charters-alist)) ; expanded charters alist
        (key (longuest-matching i-file-name nil exp-charters-alist)))
    (if key
        (cdr (assoc key exp-charters-alist))
      'default)))

(defun longuest-matching (i-pattern i-curr-match i-alist)
  "Give the longuest item of I-ALIST that matched I-PATTERN.

I-CURR-MATCH is used for internal purpose only."
  (if i-alist
      (progn
        (let* ((key (caar i-alist))
               (key-regexp (concat (regexp-quote key) "*")))
          (if (and (string-match (upcase key-regexp)
                                 (upcase i-pattern))
                   (> (match-end 0) (length i-curr-match)))
              (longuest-matching i-pattern key (cdr i-alist))
            (longuest-matching i-pattern i-curr-match (cdr i-alist)))))
    i-curr-match
    ))

(defun empty-region-p (beg end)
  "Test if characters between BEG and END are all whitespaces."
  ;;  (interactive "r")                                    
  (let ((beg-reg beg)                   ; ensure beg < end
        (end-reg end))
    (and (> beg end) (setq beg end-reg end beg-reg)))
  (save-excursion
    (goto-char beg)
    (skip-syntax-forward               ; skip whitespaces and new line
     (concat " " (char-to-string (char-syntax ?\n))))
    (>= (point) end)))

;;{{{ Headers comment
(defcustom prg-comment-max-column 80
  "*Rightmost column for text."
  :type 'integer
  :group 'prg-comment
)
(make-variable-buffer-local 'prg-comment-max-column)

(defcustom prg-comment-field-column 16
  "*Column witdh for the comment field values."
  :type 'integer
  :group 'prg-comment
)
(make-variable-buffer-local 'prg-comment-field-column)

(defcustom prg-comment-in-line-width 20
  "*Number of characters used to build in-line separator."
  :type 'integer
  :group 'prg-comment
)
(make-variable-buffer-local 'prg-comment-in-line-width)

(defcustom prg-comment-mod-char ?=
  "*Character used to build module header."
  :type 'character
  :group 'prg-comment
)
(make-variable-buffer-local 'prg-comment-mod-char)

(defcustom prg-comment-fct-char ?-
  "*Character used to build function header."
  :type 'character
  :group 'prg-comment
)
(make-variable-buffer-local 'prg-comment-fct-char)

(defcustom prg-comment-maint-char ?/
  "*Character used to build maintenance header/footer."
  :type 'character
  :group 'prg-comment
)
(make-variable-buffer-local 'prg-comment-maint-char)

(defcustom prg-comment-in-line-char ?-
  "*Character used to build in-line separator."
  :type 'character
  :group 'prg-comment
)
(make-variable-buffer-local 'prg-comment-in-line-char)

(defun prg-comment-full-line ()
  "Compute the size of a full comment line.

This function returns the number of characters to build a full line \
depending on `prg-comment-max-column'."
  (- prg-comment-max-column (length comment-start) (length comment-end) 3))


;; display the field following by spaces to fit prg-comment-field-column
;; characters
(defun prg-comment-pad-field (prg-comment-field-name)
  "Pad with spaces until the `prg-comment-field-column'.

Argument PRG-COMMENT-FIELD-NAME of the comment field."
  (let* ((prg-comment-field (prg-comment-get-text prg-comment-field-name))
         (prg-comment-field-size (length prg-comment-field)))
    (if (< prg-comment-field-size prg-comment-field-column)
        (concat (capitalize prg-comment-field)
                (make-string (- prg-comment-field-column (length prg-comment-field))
                             ?\ ))
      (message (concat "The label *" prg-comment-field
                       "* is too long (" (format "%s" prg-comment-field-size)
                       "). You should decrease its size or increase the parameter *prg-comment-field-column* ("
                       (format "%s" prg-comment-field-column) ").")))))

(defun prg-comment-sep (i-prg-comment-char &optional i-nb i-width)
  "Build I-NB separator lines whith I-PRG-COMMENT-CHAR character.

I-WIDTH is the number of characters used to build the separator. \
It is optional and set to `prg-comment-full-line' by default.
I-NB is optional and set to 1 by default."
  (unless (integerp i-nb) (setq i-nb 0))
  (unless (integerp i-width) (setq i-width (prg-comment-full-line)))
  (let ((_comment-sep
         (make-string i-width i-prg-comment-char)))
    (cond ((> i-nb 1)
           (concat _comment-sep "\n"
                   (prg-comment-sep i-prg-comment-char (1- i-nb))))
          (t _comment-sep)))
)

(defun prg-comment-mod-sep (&optional i-nb)
  "Build I-NB separator lines using the character `prg-comment-mod-char'."
  (prg-comment-sep prg-comment-mod-char i-nb))

(defun prg-comment-fct-sep (&optional i-nb)
  "Build I-NB separator lines using the character `prg-comment-fct-char'."
  (prg-comment-sep prg-comment-fct-char i-nb))

(defun prg-comment-maint-sep (&optional i-nb)
  "Build I-NB separator lines using the character `prg-comment-maint-char'."
  (prg-comment-sep prg-comment-maint-char i-nb))

(defun prg-comment-in-line-sep (&optional i-nb)
  "Build I-NB separator lines using the character `prg-comment-maint-char'."
  (prg-comment-sep prg-comment-in-line-char i-nb prg-comment-in-line-width))

;;{{{ Module level comments

;;;###autoload
(defun insert-mod-header ()
  "Insert comment header of a module."
  (interactive)
  (if (> (current-column) 0) 
      (progn 
        (end-of-line)
        (newline)))
  (let ((beg (point)))
    (funcall (intern (concat "tempo-template-mod-head-"
                             (symbol-name prg-comment-charter))))
    (unless (empty-region-p beg (point))
        (comment-region beg (point))))
)

;;;###autoload
(defun insert-removed-code ()
  "Insert tag to say that code was removed."
  (interactive)
  (let ((beg (point)))
    (prg-comment-get-text ':removed-code)
    (unless (empty-region-p beg (point))
        (comment-region beg (point))))
)

;;;###autoload
(defun insert-mod-footer ()
  "Insert comment footer of a module."
  (interactive)
  (if (> (current-column) 0) 
      (progn 
        (end-of-line)
        (newline)))
  (let ((beg (point)))
    (funcall (intern (concat "tempo-template-mod-foot-"
                             (symbol-name prg-comment-charter))))
    (unless (empty-region-p beg (point))
        (comment-region beg (point))))
)
;;}}}

;;{{{ Function level comments

;;;###autoload
(defun insert-fct-header ()
  "Insert comment header of a function."
  (interactive)
  (if (> (current-column) 0) 
      (progn 
        (end-of-line)
        (newline)))
  (let ((beg (point)))
    (funcall (intern (concat "tempo-template-fct-head-"
                             (symbol-name prg-comment-charter))))
    (unless (empty-region-p beg (point))
        (comment-region beg (point))))
)

;;;###autoload
(defun insert-in-line ()
  "Insert in-line separator."
  (interactive)
  (if (> (current-column) 0) 
      (progn 
        (end-of-line)
        (newline)))
  (let ((beg (point)))
    (funcall (intern (concat "tempo-template-in-line-"
                             (symbol-name prg-comment-charter))))
    (unless (empty-region-p beg (point))
        (progn
          (comment-region beg (point))
          (indent-region beg (point) nil))))
)


;;;###autoload
(defun insert-new-param (i-param-type)
  "Insert a blank parameter comment line.

Argument I-PARAM-TYPE is the type of the parameter.  Possible values are:
IN, OUT, IN/OUT."
  (interactive (list
                (completing-read "Type: "
                                 '(("I") ("IN") ("O") ("OUT") ("IO") ("I/O") ("IN/OUT"))
                                 nil t)))
  (if (member-ignore-case i-param-type '("I" "IN" "O" "OUT" "IO" "I/O" "IN/OUT"))
      (progn
        (forward-line 1)
        (let ((beg (point))
              (_field (cdr (assoc-ignore-case i-param-type
                                              '(("I" . :in)
                                                ("IN" . :in)
                                                ("O" . :out)
                                                ("OUT" . :out)
                                                ("IO" . :in-out)
                                                ("I/O" . :in-out)
                                                ("IN/OUT" . :in-out))))))
          (insert (prg-comment-pad-field _field))
          (comment-region beg (point))))
    (error "The type '%s' is not supported.  Please use one of the \
following: i, o, io" i-param-type)))

;;;###autoload
(defun insert-new-param-like-current ()
  "Insert a blank parameter comment line whose type is the same as \
the current line (model line).

You may meet with trouble if the value of `prg-comment-field-column'
is not the same as the one of the model line."
  (interactive)
    (beginning-of-line)
    (let ((beg (point))
          (curr-field ""))
      (forward-char (+ prg-comment-field-column (length comment-start)))
      (setq curr-field (buffer-substring beg (point)))
      (end-of-line)
      (newline)
      (insert curr-field)))
;;}}}

;;{{{ Maintenance comments

;;;###autoload
(defun insert-maint ()
  "Insert comment lines to include a maintenance region."
  (interactive)
  (insert-maint-header)
  (insert "\n")
  (let ((_here (point)))
    (insert "\n")
    (insert-maint-footer)
    (goto-char _here))
)

;;;###autoload
(defun comment-maint-region (min max)
  "Tag a maintenance comment region.

Argument MIN is the beginning of the region.
Argument MAX is the end of the region."
  (interactive "r")
  (let ((_selection (delete-and-extract-region min max)))
    (insert-maint-header)
    (insert (concat "\n" _selection "\n"))
    (insert-maint-footer))
)
;;}}}

;;{{{ Log level comments

;;;###autoload
(defun insert-log-header ()
  "Insert comment header of a log file."
  (interactive)
  (if prg-comment-log-header
      (progn
        (if (> (current-column) 0) 
            (progn 
              (end-of-line)
              (newline)))
        (let ((beg (point)))
          (funcall (intern (concat "tempo-template-log-head-"
                                   (symbol-name prg-comment-charter))))
          (unless (empty-region-p beg (point))
            (comment-region beg (point)))))))

;;}}}

;;}}}
;;}}}

;; Facilities to use prg-comment
(defun prg-comment-use-it ()
  "Function you can add to hook to initialize the package."
  (interactive)
  (let ((charter (symbol-name (prg-comment-get-charter buffer-file-name))))
    (prg-comment-set-charter charter)
    (message "Charter '%s' loaded."  charter)))

(provide 'prg-comment)

;;; prg-comment.el ends here
