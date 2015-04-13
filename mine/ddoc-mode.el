;;; ddoc-mode.el --- D Documentation (DDoc) mode.

;; Author: Per Nordlöw (per.nordlow@gmail.com)
;; Keywords: languages, D
;; See also: http://dlang.org/ddoc.html
;; Version: 0.1.0

;;; Code:

(defgroup ddoc-mode nil
  "DDoc mode for Emacs."
  :group 'tools)

(defconst d-ddoc-macros
  '(
    "B"                                 ;boldface the argument
    "I"                                 ;italicize the argument
    "U"                                 ;underline the argument

    "P"                                 ;argument is a paragraph

    "DL"                          ;argument is a definition list
    "DT"                          ;argument is a definition in a definition list
    "DD"                          ;argument is a description of a definition

    "TABLE"                             ;argument is a table
    "TR"                                ;argument is a row in a table
    "TH"                                ;argument is a header entry in a row
    "TD"                                ;argument is a data entry in a row

    "OL"                                ;argument is an ordered list
    "UL"                                ;argument is an unordered list
    "LI"                                ;argument is an item in a list

    "BIG"                               ;argument is one font size bigger
    "SMALL"                             ;argument is one font size smaller

    "BR"                                ;start new line

    "LINK"                        ;generate clickable link on argument
    "LINK2"                       ;generate clickable link, first arg is address

    "RED"                               ;argument is set to be red
    "BLUE"                              ;argument is set to be blue
    "GREEN"                             ;argument is set to be green
    "YELLOW"                            ;argument is set to be yellow
    "BLACK"                             ;argument is set to be black
    "WHITE"                             ;argument is set to be white

    "D_CODE"                            ;argument is D code
    "D_COMMENT"                         ;argument is D comment
    "D_STRING"                          ;argument is D string
    "D_KEYWORD"                         ;argument is D keyword
    "D_PSYMBOL"                         ;argument is D psybol
    "D_PARAM"                           ;argument is D parameter

    "DDOC_COMMENT"
    "DDOC_DECL"
    "DDOC_DECL_DD"
    "DDOC_DITTO"
    "DDOC_SECTIONS"
    "DDOC_SUMMARY"
    "DDOC_DESCRIPTION"
    "DDOC_AUTHORS"
    "DDOC_BUGS"
    "DDOC_COPYRIGHT"
    "DDOC_DATE"
    "DDOC_DEPRECATED"
    "DDOC_EXAMPLES"
    "DDOC_HISTORY"
    "DDOC_LICENSE"
    "DDOC_RETURNS"
    "DDOC_SEE_ALSO"
    "DDOC_STANDARDS"
    "DDOC_THROWS"
    "DDOC_VERSION"
    "DDOC_SECTION_H"
    "DDOC_SECTION"
    "DDOC_MEMBERS"
    "DDOC_MODULE_MEMBERS"
    "DDOC_CLASS_MEMBERS"
    "DDOC_STRUCT_MEMBERS"
    "DDOC_ENUM_MEMBERS"
    "DDOC_TEMPLATE_MEMBERS"
    "DDOC_PARAMS"
    "DDOC_PARAM_ROW"
    "DDOC_PARAM_ID"
    "DDOC_PARAM_DESC"
    "DDOC_BLANKLINE"

    "DDOC_ANCHOR"
    "DDOC_PSYMBOL"
    "DDOC_KEYWORD"
    "DDOC_PARAM"

    "DDOC"                              ;overall template for output
    )
  "See also: http://dlang.org/ddoc.html")

(defconst ddoc-font-lock-keywords
  (list
   (cons (concat "\\$(\\(\\sw+\\)")
         '((1 font-lock-keyword-face t) ;TODO Add highlighter function for
                                        ;BUGZILLA in font-lock-warning-face and
                                        ;parsing to matching rparen
           ))
   ) "Keywords for ddoc-mode")

;;;###autoload
(defun ddoc-mode ()
  "A major-mode to edit DDoc files"

  (interactive)
  (kill-all-local-variables)

  (setq major-mode 'ddoc-mode)
  (setq mode-name "DDoc")

  (make-local-variable 'comment-start)
  (setq comment-start "# ")

  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)

  (make-local-variable	'font-lock-defaults)
  (setq font-lock-defaults `(ddoc-font-lock-keywords nil))

  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\" "w" table)
    (set-syntax-table table))

  (run-hooks 'ddoc-mode-hook)
  )

;;;###autoload(add-to-list 'auto-mode-alist '("\\.dd\\'" . ddoc-mode))

(provide 'ddoc-mode)

;;; ddoc-mode.el ends here
