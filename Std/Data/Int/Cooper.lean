import Std.Data.Int.DivMod
import Std.Data.Nat.Gcd
import Std.Tactic.PermuteGoals
import Std.Tactic.Replace

namespace Int

theorem one_dvd {a : Int} : 1 ∣ a := sorry

/-!
## Int.gcd
-/

theorem gcd_dvd_left {a b : Int} : (gcd a b : Int) ∣ a := sorry
theorem gcd_dvd_right {a b : Int} : (gcd a b : Int) ∣ b := sorry

@[simp] theorem gcd_one_right {a : Int} : gcd a 1 = 1 := sorry
@[simp] theorem gcd_neg_right {a b : Int} : gcd a (-b) = gcd a b := sorry

/-!
## Small solutions to divisibility constraints.
-/

/--
Given a solution `x` to a divisibility constraint `a ∣ b * x + c`,
then `x % d` is another solution as long as `(a / gcd a b) | d`.
-/
theorem dvd_mul_emod_add_of_dvd_mul_add {a b c d x : Int}
    (w : a ∣ b * x + c) (h : (a / gcd a b) ∣ d) :
    a ∣ b * (x % d) + c := by
  obtain ⟨p, w⟩ := w
  obtain ⟨q, rfl⟩ := h
  rw [Int.emod_def, Int.mul_sub, Int.sub_eq_add_neg, Int.add_right_comm, w,
    Int.dvd_add_right (Int.dvd_mul_right _ _), ← Int.mul_assoc, ← Int.mul_assoc, Int.dvd_neg,
    ← Int.mul_ediv_assoc b gcd_dvd_left, Int.mul_comm b a, Int.mul_ediv_assoc a gcd_dvd_right,
    Int.mul_assoc, Int.mul_assoc]
  apply Int.dvd_mul_right

theorem dvd_emod_add_of_dvd_add {a c d x : Int} (w : a ∣ x + c) : a ∣ (x % d) + c := by
  rw [← Int.one_mul x] at w
  rw [← Int.one_mul (x % d)]
  apply dvd_mul_emod_add_of_dvd_mul_add w
  sorry

/-! ## lcm -/

/-- Computes the least common multiple of two integers, as a `Nat`. -/
def lcm (m n : Int) : Nat := m.natAbs.lcm n.natAbs

theorem lcm_pos (hm : 0 < m) (hn : 0 < n) : 0 < lcm m n := sorry

theorem dvd_lcm_right {a b : Int} : b ∣ lcm a b := sorry

@[simp] theorem lcm_self {a : Int} : lcm a a = a.natAbs := sorry

theorem exists_add_of_le {a b : Int} (h : a ≤ b) : ∃ c : Nat, b = a + c := sorry

instance : Trans (fun x y : Int => x ≤ y) (fun x y : Int => x ≤ y) (fun x y : Int => x ≤ y) := ⟨Int.le_trans⟩

theorem ediv_pos_of_dvd {a b : Int} (ha : 0 < a) (hb : 0 ≤ b) (w : b ∣ a) : 0 < a / b := sorry

theorem dvd_of_mul_dvd {a b c : Int} (w : a * b ∣ a * c) (h : 0 < a) : b ∣ c := by
  obtain ⟨z, w⟩ := w
  refine ⟨z, ?_⟩
  replace w := congr_arg (· / a) w
  dsimp at w
  rwa [Int.mul_ediv_cancel_left _ (Int.ne_of_gt h), Int.mul_assoc,
    Int.mul_ediv_cancel_left _ (Int.ne_of_gt h)] at w

theorem le_of_mul_le {a b c : Int} (w : a * b ≤ a * c) (h : 0 < a) : b ≤ c := by
  replace w := Int.sub_nonneg_of_le w
  rw [← Int.mul_sub] at w
  replace w := Int.ediv_nonneg w (Int.le_of_lt h)
  rw [Int.mul_ediv_cancel_left _ (Int.ne_of_gt h)] at w
  exact Int.le_of_sub_nonneg w

/--
There is an integer solution for `x` to the system
```
p ≤ a * x
    b * x ≤ q
d | c * x + s
```
(here `a`, `b`, `d` are positive integers, `c` and `s` are integers,
and `p` and `q` are integers which it may be helpful to think of as evaluations of linear forms),
if and only if there is an integer solution for `k` to the system
```
0 ≤ k < lcm a (a * d / gcd (a * d) c)
b * k + b * p ≤ a * q
    a | k + p
a * d | c * k + c * p + a * s
```
Note in the new system that `k` has explicit lower and upper bounds
(i.e. without a coefficient for `k`, and in terms of `a`, `c`, and `d` only).

This is a statement of "Cooper resolution" with a divisibility constraint.
See `cooper_resolution_left` for a simpler version without the divisibility constraint.
This formulation is "biased" towards the lower bound, so it is called "left Cooper resolution".
See `cooper_resolution_dvd_right` for the version biased towards the upper bound.
-/
theorem cooper_resolution_dvd_left
    {a b c d s p q : Int} (a_pos : 0 < a) (b_pos : 0 < b) (d_pos : 0 < d) :
    (∃ x, p ≤ a * x ∧ b * x ≤ q ∧ d ∣ c * x + s) ↔
    (∃ k : Int, 0 ≤ k ∧ k < lcm a (a * d / gcd (a * d) c) ∧
      b * k + b * p ≤ a * q ∧
      a ∣ k + p ∧
      a * d ∣ c * k + c * p + a * s) := by
  constructor
  · rintro ⟨x, lower, upper, dvd⟩
    obtain ⟨k', w⟩ := exists_add_of_le lower
    refine ⟨k' % (lcm a (a * d / gcd (a * d) c)), Int.ofNat_nonneg _, ?_, ?_, ?_, ?_⟩
    · rw [← Int.ofNat_emod, Int.ofNat_lt]
      exact Nat.mod_lt _ (lcm_pos a_pos (Int.ediv_pos_of_dvd (Int.mul_pos a_pos d_pos)
        (Int.ofNat_nonneg _) gcd_dvd_left))
    · replace upper : a * b * x ≤ a * q :=
        Int.mul_assoc _ _ _ ▸ Int.mul_le_mul_of_nonneg_left upper (Int.le_of_lt a_pos)
      rw [Int.mul_right_comm, w, Int.add_mul, Int.mul_comm p b, Int.mul_comm _ b] at upper
      rw [Int.add_comm]
      calc
        _ ≤ _ := Int.add_le_add_left
          (Int.mul_le_mul_of_nonneg_left (Int.ofNat_le.mpr <| Nat.mod_le _ _) (Int.le_of_lt b_pos)) _
        _ ≤ _ := upper
    · exact Int.ofNat_emod _ _ ▸ dvd_emod_add_of_dvd_add ⟨x, by rw [w, Int.add_comm]⟩
    · rw [Int.add_assoc]
      apply dvd_mul_emod_add_of_dvd_mul_add
      · obtain ⟨z, r⟩ := dvd
        refine ⟨z, ?_⟩
        rw [Int.mul_assoc, ← r, Int.mul_add, Int.mul_comm c x, ← Int.mul_assoc, w, Int.add_mul,
          Int.mul_comm c, Int.mul_comm c, ← Int.add_assoc, Int.add_comm (p * c)]
      · exact Int.dvd_lcm_right
  · rintro ⟨k, nonneg, _, le, a_dvd, ad_dvd⟩
    refine ⟨(k + p) / a, ?_, ?_, ?_⟩
    · rw [Int.mul_ediv_cancel' a_dvd]
      apply Int.le_add_of_nonneg_left nonneg
    · suffices h : a * (b * ((k + p) / a)) ≤ a * q from le_of_mul_le h a_pos
      rw [Int.mul_left_comm a b, Int.mul_ediv_cancel' a_dvd, Int.mul_add]
      exact le
    · suffices h : a * d ∣ a * ((c * ((k + p) / a)) + s) from dvd_of_mul_dvd h a_pos
      rw [Int.mul_add, Int.mul_left_comm, Int.mul_ediv_cancel' a_dvd, Int.mul_add]
      exact ad_dvd

/--
Right Cooper resolution of an upper and lower bound with divisibility constraint.

See further discussion at `cooper_resolution_dvd_left`.
-/
theorem cooper_resolution_dvd_right
    {a b c d s p q : Int} (a_pos : 0 < a) (b_pos : 0 < b) (d_pos : 0 < d) :
    (∃ x, p ≤ a * x ∧ b * x ≤ q ∧ d ∣ c * x + s) ↔
    (∃ k : Int, 0 ≤ k ∧ k < lcm b (b * d / gcd (b * d) c) ∧
      a * k + b * p ≤ a * q ∧
      b ∣ k - q ∧
      b * d ∣ (- c) * k + c * q + b * s) := by
  have this : ∀ x y z : Int, x + -y ≤ -z ↔ x + z ≤ y := by
    intros x y z
    constructor
    · intro h
      replace h := Int.le_add_of_sub_left_le h
      rw [← Int.sub_eq_add_neg] at h
      exact Int.add_le_of_le_sub_right h
    · intro h
      apply Int.sub_le_of_sub_le
      rwa [Int.sub_eq_add_neg, Int.neg_neg]
  suffices h :
    (∃ x, p ≤ a * x ∧ b * x ≤ q ∧ d ∣ c * x + s) ↔
    (∃ k : Int, 0 ≤ k ∧ k < lcm b (b * d / gcd (b * d) (-c)) ∧
      a * k + a * (-q) ≤ b * (-p) ∧
      b ∣ k + (-q) ∧
      b * d ∣ (- c) * k + (-c) * (-q) + b * s) by
    simp only [gcd_neg_right, Int.neg_mul_neg] at h
    simp only [Int.mul_neg, this] at h
    exact h
  constructor
  · rintro ⟨x, lower, upper, dvd⟩
    have h : (∃ x, -q ≤ b * x ∧ a * x ≤ -p ∧ d ∣ -c * x + s) :=
      ⟨-x, Int.mul_neg _ _ ▸ Int.neg_le_neg upper, Int.mul_neg _ _ ▸ Int.neg_le_neg lower,
        by rwa [Int.neg_mul_neg _ _]⟩
    replace h := (cooper_resolution_dvd_left b_pos a_pos d_pos).mp h
    exact h
  · intro h
    obtain ⟨x, lower, upper, dvd⟩ := (cooper_resolution_dvd_left b_pos a_pos d_pos).mpr h
    refine ⟨-x, ?_, ?_, ?_⟩
    · exact Int.mul_neg _ _ ▸ Int.le_neg_of_le_neg upper
    · exact Int.mul_neg _ _ ▸ Int.neg_le_of_neg_le lower
    · exact Int.mul_neg _ _ ▸ Int.neg_mul _ _ ▸ dvd

/--
Left Cooper resolution of an upper and lower bound.

See further discussion at `cooper_resolution_dvd_left`.
-/
theorem cooper_resolution_left
    {a b p q : Int} (a_pos : 0 < a) (b_pos : 0 < b) :
    (∃ x, p ≤ a * x ∧ b * x ≤ q) ↔
    (∃ k : Int, 0 ≤ k ∧ k < a ∧ b * k + b * p ≤ a * q ∧ a ∣ k + p) := by
  have h := cooper_resolution_dvd_left
    a_pos b_pos Int.zero_lt_one (c := 1) (s := 0) (p := p) (q := q)
  simp only [Int.mul_one, Int.one_mul, Int.mul_zero, Int.add_zero, gcd_one_right, Int.ofNat_one,
    Int.ediv_one, lcm_self, Int.natAbs_of_nonneg (Int.le_of_lt a_pos), Int.one_dvd, and_true,
    and_self] at h
  exact h

/--
Right Cooper resolution of an upper and lower bound.

See further discussion at `cooper_resolution_dvd_left`.
-/
theorem cooper_resolution_right
    {a b p q : Int} (a_pos : 0 < a) (b_pos : 0 < b) :
    (∃ x, p ≤ a * x ∧ b * x ≤ q) ↔
    (∃ k : Int, 0 ≤ k ∧ k < b ∧ a * k + b * p ≤ a * q ∧ b ∣ k - q) := by
  have h := cooper_resolution_dvd_right
    a_pos b_pos Int.zero_lt_one (c := 1) (s := 0) (p := p) (q := q)
  have : ∀ k : Int, (b ∣ -k + q) ↔ (b ∣ k - q) := by
    intro k
    rw [← Int.dvd_neg, Int.neg_add, Int.neg_neg, Int.sub_eq_add_neg]
  simp only [Int.mul_one, Int.one_mul, Int.mul_zero, Int.add_zero, gcd_one_right, Int.ofNat_one,
    Int.ediv_one, lcm_self, Int.natAbs_of_nonneg (Int.le_of_lt b_pos), Int.one_dvd, and_true,
    and_self, ← Int.neg_eq_neg_one_mul, this] at h
  exact h
