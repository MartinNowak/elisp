;;; Hugo Schmitt (hugows@gmail.com) - Insert elisp function ARGS as a
;;; Yasnippet
;; 	13-01-2008

;; Because you can't have nested snippet-inserts, its probably not a
;; good idea to use this all the time, and also for function that call
;; a lot of other functions inside, like while, progn, etc... its
;; better to use for something like 'buffer-name', 'find-file', etc.

;; Usage:
;; You've just entered a function name but forgot its arguments (cursor is on ^):
;; (push ^)
;; then running lisp-snippet-insert will expand the snippet:
;; (push ${1:x} {2:place})

;; Note: I wasn't aware of Eldoc at the time, which ends up being
;; much easier to use than this.

(provide 'lisp-snippet-insert)
(require 'yasnippet)
(require 'cl) ; remove-if

(defun lisp-snippet-insert ()
  "Insert args for 'current function' as a snippet."
  (interactive)
  (while (looking-back "\\s-") (backward-delete-char 1)) ; remove any extra whitespace
  (let* ((fun (function-called-at-point))
		 (args (unified-function-arglist fun)))
	(insert " ")
	(yas/expand-snippet	(point) (point) (args-to-snippet args))))

(defun unified-function-arglist (fun)
  "Return argument LIST for all kinds of functions (or so i hope)."
  (let ((arglist (help-function-arglist fun)))
	(if (or (stringp arglist) (listp arglist))
		(split-string (substring (downcase (format "%S" (help-function-arglist fun))) 1 -1))
		(cdr (split-string (substring (downcase (car (help-split-fundoc (documentation fun) "ignore"))) 1 -1))))))

(defun args-to-snippet (arglist)
  "Convert string with space separated args to a snippet template.
Args like &optional will be removed."
  (let* ((filterlist '("&optional" "&rest"))
		 (newlist (remove-if (lambda (x) (member x filterlist)) arglist))
		 (template (mapconcat (lambda (arg) (concat "${" arg "}")) newlist " ")))
	template))

;;; end of lisp-snippet-insert.el


