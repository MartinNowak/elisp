;;; unicode-overlays.el --- Pretty overlays of operators using unicode-symbols.
;; Author: Per Nordlöw

(defun unicode-symbol (name)
  "Translate a symbolic name for a Unicode character -- e.g.,
  LEFT-ARROW or GREATER-THAN into an actual Unicode character
  code. Use list-charset-chars() to browse them."
  (decode-char 'ucs
               (case name          ;NOTE: First argument is same as to `list-charset-chars'.
                 ;; arrows
                 ('left-arrow #X2190)
                 ('up-arrow #X2191)
                 ('right-arrow #X2192)
                 ('down-arrow #X2193)

                 ('left-arrow-tail #X2919)
                 ('right-arrow-tail #X291A)

                 ('left-double-arrow-tail #X291B)
                 ('right-double-arrow-tail #X291C)

                 ('for-all #X2200)
                 ('proportion #X2237)
                 ('black-star #X2605)

                 ('composition #X8728)

                 ;; Right
                 ('black-right-pointing-triangle #X25B6)
                 ('white-right-pointing-triangle #X25B7)
                 ('black-right-pointing-small-triangle #X25B8)
                 ('white-right-pointing-small-triangle #X25B9)
                 ('black-right-pointing-pointer #X25BA)
                 ('white-right-pointing-pointer #X25BB)

                 ;; Left
                 ('black-left-pointing-triangle #X25C0)
                 ('white-left-pointing-triangle #X25C1)
                 ('black-left-pointing-small-triangle #X25C2)
                 ('white-left-pointing-small-triangle #X25C3)
                 ('black-left-pointing-pointer #X25C4)
                 ('white-left-pointing-pointer #X25C5)

                 ;; Diamond
                 ('black-diamond #X25C6)
                 ('white-diamond #X25C7)
                 ('white-diamond-containing-small-diamond #X25C7)
                 ('white-diamond-containing-small-diamond #X25C8)

                 ;; boxes
                 ('double-vertical-bar #X2551)

                 ;; relational operators
                 ('equal #X003d)     ;c-mode: =
                 ('not-equal #X2260) ;c-mode: not used

                 ('identical #X2261)     ;c-mode: ==
                 ('not-identical #X2262) ;c-mode: !=

                 ('less-than #X003c)                ;c-mode: <
                 ('greater-than #X003e)             ;c-mode: >
                 ('less-than-or-equal-to #X2264)    ;c-mode: <=
                 ('greater-than-or-equal-to #X2265) ;c-mode: >=

                 ;; logical operators
                 ('logical-and #X2227) ;c-mode: &&
                 ('logical-or #X2228)  ;c-mode: ||
                 ('logical-neg #X00AC) ;c-mode: !

                 ;; misc
                 ('nil #X2205)
                 ('horizontal-ellipsis #X2026)
                 ('double-exclamation #X203C)
                 ('prime #X2032)
                 ('double-prime #X2033)
                 ('for-all #X2200)
                 ('there-exists #X2203)
                 ('element-of #X2208)

                 ;; mathematical operators
                 ('square-root #X221A)
                 ('cube-root #X221B)
                 ('fourth-root #X221C)

                 ('proportional-to #X221D)
                 ('infinity #X221E)

                 ('squared #X00B2)
                 ('cubed #X00B3)

                 ('squared-plus #X229E)
                 ('cubed-minus #X229F)

                 ('increment #X2206)
                 ('nabla #X2207)

                 ;; letters
                 ('lambda #X03BB)
                 ('alpha #X03B1)
                 ('beta #X03B2)
                 ('gamma #X03B3)
                 ('delta #X03B4)

                 ('contains-as-member #X220B)
                 ('small-contains-as-member #X220D)

                 ('constn-attr #X0043)   ;ToDo: Add boxing character.
                 ('static-attr #X0053)  ;ToDo: Add boxing character.
                 )))

;; ---------------------------------------------------------------------------

;; NOTE: attribute can be for example
;; '(:weight bold :height 1.0 :box (:line-width -1 :color "Red" :style released-button))
(defun subst-with-unicode (pattern symbol &optional attributes)
  "Add a font lock hook to replace the matched part of PATTERN
  with the Unicode symbol SYMBOL looked up with unicode-symbol()
  and fontified using the list of font attributes ATTRIBUTES."
  (interactive)
  (font-lock-add-keywords
   nil `(
         (,pattern (1 (progn
                        (compose-region (match-beginning 1) (match-end 1)
                                        ,(unicode-symbol symbol))
                        ,attributes
                        )
                      ))
         )))

(defun subst-list-with-unicode (patterns)
  "Call SUBST-WITH-UNICODE repeatedly."
  (mapcar (lambda (x)
              ;;(message "1:%S 2:%S 3:%S" (nth 0 x) (nth 1 x) (nth 2 x))
              (subst-with-unicode (nth 0 x) (nth 1 x) (nth 2 x))
              )
          patterns))

;; ---------------------------------------------------------------------------
;; Here’s how you could use it to make the assignment and answering
;; operators of Smalltalk a bit prettier:

(defun smalltalk-unicode ()
  (interactive)
  (subst-list-with-unicode
   (list (list "\\(:=\\)" 'left-arrow)
         (list "\\(\\^\\)" 'up-arrow))))

;; ---------------------------------------------------------------------------
;;; And to prettify ObjectiveCaml source (For some reason, tuareg.el
;;; turns on font lock after it runs the hooks, which makes the
;;; following break font locking. Simply transposing the lines solves
;;; the problem.):

(defun ocaml-unicode ()
  (interactive)
  (subst-list-with-unicode
   (list (list "\\(<-\\)" 'left-arrow)
         (list "\\(->\\)" 'right-arrow)
         (list "[^=]\\(=\\)[^=]" 'equal)
         (list "\\(==\\)" 'identical)
         (list "\\(\\!=\\)" 'not-identical)
         (list "\\(<>\\)" 'not-equal)
         (list "\\(()\\)" 'nil)

         (list (concat "\\(" "\\_<" "sqrt" "\\_>" "\\)") 'square-root)

         (list "\\(&&\\)" 'logical-and)
         (list "\\(||\\)" 'logical-or)

         (list (concat "\\(" "\\_<" "not" "\\_>" "\\)") 'logical-neg)

         (list "\\(>\\)[^=]" 'greater-than)
         (list "\\(<\\)[^=]" 'less-than)
         (list "\\(>=\\)" 'greater-than-or-equal-to)
         (list "\\(<=\\)" 'less-than-or-equal-to)

         (list (concat "\\<" "\\(" "alpha" "\\)" "\\>") 'alpha)
         (list (concat "\\<" "\\(" "beta" "\\)" "\\>") 'beta)
         (list (concat "\\<" "\\(" "gamma" "\\)" "\\>") 'gamma)
         (list (concat "\\<" "\\(" "delta" "\\)" "\\>") 'delta)

         (list "\\(''\\)" 'double-prime)
         (list "\\('\\)" 'prime)

         (list "\\<\\(List.for_all\\)\\>" 'for-all)
         (list "\\<\\(List.exists\\)\\>" 'there-exists)
         (list "\\<\\(List.mem\\)\\>" 'element-of)
         (list "^ +\\(|\\)" 'double-vertical-bar))))

;; ---------------------------------------------------------------------------
;;; And for Haskell:

(defun haskell-unicode ()
  (interactive)
  (subst-list-with-unicode
   (list (list "\\(<-\\)" 'left-arrow)
         (list "\\(->\\)" 'right-arrow)

         (list "\\(-<\\)" 'left-arrow-tail)
         (list "\\(>-\\)" 'right-arrow-tail)

         (list "\\(-<<\\)" 'left-double-arrow-tail)
         (list "\\(>>-\\)" 'right-double-arrow-tail)

         (list "\\(==\\)" 'identical)
         (list "\\(/=\\)" 'not-identical)

         (list "\\(|>\\)" 'white-right-pointing-triangle)
         (list "\\(<|\\)" 'white-left-pointing-triangle)

         (list "[^\\.]\\(\\.\\)[^\\.]" 'composition)

         ;;(list "\\(()\\)" 'nil)

         (list (concat "\\(" "\\_<" "sqrt" "\\_>" "\\)") 'square-root)

         (list "\\(&&\\)" 'logical-and)
         (list "\\(||\\)" 'logical-or)

         (list (concat "\\(" "\\_<" "not" "\\_>" "\\)") 'logical-neg)

         (list "\\(>\\)[^=]" 'greater-than)
         (list "\\(<\\)[^=]" 'less-than)

         (list "\\(>=\\)" 'greater-than-or-equal-to)
         (list "\\(<=\\)" 'less-than-or-equal-to)

         (list (concat "\\<" "\\(" "alpha" "\\)" "\\>") 'alpha)
         (list (concat "\\<" "\\(" "beta" "\\)" "\\>") 'beta)
         (list (concat "\\<" "\\(" "gamma" "\\)" "\\>") 'gamma)
         (list (concat "\\<" "\\(" "delta" "\\)" "\\>") 'delta)

         (list "\\(''\\)" 'double-prime)
         (list "\\('\\)" 'prime)
         (list "\\(!!\\)" 'double-exclamation)
         (list "\\(\\.\\.\\)" 'horizontal-ellipsis))))

;; ---------------------------------------------------------------------------
;;; And for C,C++,Java:

(defun c-common-unicode ()
  (interactive)
  (subst-list-with-unicode
   (list
    ;;(list (concat "[^|&!<>=\\+-]" "\\(" "=" "\\)" "[^<>=]") 'left-arrow)
    (list (concat "[^!=<>]" "\\(" "=" "\\)" "[^<>=]") 'left-arrow)

    ;;NOTE: I want 'contains-as-member but this is not defined yet.
    ;;(list "\\(->\\)" 'right-arrow)

    (list (concat "[^=]" "\\(" "==" "\\)" "[^=]") 'identical)
    (list (concat "[^!]" "\\(" "!=" "\\)" "[^=]") 'not-identical)

    ;;(list (concat "[^\\+]" "\\(" "[\\+]" "[\\+]" "\\)" "[^\\+]") 'squared-plus)
    ;;(list (concat "[^-]" "\\(" "--" "\\)" "[^-]") 'squared-minus)

    (list (concat "\\(" "\\_<" "sqrt" "\\_>" "\\)") 'square-root)
    (list (concat "\\(" "\\_<" "cbrt" "\\_>" "\\)") 'cube-root)

    (list "\\(&&\\)" 'logical-and)
    (list "\\(||\\)" 'logical-or)

    ;;(list (concat "\\(" "\\_<" "not" "\\_>" "\\)") 'logical-neg)
    (list (concat "[^!]" "\\(" "!" "\\)" "[^=]") 'logical-neg)

    (list (concat "[^>]" "\\(" ">" "\\)" "[^=]") 'greater-than)
    (list (concat "[^<]" "\\(" "<" "\\)" "[^=]") 'less-than)

    (list (concat "[^>]" "\\(" ">=" "\\)") 'greater-than-or-equal-to)
    (list (concat "[^<]" "\\(" "<=" "\\)") 'less-than-or-equal-to)

    (list (concat "\\<" "\\(" "alpha" "\\)" "\\>") 'alpha)
    (list (concat "\\<" "\\(" "beta" "\\)" "\\>") 'beta)
    (list (concat "\\<" "\\(" "gamma" "\\)" "\\>") 'gamma)
    (list (concat "\\<" "\\(" "delta" "\\)" "\\>") 'delta)

    ;;(list (concat "\\<" "\\(" "const" "\\)" "\\>") 'const-attr)
    ;;(list (concat "\\<" "\\(" "static" "\\)" "\\>") 'static-attr)
    )))

;; ---------------------------------------------------------------------------
;;; Python

(defun python-unicode ()
  (interactive)
  (subst-list-with-unicode
   (list
    ;;(list (concat "[^|&!<>=\\+-]" "\\(" "=" "\\)" "[^<>=]") 'left-arrow)
    (list (concat "[^!=<>]" "\\(" "=" "\\)" "[^<>=]") 'left-arrow)

    ;;NOTE: I want 'contains-as-member but this is not defined yet.
    ;;(list "\\(->\\)" 'right-arrow)

    (list (concat "[^=]" "\\(" "==" "\\)" "[^=]") 'identical)
    (list (concat "[^!]" "\\(" "!=" "\\)" "[^=]") 'not-identical)

    ;;(list (concat "[^\\+]" "\\(" "[\\+]" "[\\+]" "\\)" "[^\\+]") 'squared-plus)
    ;;(list (concat "[^-]" "\\(" "--" "\\)" "[^-]") 'squared-minus)

    (list (concat "\\(" "\\_<" "sqrt" "\\_>" "\\)") 'square-root)
    (list (concat "\\(" "\\_<" "cbrt" "\\_>" "\\)") 'cube-root)

    (list "\\(&&\\)" 'logical-and)
    (list "\\(||\\)" 'logical-or)

    ;;(list (concat "\\(" "\\_<" "not" "\\_>" "\\)") 'logical-neg)
    (list (concat "[^!]" "\\(" "!" "\\)" "[^=]") 'logical-neg)

    (list (concat "[^>]" "\\(" ">" "\\)" "[^=]") 'greater-than)
    (list (concat "[^<]" "\\(" "<" "\\)" "[^=]") 'less-than)

    (list (concat "[^>]" "\\(" ">=" "\\)") 'greater-than-or-equal-to)
    (list (concat "[^<]" "\\(" "<=" "\\)") 'less-than-or-equal-to)

    (list (concat "\\<" "\\(" "alpha" "\\)" "\\>") 'alpha)
    (list (concat "\\<" "\\(" "beta" "\\)" "\\>") 'beta)
    (list (concat "\\<" "\\(" "gamma" "\\)" "\\>") 'gamma)
    (list (concat "\\<" "\\(" "delta" "\\)" "\\>") 'delta)

    )))

;; (add-hook 'smalltalk-mode-hook 'smalltalk-unicode)
;; (add-hook 'tuareg-mode-hook 'ocaml-unicode)
;; (add-hook 'haskell-mode 'haskell-unicode)
;; (add-hook 'python-mode-hook 'python-unicode)
;; (add-hook 'scons-mode-hook 'python-unicode)
;; (add-hook 'c-mode-common-hook 'c-common-unicode)

(provide 'unicode-overlays)
