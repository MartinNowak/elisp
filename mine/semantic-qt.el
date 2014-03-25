;;; semantic-qt4.el --- Semantic for Qt4.

(defgroup semantic-qt4 nil
  "Semantic Qt4 Support."
  :group 'libraries)

(defcustom qt4-base-dir
  "/usr/include/qt4"
  :group 'semantic-qt4)
(defcustom qt4-gui-dir
  (expand-file-name "QtGui" qt4-base-dir)
  :group 'semantic-qt4)

(semantic-add-system-include qt4-base-dir 'c++-mode)
(semantic-add-system-include qt4-gui-dir 'c++-mode)

(add-to-list 'auto-mode-alist (cons qt4-base-dir 'c++-mode))
(add-to-list 'semantic-lex-c-preprocessor-symbol-file (expand-file-name "Qt/qconfig.h" qt4-base-dir))
(add-to-list 'semantic-lex-c-preprocessor-symbol-file (expand-file-name "Qt/qconfig-large.h" qt4-base-dir))
(add-to-list 'semantic-lex-c-preprocessor-symbol-file (expand-file-name "Qt/qglobal.h" qt4-base-dir))

(provide 'semantic-qt)
