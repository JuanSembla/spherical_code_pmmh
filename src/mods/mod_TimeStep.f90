! spherical_code_pmmh: solve the Boussinesq equations in a rotating spherical shell
! Copyright (C) 2025 Alan Riquier, Camille Rambert, Juan Cruz Gonzalez Sembla and Laurette Tuckerman

! Contact: juan-cruz.gonzalez-sembla@espci.fr, laurette.tuckerman@espci.fr

! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 2 of the License, or
! (at your option) any later version.

! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.

! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

! This module was written by A. Riquier, C. Rambert and J. C. Gonzalez Sembla.
! It contains the subroutines that perform the timestep. Subroutines:
! - compute_time_step_convective_explicit_PC: PC timestep using explicit Coriolis.
! - compute_time_step_convective_implicit_PC: PC timestep using implicit Coriolis.
! - compute_time_step_convective_explicit_CN_FBE: CN or FBE timestep using explicit Coriolis.
! - compute_time_step_convective_explicit_BDF2: BDF2 timestep using explicit Coriolis.
! - compute_time_step_convective_implicit_CN: CN timestep using implicit Coriolis.
! - compute_time_step_convective_implicit_FBE: FBE timestep using implicit Coriolis.
! - compute_time_step_convective_implicit_BDF2: BDF2 timestep using implicit Coriolis.
! - compute_lin_time_step_convective_explicit_CN_FBE: CN or FBD linearized timestep using explicit Coriolis.
! - compute_lin_time_step_convective_implicit_CN: CN linearized timestep using implicit Coriolis.
! - compute_lin_time_step_convective_implicit_FBE: FBD linearized timestep using explicit Coriolis.

module mod_TimeStep
  !$ USE OMP_LIB
  use mod_Globalvars
  use mod_Matrices
  use mod_PrecompXY
  use mod_ExplicitTerms

  implicit none


contains
  
subroutine compute_time_step_convective_explicit_PC()

  implicit none

  integer :: lm, k

  !--- Compute Explicit terms for the predictor Step
  call comp_ExplicitRHS(DE, DF, DT)

  !--- Predictor Step for E, F and T

  !--- For E
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k = 1, KK2
      wE(k, lm)%re = Xe_invYe(:, k, ell(lm)) .dot. real(E(:, lm))
      wDE(k, lm)%re = Xe_inv(:, k, ell(lm)) .dot. real(DE(:, lm))
      wE(k, lm)%im = Xe_invYe(:, k, ell(lm)) .dot. aimag(E(:, lm))
      wDE(k, lm)%im = Xe_inv(:, k, ell(lm)) .dot. aimag(DE(:, lm))
    end do
  end do

  !--- For F
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k=1, KK4
      wF(k, lm)%re = Xf_invYf(:, k, ell(lm)) .dot. real(F(:, lm))
      wDF(k, lm)%re = Xf_inv(:, k, ell(lm)) .dot. real(DF(:, lm))
      wF(k, lm)%im = Xf_invYf(:, k, ell(lm)) .dot. aimag(F(:, lm))
      wDF(k, lm)%im = Xf_inv(:, k, ell(lm)) .dot. aimag(DF(:, lm))
    end do
  end do

  !--- For the T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- Predictor values of E, F and T. These are the \tilde{e}^{n+1}, \tilde{f}^{n+1} and \tilde{T}^{n+1}.
  E = wE + wDE
  F = wF + wDF
  T = wT + wDT

  !--- Compute Explicit terms for the Corrector Step with the tildes{}^{n+1}
  call comp_ExplicitRHS(DEp, DFp, DTp)

  DE = (DE + DEp) / 2.
  DF = (DF + DFp) / 2.
  DT = (DT + DTp) / 2.

  !--- Corrector Step for E, F and T

  !--- For E
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k=1, KK2
      wDE(k, lm)%re = Xe_inv(:, k, ell(lm)) .dot. real(DE(:, lm))
      wDE(k, lm)%im = Xe_inv(:, k, ell(lm)) .dot. aimag(DE(:, lm))
    end do
  end do

  !--- For F
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k = 1, KK4
      wDF(k, lm)%re = Xf_inv(:, k, ell(lm)) .dot. real(DF(:, lm))
      wDF(k, lm)%im = Xf_inv(:, k, ell(lm)) .dot. aimag(DF(:, lm))
    end do
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- Corrector values of E, F and T
  E = wE + wDE
  F = wF + wDF
  T = wT + wDT

end subroutine compute_time_step_convective_explicit_PC

!--------------------------------------------------------------------------------------

subroutine compute_time_step_convective_implicit_PC()

  implicit none

  integer :: lm, k, m, n_even, n_odd, top, stride

  !--- Compute Explicit terms for the predictor Step
  call comp_ImplicitRHS(DE, DF, DT)

  DEr = (0., 0.)
  DFr = (0., 0.)

  ! Now we go to real in Chebyshev for DE and DF
  do lm=2, shtns%nlm ! We start from lm = 2 because lm = 1 is of no interest
    do k = 1, KK2
      DEr(k, lm)%re = Chb2(k, :KK2) .dot. real(DE(:KK2, lm))
      DEr(k, lm)%im = Chb2(k, :KK2) .dot. aimag(DE(:KK2, lm))
    end do
  end do

  do lm=2, shtns%nlm
    do k = 1, KK4
      DFr(k, lm)%re = Chb4(k, :KK4) .dot. real(DF(:KK4, lm))
      DFr(k, lm)%im = Chb4(k, :KK4) .dot. aimag(DF(:KK4, lm))
    end do
  end do

  ! Create arrays that respect the symmetry classes
  call small2big(E, F, A)
  call small2big(DEr, DFr, DA)

  !--- Predictor Step for E, F and T

  !--- For E and F
  stride = 1
  Ap = 0.

  do m = 0, MM*mres, mres
    DA1 = 0.
    A1 = 0.
    n_even = ((LL + mod(LL, 2)) - max(m, 1)) / 2 + mod(LL + 1, 2)
    n_odd = ((LL + mod(LL, 2)) + 1 - m) / 2
    top = 2 * (KK2 + KK4) * (n_even + n_odd)

    DA1 = Banded_Mult(top, 2*(KK2 + KK4) - 1, Yef(:, stride), 4*(KK2 + KK4) - 1, A(stride, 1), DA(stride, 1))
    A1 = Banded_LU_solve(top, 2 * (KK2 + KK4) - 1, Xef(:, stride), 6 * (KK2 + KK4) - 2, DA1, PIVOT(stride))
    Ap(stride : stride + top - 1, 1) = A1(:top, 1)
    stride = stride + 2 * (KK2 + KK4) * (LL - (max(m, 1) - 1))
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- Predictor values of E, F and Temerature. These are the \tilde{e}^{n+1}, \tilde{f}^{n+1} and \tilde{T}^{n+1}.
  call big2small(Ap, E, F)
  T = wT + wDT

  !--- Compute Explicit terms for the Corrector Step with the tildes{}^{n+1}
  call comp_ImplicitRHS(DEp, DFp, DTp)

  DEpr = (0., 0.)
  DFpr = (0., 0.)

  ! Now we go to real in Chebyshev for DEp and DFp
  do lm=2, shtns%nlm
    do k = 1, KK2
      DEpr(k, lm)%re = Chb2(k, :KK2) .dot. real(DEp(:KK2, lm))
      DEpr(k, lm)%im = Chb2(k, :KK2) .dot. aimag(DEp(:KK2, lm))
    end do
  end do

  do lm=2, shtns%nlm
    do k = 1, KK4
      DFpr(k, lm)%re = Chb4(k, :KK4) .dot. real(DFp(:KK4, lm))
      DFpr(k, lm)%im = Chb4(k, :KK4) .dot. aimag(DFp(:KK4, lm))
    end do
  end do

  DEr = (DEr + DEpr) / 2.
  DFr = (DFr + DFpr) / 2.
  DT = (DT + DTp) / 2.

  call small2big(DEr, DFr, DA)

  !--- Corrector Step for E, F and T

  !--- For E and F
  stride = 1

  do m = 0, MM*mres, mres
    DA1 = 0.
    A1 = 0.
    n_even = ((LL + mod(LL, 2)) - max(m, 1)) / 2 + mod(LL + 1, 2)
    n_odd = ((LL + mod(LL, 2)) + 1 - m) / 2
    top = 2 * (KK2 + KK4) * (n_even + n_odd)

    DA1 = Banded_Mult(top, 2*(KK2 + KK4) - 1, Yef(:, stride), 4*(KK2 + KK4) -1, A(stride, 1), DA(stride, 1))
    A1 = Banded_LU_solve(top, 2 * (KK2 + KK4) - 1, Xef(:, stride), 6 * (KK2 + KK4) - 2, DA1, PIVOT(stride))
    A(stride : stride + top - 1, 1) = A1(:top, 1)
    stride = stride + 2 * (KK2 + KK4) * (LL - (max(m, 1) - 1))
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- Corrector values of E, F and T
  call big2small(A, E, F)
  T = wT + wDT

end subroutine compute_time_step_convective_implicit_PC

! --------------------------------------------------------------------------------------

subroutine compute_time_step_convective_explicit_CN_FBE()

  implicit none

  integer :: lm, k

  !--- Compute Explicit terms
  call Explicit_RHS_ptr(DE, DF, DT)

  !--- Solution of the linear system

  !--- For E
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k = 1, KK2
      wE(k, lm)%re = Xe_invYe(:, k, ell(lm)) .dot. real(E(:, lm))
      wDE(k, lm)%re = Xe_inv(:, k, ell(lm)) .dot. real(DE(:, lm))
      wE(k, lm)%im = Xe_invYe(:, k, ell(lm)) .dot. aimag(E(:, lm))
      wDE(k, lm)%im = Xe_inv(:, k, ell(lm)) .dot. aimag(DE(:, lm))
    end do
  end do

  !--- For F
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k=1, KK4
      wF(k, lm)%re = Xf_invYf(:, k, ell(lm)) .dot. real(F(:, lm))
      wDF(k, lm)%re = Xf_inv(:, k, ell(lm)) .dot. real(DF(:, lm))
      wF(k, lm)%im = Xf_invYf(:, k, ell(lm)) .dot. aimag(F(:, lm))
      wDF(k, lm)%im = Xf_inv(:, k, ell(lm)) .dot. aimag(DF(:, lm))
    end do
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  E = wE + wDE
  F = wF + wDF
  T = wT + wDT

end subroutine compute_time_step_convective_explicit_CN_FBE

!--------------------------------------------------------------------------------------

subroutine compute_time_step_convective_explicit_BDF2()

  implicit none

  integer :: lm, k

  !--- Compute Explicit terms
  call comp_ExplicitRHS(DE, DF, DT)

  !--- Solution of the linear system

  !--- Save states and RHS
  E_tm2 = E_tm1 ; F_tm2 = F_tm1 ; T_tm2 = T_tm1 ;
  E_tm1 = E ; F_tm1 = F ; T_tm1 = T ;
  DE_tm2 = DE_tm1 ; DF_tm2 = DF_tm1 ; DT_tm2 = DT_tm1 ;
  DE_tm1 = DE ; DF_tm1 = DF ; DT_tm1 = DT ;
  
  !--- Perform 4 / 3 * U_t - 1 / 3 * U_tm1
  E = 4. / 3. * E_tm1 - 1. / 3. * E_tm2
  F = 4. / 3. * F_tm1 - 1. / 3. * F_tm2
  T = 4. / 3. * T_tm1 - 1. / 3. * T_tm2

  ! Perform 2 / 3 * (2 * N(U_t) - N(U_tm1))
  ! We need to be carefull with the temperature field because it is the only place where we do not have homogeneous BC's.
  DE = 2. / 3. * (2. * DE_tm1 - DE_tm2)
  DF = 2. / 3. * (2. * DF_tm1 - DF_tm2)
  DT(:KK, :) = 2. / 3. * (2. * DT_tm1(:KK, :) - DT_tm2(:KK, :))

  !--- For E
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k = 1, KK2
      wE(k, lm)%re = Xe_invYe(:, k, ell(lm)) .dot. real(E(:, lm))
      wDE(k, lm)%re = Xe_inv(:, k, ell(lm)) .dot. real(DE(:, lm))
      wE(k, lm)%im = Xe_invYe(:, k, ell(lm)) .dot. aimag(E(:, lm))
      wDE(k, lm)%im = Xe_inv(:, k, ell(lm)) .dot. aimag(DE(:, lm))
    end do
  end do

  !--- For F
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k=1, KK4
      wF(k, lm)%re = Xf_invYf(:, k, ell(lm)) .dot. real(F(:, lm))
      wDF(k, lm)%re = Xf_inv(:, k, ell(lm)) .dot. real(DF(:, lm))
      wF(k, lm)%im = Xf_invYf(:, k, ell(lm)) .dot. aimag(F(:, lm))
      wDF(k, lm)%im = Xf_inv(:, k, ell(lm)) .dot. aimag(DF(:, lm))
    end do
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  E = wE + wDE
  F = wF + wDF
  T = wT + wDT

end subroutine compute_time_step_convective_explicit_BDF2

!--------------------------------------------------------------------------------------

subroutine compute_time_step_convective_implicit_CN()

  implicit none

  integer :: lm, k, m, n_even, n_odd, top, stride

  !--- Compute Explicit terms
  call Implicit_RHS_ptr(DE, DF, DT)

  DEr = (0., 0.)
  DFr = (0., 0.)

  ! Now we go to real in Chebyshev for DE and DF
  do lm=2, shtns%nlm ! We start from lm = 2 because lm = 1 is of no interest
    do k = 1, KK2
      DEr(k, lm)%re = Chb2(k, :KK2) .dot. real(DE(:KK2, lm))
      DEr(k, lm)%im = Chb2(k, :KK2) .dot. aimag(DE(:KK2, lm))
    end do
  end do

  do lm=2, shtns%nlm
    do k = 1, KK4
      DFr(k, lm)%re = Chb4(k, :KK4) .dot. real(DF(:KK4, lm))
      DFr(k, lm)%im = Chb4(k, :KK4) .dot. aimag(DF(:KK4, lm))
    end do
  end do

  ! Create arrays that respect the symmetry classes
  call small2big(E, F, A)
  call small2big(DEr, DFr, DA)

  !--- Solution of the linear system

  !--- For E and F
  stride = 1
  Ap = 0.

  do m = 0, MM*mres, mres
    DA1 = 0.
    A1 = 0.
    n_even = ((LL + mod(LL, 2)) - max(m, 1)) / 2 + mod(LL + 1, 2)
    n_odd = ((LL + mod(LL, 2)) + 1 - m) / 2
    top = 2 * (KK2 + KK4) * (n_even + n_odd)

    DA1 = Banded_Mult(top, 2*(KK2 + KK4) - 1, Yef(:, stride), 4*(KK2 + KK4) - 1, A(stride, 1), DA(stride, 1))
    A1 = Banded_LU_solve(top, 2 * (KK2 + KK4) - 1, Xef(:, stride), 6 * (KK2 + KK4) - 2, DA1, PIVOT(stride))
    Ap(stride : stride + top - 1, 1) = A1(:top, 1)
    stride = stride + 2 * (KK2 + KK4) * (LL - (max(m, 1) - 1))
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  call big2small(Ap, E, F)
  T = wT + wDT

end subroutine compute_time_step_convective_implicit_CN

! --------------------------------------------------------------------------------------

subroutine compute_time_step_convective_implicit_FBE()

  implicit none

  integer :: lm, k, m, n_even, n_odd, top, stride

  !--- Compute Explicit terms
  call Implicit_RHS_ptr(DE, DF, DT)

  DEr = (0., 0.)
  DFr = (0., 0.)

  ! Now we go to real in Chebyshev for DE and DF
  do lm=2, shtns%nlm ! We start from lm = 2 because lm = 1 is of no interest
    do k = 1, KK2
      DEr(k, lm)%re = (Chb2(k, :KK2) .dot. real(DE(:KK2, lm))) + (Ye_mat(k, :, ell(lm)) .dot. real(E(:, lm)))
      DEr(k, lm)%im = (Chb2(k, :KK2) .dot. aimag(DE(:KK2, lm))) + (Ye_mat(k, :, ell(lm)) .dot. aimag(E(:, lm)))
    end do
  end do

  do lm=2, shtns%nlm
    do k = 1, KK4
      DFr(k, lm)%re = (Chb4(k, :KK4) .dot. real(DF(:KK4, lm))) + (Yf_mat(k, :, ell(lm)) .dot. real(F(:, lm)))
      DFr(k, lm)%im = (Chb4(k, :KK4) .dot. aimag(DF(:KK4, lm))) + (Yf_mat(k, :, ell(lm)) .dot. aimag(F(:, lm)))
    end do
  end do

  ! Create arrays that respect the symmetry classes
  call small2big(DEr, DFr, DA)

  !--- Solution of the linear system

  !--- For E and F
  stride = 1
  Ap = 0.

  do m = 0, MM*mres, mres
    DA1 = 0.
    A1 = 0.
    n_even = ((LL + mod(LL, 2)) - max(m, 1)) / 2 + mod(LL + 1, 2)
    n_odd = ((LL + mod(LL, 2)) + 1 - m) / 2
    top = 2 * (KK2 + KK4) * (n_even + n_odd)

    A1 = Banded_LU_solve(top, 2 * (KK2 + KK4) - 1, Xef(:, stride), 6 * (KK2 + KK4) - 2, DA(stride, 1), PIVOT(stride))
    Ap(stride : stride + top - 1, 1) = A1(:top, 1)
    stride = stride + 2 * (KK2 + KK4) * (LL - (max(m, 1) - 1))
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  call big2small(Ap, E, F)
  T = wT + wDT

end subroutine compute_time_step_convective_implicit_FBE

! --------------------------------------------------------------------------------------

subroutine compute_time_step_convective_implicit_BDF2()

  implicit none

  integer :: lm, k, m, n_even, n_odd, top, stride

  !--- Compute Explicit terms
  call comp_ImplicitRHS(DE, DF, DT)

  !--- Save states and RHS
  E_tm2 = E_tm1 ; F_tm2 = F_tm1 ; T_tm2 = T_tm1 ;
  E_tm1 = E ; F_tm1 = F ; T_tm1 = T ;
  DE_tm2 = DE_tm1 ; DF_tm2 = DF_tm1 ; DT_tm2 = DT_tm1 ;
  DE_tm1 = DE ; DF_tm1 = DF ; DT_tm1 = DT ;
  
  !--- Perform 4 / 3 * U_t - 1 / 3 * U_tm1
  E = 4. / 3. * E_tm1 - 1. / 3. * E_tm2
  F = 4. / 3. * F_tm1 - 1. / 3. * F_tm2
  T = 4. / 3. * T_tm1 - 1. / 3. * T_tm2

  ! Perform 2 / 3 * (2 * N(U_t) - N(U_tm1))
  ! We need to be carefull with the temperature field because it is the only place where we do not have homogeneous BC's.
  DE = 2. / 3. * (2. * DE_tm1 - DE_tm2)
  DF = 2. / 3. * (2. * DF_tm1 - DF_tm2)
  DT(:KK, :) = 2. / 3. * (2. * DT_tm1(:KK, :) - DT_tm2(:KK, :))

  DEr = (0., 0.)
  DFr = (0., 0.)

  ! Now we go to real in Chebyshev for DE and DF
  do lm=2, shtns%nlm ! We start from lm = 2 because lm = 1 is of no interest
    do k = 1, KK2
      DEr(k, lm)%re = (Chb2(k, :KK2) .dot. real(DE(:KK2, lm))) + (Ye_mat(k, :, ell(lm)) .dot. real(E(:, lm)))
      DEr(k, lm)%im = (Chb2(k, :KK2) .dot. aimag(DE(:KK2, lm))) + (Ye_mat(k, :, ell(lm)) .dot. aimag(E(:, lm)))
    end do
  end do

  do lm=2, shtns%nlm
    do k = 1, KK4
      DFr(k, lm)%re = (Chb4(k, :KK4) .dot. real(DF(:KK4, lm))) + (Yf_mat(k, :, ell(lm)) .dot. real(F(:, lm)))
      DFr(k, lm)%im = (Chb4(k, :KK4) .dot. aimag(DF(:KK4, lm))) + (Yf_mat(k, :, ell(lm)) .dot. aimag(F(:, lm)))
    end do
  end do

  ! Create arrays that respect the symmetry classes
  call small2big(DEr, DFr, DA)

  !--- Solution of the linear system

  !--- For E and F
  stride = 1
  Ap = 0.

  do m = 0, MM*mres, mres
    DA1 = 0.
    A1 = 0.
    n_even = ((LL + mod(LL, 2)) - max(m, 1)) / 2 + mod(LL + 1, 2)
    n_odd = ((LL + mod(LL, 2)) + 1 - m) / 2
    top = 2 * (KK2 + KK4) * (n_even + n_odd)

    A1 = Banded_LU_solve(top, 2 * (KK2 + KK4) - 1, Xef(:, stride), 6 * (KK2 + KK4) - 2, DA(stride, 1), PIVOT(stride))
    Ap(stride : stride + top - 1, 1) = A1(:top, 1)
    stride = stride + 2 * (KK2 + KK4) * (LL - (max(m, 1) - 1))
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  call big2small(Ap, E, F)
  T = wT + wDT

end subroutine compute_time_step_convective_implicit_BDF2

! --------------------------------------------------------------------------------------

subroutine compute_lin_time_step_convective_explicit_CN_FBE(E_per, F_per, T_per)

  implicit none

  double complex, dimension(KK2, shtns%nlm), intent(inout) :: E_per
  double complex, dimension(KK4, shtns%nlm), intent(inout) :: F_per
  double complex, dimension(KK2, shtns%nlm), intent(inout) :: T_per

  integer :: lm, k

  !--- Compute Explicit terms
  call comp_LinNonLin(E_base, F_base, T_base, E_per, F_per, T_per, DE, DF, DT)

  ! Solution of the linear system

  !--- For E
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k = 1, KK2
      wE(k, lm)%re = Xe_invYe(:, k, ell(lm)) .dot. real(E_per(:, lm))
      wDE(k, lm)%re = Xe_inv(:, k, ell(lm)) .dot. real(DE(:, lm))
      wE(k, lm)%im = Xe_invYe(:, k, ell(lm)) .dot. aimag(E_per(:, lm))
      wDE(k, lm)%im = Xe_inv(:, k, ell(lm)) .dot. aimag(DE(:, lm))
    end do
  end do

  !--- For F
  do lm = 2, shtns%nlm ! We begin from lm = 2 because we do not care about the m=l=0 mode
    do k=1, KK4
      wF(k, lm)%re = Xf_invYf(:, k, ell(lm)) .dot. real(F_per(:, lm))
      wDF(k, lm)%re = Xf_inv(:, k, ell(lm)) .dot. real(DF(:, lm))
      wF(k, lm)%im = Xf_invYf(:, k, ell(lm)) .dot. aimag(F_per(:, lm))
      wDF(k, lm)%im = Xf_inv(:, k, ell(lm)) .dot. aimag(DF(:, lm))
    end do
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T_per(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T_per(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  E_per = wE + wDE
  F_per = wF + wDF
  T_per = wT + wDT

end subroutine compute_lin_time_step_convective_explicit_CN_FBE

! --------------------------------------------------------------------------------------

subroutine compute_lin_time_step_convective_implicit_CN(E_per, F_per, T_per)

  implicit none

  double complex, dimension(KK2, shtns%nlm), intent(inout) :: E_per
  double complex, dimension(KK4, shtns%nlm), intent(inout) :: F_per
  double complex, dimension(KK2, shtns%nlm), intent(inout) :: T_per

  integer :: lm, k, m, n_even, n_odd, top, stride

  !--- Compute Explicit terms
  call comp_LinNonLin(E_base, F_base, T_base, E_per, F_per, T_per, DE, DF, DT)

  DEr = (0., 0.)
  DFr = (0., 0.)

  ! Now we go to real in Chebyshev for DE and DF
  do lm=2, shtns%nlm ! We start from lm = 2 because lm = 1 is of no interest
    do k = 1, KK2
      DEr(k, lm)%re = Chb2(k, :KK2) .dot. real(DE(:KK2, lm))
      DEr(k, lm)%im = Chb2(k, :KK2) .dot. aimag(DE(:KK2, lm))
    end do
  end do

  do lm=2, shtns%nlm
    do k = 1, KK4
      DFr(k, lm)%re = Chb4(k, :KK4) .dot. real(DF(:KK4, lm))
      DFr(k, lm)%im = Chb4(k, :KK4) .dot. aimag(DF(:KK4, lm))
    end do
  end do

  ! Create arrays that respect the symmetry classes
  call small2big(E_per, F_per, A)
  call small2big(DEr, DFr, DA)

  !--- Solution of the linear system

  !--- For E and F
  stride = 1
  Ap = 0.

  do m = 0, MM*mres, mres
    DA1 = 0.
    A1 = 0.
    n_even = ((LL + mod(LL, 2)) - max(m, 1)) / 2 + mod(LL + 1, 2)
    n_odd = ((LL + mod(LL, 2)) + 1 - m) / 2
    top = 2 * (KK2 + KK4) * (n_even + n_odd)

    DA1 = Banded_Mult(top, 2*(KK2 + KK4) - 1, Yef(:, stride), 4*(KK2 + KK4) - 1, A(stride, 1), DA(stride, 1))
    A1 = Banded_LU_solve(top, 2 * (KK2 + KK4) - 1, Xef(:, stride), 6 * (KK2 + KK4) - 2, DA1, PIVOT(stride))
    Ap(stride : stride + top - 1, 1) = A1(:top, 1)
    stride = stride + 2 * (KK2 + KK4) * (LL - (max(m, 1) - 1))
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T_per(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T_per(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  call big2small(Ap, E_per, F_per)
  T_per = wT + wDT

end subroutine compute_lin_time_step_convective_implicit_CN

! --------------------------------------------------------------------------------------

subroutine compute_lin_time_step_convective_implicit_FBE(E_per, F_per, T_per)

  implicit none

  double complex, dimension(KK2, shtns%nlm), intent(inout) :: E_per
  double complex, dimension(KK4, shtns%nlm), intent(inout) :: F_per
  double complex, dimension(KK2, shtns%nlm), intent(inout) :: T_per

  integer :: lm, k, m, n_even, n_odd, top, stride

  !--- Compute Explicit terms
  call comp_LinNonLin(E_base, F_base, T_base, E_per, F_per, T_per, DE, DF, DT)

  DEr = (0., 0.)
  DFr = (0., 0.)

  ! Now we go to real in Chebyshev for DE and DF
  do lm=2, shtns%nlm ! We start from lm = 2 because lm = 1 is of no interest
    do k = 1, KK2
      DEr(k, lm)%re = (Chb2(k, :KK2) .dot. real(DE(:KK2, lm))) + (Ye_mat(k, :, ell(lm)) .dot. real(E_per(:, lm)))
      DEr(k, lm)%im = (Chb2(k, :KK2) .dot. aimag(DE(:KK2, lm))) + (Ye_mat(k, :, ell(lm)) .dot. aimag(E_per(:, lm)))
    end do
  end do

  do lm=2, shtns%nlm
    do k = 1, KK4
      DFr(k, lm)%re = (Chb4(k, :KK4) .dot. real(DF(:KK4, lm))) + (Yf_mat(k, :, ell(lm)) .dot. real(F_per(:, lm)))
      DFr(k, lm)%im = (Chb4(k, :KK4) .dot. aimag(DF(:KK4, lm))) + (Yf_mat(k, :, ell(lm)) .dot. aimag(F_per(:, lm)))
    end do
  end do

  ! Create arrays that respect the symmetry classes
  call small2big(DEr, DFr, DA)

  !--- Solution of the linear system

  !--- For E and F
  stride = 1
  Ap = 0.

  do m = 0, MM*mres, mres
    DA1 = 0.
    A1 = 0.
    n_even = ((LL + mod(LL, 2)) - max(m, 1)) / 2 + mod(LL + 1, 2)
    n_odd = ((LL + mod(LL, 2)) + 1 - m) / 2
    top = 2 * (KK2 + KK4) * (n_even + n_odd)

    A1 = Banded_LU_solve(top, 2 * (KK2 + KK4) - 1, Xef(:, stride), 6 * (KK2 + KK4) - 2, DA(stride, 1), PIVOT(stride))
    Ap(stride : stride + top - 1, 1) = A1(:top, 1)
    stride = stride + 2 * (KK2 + KK4) * (LL - (max(m, 1) - 1))
  end do

  !--- For T
  do lm = 1, shtns%nlm 
    do k = 1, KK2
      wT(k, lm)%re = XT_invYT(:, k, ell(lm)) .dot. real(T_per(:, lm))
      wDT(k, lm)%re = XT_inv(:, k, ell(lm)) .dot. real(DT(:, lm))
      wT(k, lm)%im = XT_invYT(:, k, ell(lm)) .dot. aimag(T_per(:, lm))
      wDT(k, lm)%im = XT_inv(:, k, ell(lm)) .dot. aimag(DT(:, lm))
    end do
  end do

  !--- New values of E, F and T
  call big2small(Ap, E_per, F_per)
  T_per = wT + wDT

end subroutine compute_lin_time_step_convective_implicit_FBE

end module mod_TimeStep
