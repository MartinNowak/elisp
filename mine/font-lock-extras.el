;;; font-lock-extras.el --- Extra general faces (may become part of font-lock...)
;; Copyright (C) 2007 Per Nordlöw
;; Author: Per Nordlöw <per.nordlow@gmail.com>

(defun font-lock-replace-keywords (mode keywords new-keywords &optional how)
  "Substitute KEYWORDS with NEW-KEYWORDS in MODE.
http://stackoverflow.com/questions/13456263/modifying-font-locking-entries-in-emacs/13456472#13456472"
  (font-lock-remove-keywords mode keywords)
  (font-lock-add-keywords mode new-keywords how))

(defun font-lock-switch-keywords (mode keywords activate &optional how)
  (if activate
      (font-lock-add-keywords nil keywords t)
    (font-lock-remove-keywords nil keywords)))

;;; Operators

(defface font-lock-operator-face	;operator
  '((((class color)) (:inherit font-lock-builtin-face :weight normal)))
  "Font Lock mode face used to highlight operators."
  :group 'font-lock-extras)

(defface font-lock-operator-member-face ;operator-member
  '((((class color)) (:inherit font-lock-operator-face :weight bold)))
  "Font Lock mode face used to highlight member operators."
  :group 'font-lock-extras)

(defface font-lock-operator-inc-dec-face ;operator-inc-dec
  '((((class color)) (:inherit font-lock-operator-face :weight bold)))
  "Font Lock mode face used to highlight inc-dec operators."
  :group 'font-lock-extras)

(defface font-lock-operator-dots-face   ;operator-dots
  '((((class color)) (:inherit font-lock-operator-face :weight bold)))
  "Font Lock mode face used to highlight dots operator."
  :group 'font-lock-extras)

(defface font-lock-operator-concat-face
  '((((class color)) (:inherit font-lock-operator-face :weight bold)))
  "Font Lock mode face used to highlight concatenation."
  :group 'font-lock-extras)

(defface font-lock-operator-assignment-face ;operator-assignment
  '((((class color) (min-colors 88) (background dark)) (:foreground "red2" :weight bold))
    (((class color) (min-colors 88) (background light)) (:foreground "DarkRed" :weight bold)))
  ;; '((((class color)) (:inherit font-lock-operator-face :weight bold)))
  "Font Lock mode face used to highlight assignment operators."
  :group 'font-lock-extras)

;;; Parenthesises and Braces

(defface font-lock-parens-face		;braces
  '((((class color)) (:inherit font-lock-operator-face :weight normal)))
  "Font Lock mode face used to highlight braces."
  :group 'font-lock-extras)

(defface font-lock-braces-face		;braces
  '((((class color)) (:inherit font-lock-operator-face :foreground "white" :weight normal)))
  "Font Lock mode face used to highlight braces."
  :group 'font-lock-extras)

;;; Function and their Calls

(defface font-lock-function-alias-face	;function-call
  '((((class color)) (:inherit font-lock-function-name-face)))
  "Font Lock mode face used to highlight function alias."
  :group 'font-lock-extras)

;;; Function and their Calls

(defface font-lock-function-call-face	;function-call
  '((((class color)) (:inherit font-lock-function-name-face :weight normal)))
  "Font Lock mode face used to highlight function calls."
  :group 'font-lock-extras)
(defface font-lock-function-alias-call-face
  '((((class color)) (:inherit font-lock-function-name-face :weight normal)))
  "Font Lock mode face used to highlight function alias calls."
  :group 'font-lock-extras)
(defface font-lock-quoted-function-name-face	;quoted function-name
  '((((class color)) (:inherit font-lock-function-name-face :weight normal :italic t)))
  "Font Lock mode face used to highlight quoted function names."
  :group 'font-lock-extras)

;;; Commands (Interactive Functions)

(defface font-lock-command-name-face
  '((((class color) (min-colors 88) (background dark)) (:foreground "LightSkyBlue3" :weight bold))
    (((class color) (min-colors 88) (background light)) (:foreground "Blue1" :weight bold)))
  "Font Lock mode face used to highlight command names."
  :group 'font-lock-extras)
(defface font-lock-command-call-face
  '((((class color)) (:inherit font-lock-command-name-face :weight normal)))
  "Font Lock mode face used to highlight function calls."
  :group 'font-lock-extras)
(defface font-lock-quoted-command-call-face
  '((((class color)) (:inherit font-lock-command-call-face :weight normal :italic t)))
  "Font Lock mode face used to highlight quoted function names."
  :group 'font-lock-extras)

;;; Constructor and Destructor

(defface font-lock-constructor-face	;constructor
  '((((class color)) (:inherit font-lock-function-name-face :weight normal)))
  "Font Lock mode face used to highlight constructor (function) calls."
  :group 'font-lock-extras)
(defface font-lock-destructor-face	;destructor
  '((((class color)) (:inherit font-lock-function-name-face :weight normal)))
  "Font Lock mode face used to highlight destructor (function) calls."
  :group 'font-lock-extras)

;;; Macro Calls

(defface font-lock-macro-name-face	;macro-call
  '((((class color) (background dark)) (:foreground "palevioletred" :weight bold)) ;Note: Alternatives: palevioletred, #00b070
    (((class color) (background light)) (:foreground "#00b030" :weight bold))
    (t ()))
  "Font Lock mode face used to highlight (lisp) macros."
  :group 'font-lock-extras)
(defface font-lock-macro-ref-face
  '((((class color)) (:inherit font-lock-macro-name-face :weight normal)))
  "Font Lock mode face used to highlight macros references."
  :group 'font-lock-extras)
(defface font-lock-macro-call-face	;macro-call
  '((((class color)) (:inherit font-lock-macro-name-face :weight normal)))
  "Font Lock mode face used to highlight macro calls (expands)."
  :group 'font-lock-extras)
(defface font-lock-quoted-macro-name-face	;quoted macro-name
  '((((class color)) (:inherit font-lock-macro-name-face :weight normal :italic t)))
  "Font Lock mode face used to highlight quoted macro names."
  :group 'font-lock-extras)

;;; Classes Structures

(defface font-lock-type-definition-face
  '((((class color)) (:inherit font-lock-type-face :weight bold)))
  "Font Lock mode face used to highlight definition of types."
  :group 'font-lock-extras)
(defface font-lock-class-face
  '((((class color)) (:inherit font-lock-type-face :weight bold)))
  "Font Lock mode face used to highlight class types."
  :group 'font-lock-extras)
(defface font-lock-structure-face
  '((((class color)) (:inherit font-lock-type-face :weight bold)))
  "Font Lock mode face used to highlight structure types."
  :group 'font-lock-extras)

;;; Enumerations

(defface font-lock-enumerator-face
  '((((class color)) (:inherit font-lock-type-face :weight normal)))
  "Font Lock mode face used to highlight enumerator types."
  :group 'font-lock-extras)
(defface font-lock-enumeration-face
  '((((class color)) (:inherit font-lock-constant-face :weight normal)))
  "Font Lock mode face used to highlight enumeration constants."
  :group 'font-lock-extras)

;;; Union name

(defface font-lock-union-name-face
  '((((class color)) (:inherit font-lock-variable-name-face :weight bold)))
  "Font Lock mode face used to highlight union names."
  :group 'font-lock-extras)

;;; Faces:

(defface font-lock-symbol-ref-face
  '((((class color)) (:inherit font-lock-keyword-face :weight normal)))
  "Font Lock mode face used to highlight macros references."
  :group 'font-lock-extras)

;;; Built-ins

(defface font-lock-builtin-ref-face	;quoted built-ins
  '((((class color)) (:inherit font-lock-builtin-face :weight normal)))
  "Font Lock mode face used to highlight quoted built-ins."
  :group 'font-lock-extras)
(defface font-lock-quoted-builtin-ref-face	;quoted built-ins
  '((((class color)) (:inherit font-lock-builtin-face :weight normal :italic t)))
  "Font Lock mode face used to highlight quoted built-ins."
  :group 'font-lock-extras)

;;; Variable Scope
(defface font-lock-private-variable-face
  '((((class color) (min-colors 88) (background dark)) (:foreground "DarkGoldenrod" :weight normal))
    (((class color) (min-colors 88) (background light)) (:inherit font-lock-variable-name-face :weight normal)))
  "Font Lock mode face used to highlight the variable in a private scope."
  :group 'font-lock-extras)

;;; Variable Alteration

(defface font-lock-variable-alteration-face ;variable-alteration
  '((((class color) (min-colors 88) (background dark)) (:inherit font-lock-variable-name-face :weight normal)))
  "Font Lock mode face used to highlight the variable in an
  alteration."
  :group 'font-lock-extras)
(defface font-lock-variable-deletion-face
  '((((class color) (min-colors 88) (background dark)) (:inherit font-lock-variable-alteration-face :strike-through "#ff3030")))
  "Font Lock mode face used to highlight variable
deletions (memory deallocations)."
  :group 'font-lock-extras)

;;; Variable Reference/User

(defface font-lock-variable-ref-face ;variable-ref
  '((((class color)) (:inherit font-lock-variable-name-face :weight normal)))
  "Font Lock mode face used to highlight a variable reference."
  :group 'font-lock-extras)
(defface font-lock-quoted-variable-ref-face	;quoted variable-ref
  '((((class color)) (:inherit font-lock-variable-ref-face :weight normal :italic t)))
  "Font Lock mode face used to highlight a quoted variable reference."
  :group 'font-lock-extras)

;;; Regular Expression String

(defface font-lock-regexp-face
  '((((class color)) (:inherit font-lock-string-face)))
  "Font Lock mode face used to regular expression string literals."
  :group 'font-lock-extras)

;;; Number Literal

(defface font-lock-number-face
  '((((class color)) (:inherit font-lock-string-face :weight bold :foreground "orange3")))
  "Font Lock mode face used to highlight number literals."
  :group 'font-lock-extras)
(defface font-lock-number-alt-face	;number-alt
  '((((class color) (min-colors 88) (background dark))
     (:foreground "tomato" :weight bold)))
  "Font Lock mode face used to highlight number literals alternative."
  :group 'font-lock-extras)

;; ToDo: Perhaps a completely new color for this face.
(defface font-lock-number-passive-face	;number-passive
  '((((class color)) (:inherit font-lock-number-face :weight normal)))
  "Font Lock mode face used to highlight passive parts of number literals."
  :group 'font-lock-extras)

;;; Special Literal

(defface font-lock-special-literal-face
  '((((class color) (min-colors 88) (background dark))
     (:foreground "#d05000" :weight bold)))
  "Font Lock mode face used to highlight special literals."
  :group 'font-lock-extras)
(defface font-lock-special-constant-face
  '((((class color)) (:inherit font-lock-constant-face :weight bold)))
  "Font Lock mode face used to highlight special constant such as t and nil in emacs-lisp-mode."
  :group 'font-lock-extras)

;;; Separator

(defface font-lock-separator-face
  '((((class color) (min-colors 88) (background dark))
     (:foreground "white" :weight normal)))
  "Font Lock mode face used to highlight separator literals."
  :group 'font-lock-extras)
(defface font-lock-quote-face
  '((((class color) (min-colors 88) (background dark))
     (:foreground "white" :weight bold)))
  "Font Lock mode face used to highlight quotes."
  :group 'font-lock-extras)

;;; printf directives

;; ToDo: Perhaps a completely new color for this face.
(defface font-lock-printf-directives-face ;printf-directives
  '((((class color)) (:inherit font-lock-string-face :weight bold)))
  "Font Lock mode face used to highlight C printf directives."
  :group 'font-lock-extras)
;; ToDo: Perhaps a completely new color for this face.
(defface font-lock-printf-directive-conversion-face ;printf-directive-conversion
  '((((class color)) (:inherit font-lock-type-face :weight bold)))
  "Font Lock mode face used to highlight C printf conversion directives."
  :group 'font-lock-extras)

;;; Aliases

(defface font-lock-alias-definition-face
  '((((class color)) (:inherit bold :weight bold)))
  "Font Lock mode face used to highlight D Alias Definitions."
  :group 'font-lock-extras)

;;; Templates

(defface font-lock-template-definition-face
  '((((class color) (min-colors 88) (background dark))
     (:foreground "white" :weight bold)))
  ;; '((((class color)) (:inherit font-lock-type-face :weight bold)))
  "Font Lock mode face used to highlight C++/D Template Instances."
  :group 'font-lock-extras)
(defface font-lock-template-instance-face
  '((((class color) (min-colors 88) (background dark))
     (:foreground "white" :weight regular)))
  ;; '((((class color)) (:inherit font-lock-type-face :weight bold)))
  "Font Lock mode face used to highlight C++/D Template Instances."
  :group 'font-lock-extras)

;;; Face

(defface font-lock-face-name-face
  '((((class color) (min-colors 88) (background dark))
     (:foreground "orange" :weight normal)))
  "Font Lock mode face used to highlight face names."
  :group 'font-lock-extras)
(defface font-lock-quoted-face-name-face	;quoted face
  '((((class color)) (:inherit font-lock-face-name-face :weight normal :italic t))
    )
  "Font Lock mode face used to highlight a quoted face reference."
  :group 'font-lock-extras)

;;; URLs, Files and Directories

(defface font-lock-url-face
  '((((class color)) (:inherit dired-directory :weight bold)))
  "Font Lock mode face used to highlight an URL."
  :group 'font-lock-extras)
(defface font-lock-directory-name-face
  '((((class color) (background dark)) (:foreground "darkgrey" :weight bold))
    (((class color) (background light)) (:foreground "lightgrey" :weight bold))
    (t ()))
  "Font Lock mode face used to highlight a directory file name."
  :group 'font-lock-extras)
(defface font-lock-file-name-face
  '((((class color) (background dark)) (:foreground "darkgrey" :weight normal))
    (((class color) (background light)) (:foreground "lightgrey" :weight normal))
    (t ()))
  "Font Lock mode face used to highlight a file name."
  :group 'font-lock-extras)
(defface font-lock-exe-name-face
  '((((class color) (background dark)) (:foreground "darkgreen" :weight normal))
    (((class color) (background light)) (:foreground "lightgreen" :weight normal))
    (t ()))
  "Font Lock mode face used to highlight a executable file name."
  :group 'font-lock-extras)
(defface font-lock-lib-name-face
  '((((class color) (background dark)) (:foreground "darkcyan" :weight normal))
    (((class color) (background light)) (:foreground "lightcyan" :weight normal))
    (t ()))
  "Font Lock mode face used to highlight a library file name."
  :group 'font-lock-extras)
(defface font-lock-package-name-face
  '((((class color)) (:inherit font-lock-file-name-face :weight bold)))
  "Font Lock mode face used to highlight a package file name."
  :group 'font-lock-extras)
(defface font-lock-library-name-face
  '((((class color)) (:inherit font-lock-file-name-face :weight bold)))
  "Font Lock mode face used to highlight a library file name."
  :group 'font-lock-extras)

(defface font-lock-buffer-name-face
  '((((class color) (background dark)) (:foreground "grey" :weight normal))
    (((class color) (background light)) (:foreground "grey" :weight normal))
    (t ()))
  "Font Lock mode face used to highlight a buffer name."
  :group 'font-lock-extras)
(defface font-lock-time-face
  '((((class color) (background dark)) (:foreground "#606060" :weight normal))
    (((class color) (background light)) (:foreground "lightgrey" :weight normal))
    (t ()))
  "Font Lock mode face used to highlight a time."
  :group 'font-lock-extras)

(defface font-lock-superuser-face
  '(
    (((class color) (background dark)) (:foreground "#f04030" :weight normal))
    (((class color) (background light)) (:foreground "darkred" :weight normal))
    (t ()))
  "Font Lock mode face used to highlight sudo operations."
  :group 'font-lock-extras)
(defface font-lock-keycomb-face
  '(
    (((class color) (background dark)) (:inherit font-lock-builtin-face :background "grey10" :box (:line-width -1 :color "grey75" :style released-button) :weight normal))
    (((class color) (background light)) (:inherit font-lock-builtin-face :background "grey90" :box (:line-width -1 :color "grey25" :style released-button) :weight normal))
    (t ())
    )
  "Font Lock mode face used to highlight keyboard combinations."
  :group 'font-lock-extras)

;; Note: These settings harmonize with the faces defined above.
(custom-set-faces
 '(font-lock-alert-face ((t (:foreground "red" :background "gray32" :weight bold))))
 '(font-lock-builtin-face ((((class color) (min-colors 88) (background dark)) (:foreground "#d0b0ed" :weight bold))))
 '(font-lock-comment-delimiter-face ((default (:inherit font-lock-comment-face)) (((class color) (min-colors 16)) (:weight bold))))
 '(font-lock-comment-face ((((class color) (min-colors 88) (background dark)) (:foreground "tan3"))))
 '(font-lock-face-name-face ((t (:foreground "darkorange3" :weight normal))))
 '(font-lock-function-name-face ((((class color) (min-colors 88) (background dark)) (:foreground "LightSkyBlue" :weight bold))
                                 (((class color) (min-colors 88) (background light)) (:foreground "Blue1" :weight bold))))
 '(font-lock-keyword-face ((((class color) (min-colors 88) (background dark)) (:foreground "Cyan1" :weight bold))))
 '(font-lock-negation-char-face ((((background dark) (supports :foreground "#808080")) nil)))
 '(font-lock-note-face ((t (:foreground "yellow" :background "gray32" :weight bold))))
 '(font-lock-parens-face ((((background light)) (:foreground "grey30" :weight normal))
                          (((background dark)) (:foreground "grey" :weight normal))))
 '(font-lock-variable-alteration-face ((t (:inherit font-lock-variable-name-face :underline "white" :weight normal))))
 '(font-lock-variable-name-face ((((class color) (min-colors 88) (background dark)) (:foreground "LightGoldenrod" :weight bold))
                                 (((class color) (min-colors 88) (background light)) (:foreground "DarkGoldenrod" :weight bold))))
 '(font-lock-warn-face ((t (:foreground "orange" :background "gray32" :weight bold))))
 )

(provide 'font-lock-extras)
