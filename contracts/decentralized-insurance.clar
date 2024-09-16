;; Decentralized Insurance Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant insurance-fee u100000) ;; 0.1 STX
(define-constant claim-amount u1000000) ;; 1 STX

;; Define data maps
(define-map policies
  principal
  {
    start: uint,
    claims-count: uint,
    total-paid: uint
  })
(define-map claims principal (list 10 uint))

;; Error codes
(define-constant err-insufficient-balance (err u1))
(define-constant err-invalid-policy (err u2))
(define-constant err-claim-limit-reached (err u3))
(define-constant err-policy-expired (err u4))
(define-constant err-insufficient-contract-balance (err u5))

;; Public functions

;; Buy insurance
(define-public (buy-insurance)
  (let ((current-balance (stx-get-balance tx-sender)))
    (if (>= current-balance insurance-fee)
        (begin
          (try! (stx-transfer? insurance-fee tx-sender (as-contract tx-sender)))
          (map-set policies
            tx-sender
            {
              start: block-height,
              claims-count: u0,
              total-paid: u0
            })
          (ok true))
        err-insufficient-balance)))

;; File a claim
(define-public (file-claim)
  (let (
    (policy (unwrap! (map-get? policies tx-sender) err-invalid-policy))
    (current-claims (default-to (list) (map-get? claims tx-sender)))
  )
    (asserts! (< (len current-claims) max-claims) err-claim-limit-reached)
    (asserts! (< (- block-height (get start policy)) policy-duration) err-policy-expired)
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) claim-amount) err-insufficient-contract-balance)
    
    (try! (as-contract (stx-transfer? claim-amount (as-contract tx-sender) tx-sender)))
    (map-set policies
      tx-sender
      (merge policy {
        claims-count: (+ (get claims-count policy) u1),
        total-paid: (+ (get total-paid policy) claim-amount)
      })
    )
    (map-set claims tx-sender (unwrap-panic (as-max-len? (append current-claims block-height) u10)))
    (ok true)
  ))

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