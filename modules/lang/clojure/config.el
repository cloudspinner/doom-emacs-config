;;; lang/clojure/config.el -*- lexical-binding: t; -*-

(after! projectile
  (pushnew! projectile-project-root-files "project.clj" "build.boot" "deps.edn"))

;; Large clojure buffers tend to be slower than large buffers of other modes, so
;; it should have a lower threshold too.
(add-to-list 'doom-large-file-size-alist '("\\.\\(?:clj[sc]?\\|dtm\\|edn\\)\\'" . 0.5))

(defvar +clojure-load-clj-refactor-with-lsp nil
  "Whether or not to include clj-refactor along with clojure-lsp.")

;;
;;; Packages

(use-package! clojure-mode
  :hook (clojure-mode . rainbow-delimiters-mode)
  :config
  (set-repl-handler! '(clojure-mode clojurescript-mode clojurec-mode) (λ! (inf-clojure inf-clojure-custom-startup)
                                                                          (inf-clojure-select-target-repl)) :persist t)
  (set-eval-handler! '(clojure-mode clojurescript-mode clojurec-mode) #'inf-clojure-eval-region)

  (set-formatter! 'cljfmt '("cljfmt" "fix" "-") :modes '(clojure-mode clojurec-mode clojurescript-mode))

  (when (modulep! +lsp)
    (add-hook! '(clojure-mode-local-vars-hook
                 clojurec-mode-local-vars-hook
                 clojurescript-mode-local-vars-hook)
               :append
               (defun +clojure-disable-lsp-indentation-h ()
                 (setq-local lsp-enable-indentation nil))
               #'lsp!)
    (after! lsp-clojure
      (dolist (m '(clojure-mode
                   clojurec-mode
                   clojurescript-mode
                   clojurex-mode))
        (add-to-list 'lsp-language-id-configuration (cons m "clojure")))))

  (when (modulep! +tree-sitter)
    (add-hook! '(clojure-mode-local-vars-hook
                 clojurec-mode-local-vars-hook
                 clojurescript-mode-local-vars-hook)
               :append
               #'tree-sitter!)
    ;; TODO: PR this upstream
    (after! tree-sitter-langs
      (add-to-list 'tree-sitter-major-mode-language-alist '(clojurec-mode . clojure))
      (add-to-list 'tree-sitter-major-mode-language-alist '(clojurescript-mode . clojure))))

  (map! (:localleader
         (:map (clojure-mode-map clojurescript-mode-map clojurec-mode-map)
               "'"  (λ! (inf-clojure inf-clojure-custom-startup)
                        (inf-clojure-select-target-repl))
               "c"  #'inf-clojure-connect
               "m"  (λ! (inf-clojure-macroexpand t))
               "M"  #'inf-clojure-macroexpand
               (:prefix ("e" . "eval")
                        "b" #'inf-clojure-eval-buffer
                        "d" #'inf-clojure-eval-defun
                        "e" #'inf-clojure-eval-last-sexp
                        "r" #'inf-clojure-eval-region)
               (:prefix ("h" . "help")
                        "n" #'inf-clojure-show-ns-vars
                        "a" #'inf-clojure-apropos
                        "d" #'inf-clojure-show-var-documentation
                        "s" #'inf-clojure-show-var-source)
               (:prefix ("n" . "namespace")
                        "n" #'inf-clojure-show-ns-vars
                        "r" #'inf-clojure-reload)
               (:prefix ("r" . "repl")
                        "n" #'inf-clojure-set-ns
                        "q" #'inf-clojure-quit
                        "r" #'inf-clojure-reload
                        "R" #'inf-clojure-restart
                        "b" #'inf-clojure-select-target-repl
                        "c" #'inf-clojure-clear-repl-buffer
                        "l" #'inf-clojure-load-file)))))

;; clojure-lsp already uses clj-kondo under the hood
(use-package! flycheck-clj-kondo
  :when (and (modulep! :checkers syntax)
             (not (modulep! :checkers syntax +flymake))
             (not (modulep! +lsp)))
  :after flycheck)
