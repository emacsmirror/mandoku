;;support file for the DIV texts.
;; currently there are four subsections s1 s2 s3 s4, they are accessed through different functions
(setq mandoku-div-titles nil)
(setq mandoku-div-titletable (expand-file-name (concat mandoku-meta-dir "div-titles.txt")))

(defun mandoku-div-page-to-image (locid)
"given a location id, returns the path of the image"
(let* ((textid (car (split-string locid ":" )))
       (vol (substring textid 0 3))
      (page (car (cdr (split-string locid ":" )))))
(concat (substring vol 0 1) "/" vol "/" (substring page 0 2) "/"
	vol "-" (substring page 0 4) ".tif")))




(defun mandoku-div-vol-page (vol page)
(interactive "sPlease enter the volume, including a letter (T X J H W), eg T51: \nsPlease enter the page with optional line number like 439a12: ")
(org-mandoku-open (concat "div: " vol ":"  page)))

(defun mandoku-div-parse-location (loc)
"parses the location in the index file, returns a list starting with vol (=sec) page line.
For compatibility with the other collections, we move the text number to the back."
(list (format "n%4.4d" (string-to-number (car (split-string loc "[:_]")))) 
      (concat (car (cdr (split-string loc "[:_]"))) "_" (nth 2  (split-string loc "[:_]")))
      (nth 3 (split-string loc "[:_]"))
      (nth 4 (split-string loc "[:_]"))))


(defun mandoku-div-textid-to-title (textid page)
"returns the title of the text"
;; read the table if necessary
(mandoku-div-read-titletable)
(list textid (gethash textid mandoku-div-titles))
)

(defun mandoku-div-textid-to-file (textid page)
"Textids of the form T01n0001 and page strings like 439a12 are used to find the right file"
  (let* ((subcoll (substring textid 0 2))
	 (textnum (string-to-number (car (cdr (split-string (substring textid 2) "n")))))
	 ;; the page I get passed in from org-mandoku is separated with :
	 (sec (string-to-number (car (split-string page ":")))))
    (mandoku-div-vol-page-to-file subcoll textnum sec)))

(defun mandoku-div-vol-page-to-file (subcoll textnum sec)
"converts the text id and page to a file name.  Page is numeric with the ending abc as 123"
(let ((txtid (concat (upcase subcoll) "n" (format "%4.4d" textnum)))) 
(concat (downcase subcoll) "/" txtid "/" txtid "-" (format "%3.3d" sec) ".txt")
))


(defun mandoku-div-vol-page-to-title  (subcoll vol page)
  (list subcoll (concat vol ":" page))
)


(defun mandoku-div-read-titletable () 
"read the titles table"
  (when (file-exists-p mandoku-div-titletable)
    (unless mandoku-div-titles
      (setq mandoku-div-titles (make-hash-table :test 'equal))
      (with-temp-buffer
        (let ((coding-system-for-read 'utf-8)
              textid)
          (insert-file-contents mandoku-div-titletable)
          (goto-char (point-min))
          (while (re-search-forward "^\\([a-z0-9]+\\)	\\([^	]+\\)" nil t)
	     (puthash (match-string 1) (match-string 2) mandoku-div-titles)))))))
