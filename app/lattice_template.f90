#include "assert.ppc"
! Copyright (C)  2009 Max J. Hoffmann
!
! This file is part of libkmc.
!
! libkmc is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 2 of the License, or
! (at your option) any later version.
!
! libkmc is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with libkmc; if not, write to the Free Software
! Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
! USA



module lattice_%(lattice_name)s
use kind_values
! Import and rename from libkmc
use libkmc, only: &
  assertion_fail, &
  deallocate_system, &
  get_kmc_step, &
  get_kmc_time, &
  get_kmc_time_step, &
  get_rate, &
  libkmc_increment_procstat => increment_procstat, &
  libkmc_add_proc => add_proc, &
  libkmc_allocate_system => allocate_system, &
  libkmc_can_do => can_do, &
  libkmc_del_proc => del_proc, &
  determine_procsite, &
  libkmc_replace_species => replace_species, &
  libkmc_get_species => get_species, &
  libkmc_get_volume  => get_volume, &
  libkmc_reload_system => reload_system, &
  null_species, &
  reload_system, &
  save_system, &
  set_rate, &
  update_accum_rate, &
  update_clocks

implicit none

private

! Public subroutines
public :: allocate_system, &
  null_species, &
  assertion_fail, &
  deallocate_system, &
  determine_procsite, &
  get_rate, &
  get_kmc_step, &
  get_kmc_time, &
  get_system_size, &
  increment_procstat, &
  reload_system, &
  save_system, &
  set_rate, &
  update_accum_rate, &
  %(lattice_name)s2nr, &
  nr2%(lattice_name)s, &
  %(lattice_name)s_increment_procstat, &
  %(lattice_name)s_add_proc, &
  %(lattice_name)s_can_do, &
  %(lattice_name)s_del_proc, &
  %(lattice_name)s_replace_species, &
  %(lattice_name)s_get_species, &
  update_clocks


type tuple
  integer(kind=iint), dimension(2) :: t
end type tuple

integer(kind=iint), dimension(2), public :: system_size

{species_definition}
{lookup_table_initialization}


contains


subroutine %(lattice_name)s2nr(%(lattice_name)s_site, nr_site)
  !****f* lattice_%(lattice_name)s/%(lattice_name)s2nr
  ! FUNCTION
  !    Maps a coordinate from the %(lattice_name)s lattice to a coordinate
  !    on a
  !     |latex $d=1$
  !     |html d = 1
  !   array.
  ! ARGUMENTS
  !  * %(lattice_name)s_site -- tuple of integers that represent %(lattice_name)s coordinates
  !  * nr_site -- writable integer where the 1d coordinate will be
  !    stored
  !******
  !---------------I/O variables---------------
  integer(kind=iint), dimension(2), intent(in) :: %(lattice_name)s_site
  integer(kind=iint), intent(out) :: nr_site
  !---------------internal variables---------------
  integer(kind=iint) , dimension(2) :: folded_%(lattice_name)s_site


  folded_%(lattice_name)s_site = modulo(%(lattice_name)s_site, system_size)
  nr_site = folded_%(lattice_name)s_site(2)*system_size(1) + folded_%(lattice_name)s_site(1) + 1

end subroutine %(lattice_name)s2nr


subroutine nr2%(lattice_name)s(nr_site, %(lattice_name)s_site)
  !****f* lattice_%(lattice_name)s/nr2%(lattice_name)s
  ! FUNCTION
  !    Maps a coordinate from a
  !     |latex $d=1$
  !     |html d = 1
  !   array to a coordinate on the %(lattice_name)s lattice
  ! ARGUMENTS
  !  * nr_site -- writable integer where the 1d coordinate will be
  !    stored
  !  * %(lattice_name)s_site -- tuple of integers that represent %(lattice_name)s coordinates
  !******
  !---------------I/O variables---------------
  integer(kind=iint), intent(in) :: nr_site
  integer(kind=iint), dimension(2), intent(out) :: %(lattice_name)s_site

  %(lattice_name)s_site(1) = modulo(nr_site - 1, system_size(1))
  %(lattice_name)s_site(2) = (nr_site - 1)/system_size(1)


end subroutine nr2%(lattice_name)s


subroutine get_system_size(return_system_size)
  !****f* lattice_%(lattice_name)s/get_system_size
  ! FUNCTION
  !    Simple wrapper subroutine to that return the system's dimensions
  !******
  !---------------I/O variables---------------
  integer(kind=iint), dimension(2), intent(out) :: return_system_size
  return_system_size = system_size

end subroutine get_system_size


subroutine allocate_system(nr_of_proc, input_system_size, system_name)
  !---------------I/O variables---------------
  !****f* lattice_%(lattice_name)s/allocate_system
  ! FUNCTION
  !    Allocates combined RuO_2 system.
  !    Replication of core/allocate_system
  ! ARGUMENTS
  !  * nr_of_proc -- integer value representing the total number of processes
  !  * input_system_size -- integer value representing the total number of sites
  !  * system_name -- string of 200 characters that determines the name of the reload
  !    file that will be saved as ./<system_name>.reload
  !******
  !---------------I/O variables---------------
  integer(kind=iint), intent(in) :: nr_of_proc
  integer(kind=iint), dimension(2), intent(in) :: input_system_size
  character(len=200), intent(in) :: system_name
  !---------------internal variables---------------
  integer(kind=iint) :: volume

  if(.not.mod(system_size(1),2)==0)then
    print *,'Error(lattice_%(lattice_name)s/allocate_system): x-component '// &
      'of system size has to be even'
  endif
  ! Copy to module wide variable
  system_size = input_system_size

  {lookup_table_definition}

  volume = system_size(2)*system_size(1)

  call libkmc_allocate_system(nr_of_proc, volume, system_name)

end subroutine allocate_system



subroutine %(lattice_name)s_add_proc(proc, site)
  !****f* lattice_%(lattice_name)s/%(lattice_name)s_add_proc
  ! FUNCTION
  !    The %(lattice_name)s version of core/add_proc
  !******
  !---------------I/O variables---------------
  integer(kind=iint), intent(in) :: proc
  integer(kind=iint), dimension(2), intent(in) :: site
  !---------------internal variables---------------
  integer(kind=iint) :: nr


  ! Convert %(lattice_name)s site to nr
  call %(lattice_name)s2nr(site, nr)

  ! Call likmc subroutine
  call libkmc_add_proc(proc, nr)

end subroutine %(lattice_name)s_add_proc


subroutine %(lattice_name)s_del_proc(proc, site)
  !****f* lattice_%(lattice_name)s/%(lattice_name)s_del_proc
  ! FUNCTION
  !    The %(lattice_name)s version of core/add_proc
  !******
  !---------------I/O variables---------------
  integer(kind=iint), intent(in) :: proc
  integer(kind=iint), dimension(2), intent(in) :: site
  !---------------internal variables---------------
  integer(kind=iint) :: nr

  ! Convert %(lattice_name)s site to nr
  call %(lattice_name)s2nr(site, nr)

  ! Call likmc subroutine
  call libkmc_del_proc(proc, nr)

end subroutine %(lattice_name)s_del_proc

subroutine %(lattice_name)s_can_do(proc, site, can)
  !---------------I/O variables---------------
  integer(kind=iint), intent(in) :: proc
  integer(kind=iint), dimension(2), intent(in) :: site
  logical, intent(out) :: can
  !---------------internal variables---------------
  integer(kind=iint) :: nr

  ! Convert %(lattice_name)s site to nr
  call %(lattice_name)s2nr(site, nr)

  ! Call likmc subroutine
  call libkmc_can_do(proc, nr, can)

end subroutine %(lattice_name)s_can_do


subroutine increment_procstat(proc)
  !---------------I/O variables---------------
  integer(kind=iint), intent(in) :: proc

  call libkmc_increment_procstat(proc)

end subroutine increment_procstat


subroutine %(lattice_name)s_increment_procstat(proc)
  !---------------I/O variables---------------
  integer(kind=iint), intent(in) :: proc

  call libkmc_increment_procstat(proc)

end subroutine %(lattice_name)s_increment_procstat


subroutine %(lattice_name)s_replace_species(site, old_species, new_species)
  !****f* lattice_%(lattice_name)s/%(lattice_name)s_replace_species
  ! FUNCTION
  !    The %(lattice_name)s version of core/replace_species
  !******
  !---------------I/O variables---------------
  integer(kind=iint), dimension(2), intent(in) :: site
  integer(kind=iint), intent(in) :: old_species, new_species
  !---------------internal variables---------------
  integer(kind=iint) :: nr

  ! Convert %(lattice_name)s site to nr
  call %(lattice_name)s2nr(site, nr)
  ! Call likmc subroutine
  call libkmc_replace_species(nr, old_species, new_species)

end subroutine %(lattice_name)s_replace_species


subroutine %(lattice_name)s_get_species(site, return_species)
  !****f* lattice_%(lattice_name)s/%(lattice_name)s_get_species
  ! FUNCTION
  !    The %(lattice_name)s  version of core/get_species
  !******
  !---------------I/O variables---------------
  integer(kind=iint), dimension(2), intent(in) :: site
  integer(kind=iint), intent(out) :: return_species
  !---------------internal variables---------------
  integer(kind=iint) :: nr

  ! Convert %(lattice_name)s site to nr
  call %(lattice_name)s2nr(site, nr)

  ! Call likmc subroutine
  call libkmc_get_species(nr, return_species)
end subroutine %(lattice_name)s_get_species


end module lattice_%(lattice_name)s
