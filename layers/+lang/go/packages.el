(setq go-packages
      '(
        company
        company-go
        flycheck
        (flycheck-gometalinter :toggle go-use-gometalinter)
        go-eldoc
        go-mode
        (go-oracle :location site)
        (go-rename :location local)
        ))

(defun go/post-init-flycheck ()
  (spacemacs/add-flycheck-hook 'go-mode))

(defun go/init-go-mode()
  (when (memq window-system '(mac ns x))
    (dolist (var '("GOPATH" "GO15VENDOREXPERIMENT"))
      (unless (getenv var)
        (exec-path-from-shell-copy-env var))))

  (use-package go-mode
    :defer t
    :init
    (progn
      (defun spacemacs//go-set-tab-width ()
        "Set the tab width."
        (setq-local tab-width go-tab-width))
      (add-hook 'go-mode-hook 'spacemacs//go-set-tab-width))
    :config
    (progn
      (add-hook 'before-save-hook 'gofmt-before-save)

      (defun spacemacs/go-run-tests (args)
        (interactive)
        (save-selected-window
          (async-shell-command (concat "go test " args))))

      (defun spacemacs/go-run-package-tests ()
        (interactive)
        (spacemacs/go-run-tests ""))

      (defun spacemacs/go-run-package-tests-nested ()
        (interactive)
        (spacemacs/go-run-tests "./..."))

      (defun spacemacs/go-run-test-current-function ()
        (interactive)
        (if (string-match "_test\\.go" buffer-file-name)
            (let ((test-method (if go-use-gocheck-for-testing
                                   "-check.f"
                                 "-run")))
              (save-excursion
                  (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Test[[:alnum:]_]+\\)(.*)")
                  (spacemacs/go-run-tests (concat test-method "='" (match-string-no-properties 2) "'"))))
          (message "Must be in a _test.go file to run go-run-test-current-function")))

      (defun spacemacs/go-run-test-current-suite ()
        (interactive)
        (if (string-match "_test\.go" buffer-file-name)
            (if go-use-gocheck-for-testing
                (save-excursion
                    (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?\\([[:alnum:]]+\\))[ ]+\\)?Test[[:alnum:]_]+(.*)")
                    (spacemacs/go-run-tests (concat "-check.f='" (match-string-no-properties 2) "'")))
              (message "Gocheck is needed to test the current suite"))
          (message "Must be in a _test.go file to run go-test-current-suite")))

      (defun spacemacs/go-run-main ()
        (interactive)
        (shell-command
          (format "go run %s"
                  (shell-quote-argument (buffer-file-name)))))

      (spacemacs/declare-prefix-for-mode 'go-mode "me" "playground")
      (spacemacs/declare-prefix-for-mode 'go-mode "mg" "goto")
      (spacemacs/declare-prefix-for-mode 'go-mode "mh" "help")
      (spacemacs/declare-prefix-for-mode 'go-mode "mi" "imports")
      (spacemacs/declare-prefix-for-mode 'go-mode "mt" "test")
      (spacemacs/declare-prefix-for-mode 'go-mode "mx" "execute")
      (spacemacs/set-leader-keys-for-major-mode 'go-mode
        "hh" 'godoc-at-point
        "ig" 'go-goto-imports
        "ia" 'go-import-add
        "ir" 'go-remove-unused-imports
        "eb" 'go-play-buffer
        "er" 'go-play-region
        "ed" 'go-download-play
        "xx" 'spacemacs/go-run-main
        "ga" 'ff-find-other-file
        "gg" 'godef-jump
        "tt" 'spacemacs/go-run-test-current-function
        "ts" 'spacemacs/go-run-test-current-suite
        "tp" 'spacemacs/go-run-package-tests
        "tP" 'spacemacs/go-run-package-tests-nested))))

(defun go/init-go-eldoc()
  (add-hook 'go-mode-hook 'go-eldoc-setup))

(when (configuration-layer/layer-usedp 'auto-completion)
  (defun go/post-init-company ()
    (spacemacs|add-company-hook go-mode))

  (defun go/init-company-go ()
    (use-package company-go
      :if (configuration-layer/package-usedp 'company)
      :defer t
      :init
      (progn
        (setq company-go-show-annotation t)
        (push 'company-go company-backends-go-mode)))))

(defun go/init-go-oracle()
  (let ((go-path (getenv "GOPATH")))
    (if (not go-path)
        (spacemacs-buffer/warning
         "GOPATH variable not found, go-oracle configuration skipped.")
      (when (load-gopath-file
             go-path "/src/golang.org/x/tools/cmd/oracle/oracle.el")
        (spacemacs/declare-prefix-for-mode 'go-mode "mr" "rename")
        (spacemacs/set-leader-keys-for-major-mode 'go-mode
          "ro" 'go-oracle-set-scope
          "r<" 'go-oracle-callers
          "r>" 'go-oracle-callees
          "rc" 'go-oracle-peers
          "rd" 'go-oracle-definition
          "rf" 'go-oracle-freevars
          "rg" 'go-oracle-callgraph
          "ri" 'go-oracle-implements
          "rp" 'go-oracle-pointsto
          "rr" 'go-oracle-referrers
          "rs" 'go-oracle-callstack
          "rt" 'go-oracle-describe)))))

(defun go/init-go-rename()
  (use-package go-rename
    :init
    (spacemacs/set-leader-keys-for-major-mode 'go-mode "rn" 'go-rename)))

(defun go/init-flycheck-gometalinter()
  (use-package flycheck-gometalinter
    :defer t
    :init
    (add-hook 'go-mode-hook 'spacemacs//go-enable-gometalinter t)))
