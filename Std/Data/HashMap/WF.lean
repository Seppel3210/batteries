  /-
  Copyright (c) 2022 Mario Carneiro. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Mario Carneiro, Markus Himmel
  -/
  import Std.Data.HashMap.Basic
  import Std.Data.Array.Lemmas
  import Std.Data.Nat.Lemmas

  namespace Std.HashMap
  namespace Imp

  attribute [-simp] Bool.not_eq_true

  namespace Buckets

  @[ext] protected theorem ext : ∀ {b₁ b₂ : Buckets α β}, b₁.1.data = b₂.1.data → b₁ = b₂
    | ⟨⟨_⟩, _⟩, ⟨⟨_⟩, _⟩, rfl => rfl

  theorem update_data (self : Buckets α β) (i d h) :
      (self.update i d h).1.data = self.1.data.set i.toNat d := rfl

  theorem update_get {self : Buckets α β} {i d h} {j : Nat} (hj : j < (self.update i d h).1.size) :
      have : j < self.1.size := by simpa using hj;
      (self.update i d h).1[j] = if i.toNat = j then d else self.1[j] := by
    simp [Buckets.update]
    rw [Array.get_set]

  theorem exists_of_update (self : Buckets α β) (i d h) :
      ∃ l₁ l₂, self.1.data = l₁ ++ self.1[i] :: l₂ ∧ List.length l₁ = i.toNat ∧
        (self.update i d h).1.data = l₁ ++ d :: l₂ := by
    simp [Array.getElem_eq_data_get]; exact List.exists_of_set' h

  theorem update_update (self : Buckets α β) (i d d' h h') :
      (self.update i d h).update i d' h' = self.update i d' h := by
    simp [update]; congr 1; rw [Array.set_set]

  @[simp] theorem mk_size' (h) : (mk n h : Buckets α β).1.size = n := by
    simp [Buckets.mk]

  @[simp]
  theorem mk_val (h) (i : Nat) {h' : i < (Buckets.mk n h).1.size} :
      (mk n h : Buckets α β).val[i] = .nil := by
    simp [Buckets.mk]

  open List

  theorem toDList_eq' [BEq α] [Hashable α] (self : Buckets α β) :
      self.toDList = self.1.data.bind AssocList.toDList := by
    rfl

theorem List.perm_append_comm_assoc (l₁ l₂ l₃ : List α) : l₁ ++ (l₂ ++ l₃) ~ l₂ ++ (l₁ ++ l₃) := by
  simpa only [List.append_assoc] using perm_append_comm.append_right _

theorem bucket_toDList_perm_update [BEq α] [Hashable α]
      (self : Buckets α β) (i : USize) (hi : i.toNat < self.1.size) (d : AssocList α β) :
        ∃ l, self.toDList ~ self.1[i].toDList ++ l ∧
          (self.update i d hi).toDList ~ d.toDList ++ l ∧
          (∀ [EquivBEq α], self.WF → ∀ k, l.containsKey k → ((hash k).toUSize % self.1.size).toNat ≠ i.toNat) := by
    obtain ⟨l₁, l₂, h₁, h₂, h₃⟩ := self.exists_of_update i d hi
    refine ⟨l₁.bind AssocList.toDList ++ l₂.bind AssocList.toDList, ?_, ?_, ?_⟩
    · rw [toDList_eq', h₁]
      simpa using List.perm_append_comm_assoc _ _ _
    · rw [toDList_eq', h₃]
      simpa using List.perm_append_comm_assoc _ _ _
    · intros _ h k hk
      simp at hk
      rcases hk with (hk|hk)
      · rw [containsKey_eq_true_iff_exists_mem] at hk
        rcases hk with ⟨⟨k', v'⟩, ⟨hk₁, hk₂⟩⟩
        rw [mem_bind] at hk₁
        obtain ⟨b, ⟨hb₁, hb₂⟩⟩ := hk₁
        obtain ⟨j, hj⟩ := get_of_mem hb₁
        have : l₁.length ≤ self.val.data.length := by
          rw [h₁]
          simp
          exact Nat.le_add_right l₁.length (l₂.length + 1)
        have hkey : self.val.data.get (j.castLE this) = b := by
          rcases j with ⟨j, hj'⟩
          simp
          rw [← List.getElem_eq_get]
          simp only [h₁]
          rw [List.getElem_eq_get]
          rwa [List.get_append_left _ _ hj']
        have hh := h.hash_self j (j.castLE this).2 k
        have : j.1 ≠ i.toNat := by omega
        rw [hh]
        exact this
        erw [Array.getElem_eq_data_get, hkey, containsKey_eq_true_iff_exists_mem]
        refine ⟨⟨k', v'⟩, hb₂, hk₂⟩
      · rw [containsKey_eq_true_iff_exists_mem] at hk
        rcases hk with ⟨⟨k', v'⟩, ⟨hk₁, hk₂⟩⟩
        rw [mem_bind] at hk₁
        obtain ⟨b, ⟨hb₁, hb₂⟩⟩ := hk₁
        obtain ⟨⟨j, hj'⟩, hj⟩ := get_of_mem hb₁
        have : l₁.length + (j + 1) < self.val.size := by
          rw [Array.size_eq_length_data, h₁]
          simp
          omega
        have hh := h.hash_self (l₁.length + (j + 1)) this k
        suffices containsKey k self.val[l₁.length + (j + 1)].toDList = true by
          rw [hh this, h₂]
          omega
        rw [containsKey_eq_true_iff_exists_mem]
        refine ⟨⟨k', v'⟩, ?_, hk₂⟩
        suffices b = self.val[l₁.length + (j + 1)] by simpa [this] using hb₂
        -- rw [← hj]
        rw [Array.getElem_eq_data_get]
        rw [← List.getElem_eq_get]
        simp only [h₁]
        rw [List.getElem_eq_get]
        have haux : ¬l₁.length + (j + 1) < l₁.length := by omega
        have haux₂ : l₁.length + (j + 1) - l₁.length < (self.val[i] :: l₂).length := by
          simp
          omega
        rw [List.get_append_right (h'' := haux₂) (h := haux)]
        have : l₁.length + (j + 1) - l₁.length = j + 1 := by omega
        simp only [this]
        rw [List.get_cons_succ, hj]

theorem bucket_toDList_perm [BEq α] [Hashable α]
    (self : Buckets α β) (i : USize) (hi : i.toNat < self.1.size) :
      ∃ l, self.toDList ~ self.1[i].toDList ++ l ∧
        (∀ [EquivBEq α], self.WF → ∀ k, l.containsKey k → ((hash k).toUSize % self.1.size).toNat ≠ i.toNat) := by
  obtain ⟨l, hl, -, hlk⟩ := bucket_toDList_perm_update self i hi .nil
  exact ⟨l, hl, hlk⟩

@[simp]
theorem mk_toDList [BEq α] [Hashable α] (h) : (Buckets.mk n h : Buckets α β).toDList = [] := by
  simp only [mk, toDList_eq', mkArray_data]
  clear h
  induction n <;> simp_all

theorem WF.mk' [BEq α] [Hashable α] (h) : (Buckets.mk n h : Buckets α β).WF :=
  ⟨by simp, by simp⟩

end Buckets

namespace HashMap.Imp

-- Okay, this is the proof we will go for!
theorem contains_eq_containsKey_toDList₃ [BEq α] [Hashable α] [EquivBEq α] (m : HashMap.Imp α β)
    (h : m.buckets.WF) (k : α) :
    m.contains k = m.buckets.toDList.containsKey k := by
  rw [contains]
  dsimp
  let idx := mkIdx m.buckets.2 (hash k).toUSize
  obtain ⟨l, hl, hlk⟩ := Buckets.bucket_toDList_perm m.buckets idx.1 idx.2
  refine Eq.trans ?_ (List.containsKey_of_perm ?_ hl.symm)
  · rw [AssocList.contains_eq_contains_toDList, List.containsKey_append_of_not_contains_right]
    · simp [idx]
    · rw [Bool.eq_false_iff]
      intro hlk'
      have := hlk h k hlk'
      simp [idx, mkIdx] at this
  · exact List.WF_of_perm hl.symm h.1

end HashMap.Imp

open List

@[simp]
theorem reinsertAux_toDList [BEq α] [Hashable α] (data : Buckets α β) (a : α) (b : β) :
    (reinsertAux data a b).toDList ~ ⟨a, b⟩ :: data.toDList := by
  rw [reinsertAux]
  dsimp
  let idx := mkIdx data.2 (hash a).toUSize
  obtain ⟨l, hl₁, hl₂, -⟩ := Buckets.bucket_toDList_perm_update data idx.1 idx.2
    (data.1[idx.1].cons a b)
  refine hl₂.trans ?_
  simpa using hl₁.symm

theorem expand.foldl_toDList [BEq α] [Hashable α] (l : AssocList α β) (target : Buckets α β) :
    (l.foldl reinsertAux target).toDList ~ l.toDList ++ target.toDList := by
  induction l generalizing target
  · simp
  · next k v t ih =>
    skip
    have := ih (reinsertAux target k v)
    simp at this
    simp
    refine this.trans ?_
    refine ((reinsertAux_toDList target k v).append_left t.toDList).trans ?_
    simp


theorem expand.go_pos [Hashable α] {i : Nat} {source : Array (AssocList α β)} {target : Buckets α β}
    (h : i < source.size) : expand.go i source target =
      go (i + 1) (source.set ⟨i, h⟩ .nil) ((source.get ⟨i, h⟩).foldl reinsertAux target) := by
  rw [expand.go]
  simp only [h, dite_true]

theorem expand.go_neg [Hashable α] {i : Nat} {source : Array (AssocList α β)} {target : Buckets α β}
    (h : ¬i < source.size) : expand.go i source target = target := by
  rw [expand.go]
  simp only [h, dite_false]


theorem List.append_swap_perm (l l' : List α) : l ++ l' ~ l' ++ l := by exact perm_append_comm

theorem expand_toDList [BEq α] [Hashable α] {buckets : Buckets α β} :
    (expand sz buckets).buckets.toDList ~ buckets.toDList := by
  rw [expand]
  dsimp
  refine (go _ _ _).trans ?_
  simp
  rw [Buckets.toDList_eq']
  where
    go (i) (source : Array (AssocList α β)) (target : Buckets α β) :
        (expand.go i source target).toDList ~ (source.data.drop i).bind AssocList.toDList ++ target.toDList := by
      induction i, source, target using expand.go.induct
      · next i source target hi _ es newSource newTarget ih =>
        skip
        simp only [newSource, newTarget, es] at *
        rw [expand.go_pos hi]
        refine ih.trans ?_
        rw [Array.size_eq_length_data] at hi
        rw [List.drop_eq_get_cons hi, List.cons_bind, Array.data_set, List.drop_set_of_lt _ _ (Nat.lt_succ_self i),
          Array.get_eq_getElem, Array.getElem_eq_data_get]
        refine ((expand.foldl_toDList _ _).append_left _).trans ?_
        simp
        exact Buckets.List.perm_append_comm_assoc _ _ _
      · next i source target hi =>
        rw [expand.go_neg hi]
        rw [Array.size_eq_length_data, Nat.not_lt, ← List.drop_eq_nil_iff_le] at hi
        simp [hi]

theorem insert_toDList [BEq α] [Hashable α] {m : HashMap.Imp α β} (h : m.WF) :
    (m.insert k v).buckets.toDList ~ m.buckets.toDList.insertEntry k v := by
  rw [insert]
  dsimp
  let idx := mkIdx m.buckets.2 (hash k).toUSize
  rw [cond_eq_if]
  split
  · next h =>
    skip
    dsimp
    obtain ⟨l, hl₁, hl₂, hlk⟩ := Buckets.bucket_toDList_perm_update m.buckets idx.1 idx.2
      (m.buckets.1[idx.1].replace k v)
    refine hl₂.trans ?_
    sorry
  · next h =>
    skip
    sorry

@[simp] theorem reinsertAux_size' [Hashable α] (data : Buckets α β) (a : α) (b : β) :
    (reinsertAux data a b).1.size = data.1.size := by
  simp [reinsertAux]

theorem reinsertAux_size [Hashable α] (data : Buckets α β) (a : α) (b : β) :
    (reinsertAux data a b).size = data.size + 1 := by
  simp [Buckets.size_eq, reinsertAux]
  refine have ⟨l₁, l₂, h₁, _, eq⟩ := Buckets.exists_of_update ..; eq ▸ ?_
  simp [h₁, Nat.succ_add]; rfl

theorem expand_size'.foldl [Hashable α] (l : AssocList α β) (target : Buckets α β) :
    (l.foldl reinsertAux target).1.size = target.1.size := by
  induction l generalizing target <;> simp_all

theorem expand_size.foldl [Hashable α] {l : AssocList α β} (target : Buckets α β)
    (ht : 0 < target.1.size) :
    (l.foldl reinsertAux target).size = target.size + l.toList.length := by
  induction l generalizing target
  · simp
  · next k v t ih =>
    simp only [AssocList.foldl_eq, AssocList.toList, List.foldl_cons, List.length_cons,
      Nat.succ_eq_add_one]
    have := ih (reinsertAux target k v)
    simp only [Array.data_length, reinsertAux_size', AssocList.foldl_eq] at this
    rw [this ht, reinsertAux_size, Nat.add_assoc, Nat.add_comm 1]

-- TODO: this proof is still quite long, how can it be simplified?
-- Does this just go away once we know how toLi st works?
theorem expand_size [Hashable α] {buckets : Buckets α β} (hd : 0 < buckets.1.size) :
    (expand sz buckets).buckets.size = buckets.size := by
  rw [expand, go]
  · rw [Buckets.mk_size, Buckets.size, Nat.add_zero, List.drop_zero]
  · rw [Buckets.mk_size']
    exact Nat.mul_pos hd (by decide)
  where
    go (i source) (target : Buckets α β) (ht : 0 < target.1.size) :
        (expand.go i source target).size =
          .sum ((source.data.drop i).map (·.toList.length)) + target.size := by
      induction i, source, target using expand.go.induct
      · next i source target hi _ es newSource newTarget ih =>
        simp only [newSource, newTarget, es] at *
        rw [expand.go_pos]
        refine (ih ?_).trans ?_
        · simpa only [newTarget, expand_size'.foldl]
        · rw [Array.size_eq_length_data] at hi
          rw [List.drop_eq_get_cons hi, List.map_cons, Nat.sum_cons, Array.data_set,
            List.drop_set_of_lt _ _ (Nat.lt_succ_self i), expand_size.foldl _ ht,
            Array.get_eq_getElem, Array.getElem_eq_data_get]
          simp only [Nat.add_comm, ← Nat.add_assoc]
      · next i source target hi =>
        rw [expand.go_neg hi]
        rw [Array.size_eq_length_data, Nat.not_lt, ← List.drop_eq_nil_iff_le] at hi
        simp [hi]

theorem reinsertAux_WF [BEq α] [Hashable α] {data : Buckets α β} {a : α} {b : β} (H : data.WF)
    (h₁ : ∀ [PartialEquivBEq α] [LawfulHashable α],
      haveI := mkIdx data.2 (hash a).toUSize
      data.val[this.1].contains a = false) :
    (reinsertAux data a b).WF :=
  H.update (fun h => h.cons h₁ rfl)

theorem expand_WF.foldl [BEq α] [Hashable α] (rank : α → Nat) {l : List (α × β)} {i : Nat}
    (hl₁ : ∀ [PartialEquivBEq α] [LawfulHashable α], l.Pairwise fun a b => ¬(a.1 == b.1))
    (hl₂ : ∀ x ∈ l, rank x.1 = i)
    {target : Buckets α β} (ht₁ : target.WF)
    (ht₂ : ∀ bucket ∈ target.1.data,
      bucket.All fun k _ => rank k ≤ i ∧
        ∀ [PartialEquivBEq α] [LawfulHashable α], ∀ x ∈ l, ¬(x.1 == k)) :
    (l.foldl (fun d x => reinsertAux d x.1 x.2) target).WF ∧
    ∀ bucket ∈ (l.foldl (fun d x => reinsertAux d x.1 x.2) target).1.data,
      bucket.All fun k _ => rank k ≤ i := by
  induction l generalizing target with
  | nil => exact ⟨ht₁, fun _ h₁ _ h₂ => (ht₂ _ h₁ _ h₂).1⟩
  | cons _ _ ih =>
    simp only [List.pairwise_cons, List.mem_cons, forall_eq_or_imp] at hl₁ hl₂ ht₂
    refine ih hl₁.2 hl₂.2
      (reinsertAux_WF ht₁ fun _ h => (ht₂ _ (Array.getElem_mem_data ..) _ h).2.1)
      (fun _ h => ?_)
    simp [reinsertAux, Buckets.update] at h
    match List.mem_or_eq_of_mem_set h with
    | .inl h =>
      intro _ hf
      have ⟨h₁, h₂⟩ := ht₂ _ h _ hf
      exact ⟨h₁, h₂.2⟩
    | .inr h => subst h; intro
      | _, .head .. =>
        exact ⟨hl₂.1 ▸ Nat.le_refl _, fun _ h h' => hl₁.1 _ h (PartialEquivBEq.symm h')⟩
      | _, .tail _ h =>
        have ⟨h₁, h₂⟩ := ht₂ _ (Array.getElem_mem_data ..) _ h
        exact ⟨h₁, h₂.2⟩

theorem expand_WF [BEq α] [Hashable α] {buckets : Buckets α β} (H : buckets.WF) :
    (expand sz buckets).buckets.WF :=
  go _ H.1 H.2 ⟨.mk' _, fun _ _ _ _ => by simp_all [Buckets.mk, List.mem_replicate]⟩
where
  go (i) {source : Array (AssocList α β)}
      (hs₁ : ∀ [LawfulHashable α] [PartialEquivBEq α], ∀ bucket ∈ source.data,
        bucket.toList.Pairwise fun a b => ¬(a.1 == b.1))
      (hs₂ : ∀ (j : Nat) (h : j < source.size),
        source[j].All fun k _ => ((hash k).toUSize % source.size).toNat = j)
      {target : Buckets α β} (ht : target.WF ∧ ∀ bucket ∈ target.1.data,
        bucket.All fun k _ => ((hash k).toUSize % source.size).toNat < i) :
      (expand.go i source target).WF := by
    unfold expand.go; split
    · next H =>
      refine go (i+1) (fun _ hl => ?_) (fun i h => ?_) ?_
      · match List.mem_or_eq_of_mem_set hl with
        | .inl hl => exact hs₁ _ hl
        | .inr e => exact e ▸ .nil
      · simp [Array.getElem_eq_data_get, List.get_set]; split
        · nofun
        · exact hs₂ _ (by simp_all)
      · let rank (k : α) := ((hash k).toUSize % source.size).toNat
        have := expand_WF.foldl rank ?_ (hs₂ _ H) ht.1 (fun _ h₁ _ h₂ => ?_)
        · simp only [Array.get_eq_getElem, AssocList.foldl_eq, Array.size_set]
          exact ⟨this.1, fun _ h₁ _ h₂ => Nat.lt_succ_of_le (this.2 _ h₁ _ h₂)⟩
        · exact hs₁ _ (Array.getElem_mem_data ..)
        · have := ht.2 _ h₁ _ h₂
          refine ⟨Nat.le_of_lt this, fun _ h h' => Nat.ne_of_lt this ?_⟩
          exact LawfulHashable.hash_eq h' ▸ hs₂ _ H _ h
    · exact ht.1
  termination_by source.size - i

theorem insert_size [BEq α] [Hashable α] {m : Imp α β} {k v}
    (h : m.size = m.buckets.size) :
    (insert m k v).size = (insert m k v).buckets.size := by
  dsimp [insert, cond]; split
  · unfold Buckets.size
    refine have ⟨_, _, h₁, _, eq⟩ := Buckets.exists_of_update ..; eq ▸ ?_
    simp [h, h₁, Buckets.size_eq]
  split
  · unfold Buckets.size
    refine have ⟨_, _, h₁, _, eq⟩ := Buckets.exists_of_update ..; eq ▸ ?_
    simp [h, h₁, Buckets.size_eq, Nat.succ_add]; rfl
  · rw [expand_size]; simp [h, expand, Buckets.size]
    refine have ⟨_, _, h₁, _, eq⟩ := Buckets.exists_of_update ..; eq ▸ ?_
    simp [h₁, Buckets.size_eq, Nat.succ_add]; rfl

private theorem mem_replaceF {l : List (α × β)} {x : α × β} {p : α × β → Bool} {f : α × β → β} :
    x ∈ (l.replaceF fun a => bif p a then some (k, f a) else none) → x.1 = k ∨ x ∈ l := by
  induction l with
  | nil => exact .inr
  | cons a l ih =>
    simp; generalize e : cond .. = z; revert e
    unfold cond; split <;> (intro h; subst h; simp)
    · intro
      | .inl eq => exact eq ▸ .inl rfl
      | .inr h => exact .inr (.inr h)
    · intro
      | .inl eq => exact .inr (.inl eq)
      | .inr h => exact (ih h).imp_right .inr

private theorem pairwise_replaceF [BEq α] [PartialEquivBEq α]
    {l : List (α × β)} {f : α × β → β}
    (H : l.Pairwise fun a b => ¬(a.fst == b.fst)) :
    (l.replaceF fun a => bif a.fst == k then some (k, f a) else none)
      |>.Pairwise fun a b => ¬(a.fst == b.fst) := by
  induction l with
  | nil => simp [H]
  | cons a l ih =>
    simp at H ⊢
    generalize e : cond .. = z; unfold cond at e; revert e
    split <;> (intro h; subst h; simp)
    · next e => exact ⟨(H.1 · · ∘ PartialEquivBEq.trans e), H.2⟩
    · next e =>
      refine ⟨fun a h => ?_, ih H.2⟩
      match mem_replaceF h with
      | .inl eq => exact eq ▸ ne_true_of_eq_false e
      | .inr h => exact H.1 a h

theorem insert_WF [BEq α] [Hashable α] {m : Imp α β} {k v}
    (h : m.buckets.WF) : (insert m k v).buckets.WF := by
  dsimp [insert, cond]; split
  · next h₁ =>
    simp at h₁; have ⟨x, hx₁, hx₂⟩ := h₁
    refine h.update (fun H => ?_) (fun H a h => ?_)
    · simp; exact pairwise_replaceF H
    · simp [AssocList.All] at H h ⊢
      match mem_replaceF h with
      | .inl rfl => rfl
      | .inr h => exact H _ h
  · next h₁ =>
    rw [Bool.eq_false_iff] at h₁; simp at h₁
    suffices _ by split <;> [exact this; refine expand_WF this]
    refine h.update (.cons ?_) (fun H a h => ?_)
    · exact fun a h h' => h₁ a h (PartialEquivBEq.symm h')
    · cases h with
      | head => rfl
      | tail _ h => exact H _ h

theorem erase_size [BEq α] [Hashable α] {m : Imp α β} {k}
    (h : m.size = m.buckets.size) :
    (erase m k).size = (erase m k).buckets.size := by
  dsimp [erase, cond]; split
  · next H =>
    simp [h, Buckets.size]
    refine have ⟨_, _, h₁, _, eq⟩ := Buckets.exists_of_update ..; eq ▸ ?_
    simp [h, h₁, Buckets.size_eq]
    rw [(_ : List.length _ = _ + 1), Nat.add_right_comm]; {rfl}
    clear h₁ eq
    simp [AssocList.contains_eq] at H
    have ⟨a, h₁, h₂⟩ := H
    refine have ⟨_, _, _, _, _, h, eq⟩ := List.exists_of_eraseP h₁ h₂; eq ▸ ?_
    simp [h]; rfl
  · exact h

theorem erase_WF [BEq α] [Hashable α] {m : Imp α β} {k}
    (h : m.buckets.WF) : (erase m k).buckets.WF := by
  dsimp [erase, cond]; split
  · refine h.update (fun H => ?_) (fun H a h => ?_) <;> simp at h ⊢
    · exact H.sublist (List.eraseP_sublist _)
    · exact H _ (List.mem_of_mem_eraseP h)
  · exact h

theorem modify_size [BEq α] [Hashable α] {m : Imp α β} {k}
    (h : m.size = m.buckets.size) :
    (modify m k f).size = (modify m k f).buckets.size := by
  dsimp [modify, cond]; rw [Buckets.update_update]
  simp [h, Buckets.size]
  refine have ⟨_, _, h₁, _, eq⟩ := Buckets.exists_of_update ..; eq ▸ ?_
  simp [h, h₁, Buckets.size_eq]

theorem modify_WF [BEq α] [Hashable α] {m : Imp α β} {k}
    (h : m.buckets.WF) : (modify m k f).buckets.WF := by
  dsimp [modify, cond]; rw [Buckets.update_update]
  refine h.update (fun H => ?_) (fun H a h => ?_) <;> simp at h ⊢
  · exact pairwise_replaceF H
  · simp [AssocList.All] at H h ⊢
    match mem_replaceF h with
    | .inl rfl => rfl
    | .inr h => exact H _ h

theorem WF.out [BEq α] [Hashable α] {m : Imp α β} (h : m.WF) :
    m.size = m.buckets.size ∧ m.buckets.WF := by
  induction h with
  | mk h₁ h₂ => exact ⟨h₁, h₂⟩
  | @empty' _ h => exact ⟨(Buckets.mk_size h).symm, .mk' h⟩
  | insert _ ih => exact ⟨insert_size ih.1, insert_WF ih.2⟩
  | erase _ ih => exact ⟨erase_size ih.1, erase_WF ih.2⟩
  | modify _ ih => exact ⟨modify_size ih.1, modify_WF ih.2⟩

theorem WF_iff [BEq α] [Hashable α] {m : Imp α β} :
    m.WF ↔ m.size = m.buckets.size ∧ m.buckets.WF :=
  ⟨(·.out), fun ⟨h₁, h₂⟩ => .mk h₁ h₂⟩

theorem WF.mapVal {α β γ} {f : α → β → γ} [BEq α] [Hashable α]
    {m : Imp α β} (H : WF m) : WF (mapVal f m) := by
  have ⟨h₁, h₂⟩ := H.out
  simp [Imp.mapVal, Buckets.mapVal, WF_iff, h₁]; refine ⟨?_, ?_, fun i h => ?_⟩
  · simp [Buckets.size]; congr; funext l; simp
  · simp only [Array.map_data, List.forall_mem_map_iff]
    simp only [AssocList.toList_mapVal, List.pairwise_map]
    exact fun _ => h₂.1 _
  · simp [AssocList.All] at h ⊢
    intro a m
    apply h₂.2 _ _ _ m

theorem WF.filterMap {α β γ} {f : α → β → Option γ} [BEq α] [Hashable α]
    {m : Imp α β} (H : WF m) : WF (filterMap f m) := by
  let g₁ (l : AssocList α β) := l.toList.filterMap (fun x => (f x.1 x.2).map (x.1, ·))
  have H1 (l n acc) : filterMap.go f acc l n =
      (((g₁ l).reverse ++ acc.toList).toAssocList, ⟨n.1 + (g₁ l).length⟩) := by
    induction l generalizing n acc with simp [filterMap.go, g₁, *]
    | cons a b l => match f a b with
      | none => rfl
      | some c => simp; rw [Nat.add_right_comm]; rfl
  let g l := (g₁ l).reverse.toAssocList
  let M := StateT (ULift Nat) Id
  have H2 (l : List (AssocList α β)) n :
      l.mapM (m := M) (filterMap.go f .nil) n =
      (l.map g, ⟨n.1 + .sum ((l.map g).map (·.toList.length))⟩) := by
    induction l generalizing n with
    | nil => rfl
    | cons l L IH => simp [bind, StateT.bind, IH, H1, Nat.add_assoc, g]; rfl
  have H3 (l : List _) :
    (l.filterMap (fun (a, b) => (f a b).map (a, ·))).map (fun a => a.fst)
     |>.Sublist (l.map (·.1)) := by
    induction l with
    | nil => exact .slnil
    | cons a l ih =>
      simp; exact match f a.1 a.2 with
      | none => .cons _ ih
      | some b => .cons₂ _ ih
  suffices ∀ bk sz (h : 0 < bk.length),
    m.buckets.val.mapM (m := M) (filterMap.go f .nil) ⟨0⟩ = (⟨bk⟩, ⟨sz⟩) →
    WF ⟨sz, ⟨bk⟩, h⟩ from this _ _ _ rfl
  simp [Array.mapM_eq_mapM_data, bind, StateT.bind, H2, g]
  intro bk sz h e'; cases e'
  refine .mk (by simp [Buckets.size]) ⟨?_, fun i h => ?_⟩
  · simp only [List.forall_mem_map_iff, List.toList_toAssocList]
    refine fun l h => (List.pairwise_reverse.2 ?_).imp (mt PartialEquivBEq.symm)
    have := H.out.2.1 _ h
    rw [← List.pairwise_map (R := (¬ · == ·))] at this ⊢
    exact this.sublist (H3 l.toList)
  · simp only [Array.size_mk, List.length_map, Array.data_length, Array.getElem_eq_data_get,
      List.get_map] at h ⊢
    have := H.out.2.2 _ h
    simp [AssocList.All, g₁] at this ⊢
    rintro _ _ h' _ _ rfl
    exact this _ h'

end Imp

variable {_ : BEq α} {_ : Hashable α}

/-- Map a function over the values in the map. -/
@[inline] def mapVal (f : α → β → γ) (self : HashMap α β) : HashMap α γ :=
  ⟨self.1.mapVal f, self.2.mapVal⟩

/--
Applies `f` to each key-value pair `a, b` in the map. If it returns `some c` then
`a, c` is pushed into the new map; else the key is removed from the map.
-/
@[inline] def filterMap (f : α → β → Option γ) (self : HashMap α β) : HashMap α γ :=
  ⟨self.1.filterMap f, self.2.filterMap⟩

/-- Constructs a map with the set of all pairs `a, b` such that `f` returns true. -/
@[inline] def filter (f : α → β → Bool) (self : HashMap α β) : HashMap α β :=
  self.filterMap fun a b => bif f a b then some b else none
