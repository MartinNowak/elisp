;;; org-export-blocks-format-plantuml.el Export UML using plantuml

(add-to-list 'org-export-blocks '(uml iy/org-export-blocks-format-plantuml nil))
(add-to-list 'org-protecting-blocks "uml")

(defvar iy/org-plantuml-jar-path (expand-file-name "~/Dropbox/java-libs/plantuml.jar")
  "Path to the plantuml jar executable.")
(defun iy/org-export-blocks-format-plantuml (body &rest headers)
  "Pass block BODY to the plantuml utility creating an image.
Specify the path at which the image should be saved as the first
element of headers, any additional elements of headers will be
passed to the ditaa utility as command line arguments."
  (message "plantuml-formatting...")
  (let* ((args (if (cdr headers) (mapconcat 'identity (cdr headers) " ")))
         (data-file (make-temp-file "org-plantuml"))
     (hash (progn
         (set-text-properties 0 (length body) nil body)
         (sha1 (prin1-to-string (list body args)))))
     (raw-out-file (if headers (car headers)))
     (out-file-parts (if (string-match "\\(.+\\)\\.\\([^\\.]+\\)$" raw-out-file)
                 (cons (match-string 1 raw-out-file)
                   (match-string 2 raw-out-file))
               (cons raw-out-file "png")))
     (out-file (concat (car out-file-parts) "_" hash "." (cdr out-file-parts))))
    (unless (file-exists-p iy/org-plantuml-jar-path)
      (error (format "Could not find ditaa.jar at %s" iy/org-plantuml-jar-path)))
    (setq body (if (string-match "^\\([^:\\|:[^ ]\\)" body)
           body
         (mapconcat (lambda (x) (substring x (if (> (length x) 1) 2 1)))
                (org-split-string body "\n")
                "\n")))
    (cond
     ((or htmlp latexp docbookp)
      (unless (file-exists-p out-file)
        (mapc ;; remove old hashed versions of this file
         (lambda (file)
           (when (and (string-match (concat (regexp-quote (car out-file-parts))
                                            "_\\([[:alnum:]]+\\)\\."
                                            (regexp-quote (cdr out-file-parts)))
                                    file)
                      (= (length (match-string 1 out-file)) 40))
             (delete-file (expand-file-name file
                                            (file-name-directory out-file)))))
         (directory-files (or (file-name-directory out-file)
                              default-directory)))
        (with-temp-file data-file (insert (concat "@startuml " out-file "\n" body "\n@enduml")))
        (message (concat "java -jar " iy/org-plantuml-jar-path " " args " " data-file))
        (shell-command (concat "java -jar " iy/org-plantuml-jar-path " " args " " data-file)))
      (format "\n[[file:%s]]\n" out-file))
     (t (concat
     "\n#+BEGIN_EXAMPLE\n"
     body (if (string-match "\n$" body) "" "\n")
     "#+END_EXAMPLE\n")))))
