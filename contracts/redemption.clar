;; Redemption Contract
;; Manages the exchange of points for rewards

(define-map rewards
  { id: uint }
  {
    name: (string-ascii 50),
    cost: uint,
    active: bool
  }
)

(define-map redemptions
  { id: uint }
  {
    user: principal,
    reward-id: uint,
    cost: uint,
    status: (string-ascii 10)
  }
)

(define-data-var last-reward-id uint u0)
(define-data-var last-redemption-id uint u0)
(define-constant admin tx-sender)

;; Add a new reward
(define-public (add-reward (name (string-ascii 50)) (cost uint))
  (let
    (
      (new-id (+ (var-get last-reward-id) u1))
    )
    ;; Only admin can add rewards
    (asserts! (is-eq tx-sender admin) (err u1))

    ;; Update reward counter
    (var-set last-reward-id new-id)

    ;; Create the reward
    (ok (map-set rewards
      { id: new-id }
      {
        name: name,
        cost: cost,
        active: true
      }
    ))
  )
)

;; Redeem points for a reward
(define-public (redeem-reward (reward-id uint))
  (let
    (
      (new-id (+ (var-get last-redemption-id) u1))
      (reward (unwrap! (get-reward reward-id) (err u404)))
    )
    ;; Check reward is active
    (asserts! (get active reward) (err u2))

    ;; Update redemption counter
    (var-set last-redemption-id new-id)

    ;; Create the redemption
    (ok (map-set redemptions
      { id: new-id }
      {
        user: tx-sender,
        reward-id: reward-id,
        cost: (get cost reward),
        status: "pending"
      }
    ))
  )
)

;; Update redemption status
(define-public (update-status (redemption-id uint) (status (string-ascii 10)))
  (let
    (
      (redemption (unwrap! (get-redemption redemption-id) (err u404)))
    )
    ;; Only admin can update status
    (asserts! (is-eq tx-sender admin) (err u1))

    ;; Update redemption status
    (ok (map-set redemptions
      { id: redemption-id }
      (merge redemption { status: status })
    ))
  )
)

;; Get reward details
(define-read-only (get-reward (id uint))
  (map-get? rewards { id: id })
)

;; Get redemption details
(define-read-only (get-redemption (id uint))
  (map-get? redemptions { id: id })
)

