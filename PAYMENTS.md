# Documentación de Pagos - Leagend

## Estado Actual del Sistema de Pagos

### ❌ Sistema de Pagos NO Implementado

**Resumen:** La aplicación Leagend **NO tiene implementado** un sistema de pagos completo. Solo existen campos básicos para precios y tarifas, pero no hay integración con procesadores de pago.

## Campos de Precio Existentes

### 1. Modelo Duel
**Archivo:** `app/models/duel.rb`

**Campos de Precio:**
```ruby
attribute :price, :decimal, default: 0.0
attribute :budget, :decimal, default: 0.0
attribute :referee_fee, :decimal, default: 0.0
```

**Validaciones:**
```ruby
validates :price, :budget, :referee_fee, numericality: { greater_than_or_equal_to: 0 }
```

**Propósito:**
- `price` - Precio del duelo (no implementado)
- `budget` - Presupuesto del duelo (no implementado)
- `referee_fee` - Tarifa del árbitro (no implementado)

### 2. Modelo Referee
**Archivo:** `app/models/referee.rb`

**Campo de Tarifa:**
```ruby
validates :fee, numericality: { greater_than_or_equal_to: 0 }
```

**Propósito:**
- `fee` - Tarifa por partido del árbitro (no implementado)

## ❌ Componentes Faltantes

### 1. Modelo Payment
**Estado:** No existe
**Ubicación esperada:** `app/models/payment.rb`

**Estructura recomendada:**
```ruby
class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :duel, optional: true
  belongs_to :reservation, optional: true
  
  enum :status, { 
    pending: 0,      # Pendiente de pago
    processing: 1,    # Procesando
    completed: 2,     # Completado
    failed: 3,       # Fallido
    refunded: 4      # Reembolsado
  }
  
  enum :payment_type, {
    duel_fee: 0,     # Pago por duelo
    arena_rental: 1, # Alquiler de arena
    referee_fee: 2   # Tarifa de árbitro
  }
  
  validates :amount, numericality: { greater_than: 0 }
  validates :stripe_payment_intent_id, presence: true
  validates :status, presence: true
end
```

### 2. Controladores de Pago
**Estado:** No existen
**Ubicaciones esperadas:**
- `app/controllers/payments_controller.rb`
- `app/controllers/webhooks_controller.rb`

### 3. Configuración de Stripe
**Estado:** No existe
**Ubicación esperada:** `config/initializers/stripe.rb`

**Configuración recomendada:**
```ruby
# config/initializers/stripe.rb
Rails.application.configure do
  config.stripe = {
    publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
    secret_key: ENV['STRIPE_SECRET_KEY'],
    webhook_secret: ENV['STRIPE_WEBHOOK_SECRET']
  }
end
```

### 4. Gemas de Stripe
**Estado:** No instaladas
**Gemas necesarias:**
```ruby
# Gemfile
gem 'stripe'
gem 'stripe-rails' # Opcional, para helpers
```

## Flujo de Pagos Recomendado

### 1. Creación de Pago
```ruby
# app/services/payment_service.rb
class PaymentService
  def self.create_payment(user, duel, amount)
    # Crear Payment Intent en Stripe
    payment_intent = Stripe::PaymentIntent.create({
      amount: (amount * 100).to_i, # Stripe usa centavos
      currency: 'usd',
      customer: user.stripe_customer_id,
      metadata: {
        duel_id: duel.id,
        user_id: user.id
      }
    })
    
    # Crear registro local
    Payment.create!(
      user: user,
      duel: duel,
      amount: amount,
      status: :pending,
      stripe_payment_intent_id: payment_intent.id
    )
  end
end
```

### 2. Webhook de Stripe
```ruby
# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.config.stripe[:webhook_secret]
    
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      render json: { error: e.message }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: e.message }, status: 400
      return
    end
    
    case event.type
    when 'payment_intent.succeeded'
      handle_payment_success(event.data.object)
    when 'payment_intent.payment_failed'
      handle_payment_failure(event.data.object)
    end
    
    render json: { received: true }
  end
  
  private
  
  def handle_payment_success(payment_intent)
    payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless payment
    
    payment.update!(status: :completed)
    # Lógica adicional después del pago exitoso
  end
  
  def handle_payment_failure(payment_intent)
    payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless payment
    
    payment.update!(status: :failed)
    # Lógica adicional después del pago fallido
  end
end
```

### 3. API de Pagos
```ruby
# app/controllers/api/v1/payments_controller.rb
class Api::V1::PaymentsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    payment = PaymentService.create_payment(
      current_user,
      params[:duel_id],
      params[:amount]
    )
    
    render json: {
      payment_intent_id: payment.stripe_payment_intent_id,
      client_secret: payment.stripe_payment_intent_id
    }
  end
  
  def show
    payment = current_user.payments.find(params[:id])
    render json: payment
  end
end
```

## Estados de Pago Recomendados

### 1. Estados del Payment
```ruby
enum :status, { 
  pending: 0,      # Pendiente de pago
  processing: 1,    # Procesando
  completed: 2,     # Completado
  failed: 3,       # Fallido
  refunded: 4      # Reembolsado
}
```

### 2. Estados del Duel
```ruby
# Agregar al enum existente
enum :status, { 
  pending: 0,           # Pendiente de confirmación
  open: 1,             # Abierto para desafíos
  ongoing: 2,           # En curso
  finished: 3,           # Finalizado
  merged: 4,            # Fusionado con otro duelo
  cancelled: 5,         # Cancelado
  postponed: 6,          # Postergado
  requires_payment: 7,  # Requiere pago
  paid: 8              # Pagado
}
```

## Integración con Modelos Existentes

### 1. Duel
```ruby
# Agregar al modelo Duel
has_many :payments
belongs_to :payment, optional: true

def requires_payment?
  price > 0 && payments.completed.empty?
end

def paid?
  payments.completed.any?
end
```

### 2. Reservation
```ruby
# Agregar al modelo Reservation
has_many :payments
belongs_to :payment, optional: true

def requires_payment?
  reservable.is_a?(Arena) && reservable.price_per_hour > 0
end
```

### 3. User
```ruby
# Agregar al modelo User
has_many :payments
has_many :sent_payments, class_name: 'Payment'
has_many :received_payments, class_name: 'Payment'

def stripe_customer_id
  # Crear customer en Stripe si no existe
  super || create_stripe_customer
end
```

## Rutas Recomendadas

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Rutas de pago
  resources :payments, only: [:show, :create]
  
  # Webhooks
  post '/webhooks/stripe', to: 'webhooks#stripe'
  
  # API de pagos
  namespace :api do
    namespace :v1 do
      resources :payments, only: [:show, :create]
    end
  end
end
```

## Próximos Pasos para Implementar

### 1. Fase 1: Configuración Básica
- [ ] Instalar gema de Stripe
- [ ] Configurar variables de entorno
- [ ] Crear modelo Payment
- [ ] Configurar webhooks

### 2. Fase 2: Integración con Duelos
- [ ] Modificar modelo Duel para pagos
- [ ] Crear servicio de pago
- [ ] Implementar controlador de pagos
- [ ] Agregar validaciones de pago

### 3. Fase 3: Integración con Reservaciones
- [ ] Modificar modelo Reservation
- [ ] Implementar pagos de arena
- [ ] Agregar validaciones de disponibilidad

### 4. Fase 4: Funcionalidades Avanzadas
- [ ] Reembolsos
- [ ] Pagos recurrentes
- [ ] Descuentos y cupones
- [ ] Reportes de pagos

## Notas Importantes

1. **No hay sistema de pagos actual** - Solo campos básicos sin funcionalidad
2. **No hay integración con Stripe** - Necesita implementación completa
3. **No hay webhooks** - Necesita configuración de webhooks
4. **No hay API de pagos** - Necesita endpoints de API
5. **Campos de precio sin uso** - Los campos existen pero no se utilizan

## Recomendaciones

1. **Implementar gradualmente** - Empezar con pagos básicos de duelos
2. **Usar Stripe** - Es el estándar de la industria
3. **Implementar webhooks** - Para sincronización en tiempo real
4. **Agregar validaciones** - Para prevenir pagos duplicados
5. **Documentar flujos** - Para facilitar mantenimiento
