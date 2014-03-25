;;; semantic-boost.el --- Semantic for OpenCV C++ Libraries.
;;; see: http://stackoverflow.com/questions/9029872/emacs-cedet-for-opencv-c-interface

(require 'semantic-glib-gtk nil t)

(defgroup semantic-opencv nil
  "Semantic OpenCV Settings."
  :group 'tools)

(defcustom opencv1-root "/usr/include/opencv" "" :group 'semantic-opencv)
(defcustom opencv2-root "/usr/include/opencv2" "" :group 'semantic-opencv)

(semantic-add-system-include opencv1-root 'c-mode)
(semantic-add-system-include opencv2-root 'c++-mode)
(semantic-add-system-include opencv1-root 'c-mode)
(semantic-add-system-include opencv2-root 'c++-mode)

(add-to-list 'semantic-lex-c-preprocessor-symbol-file (expand-file-name "core/types_c.h" opencv2-root))
(add-to-list 'semantic-lex-c-preprocessor-symbol-file (expand-file-name "imgproc/types_c.h" opencv2-root))

(add-to-list 'semantic-lex-c-preprocessor-symbol-map '("CV_PROP_RW" . ""))
(add-to-list 'semantic-lex-c-preprocessor-symbol-map '("CV_EXPORTS" . ""))
(add-to-list 'semantic-lex-c-preprocessor-symbol-map '("CV_EXPORTS_W_SIMPLE" . ""))
(add-to-list 'semantic-lex-c-preprocessor-symbol-map '("CV_EXPORTS_W" . ""))
(add-to-list 'semantic-lex-c-preprocessor-symbol-map '("CV_EXPORTS_W_MAP" . ""))
(add-to-list 'semantic-lex-c-preprocessor-symbol-map '("CV_INLINE" . ""))

(provide 'semantic-opencv)
