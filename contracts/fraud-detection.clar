;; Fraud Detection Contract
;; Monitors for suspicious activity in point transactions

(define-map alerts
  { id: uint }
  {
    user: principal,
    tx-id: uint,
    type: (string-ascii 20),
    status: (string-ascii 10)
  }
)

(define-map user-risk
  { user: principal }
  {
    score: uint,
    alert-count: uint
  }
)

(define-data-var last-id uint u0)
(define-constant admin tx-sender)

;; Create a fraud alert
(define-public (create-alert (user principal) (tx-id uint) (alert-type (string-ascii 20)))
  (let
    (
      (new-id (+ (var-get last-id) u1))
      (risk (default-to { score: u0, alert-count: u0 } (map-get? user-risk { user: user })))
    )
    ;; Only admin can create alerts
    (asserts! (is-eq tx-sender admin) (err u1))

    ;; Update alert counter
    (var-set last-id new-id)

    ;; Update user risk
    (map-set user-risk
      { user: user }
      {
        score: (+ (get score risk) u10),
        alert-count: (+ (get alert-count risk) u1)
      }
    )

    ;; Create the alert
    (ok (map-set alerts
      { id: new-id }
      {
        user: user,
        tx-id: tx-id,
        type: alert-type,
        status: "open"
      }
    ))
  )
)

;; Update alert status
(define-public (update-status (alert-id uint) (status (string-ascii 10)))
  (let
    (
      (alert (unwrap! (get-alert alert-id) (err u404)))
    )
    ;; Only admin can update status
    (asserts! (is-eq tx-sender admin) (err u1))

    ;; Update alert status
    (ok (map-set alerts
      { id: alert-id }
      (merge alert { status: status })
    ))
  )
)

;; Check transaction for fraud
(define-public (check-transaction (user principal) (tx-id uint) (amount uint))
  ;; Simple check - flag large transactions
  (if (> amount u10000)
    (create-alert user tx-id "large-amount")
    (ok true)
  )
)

;; Get alert details
(define-read-only (get-alert (id uint))
  (map-get? alerts { id: id })
)

;; Get user risk
(define-read-only (get-user-risk (user principal))
  (map-get? user-risk { user: user })
)

