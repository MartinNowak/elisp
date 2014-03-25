;;; semantic-wxwidgets.el --- Semantic for wxWidgets.

;; wxWidgets:
;; See: http://navaneethkn.wordpress.com/2009/10/11/getting-smart-completion-wxwidgets-cedet-emacs/
;; The wxWidget library uses some preprocessor macros in its class
;; definitions, which currently cannot be correctly dereferenced
;; by Semantic. You have to set these macros manually through

(defun semantic-imply-includes-in-directory (dir)
  "Add all header files in DIR to `semanticdb-implied-include-tags'."
  (let ((files (directory-files dir t "^.+\\.h[hp]*$" t)))
    (defvar-mode-local c++-mode semanticdb-implied-include-tags
      (mapcar (lambda (header)
		(semantic-tag-new-include
		 header
		 nil
		 :filename header))
	      files))))

(when (executable-find "wx-config")
  (defconst wxwidgets-prefix (substring (shell-command-to-string "wx-config --prefix") 0 -1))
  (defconst wxwidgets-version (substring (shell-command-to-string "wx-config --version") 0 -1))
  (defconst wxwidgets-major (substring wxwidgets-version 0 3))
  (defconst wxwidgets-root (expand-file-name (concat "include/wx-" wxwidgets-major) wxwidgets-prefix))

  (when (file-directory-p wxwidgets-root)
    (when (require 'semantic nil t)
      (add-to-list 'auto-mode-alist `(,wxwidgets-root . c++-mode))
      (semantic-add-system-include wxwidgets-root 'c++-mode)))

  (when (require 'inversion nil t)
    (if (inversion-< (inversion-decode-version wxwidgets-version)
                     (inversion-decode-version "2.9.0"))
        (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("WXDLLEXPORT" . ""))
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("WXDLLIMPEXP_CORE" . ""))
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("WXDLLIMPEXP_FWD_CORE" . ""))
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("WXDLLIMPEXP_BASE" . ""))
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("WXDLLIMPEXP_FWD_BASE" . ""))
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("WXDLLIMPEXP_FWD_XML" . ""))
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("WXDLLIMPEXP_ADV" . ""))
      ))
  (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("wxUSE_MENUS" . "1"))
  ;; Another problem with wxWidget is that it can use different
  ;; toolkits, and most of the classes are defined in the toolkit
  ;; header files, which are not included manually in the C++
  ;; files. However, you can include those header files through a
  ;; Semantic feature called “implied includes”. You can use the
  ;; following helper function:

  (let ((wx-gtk-directory (expand-file-name "wx/gtk" wxwidgets-root)))
    (when (file-directory-p wx-gtk-directory)
      (semantic-imply-includes-in-directory wx-gtk-directory))))

(provide 'semantic-wxwidgets)
