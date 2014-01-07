;; -*- coding: utf-8 -*-
;;; mandoku-install.el
;; inspired by el-get
;(setq mandoku-base-dir nil)

(defvar mandoku-git-install-url "http://github.com/cwittern/mandoku.git")

(defun mandoku-install (&optional mandoku-base-dir)
  (let ((mandoku-root
	 (file-name-as-directory
	  (or (bound-and-true-p mandoku-base-dir)
	      (concat (file-name-as-directory user-emacs-directory) "mandoku")))))
    
    (setq mandoku-base-dir mandoku-root)

    (when (file-directory-p mandoku-root)
      (add-to-list 'load-path (concat mandoku-root "mandoku/lisp")))

  ;; try to require mandoku, failure means we have to install it
    (unless (require 'mandoku nil t)
      (unless (file-directory-p mandoku-root)
	(make-directory mandoku-root t))
      
      (let* ((package   "mandoku")
	     (buf       (switch-to-buffer "*mandoku bootstrap*"))
	     (pdir      (file-name-as-directory (concat mandoku-root package "/lisp")))
	     (git       (or (executable-find "git")
			    (error "Unable to find `git'")))
	     (url       (or (bound-and-true-p mandoku-git-install-url)
			  "http://github.com/cwittern/mandoku.git"))
	     (default-directory mandoku-root)
	     (process-connection-type nil)   ; pipe, no pty (--no-progress)

	   ;; First clone mandoku
	     (status
	      (call-process
	       git nil `(,buf t) t "--no-pager" "clone" "-v" url package)))

	(unless (zerop status)
	  (error "Couldn't clone mandoku from the Git repository: %s" url))

	;; switch branch if we have to
	(let* ((branch (cond
			;; Check if a specific branch is requested
			((bound-and-true-p mandoku-install-branch))
			;; Check if master branch is requested
			((boundp 'mandoku-master-branch) "master")
			;; As a last resort, use the master branch
			("master")))
	       (remote-branch (format "origin/%s" branch))
	       (default-directory mandoku-root)
	       (bstatus
		(if (string-equal branch "master")
		    0
		  (call-process git nil (list buf t) t "checkout" "-t" remote-branch))))
	  (unless (zerop bstatus)
	    (error "Couldn't `git checkout -t %s`" branch)))

	(add-to-list 'load-path pdir)
	(load package)

	(unless (file-directory-p mandoku-meta-dir)
	  (make-directory mandoku-meta-dir t))
	(unless (file-directory-p mandoku-sys-dir)
	  (make-directory mandoku-sys-dir t))
	(unless (file-directory-p mandoku-temp-dir)
	  (make-directory mandoku-temp-dir t))
	

	(let ((byte-compile-warnings nil)
	      ;; Byte-compile runs emacs-lisp-mode-hook; disable it
	      (file pdir)
	      emacs-lisp-mode-hook)
	  (byte-recompile-directory file 0)))
      ;; TODO to loop over the repository list, get the clone URL there and clone the catalog
      (mandoku-clone-catalog "http://github.com/cwittern/ZB" (user-login-name))

      (add-to-list 'load-path user-emacs-directory)
      (setq mandoku-catalogs-alist nil)
      (mandoku-setup-local-init-file)
      (ignore-errors
	(load "mandoku-local-init"))
      (insert "Now compiling the title list, this can take a few minutes...\n")
      (mandoku-update-subcoll-list)
      (mandoku-update-title-lists)
;      (mandoku-read-titletables)
      (mandoku-read-lookup-list)
      (with-current-buffer (switch-to-buffer "*mandoku bootstrap*")
	(goto-char (point-max))
	(insert "\nCongrats, mandoku is installed and ready to serve!")))))


(defun mandoku-clone-catalog (url &optional mandoku-install-branch)
      (let* ((default-directory mandoku-meta-dir)
	   ;; Now clone the catalogs
	     (buf       (switch-to-buffer "*mandoku bootstrap*"))
	     (git       (or (executable-find "git")
			    (error "Unable to find `git'")))
	     (status
	      (call-process
	       git nil `(,buf t) t "--no-pager" "clone" "-v" url)))
        (unless (zerop status)
	  (error "Couldn't clone mandoku catalogs from the Git repository: %s " (concat url " / " default-directory)))
	;; switch branch if we have to
;; arrgh, cant get this to work yet... git keeps complaining about not being in a git directory...
;; 	(let* ((branch (cond
;; 			;; Check if a specific branch is requested
;; 			((bound-and-true-p mandoku-install-branch))
;; 			;; Check if master branch is requested
;; 			((boundp 'mandoku-master-branch) "master")
;; 			;; As a last resort, use the master branch
;; 			("master")))
;; ;	       (remote-branch (format "origin/%s" branch))
;; ;	       (default-directory (concat default-directory (car (last (split-string url "/")))))
;; 	       (bstatus
;; 		(if (string-equal branch "master")
;; 		    0
;; 		  (progn (insert "defdir: " default-directory "\n")
;; 		  (call-process git nil (list buf t) t "checkout" "-b" branch)))))
;; 	  (unless (zerop bstatus)
;; 	    (error "Couldn't `git checkout -b %s`" branch)))
))	
      

(defun mandoku-setup-local-init-file ()
  (let ((local-init-file (concat (file-name-as-directory user-emacs-directory) "mandoku-local-init.el")))
    (with-current-buffer (find-file-noselect local-init-file)
      (erase-buffer)
  (insert ";; local init file for mandoku
(require 'mandoku)
(require 'mandoku-remote)
(require 'org-mandoku)
(require 'mandoku-dict)

(setq mandoku-repositories-alist '((\"ZB\" . \"http://www.kanripo.org/zb\")))

(setq org-return-follows-link t)

(setq mandoku-do-remote t)


(setq mandoku-base-dir (expand-file-name  \"" mandoku-base-dir   "\"))
(setq mandoku-image-dir (expand-file-name  (concat mandoku-base-dir \"images/\")))
(setq mandoku-index-dir (expand-file-name  (concat mandoku-base-dir \"index/\")))
(setq mandoku-meta-dir (expand-file-name  (concat mandoku-base-dir \"meta/\")))
(setq mandoku-sys-dir (expand-file-name  (concat mandoku-base-dir \"system/\")))
(setq mandoku-temp-dir (expand-file-name  (concat mandoku-base-dir \"temp/\")))

;; dic
(setq mandoku-dict-img-dir nil)
(ignore-errors 
(load \"mandoku-dict\" t)
(global-set-key [f5] 'mandoku-dict-mlookup)
)
(global-set-key [f6] 'mandoku-search-text)
(global-set-key [f7] 'mandoku-search-titles)

(setq org-support-shift-select 'always)

(setq mandoku-dict-url \"http://www.kanripo.org/zb\")

(setq mandoku-catalogs-alist nil)
(dolist (dir (directory-files mandoku-meta-dir nil \"^[^.,].*\"))
  (when (file-directory-p (concat mandoku-meta-dir dir))
    (dolist (file (directory-files (concat mandoku-meta-dir dir) nil \".txt\" ))
      (add-to-list 'mandoku-catalogs-alist 
		   (cons (file-name-sans-extension file) (concat mandoku-meta-dir dir \"/\" file))))))

(mandoku-read-titletables) 

(setq mandoku-catalog (concat mandoku-meta-dir \"mandoku-catalog.txt\"))

(unless (file-exists-p mandoku-catalog)
  (with-current-buffer (find-file-noselect mandoku-catalog)
    (erase-buffer)
    (insert \"#-*- mode: mandoku-view; -*-
#+DATE: \" (format-time-string \"%Y-%m-%d\\n\" (current-time))  
\"#+TITLE: 漢籍リポジトリ目録

# このファイルは自動作成しますので、編集しないでください
# This file is generated automatically, so please do not edit

リンクをクリックするかカーソルをリンクの上に移動して<enter>してください
Click on a link or move the cursor to the link and then press enter

\")

    (dolist (x (sort mandoku-catalogs-alist (lambda (a b) (string< (car a) (car b)))))
      (insert 
       (format \"* [[file:%s][%s %s]]\\n\" 
	       (cdr x) 
	       (car x)
	       (gethash (substring (car x) 2)  mandoku-subcolls))))
    (save-buffer)
    )
  )

(ignore-errors
  (copy-file (concat mandoku-base-dir "mandoku/lisp/mandoku-settings.org") (concat mandoku-meta-dir "settings.org")))
(or (ignore-errors (org-babel-load-file (expand-file-name "settings.org" mandoku-meta-dir))))

 
(setq mandoku-initialized t)
(message \"Loading of local setup for Mandoku finished\")
(find-file mandoku-catalog)
;; mandoku-init ends here

")
(save-buffer)
)))


;; mandoku-install ends here
