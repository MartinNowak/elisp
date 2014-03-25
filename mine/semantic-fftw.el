;;; semantic-fftw.el --- Semantic for FFTW.

;; Did you add fftw3.h to the variable `semantic-lex-c-preprocessor-symbol-file'
;; for your project?  I parsed that file, and the raw parsed macro looks ok in
;; `semantic-lex-spp-describe'.
(add-to-list 'semantic-lex-c-preprocessor-symbol-file "/usr/include/fftw3.h")
;;(add-to-list 'semantic-lex-c-preprocessor-symbol-file "/usr/include/OpenSceneGraph-2.7.4/include/osg/Export")

(provide 'semantic-fftw)
