;;; strip-common.el --- Strip Common Patterns (Prefixes and Suffixes.

(require 'rx-delim)
(require 'power-utils)

(defun strip-common-prefix-suffix-from-string-list (strings &optional delim)
  "Strip common prefix and suffix from STRING-LIST.
Return result in the format (PREFIX-STRING MIDDLE-STRING-LIST SUFFIX-STRING)"
  (let* ((strings-count (length strings))
         )
    (if (= strings-count 1)
        (let* ((thing (car strings))
               (to (read-string (format "Replace \"%s\" with: " (faze thing 'string))
                                thing nil)))
          (list (rx-delim thing delim) to))
      (let* ( ;; find prefix
             (prefix (common-prefix strings))
             (prefix-length (length prefix))

             ;; strip prefix
             (unprefixed-things (mapcar
                                 (lambda (str)
                                   (substring str prefix-length))
                                 strings))

             ;; find suffix
             (suffix (cond ((fboundp 'common-suffix)
                            (common-suffix unprefixed-things))
                           ((fboundp 'completion--common-suffix)
                            (completion--common-suffix unprefixed-things))
                           (t
                            "")))
             (suffix-length (length suffix))

             ;; strip suffix
             (last-things (mapcar
                           (lambda (str)
                             (substring str
                                        0
                                        (- (length str) suffix-length)))
                           unprefixed-things))

             (prefix-to (when (> prefix-length 0)
                          (read-string (format "Replace prefix \"%s\" with: " (faze prefix 'string))
                                       prefix nil)))
             (suffix-to (when (> suffix-length 0)
                          (read-string (format "Replace suffix \"%s\" with: " (faze suffix 'string))
                                       suffix nil)))
             )
        (list (rx-delim-things last-things prefix suffix delim)
              (concat prefix-to "\\1" suffix-to))))))

;;;###autoload
(defun read-strings-common-prefix-suffix-stripped (&optional prompt read-fn delim)
  (interactive)
  (strip-common-prefix-suffix-from-string-list (multi-read-thing prompt 'string t nil read-fn)
                                               delim))
;; Use: (eval (car (read-strings-common-prefix-suffix-stripped "Key string")))

(provide 'strip-common)
