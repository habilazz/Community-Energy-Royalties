(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_UNAUTHORIZED (err u105))
(define-constant ERR_INVALID_COORDINATES (err u106))
(define-constant ERR_FIELD_INACTIVE (err u107))
(define-constant ERR_INVALID_PRODUCTION (err u108))

(define-data-var next-field-id uint u1)
(define-data-var next-production-id uint u1)
(define-data-var next-community-id uint u1)
(define-data-var total-fields uint u0)
(define-data-var total-communities uint u0)
(define-data-var contract-balance uint u0)

(define-map energy-fields
  { field-id: uint }
  {
    operator: principal,
    name: (string-ascii 100),
    latitude: int,
    longitude: int,
    production-rate: uint,
    royalty-rate: uint,
    is-active: bool,
    total-deposited: uint,
    total-distributed: uint,
    created-at: uint
  }
)

(define-map communities
  { community-id: uint }
  {
    representative: principal,
    name: (string-ascii 100),
    latitude: int,
    longitude: int,
    population: uint,
    is-verified: bool,
    total-earned: uint,
    unclaimed-balance: uint,
    created-at: uint
  }
)

(define-map field-operators
  { operator: principal }
  { field-ids: (list 50 uint) }
)

(define-map community-representatives
  { representative: principal }
  { community-ids: (list 10 uint) }
)

(define-map royalty-payments
  { field-id: uint, community-id: uint }
  {
    total-paid: uint,
    last-payment: uint,
    payment-count: uint
  }
)

(define-map proximity-eligibility
  { field-id: uint, community-id: uint }
  {
    distance: uint,
    royalty-share: uint,
    is-eligible: bool
  }
)

(define-map production-records
  { production-id: uint }
  {
    field-id: uint,
    amount: uint,
    recorded-at: uint,
    operator: principal
  }
)

(define-map field-production-history
  { field-id: uint }
  {
    production-ids: (list 100 uint),
    total-production: uint,
    last-recorded: uint
  }
)

(define-public (register-energy-field (name (string-ascii 100)) (latitude int) (longitude int) (production-rate uint) (royalty-rate uint))
  (let (
    (field-id (var-get next-field-id))
    (current-time (get-stacks-block-info? time (- stacks-block-height u1)))
  )
    (asserts! (and (<= latitude 90000000) (>= latitude -90000000)) ERR_INVALID_COORDINATES)
    (asserts! (and (<= longitude 180000000) (>= longitude -180000000)) ERR_INVALID_COORDINATES)
    (asserts! (> production-rate u0) ERR_INVALID_AMOUNT)
    (asserts! (and (> royalty-rate u0) (<= royalty-rate u10000)) ERR_INVALID_AMOUNT)
    
    (map-set energy-fields 
      { field-id: field-id }
      {
        operator: tx-sender,
        name: name,
        latitude: latitude,
        longitude: longitude,
        production-rate: production-rate,
        royalty-rate: royalty-rate,
        is-active: true,
        total-deposited: u0,
        total-distributed: u0,
        created-at: (default-to u0 current-time)
      }
    )
    
    (let ((existing-fields (default-to (list) (get field-ids (map-get? field-operators { operator: tx-sender })))))
      (map-set field-operators 
        { operator: tx-sender }
        { field-ids: (unwrap! (as-max-len? (append existing-fields field-id) u50) ERR_INVALID_AMOUNT) }
      )
    )
    
    (var-set next-field-id (+ field-id u1))
    (var-set total-fields (+ (var-get total-fields) u1))
    (ok field-id)
  )
)

(define-public (register-community (name (string-ascii 100)) (latitude int) (longitude int) (population uint))
  (let (
    (community-id (var-get next-community-id))
    (current-time (get-stacks-block-info? time (- stacks-block-height u1)))
  )
    (asserts! (and (<= latitude 90000000) (>= latitude -90000000)) ERR_INVALID_COORDINATES)
    (asserts! (and (<= longitude 180000000) (>= longitude -180000000)) ERR_INVALID_COORDINATES)
    (asserts! (> population u0) ERR_INVALID_AMOUNT)
    
    (map-set communities 
      { community-id: community-id }
      {
        representative: tx-sender,
        name: name,
        latitude: latitude,
        longitude: longitude,
        population: population,
        is-verified: false,
        total-earned: u0,
        unclaimed-balance: u0,
        created-at: (default-to u0 current-time)
      }
    )
    
    (let ((existing-communities (default-to (list) (get community-ids (map-get? community-representatives { representative: tx-sender })))))
      (map-set community-representatives 
        { representative: tx-sender }
        { community-ids: (unwrap! (as-max-len? (append existing-communities community-id) u10) ERR_INVALID_AMOUNT) }
      )
    )
    
    (var-set next-community-id (+ community-id u1))
    (var-set total-communities (+ (var-get total-communities) u1))
    (ok community-id)
  )
)

(define-public (verify-community (community-id uint))
  (let ((community (unwrap! (map-get? communities { community-id: community-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-set communities
      { community-id: community-id }
      (merge community { is-verified: true })
    )
    (ok true)
  )
)

(define-public (set-proximity-eligibility (field-id uint) (community-id uint) (distance uint) (royalty-share uint))
  (let (
    (field (unwrap! (map-get? energy-fields { field-id: field-id }) ERR_NOT_FOUND))
    (community (unwrap! (map-get? communities { community-id: community-id }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get operator field)) ERR_UNAUTHORIZED)
    (asserts! (get is-verified community) ERR_UNAUTHORIZED)
    (asserts! (<= royalty-share u10000) ERR_INVALID_AMOUNT)
    
    (map-set proximity-eligibility
      { field-id: field-id, community-id: community-id }
      {
        distance: distance,
        royalty-share: royalty-share,
        is-eligible: true
      }
    )
    (ok true)
  )
)

(define-public (deposit-royalties (field-id uint))
  (let (
    (field (unwrap! (map-get? energy-fields { field-id: field-id }) ERR_NOT_FOUND))
    (amount (stx-get-balance tx-sender))
  )
    (asserts! (is-eq tx-sender (get operator field)) ERR_UNAUTHORIZED)
    (asserts! (get is-active field) ERR_FIELD_INACTIVE)
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set energy-fields
      { field-id: field-id }
      (merge field { total-deposited: (+ (get total-deposited field) amount) })
    )
    
    (var-set contract-balance (+ (var-get contract-balance) amount))
    (ok amount)
  )
)

(define-public (distribute-royalties (field-id uint) (community-ids (list 20 uint)))
  (let ((field (unwrap! (map-get? energy-fields { field-id: field-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get operator field)) ERR_UNAUTHORIZED)
    (asserts! (get is-active field) ERR_FIELD_INACTIVE)
    
    (fold distribute-to-community community-ids (ok field-id))
  )
)

(define-private (distribute-to-community (community-id uint) (result (response uint uint)))
  (match result
    success-field-id 
    (let (
      (field (unwrap! (map-get? energy-fields { field-id: success-field-id }) ERR_NOT_FOUND))
      (community (unwrap! (map-get? communities { community-id: community-id }) ERR_NOT_FOUND))
      (eligibility (map-get? proximity-eligibility { field-id: success-field-id, community-id: community-id }))
    )
      (match eligibility
        elig-data
        (if (get is-eligible elig-data)
          (let (
            (royalty-amount (/ (* (get production-rate field) (get royalty-share elig-data)) u10000))
            (payment-record (default-to { total-paid: u0, last-payment: u0, payment-count: u0 } 
                           (map-get? royalty-payments { field-id: success-field-id, community-id: community-id })))
          )
            (if (>= (var-get contract-balance) royalty-amount)
              (begin
                (map-set communities
                  { community-id: community-id }
                  (merge community { 
                    unclaimed-balance: (+ (get unclaimed-balance community) royalty-amount),
                    total-earned: (+ (get total-earned community) royalty-amount)
                  })
                )
                
                (map-set royalty-payments
                  { field-id: success-field-id, community-id: community-id }
                  {
                    total-paid: (+ (get total-paid payment-record) royalty-amount),
                    last-payment: royalty-amount,
                    payment-count: (+ (get payment-count payment-record) u1)
                  }
                )
                
                (map-set energy-fields
                  { field-id: success-field-id }
                  (merge field { total-distributed: (+ (get total-distributed field) royalty-amount) })
                )
                
                (var-set contract-balance (- (var-get contract-balance) royalty-amount))
                (ok success-field-id)
              )
              (ok success-field-id)
            )
          )
          (ok success-field-id)
        )
        (ok success-field-id)
      )
    )
    error-code (err error-code)
  )
)

(define-public (claim-royalties (community-id uint))
  (let (
    (community (unwrap! (map-get? communities { community-id: community-id }) ERR_NOT_FOUND))
    (amount (get unclaimed-balance community))
  )
    (asserts! (is-eq tx-sender (get representative community)) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
    
    (try! (as-contract (stx-transfer? amount tx-sender (get representative community))))
    
    (map-set communities
      { community-id: community-id }
      (merge community { unclaimed-balance: u0 })
    )
    (ok amount)
  )
)

(define-public (deactivate-field (field-id uint))
  (let ((field (unwrap! (map-get? energy-fields { field-id: field-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get operator field)) ERR_UNAUTHORIZED)
    (map-set energy-fields
      { field-id: field-id }
      (merge field { is-active: false })
    )
    (ok true)
  )
)

(define-read-only (get-field-info (field-id uint))
  (map-get? energy-fields { field-id: field-id })
)

(define-read-only (get-community-info (community-id uint))
  (map-get? communities { community-id: community-id })
)

(define-read-only (get-operator-fields (operator principal))
  (map-get? field-operators { operator: operator })
)

(define-read-only (get-representative-communities (representative principal))
  (map-get? community-representatives { representative: representative })
)

(define-read-only (get-payment-history (field-id uint) (community-id uint))
  (map-get? royalty-payments { field-id: field-id, community-id: community-id })
)

(define-read-only (get-proximity-info (field-id uint) (community-id uint))
  (map-get? proximity-eligibility { field-id: field-id, community-id: community-id })
)

(define-read-only (get-contract-stats)
  {
    total-fields: (var-get total-fields),
    total-communities: (var-get total-communities),
    contract-balance: (var-get contract-balance),
    next-field-id: (var-get next-field-id),
    next-community-id: (var-get next-community-id)
  }
)

(define-public (record-production (field-id uint) (amount uint))
  (let (
    (field (unwrap! (map-get? energy-fields { field-id: field-id }) ERR_NOT_FOUND))
    (production-id (var-get next-production-id))
    (current-time (default-to u0 (get-stacks-block-info? time (- stacks-block-height u1))))
    (history (default-to { production-ids: (list), total-production: u0, last-recorded: u0 } 
                         (map-get? field-production-history { field-id: field-id })))
  )
    (asserts! (is-eq tx-sender (get operator field)) ERR_UNAUTHORIZED)
    (asserts! (get is-active field) ERR_FIELD_INACTIVE)
    (asserts! (> amount u0) ERR_INVALID_PRODUCTION)
    
    (map-set production-records
      { production-id: production-id }
      {
        field-id: field-id,
        amount: amount,
        recorded-at: current-time,
        operator: tx-sender
      }
    )
    
    (map-set field-production-history
      { field-id: field-id }
      {
        production-ids: (unwrap! (as-max-len? (append (get production-ids history) production-id) u100) ERR_INVALID_PRODUCTION),
        total-production: (+ (get total-production history) amount),
        last-recorded: current-time
      }
    )
    
    (var-set next-production-id (+ production-id u1))
    (ok production-id)
  )
)

(define-read-only (get-production-record (production-id uint))
  (map-get? production-records { production-id: production-id })
)

(define-read-only (get-field-production-history (field-id uint))
  (map-get? field-production-history { field-id: field-id })
)
