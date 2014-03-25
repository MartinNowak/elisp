;;; faze.el --- Collection of lots och nice and useful Snippets and Utilities.

(defun italicize (string)
  "Make string `slant' `italic'."
  (propertize string 'slant 'italic))

(defun boldize (string)
  "Make string `weight' `bold'."
  (propertize string 'weight 'bold))

(defun colorize (string color)
  "Make string `color' `color'."
  (propertize string 'color color))

(defun faze (object face)
  "Make object `face' `face'."
  (cond ((stringp object)
         (let ((face2 (cond ((facep face)
                             face)

                            ((eq face 'macro-call)
                             'font-lock-macro-call-face)
                            ((eq face 'macro-ref)
                             'font-lock-macro-ref-face)
                            ((eq face 'macro)
                             'font-lock-macro-name-face)

                            ((memq face '(fun function mode))
                             'font-lock-function-name-face)
                            ((eq face 'function-call)
                             'font-lock-function-call-face)
                            ((eq face 'function-alias)
                             'font-lock-function-alias-face)
                            ((eq face 'builtin)
                             'font-lock-builtin-face)

                            ((eq face 'type)
                             'font-lock-type-face)
                            ((eq face 'class)
                             'font-lock-class-face)

                            ((memq face '(var variable))
                             'font-lock-variable-name-face)
                            ((memq face '(const constant))
                             'font-lock-constant-face)

                            ((memq face '(buf buffer))
                             'font-lock-buffer-name-face)
                            ((memq face '(dir directory))
                             'font-lock-directory-name-face)

                            ((memq face '(file filename file-name))
                             'font-lock-file-name-face)
                            ((memq face '(cmd command prg prog program process))
                             'font-lock-file-name-face)

                            ((memq face '(pkg package))
                             'font-lock-package-name-face)
                            ((memq face '(lib library))
                             'font-lock-library-name-face)

                            ((memq face '(num number))
                             'font-lock-number-face)
                            ((memq face '(str string))
                             'font-lock-string-face)
                            ((memq face '(str regexp))
                             'font-lock-regexp-face)
                            ((memq face '(doc comment))
                             'font-lock-comment-face)

                            ((memq face '(keycomb))
                             'font-lock-keycomb-face)
                            ((memq face '(keyword))
                             'font-lock-keyword-face)

                            (t
                             (error "Undefined face or face-alias %s" (faze face 'face))))))
           (propertize object 'face face2)))
        ((numberp object)
         (faze (number-to-string object) face)
         )
        ((symbolp object)
         (faze (symbol-name object) face)
         )
        ((or (listp object)
             (vectorp object))
         (mapcar `(lambda (th)
                    (faze th ',face))
                 object))))

;; Use: (faze '("x" "y" "z") 'fun)
;; Use: (faze ["x" "y" "z"] 'fun)
;; Use: (faze '(x y z) 'fun)
;; Use: (faze 'x 'fun)

(provide 'faze)
