{-# OPTIONS --without-K --safe #-}

module Categories.Category.Instance.Properties.Setoids where

open import Level
open import Data.Product using (Σ; proj₁; proj₂; _,_; Σ-syntax; _×_; -,_)
open import Function.Equality using (Π)
open import Relation.Binary using (Setoid; Preorder; Rel)
open import Relation.Binary.PropositionalEquality as ≡ using (_≡_)
open import Relation.Binary.Indexed.Heterogeneous using (_=[_]⇒_)
open import Relation.Binary.Construct.Closure.SymmetricTransitive as ST using (Plus⇔; minimal)
open Plus⇔

open import Categories.Category using (Category; _[_,_])
open import Categories.Functor
open import Categories.Category.Instance.Setoids
open import Categories.Category.Complete
open import Categories.Category.Cocomplete

import Categories.Category.Construction.Cocones as Coc
import Categories.Category.Construction.Cones as Co
import Relation.Binary.Reasoning.Setoid as RS


open Π using (_⟨$⟩_)

module _ {o ℓ e} c ℓ′ {J : Category o ℓ e} (F : Functor J (Setoids (o ⊔ c) (o ⊔ ℓ ⊔ c ⊔ ℓ′))) where
  private
    module J    = Category J
    open Functor F
    module F₀ j = Setoid (F₀ j)
    open F₀ using () renaming (_≈_ to _[_≈_])

  vertex-carrier : Set (o ⊔ c)
  vertex-carrier = Σ J.Obj F₀.Carrier

  coc : Rel vertex-carrier (o ⊔ ℓ ⊔ c ⊔ ℓ′)
  coc (X , x) (Y , y) = Σ[ f ∈ J [ X , Y ] ] Y [ (F₁ f ⟨$⟩ x) ≈ y ]
    
  coc-preorder : Preorder (o ⊔ c) (o ⊔ c) (o ⊔ ℓ ⊔ c ⊔ ℓ′)
  coc-preorder = record
    { Carrier    = vertex-carrier
    ; _≈_        = _≡_
    ; _∼_        = coc
    ; isPreorder = record
      { isEquivalence = ≡.isEquivalence
      ; reflexive     = λ { {j , _} ≡.refl → J.id , (identity (F₀.refl j)) }
      ; trans         = λ { {a , Sa} {b , Sb} {c , Sc} (f , eq₁) (g , eq₂) →
        let open RS (F₀ c)
        in g J.∘ f , (begin
        F₁ (g J.∘ f) ⟨$⟩ Sa    ≈⟨ homomorphism (F₀.refl a) ⟩
        F₁ g ⟨$⟩ (F₁ f ⟨$⟩ Sa) ≈⟨ Π.cong (F₁ g) eq₁ ⟩
        F₁ g ⟨$⟩ Sb            ≈⟨ eq₂ ⟩
        Sc                     ∎) }
      }
    }

Setoids-Cocomplete : (o ℓ e c ℓ′ : Level) → Cocomplete o ℓ e (Setoids (o ⊔ c) (o ⊔ ℓ ⊔ c ⊔ ℓ′))
Setoids-Cocomplete o ℓ e c ℓ′ {J} F = record
  { initial =
    record
    { ⊥        = record
      { N      = ⇛-Setoid
      ; coapex = record
        { ψ       = λ j → record
          { _⟨$⟩_ = j ,_
          ; cong  = λ i≈k → forth (-, identity i≈k)
          }
        ; commute = λ {X} X⇒Y x≈y → back (-, Π.cong (F₁ X⇒Y) (F₀.sym X x≈y))
        }
      }
    ; !        = λ {K} →
      let module K = Cocone K
      in record
      { arr     = record
        { _⟨$⟩_ = to-coapex K
        ; cong  = minimal (coc c ℓ′ F) K.N (to-coapex K) (coapex-cong K)
        }
      ; commute = λ {X} x≈y → Π.cong (Coapex.ψ (Cocone.coapex K) X) x≈y
      }
    ; !-unique = λ { {K} f {a , Sa} {b , Sb} eq →
      let module K = Cocone K
          module f = Cocone⇒ f
          open RS K.N
      in begin
        K.ψ a ⟨$⟩ Sa       ≈˘⟨ f.commute (F₀.refl a) ⟩
        f.arr ⟨$⟩ (a , Sa) ≈⟨ Π.cong f.arr eq ⟩
        f.arr ⟨$⟩ (b , Sb) ∎ }
    }
  }
  where open Functor F
        open Coc F
        module J    = Category J
        module F₀ j = Setoid (F₀ j)
        open F₀ using () renaming (_≈_ to _[_≈_])

        -- this is essentially a symmetric transitive closure of coc
        ⇛-Setoid : Setoid (o ⊔ c) (o ⊔ ℓ ⊔ c ⊔ ℓ′)
        ⇛-Setoid = ST.setoid (coc c ℓ′ F) (Preorder.refl (coc-preorder c ℓ′ F))
        
        to-coapex : ∀ K → vertex-carrier c ℓ′ F → Setoid.Carrier (Cocone.N K)
        to-coapex K (j , Sj) = K.ψ j ⟨$⟩ Sj
          where module K = Cocone K
        coapex-cong : ∀ K → coc c ℓ′ F =[ to-coapex K ]⇒ (Setoid._≈_ (Cocone.N K))
        coapex-cong K {X , x} {Y , y} (f , fx≈y) = begin
          K.ψ X ⟨$⟩ x            ≈˘⟨ K.commute f (F₀.refl X) ⟩
          K.ψ Y ⟨$⟩ (F₁ f ⟨$⟩ x) ≈⟨ Π.cong (K.ψ Y) fx≈y ⟩
          K.ψ Y ⟨$⟩ y            ∎
          where module K = Cocone K
                open RS K.N

Setoids-Complete : (o ℓ e c ℓ′ : Level) → Complete o ℓ e (Setoids (c ⊔ ℓ ⊔ o ⊔ ℓ′) (o ⊔ ℓ′))
Setoids-Complete o ℓ e c ℓ′ {J} F =
  record
  { terminal = record
    { ⊤        = record
      { N     = record
        { Carrier       = Σ (∀ j → F₀.Carrier j)
                            (λ S → ∀ {X Y} (f : J [ X , Y ]) → [ F₀ Y ] F₁ f ⟨$⟩ S X ≈ S Y)
        ; _≈_           = λ { (S₁ , _) (S₂ , _) → ∀ j → [ F₀ j ] S₁ j ≈ S₂ j }
        ; isEquivalence = record
          { refl  = λ j → F₀.refl j
          ; sym   = λ a≈b j → F₀.sym j (a≈b j)
          ; trans = λ a≈b b≈c j → F₀.trans j (a≈b j) (b≈c j)
          }
        }
      ;  apex = record
        { ψ = λ j → record
          { _⟨$⟩_ = λ { (S , _) → S j }
          ; cong  = λ eq → eq j
          }
        ; commute = λ { {X} {Y} X⇒Y {_ , eq} {y} f≈g → F₀.trans Y (eq X⇒Y) (f≈g Y) }
        }
      }
    ; !        = λ {K} →
      let module K = Cone K
      in record
      { arr     = record
        { _⟨$⟩_ = λ x → (λ j → K.ψ j ⟨$⟩ x) , λ f → K.commute f (Setoid.refl K.N)
        ; cong  = λ a≈b j → Π.cong (K.ψ j) a≈b
        }
      ; commute = λ x≈y → Π.cong (K.ψ _) x≈y
      }
    ; !-unique = λ {K} f x≈y j →
      let module K = Cone K
      in F₀.sym j (Cone⇒.commute f (Setoid.sym K.N x≈y))
    }
  }
  where open Functor F
        open Co F
        module J    = Category J
        module F₀ j = Setoid (F₀ j)
        [_]_≈_ = Setoid._≈_
