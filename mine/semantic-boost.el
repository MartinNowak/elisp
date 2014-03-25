;;; semantic-boost.el --- Semantic for Boost C++ Libraries.

(defconst c++-boost-dir
  (if (file-directory-p "~/alt/include/boost")
      "~/alt/include/boost"
    "/usr/include/boost") "Root Directory for the Boost C++ Libraries.")

(when (file-directory-p c++-boost-dir)
  (when (require 'semantic nil t)
    (add-to-list 'auto-mode-alist `(,c++-boost-dir . c++-mode))
    (semantic-add-system-include c++-boost-dir 'c++-mode)))

(add-to-list 'semantic-lex-c-preprocessor-symbol-file
               (expand-file-name "config.hpp" c++-boost-dir))

(provide 'semantic-boost)
