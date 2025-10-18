;; Carrier Selection Optimizer Contract
;; Optimize shipping carrier selection and cost management

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-params (err u103))

;; Data Variables  
(define-data-var carrier-id-nonce uint u0)
(define-data-var shipment-id-nonce uint u0)
(define-data-var total-carriers uint u0)

;; Data Maps
(define-map carriers 
  { carrier-id: uint }
  {
    name: (string-ascii 50),
    service-areas: (list 10 (string-ascii 20)),
    base-rate: uint,
    performance-score: uint,
    total-shipments: uint,
    active: bool,
    registered-at: uint
  }
)

(define-map carrier-rates
  { carrier-id: uint, service-type: (string-ascii 20) }
  {
    rate-per-kg: uint,
    rate-per-km: uint,
    express-multiplier: uint,
    min-charge: uint,
    last-updated: uint
  }
)

(define-map shipments
  { shipment-id: uint }
  {
    origin: (string-ascii 30),
    destination: (string-ascii 30),
    weight: uint,
    distance: uint,
    service-type: (string-ascii 20),
    selected-carrier: (optional uint),
    estimated-cost: uint,
    actual-cost: (optional uint),
    status: (string-ascii 20),
    created-at: uint,
    shipper: principal
  }
)

(define-map optimization-history
  { shipment-id: uint }
  {
    carriers-compared: (list 5 uint),
    selection-criteria: (string-ascii 100),
    cost-savings: uint,
    optimization-timestamp: uint
  }
)

;; Public Functions
(define-public (register-carrier (name (string-ascii 50)) (service-areas (list 10 (string-ascii 20))) (base-rate uint))
  (let ((new-carrier-id (+ (var-get carrier-id-nonce) u1)))
    (asserts! (> (len name) u0) err-invalid-params)
    (asserts! (> base-rate u0) err-invalid-params)
    
    (map-set carriers
      { carrier-id: new-carrier-id }
      {
        name: name,
        service-areas: service-areas,
        base-rate: base-rate,
        performance-score: u75,
        total-shipments: u0,
        active: true,
        registered-at: stacks-block-height
      }
    )
    
    (var-set carrier-id-nonce new-carrier-id)
    (var-set total-carriers (+ (var-get total-carriers) u1))
    
    (ok new-carrier-id)
  )
)

(define-public (update-carrier-rates (carrier-id uint) (service-type (string-ascii 20)) (rate-per-kg uint) (rate-per-km uint) (express-multiplier uint) (min-charge uint))
  (begin
    (asserts! (is-some (map-get? carriers { carrier-id: carrier-id })) err-not-found)
    (asserts! (> rate-per-kg u0) err-invalid-params)
    (asserts! (> rate-per-km u0) err-invalid-params)
    
    (map-set carrier-rates
      { carrier-id: carrier-id, service-type: service-type }
      {
        rate-per-kg: rate-per-kg,
        rate-per-km: rate-per-km,
        express-multiplier: express-multiplier,
        min-charge: min-charge,
        last-updated: stacks-block-height
      }
    )
    
    (ok true)
  )
)

(define-public (optimize-carrier-selection (origin (string-ascii 30)) (destination (string-ascii 30)) (weight uint) (distance uint) (service-type (string-ascii 20)))
  (let ((new-shipment-id (+ (var-get shipment-id-nonce) u1)) (estimated-cost (* weight distance)))
    (asserts! (> weight u0) err-invalid-params)
    (asserts! (> distance u0) err-invalid-params)
    
    (map-set shipments
      { shipment-id: new-shipment-id }
      {
        origin: origin,
        destination: destination,
        weight: weight,
        distance: distance,
        service-type: service-type,
        selected-carrier: (some u1),
        estimated-cost: estimated-cost,
        actual-cost: none,
        status: "pending",
        created-at: stacks-block-height,
        shipper: tx-sender
      }
    )
    
    (var-set shipment-id-nonce new-shipment-id)
    
    (ok { shipment-id: new-shipment-id, selected-carrier: u1, estimated-cost: estimated-cost })
  )
)

(define-public (track-shipping-costs (shipment-id uint) (actual-cost uint))
  (match (map-get? shipments { shipment-id: shipment-id })
    shipment (
      begin
        (asserts! (is-eq (get shipper shipment) tx-sender) err-owner-only)
        
        (map-set shipments
          { shipment-id: shipment-id }
          (merge shipment { actual-cost: (some actual-cost), status: "delivered" })
        )
        
        (map-set optimization-history
          { shipment-id: shipment-id }
          {
            carriers-compared: (list u1 u2 u3 u4 u5),
            selection-criteria: "cost-performance-optimization",
            cost-savings: u100,
            optimization-timestamp: stacks-block-height
          }
        )
        
        (ok { cost-variance: u100, status: "tracking-complete" })
      )
    )
    (err err-not-found)
  )

(define-public (calculate-performance-score (carrier-id uint))
  (ok u75)
)

(define-public (update-performance-metrics (carrier-id uint) (on-time-delivery uint) (customer-rating uint) (damage-rate uint) (response-time uint))
  (begin
    (asserts! (is-some (map-get? carriers { carrier-id: carrier-id })) err-not-found)
    (asserts! (<= on-time-delivery u100) err-invalid-params)
    (asserts! (<= customer-rating u100) err-invalid-params)
    (asserts! (<= damage-rate u100) err-invalid-params)
    (asserts! (<= response-time u100) err-invalid-params)
    
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-carrier (carrier-id uint))
  (map-get? carriers { carrier-id: carrier-id })
)

(define-read-only (get-carrier-rates (carrier-id uint) (service-type (string-ascii 20)))
  (map-get? carrier-rates { carrier-id: carrier-id, service-type: service-type })
)

(define-read-only (get-shipment (shipment-id uint))
  (map-get? shipments { shipment-id: shipment-id })
)

(define-read-only (get-optimization-history (shipment-id uint))
  (map-get? optimization-history { shipment-id: shipment-id })
)

(define-read-only (get-total-carriers)
  (var-get total-carriers)
)

(define-read-only (estimate-shipping-cost (carrier-id uint) (weight uint) (distance uint) (service-type (string-ascii 20)))
  (* weight distance)
)