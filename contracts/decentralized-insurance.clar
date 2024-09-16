;; Decentralized Insurance Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant insurance-fee u100000) ;; 0.1 STX
(define-constant claim-amount u1000000) ;; 1 STX
(define-constant policy-duration u144) ;; 24 hours (assuming 10-minute block times)
(define-constant max-claims u3) ;; Maximum number of claims per policy


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

;; Renew policy
(define-public (renew-policy)
  (let ((policy (unwrap! (map-get? policies tx-sender) err-invalid-policy)))
    (asserts! (>= (stx-get-balance tx-sender) insurance-fee) err-insufficient-balance)
    (try! (stx-transfer? insurance-fee tx-sender (as-contract tx-sender)))
    (map-set policies
      tx-sender
      (merge policy { start: block-height })
    )
    (ok true)
  ))


;; Read-only functions

;; Check if an address has a valid policy
(define-read-only (has-valid-policy (address principal))
  (match (map-get? policies address)
    policy (< (- block-height (get start policy)) policy-duration)
    false
  ))

;; Get policy details
(define-read-only (get-policy-details (address principal))
  (map-get? policies address))

;; Get claim history
(define-read-only (get-claim-history (address principal))
  (map-get? claims address))

;; Get contract balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender)))

;; Get total insured amount
(define-read-only (get-total-insured-amount)
  (fold + (map get-policy-amount (keys policies)) u0))

(define-private (get-policy-amount (address principal))
  (match (map-get? policies address)
    policy (- claim-amount (get total-paid policy))
    u0
  ))

;; Admin functions

;; Update insurance fee
(define-public (update-insurance-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (var-set insurance-fee new-fee)
    (ok true)))

;; Update claim amount
(define-public (update-claim-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (var-set claim-amount new-amount)
    (ok true)))

;; Withdraw excess funds
(define-public (withdraw-excess-funds (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (asserts! (<= amount (- (stx-get-balance (as-contract tx-sender)) (get-total-insured-amount))) (err u406))
    (as-contract (stx-transfer? amount (as-contract tx-sender) contract-owner))))

