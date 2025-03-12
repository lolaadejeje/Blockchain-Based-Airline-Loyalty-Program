;; Partner Integration Contract
;; Facilitates point transfers between airlines

(define-map partners
  { id: uint }
  {
    name: (string-ascii 50),
    address: principal,
    rate: uint,
    active: bool
  }
)

(define-map transfers
  { id: uint }
  {
    user: principal,
    partner-id: uint,
    amount: uint,
    direction: (string-ascii 10),
    status: (string-ascii 10)
  }
)

(define-data-var last-partner-id uint u0)
(define-data-var last-transfer-id uint u0)
(define-constant admin tx-sender)

;; Add a new partner
(define-public (add-partner (name (string-ascii 50)) (address principal) (rate uint))
  (let
    (
      (new-id (+ (var-get last-partner-id) u1))
    )
    ;; Only admin can add partners
    (asserts! (is-eq tx-sender admin) (err u1))

    ;; Update partner counter
    (var-set last-partner-id new-id)

    ;; Create the partner
    (ok (map-set partners
      { id: new-id }
      {
        name: name,
        address: address,
        rate: rate,
        active: true
      }
    ))
  )
)

;; Transfer points to a partner
(define-public (transfer-to-partner (partner-id uint) (amount uint))
  (let
    (
      (new-id (+ (var-get last-transfer-id) u1))
      (partner (unwrap! (get-partner partner-id) (err u404)))
    )
    ;; Check partner is active
    (asserts! (get active partner) (err u2))

    ;; Update transfer counter
    (var-set last-transfer-id new-id)

    ;; Create the transfer
    (ok (map-set transfers
      { id: new-id }
      {
        user: tx-sender,
        partner-id: partner-id,
        amount: amount,
        direction: "outgoing",
        status: "pending"
      }
    ))
  )
)

;; Receive points from a partner
(define-public (receive-from-partner (partner-id uint) (amount uint) (user principal))
  (let
    (
      (new-id (+ (var-get last-transfer-id) u1))
      (partner (unwrap! (get-partner partner-id) (err u404)))
    )
    ;; Only the partner can call this
    (asserts! (is-eq tx-sender (get address partner)) (err u1))

    ;; Update transfer counter
    (var-set last-transfer-id new-id)

    ;; Create the transfer
    (ok (map-set transfers
      { id: new-id }
      {
        user: user,
        partner-id: partner-id,
        amount: amount,
        direction: "incoming",
        status: "completed"
      }
    ))
  )
)

;; Get partner details
(define-read-only (get-partner (id uint))
  (map-get? partners { id: id })
)

;; Get transfer details
(define-read-only (get-transfer (id uint))
  (map-get? transfers { id: id })
)

