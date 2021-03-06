;;; smart-op.el --- Insert operators with surrounding spaces smartly

;; Copyright (C) 2004, 2005, 2007, 2008, 2009 William Xu

;; Author: William Xu <william.xwl@gmail.com>
;; Version: 1.1
;; Url: http://xwl.appspot.com/ref/smart-op.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with EMMS; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; When typing operators, this package can automatically insert spaces
;; before and after operators. For instance, `=' will become ` = ', `+='
;; will become ` += '. This is handy for writing C-style sources.

;; To use, put this file to your load-path and the following to your
;; ~/.emacs:
;;             (require 'smart-op)
;;
;; Then `M-x smart-op-mode' for toggling this minor mode.

;; Usage Tips
;; ----------

;; - If you want it to insert operator with surrounding spaces , you'd
;;   better not type the front space yourself, instead, type operator
;;   directly. smart-op-mode will also take this as a hint on how
;;   to properly insert spaces in some specific occasions. For
;;   example, in c-mode, `a*' -> `a * ', `char *' -> `char *'.

;;; Acknowledgements

;; Nikolaj Schumacher <n_schumacher@web.de>, for suggesting
;; reimplementing as a minor mode and providing an initial patch for
;; that.

;;; TODO

;; - for c mode, probably it would be much better doing this in cc-mode.
;; - Merge with dpchiesa-elisp/smart-op.el

;;; Code:

;;; smart-op minor mode

(require 'cc-utils)

(defvar smart-op-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap "=" 'smart-op-=)
    (define-key keymap "<" 'smart-op-<)
    (define-key keymap ">" 'smart-op->)
    (define-key keymap "%" 'smart-op-%)
    (define-key keymap "+" 'smart-op-+)
    (define-key keymap "-" 'smart-op--)
    (define-key keymap "*" 'smart-op-*)
    (define-key keymap "/" 'smart-op-/)
    ;; (define-key keymap "/" 'smart-op-self-insert-command)
    (define-key keymap "&" 'smart-op-&)
    (define-key keymap "|" 'smart-op-self-insert-command)
    ;; (define-key keymap "!" 'smart-op-self-insert-command)
    (define-key keymap ":" 'smart-op-:)
    (define-key keymap "?" 'smart-op-?)
    (define-key keymap "," 'smart-op-\,)
    (define-key keymap "." 'smart-op-.)
    (define-key keymap "~" 'smart-op-~)
    ;; (define-key keymap "{" 'smart-op-lbrace)
    ;; (define-key keymap "}" 'smart-op-rbrace)
    keymap)
  "Keymap used my `smart-op-mode'.")

;;;###autoload
(define-minor-mode smart-op-mode
  "Insert operators with surrounding spaces smartly."
  nil " _+_" smart-op-mode-map)

(defun smart-op-mode-on ()
  (smart-op-mode 1))

;;;###autoload
(defun smart-op-self-insert-command (arg)
  "Insert the entered operator plus surrounding spaces."
  (interactive "p")
  (smart-op-insert (string last-command-event)))

(defconst smart-op-list
  '("=" "<" ">" "%" "+" "-" "*" "/" "&" "|" "!" ":" "?" "," "." "~"))

(defconst smart-op-modes
  '(c-mode c++-mode objc-mode java-mode csharp-mode d-mode ada-mode)
  "Common modes where `smart-op' should have special behaviour.")

(defun smart-op-insert (op &optional only-after)
  "Insert operator OP with surrounding spaces.
e.g., `=' will become ` = ', `+=' will become ` += '.

When ONLY-AFTER, insert space at back only."
  (if (at-syntax-code-p)            ;only inside real code
      (progn
        (delete-horizontal-space)
        (if (or (looking-back (regexp-opt smart-op-list)
                              (save-excursion (beginning-of-line)
                                              (point)))
                only-after
                (bolp))
            (progn (insert (concat op " "))
                   (save-excursion
                     (backward-char 2)
                     (when (bolp)
                       (indent-according-to-mode))))
          (insert (concat " " op " "))))
    (insert op)))

(defun smart-op-bol ()
  (save-excursion
    (beginning-of-line)
    (point)))

(if (fboundp 'python-comment-line-p)
    (defalias 'smart-op-comment-line-p 'python-comment-line-p)
  (defun smart-op-comment-line-p ()
    "Return non-nil if and only if current line has only a comment."
    (save-excursion
      (end-of-line)
      (when (eq 'comment (syntax-ppss-context (syntax-ppss)))
        (back-to-indentation)
        (looking-at (rx (or (syntax comment-start) line-end))))))
  )


;;; Fine Tunings

(defun smart-op-= ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)                ;only inside real code
      (cond ((memq major-mode smart-op-modes)
             (cond ((looking-forward "=")
                    (insert "="))
                   (t
                    (when (looking-back (rx (: (not space)
                                               (| "+" "-" ;additive
                                                  "~"     ;concatenation
                                                  "*" "/" "^^"  ;multiplicative
                                                  "|" "&" "^"  ;bitwise
                                                  "||" "&&" ;logical
                                                  "!" "!<>" "<>" ;equality
                                                  "!<" "!>"
                                                  "<<" ">>"  ;shift
                                                  "<<<" ">>>" ;rotation
                                                  ))))
                      (save-excursion
                        (backward-char 1)
                        (insert " ")))
                    (smart-op-insert "="))))
            (t
             (smart-op-insert "=")))
    (insert "=")))

(defun smart-op-< ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((and (memq major-mode '(c-mode c++-mode objc-mode))
                  (looking-back
                   (concat "\\("
                           (regexp-opt
                            (append
                             '("#include" "vector" "deque" "list" "map"
                               "multimap" "set" "hash_map" "iterator" "template"
                               "pair" "auto_ptr")
                             '("#import")))
                           "\\)\\ *")
                   (smart-op-bol)))
             (insert "<>")
             (backward-char))
            ((eq major-mode 'sgml-mode)
             (insert "<>")
             (backward-char))
            (t
             (smart-op-insert "<")))
    (insert "<")))

(defun smart-op-: ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((memq major-mode smart-op-modes)
             (if (looking-back "\\?.+" (smart-op-bol))
                 (smart-op-insert ":")
               (insert ":")))
            (t
             (smart-op-insert ":" t)))
    (insert ":")))

(defun smart-op-\, ()
  "See `smart-op-insert'."
  (interactive)
  (smart-op-insert "," t))

(defun smart-op-. ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)
      (cond ((smart-op-comment-line-p)
             (smart-op-insert "." t)
             (insert " "))
            ((and (eq major-mode 'd-mode)
                  (looking-back (rx (: (not space) (| ".")))))  ;D range expression
             (save-excursion
               (backward-char 1)
               (insert " "))
             (insert ". "))
            ((or (looking-back "[[:digit:]]" (1- (point)))
                 (and (memq major-mode '(c-mode
                                         c++-mode
                                         objc-mode
                                         java-mode
                                         csharp-mode
                                         ada-mode
                                         d-mode
                                         python-mode
                                         scons-mode))
                      (looking-back "[[:lower:]]" (1- (point)))))
             (insert "."))
            ((memq major-mode '(cperl-mode
                                perl-mode))
             (insert " . "))
            ((memq major-mode (append cc-derived-modes '(ada-mode)))
             (insert "."))
            (t
             (smart-op-insert "." t)
             (insert " ")))
    (insert ".")))

(defun smart-op-& ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((memq major-mode smart-op-modes)
             (insert "&"))
            (t
             (smart-op-insert "&")))
    (insert ".")))

(defun smart-op-* ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((memq major-mode smart-op-modes)
             ;;          (if (or (looking-back "[0-9a-zA-Z]" (1- (point)))
             ;;                  (bolp))
             ;;              (smart-op-insert "*")
             (insert "*"))
            ((memq major-mode '(ada-mode python-mode scons-mode)) ;handle exponentation
             (insert "*"))
            (t
             (smart-op-insert "*")))
    (insert "*")))

(defun smart-op-/ ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((memq major-mode smart-op-modes)
             ;;          (if (or (looking-back "[0-9a-zA-Z]" (1- (point)))
             ;;                  (bolp))
             ;;              (smart-op-insert "/")
             (insert "/"))
            ((memq major-mode '(d-mode python-mode scons-mode)) ;handle exponentation
             (insert "/"))
            (t
             (smart-op-insert "/")))
    (insert "/")))

(defun smart-op-> ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((and (memq major-mode smart-op-modes)
                  (looking-back " - " (- (point) 3)))
             (delete-char -3)
             (insert "->"))
            (t
             (smart-op-insert ">")))
    (insert ">")))

(defun smart-op-+ ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((and (memq major-mode smart-op-modes)
                  (looking-at "="))
             (insert "+")
             (indent-according-to-mode))
            ((and (memq major-mode smart-op-modes)
                  (looking-back "[a-zA-Z_]+ " (- (point) 2)))
             (delete-char -2)
             (delete-horizontal-space)
             (insert "++")
             (indent-according-to-mode))
            ((and (memq major-mode smart-op-modes)
                  (looking-at (rx digit)))
             (insert "+")
             (indent-according-to-mode))
            (t
             (smart-op-insert "+")))
    (insert "+")))

(defun smart-op-- ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((and (memq major-mode smart-op-modes)
                  (looking-at "="))
             (insert "-")
             (indent-according-to-mode))
            ((and (memq major-mode smart-op-modes)
                  (looking-back "- " (- (point) 2)))
             (delete-char -2)
             (delete-horizontal-space)
             (insert "--")
             (indent-according-to-mode))
            ((and (memq major-mode smart-op-modes)
                  (looking-at (rx digit)))
             (insert "-")
             (indent-according-to-mode))
            (t
             (smart-op-insert "-")))
    (insert "-")))

(defun smart-op-? ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((memq major-mode smart-op-modes)
             (smart-op-insert "?"))
            (t
             (smart-op-insert "?" t)))
    (insert "?")))

(defun smart-op-% ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((and (memq major-mode '(c-mode c++-mode objc-mode d-mode)))
             (insert "%"))
            (t
             (smart-op-insert "%")))
    (insert "%")))

(defun smart-op-lbrace ()
  "See `smart-op-insert'{"
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((and (memq major-mode '(c-mode c++-mode objc-mode d-mode)))
             (insert " {")
             (indent-according-to-mode))
            (t
             (smart-op-insert "{")))
    (insert "{")))

(defun smart-op-rbrace ()
  "See `smart-op-insert'}"
  (interactive)
  (if (at-syntax-code-p)            ;only inside real code
      (cond ((and (memq major-mode '(c-mode c++-mode objc-mode d-mode)))
             (insert "} ")
             (indent-according-to-mode))
            (t
             (smart-op-insert "}")))
    (insert "}")))

(defun smart-op-~ ()
  "See `smart-op-insert'."
  (interactive)
  (if (at-syntax-code-p)                ;only inside real code
      (cond ((memq major-mode '(d-mode))
             (smart-op-insert "~"))
            (t
             (insert "~")))
    (insert "~")))

(provide 'smart-op)

;;; smart-op.el ends here
