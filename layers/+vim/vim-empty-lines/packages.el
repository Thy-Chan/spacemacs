(setq vim-empty-lines-packages
      '(
        (vim-empty-lines-mode :location local)
        (vi-tilde-fringe :excluded t)
        ))

(defun vim-empty-lines/init-vim-empty-lines-mode ()
  (use-package vim-empty-lines-mode
    :diminish vim-empty-lines-mode
    :init
    (spacemacs/add-to-hooks (lambda () (vim-empty-lines-mode -1)) '(comint-mode-hook
                                                                    eshell-mode-hook
                                                                    eww-mode-hook
                                                                    shell-mode-hook
                                                                    term-mode-hook))
    :config
    (progn
      (global-vim-empty-lines-mode)
      (spacemacs|add-toggle vim-empty-lines-mode
        :status vim-empty-lines-mode
        :on (global-vim-empty-lines-mode)
        :off (global-vim-empty-lines-mode -1)
        :documentation
        "Display an overlay of ~ on empty lines."
        :evil-leader "t~")
      ;; don't enable it on spacemacs home buffer
      (with-current-buffer  "*spacemacs*"
        (vim-empty-lines-mode -1))
      ;; after a major mode is loaded, check if the buffer is read only
      ;; if so, disable vim-empty-lines-mode
      (add-hook 'after-change-major-mode-hook (lambda ()
                                                (when buffer-read-only
                                                  (vim-empty-lines-mode -1)))))))
