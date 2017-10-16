{-# LANGUAGE TypeFamilies, DataKinds, KindSignatures, TypeOperators,
     UndecidableInstances, PolyKinds #-}
module GenericContext where

import Generics.SOP (Proxy)

-- ------------------------------------------- Type arithmetic
type family (.++) (xs :: [[*]]) (ys :: [[*]]) :: [[*]] where
    (x ': xs) .++ ys = x ': (xs .++ ys)
    '[]       .++ ys = ys

type family (.*) (x :: *) (ys :: [[*]]) :: [[*]] where
    x .* (ys ': yss) = (x ': ys) ': (x .* yss)
    x .* '[]         = '[]

type family (.**) (xs :: [*]) (ys :: [[*]]) :: [[*]] where
    (x ': xs) .** yss = x .* (xs .** yss)
    '[]       .** yss = yss

infixr 6 .++
infixr 7 .*
infixr 7 .**
-- -------------------------------------------

data ConsNum = F         -- First
             | N ConsNum -- Next
             | None
    deriving Eq

type family In (a :: k) (fam :: [k]) :: Bool where
    In a (a ': fam) = 'True
    In a (x ': fam) = In a fam
    In a '[]        = 'False

type family If (c :: Bool) (t :: k) (e :: k) where
    If 'True  t e = t
    If 'False t e = e

type family ToContext (n :: ConsNum) (fam :: [*]) (code :: [[*]]) :: [[*]] where
    ToContext n fam '[] = '[]
    ToContext n fam (xs ': xss)
        = Proxy n .* DiffProd fam xs .++ ToContext ('N n) fam xss

data Hole = Hole
data End

type family DiffProd (fam :: [*]) (xs :: [*]) :: [[*]] where
    DiffProd fam '[]       = '[]
    DiffProd fam '[x]      = If (In x fam) '[ '[Hole]] '[]
    DiffProd fam '[End, x] = If (In x fam) '[ '[]]     '[]
    DiffProd fam (x ': xs)
        = Hole .* xs .** DiffProd fam '[End, x] .++ x .* DiffProd fam xs
