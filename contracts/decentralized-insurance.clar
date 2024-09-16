;; Decentralized Insurance Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant insurance-fee u100000) ;; 0.1 STX
(define-constant claim-amount u1000000) ;; 1 STX

;; Define data maps
(define-map policies principal uint)
(define-map claims principal bool)

;; Public functions

;; Buy insurance
(define-public (buy-insurance)
  (let ((current-balance (stx-get-balance tx-sender)))
    (if (>= current-balance insurance-fee)
        (begin
          (try! (stx-transfer? insurance-fee tx-sender (as-contract tx-sender)))
          (map-set policies tx-sender block-height)
          (ok true))
        (err u0))))

;; File a claim
(define-public (file-claim)
  (let ((policy-start (default-to u0 (map-get? policies tx-sender))))
    (if (and
         (> policy-start u0)
         (>= (- block-height policy-start) u144) ;; 24 hours (assuming 10-minute block times)
         (not (default-to false (map-get? claims tx-sender))))
        (begin
          (try! (as-contract (stx-transfer? claim-amount (as-contract tx-sender) tx-sender)))
          (map-set claims tx-sender true)
          (ok true))
        (err u1))))

;; Read-only functions

;; Check if an address has a valid policy
(define-read-only (has-valid-policy (address principal))
  (let ((policy-start (default-to u0 (map-get? policies address))))
    (> policy-start u0)))

;; Check if an address has filed a claim
(define-read-only (has-filed-claim (address principal))
  (default-to false (map-get? claims address)))

;; Get contract balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender)))