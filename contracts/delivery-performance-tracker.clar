;; Delivery Performance Tracker Contract
;; Track carrier delivery performance and service quality

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-invalid-params (err u203))

;; Data Variables
(define-data-var delivery-id-nonce uint u0)
(define-data-var report-id-nonce uint u0)
(define-data-var total-deliveries uint u0)

;; Data Maps
(define-map deliveries
  { delivery-id: uint }
  {
    shipment-id: uint,
    carrier-id: uint,
    tracking-number: (string-ascii 30),
    pickup-timestamp: (optional uint),
    delivery-timestamp: (optional uint),
    estimated-delivery: uint,
    actual-delivery: (optional uint),
    delivery-status: (string-ascii 20),
    delivery-location: (string-ascii 50),
    recipient: (string-ascii 50),
    created-at: uint,
    created-by: principal
  }
)

(define-map customer-feedback
  { delivery-id: uint }
  {
    rating: uint,
    service-quality: uint,
    delivery-condition: uint,
    timeliness: uint,
    comments: (string-ascii 200),
    feedback-timestamp: uint,
    customer: principal
  }
)

(define-map performance-reports
  { report-id: uint }
  {
    carrier-id: uint,
    report-period: uint,
    total-shipments: uint,
    success-rate: uint,
    average-rating: uint,
    improvement-areas: (list 5 (string-ascii 30)),
    recommendations: (string-ascii 200),
    generated-at: uint
  }
)

(define-map delivery-events
  { delivery-id: uint, event-sequence: uint }
  {
    event-type: (string-ascii 20),
    event-description: (string-ascii 100),
    event-location: (string-ascii 50),
    event-timestamp: uint,
    recorded-by: principal
  }
)

(define-map carrier-incentives
  { carrier-id: uint, period: uint }
  {
    base-incentive: uint,
    performance-bonus: uint,
    customer-satisfaction-bonus: uint,
    on-time-bonus: uint,
    total-earned: uint,
    incentive-status: (string-ascii 20),
    calculated-at: uint
  }
)

;; Public Functions
(define-public (record-delivery-event (shipment-id uint) (carrier-id uint) (tracking-number (string-ascii 30)) (estimated-delivery uint) (delivery-location (string-ascii 50)) (recipient (string-ascii 50)))
  (let ((new-delivery-id (+ (var-get delivery-id-nonce) u1)))
    (asserts! (> (len tracking-number) u0) err-invalid-params)
    
    (map-set deliveries
      { delivery-id: new-delivery-id }
      {
        shipment-id: shipment-id,
        carrier-id: carrier-id,
        tracking-number: tracking-number,
        pickup-timestamp: none,
        delivery-timestamp: none,
        estimated-delivery: estimated-delivery,
        actual-delivery: none,
        delivery-status: "pending",
        delivery-location: delivery-location,
        recipient: recipient,
        created-at: stacks-block-height,
        created-by: tx-sender
      }
    )
    
    (map-set delivery-events
      { delivery-id: new-delivery-id, event-sequence: u1 }
      {
        event-type: "shipment-created",
        event-description: "Delivery tracking initiated",
        event-location: "origin",
        event-timestamp: stacks-block-height,
        recorded-by: tx-sender
      }
    )
    
    (var-set delivery-id-nonce new-delivery-id)
    (var-set total-deliveries (+ (var-get total-deliveries) u1))
    
    (ok new-delivery-id)
  )
)

(define-public (update-delivery-status (delivery-id uint) (status (string-ascii 20)) (event-description (string-ascii 100)) (event-location (string-ascii 50)))
  (match (map-get? deliveries { delivery-id: delivery-id })
    delivery (
      begin
        (map-set deliveries
          { delivery-id: delivery-id }
          (merge delivery { 
            delivery-status: status,
            pickup-timestamp: (if (is-eq status "picked-up") 
              (some stacks-block-height) 
              (get pickup-timestamp delivery)),
            delivery-timestamp: (if (is-eq status "delivered") 
              (some stacks-block-height) 
              (get delivery-timestamp delivery)),
            actual-delivery: (if (is-eq status "delivered") 
              (some stacks-block-height) 
              (get actual-delivery delivery))
          })
        )
        
        (map-set delivery-events
          { delivery-id: delivery-id, event-sequence: u2 }
          {
            event-type: status,
            event-description: event-description,
            event-location: event-location,
            event-timestamp: stacks-block-height,
            recorded-by: tx-sender
          }
        )
        
        (ok true)
      )
    )
    (err err-not-found)
  )

(define-public (track-customer-satisfaction (delivery-id uint) (rating uint) (service-quality uint) (delivery-condition uint) (timeliness uint) (comments (string-ascii 200)))
  (begin
    (asserts! (is-some (map-get? deliveries { delivery-id: delivery-id })) err-not-found)
    (asserts! (<= rating u10) err-invalid-params)
    (asserts! (<= service-quality u10) err-invalid-params)
    (asserts! (<= delivery-condition u10) err-invalid-params)
    (asserts! (<= timeliness u10) err-invalid-params)
    
    (map-set customer-feedback
      { delivery-id: delivery-id }
      {
        rating: rating,
        service-quality: service-quality,
        delivery-condition: delivery-condition,
        timeliness: timeliness,
        comments: comments,
        feedback-timestamp: stacks-block-height,
        customer: tx-sender
      }
    )
    
    (ok true)
  )
)

(define-public (generate-performance-report (carrier-id uint))
  (let ((current-period (/ stacks-block-height u1000)) (new-report-id (+ (var-get report-id-nonce) u1)))
    (map-set performance-reports
      { report-id: new-report-id }
      {
        carrier-id: carrier-id,
        report-period: current-period,
        total-shipments: u10,
        success-rate: u95,
        average-rating: u85,
        improvement-areas: (list "timeliness" "communication" "handling" "tracking" "service"),
        recommendations: "Focus on on-time delivery and customer communication",
        generated-at: stacks-block-height
      }
    )
    
    (var-set report-id-nonce new-report-id)
    (ok new-report-id)
  )
)

(define-public (manage-performance-incentives (carrier-id uint) (base-incentive uint))
  (let ((current-period (/ stacks-block-height u1000)) (total-incentive (+ base-incentive u1000)))
    (map-set carrier-incentives
      { carrier-id: carrier-id, period: current-period }
      {
        base-incentive: base-incentive,
        performance-bonus: u500,
        customer-satisfaction-bonus: u300,
        on-time-bonus: u200,
        total-earned: total-incentive,
        incentive-status: "calculated",
        calculated-at: stacks-block-height
      }
    )
    
    (ok total-incentive)
  )
)

;; Read-only Functions
(define-read-only (get-delivery (delivery-id uint))
  (map-get? deliveries { delivery-id: delivery-id })
)

(define-read-only (get-customer-feedback (delivery-id uint))
  (map-get? customer-feedback { delivery-id: delivery-id })
)

(define-read-only (get-performance-report (report-id uint))
  (map-get? performance-reports { report-id: report-id })
)

(define-read-only (get-delivery-events (delivery-id uint) (event-sequence uint))
  (map-get? delivery-events { delivery-id: delivery-id, event-sequence: event-sequence })
)

(define-read-only (get-carrier-incentives (carrier-id uint) (period uint))
  (map-get? carrier-incentives { carrier-id: carrier-id, period: period })
)

(define-read-only (get-total-deliveries)
  (var-get total-deliveries)
)

(define-read-only (calculate-carrier-score (on-time-rate uint) (customer-satisfaction uint) (success-rate uint))
  (/ (+ 
    (* on-time-rate u40)
    (* customer-satisfaction u35)
    (* success-rate u25)
  ) u100)
)